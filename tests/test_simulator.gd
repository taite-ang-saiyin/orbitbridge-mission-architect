extends SceneTree

const Simulator = preload("res://core/MissionSimulator.gd")
var _failed: bool = false

func _initialize() -> void:
	var catalog: Dictionary = _catalog()
	_test_radio_fixture(catalog)
	_test_energy_boundaries(catalog)
	_test_windows_and_storage(catalog)
	_test_priority_overlap(catalog)
	_test_invariants_and_event_contract(catalog)
	_test_replay_and_max_duration(catalog)
	if _failed:
		quit(1)
	else:
		quit(0)

func _catalog() -> Dictionary:
	var file := FileAccess.open("res://data/fixtures/hpc_catalog.json", FileAccess.READ)
	return JSON.parse_string(file.get_as_text())

func _input(radio_id: String = "radio_base", policy: String = "observe_first") -> Dictionary:
	return {
		"schema_version": 1,
		"catalog_version": "demo-1",
		"model_version": "slots-1",
		"brief": {"name": "Radio fixture", "description": "", "objective_id": "capture", "target_ids": ["equator"], "required_obs": 5, "duration_orbits": 3, "budget_cr": 100},
		"design": {"instrument_id": "cam", "bus_id": "core_bus", "battery_id": "bat60", "solar_id": "solar40", "storage_id": "store50", "radio_id": radio_id, "launcher_id": "small_launch", "orbit_id": "low_eq", "policy": policy}
	}

func _run(input: Dictionary, catalog: Dictionary) -> Dictionary:
	var result: Dictionary = Simulator.simulate(input, catalog)
	if not _expect(result.get("ok", false), str(result.get("error", "run failed"))):
		return {"ok": false, "metrics": {}, "events": [], "state": {}, "slot_count": 0}
	for key in ["metrics", "events", "state", "slot_count", "slot_seconds", "status"]:
		if not _expect(result.has(key), "successful trace missing %s" % key):
			return {"ok": false, "metrics": {}, "events": [], "state": {}, "slot_count": 0}
	return result

func _test_radio_fixture(catalog: Dictionary) -> void:
	var fixture_file := FileAccess.open("res://data/fixtures/hpc_golden_radio_ab.json", FileAccess.READ)
	var fixture: Dictionary = JSON.parse_string(fixture_file.get_as_text())
	var run_a_input: Dictionary = fixture.duplicate(true)
	run_a_input.erase("expected")
	run_a_input.design.radio_id = str(fixture.expected.run_a.radio_id)
	var run_b_input: Dictionary = fixture.duplicate(true)
	run_b_input.erase("expected")
	run_b_input.design.radio_id = str(fixture.expected.run_b.radio_id)
	var run_a: Dictionary = _run(run_a_input, catalog)
	var run_b: Dictionary = _run(run_b_input, catalog)
	for key in ["captured", "delivered", "returned_kb", "buffer_kb", "min_battery_ws", "cost_cr", "mass_kg"]:
		_expect(run_a.metrics[key] == fixture.expected.run_a[key])
		_expect(run_b.metrics[key] == fixture.expected.run_b[key])
	_expect(round(float(run_a.metrics.min_battery_ws) / 3600.0 * 100.0) / 100.0 == 52.92)
	_expect(round(float(run_b.metrics.min_battery_ws) / 3600.0 * 100.0) / 100.0 == 51.07)
	_expect(run_a.metrics.returned_kb + run_a.metrics.buffer_kb == run_a.metrics.captured * 8000)
	_expect(run_b.metrics.returned_kb + run_b.metrics.buffer_kb == run_b.metrics.captured * 8000)
	_expect(run_a.metrics.delivered_by_target.equator == 2)
	_expect(run_b.metrics.delivered_by_target.equator == 5)
	_expect(run_a.state.packet_queue.size() == 3)
	_expect(run_a.state.packet_queue[0].remaining_kb == 7380)
	_expect(run_b.state.packet_queue.is_empty())

func _test_energy_boundaries(source_catalog: Dictionary) -> void:
	var exact_catalog: Dictionary = source_catalog.duplicate(true)
	var orbit: Dictionary = exact_catalog.orbits[0]
	orbit.slot_seconds = 1
	orbit.target_windows.equator = [0]
	_set_part(exact_catalog, "bat60", "capacity_ws", 10)
	_set_part(exact_catalog, "core_bus", "idle_w", 0)
	_set_part(exact_catalog, "cam", "observe_w", 10)
	_set_part(exact_catalog, "solar40", "output_w", 0)
	var exact_input := _input()
	exact_input.brief.required_obs = 1
	var exact: Dictionary = _run(exact_input, exact_catalog)
	_expect(exact.metrics.captured == 1 and exact.metrics.min_battery_ws == 0)
	_expect(exact.status == "completed")

	var fallback_catalog: Dictionary = source_catalog.duplicate(true)
	_set_part(fallback_catalog, "bat60", "capacity_ws", 5)
	_set_part(fallback_catalog, "core_bus", "idle_w", 0)
	_set_part(fallback_catalog, "cam", "observe_w", 6)
	_set_part(fallback_catalog, "solar40", "output_w", 0)
	var fallback: Dictionary = _run(_input(), fallback_catalog)
	_expect(fallback.status == "completed" and fallback.metrics.captured == 0)
	_expect(_has_code(fallback.events, "SKIP_POWER"))
	_expect(not _has_code(fallback.events, "POWER_DEPLETED"))

	var dead_catalog: Dictionary = source_catalog.duplicate(true)
	_set_part(dead_catalog, "bat60", "capacity_ws", 5)
	_set_part(dead_catalog, "core_bus", "idle_w", 6)
	_set_part(dead_catalog, "solar40", "output_w", 0)
	var depleted: Dictionary = _run(_input(), dead_catalog)
	_expect(depleted.status == "depleted" and depleted.slot_count == 1)
	_expect(depleted.metrics.final_battery_ws == 0)
	_expect(_count_code(depleted.events, "POWER_DEPLETED") == 1)

