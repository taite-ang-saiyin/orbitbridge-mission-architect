extends SceneTree

const StepEngine = preload("res://core/MissionStepEngine.gd")
const Adapter = preload("res://core/HPCContractAdapter.gd")
const LegacySimulator = preload("res://core/MissionSimulator.gd")
const LegacyTraceAdapter = preload("res://core/LegacyTraceAdapter.gd")
const Ke1CatalogLoader = preload("res://scripts/core/catalog_loader.gd")
const Ke1MissionValidator = preload("res://scripts/core/mission_validator.gd")
var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	var catalog: Dictionary = _catalog()
	_test_successful_observe(catalog)
	_test_observe_outside_window(catalog)
	_test_observe_storage_full(catalog)
	_test_observe_low_energy(catalog)
	_test_observe_fractional_energy_deficit(catalog)
	_test_successful_transmit(catalog)
	_test_transmit_outside_contact(catalog)
	_test_transmit_no_data(catalog)
	_test_power_save(catalog)
	_test_battery_bound(catalog)
	_test_storage_bound(catalog)
	_test_determinism(catalog)
	_test_orbit_window_differences(catalog)
	_test_rejected_action_is_immutable(catalog)
	_test_mission_finish(catalog)
	_test_invalid_config(catalog)
	_test_legacy_golden_compatibility(catalog)
	_test_v1_run_identity_and_event_contract(catalog)
	_test_inconsistent_terminal_indices(catalog)
	_test_storage_float_boundary(catalog)
	_test_power_save_clamps_and_continues(catalog)
	_test_ke1_catalog_bridge()
	_test_abort_run(catalog)
	_test_ke1_readiness_integration()
	_test_next_step_prediction(catalog)
	if _failed > 0:
		push_error("HPC Team Contract v1 suite failed: %d passed, %d failed" % [_passed, _failed])
		quit(1)
	else:
		print("HPC Team Contract v1 tests passed: %d" % _passed)
		quit(0)

func _test_successful_observe(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [0], [8])
	var state: Dictionary = _initialized(_config(), catalog)
	var result: Dictionary = StepEngine.execute_step(state, "observe", catalog)
	_case("successful observe", result.get("allowed", false) and int(result.state.observations_completed) == 1 and is_equal_approx(float(result.state.stored_data_mb), 8.0) and result.event.has("energy_change_wh"))

func _test_observe_outside_window(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [2], [8])
	var state: Dictionary = _initialized(_config(), catalog)
	var result: Dictionary = StepEngine.execute_step(state, "observe", catalog)
	_case("blocked observe outside target window", not result.allowed and result.reason_code == "TARGET_NOT_VISIBLE")

func _test_observe_storage_full(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [0], [8])
	var state: Dictionary = _initialized(_config(), catalog)
	state.stored_data_mb = state.storage_capacity_mb
	var result: Dictionary = StepEngine.execute_step(state, "observe", catalog)
	_case("blocked observe when storage is full", not result.allowed and result.reason_code == "STORAGE_FULL")

func _test_observe_low_energy(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [0], [8])
	_set_part(catalog, "solar40", "output_w", 0)
	var state: Dictionary = _initialized(_config(), catalog)
	state.energy_wh = 0.0
	var result: Dictionary = StepEngine.execute_step(state, "observe", catalog)
	_case("blocked observe with insufficient energy", not result.allowed and result.reason_code == "LOW_BATTERY")

func _test_observe_fractional_energy_deficit(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [0], [])
	_set_part(catalog, "solar40", "output_w", 0.0)
	var state: Dictionary = _initialized(_config(), catalog)
	var step_hours: float = float(_orbit(catalog, "low_eq").step_duration_hours)
	state.energy_wh = 30.0 * step_hours - 0.00000005
	var result: Dictionary = StepEngine.request_action(state, "observe")
	_case("tiny real action-energy deficit is blocked", result.get("ok", false) and not result.get("allowed", true) and result.events[0].code == "LOW_BATTERY" and result.state.step_index == state.step_index and result.state.observations_completed == state.observations_completed and is_equal_approx(float(result.state.energy_wh), float(state.energy_wh)))

