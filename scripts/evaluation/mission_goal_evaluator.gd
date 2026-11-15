extends RefCounted
## Communication/Weather report v2. Uses the settled KE2 capped-ratio rubric
## and HPC's validated native goal evidence; legacy Imaging remains separate.
const Step = preload("res://core/MissionStepEngine.gd")

static func evaluate_mission(config: Dictionary, state: Dictionary, events: Array) -> Dictionary:
	var id: Variant = state.get("run_id")
	if config.get("schema_version") != 2 or not config.get("mission") is Dictionary:
		return _error("INVALID_EVALUATION_INPUT", "config", "A supported config v2 is required.", id)
	var mission: Dictionary = config.mission
	var objective: Variant = mission.get("objective")
	if objective not in ["communication", "weather_monitoring"]:
		return _error("INVALID_EVALUATION_INPUT", "config.mission.objective", "No expanded evaluator for this objective.", id)
	if state.get("phase") == "operating":
		return _error("NONTERMINAL_RUN_STATE", "final_state.phase", "Finish or stop the flight before evaluating it.", id)
	if state.get("phase") != "finished" or state.get("run_status") not in ["completed", "aborted"]:
		return _error("INVALID_EVALUATION_INPUT", "final_state.run_status", "A completed or aborted native flight is required.", id)
	if state.get("config_snapshot") != config or state.get("event_log") != events:
		return _error("INVALID_EVALUATION_INPUT", "trace", "Configuration and ordered events must match this exact native run.", id)
	# The engine revalidates frozen config/catalog/scenario, IDs, event order,
	# accepted steps, resource bounds and reconstructed goal evidence here.
	var checked: Dictionary = Step.get_available_actions(state)
	if not checked.get("ok", false):
		return _error("INVALID_EVALUATION_INPUT", "final_state", "Native flight evidence is missing, inconsistent or invalid.", id)
	if not _consistent_actuals(state, events):
		return _error("INVALID_EVALUATION_INPUT", "events", "Recorded captures and returned data must match the accepted step evidence.", id)
	var progress: Dictionary = state.goal_progress
	var required: Variant = mission.goal.get("required_positive_contact_steps" if objective == "communication" else "required_distinct_orbits")
	if progress.get("kind") != objective or progress.get("required_count") != required:
		return _error("INVALID_EVALUATION_INPUT", "final_state.goal_progress", "Goal evidence must match the frozen mission goal.", id)
	var count: int = int(progress.actual_count)
	var returned: float = float(state.returned_data_mb)
	var count_ratio: float = _ratio(count, required)
	var data_ratio: float = _ratio(returned, mission.required_returned_data_mb)
	var status: String = "success" if count >= required and returned >= mission.required_returned_data_mb else ("partial" if count > 0 or returned > 0 else "failed")
	var score: Variant = int(floorf(50.0 * (count_ratio + data_ratio) + 0.5))
	if state.run_status == "aborted": status = "failed"; score = null
	var return_ids: Array = []
	for event in events:
		if event.get("type") == "action_accepted" and event.get("action") == "transmit" and event.get("delta_returned_data_mb", 0.0) > 0:
			return_ids.append(event.event_id)
	var goal_id: String = "positive_transmit_steps" if objective == "communication" else "selected_target_revolution_visits"
	var goals: Array = [
		_goal(goal_id, count, required, "steps" if objective == "communication" else "orbits", progress.evidence_event_ids),
		_goal("returned_data", returned, mission.required_returned_data_mb, "MB", return_ids)]
	var label: String = "successful transmission steps" if objective == "communication" else "orbits with a target observation"
	var summary: String = "%s of %s %s; %s of %s MB returned to Earth." % [count, required, label, _number(returned), _number(mission.required_returned_data_mb)]
	var suggestion: String = "Keep the mission and action plan fixed; try one spacecraft change."
	if count < required:
		suggestion = "Keep data onboard for another successful transmission step." if objective == "communication" else "Wait for the next orbit before taking another target observation."
	elif returned < mission.required_returned_data_mb:
		suggestion = "Transmit the remaining onboard data during a ground-contact step."
	if state.run_status == "aborted":
		summary = "Flight stopped early. " + summary
		suggestion = "Review the flight log, then retry when ready."
	var report: Dictionary = {"schema_version":2,"run_id":state.run_id,"mission_id":state.mission_id,
		"run_status":state.run_status,"status":status,"objective":objective,
		"observations_completed":state.observations_completed,"required_observations":mission.required_observations,
		"returned_data_mb":state.returned_data_mb,"required_returned_data_mb":mission.required_returned_data_mb,
		"observation_completion_ratio":_ratio(state.observations_completed,mission.required_observations),
		"data_return_completion_ratio":data_ratio,"score":score,"goal_progress":goals,
		"explanation":summary,"root_causes":[],"next_experiment":suggestion,"source_ids":[],"comparison":null}
	return {"ok":true,"report":report}

static func _goal(id: String, actual: Variant, required: Variant, unit: String, ids: Array) -> Dictionary:
	return {"id":id,"actual":actual,"required":required,"unit":unit,"met":actual>=required,
		"completion_ratio":_ratio(actual,required),"evidence_event_ids":ids.duplicate()}

static func _ratio(actual: Variant, required: Variant) -> float:
	return 1.0 if actual >= required else float(actual)/float(required)

static func _consistent_actuals(state: Dictionary, events: Array) -> bool:
	var accepted: Dictionary = {}
	var captures: int = 0
	var returned: float = 0.0
	for event in events:
		if not event is Dictionary: return false
		if event.get("type") != "action_accepted": continue
		if accepted.has(event.step_index): return false
		accepted[event.step_index] = true
		var observations: Variant = event.get("delta_observations")
		var data: Variant = event.get("delta_returned_data_mb")
		if not (observations is int or observations is float) or not is_finite(observations) or observations != floorf(observations) or observations < 0: return false
		if not (data is int or data is float) or not is_finite(data) or data < 0: return false
		if event.get("action") == "observe":
			if observations != 1: return false
		elif observations != 0: return false
		if event.get("action") != "transmit" and data != 0: return false
		captures += int(observations)
		returned += float(data)
	if accepted.size() != int(state.step_index) or captures != state.observations_completed or not is_finite(returned): return false
	return absf(returned-float(state.returned_data_mb)) <= 1e-8 * maxf(1.0,maxf(absf(returned),absf(state.returned_data_mb)))

static func _number(value: float) -> String:
	return ("%.2f" % value).trim_suffix(".00")

static func _error(code: String, field: String, message: String, id: Variant) -> Dictionary:
	return {"ok":false,"error":{"code":code,"field_path":field,"message":message,
		"suggested_fix":"Use the full frozen configuration and same-run native evidence.","run_id":id if id is String and not id.strip_edges().is_empty() else null}}
