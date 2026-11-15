extends SceneTree
## Public callable comparison against current SE records and existing native modules.
const Comparison = preload("res://scripts/evaluation/mission_comparison.gd")
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
const Catalog = preload("res://data/mock/DesignCatalog.gd")
var passed: int = 0
var failed: int = 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL " + label)

func measure(reply: Dictionary, id: String) -> Dictionary:
	for item: Dictionary in reply.comparison.get("measures", []):
		if item.id == id: return item
	return {}

func native_record(required_mb: float = 12.0) -> Dictionary:
	var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
	draft.name = "Native callable comparison"
	draft.targets = ["Equator"]
	draft.observations = 1
	draft.duration = 1
	draft.required_returned_data_mb = required_mb
	draft.run_session_id = "ke2_callable_comparison"
	var run: Dictionary = Runtime.launch(draft)
	check(run.get("ok", false), "extra native launch")
	if not run.get("ok", false): return {}
	var reply: Dictionary = Results.publish(draft, run.trace.final_state)
	check(reply.get("ok", false), "extra native publication")
	return draft.evaluation_store.history[-1].duplicate(true) if reply.get("ok", false) else {}

func operations(record: Dictionary) -> Dictionary:
	var requests: Array = []
	for event: Dictionary in record.state.event_log:
		if event.get("type") in ["action_accepted", "action_blocked"]: requests.append({"step_index": event.step_index, "action": event.action})
	return {"policy": {"id": "observe_first_v1", "version": 1, "parameters": {}}, "manual_requests": [], "requested_actions": requests}

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): printerr("FAIL callable comparison timeout"); quit(1))
	var records: Array = []
	for fast in [false, true]:
		var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
		draft.name = "Native callable comparison"
		draft.targets = ["Equator"]
		draft.observations = 1
		draft.required_returned_data_mb = 12
		draft.duration = 1
		draft.run_session_id = "ke2_callable_comparison"
		if fast: draft.engineering_parts = {"radio": "radio_fast"}
		var run: Dictionary = Runtime.launch(draft)
		check(run.get("ok", false), "native validated launch " + str(fast))
		if not run.get("ok", false): quit(1); return
		var reply: Dictionary = Results.publish(draft, run.trace.final_state)
		check(reply.get("ok", false), "native report publication " + str(fast))
		if not reply.get("ok", false): quit(1); return
		records.append(draft.evaluation_store.history[-1].duplicate(true))
	var a: Dictionary = records[0]
	var b: Dictionary = records[1]
	var original: Array = records.duplicate(true)
	var result: Dictionary = Comparison.compare_runs(a, b)
	check(result.get("ok", false) and result.get("comparison", {}).get("eligible", false), "current SE records yield callable comparison")
	if not result.get("ok", false) or not result.get("comparison", {}).get("eligible", false): printerr(result); quit(1); return
	check(not result.has("proposal") and not result.comparison.has("proposal"), "callable v1 result is separate from expansion prototypes")
	check(result.comparison.a_execution_key == a.execution_key and result.comparison.b_execution_key == b.execution_key and result.comparison.a_mission_id == a.state.mission_id and result.comparison.b_mission_id == b.state.mission_id, "comparison output binds both identities and execution keys")
	check(result.comparison.classification == null, "absent requested policy cannot claim a controlled Design label")
	check(absf(float(measure(result, "returned_data_mb").delta_b_minus_a) - 4.6133333328) < 1e-8, "native callable MB delta")
	check(measure(result, "score").delta_b_minus_a == 19, "native callable score delta")
	check(measure(result, "total_mass_g").delta_b_minus_a == 60 and measure(result, "total_cost_credits").delta_b_minus_a == 7, "native callable mass/cost deltas")
	check(measure(result, "lowest_battery_wh").delta_b_minus_a == null, "unratified optional sampling stays unavailable")
	check(Comparison.compare_runs(a, b) == result and records == original, "callable deterministic/input preserving")
	check(measure(Comparison.compare_runs(a, a), "returned_data_mb").delta_b_minus_a == 0, "identical callable comparison")
	check(absf(float(measure(Comparison.compare_runs(b, a), "returned_data_mb").delta_b_minus_a) + 4.6133333328) < 1e-8, "reversed callable comparison")
	var different: Dictionary = native_record(13.0)
	if different.is_empty(): quit(1); return
	check(not Comparison.compare_runs(a, different).comparison.eligible, "different actual native goal makes pair unavailable")
	var controlled_a: Dictionary = a.duplicate(true)
	var controlled_b: Dictionary = b.duplicate(true)
	controlled_a.operations = operations(a)
	controlled_b.operations = operations(b)
	check(Comparison.compare_runs(controlled_a, controlled_b).comparison.classification == "Design", "explicit validated requested policy enables Design classification")
	# Labeled manual-context fixture: request must exist in the recorded history.
	controlled_b.operations.manual_requests = [{"step_index": 0, "action": "power_save"}]
	check(Comparison.compare_runs(controlled_a, controlled_b).comparison.classification == "Design + operations", "validated manual-context fixture enables combined classification")
	controlled_b.operations.requested_actions[0].action = "observe"
	check(Comparison.compare_runs(controlled_a, controlled_b).comparison.classification == null, "contradictory operations context cannot classify Design")
	check(not Comparison.compare_runs(null, b).ok, "malformed comparison record structured error")
	var changed: Dictionary = b.duplicate(true)
	changed.execution_key = "wrong"
	check(not Comparison.compare_runs(a, changed).ok, "mismatched comparison key error")
	changed = b.duplicate(true)
	changed.report.score = 99
	check(not Comparison.compare_runs(a, changed).ok, "report score must reproduce through agreed evaluator")
	changed = b.duplicate(true)
	changed.report.schema_version = 2
	check(not Comparison.compare_runs(a, changed).comparison.eligible, "unratified report-v2 contract unavailable")
	changed.report.schema_version = true
	check(not Comparison.compare_runs(a, changed).ok, "boolean report version malformed")
	changed = b.duplicate(true)
	changed.state.run_status = "aborted"
	check(not Comparison.compare_runs(a, changed).comparison.eligible, "aborted comparison unavailable")
	changed = b.duplicate(true)
	changed.state.phase = "operating"
	check(not Comparison.compare_runs(a, changed).comparison.eligible, "unfinished comparison unavailable")
	for objective in ["survey", "communication", "weather_monitoring", "unknown"]:
		var config: Dictionary = b.state.config_snapshot.duplicate(true)
		var state: Dictionary = b.state.duplicate(true)
		config.mission.objective = objective
		state.config_snapshot = config.duplicate(true)
		var evaluated: Dictionary = Evaluator.evaluate_mission(config, state, state.event_log)
		check(not evaluated.ok and evaluated.error.field_path == "config.mission.objective", "unapproved objective cannot inherit Imaging score " + objective)
	var packet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/expansion-plan/evidence/ke2-handoff-current.json"))
	var preimages: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/expansion-plan/evidence/execution-key-preimages-review.json"))
	var transported: Array = []
	for name in ["imaging_a", "imaging_b"]:
		var item: Dictionary = packet.cases[name]
		transported.append({"state": item.trace.final_state, "report": item.evaluation.report, "validation": item.trace.validation, "execution_key": item.execution_key})
	check(not Comparison.compare_runs(transported[0], transported[1]).ok, "JSON roundtrip mismatch is not silently rewritten")
	for index in 2:
		var name: String = "imaging_a" if index == 0 else "imaging_b"
		transported[index].key_preimage_utf8 = preimages.cases[name].preimage_utf8
	var transported_reply: Dictionary = Comparison.compare_runs(transported[0], transported[1])
	check(transported_reply.get("ok", false) and transported_reply.get("comparison", {}).get("eligible", false), "verified original hash bytes support transported history")
	if not transported_reply.get("ok", false): printerr(transported_reply)
	print("KE2 CALLABLE COMPARISON: %d passed; %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