func _test_successful_transmit(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [], [0])
	var state: Dictionary = _initialized(_config(), catalog)
	state.stored_data_mb = 8.0
	var result: Dictionary = StepEngine.execute_step(state, "transmit", catalog)
	var expected_mb: float = minf(8.0, float(_part(catalog, "radio_base").downlink_mb_per_hour) * float(_orbit(catalog, "low_eq").step_duration_hours))
	_case("successful transmit uses decimal MB per step", result.allowed and is_equal_approx(float(result.state.returned_data_mb), expected_mb) and is_equal_approx(float(result.event.data_transmitted_mb), expected_mb) and is_equal_approx(float(result.event.delta_returned_data_mb), expected_mb) and is_equal_approx(float(result.state.stored_data_mb), 8.0 - expected_mb))

func _test_transmit_outside_contact(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [], [8])
	var state: Dictionary = _initialized(_config(), catalog)
	state.stored_data_mb = 2.0
	var result: Dictionary = StepEngine.execute_step(state, "transmit", catalog)
	_case("blocked transmit outside contact window", not result.allowed and result.reason_code == "NO_LINK_WINDOW" and is_equal_approx(float(result.state.returned_data_mb), 0.0))

func _test_transmit_no_data(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [], [0])
	var state: Dictionary = _initialized(_config(), catalog)
	var result: Dictionary = StepEngine.execute_step(state, "transmit", catalog)
	_case("blocked transmit with no data", not result.allowed and result.reason_code == "NO_DATA")

func _test_power_save(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [], [])
	var state: Dictionary = _initialized(_config(), catalog)
	var result: Dictionary = StepEngine.execute_step(state, "power_save", catalog)
	_case("successful power_save", result.allowed and int(result.state.step_index) == 1 and int(result.state.observations_completed) == 0 and is_equal_approx(float(result.event.energy_consumed_wh), 10.0 * 0.1538888889))

func _test_battery_bound(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [], [])
	var state: Dictionary = _initialized(_config(), catalog)
	state.energy_wh = float(state.battery_capacity_wh) - 0.001
	var result: Dictionary = StepEngine.execute_step(state, "power_save", catalog)
	_case("battery remains within capacity", result.allowed and float(result.state.energy_wh) <= float(result.state.battery_capacity_wh) and float(result.state.energy_wh) >= 0.0 and result.event.energy_clamped)

func _test_storage_bound(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [0], [])
	var state: Dictionary = _initialized(_config(), catalog)
	state.stored_data_mb = float(state.storage_capacity_mb) - 8.0
	var result: Dictionary = StepEngine.execute_step(state, "observe", catalog)
	_case("storage remains within capacity", result.allowed and is_equal_approx(float(result.state.stored_data_mb), float(result.state.storage_capacity_mb)))

func _test_determinism(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [], [])
	var initial: Dictionary = _initialized(_config(), catalog)
	var first: Dictionary = StepEngine.execute_step(initial.duplicate(true), "power_save", catalog)
	var second: Dictionary = StepEngine.execute_step(initial.duplicate(true), "power_save", catalog)
	_case("deterministic identical replay", first == second)

func _test_orbit_window_differences(source_catalog: Dictionary) -> void:
	var low: Dictionary = StepEngine.initialize(_config("low_eq"), source_catalog)
	var high: Dictionary = StepEngine.initialize(_config("high_inc"), source_catalog)
	var low_actions: Dictionary = StepEngine.get_available_actions(low.state)
	var high_actions: Dictionary = StepEngine.get_available_actions(high.state)
	var low_plan: Dictionary = _planner().build_step_plan("low_eq", ["equator"], 10, source_catalog)
	var high_plan: Dictionary = _planner().build_step_plan("high_inc", ["equator"], 10, source_catalog)
	_case("different orbit preset windows", low.ok and high.ok and low_actions.ok and high_actions.ok and not low_plan.steps[1].target_windows.has("equator") and not low_plan.steps[1].contact and high_plan.steps[1].target_windows.has("equator") and low_plan.steps[2].target_windows.has("equator") and not high_plan.steps[2].target_windows.has("equator"))

func _test_rejected_action_is_immutable(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [2], [8])
	var state: Dictionary = _initialized(_config(), catalog)
	var result: Dictionary = StepEngine.execute_step(state, "observe", catalog)
	var unchanged_resources: bool = is_equal_approx(float(result.state.energy_wh), float(state.energy_wh)) and is_equal_approx(float(result.state.stored_data_mb), float(state.stored_data_mb)) and is_equal_approx(float(result.state.returned_data_mb), float(state.returned_data_mb)) and int(result.state.observations_completed) == int(state.observations_completed)
	_case("rejected action leaves resources and step unchanged", not result.allowed and unchanged_resources and int(result.state.step_index) == int(state.step_index) and result.state.event_log.size() == state.event_log.size() + 1)

