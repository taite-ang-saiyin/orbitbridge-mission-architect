extends SceneTree
## Current-v1 example audit only; not SE storage/UI or a production A/B comparator.
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Steps = preload("res://core/MissionStepEngine.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
var passed: int = 0
var failed: int = 0
var evidence: Dictionary = {"base_main": "dce75db845f6c494b8c25c9028dd9c0648aabd91", "scope": "SUPPORTED_V1_IMAGING_EXAMPLES_NOT_NEW_GOAL_INTEGRATION", "cases": {}}
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1; printerr("FAIL: " + label)
func json_file(path: String) -> Dictionary: return JSON.parse_string(FileAccess.get_file_as_string(path))
func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2: printerr("Pass example/output folders after --"); quit(1); return
	var base: String = args[0]; var output: String = args[1]
	DirAccess.make_dir_recursive_absolute(output)
	var a: Dictionary = json_file(base.path_join("design-a.v1.json"))
	var b: Dictionary = json_file(base.path_join("design-b.v1.json"))
	var normalized_b: Dictionary = b.duplicate(true); normalized_b.design.radio_id = a.design.radio_id
	check(a == normalized_b and a.design.radio_id != b.design.radio_id, "Only design.radio_id differs")
	var plan: Dictionary = json_file(base.path_join("action-plan.json"))
	var loaded: Dictionary = Runtime.load_game_catalogs()
	check(loaded.ok, "Active runtime catalogs load")
	if not loaded.ok: quit(1); return
	var catalogs_before: String = JSON.stringify(loaded.catalogs)
	var baseline_before: String = ""
	for name in ["A", "B"]:
		var config: Dictionary = a if name == "A" else b
		var config_before: String = JSON.stringify(config)
		var validation: Dictionary = Validator.validate(config, loaded.catalogs)
		check(validation.ready_to_launch and validation.checks.size() == 8, name + ": all eight readiness gates pass")
		var trace: Dictionary = simulate(config, loaded.catalogs, plan, name)
		check(trace.get("ok", false), name + ": identical scheduled actions all accepted")
		if not trace.get("ok", false): continue
		trace.config = config.duplicate(true); trace.validation = validation
		trace.catalogs_snapshot = loaded.catalogs.duplicate(true)
		var physical_copy: Dictionary = trace.duplicate(true)
		var repeated: Dictionary = simulate(config, loaded.catalogs, plan, name)
		check(trace.final_state == repeated.final_state and trace.events == repeated.events, name + ": native replay deterministic")
		check(trace.resources_bounded and trace.inputs_preserved, name + ": resources bounded and action inputs immutable")
		var reply: Dictionary = Results.evaluate_trace(trace)
		check(reply.get("ok", false), name + ": real existing Imaging evaluator returns a bound report")
		if not reply.get("ok", false): continue
		check(trace.final_state.config_snapshot == config and trace.events == trace.final_state.event_log, name + ": exact frozen config/event binding")
		check(reply.report.run_id == trace.final_state.run_id and reply.report.mission_id == trace.final_state.mission_id, name + ": report identity matches execution")
		check(reply.report.comparison == null, name + ": no invented official comparison object")
		check(trace.final_state.run_status == "completed" and trace.final_state.step_index == 30, name + ": completed terminal state")
		check(trace.final_state.observations_completed == 2, name + ": both captures made")
		check(config_before == JSON.stringify(config) and catalogs_before == JSON.stringify(loaded.catalogs), name + ": config/catalog inputs unchanged")
		check(trace.final_state == physical_copy.final_state and trace.events == physical_copy.events, name + ": report adapter preserves native evidence")
		var tampered: Dictionary = trace.duplicate(true)
		tampered.config.mission.required_returned_data_mb = 12
		var rejected: Dictionary = Results.evaluate_trace(tampered)
		check(not rejected.ok and not rejected.has("report"), name + ": mismatched requirements cannot bind an old execution")
		evidence.cases[name] = trace.duplicate(true)
		if name == "A": baseline_before = JSON.stringify(evidence.cases.A)
		else: check(baseline_before == JSON.stringify(evidence.cases.A), "Constructing B leaves saved A fixture bytes unchanged (not a UI/storage test)")
		write(output.path_join("run-" + name.to_lower() + ".json"), trace)
	if evidence.cases.size() == 2:
		var left: Dictionary = evidence.cases.A; var right: Dictionary = evidence.cases.B
		check(left.final_state.run_id != right.final_state.run_id, "A/B have distinct run IDs")
		check(left.final_state.scenario_snapshot == right.final_state.scenario_snapshot and left.catalogs_snapshot == right.catalogs_snapshot, "Both frozen scenario/catalog snapshots match")
		check(left.accepted_actions == right.accepted_actions, "Actual accepted action histories are identical")
		check(absf(left.final_state.returned_data_mb - 15.4666666656) < 0.000001 and absf(right.final_state.returned_data_mb - 24) < 0.000001, "Measured returned data matches expected radio capacities")
		check(left.evaluation.report.status == "partial" and left.evaluation.report.score == 82 and right.evaluation.report.status == "success" and right.evaluation.report.score == 100, "Actual existing Imaging reports are partial/82 and success/100")
		check(right.validation.metrics.total_mass_g - left.validation.metrics.total_mass_g == 60 and right.validation.metrics.total_cost_credits - left.validation.metrics.total_cost_credits == 7, "Fast radio costs 60 g and 7 credits more")
		check(right.final_state.energy_wh < left.final_state.energy_wh, "Faster radio uses more energy under the same two transmissions")
		for name in ["A", "B"]:
			var trace: Dictionary = evidence.cases[name]
			evidence[name] = {"run_id": trace.final_state.run_id, "mass_g": trace.validation.metrics.total_mass_g, "cost_credits": trace.validation.metrics.total_cost_credits, "returned_data_mb": trace.final_state.returned_data_mb, "remaining_energy_wh": trace.final_state.energy_wh, "minimum_energy_wh": trace.minimum_energy_wh, "status": trace.evaluation.report.status, "score": trace.evaluation.report.score}
	evidence.erase("cases")
	evidence.passed = passed; evidence.failed = failed
	write(output.path_join("summary.json"), evidence)
	print("K27 A/B radio preparation: %d checks passed; %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)
func simulate(config: Dictionary, catalogs: Dictionary, plan: Dictionary, name: String) -> Dictionary:
	var init: Dictionary = Steps.init_validated_run(config, catalogs, "run_k27_" + name, "mission_k27_radio_lab")
	if not init.ok: return init
	var state: Dictionary = init.state; var samples: Array = []; var actions: Array = []
	var observe: Array = plan.observe_steps.map(func(v): return int(v)); var transmit: Array = plan.transmit_steps.map(func(v): return int(v))
	var bounded: bool = true; var unchanged: bool = true; var minimum: float = state.energy_wh
	for step in range(int(state.total_steps)):
		var action: String = "observe" if step in observe else ("transmit" if step in transmit else "power_save")
		var before: String = JSON.stringify(state)
		var reply: Dictionary = Steps.request_action(state, action)
		unchanged = unchanged and before == JSON.stringify(state)
		if not reply.get("ok", false) or not reply.get("allowed", false): return {"ok": false, "step": step, "reply": reply}
		state = reply.state
		bounded = bounded and state.energy_wh >= 0 and state.energy_wh <= state.battery_capacity_wh and state.stored_data_mb >= 0 and state.stored_data_mb <= state.storage_capacity_mb
		minimum = minf(minimum, state.energy_wh)
		actions.append({"step_index": step, "action": action})
		samples.append({"step_index": state.step_index, "energy_wh": state.energy_wh, "stored_data_mb": state.stored_data_mb, "returned_data_mb": state.returned_data_mb, "observations_completed": state.observations_completed})
	return {"ok": state.phase == "finished", "final_state": state, "events": state.event_log.duplicate(true), "accepted_actions": actions, "telemetry": samples, "minimum_energy_wh": minimum, "resources_bounded": bounded, "inputs_preserved": unchanged, "plan": plan.duplicate(true)}
func write(path: String, value: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null: check(false, "Cannot write evidence: " + path); return
	file.store_string(JSON.stringify(value, "  ")); file.close()
