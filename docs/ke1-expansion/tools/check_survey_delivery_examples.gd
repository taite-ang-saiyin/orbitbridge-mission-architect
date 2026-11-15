extends SceneTree
## K26 preparation audit. No production evaluator or new-goal report is implemented.
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Steps = preload("res://core/MissionStepEngine.gd")
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
var passed: int = 0
var failed: int = 0
var evidence: Dictionary = {"status": "PREPARATION_EVIDENCE_ONLY_OWNER_REVIEW_PENDING", "base_main": "dce75db845f6c494b8c25c9028dd9c0648aabd91", "cases": {}, "official_survey_score": null}
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1; printerr("FAIL: " + label)
func read_json(path: String) -> Variant: return JSON.parse_string(FileAccess.get_file_as_string(path))
func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2: printerr("Pass example folder and output folder after --"); quit(1); return
	var examples: String = args[0]; var output: String = args[1]
	DirAccess.make_dir_recursive_absolute(output)
	var plans: Dictionary = read_json(examples.path_join("plans.json"))
	var loaded: Dictionary = Runtime.load_game_catalogs()
	check(loaded.ok, "Current runtime-extended catalogs load")
	if not loaded.ok: quit(1); return
	var candidate: Dictionary = read_json(examples.path_join("two-target-survey.proposed-v2.json"))
	check(not Validator.validate(candidate, loaded.catalogs).ready_to_launch, "Proposed v2 example is still rejected by production boundary")
	for plan in plans.cases:
		var config: Dictionary = read_json(examples.path_join(plan.config_file))
		check(config.schema_version == 1 and config.mission.objective == "survey", plan.id + ": actual Survey input, no Imaging substitution")
		var config_before: String = JSON.stringify(config); var catalogs_before: String = JSON.stringify(loaded.catalogs)
		var validation: Dictionary = Validator.validate(config, loaded.catalogs)
		check(validation.ready_to_launch and validation.checks.size() == 8, plan.id + ": all eight readiness checks pass")
		check(validation.metrics.total_mass_g == (1120 if config.design.radio_id == "radio_fast" else 1060) and validation.metrics.total_cost_credits == (89 if config.design.radio_id == "radio_fast" else 82), plan.id + ": expected physical totals")
		var trace: Dictionary = simulate(config, loaded.catalogs, plan)
		check(trace.get("ok", false), plan.id + ": every scheduled action accepted and native run completed")
		if not trace.get("ok", false): continue
		var state: Dictionary = trace.final_state
		check(config_before == JSON.stringify(config) and catalogs_before == JSON.stringify(loaded.catalogs), plan.id + ": input config/catalogs unchanged")
		check(state.config_snapshot == config, plan.id + ": exact frozen config")
		check(state.step_index == state.total_steps and state.run_status == "completed", plan.id + ": terminal completion at correct bound")
		check(absf(state.returned_data_mb - float(plan.expected.returned_mb)) < 0.000001 and absf(state.stored_data_mb - float(plan.expected.stored_mb)) < 0.000001, plan.id + ": exact returned/stored MB")
		var per_target_met: bool = true
		for target in config.mission.target_regions:
			var captures: int = int(state.observations_by_target.get(target, 0))
			var delivered: int = int(state.observations_delivered_by_target.get(target, 0))
			check(captures == plan.expected.captures[target], plan.id + ": capture count for " + target)
			check(delivered == plan.expected.complete_deliveries[target], plan.id + ": full-delivery count for " + target)
			check(absf(float(state.returned_data_by_target_mb.get(target, 0.0)) - float(plan.expected.returned_by_target_mb[target])) < 0.000001, plan.id + ": returned MB for " + target)
			if delivered < 1: per_target_met = false
		var capture_met: bool = state.observations_completed >= config.mission.required_observations
		var data_met: bool = state.returned_data_mb + 0.00000001 >= config.mission.required_returned_data_mb
		check(capture_met == plan.expected.capture_goal_met and data_met == plan.expected.data_goal_met and per_target_met == plan.expected.per_target_goal_met, plan.id + ": separate capture/data/complete-target conditions match")
		check(trace.resources_bounded and trace.inputs_preserved, plan.id + ": resource bounds and immutable action inputs")
		var repeated: Dictionary = simulate(config, loaded.catalogs, plan)
		check(trace == repeated, plan.id + ": exact deterministic replay")
		var before: String = JSON.stringify([config, state, state.event_log])
		var evaluation: Dictionary = Evaluator.evaluate_mission(config, state, state.event_log)
		check(not evaluation.ok and evaluation.error.code == "INVALID_EVALUATION_INPUT" and evaluation.error.field_path == "config.mission.objective" and not evaluation.has("report"), plan.id + ": current scorer explicitly refuses Survey; no fake Imaging report")
		check(before == JSON.stringify([config, state, state.event_log]), plan.id + ": evaluator preserves its inputs")
		if plan.id == "two_targets_second_unreturned": check(state.data_packets.size() == 1 and state.data_packets[0].target_id == "antarctic_region" and state.data_packets[0].remaining_mb == 12, "Unreturned second target retains its entire 12-MB packet")
		if plan.id == "two_targets_second_partial": check(state.data_packets.size() == 1 and state.data_packets[0].remaining_mb > 0 and state.data_packets[0].remaining_mb < 12, "Partially returned target still has an incomplete packet")
		if plan.id == "stock_polar_ice_data_shortfall": stock_opportunity_bound(config, state, validation)
		trace.config = config; trace.validation = validation; trace.current_evaluation = evaluation
		trace.proposed_conditions = {"capture_met": capture_met, "data_met": data_met, "all_targets_fully_delivered_at_least_once": per_target_met, "minimum_per_target": 1, "official_score": null, "owner_confirmation": "pending"}
		write(output.path_join(plan.id + ".json"), trace)
		evidence.cases[plan.id] = {"trace_file": plan.id + ".json", "returned_mb": state.returned_data_mb, "stored_mb": state.stored_data_mb, "captures_by_target": state.observations_by_target, "complete_deliveries_by_target": state.observations_delivered_by_target, "returned_by_target_mb": state.returned_data_by_target_mb, "proposed_conditions": trace.proposed_conditions, "current_evaluation": evaluation}
	check(evidence.cases.size() == 5, "All five Survey traces recorded")
	evidence.passed = passed; evidence.failed = failed
	write(output.path_join("summary.json"), evidence)
	print("K26 Survey preparation: %d checks passed; %d failed; %d native Survey traces." % [passed, failed, evidence.cases.size()])
	quit(0 if failed == 0 else 1)