func _test_mission_finish(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [], [])
	var state: Dictionary = _initialized(_config(), catalog)
	var success: bool = true
	while str(state.phase) != "finished":
		var result: Dictionary = StepEngine.execute_step(state, "power_save", catalog)
		if not result.get("allowed", false):
			success = false
			break
		state = result.state
	var accepted_event: Dictionary = state.event_log[state.event_log.size() - 2] if state.event_log.size() >= 2 else {}
	var terminal_event: Dictionary = state.event_log.back() if not state.event_log.is_empty() else {}
	_case("mission finishes at total_steps", success and int(state.step_index) == int(state.total_steps) and state.phase == "finished" and state.run_status == "completed" and accepted_event.type == "action_accepted" and accepted_event.step_index == state.total_steps - 1 and terminal_event.type == "mission_finished" and terminal_event.step_index == state.total_steps)

func _test_invalid_config(source_catalog: Dictionary) -> void:
	var missing: Dictionary = _config()
	missing.design.erase("battery_id")
	var bad_schema: Dictionary = _config()
	bad_schema.schema_version = 9
	var fractional: Dictionary = _config()
	fractional.mission.duration_orbits = 1.5
	var missing_id: Dictionary = _config("does_not_exist")
	var a: Dictionary = Adapter.validate_config(missing, source_catalog)
	var b: Dictionary = Adapter.validate_config(bad_schema, source_catalog)
	var c: Dictionary = Adapter.validate_config(fractional, source_catalog)
	var d: Dictionary = Adapter.validate_config(missing_id, source_catalog)
	_case("invalid MissionConfig returns stable errors", not a.ok and a.error_code == "MISSING_FIELD" and not b.ok and b.error_code == "UNSUPPORTED_SCHEMA_VERSION" and not c.ok and c.error_code == "INVALID_TYPE" and not d.ok and d.error_code == "UNKNOWN_ORBIT_ID")

func _test_legacy_golden_compatibility(catalog: Dictionary) -> void:
	var file := FileAccess.open("res://data/fixtures/hpc_golden_radio_ab.json", FileAccess.READ)
	var fixture: Dictionary = JSON.parse_string(file.get_as_text())
	var a_input: Dictionary = fixture.duplicate(true)
	a_input.erase("expected")
	a_input.design.radio_id = "radio_base"
	var b_input: Dictionary = fixture.duplicate(true)
	b_input.erase("expected")
	b_input.design.radio_id = "radio_upgraded"
	var a: Dictionary = LegacySimulator.simulate(a_input, catalog)
	var b: Dictionary = LegacySimulator.simulate(b_input, catalog)
	_case("legacy whole-run golden API compatibility", a.get("ok", false) and b.get("ok", false) and a.metrics.captured == 5 and a.metrics.delivered == 2 and a.metrics.returned_kb == 16620 and a.metrics.buffer_kb == 23380 and b.metrics.captured == 5 and b.metrics.delivered == 5 and b.metrics.returned_kb == 40000 and b.metrics.buffer_kb == 0)
	var adapted: Dictionary = LegacyTraceAdapter.to_v1_units(b)
	var last_telemetry: Dictionary = adapted.telemetry.back() if adapted.get("telemetry", []).size() > 0 else {}
	var unit_conversion_ok: bool = adapted.get("ok", false) and adapted.compatibility_kind == "legacy_trace_summary" and is_equal_approx(float(adapted.metrics.energy_wh), float(b.metrics.final_battery_ws) / 3600.0) and is_equal_approx(float(adapted.metrics.returned_data_mb), 40.0) and is_equal_approx(float(adapted.metrics.stored_data_mb), 0.0) and is_equal_approx(float(adapted.summary.minimum_energy_wh), float(b.state.minimum_battery_ws) / 3600.0) and is_equal_approx(float(last_telemetry.energy_wh), float(b.telemetry.back().battery_ws) / 3600.0) and adapted.legacy_events.size() == b.events.size() and adapted.legacy_event_schema == "seq_slot_t_s_code_params"
	_case("legacy trace adapter exposes Wh and decimal MB", unit_conversion_ok)
	var invalid_adapted: Dictionary = LegacyTraceAdapter.to_v1_units({"ok": true})
	_case("legacy trace adapter rejects malformed traces", not invalid_adapted.get("ok", false) and invalid_adapted.error.code == "INVALID_LEGACY_TRACE")

