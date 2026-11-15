extends RefCounted
## Step 10.3 fixture-only proposal. Never used by runtime/public report production.
## Equal thirds and any-goal-progress semantics are NOT a ratified scoring contract.
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")

static func assess(config: Dictionary, state: Dictionary) -> Dictionary:
	var run_id: Variant = state.get("run_id")
	if not run_id is String or run_id.strip_edges().is_empty(): run_id = null
	if state.get("phase") != "finished" or not state.get("run_status") in ["completed", "aborted"]:
		return Evaluator._error(Evaluator.NONTERMINAL_STATE, "final_state.run_status",
			"The scoring proposal requires a terminal fixture.", "Complete or abort the labeled fixture first.", run_id)
	for field in ["step_index", "total_steps"]:
		if not Evaluator._is_whole_number(state.get(field)) or state[field] < (1 if field == "total_steps" else 0):
			return Evaluator._error(Evaluator.INVALID_INPUT, "final_state." + field,
				"Terminal step counters must be finite whole values in range.", "Supply valid fixture step counters.", run_id)
	if (state.run_status == "completed" and state.step_index != state.total_steps) or (state.run_status == "aborted" and state.step_index >= state.total_steps):
		return Evaluator._error(Evaluator.INVALID_INPUT, "final_state.step_index",
			"Terminal fixture steps do not match its run status.", "Complete at total_steps or abort before it.", run_id)
	var mission: Variant = config.get("mission")
	if not mission is Dictionary:
		return Evaluator._error(Evaluator.INVALID_INPUT, "config.mission",
			"The proposal requires a mission object.", "Supply the labeled Survey fixture config.", run_id)
	for item in [
		[mission.get("required_observations"), "config.mission.required_observations", true, true],
		[mission.get("required_returned_data_mb"), "config.mission.required_returned_data_mb", false, true],
		[state.get("observations_completed"), "final_state.observations_completed", true, false],
		[state.get("returned_data_mb"), "final_state.returned_data_mb", false, false],
	]:
		var valid: bool = Evaluator._is_whole_number(item[0]) if item[2] else Evaluator._is_finite_number(item[0])
		if not valid or item[0] < 0 or (item[3] and item[0] == 0):
			return Evaluator._error(Evaluator.INVALID_INPUT, item[1],
				"Goals must be positive and actuals nonnegative, finite and correctly typed.",
				"Supply whole capture counts and finite decimal MB in the fixture.", run_id)
	var measured: Dictionary = Evaluator._measure_survey_deliveries(config, state)
	if not measured.ok: return measured
	var captures: Variant = state.observations_completed
	var returned: Variant = state.returned_data_mb
	var delivery: Dictionary = measured.measure
	var capture_ratio: float = 1.0 if captures >= mission.required_observations else float(captures) / float(mission.required_observations)
	var data_ratio: float = 1.0 if returned >= mission.required_returned_data_mb else float(returned) / float(mission.required_returned_data_mb)
	var delivery_ratio: float = float(delivery.delivered_selected_target_count) / float(delivery.selected_target_count)
	var status: String = "failed"
	if capture_ratio == 1.0 and data_ratio == 1.0 and delivery_ratio == 1.0:
		status = "success"
	elif captures > 0 or returned > 0 or delivery.delivered_selected_target_count > 0:
		status = "partial"
	var score: Variant = int(floorf(100.0 * (capture_ratio + data_ratio + delivery_ratio) / 3.0 + 0.5))
	if state.run_status == "aborted":
		status = "failed"
		score = null
	return {"ok": true, "proposal": {
		"rule_id": "survey-equal-thirds-proposal-1", "not_for_publication": true,
		"run_id": run_id, "run_status": state.run_status, "status": status, "score": score,
		"actuals": {"observations_completed": captures, "returned_data_mb": returned,
			"observations_delivered_by_target": state.observations_delivered_by_target.duplicate(true)},
		"requirements": {"observations": mission.required_observations, "returned_mb": mission.required_returned_data_mb,
			"selected_targets": delivery.selected_target_count},
		"completion_ratios": {"captures": capture_ratio, "returned_mb": data_ratio, "delivered_targets": delivery_ratio},
		"delivery_measure": delivery.duplicate(true),
	}}
