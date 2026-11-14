extends RefCounted
## Callable comparison for candidate records. No storage/UI/runtime side effects.
const Records = preload("res://scripts/evaluation/mission_expansion_records.gd")
const Existing = preload("res://scripts/evaluation/mission_comparison.gd")

static func compare_runs(a_record: Variant, b_record: Variant) -> Dictionary:
	var a_checked: Dictionary = Records.validate_record(a_record)
	if not a_checked.ok: return a_checked
	var b_checked: Dictionary = Records.validate_record(b_record)
	if not b_checked.ok: return b_checked
	var a: Dictionary = a_checked.record
	var b: Dictionary = b_checked.record
	for record in [a, b]:
		if record.final_state.run_status != "completed": return _unavailable("RUN_NOT_COMPLETED", "final_state.run_status")
	if not Existing._same(Existing._requirements(a.config_snapshot), Existing._requirements(b.config_snapshot)): return _unavailable("REQUIREMENTS_MISMATCH", "config_snapshot")
	for key in ["evaluation_policy", "report_contract_revision", "evaluator_revision"]:
		if not Existing._same(a[key], b[key]): return _unavailable("CONTEXT_MISMATCH", key)
	for key in ["catalogs_snapshot", "source_versions", "initialization_policy", "legacy_identity_policy", "verification_scope"]:
		if not Existing._same(a.context[key], b.context[key]): return _unavailable("CONTEXT_MISMATCH", "context." + key)
	if not Existing._same(a.final_state.scenario_snapshot, b.final_state.scenario_snapshot): return _unavailable("SCENARIO_MISMATCH", "final_state.scenario_snapshot")
	var av: Dictionary = _normalized(a)
	var bv: Dictionary = _normalized(b)
	var values_a: Dictionary = Existing._values(av)
	var values_b: Dictionary = Existing._values(bv)
	var measures: Array = []
	for entry in [["observations_completed", "count"], ["returned_data_mb", "MB"], ["score", "points"], ["total_cost_credits", "credits"], ["total_mass_g", "g"], ["lowest_battery_wh", "Wh"], ["lowest_battery_percent", "percent"], ["highest_storage_mb", "MB"]]:
		measures.append(_delta(entry[0], entry[1], values_a.get(entry[0]), values_b.get(entry[0])))
	var goals: Array = []
	if a.report.goal_progress.size() != b.report.goal_progress.size(): return _unavailable("GOAL_MISMATCH", "report.goal_progress")
	for index in a.report.goal_progress.size():
		var ag: Dictionary = a.report.goal_progress[index]
		var bg: Dictionary = b.report.goal_progress[index]
		if ag.id != bg.id or ag.unit != bg.unit or ag.required != bg.required: return _unavailable("GOAL_MISMATCH", "report.goal_progress")
		goals.append(_delta(ag.id, ag.unit, ag.actual, bg.actual))
	var classification: Variant = null
	if a.context.get("operations") is Dictionary and b.context.get("operations") is Dictionary:
		classification = "Design" if Existing._same(a.context.operations.policy, b.context.operations.policy) and Existing._same(a.context.operations.manual_requests, b.context.operations.manual_requests) else "Design + operations"
	var changed: Array = []
	for key in a.config_snapshot.design:
		if a.config_snapshot.design[key] != b.config_snapshot.design[key]: changed.append({"field": key, "a": a.config_snapshot.design[key], "b": b.config_snapshot.design[key]})
	return {"ok": true, "comparison": {"proposal": true, "eligible": true, "classification": classification,
		"a_run_id": a.run_id, "b_run_id": b.run_id, "a_mission_id": a.mission_id, "b_mission_id": b.mission_id,
		"a_execution_key": a.execution_key, "b_execution_key": b.execution_key, "objective": a.report.objective,
		"outcomes": {"a": a.report.status, "b": b.report.status}, "measures": measures, "goal_measures": goals,
		"goal_progress": {"a": a.report.goal_progress.duplicate(true), "b": b.report.goal_progress.duplicate(true)},
		"target_deliveries": {"a": a.final_state.get("observations_delivered_by_target"), "b": b.final_state.get("observations_delivered_by_target")}.duplicate(true),
		"requirements": a.config_snapshot.mission.duplicate(true), "changed_parts": changed,
		"interpretation": "Measured B minus A for this pair only. Proposed scoring, identity and sampling rules apply. Multiple changes limit causal attribution; missing operations context leaves classification unavailable."}}

static func _normalized(record: Dictionary) -> Dictionary:
	return {"report": record.report, "validation": record.validation_snapshot, "initial_state": record.context.initial_state,
		"final_state": record.final_state, "resource_samples": record.context.get("resource_samples"),
		"resource_sampling_id": record.context.get("resource_sampling_id") if _sampling_matches(record) else null}

static func _sampling_matches(record: Dictionary) -> bool:
	var samples: Variant = record.context.get("resource_samples")
	if not samples is Array or samples.size() != int(record.final_state.total_steps) + 1: return false
	var accepted: Dictionary = {}
	for event: Dictionary in record.events:
		if event.get("type") == "action_accepted" and not accepted.has(int(event.step_index)): accepted[int(event.step_index)] = event
	for step in int(record.final_state.total_steps):
		if not accepted.has(step) or not samples[step] is Dictionary or not samples[step + 1] is Dictionary: return false
		var event: Dictionary = accepted[step]
		for number in [event.get("delta_energy_wh"), event.get("stored_data_mb"), samples[step].get("energy_wh"), samples[step + 1].get("energy_wh"), samples[step + 1].get("stored_data_mb")]:
			if not Existing.Evaluator._is_finite_number(number): return false
		if not Records.Evaluation._close(samples[step + 1].energy_wh, samples[step].energy_wh + event.delta_energy_wh) or not Records.Evaluation._close(samples[step + 1].stored_data_mb, event.stored_data_mb): return false
	return true

static func _delta(id: String, unit: String, a: Variant, b: Variant) -> Dictionary:
	var known: bool = Existing.Evaluator._is_finite_number(a) and Existing.Evaluator._is_finite_number(b)
	return {"id": id, "unit": unit, "delta_unit": "percentage_points" if unit == "percent" else unit,
		"a": a, "b": b, "available": known, "delta_b_minus_a": b - a if known else null,
		"unavailable_reason": null if known else "Matching optional measurements or the explicit candidate sampling definition are unavailable."}

static func _unavailable(code: String, path: String) -> Dictionary:
	var result: Dictionary = Existing._blocked(code, path)
	result.erase("ok")
	return {"ok": true, "comparison": result}