func _test_v1_run_identity_and_event_contract(catalog: Dictionary) -> void:
	var initialized: Dictionary = StepEngine.init_run(_config(), catalog, "run_v1_01", "mission_v1_01")
	var state: Dictionary = initialized.state
	var blocked: Dictionary = StepEngine.request_action(state, "observe")
	var blocked_event: Dictionary = blocked.events[0]
	var blocked_again: Dictionary = StepEngine.request_action(blocked.state, "observe")
	var blocked_again_event: Dictionary = blocked_again.events[0]
	var identity_ok: bool = state.run_id == "run_v1_01" and state.mission_id == "mission_v1_01"
	var event_ok: bool = blocked_event.event_id == "evt_000" and blocked_event.run_id == state.run_id and blocked_event.mission_id == state.mission_id and blocked_event.type == "action_blocked" and blocked_event.delta_energy_wh == 0.0 and blocked_event.delta_stored_data_mb == 0.0 and blocked_event.delta_returned_data_mb == 0.0 and blocked_event.delta_observations == 0
	var repeated_event_ok: bool = blocked_again_event.event_id == "evt_001" and blocked_again_event.event_id != blocked_event.event_id and blocked_again_event.step_index == blocked_event.step_index and blocked_again.state.step_index == state.step_index
	_case("v1 run identity, blocked deltas and unique repeated events", initialized.ok and identity_ok and event_ok and repeated_event_ok and blocked.state.step_index == state.step_index)
	var actions: Dictionary = StepEngine.get_available_actions(state)
	_case("v1 action availability map", actions.ok and actions.available_actions.has("observe") and actions.available_actions.has("transmit") and actions.available_actions.has("power_save"))

func _test_inconsistent_terminal_indices(catalog: Dictionary) -> void:
	var initialized: Dictionary = StepEngine.init_run(_config(), catalog, "run_bad_terminal", "mission_bad_terminal")
	var operating_at_end: Dictionary = initialized.state.duplicate(true)
	operating_at_end.step_index = operating_at_end.total_steps
	var actions: Dictionary = StepEngine.get_available_actions(operating_at_end)
	var action_result: Dictionary = StepEngine.request_action(operating_at_end, "power_save")
	var aborted_at_end: Dictionary = initialized.state.duplicate(true)
	aborted_at_end.step_index = aborted_at_end.total_steps
	aborted_at_end.phase = "finished"
	aborted_at_end.run_status = "aborted"
	aborted_at_end.terminal_reason = "Malformed terminal test"
	var abort_result: Dictionary = StepEngine.get_available_actions(aborted_at_end)
	_case("inconsistent terminal indices return errors", not actions.get("ok", false) and actions.error.code == "INVALID_MISSION_STATE" and not action_result.get("ok", false) and action_result.error.code == "INVALID_MISSION_STATE" and not abort_result.get("ok", false) and abort_result.error.code == "INVALID_MISSION_STATE")

func _test_storage_float_boundary(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [0], [])
	var state: Dictionary = _initialized(_config(), catalog)
	var packet_mb: float = 8.0
	state.stored_data_mb = float(state.storage_capacity_mb) - packet_mb + 0.00000005
	var result: Dictionary = StepEngine.request_action(state, "observe")
	var event: Dictionary = result.events[0] if result.get("events", []).size() == 1 else {}
	_case("storage float boundary cannot exceed capacity", result.get("ok", false) and not result.get("allowed", true) and event.get("code") == "STORAGE_FULL" and is_equal_approx(float(result.state.stored_data_mb), float(state.stored_data_mb)) and float(result.state.stored_data_mb) <= float(result.state.storage_capacity_mb))

func _test_power_save_clamps_and_continues(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [], [])
	_set_part(catalog, "bat60", "capacity_ws", 100)
	_set_part(catalog, "core_bus", "idle_w", 10)
	_set_part(catalog, "solar40", "output_w", 0)
	var initialized: Dictionary = StepEngine.init_run(_config(), catalog, "run_clamp", "mission_clamp")
	var state: Dictionary = initialized.state
	state.energy_wh = 0.01
	var result: Dictionary = StepEngine.request_action(state, "power_save")
	_case("power_save clamps at zero and advances", result.ok and result.state.energy_wh == 0.0 and result.state.step_index == state.step_index + 1 and result.state.run_status == null)

