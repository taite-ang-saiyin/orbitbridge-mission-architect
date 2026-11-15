extends RefCounted
## Read-only goal presentation. Count qualification and scoring belong to providers.
## `details` is a KE3 view input, not a MissionConfig or an agreed report extension.
const Words = preload("res://scripts/presentation/PlayerLanguage.gd")
const Summary = preload("res://scripts/presentation/DebriefSummary.gd")
const Results = preload("res://scripts/integration/mission_results.gd")

static func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value)

static func metric(label: String, actual: Variant, required: Variant, ratio: Variant = null, unit: String = "") -> Dictionary:
	var verdict: Dictionary = Summary.goal(actual, required, ratio, unit)
	if verdict.known and not verdict.reached and required - actual == 1 and unit in [" steps", " orbits", " captures"]:
		verdict.label = verdict.label.trim_suffix("s")
	return {"label":label, "actual":actual, "required":required,
		"value":"%s / %s%s" % [Words.amount(actual), Words.amount(required), unit],
		"verdict":verdict.label if verdict.known else "Unavailable",
		"known":verdict.known, "reached":verdict.reached,
		"progress_known":verdict.progress_known, "progress":verdict.progress}

static func verified_native_trace(trace: Dictionary) -> bool:
	# Only the full, same-run native trace may supply zero for absent sparse keys.
	# Legacy projections and missing source/version evidence cannot establish that meaning.
	var final: Dictionary = trace.get("final_state", {})
	var versions: Variant = trace.get("versions")
	var validation: Variant = trace.get("validation")
	var frames: Variant = trace.get("frames")
	if final.get("schema_version") != 1 or not final.get("run_id") is String or str(final.run_id).is_empty() or not final.get("mission_id") is String or str(final.mission_id).is_empty(): return false
	if final.get("config_snapshot") != trace.get("config") or final.get("event_log") != trace.get("events") or not trace.get("events") is Array: return false
	if not validation is Dictionary or validation.get("ready_to_launch") != true or validation.get("config") != trace.get("config"): return false
	if not versions is Dictionary: return false
	for pair in [["simulator_sha256", "res://core/MissionStepEngine.gd"], ["adapter_sha256", "res://core/HPCContractAdapter.gd"]]:
		var source_hash: String = FileAccess.get_sha256(pair[1])
		if source_hash.is_empty() or versions.get(pair[0]) != source_hash: return false
	if not frames is Array or frames.is_empty() or not frames[0] is Dictionary or not frames[-1] is Dictionary: return false
	if not frames[0].get("state") is Dictionary or not frames[-1].get("state") is Dictionary: return false
	if frames[0].get("state", {}).get("step_index") != 0 or frames[0].get("state", {}).get("event_log") != [] or frames[-1].get("state") != final: return false
	for frame in frames:
		if not frame is Dictionary or not frame.get("state") is Dictionary: return false
		var state: Dictionary = frame.state
		if state.get("run_id") != final.run_id or state.get("mission_id") != final.mission_id or state.get("config_snapshot") != trace.config: return false
	for index in trace.events.size():
		var event: Variant = trace.events[index]
		if not event is Dictionary or event.get("event_id") != "evt_%03d" % index or event.get("run_id") != final.run_id or event.get("mission_id") != final.mission_id: return false
	return true

static func target_measurement(final: Dictionary, map_name: String, target: String, native_verified: bool = false) -> Variant:
	var values: Variant = final.get(map_name)
	if not values is Dictionary: return null
	# HPC v1.0.0 confirms absent selected keys mean zero only in genuine native maps.
	return values.get(target, 0 if native_verified else null)

static func delivery_context(final: Dictionary, target: String, stale: bool = false, native_verified: bool = false) -> String:
	if stale: return "Target measurements: Unavailable"
	var packets: Variant = final.get("data_packets")
	var pending: Array[String] = []
	var packets_known: bool = packets is Array
	if packets is Array:
		for packet in packets:
			if not packet is Dictionary or not packet.get("target_id") is String:
				packets_known = false
				continue
			if packet.target_id == target: pending.append(Words.amount(packet.get("remaining_mb")) + " MB")
	var remaining: String = "Unavailable" if not packets_known else ("None listed" if pending.is_empty() else ", ".join(pending))
	# Raw native context only. Never turn captures, MB or pending packets into deliveries.
	return "Captured: %s · Returned: %s MB\nPacket remainder(s): %s" % [Words.amount(target_measurement(final, "observations_by_target", target, native_verified)), Words.amount(target_measurement(final, "returned_data_by_target_mb", target, native_verified)), remaining]

