extends SceneTree

const StepEngine = preload("res://core/MissionStepEngine.gd")
const Adapter = preload("res://core/HPCContractAdapter.gd")
const LegacySimulator = preload("res://core/MissionSimulator.gd")
var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	var catalog: Dictionary = _catalog()
	_test_successful_observe(catalog)
	_test_observe_outside_window(catalog)
	_test_observe_storage_full(catalog)
	_test_observe_low_energy(catalog)
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
	_test_power_save_clamps_and_continues(catalog)
	_test_ke1_catalog_bridge()
	_test_abort_run(catalog)
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

func _test_successful_transmit(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = _catalog_with_windows(source_catalog, "low_eq", [], [0])
	var state: Dictionary = _initialized(_config(), catalog)
	state.stored_data_mb = 8.0
	var result: Dictionary = StepEngine.execute_step(state, "transmit", catalog)
	_case("successful transmit", result.allowed and float(result.state.returned_data_mb) > 0.0 and float(result.state.stored_data_mb) < 8.0 and float(result.event.data_transmitted_mb) > 0.0)

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
	_case("battery remains within capacity", result.allowed and float(result.state.energy_wh) <= float(result.state.battery_capacity_wh) and float(result.state.energy_wh) >= 0.0)

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
	_case("mission finishes at total_steps", success and int(state.step_index) == int(state.total_steps) and state.event_log.back().code == "MISSION_FINISHED")

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

func _test_v1_run_identity_and_event_contract(catalog: Dictionary) -> void:
	var initialized: Dictionary = StepEngine.init_run(_config(), catalog, "run_v1_01", "mission_v1_01")
	var state: Dictionary = initialized.state
	var blocked: Dictionary = StepEngine.request_action(state, "observe")
	var blocked_event: Dictionary = blocked.events[0]
	var identity_ok: bool = state.run_id == "run_v1_01" and state.mission_id == "mission_v1_01"
	var event_ok: bool = blocked_event.event_id == "evt_000" and blocked_event.run_id == state.run_id and blocked_event.mission_id == state.mission_id and blocked_event.type == "action_blocked" and blocked_event.has("delta_energy_wh") and blocked_event.has("delta_stored_data_mb") and blocked_event.has("delta_returned_data_mb") and blocked_event.has("delta_observations")
	_case("v1 run identity and event schema", initialized.ok and identity_ok and event_ok and blocked.state.step_index == state.step_index)
	var actions: Dictionary = StepEngine.get_available_actions(state)
	_case("v1 action availability map", actions.ok and actions.available_actions.has("observe") and actions.available_actions.has("transmit") and actions.available_actions.has("power_save"))

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

func _planner() -> GDScript:
	return load("res://core/OrbitPlanner.gd")

func _case(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("TEST FAILURE: %s" % label)
