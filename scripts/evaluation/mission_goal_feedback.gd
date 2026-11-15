extends RefCounted
## Internal goal-feedback proposal. Existing production build_feedback is unchanged.
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const Feedback = preload("res://scripts/evaluation/mission_feedback.gd")
const Goals = preload("res://scripts/evaluation/mission_goal_evidence.gd")

static func _build(state: Dictionary, events: Variant, progress: Variant, hpc_confirmed: bool = false) -> Dictionary:
	if state.get("run_status") == "aborted":
		var reason: String = Feedback._abort_reason(state)
		return _neutral("Run aborted." + (" Recorded abort reason: " + reason if not reason.is_empty() else ""),
			"Review the recorded termination reason, then retry with one change.")
	var checked: Dictionary = Goals._events(state, events)
	if not checked.ok or not state.get("config_snapshot") is Dictionary or not progress is Array or progress.is_empty(): return _neutral("Goal or event evidence is unavailable.")
	var unmet: Array = []
	var seen: Array = []
	for goal in progress:
		if not goal is Dictionary or not goal.get("id") is String or goal.id in seen or not goal.get("met") is bool: return _neutral("Goal evidence is unavailable or conflicting.")
		if not Evaluator._is_finite_number(goal.get("actual")) or not Evaluator._is_finite_number(goal.get("required")) or goal.actual < 0 or goal.required <= 0 or goal.met != (goal.actual >= goal.required): return _neutral("Goal evidence is unavailable or inconsistent.")
		if not goal.id in ["captures", "returned_data", "selected_targets_delivered", "positive_transmit_steps", "selected_target_revolution_visits"]: return _neutral("Goal semantics are unavailable.")
		var actual: Variant = null
		if goal.id == "captures": actual = state.get("observations_completed")
		elif goal.id == "returned_data": actual = state.get("returned_data_mb")
		else:
			var measured: Dictionary
			if goal.id == "positive_transmit_steps":
				measured = Goals._communication(state, events)
				if measured.ok: actual = measured.measure.positive_transmit_steps
			elif goal.id == "selected_targets_delivered":
				measured = Evaluator._measure_survey_deliveries(state.config_snapshot, state)
				if measured.ok: actual = measured.measure.delivered_selected_target_count
			else:
				measured = Goals._weather(state.config_snapshot, state, events)
				if measured.ok: actual = measured.measure.selected_target_revolution_visits
		if actual == null: return _neutral("Goal measurement evidence is unavailable; sparse entries have not been assigned zero.")
		if actual != goal.actual: return _neutral("Supplied goal progress does not match recorded evidence.")
		seen.append(goal.id)
		if not goal.met: unmet.append(goal.id)
	if unmet.is_empty(): return _neutral("The supplied goal measurements are met.", "Repeat the same plan to check the measured result.")
	for event: Dictionary in checked.events:
		var relevant: bool = (event.get("action") == "transmit" and ("returned_data" in unmet or "positive_transmit_steps" in unmet)) or (event.get("action") == "observe" and ("captures" in unmet or "selected_target_revolution_visits" in unmet))
		if not relevant: continue
		var cause: Dictionary = Feedback.explain_event(event)
		if cause.is_empty(): continue
		return {"proposal": true, "explanation": cause.explanation,
			"root_causes": [{"code": cause.code, "segment": cause.segment, "evidence_event_ids": cause.evidence_event_ids.duplicate(), "explanation": cause.explanation}],
			"next_experiment": cause.next_experiment}
	if "selected_targets_delivered" in unmet:
		var delivered: Dictionary = Evaluator._measure_survey_deliveries(state.config_snapshot, state)
		if not delivered.ok: return _neutral("Survey complete-delivery evidence is unavailable; omitted native entries have not been assigned zero.")
		return _neutral("A selected target has no recorded complete delivery. Available events do not establish why.",
			"Keep the design and captures fixed; try transmitting remaining packets during available contact steps.")
	if "selected_target_revolution_visits" in unmet:
		var weather: Dictionary = Goals._weather(state.config_snapshot, state, events)
		if not weather.ok: return _neutral("Weather revolution evidence is unavailable.")
		var explanation: String = "Accepted captures cover fewer required revolutions under HPC's confirmed pre-action mapping." if hpc_confirmed else "Under the proposed pre-action mapping, captures cover fewer required revolutions. The mapping still awaits HPC confirmation."
		return _neutral(explanation,
			"Keep design and downlink fixed; try a target-access step in a different revolution.")
	return _neutral("Recorded goals have a shortfall; available events do not establish its cause.")

static func _neutral(message: String, experiment: String = "Retry with one timing change and review the recorded event timeline.") -> Dictionary:
	return {"proposal": true, "explanation": message, "root_causes": [], "next_experiment": experiment}