static func same_run_events(trace: Dictionary) -> Array:
	var final: Dictionary = trace.get("final_state", {})
	var result: Array = []
	if not final.get("run_id") is String or str(final.run_id).is_empty() or not final.get("mission_id") is String or str(final.mission_id).is_empty(): return result
	var events: Variant = final.get("event_log")
	if not events is Array: return result
	for event in events:
		if event is Dictionary and event.get("run_id") == final.run_id and event.get("mission_id") == final.mission_id:
			result.append(event)
	return result

static func supplied_goal(entry: Dictionary, label: String) -> Dictionary:
	var unit: String = str(entry.get("unit", ""))
	unit = {"count":"captures", "complete_observations":"complete"}.get(unit, unit)
	var known: bool = numeric(entry.get("actual")) and numeric(entry.get("required")) and entry.required > 0 and entry.get("met") is bool
	var ratio: Variant = entry.get("completion_ratio")
	var progress_known: bool = numeric(ratio) and ratio >= 0 and ratio <= 1
	return {"label":label, "actual":entry.get("actual"), "required":entry.get("required"),
		"value":"%s / %s%s" % [Words.amount(entry.get("actual")), Words.amount(entry.get("required")), " " + unit if not unit.is_empty() else ""],
		"known":known, "reached":entry.get("met") == true if known else false,
		"verdict":("Reached" if entry.met else "Not reached") if known else "Unavailable",
		"progress_known":progress_known, "progress":float(ratio) * 100.0 if progress_known else 0.0}

static func _supplied_preview(model: Dictionary, trace: Dictionary, supplied: Dictionary) -> Dictionary:
	# Exact draft goal entries are accepted only in an execution-bound, labeled preview.
	# Never reinterpret an Imaging proxy report as a production expanded report.
	var base: Dictionary = supplied.duplicate(true)
	base.erase("goal_progress")
	var index: Dictionary = {}
	var references: Array = []
	for entry in supplied.goal_progress:
		if not entry is Dictionary or not entry.get("id") is String: continue
		index[entry.id] = {} if index.has(entry.id) else entry
		if entry.get("evidence_event_ids") is Array: references.append_array(entry.evidence_event_ids)
	base.evidence_event_ids = references
	var result: Dictionary = build(model, trace, base)
	var kind: String = result.goal_type
	var mission: Dictionary = trace.get("config", {}).get("mission", {})
	var goal_id: String = {"communication":"positive_transmit_steps", "weather_monitoring":"selected_target_revolution_visits"}.get(kind, "captures")
	var label: String = {"communication":"Positive downlink steps", "weather_monitoring":"Observed revolutions · " + str(mission.get("target_region", "Unavailable")).replace("_", " ").capitalize()}.get(kind, "Captures")
	result.primary = supplied_goal(index.get(goal_id, {}), label)
	result.data = supplied_goal(index.get("returned_data", {}), "Returned to Earth")
	result.deliveries = []
	result.extra_goals = []
	var rows: Array = [result.primary, result.data]
	if kind == "survey":
		var delivery_goal: Dictionary = index.get("selected_targets_delivered", {})
		var aggregate: Dictionary = supplied_goal(delivery_goal, "Selected targets completely delivered")
		result.extra_goals.append(aggregate)
		rows.append(aggregate)
		var by_target: Dictionary = {}
		var provided: Array = delivery_goal.by_target if delivery_goal.get("by_target") is Array else []
		for target in provided:
			if target is Dictionary and target.get("target_id") is String: by_target[target.target_id] = target
		for id in mission.get("target_regions", [mission.get("target_region", "")]):
			if str(id).is_empty(): continue
			var row: Dictionary = supplied_goal(by_target.get(id, {}), str(id).replace("_", " ").capitalize())
			row.context_text = delivery_context(trace.get("final_state", {}), str(id), false, verified_native_trace(trace))
			result.deliveries.append(row)
			rows.append(row)
	var missed: Array[String] = []
	var unknown: bool = false
	for row in rows:
		if not row.known: unknown = true
		elif not row.reached: missed.append(row.label + ": " + row.verdict)
	result.missed_text = "\n".join(missed)
	if result.missed_text.is_empty(): result.missed_text = "Unavailable where provider values are missing." if unknown else "No supplied goal is below its requirement."
	elif unknown: result.missed_text += "\nOther goal progress: Unavailable."
	return result

