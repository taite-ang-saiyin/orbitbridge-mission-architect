extends RefCounted
## KE3 display/correlation only. Outcomes, scores and ratios remain KE2-owned.
static func text(value: Variant) -> String:
	if value == null: return "Unavailable"
	return str(value).trim_suffix(".0") if value is float else str(value)

static func number(data: Dictionary, key: String) -> String:
	var value: Variant = data.get(key)
	return "%.3f" % value if (value is int or value is float) and is_finite(value) else "Unavailable"

static func percent(value: Variant) -> String:
	return "%.2f%%" % (value * 100.0) if (value is int or value is float) and is_finite(value) else "Unavailable"

static func build(trace: Dictionary, store: Dictionary) -> Dictionary:
	var final: Dictionary = trace.get("final_state", {})
	var config: Dictionary = trace.get("config", {})
	var mission: Dictionary = config.get("mission", {})
	var id: String = str(final.get("run_id", ""))
	var report: Dictionary = store.get("reports", {}).get(id, {})
	var model: Dictionary = {"state":"pending", "text":"", "credits":"", "report":{}}
	var heading: String = "%s / %s\n%s" % [text(final.get("run_id")), text(final.get("run_status")), text(mission.get("title"))]
	if not report.is_empty():
		var matches: bool = report.get("run_id") == final.get("run_id") and report.get("mission_id") == final.get("mission_id")
		var expected_key: Variant = store.get("bindings",{}).get(id)
		if expected_key != null and expected_key != preload("res://scripts/integration/mission_results.gd").input_key(trace): matches = false
		for key in ["required_observations", "required_returned_data_mb"]:
			if report.has(key) and report[key] != mission.get(key): matches = false
		for key in ["observations_completed", "returned_data_mb", "run_status"]:
			if report.has(key) and report[key] != final.get(key): matches = false
		if not matches:
			model.state = "stale_report"
			model.text = heading + "\n\nReport unavailable: run/mission, goals or counters do not match this run."
		else:
			model.state = "report"
			model.report = report.duplicate(true)
			model.text = heading + "\n\nOutcome: %s\nScore: %s\nCaptured %s / %s\nReturned %s / %s MB\nCompletion: %s observations / %s returned data\n\n%s\n\nNext experiment: %s" % [text(report.get("status")), "Not scored (aborted)" if report.get("score") == null and report.get("run_status") == "aborted" else text(report.get("score")), text(report.get("observations_completed")), text(report.get("required_observations")), text(report.get("returned_data_mb")), text(report.get("required_returned_data_mb")), percent(report.get("observation_completion_ratio")), percent(report.get("data_return_completion_ratio")), text(report.get("explanation")), text(report.get("next_experiment"))]
			var index: Dictionary = {}
			var ambiguous: Array = []
			for event in final.get("event_log", []):
				if not event is Dictionary or event.get("run_id") != id or event.get("mission_id") != final.get("mission_id"): continue
				var event_id: Variant = event.get("event_id")
				if event_id == null: continue
				if index.has(event_id) and index[event_id] != event: ambiguous.append(event_id)
				index[event_id] = event
			var causes: Variant = report.get("root_causes", [])
			if causes is Array:
				for cause in causes:
					if not cause is Dictionary: continue
					model.text += "\n\nCause %s: %s" % [text(cause.get("code")), text(cause.get("explanation"))]
					var references: Variant = cause.get("evidence_event_ids", [])
					if not references is Array or references.is_empty(): model.text += "\nEvidence Unavailable"
					else:
						for event_id in references:
							if not index.has(event_id) or ambiguous.has(event_id): model.text += "\nEvidence Unavailable: " + str(event_id)
							else:
								var event: Dictionary = index[event_id]
								model.text += "\nEvidence: %s | Step %s | %s" % [event_id, text(event.get("step_index")), text(event.get("message"))]
	if model.state == "pending":
		var error: Dictionary = store.get("errors", {}).get(id, {})
		model.state = "evaluation_error" if not error.is_empty() else "pending"
		model.text = heading + "\n\nEvaluation unavailable\n%s\n%s" % [text(error.get("message", "Finish or abort playback before requesting evaluation.")), text(error.get("suggested_fix", "Return to Operations and finish or abort the run."))]
	for target_id in mission.get("target_regions", [mission.get("target_region", "")]):
		if str(target_id).is_empty(): continue
		var captured: Variant = final.get("observations_by_target", {}).get(target_id, 0) if final.has("observations_by_target") else null
		var returned: Variant = final.get("returned_data_by_target_mb", {}).get(target_id, 0.0) if final.has("returned_data_by_target_mb") else null
		model.text += "\n%s: %s captures, %s MB returned" % [str(target_id).replace("_", " ").capitalize(), text(captured), text(returned)]
		if mission.get("objective") == "survey":
			var delivered: Variant = final.get("observations_delivered_by_target", {}).get(target_id, 0) if final.has("observations_delivered_by_target") else null
			model.text += " / %s complete observations delivered" % text(delivered)
	model.text += "\n\nHPC battery: %s Wh | Stored: %s MB" % [number(final,"energy_wh"),number(final,"stored_data_mb")]
	# Launch credit is bound to the executed validation, independent of report source_ids.
	var mass: Dictionary = trace.get("validation", {}).get("checks", {}).get("profile_mass", {})
	model.readiness_credit = mass.duplicate(true)
	if mass.get("source_id") == "cubesat_101_1u_sample":
		model.credits = "Scope: readiness\nNASA CubeSat 101, App. C item 6, printed p.79 / PDF p.87.\nExecuted sample mass check: %s g %s %s g. This is not flight certification.\nSource ID: %s" % [text(mass.get("total_mass_g")),text(mass.get("comparator")),text(mass.get("threshold_g")),text(mass.get("source_id"))]
	else: model.credits = "Readiness source credit: Unavailable"
	var scoped: Array = []
	for record in store.get("history", []):
		# Attribution attached to a rejected report must not leak via matching history.
		if model.state == "report" and record.get("state", {}).get("run_id") == id and record.state.get("config_snapshot") == config and record.get("state") == final:
			var metadata: Variant = record.get("source_credit_metadata", {})
			if metadata is Dictionary and metadata.get("applicable_source_credits") is Array: scoped = metadata.applicable_source_credits
	var has_feedback: bool = false
	model.source_credits = scoped.duplicate(true)
	for credit in scoped:
		if not credit is Dictionary: continue
		if credit.get("credit_scope") == "feedback_vocabulary": has_feedback = true
		model.credits += "\n\nScope: %s (display metadata; not report source_ids)\n%s\n%s\n%s\nActual use: %s" % [text(credit.get("credit_scope")),text(credit.get("title")),text(credit.get("attribution_text")),text(credit.get("url")),text(credit.get("actual_use"))]
	if not has_feedback: model.credits += "\n\nFeedback-vocabulary credit metadata: Unavailable"
	return model.duplicate(true)
