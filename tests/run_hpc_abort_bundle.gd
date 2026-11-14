extends SceneTree

const StepEngine = preload("res://core/MissionStepEngine.gd")
const CatalogLoader = preload("res://scripts/core/catalog_loader.gd")
const SOURCE_COMMIT_SHA: String = "3990d3c7aae3b69dcf367d9f0601fc40fd669262"
const RUN_ID: String = "run_hpc_ke2_abort_3990d3c_01"
const MISSION_ID: String = "mission_hpc_ke2_abort_01"
const ABORT_REASON: String = "Operator requested abort for KE2 and SE/KE3 lifecycle verification."
const OUTPUT_PATH: String = "res://docs/hpc-ke2-abort-bundle-v0.1.json"

func _initialize() -> void:
	var config_file: FileAccess = FileAccess.open("res://tests/fixtures/valid_1u_feasible.json", FileAccess.READ)
	if config_file == null:
		_fail("Could not open launch config fixture")
		return
	var parsed: Variant = JSON.parse_string(config_file.get_as_text())
	if not parsed is Dictionary:
		_fail("Launch config fixture is malformed")
		return
	var launch_config: Dictionary = parsed
	var catalog_result: Dictionary = CatalogLoader.load_catalogs()
	if not catalog_result.get("ok", false):
		_fail("KE1 catalogs failed to load: %s" % catalog_result.get("errors", []))
		return
	var started: Dictionary = StepEngine.init_validated_run(launch_config, catalog_result.catalogs, RUN_ID, MISSION_ID)
	if not started.get("ok", false):
		_fail("Validated run did not initialize: %s" % started)
		return
	var state: Dictionary = started.state
	var actions: Array[Dictionary] = []
	# Match the shared handoff trace through evt_008: observe, contact-on transmit,
	# then attempt a transmit outside contact. Abort at the same unadvanced step.
	for expected_step in range(8):
		if int(state.step_index) != expected_step:
			_fail("Unexpected step before action: expected %d, got %d" % [expected_step, state.step_index])
			return
		var action: String = "observe" if expected_step == 1 else ("transmit" if expected_step == 7 else "power_save")
		var action_result: Dictionary = StepEngine.request_action(state, action)
		if not action_result.get("ok", false) or not action_result.get("allowed", false):
			_fail("Expected action %s at step %d to succeed: %s" % [action, expected_step, action_result])
			return
		state = action_result.state
		actions.append({"step_index": expected_step, "action": action, "response": action_result})
	if int(state.step_index) != 8:
		_fail("Run did not reach step 8 before blocked-transmit evidence")
		return
	var blocked_result: Dictionary = StepEngine.request_action(state, "transmit")
	if not blocked_result.get("ok", false) or blocked_result.get("allowed", true):
		_fail("Expected no-contact transmit to be blocked: %s" % blocked_result)
		return
	state = blocked_result.state
	actions.append({"step_index": 8, "action": "transmit", "response": blocked_result})
	var pre_abort_state: Dictionary = state.duplicate(true)
	var abort_response: Dictionary = StepEngine.abort_run(state, ABORT_REASON)
	if not abort_response.get("ok", false):
		_fail("Operator abort failed: %s" % abort_response)
		return
	var terminal_state: Dictionary = abort_response.state
	var ordered_events: Array = terminal_state.event_log.duplicate(true)
	var abort_events: Array = abort_response.events
	if not _verify_abort_bundle(terminal_state, pre_abort_state, ordered_events, abort_events):
		_fail("Abort bundle invariants failed")
		return
	var scenario: Dictionary = terminal_state.scenario_snapshot
	var bundle: Dictionary = {
		"bundle_revision": "hpc-ke2-operator-abort-v0.1",
		"source": {
			"repository": "taite-ang-saiyin/orbitbridge-mission-architect",
			"branch": "feature/hpc-simulator",
			"source_commit_sha": SOURCE_COMMIT_SHA,
			"engine_path": "core/MissionStepEngine.gd",
			"generation_script": "tests/run_hpc_abort_bundle.gd"
		},
		"run_id": RUN_ID,
		"mission_id": MISSION_ID,
		"scenario_id": str(terminal_state.scenario_id),
		"scenario_version": str(scenario.scenario_version),
		"units": {"energy": "Wh", "data": "decimal MB", "time": "hours"},
		"launch_config": launch_config.duplicate(true),
		"readiness": {
			"launch_approved": bool(started.validation_result.ready_to_launch),
			"validation_result": started.validation_result.duplicate(true)
		},
		"abort_reason": ABORT_REASON,
		"trace_actions": actions,
		"pre_abort_state": pre_abort_state,
		"abort_response": abort_response,
		"terminal_state": terminal_state,
		"ordered_events": ordered_events,
		"abort_event": abort_events[0],
		"expected_ke2_checks": {
			"run_status": "aborted",
			"status": "failed",
			"score": null,
			"terminal_reason_nonempty": true,
			"evidence_event_ids": ["evt_008", str(abort_events[0].event_id)]
		}
	}
	var output: FileAccess = FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if output == null:
		_fail("Could not write abort bundle at %s" % OUTPUT_PATH)
		return
	output.store_string(JSON.stringify(bundle, "\t"))
	output.close()
	print("Wrote %s: %s, %s, step %d, %d ordered events." % [OUTPUT_PATH, RUN_ID, terminal_state.run_status, terminal_state.step_index, ordered_events.size()])
	quit(0)

func _verify_abort_bundle(terminal_state: Dictionary, before_abort: Dictionary, events: Array, abort_events: Array) -> bool:
	if str(terminal_state.run_status) != "aborted" or str(terminal_state.phase) != "finished":
		return false
	if str(terminal_state.terminal_reason).strip_edges().is_empty() or str(terminal_state.terminal_reason) != ABORT_REASON:
		return false
	for key in ["step_index", "energy_wh", "stored_data_mb", "returned_data_mb", "observations_completed"]:
		if terminal_state.get(key) != before_abort.get(key):
			return false
	if int(terminal_state.step_index) != 8 or int(terminal_state.observations_completed) != 1:
		return false
	if events.size() != 10 or str(events[8].event_id) != "evt_008" or str(events[8].code) != "NO_LINK_WINDOW":
		return false
	if events[8].type != "action_blocked" or int(events[8].step_index) != 8:
		return false
	if abort_events.size() != 1 or str(abort_events[0].event_id) != "evt_009":
		return false
	if str(abort_events[0].type) != "mission_aborted" or str(abort_events[0].terminal_reason) != ABORT_REASON:
		return false
	return events[9] == abort_events[0]

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