static func build(model: Dictionary, trace: Dictionary, details: Dictionary = {}) -> Dictionary:
	var final: Dictionary = trace.get("final_state", {})
	var mission: Dictionary = trace.get("config", {}).get("mission", {})
	var supplied: Dictionary = details.duplicate(true)
	if supplied.get("run_id") != final.get("run_id") or supplied.get("mission_id") != final.get("mission_id") or supplied.get("execution_key") != Results.input_key(trace): supplied.clear()
	var stale: bool = model.get("state") == "stale_report"
	if stale: supplied.clear()
	# Objective overrides are limited to explicitly labeled previews.
	var preview: bool = supplied.get("fixture_label") is String and not supplied.fixture_label.is_empty()
	if preview and supplied.get("goal_progress") is Array: return _supplied_preview(model, trace, supplied)
	var kind: String = str(supplied.get("goal_type", mission.get("objective", ""))) if preview else str(mission.get("objective", ""))
	var bound: bool = model.get("state") == "report"
	var report: Dictionary = model.get("report", {}) if bound else {}
	var actuals: Dictionary = {} if stale else (report if bound else final)
	var requirements: Dictionary = {} if stale else (report if bound else mission)
	# Map the existing validated native counters into view-only fields. No mission
	# config, action policy or provider measurements are changed by this adapter.
	if not preview and not stale and kind in ["communication", "weather_monitoring"] and verified_native_trace(trace):
		var checked: Dictionary = preload("res://core/MissionStepEngine.gd").get_available_actions(final)
		var native: Variant = final.get("goal_progress")
		if checked.ok and native is Dictionary and native.get("kind") == kind:
			supplied.actual_count = native.get("actual_count")
			supplied.required_count = mission.get("goal", {}).get("required_positive_contact_steps" if kind == "communication" else "required_distinct_orbits")
			supplied.evidence_event_ids = native.get("evidence_event_ids", []).duplicate()
	var primary: Dictionary
	match kind:
		"communication": primary = metric("Positive downlink steps", supplied.get("actual_count"), supplied.get("required_count"), supplied.get("completion_ratio"), " steps")
		"weather_monitoring": primary = metric("Observed orbits · %s" % str(mission.get("target_region", "Unavailable")).replace("_", " ").capitalize(), supplied.get("actual_count"), supplied.get("required_count"), supplied.get("completion_ratio"), " orbits")
		"imaging", "survey": primary = metric("Captures", actuals.get("observations_completed"), requirements.get("required_observations"), report.get("observation_completion_ratio"), " captures")
		_: primary = metric("Goal progress unavailable", null, null)
	var data: Dictionary = metric("Returned to Earth", actuals.get("returned_data_mb"), requirements.get("required_returned_data_mb"), report.get("data_return_completion_ratio"), " MB")
	var rows: Array = [primary, data]
	var deliveries: Array = []
	if kind == "survey":
		var native_verified: bool = not stale and verified_native_trace(trace)
		for target in mission.get("target_regions", [mission.get("target_region", "")]):
			if str(target).is_empty(): continue
			var measured: Variant = null if stale else target_measurement(final, "observations_delivered_by_target", target, native_verified)
			var delivery: Dictionary = metric(str(target).replace("_", " ").capitalize(), measured, 1, null, " complete")
			delivery.context_text = delivery_context(final, str(target), stale, native_verified)
			deliveries.append(delivery)
			rows.append(delivery)
	var missed: Array[String] = []
	var unknown: bool = false
	for row in rows:
		if not row.known: unknown = true
		elif not row.reached: missed.append(row.label + ": " + row.verdict)
	# Only link events that resolve uniquely to this execution. Never infer causes.
	var index: Dictionary = {}
	var ambiguous: Array = []
	for event in same_run_events(trace):
		var id: Variant = event.get("event_id")
		if not id is String or id.is_empty(): continue
		if index.has(id): ambiguous.append(id)
		index[id] = event
	var references: Array[String] = []
	var requested: Array = supplied.evidence_event_ids.duplicate() if supplied.get("evidence_event_ids") is Array else []
	var causes: Array = report.root_causes if report.get("root_causes") is Array else []
	for cause in causes:
		if cause is Dictionary and cause.get("evidence_event_ids") is Array: requested.append_array(cause.evidence_event_ids)
	for id in requested:
		if id is String and index.has(id) and not ambiguous.has(id) and not references.has(id) and not stale: references.append(id)
	var evidence_text: String = "Unavailable" if references.is_empty() else ", ".join(references.slice(0, 8))
	if references.size() > 8: evidence_text += " (+%s in the ordered flight log)" % (references.size() - 8)
	var missed_text: String = "\n".join(missed)
	if missed_text.is_empty(): missed_text = "Unavailable where measurements or requirements are missing." if unknown else "No listed goal is below its requirement."
	elif unknown: missed_text += "\nOther goal progress: Unavailable."
	return {"goal_type":kind, "primary":primary, "data":data, "deliveries":deliveries,
		"missed_text":missed_text, "evidence_ids":references, "evidence_text":evidence_text,
		"fixture_label":supplied.get("fixture_label", "") if preview else "",
		"run_id":final.get("run_id"), "mission_id":final.get("mission_id")}
