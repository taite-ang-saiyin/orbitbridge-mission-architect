extends SceneTree

const StepEngine = preload("res://core/MissionStepEngine.gd")
const Adapter = preload("res://core/HPCContractAdapter.gd")
const CatalogLoader = preload("res://scripts/core/catalog_loader.gd")
const HPC_BASE_SHA: String = "a9a65c94142348f9951533155dbb0ea9fd70c8f1"
const KE1_SHA: String = "55d4f336e72a68ff31cf37e44f65a98c1cdcc193"
const TRACE_REVISION: String = "hpc-ke3-ops-trace-v0.2"
const RUN_ID: String = "run_ke3_handoff_v01"
const MISSION_ID: String = "mission_ke3_handoff_v01"

func _initialize() -> void:
	var config_file: FileAccess = FileAccess.open("res://tests/fixtures/valid_1u_feasible.json", FileAccess.READ)
	if config_file == null:
		_fail("Could not open KE1 mission config fixture")
		return
	var config: Dictionary = JSON.parse_string(config_file.get_as_text())
	var ke1_result: Dictionary = CatalogLoader.load_catalogs()
	if not ke1_result.get("ok", false):
		_fail("KE1 catalogs failed to load: %s" % ke1_result.get("errors", []))
		return
	var catalogs: Dictionary = ke1_result.catalogs
	var orbit_data: Dictionary = catalogs.get("orbit_catalog", {})
	var started: Dictionary = StepEngine.init_validated_run(config, catalogs, RUN_ID, MISSION_ID)
	if not started.get("ok", false):
		_fail("KE1 readiness or HPC initialization failed: %s" % started)
		return
	var state: Dictionary = started.state
	var validation_result: Dictionary = started.validation_result
	var scenario_result: Dictionary = Adapter.build_scenario(catalogs, orbit_data)
	if not scenario_result.get("ok", false):
		_fail("Scenario adapter failed: %s" % scenario_result)
		return
	var ordered_events: Array[Dictionary] = []
	var selected_replies: Array[Dictionary] = []
	var action_count: int = 0
	var no_contact_transmit_attempted: bool = false
	while int(state.step_index) < int(state.total_steps):
		var action_step_index: int = int(state.step_index)
		var action: String = "power_save"
		match action_step_index:
			1: action = "observe"
			7: action = "transmit"
			8: action = "power_save" if no_contact_transmit_attempted else "transmit"
		var action_result: Dictionary = StepEngine.request_action(state, action)
		if not action_result.get("ok", false):
			_fail("HPC action failed at step %d: %s" % [state.step_index, action_result])
			return
		state = action_result.state
		action_count += 1
		if action_step_index == 8 and action == "transmit":
			no_contact_transmit_attempted = true
		for event in action_result.events:
			var record: Dictionary = event.duplicate(true)
			record["energy_wh_after"] = state.energy_wh
			record["stored_data_mb_after"] = state.stored_data_mb
			record["returned_data_mb_after"] = state.returned_data_mb
			record["observations_completed_after"] = state.observations_completed
			record["phase_after"] = state.phase
			record["run_status_after"] = state.run_status
			ordered_events.append(record)
		if action_step_index in [1, 7, 8] or str(state.phase) == "finished":
			selected_replies.append({
				"requested_step_index": action_step_index,
				"action": action,
				"ok": bool(action_result.ok),
				"allowed": bool(action_result.get("allowed", false)),
				"state": _state_reply(state),
				"events": action_result.events.duplicate(true)
			})
	var selected_orbit: Dictionary = {}
	for orbit in scenario_result.scenario.orbits:
		if str(orbit.id) == str(state.scenario_id):
			selected_orbit = orbit
			break
	var trace: Dictionary = {
		"trace_revision": TRACE_REVISION,
		"trace_status": "HPC run initialized from a config approved by KE1 readiness",
		"source": {
			"repository": "taite-ang-saiyin/orbitbridge-mission-architect",
			"hpc_branch": "feature/hpc-simulator",
			"hpc_base_commit_sha": HPC_BASE_SHA,
			"hpc_working_tree_revision": "hpc-ke1-readiness-integration-v0.1",
			"hpc_changes_committed": false,
			"ke1_branch": "ke1",
			"ke1_commit_sha": KE1_SHA,
			"config_fixture": "tests/fixtures/valid_1u_feasible.json",
			"ke1_status": "KE1 readiness implementation from the recorded commit"
		},
		"validation": {
			"launch_approved": bool(validation_result.ready_to_launch),
			"result": validation_result,
			"hpc_scenario_adapter": "passed"
		},
		"run_id": RUN_ID,
		"mission_id": MISSION_ID,
		"config": config,
		"scenario_id": state.scenario_id,
		"scenario_version": str(scenario_result.scenario.scenario_version),
		"target_id": str(config.mission.target_region),
		"total_steps": state.total_steps,
		"step_duration_hours": float(selected_orbit.step_duration_hours),
		"units": {"energy": "Wh", "data": "decimal MB", "time": "hours"},
		"action_count": action_count,
		"event_count": ordered_events.size(),
		"selected_action_replies": selected_replies,
		"trace_actions": [
			{"step_index": 0, "action": "power_save", "purpose": "advance to high_inc equator access"},
			{"step_index": 1, "action": "observe", "purpose": "capture 12 MB at equator"},
			{"step_index": 7, "action": "transmit", "purpose": "transmit during ground contact"},
			{"step_index": 8, "action": "transmit", "purpose": "blocked because no ground contact; does not advance the step"},
			{"step_index": 8, "action": "power_save", "purpose": "accepted action advances after blocked request"},
			{"step_index": 59, "action": "power_save", "purpose": "complete mission at total_steps"}
		],
		"final_state": _terminal_state_payload(state),
		"events": ordered_events
	}
	var output: FileAccess = FileAccess.open("res://docs/hpc-ke3-ops-trace-v0.2.json", FileAccess.WRITE)
	if output == null:
		_fail("Could not write trace payload")
		return
	output.store_string(JSON.stringify(trace, "\t"))
	output.close()
	print("Wrote KE3 operations trace revision %s (%d events, %s)." % [TRACE_REVISION, ordered_events.size(), state.run_status])
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _state_reply(state: Dictionary) -> Dictionary:
	return {
		"step_index": state.step_index,
		"total_steps": state.total_steps,
		"phase": state.phase,
		"run_status": state.run_status,
		"terminal_reason": state.terminal_reason,
		"is_sunlit": state.is_sunlit,
		"in_target_access": state.in_target_access,
		"in_ground_contact": state.in_ground_contact,
		"energy_wh": state.energy_wh,
		"stored_data_mb": state.stored_data_mb,
		"returned_data_mb": state.returned_data_mb,
		"observations_completed": state.observations_completed
	}

func _terminal_state_payload(state: Dictionary) -> Dictionary:
	var payload: Dictionary = _state_reply(state)
	for key in ["schema_version", "run_id", "mission_id", "scenario_id", "available_actions"]:
		payload[key] = state[key]
	return payload