func _test_ke1_catalog_bridge() -> void:
	var orbit_file := FileAccess.open("res://data/orbits.json", FileAccess.READ)
	var config_file := FileAccess.open("res://docs/contracts/v1-draft/mission-config.example.json", FileAccess.READ)
	var orbit_data: Dictionary = JSON.parse_string(orbit_file.get_as_text())
	var config: Dictionary = JSON.parse_string(config_file.get_as_text())
	# Selected production KE1 rows and IDs at ke1 commit 15385a4; the shape is CatalogLoader's bundle.
	var ke1: Dictionary = {
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
		"launch_profiles": [{"id": "cubesat_1u_sample", "supported_orbit_ids": ["low_eq", "high_inc"]}],
		"launchers": [{"id": "small", "supported_orbit_ids": ["low_eq", "high_inc"]}],
		"objective_ids": ["imaging"],
		"orbit_ids": ["low_eq", "high_inc"],
		"target_region_ids": ["equator"]
	}
	var built: Dictionary = Adapter.build_scenario(ke1, orbit_data)
	if not built.get("ok", false):
		_case("KE1 catalog bridge", false)
		return
	var initialized: Dictionary = StepEngine.init_run(config, built.scenario, "run_ke1", "mission_ke1")
	var good: bool = initialized.get("ok", false)
	if good:
		var state: Dictionary = initialized.state
		good = state.total_steps == 60 and is_equal_approx(float(state.energy_wh), 25.0) and state.scenario_id == "high_inc"
		var saved: Dictionary = StepEngine.request_action(state, "power_save")
		good = good and saved.ok and saved.allowed and saved.state.step_index == 1
	_case("KE1 catalog bridge and initial charge", good)
	var partial_charge_catalog: Dictionary = ke1.duplicate(true)
	partial_charge_catalog.components[3].initial_charge_fraction = 0.5
	var partial_built: Dictionary = Adapter.build_scenario(partial_charge_catalog, orbit_data)
	var partial_run: Dictionary = StepEngine.init_run(config, partial_built.scenario, "run_ke1_partial", "mission_ke1_partial") if partial_built.ok else {}
	_case("KE1 initial charge fraction is applied", partial_run.get("ok", false) and is_equal_approx(float(partial_run.state.energy_wh), 12.5))
	var mismatch: Dictionary = ke1.duplicate(true)
	mismatch.target_region_ids = ["other"]
	var rejected: Dictionary = Adapter.build_scenario(mismatch, orbit_data)
	_case("KE1 and HPC target IDs must align", not rejected.ok and rejected.error_code == "CATALOG_ID_MISMATCH")
	var wrong_contract: Dictionary = ke1.duplicate(true)
	wrong_contract.contract_revision = "draft"
	var contract_rejected: Dictionary = Adapter.build_scenario(wrong_contract, orbit_data)
	_case("KE1 contract revision is checked", not contract_rejected.ok and contract_rejected.error_code == "UNSUPPORTED_KE1_CONTRACT")

func _test_abort_run(catalog: Dictionary) -> void:
	var initialized: Dictionary = StepEngine.init_run(_config(), catalog, "run_abort", "mission_abort")
	var starting: Dictionary = initialized.state
	starting.step_index = 2
	starting.observations_completed = 1
	starting.stored_data_mb = 8.0
	var result: Dictionary = StepEngine.abort_run(starting, "Operator ended the run")
	var state: Dictionary = result.get("state", {})
	var event: Dictionary = result.events[0] if result.get("events", []).size() == 1 else {}
	_case("abort preserves progress and emits terminal event", result.get("ok", false) and state.phase == "finished" and state.run_status == "aborted" and state.step_index == 2 and state.observations_completed == 1 and is_equal_approx(float(state.stored_data_mb), 8.0) and state.terminal_reason == "Operator ended the run" and event.get("type") == "mission_aborted" and event.get("event_id") == "evt_000")
	var blank: Dictionary = StepEngine.abort_run(starting, "  ")
	_case("abort requires a reason", not blank.get("ok", false) and blank.error.code == "MISSING_ABORT_REASON")
	var repeated: Dictionary = StepEngine.abort_run(state, "Again")
	_case("terminal run cannot be aborted twice", not repeated.get("ok", false) and repeated.error.code == "MISSION_FINISHED")

