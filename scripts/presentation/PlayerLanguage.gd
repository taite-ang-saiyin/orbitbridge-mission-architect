extends RefCounted
## Player-facing wording and rounding only. Supplied records remain unchanged.

static func amount(value: Variant) -> String:
	if not (value is int or value is float) or not is_finite(value): return "Not available"
	if value != 0 and absf(value) < 0.005: return "< 0.01" if value > 0 else "> -0.01"
	return ("%.2f" % value).trim_suffix(".00")

static func sentence(value: Variant) -> String:
	if value == null: return "Not available"
	var result: String = str(value)
	var decimals = RegEx.new()
	decimals.compile("-?[0-9]+\\.[0-9]+")
	var matches: Array[RegExMatch] = decimals.search_all(result)
	matches.reverse()
	for found in matches:
		result = result.substr(0, found.get_start()) + amount(float(found.get_string())) + result.substr(found.get_end())
	for pair in [
		["observations captured", "photos taken"],
		["received on Earth", "sent to Earth"],
		["remain onboard", "are still on the spacecraft"],
		["Available events do not establish the cause of the shortfall.", "The flight log does not show why this goal was missed."],
		["Retry and transmit during an available ground-contact window.", "Try again and send data while a ground station is in range."],
		["Keep the scenario and targets fixed and change one operation on the next attempt.", "Keep the same goal and targets. Try changing when you take a photo or send data."],
		["Retry with one change to transmission timing and review the event timeline.", "Try again and change when you send data to Earth. Check the flight log to see what changed."],
		["HPC", "flight simulation"], ["KE1", "readiness"], ["KE2", "mission review"], ["KE3", "display"]
	]: result = result.replace(pair[0], pair[1])
	return preload("res://ui/components/UI.gd").user_message(result)

static func event_name(value: String) -> String:
	return {"START":"Flight started", "OBSERVE":"Photo taken", "TX":"Data sent", "POWER_SAVE":"Saving power", "SKIP_POWER":"Low battery", "MISSION_FINISHED":"Flight finished", "PLAYING":"Running", "PAUSED":"Paused", "COMPLETED":"Finished", "ABORTED":"Stopped early"}.get(value, value.replace("_", " ").capitalize())

static func report(model: Dictionary, trace: Dictionary) -> Dictionary:
	var final: Dictionary = trace.get("final_state", {})
	var mission: Dictionary = trace.get("config", {}).get("mission", {})
	var supplied: Dictionary = model.get("report", {})
	var valid: bool = model.get("state") == "report"
	var result: Dictionary = {
		"headline":"Results not available yet", "score":"Not available",
		"summary":"Finish the flight to see how you did.", "next":"Return to Operations to continue your flight.",
		"photos":amount(final.get("observations_completed")), "photo_goal":amount(mission.get("required_observations")),
		"data":amount(final.get("returned_data_mb")), "data_goal":amount(mission.get("required_returned_data_mb")),
		"battery":amount(final.get("energy_wh")), "stored":amount(final.get("stored_data_mb")),
		"targets":"", "evidence":"", "credits":""
	}
	if valid:
		result.headline = {"success":"All goals reached", "partial":"Some goals reached", "failed":"Goals not reached"}.get(supplied.get("status"), "Mission results")
		if supplied.get("run_status") == "aborted": result.headline = "Mission stopped early"
		result.score = "Not scored" if supplied.get("score") == null else amount(supplied.score) + " / 100"
		result.summary = sentence(supplied.get("explanation"))
		result.next = sentence(supplied.get("next_experiment"))
		result.photos = amount(supplied.get("observations_completed"))
		result.photo_goal = amount(supplied.get("required_observations"))
		result.data = amount(supplied.get("returned_data_mb"))
		result.data_goal = amount(supplied.get("required_returned_data_mb"))
	elif model.get("state") == "evaluation_error":
		result.headline = "Flight complete · score unavailable"
		result.summary = "Evaluation unavailable for this flight. Your recorded measurements are shown below."
		if mission.get("objective") in ["communication", "weather_monitoring"]:
			result.summary = "Your flight is complete. Scoring is not available for this mission yet; recorded measurements are shown below."
			var progress: Dictionary = final.get("goal_progress", {})
			var goal_label: String = "Data-return steps" if mission.objective == "communication" else "Orbits with a target observation"
			result.summary += "\n%s: %s / %s" % [goal_label, amount(progress.get("actual_count")), amount(progress.get("required_count"))]
		if mission.get("objective") == "survey": result.summary = "Your Survey flight is complete. Survey scoring is not available yet; you can still review the photos and data you collected."
		result.next = "Try an imagery mission for a scored result, or modify this design and fly again."
	elif model.get("state") == "stale_report":
		result.headline = "These results do not match this flight"
		result.summary = "The report could not be matched to your recorded flight. Its score and explanation are not shown."
		result.next = "Return to Operations or select another completed flight."
	for target in mission.get("target_regions", [mission.get("target_region", "")]):
		if str(target).is_empty(): continue
		var captured: Variant = final.get("observations_by_target", {}).get(target) if final.has("observations_by_target") else null
		var returned: Variant = final.get("returned_data_by_target_mb", {}).get(target) if final.has("returned_data_by_target_mb") else null
		result.targets += "%s: %s captures, %s MB sent to Earth.\n" % [str(target).replace("_", " ").capitalize(), amount(captured), amount(returned)]
	var history: Dictionary = {}
	var ambiguous: Array = []
	for event in final.get("event_log", []):
		if not event is Dictionary or event.get("run_id") != final.get("run_id") or event.get("mission_id") != final.get("mission_id"): continue
		var id: Variant = event.get("event_id")
		if id == null: continue
		if history.has(id) and history[id] != event: ambiguous.append(id)
		history[id] = event
	if valid:
		for cause in supplied.get("root_causes", []):
			if not cause is Dictionary: continue
			result.evidence += sentence(cause.get("explanation")) + "\n"
			for id in cause.get("evidence_event_ids", []):
				if not history.has(id) or ambiguous.has(id): result.evidence += "Evidence Unavailable: " + str(id) + "\n"
				else: result.evidence += "Evidence: Step %s · %s\n" % [amount(history[id].get("step_index")), sentence(history[id].get("message"))]
	return result

static func credits(model: Dictionary) -> String:
	var parts: Array[String] = []
	var readiness: Dictionary = model.get("readiness_credit", {})
	if readiness.get("source_id") == "cubesat_101_1u_sample":
		parts.append("NASA CubeSat 101\nThe sample 1U spacecraft mass check is adapted from Appendix C, item 6, printed page 79. Your recorded check: %s g %s %s g. This educational check is not flight certification." % [amount(readiness.get("total_mass_g")), readiness.get("comparator", ""), amount(readiness.get("threshold_g"))])
	for source in model.get("source_credits", []):
		if not source is Dictionary or source.get("credit_scope") == "readiness": continue
		parts.append(sentence(source.get("title")) + "\n" + sentence(source.get("attribution_text")))
	return "\n\n".join(parts) if not parts.is_empty() else "No source attribution was supplied for this flight."