func simulate(config: Dictionary, catalogs: Dictionary, plan: Dictionary) -> Dictionary:
	var initialized: Dictionary = Steps.init_validated_run(config, catalogs, "run_k26_" + plan.id, "mission_k26_survey_review")
	if not initialized.ok: return initialized
	var state: Dictionary = initialized.state; var telemetry: Array = []
	var observe: Array = plan.observe_steps.map(func(value): return int(value))
	var transmit: Array = plan.transmit_steps.map(func(value): return int(value))
	var bounded: bool = true; var unchanged: bool = true
	for step in range(int(state.total_steps)):
		var action: String = "observe" if step in observe else ("transmit" if step in transmit else "power_save")
		var before: String = JSON.stringify(state)
		var reply: Dictionary = Steps.request_action(state, action)
		unchanged = unchanged and before == JSON.stringify(state)
		if not reply.get("ok", false) or not reply.get("allowed", false): return {"ok": false, "step": step, "action": action, "reply": reply}
		state = reply.state
		bounded = bounded and state.energy_wh >= 0 and state.energy_wh <= state.battery_capacity_wh and state.stored_data_mb >= 0 and state.stored_data_mb <= state.storage_capacity_mb
		telemetry.append({"step_index": state.step_index, "energy_wh": state.energy_wh, "stored_data_mb": state.stored_data_mb, "returned_data_mb": state.returned_data_mb, "observations_completed": state.observations_completed})
	return {"ok": state.phase == "finished", "final_state": state, "events": state.event_log.duplicate(true), "telemetry": telemetry, "resources_bounded": bounded, "inputs_preserved": unchanged, "plan": plan.duplicate(true)}
func stock_opportunity_bound(config: Dictionary, state: Dictionary, validation: Dictionary) -> void:
	var orbit: Dictionary = {}
	for row in state.scenario_snapshot.orbits:
		if row.id == config.design.orbit_id: orbit = row
	var all_capture_steps_are_contact: bool = true
	for step in orbit.target_windows[config.mission.target_region]:
		if not step in orbit.ground_contact_windows: all_capture_steps_are_contact = false
	var contact_slots: int = int(config.mission.duration_orbits) * orbit.ground_contact_windows.size()
	var transmit_slots_after_captures: int = contact_slots - int(config.mission.required_observations)
	var per_step_mb: float = validation.metrics.downlink_mb_per_hour * orbit.step_duration_hours
	var upper_mb: float = transmit_slots_after_captures * per_step_mb
	check(all_capture_steps_are_contact and contact_slots == 12 and transmit_slots_after_captures == 7 and upper_mb < config.mission.required_returned_data_mb, "Current stock Survey has insufficient disjoint capture/transmit opportunities to reach 60 MB")
	evidence.stock_preset_opportunity_bound = {"source": "frozen native scenario + current one-action-per-step model", "all_capture_windows_overlap_contact": all_capture_steps_are_contact, "contact_slots": contact_slots, "required_capture_slots": config.mission.required_observations, "maximum_remaining_transmit_slots": transmit_slots_after_captures, "radio_mb_per_contact_step": per_step_mb, "returned_mb_upper_bound_after_all_captures": upper_mb, "required_returned_data_mb": config.mission.required_returned_data_mb, "preset_changed": false, "hpc_review": "pending"}
func write(path: String, value: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null: check(false, "Cannot write evidence: " + path); return
	file.store_string(JSON.stringify(value, "  ")); file.close()