func _test_ke1_readiness_integration() -> void:
	var loaded: Dictionary = Ke1CatalogLoader.load_catalogs()
	if not loaded.get("ok", false):
		_case("real KE1 catalogs load with HPC orbit metadata", false)
		return
	_case("real KE1 catalogs load with HPC orbit metadata", loaded.catalogs.has("orbit_catalog"))
	var valid_config: Dictionary = _read_json("res://tests/fixtures/valid_1u_feasible.json")
	var validation: Dictionary = Ke1MissionValidator.validate(valid_config, loaded.catalogs)
	var started: Dictionary = StepEngine.init_validated_run(valid_config, loaded.catalogs, "run_ke1_ready", "mission_ke1_ready")
	_case("KE1 ready result starts HPC run", validation.get("ready_to_launch", false) and started.get("ok", false) and started.validation_result.ready_to_launch and started.state.scenario_id == "high_inc" and is_equal_approx(float(started.state.energy_wh), float(validation.metrics.initial_energy_wh)))
	var overweight: Dictionary = _read_json("res://tests/fixtures/overweight_1u_1380g.json")
	var rejected: Dictionary = StepEngine.init_validated_run(overweight, loaded.catalogs, "run_ke1_rejected", "mission_ke1_rejected")
	_case("KE1 failed readiness cannot start HPC run", not rejected.get("ok", false) and rejected.error.code == "MISSION_NOT_READY" and not rejected.validation_result.ready_to_launch and not rejected.has("state"))
	var no_target_bundle: Dictionary = loaded.catalogs.duplicate(true)
	for orbit in no_target_bundle.orbit_catalog.orbits:
		if str(orbit.id) == "high_inc":
			orbit.target_windows.erase("equator")
	var unsuitable: Dictionary = Ke1MissionValidator.validate(valid_config, no_target_bundle)
	var blocked: Dictionary = StepEngine.init_validated_run(valid_config, no_target_bundle, "run_ke1_unsuitable", "mission_ke1_unsuitable")
	_case("KE1 readiness uses HPC target windows", not unsuitable.ready_to_launch and unsuitable.checks.target_orbit.status == "fail" and not blocked.get("ok", false) and blocked.validation_result.checks.target_orbit.status == "fail")
	var low_eq_config: Dictionary = _read_json("res://tests/fixtures/valid_low_eq.json")
	var low_eq: Dictionary = StepEngine.init_validated_run(low_eq_config, loaded.catalogs, "run_ke1_low_eq", "mission_ke1_low_eq")
	_case("KE1 readiness and HPC start support low_eq", low_eq.get("ok", false) and low_eq.state.scenario_id == "low_eq")

func _read_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("TEST SETUP FAILURE: could not read %s" % path)
		_failed += 1
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("TEST SETUP FAILURE: %s must contain a JSON object" % path)
		_failed += 1
		return {}
	return parsed