func _test_windows_and_storage(source_catalog: Dictionary) -> void:
	var no_window: Dictionary = source_catalog.duplicate(true)
	no_window.orbits[0].target_windows = {}
	var none: Dictionary = _run(_input(), no_window)
	_expect(none.metrics.captured == 0)

	var too_small: Dictionary = source_catalog.duplicate(true)
	_set_part(too_small, "store50", "capacity_kb", 7999)
	var stored: Dictionary = _run(_input(), too_small)
	_expect(stored.metrics.captured == 0)
	_expect(_has_code(stored.events, "SKIP_STORAGE"))
	_expect(stored.metrics.peak_buffer_kb <= 7999)

func _test_priority_overlap(source_catalog: Dictionary) -> void:
	var catalog: Dictionary = source_catalog.duplicate(true)
	catalog.orbits[0].target_windows.equator = [2, 5]
	catalog.orbits[0].contact_slots = [5, 8]
	var observe_first: Dictionary = _run(_input("radio_base", "observe_first"), catalog)
	_expect(_slot_action(observe_first.events, 5) == "observe")
	var transmit_first: Dictionary = _run(_input("radio_base", "downlink_first"), catalog)
	_expect(_slot_action(transmit_first.events, 5) == "transmit")

func _test_invariants_and_event_contract(source_catalog: Dictionary) -> void:
	var result: Dictionary = _run(_input(), source_catalog)
	_expect(result.metrics.returned_kb + result.metrics.buffer_kb == result.metrics.captured * 8000)
	_expect(result.metrics.delivered <= result.metrics.captured)
	_expect(result.metrics.peak_buffer_kb <= 50000)
	_expect(result.metrics.final_battery_ws >= 0 and result.metrics.final_battery_ws <= 216000)
	_expect(result.metrics.min_battery_ws >= 0 and result.metrics.min_battery_ws <= 216000)
	_expect(result.metrics.delivered_by_target.equator == result.metrics.delivered)
	_expect(_count_code(result.events, "DEPLOY") == 1)
	var observation_ids: Dictionary = {}
	var tx_delivered_count := 0
	for event in result.events:
		if event.code == "OBSERVE":
			_expect(not observation_ids.has(event.params.observation_id))
			observation_ids[event.params.observation_id] = true
		elif event.code == "TX":
			tx_delivered_count += int(event.params.delivered_now)
	_expect(observation_ids.size() == result.metrics.captured)
	_expect(tx_delivered_count == result.metrics.delivered)
	var last_seq := -1
	for event in result.events:
		_expect(event.seq == last_seq + 1)
		last_seq = event.seq
		_expect(event.has("slot") and event.has("t_s") and event.has("code") and event.has("params"))
		if event.slot == -1:
			_expect(event.t_s == 0)
		else:
			_expect(event.t_s == (event.slot + 1) * result.slot_seconds)
		if event.code == "LAUNCH" or event.code == "DEPLOY":
			_expect(event.slot == -1 and event.t_s == 0)

func _test_replay_and_max_duration(catalog: Dictionary) -> void:
	var input := _input("radio_upgraded")
	var first: Dictionary = _run(input, catalog)
	var second: Dictionary = _run(input, catalog)
	_expect(first == second)
	input.brief.duration_orbits = 9
	var long_run: Dictionary = _run(input, catalog)
	_expect(long_run.slot_count == 90)

func _set_part(catalog: Dictionary, part_id: String, key: String, value: int) -> void:
	for part in catalog.parts:
		if part.id == part_id:
			part[key] = value
			return

func _has_code(events: Array, wanted: String) -> bool:
	return _count_code(events, wanted) > 0

func _count_code(events: Array, wanted: String) -> int:
	var count := 0
	for event in events:
		if event.code == wanted:
			count += 1
	return count

func _slot_action(events: Array, slot_index: int) -> String:
	for event in events:
		if event.code == "SLOT_STATE" and event.slot == slot_index:
			return str(event.params.action)
	return ""

func _expect(condition: bool, message: String = "assertion failed") -> bool:
	if not condition:
		_failed = true
		push_error("TEST FAILURE: %s" % message)
		return false
	return true
