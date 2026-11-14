extends SceneTree

const StepEngine = preload("res://core/MissionStepEngine.gd")
const Adapter = preload("res://core/HPCContractAdapter.gd")
const HPC_BASE_SHA: String = "ab7865cf45e65de84637b4319899759928ee7082"
const KE1_SHA: String = "15385a442c0dfeebd4752a8a648e306624327098"
const TRACE_REVISION: String = "hpc-ke1-adapter-abort-v0.1"
const RUN_ID: String = "run_ke2_handoff_v01"
const MISSION_ID: String = "mission_ke2_handoff_v01"

func _initialize() -> void:
	var config_file: FileAccess = FileAccess.open("res://docs/contracts/v1-draft/mission-config.example.json", FileAccess.READ)
	if config_file == null:
		_fail("Could not open KE1 mission config fixture")
		return
	var config: Dictionary = JSON.parse_string(config_file.get_as_text())
	var orbit_file: FileAccess = FileAccess.open("res://data/orbits.json", FileAccess.READ)
	if orbit_file == null:
		_fail("Could not open HPC orbit presets")
		return
	var orbit_data: Dictionary = JSON.parse_string(orbit_file.get_as_text())
	var built: Dictionary = Adapter.build_scenario(_ke1_catalog_sample(), orbit_data)
	if not built.get("ok", false):
		_fail("Scenario adapter failed: %s" % built)
		return
	var started: Dictionary = StepEngine.init_run(config, built.scenario, RUN_ID, MISSION_ID)
	if not started.get("ok", false):
		_fail("HPC initialization failed: %s" % started)
		return
	var state: Dictionary = started.state
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
	for orbit in built.scenario.orbits:
		if str(orbit.id) == str(state.scenario_id):
			selected_orbit = orbit
			break
	var trace: Dictionary = {
		"trace_revision": TRACE_REVISION,
		"trace_status": "HPC sample; KE1 launch readiness is not yet implemented",
		"source": {
			"repository": "taite-ang-saiyin/orbitbridge-mission-architect",
			"hpc_branch": "feature/hpc-simulator",
			"hpc_base_commit_sha": HPC_BASE_SHA,
			"hpc_working_tree_revision": TRACE_REVISION,
			"hpc_changes_committed": false,
			"ke1_branch": "ke1",
			"ke1_commit_sha": KE1_SHA,
			"config_fixture": "origin/ke1:tests/fixtures/ke1_config.json (same payload as docs/contracts/v1-draft/mission-config.example.json)",
			"ke1_status": "K05-K06 schema and reference validation implemented; K07-K09 launch-readiness checks pending"
		},
		"validation": {
			"mission_config_schema_and_references": "KE1 fixture from the K05-K06 branch; KE1 reports ready_to_launch=false until K07-K09 are implemented",
			"launch_approved": false,
			"hpc_scenario_adapter": "passed"
		},
		"run_id": RUN_ID,
		"mission_id": MISSION_ID,
		"config": config,
		"scenario_id": state.scenario_id,
		"scenario_version": str(built.scenario.scenario_version),
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
	var output: FileAccess = FileAccess.open("res://docs/hpc-ke2-trace-v0.1.json", FileAccess.WRITE)
	if output == null:
		_fail("Could not write trace payload")
		return
	output.store_string(JSON.stringify(trace, "\t"))
	output.close()
	print("Wrote KE2 trace revision %s (%d events, %s)." % [TRACE_REVISION, ordered_events.size(), state.run_status])
	quit(0)

func _ke1_catalog_sample() -> Dictionary:
	return {
		"schema_version": 1,
		"contract_revision": "v1.0-agreed",
		"components": [
			{"id": "bus_basic", "category": "bus", "baseline_power_w": 2},
			{"id": "instrument_basic", "category": "instrument", "observe_power_w": 4, "data_per_observation_mb": 12, "supported_objectives": ["imaging"]},
			{"id": "solar_standard", "category": "solar", "generation_power_w": 3},
			{"id": "battery_standard", "category": "battery", "capacity_wh": 25, "initial_charge_fraction": 1},
			{"id": "radio_basic", "category": "radio", "transmit_power_w": 3, "downlink_mb_per_hour": 48},
			{"id": "storage_standard", "category": "storage", "capacity_mb": 64}
		],
		"launch_profiles": [{"id": "cubesat_1u_sample"}],
		"launchers": [{"id": "small"}],
		"objective_ids": ["imaging"],
		"orbit_ids": ["low_eq", "high_inc"],
		"target_region_ids": ["equator"]
	}

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
