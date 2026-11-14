extends RefCounted
## Binds evaluation and attribution to the complete terminal input snapshot.

const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const LEDGER_PATH = "res://data/nasa_sources.json"

static func input_key(trace: Dictionary) -> String:
	return JSON.stringify([
		trace.get("config"), trace.get("final_state"), trace.get("events"),
		trace.get("validation"),
	], "", true, true).sha256_text()


static func evaluate_trace(trace: Dictionary) -> Dictionary:
	var key: String = input_key(trace)
	if trace.get("evaluation_key") == key and trace.get("evaluation") is Dictionary:
		return trace.evaluation.duplicate(true)
	var final_value: Variant = trace.get("final_state")
	var final: Dictionary = final_value if final_value is Dictionary else {}
	var config: Variant = trace.get("config")
	var events: Variant = trace.get("events")
	var result: Dictionary
	if not config is Dictionary or not events is Array:
		result = _input_error(final, "trace", "The run requires its config, terminal state and complete event history.")
	elif final.get("config_snapshot") != config or final.get("event_log") != events:
		result = _input_error(final, "trace.events", "The run snapshots do not match the terminal config and complete event log.")
	else:
		result = Evaluator.evaluate_mission(config, final, events)
		if result.get("ok", false):
			for event: Dictionary in events:
				if event.get("run_id") != final.get("run_id") or event.get("mission_id") != final.get("mission_id"):
					result = _input_error(final, "trace.events", "An event belongs to a different run or mission.")
					break
	trace.evaluation_key = key
	trace.evaluation = result.duplicate(true)
	trace.result_context = _context(trace, result)
	return result.duplicate(true)


static func presentation(trace: Dictionary) -> Dictionary:
	var result: Dictionary = evaluate_trace(trace)
	var final_value: Variant = trace.get("final_state")
	var state: Dictionary = final_value.duplicate(true) if final_value is Dictionary else {}
	var events: Variant = trace.get("events")
	state.events = events.duplicate(true) if events is Array else []
	return {
		"context": trace.result_context.duplicate(true),
		"state": state,
		"report": result.get("report", {}).duplicate(true),
	}


static func _context(trace: Dictionary, result: Dictionary) -> Dictionary:
	var final_value: Variant = trace.get("final_state")
	var final: Dictionary = final_value if final_value is Dictionary else {}
	var config: Variant = trace.get("config")
	var context: Dictionary = {
		"run_id": final.get("run_id"), "mission_id": final.get("mission_id"),
		"execution_key": trace.evaluation_key,
		"config": config.duplicate(true) if config is Dictionary else {},
		"applicable_source_credits": [], "source_metadata": {},
		"profile_metadata": {},
		"attribution_notice": "Credits apply to the recorded readiness check and emitted feedback vocabulary. Orbital windows and gameplay rates are authored educational values.",
	}
	if not result.get("ok", false):
		context.evaluation_error = result.get("error", {}).duplicate(true)
		return context
	var ledger: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LEDGER_PATH))
	var validation: Dictionary = trace.get("validation", {})
	var mass: Dictionary = validation.get("checks", {}).get("profile_mass", {})
	var profile_id: String = str(trace.config.get("design", {}).get("launch_profile_id", ""))
	for source: Dictionary in ledger.get("sources", []):
		context.source_metadata[source.source_id] = source.duplicate(true)
		if source.source_id == "cubesat_101_1u_sample" and validation.get("ready_to_launch") == true:
			if mass.get("passed") == true and mass.get("source_id") == source.source_id and mass.get("profile_id") == profile_id:
				var credit: Dictionary = source.duplicate(true)
				credit.credit_scope = "readiness"
				credit.actual_use = "Recorded KE1 mass check: %s g %s %s g, profile %s." % [mass.get("total_mass_g"), mass.get("comparator"), mass.get("threshold_g"), profile_id]
				context.applicable_source_credits.append(credit)
				context.profile_metadata = {"label": source.applicable_profile.label, "source_label": source.title, "credit": source.attribution_text}
		if source.source_id == "nasa_design_develop_science_missions_2025" and not result.report.root_causes.is_empty():
			var credit: Dictionary = source.duplicate(true)
			credit.credit_scope = "feedback_vocabulary"
			credit.actual_use = "Mission-segment terminology in this report's recorded-event causes."
			context.applicable_source_credits.append(credit)
	return context


static func _input_error(final: Dictionary, field: String, message: String) -> Dictionary:
	return {"ok": false, "error": {
		"code": "INVALID_EVALUATION_INPUT", "field_path": field,
		"message": message, "suggested_fix": "Use the original config, terminal state and ordered events from this execution.",
		"run_id": final.get("run_id"),
	}}
