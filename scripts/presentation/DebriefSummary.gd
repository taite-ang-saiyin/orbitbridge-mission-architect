extends RefCounted
## Factual display of already bound results, never an alternative mission evaluator.
const Words = preload("res://scripts/presentation/PlayerLanguage.gd")

static func goal(actual: Variant, required: Variant, ratio: Variant, unit: String) -> Dictionary:
	var known: bool = (actual is int or actual is float) and (required is int or required is float) and is_finite(actual) and is_finite(required) and required > 0
	var progress_known: bool = (ratio is int or ratio is float) and is_finite(ratio)
	var result = {"known":known, "reached":false, "label":"Not available", "progress_known":progress_known, "progress":clampf(float(ratio), 0, 1) * 100 if progress_known else 0.0}
	if known:
		result.reached = actual >= required
		result.label = "Reached" if result.reached else "Short by %s%s" % [Words.amount(required - actual), unit]
	return result

static func build(model: Dictionary, trace: Dictionary) -> Dictionary:
	var bound: bool = model.get("state") == "report"
	var report: Dictionary = model.get("report", {}) if bound else {}
	var photo = goal(report.get("observations_completed"), report.get("required_observations"), report.get("observation_completion_ratio"), " photos")
	var data = goal(report.get("returned_data_mb"), report.get("required_returned_data_mb"), report.get("data_return_completion_ratio"), " MB")
	var text = ""
	if bound and photo.known and data.known:
		if report.get("run_status") == "aborted": text = "This flight ended early. These are the results recorded before it stopped."
		elif photo.reached and data.reached: text = "Your spacecraft took the requested photos and sent enough data back to Earth."
		elif photo.reached: text = "All requested photos were taken. The data-return goal was not reached."
		elif data.reached: text = "Enough data reached Earth. The photo goal was not reached."
		else: text = "The photo and data-return goals were not reached."
		var stored: Variant = trace.get("final_state", {}).get("stored_data_mb")
		if (stored is int or stored is float) and is_finite(stored) and stored > 0:
			text += " %s MB are still on the spacecraft." % Words.amount(stored)
	elif bound: text = "Some goal measurements are unavailable. The supplied report is kept in Flight log."
	return {"photos":photo, "data":data, "text":text}