func _test_next_step_prediction(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [0], [0])
	var state: Dictionary = _initialized(_config(), catalog)
	state.energy_wh = 10.0
	state.stored_data_mb = 8.0
	var hours: float = float(_orbit(catalog, "low_eq").step_duration_hours)
	var observed: Dictionary = StepEngine.predict_next_step(state, "observe").prediction
	_case("prediction observes using Wh and decimal MB", _prediction_matches_execution(state, "observe") and is_equal_approx(float(observed.energy_wh_after), 10.0 + 10.0 * hours) and observed.stored_data_mb_after == 16.0 and observed.storage_remaining_mb_after == 34.0 and observed.delta_observations == 1 and is_equal_approx(float(observed.energy_generated_wh), 40.0 * hours) and is_equal_approx(float(observed.energy_consumed_wh), 30.0 * hours))
	var transmitted: Dictionary = StepEngine.predict_next_step(state, "transmit").prediction
	_case("prediction transmits hourly rate times step hours", _prediction_matches_execution(state, "transmit") and is_equal_approx(float(transmitted.data_transmitted_mb), 36.0 * hours) and is_equal_approx(float(transmitted.stored_data_mb_after), 8.0 - 36.0 * hours))
	state.stored_data_mb = 0.125
	var emptied: Dictionary = StepEngine.predict_next_step(state, "transmit").prediction
	_case("prediction limits downlink to stored data", _prediction_matches_execution(state, "transmit") and emptied.stored_data_mb_after == 0.0 and emptied.data_transmitted_mb == 0.125)
	state.energy_wh = state.battery_capacity_wh
	var capped: Dictionary = StepEngine.predict_next_step(state, "power_save").prediction
	_case("prediction clamps solar charging at capacity", _prediction_matches_execution(state, "power_save") and capped.energy_wh_after == state.battery_capacity_wh and capped.energy_clamped and capped.delta_energy_wh == 0.0)
	state.stored_data_mb = state.storage_capacity_mb
	var full: Dictionary = StepEngine.predict_next_step(state, "observe").prediction
	_case("prediction blocks storage overflow with zero deltas", _prediction_matches_execution(state, "observe") and full.blocked_code == "STORAGE_FULL" and full.elapsed_step_hours == 0.0 and full.next_step_index == state.step_index)
	state.stored_data_mb = 0.0
	_case("prediction handles empty downlink and unknown action", _prediction_matches_execution(state, "transmit") and StepEngine.predict_next_step(state, "transmit").prediction.blocked_code == "NO_DATA" and _prediction_matches_execution(state, "invalid") and StepEngine.predict_next_step(state, "invalid").prediction.blocked_code == "INVALID_ACTION")
	var eclipse: Dictionary = source_catalog.duplicate(true)
	_orbit(eclipse, "low_eq").sunlight_windows = []
	_orbit(eclipse, "low_eq").target_windows.equator = [0]
	_part(eclipse, "cam").requires_sunlight = false
	state = _initialized(_config(), eclipse)
	state.energy_wh = 0.01
	var depleted: Dictionary = StepEngine.predict_next_step(state, "power_save").prediction
	_case("prediction power_save clamps in eclipse and advances", _prediction_matches_execution(state, "power_save") and depleted.energy_wh_after == 0.0 and depleted.energy_clamped and depleted.next_step_index == 1 and depleted.energy_generated_wh == 0.0)
	var low_energy: Dictionary = StepEngine.predict_next_step(state, "observe").prediction
	_case("prediction low battery keeps energy and storage unchanged", _prediction_matches_execution(state, "observe") and low_energy.blocked_code == "LOW_BATTERY" and low_energy.energy_wh_after == state.energy_wh and low_energy.stored_data_mb_after == state.stored_data_mb)
	var replay_matches: bool = true
	var last_step_matches: bool = true
	for orbit_id in ["low_eq", "high_inc"]:
		state = _initialized(_config(orbit_id), source_catalog)
		while state.phase != "finished":
			for action in StepEngine.ACTIONS:
				replay_matches = _prediction_matches_execution(state, action) and replay_matches
			var action: String = "power_save"
			var available: Dictionary = StepEngine.get_available_actions(state).available_actions
			if available.observe.allowed:
				action = "observe"
			elif available.transmit.allowed:
				action = "transmit"
			if state.step_index == state.total_steps - 1:
				var final_prediction: Dictionary = StepEngine.predict_next_step(state, action).prediction
				last_step_matches = last_step_matches and final_prediction.will_finish and final_prediction.next_step_index == state.total_steps and final_prediction.phase_after == "finished" and final_prediction.run_status_after == "completed"
			state = StepEngine.request_action(state, action).state
		var finished: Dictionary = StepEngine.predict_next_step(state, "power_save").prediction
		replay_matches = _prediction_matches_execution(state, "power_save") and finished.blocked_code == "MISSION_FINISHED" and finished.step_duration_hours == 0.0 and not finished.will_finish and replay_matches
	_case("prediction equals execution throughout both orbit presets without input mutation", replay_matches)
	_case("prediction identifies final accepted step", last_step_matches)
	state = StepEngine.abort_run(_initialized(_config(), source_catalog), "Operator test abort").state
	var aborted: Dictionary = StepEngine.predict_next_step(state, "observe").prediction
	_case("prediction preserves aborted terminal status", _prediction_matches_execution(state, "observe") and aborted.blocked_code == "MISSION_FINISHED" and aborted.run_status_after == "aborted" and aborted.elapsed_step_hours == 0.0)
	var invalid: Dictionary = StepEngine.predict_next_step({}, "observe")
	state = _initialized(_config(), source_catalog)
	state.energy_wh = NAN
	var nonfinite: Dictionary = StepEngine.predict_next_step(state, "observe")
	_case("prediction rejects malformed and nonfinite state", not invalid.ok and invalid.error.code == "INVALID_MISSION_STATE" and not nonfinite.ok and nonfinite.error.code == "INVALID_MISSION_STATE")

