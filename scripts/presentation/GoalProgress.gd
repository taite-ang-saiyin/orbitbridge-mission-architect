extends RefCounted
## Read-only view of supplied measurements. No scoring or simulation rules.
## `details` is a presentation-only input for pending requirements, never MissionConfig.
const Words = preload("res://scripts/presentation/PlayerLanguage.gd")
const Summary = preload("res://scripts/presentation/DebriefSummary.gd")

static func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value)

static func metric(label: String, actual: Variant, required: Variant, ratio: Variant = null, unit: String = "") -> Dictionary:
	var verdict: Dictionary = Summary.goal(actual, required, ratio, unit)
	if verdict.known and not verdict.reached and required - actual == 1 and unit in [" steps"," orbits"," captures"]:
		verdict.label = verdict.label.trim_suffix("s")
	return {"label":label, "actual":actual, "required":required,
		"value":"%s / %s%s" % [Words.amount(actual),Words.amount(required),unit],
		"verdict":verdict.label if verdict.known else "Unavailable",
		"known":verdict.known,"reached":verdict.reached,
		"progress_known":verdict.progress_known,"progress":verdict.progress}

static func same_run_events(trace: Dictionary) -> Variant:
	var final: Dictionary = trace.get("final_state", {})
	if not final.get("run_id") is String or str(final.run_id).is_empty() or not final.get("mission_id") is String or str(final.mission_id).is_empty(): return null
	var events: Variant = final.get("event_log")
	if not events is Array: return null
	var result: Array = []
	for event in events:
		if event is Dictionary and event.get("run_id") == final.get("run_id") and event.get("mission_id") == final.get("mission_id"):
			result.append(event)
	return result

static func distinct_steps(events: Variant) -> Variant:
	if not events is Array: return null
	var steps: Array = []
	for event in events:
		if event.get("type") != "action_accepted" or event.get("action") != "transmit": continue
		var amount: Variant = event.get("data_transmitted_mb")
		var step: Variant = event.get("step_index")
		if not numeric(amount) or not numeric(step) or step < 0 or step != floor(step): return null
		if amount > 0 and not steps.has(step): steps.append(step)
	return steps.size()

static func distinct_orbits(trace: Dictionary, events: Variant) -> Variant:
	if not events is Array: return null
	var final: Dictionary = trace.get("final_state", {})
	var region: Variant = trace.get("config", {}).get("mission", {}).get("target_region")
	if not region is String or region.is_empty(): return null
	var steps_per_orbit: Variant = null
	for orbit in final.get("scenario_snapshot", {}).get("orbits", []):
		if orbit.get("id") == final.get("scenario_id"): steps_per_orbit = orbit.get("steps_per_orbit")
	if not numeric(steps_per_orbit) or steps_per_orbit <= 0 or steps_per_orbit != floor(steps_per_orbit): return null
	var visits: Array = []
	for event in events:
		if event.get("type") != "action_accepted" or event.get("action") != "observe": continue
		if not event.has("target_id"): return null
		if event.target_id != region: continue
		var step: Variant = event.get("step_index")
		if not numeric(step) or step < 0 or step != floor(step): return null
		var orbit_index: int = floori(float(step) / float(steps_per_orbit))
		if not visits.has(orbit_index): visits.append(orbit_index)
	return visits.size()

static func build(model: Dictionary, trace: Dictionary, details: Dictionary = {}) -> Dictionary:
	var final: Dictionary = trace.get("final_state", {})
	var mission: Dictionary = trace.get("config", {}).get("mission", {})
	var supplied: Dictionary = details.duplicate(true)
	if not supplied.is_empty():
		if supplied.get("run_id") != final.get("run_id") or supplied.get("mission_id") != final.get("mission_id") or supplied.get("execution_key") != preload("res://scripts/integration/mission_results.gd").input_key(trace): supplied.clear()
	var kind: String = str(supplied.get("goal_type", mission.get("objective", "")))
	var bound: bool = model.get("state") == "report"
	var stale: bool = model.get("state") == "stale_report"
	var report: Dictionary = model.get("report", {}) if bound else {}
	var actuals: Dictionary = {} if stale else (report if bound else final)
	var requirements: Dictionary = {} if stale else (report if bound else mission)
	var events: Variant = same_run_events(trace)
	if stale: events = null
	var primary: Dictionary
	match kind:
		"communication": primary = metric("Positive downlink steps",distinct_steps(events),supplied.get("required_count"),null," steps")
		"weather_monitoring": primary = metric("Observed orbits · %s" % str(mission.get("target_region","Unavailable")).replace("_"," ").capitalize(),distinct_orbits(trace,events),supplied.get("required_count"),null," orbits")
		_: primary = metric("Captures",actuals.get("observations_completed"),requirements.get("required_observations"),report.get("observation_completion_ratio")," captures")
	var data: Dictionary = metric("Returned to Earth",actuals.get("returned_data_mb"),requirements.get("required_returned_data_mb"),report.get("data_return_completion_ratio")," MB")
	var rows: Array = [primary,data]
	var deliveries: Array = []
	if kind == "survey":
		for target in mission.get("target_regions",[mission.get("target_region","")]):
			if str(target).is_empty(): continue
			# Existing Survey rule: at least one complete packet per selected target.
			var measured: Variant = null if stale else final.get("observations_delivered_by_target",{}).get(target)
			var delivery: Dictionary = metric(str(target).replace("_"," ").capitalize(),measured,1,null," complete")
			deliveries.append(delivery)
			rows.append(delivery)
	var missed: Array[String] = []
	var unknown: bool = false
	for row in rows:
		if not row.known: unknown = true
		elif not row.reached: missed.append(row.label + ": " + row.verdict)
	var references: Array[String] = []
	if events is Array:
		for event in events:
			if event.get("type") != "action_accepted": continue
			var relevant: bool = event.get("action") == "observe" and kind in ["imaging","survey","weather_monitoring"]
			if kind == "weather_monitoring": relevant = relevant and event.get("target_id") == mission.get("target_region")
			if event.get("action") == "transmit" and numeric(event.get("data_transmitted_mb")): relevant = event.data_transmitted_mb > 0
			if relevant and event.get("event_id") is String and not references.has(event.event_id): references.append(event.event_id)
	var evidence_text: String = "Unavailable" if references.is_empty() else ", ".join(references.slice(0,8))
	if references.size() > 8: evidence_text += " (+%s in the ordered flight log)" % (references.size()-8)
	var missed_text: String = "\n".join(missed)
	if missed_text.is_empty(): missed_text = "Unavailable where measurements or requirements are missing." if unknown else "No listed goal is below its requirement."
	elif unknown: missed_text += "\nOther goal progress: Unavailable."
	return {"goal_type":kind,"primary":primary,"data":data,"deliveries":deliveries,
		"missed_text":missed_text,"evidence_ids":references,"evidence_text":evidence_text,
		"run_id":final.get("run_id"),"mission_id":final.get("mission_id")}
