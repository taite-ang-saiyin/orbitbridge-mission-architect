extends RefCounted
## Descriptive comparison of execution-bound records after Design Lab's eligibility
## gates. Reuses published scores; never evaluates a new score or changes a run.
const Results = preload("res://scripts/integration/mission_results.gd")
const Words = preload("res://scripts/presentation/PlayerLanguage.gd")

static func compare(pair: Dictionary) -> Dictionary:
	var values: Array = []
	for side in ["a", "b"]:
		var packet: Dictionary = pair.get(side, {})
		var trace: Dictionary = packet.get("trace", {})
		if packet.get("execution_key") != Results.input_key(trace) or trace.get("final_state", {}).get("run_status") != "completed":
			return {"ok":false,"error":{"code":"EXECUTION_MISMATCH","message":"Comparison requires the original completed flight records."}}
		values.append(measurements(trace, packet.get("evaluation", {})))
	var a: Dictionary = values[0]
	var b: Dictionary = values[1]
	var metrics: Dictionary = {}
	for key in a:
		var left: Variant = a[key]
		var right: Variant = b.get(key)
		metrics[key] = {"a":left,"b":right,"delta":right-left if numeric(left) and numeric(right) else null}
	var changed: Array = []
	for slot in ["bus", "instrument", "solar", "battery", "radio", "storage"]:
		var key: String = slot + "_id"
		var left: Variant = pair.a.trace.config.design.get(key)
		var right: Variant = pair.b.trace.config.design.get(key)
		if left != right: changed.append({"slot":slot.capitalize(),"a":left,"b":right})
	var difference: float = b.returned_data_mb - a.returned_data_mb
	var explanation: String = "B returned the same amount of data as A." if is_zero_approx(difference) else "B returned %s MB %s than A." % [Words.amount(absf(difference)), "more" if difference > 0 else "less"]
	var scored: bool = numeric(a.score) and numeric(b.score)
	if scored: explanation += " Score change: %s points." % Words.amount(b.score - a.score)
	else: explanation += " Scoring is unavailable for this mission. These are recorded measurements."
	if changed.is_empty(): explanation += " No spacecraft components changed."
	var result: Dictionary = {"eligible":true,"classification":pair.get("mode"),"metrics":metrics,"changed_parts":changed,
		"interpretation":explanation,"scored":scored,"reasons":[],
		"limitations":["Measurements describe these two flights; a change alone does not establish a cause.", "Battery and storage extrema use the initial state and recorded step samples."]}
	for side in ["a", "b"]:
		result[side+"_run_id"] = pair[side].run_id
		result[side+"_mission_id"] = pair[side].mission_id
		result[side+"_execution_key"] = pair[side].execution_key
	return {"ok":true,"comparison":result}

static func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value)

static func measurements(trace: Dictionary, evaluation: Dictionary) -> Dictionary:
	var final: Dictionary = trace.get("final_state", {})
	var mission: Dictionary = trace.get("config", {}).get("mission", {})
	var metrics: Dictionary = trace.get("validation", {}).get("metrics", {})
	var report: Dictionary = evaluation.get("report", {}) if evaluation.get("ok") == true else {}
	var count: Variant = final.get("observations_completed")
	if mission.get("objective") in ["communication", "weather_monitoring"]: count = final.get("goal_progress", {}).get("actual_count")
	if mission.get("objective") == "survey":
		count = null
		if final.get("observations_delivered_by_target") is Dictionary:
			count = 0
			for target in mission.get("target_regions", [mission.get("target_region")]):
				if final.observations_delivered_by_target.get(target, 0) >= 1: count += 1
	var minimum: Variant = null
	var peak: Variant = null
	for frame in trace.get("frames", []):
		var state: Dictionary = frame.get("state", {})
		if not numeric(state.get("energy_wh")) or not numeric(state.get("stored_data_mb")):
			minimum = null; peak = null; break
		minimum = state.energy_wh if minimum == null else minf(minimum, state.energy_wh)
		peak = state.stored_data_mb if peak == null else maxf(peak, state.stored_data_mb)
	return {"outcome":report.get("status", "Not scored"),"score":report.get("score"),
		"qualifying_count":count,"returned_data_mb":final.get("returned_data_mb"),
		"lowest_battery_wh":minimum,"lowest_battery_percent":100.0*minimum/final.battery_capacity_wh if numeric(minimum) and final.get("battery_capacity_wh",0)>0 else null,
		"peak_storage_mb":peak,"total_mass_g":metrics.get("total_mass_g"),"total_cost_credits":metrics.get("total_cost_credits")}