func _prediction_matches_execution(state: Dictionary, action: String) -> bool:
	var before: Dictionary = state.duplicate(true)
	var predicted: Dictionary = StepEngine.predict_next_step(state, action)
	var repeated: Dictionary = StepEngine.predict_next_step(state, action)
	if not predicted.get("ok", false) or predicted != repeated or state != before:
		return false
	var actual: Dictionary = StepEngine.request_action(state, action)
	if not actual.get("ok", false) or state != before:
		return false
	var p: Dictionary = predicted.prediction
	var s: Dictionary = actual.state
	if p.allowed != actual.allowed or p.next_step_index != s.step_index or p.phase_after != s.phase or p.run_status_after != s.run_status:
		return false
	if p.run_id != state.run_id or p.mission_id != state.mission_id or p.scenario_id != state.scenario_id or p.step_index != state.step_index:
		return false
	for key in ["energy_wh", "stored_data_mb", "returned_data_mb", "observations_completed"]:
		if p[key + "_after"] != s[key]:
			return false
	var event: Dictionary = actual.events[0]
	for key in ["delta_energy_wh", "delta_stored_data_mb", "delta_returned_data_mb", "delta_observations", "energy_generated_wh", "energy_consumed_wh", "energy_clamped", "data_added_mb", "data_transmitted_mb"]:
		if p[key] != event.get(key, false if key == "energy_clamped" else 0.0):
			return false
	if not p.allowed and (p.blocked_code != event.code or p.reason != event.message):
		return false
	return true

func _catalog() -> Dictionary:
	var file := FileAccess.open("res://data/fixtures/hpc_catalog.json", FileAccess.READ)
	return JSON.parse_string(file.get_as_text())

func _config(orbit_id: String = "low_eq") -> Dictionary:
	return {
		"schema_version": 1,
		"contract_version": Adapter.CONTRACT_VERSION,
		"mission": {"title": "HPC test", "objective": "imaging", "target_region": "equator", "required_observations": 5, "required_returned_data_mb": 1.0, "duration_orbits": 1, "budget_credits": 100},
		"design": {"bus_id": "core_bus", "instrument_id": "cam", "solar_id": "solar40", "battery_id": "bat60", "radio_id": "radio_base", "storage_id": "store50", "launch_profile_id": "cubesat_101_1u_sample", "launcher_id": "small_launch", "orbit_id": orbit_id}
	}

func _initialized(config: Dictionary, catalog: Dictionary) -> Dictionary:
	var result: Dictionary = StepEngine.initialize(config, catalog)
	if not result.get("ok", false):
		push_error("TEST SETUP FAILURE: %s: %s" % [result.get("error_code", "UNKNOWN"), result.get("error_message", "")])
		_failed += 1
		return {"schema_version": 1, "contract_version": Adapter.CONTRACT_VERSION, "scenario_id": "invalid", "step_index": 0, "total_steps": 1, "phase": "operating", "energy_wh": 0.0, "battery_capacity_wh": 1.0, "stored_data_mb": 0.0, "storage_capacity_mb": 1.0, "returned_data_mb": 0.0, "observations_completed": 0, "available_actions": [], "event_log": [], "config_snapshot": config}
	return result.state

func _catalog_with_windows(source: Dictionary, orbit_id: String, target_steps: Array, contact_steps: Array) -> Dictionary:
	var catalog: Dictionary = source.duplicate(true)
	for orbit in catalog.orbits:
		if str(orbit.id) == orbit_id:
			orbit.sunlight_windows = [0, 1, 2, 3, 4, 5]
			orbit.target_windows.equator = target_steps.duplicate()
			orbit.ground_contact_windows = contact_steps.duplicate()
		return catalog
	return catalog

func _set_part(catalog: Dictionary, part_id: String, key: String, value: float) -> void:
	for part in catalog.parts:
		if str(part.id) == part_id:
			part[key] = value
			return

func _part(catalog: Dictionary, part_id: String) -> Dictionary:
	for part in catalog.parts:
		if str(part.id) == part_id:
			return part
	return {}

func _orbit(catalog: Dictionary, orbit_id: String) -> Dictionary:
	for orbit in catalog.orbits:
		if str(orbit.id) == orbit_id:
			return orbit
	return {}

func _planner() -> GDScript:
	return load("res://core/OrbitPlanner.gd")

func _case(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("TEST FAILURE: %s" % label)
