extends RefCounted
## KE2 internal comparison prototype; normalized inputs below are fixture proposals.
## Not called by evaluate_mission, SE storage or UI. No public record API ratification.
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const Goals = preload("res://scripts/evaluation/mission_goal_evidence.gd")

static func _eligibility(a: Variant, b: Variant) -> Dictionary:
	for side in [["a", a], ["b", b]]:
		var record: Variant = side[1]
		if not record is Dictionary: return _blocked("MISSING_RECORD", side[0])
		for key in ["config", "final_state", "report", "validation", "context", "operations", "initial_state"]:
			if not record.get(key) is Dictionary: return _blocked("MISSING_CONTEXT", side[0] + "." + key)
		if record.final_state.get("phase") != "finished" or record.final_state.get("run_status") != "completed": return _blocked("RUN_NOT_COMPLETED", side[0])
		if not _bound(record): return _blocked("BINDING_MISMATCH", side[0])
		for key in ["catalogs_fingerprint", "report_contract_revision", "legacy_identity_policy", "initialization_policy"]:
			if not record.context.get(key) is String or record.context[key].is_empty(): return _blocked("UNKNOWN_CONTEXT", side[0] + ".context." + key)
		if not record.context.get("versions") is Dictionary: return _blocked("UNKNOWN_VERSION", side[0])
		for key in ["engine", "adapter", "catalogs", "scenario", "evaluator", "report"]:
			if not record.context.versions.get(key) is String or record.context.versions[key].is_empty(): return _blocked("UNKNOWN_VERSION", side[0] + "." + key)
		if record.context.initialization_policy != "full_battery_empty_v1_proposal": return _blocked("UNSUPPORTED_INITIALIZATION", side[0])
		var initial: Dictionary = record.initial_state
		var capacity: Variant = record.final_state.get("battery_capacity_wh")
		if not Evaluator._is_finite_number(capacity) or capacity <= 0 or not Evaluator._is_finite_number(initial.get("energy_wh")): return _blocked("UNKNOWN_INITIAL_STATE", side[0])
		if absf(float(initial.energy_wh) - float(capacity)) > 1e-8: return _blocked("INITIAL_STATE_MISMATCH", side[0])
		for key in ["stored_data_mb", "returned_data_mb", "observations_completed"]:
			if not Evaluator._is_finite_number(initial.get(key)) or initial[key] != 0: return _blocked("INITIAL_STATE_MISMATCH", side[0])
		var operations: Dictionary = record.operations
		if not operations.get("policy") is Dictionary or not operations.get("manual_requests") is Array: return _blocked("UNKNOWN_OPERATIONS", side[0])
		if not operations.policy.get("id") is String or operations.policy.id.is_empty() or not Evaluator._is_whole_number(operations.policy.get("version")) or operations.policy.version <= 0 or not operations.policy.get("parameters") is Dictionary: return _blocked("UNKNOWN_OPERATIONS", side[0])
		var previous: int = -1
		for request in operations.manual_requests:
			if not request is Dictionary or not Evaluator._is_whole_number(request.get("step_index")) or request.step_index < 0 or request.step_index < previous or request.step_index >= record.final_state.total_steps or not request.get("action") in ["observe", "transmit", "power_save"]: return _blocked("INVALID_MANUAL_PLAN", side[0])
			previous = int(request.step_index)
	if not _same(_requirements(a.config), _requirements(b.config)): return _blocked("REQUIREMENTS_MISMATCH", "config")
	if not _same(a.context, b.context): return _blocked("CONTEXT_MISMATCH", "context")
	if not _same(a.final_state.get("scenario_snapshot"), b.final_state.get("scenario_snapshot")): return _blocked("SCENARIO_MISMATCH", "final_state.scenario_snapshot")
	var same_operations: bool = _same(a.operations.policy, b.operations.policy) and _same(a.operations.manual_requests, b.operations.manual_requests)
	return {"ok": true, "proposal": true, "eligible": true, "classification": "Design" if same_operations else "Design + operations", "reasons": []}

static func _deltas(a: Dictionary, b: Dictionary) -> Dictionary:
	var eligibility: Dictionary = _eligibility(a, b)
	if not eligibility.eligible: return eligibility
	var av: Dictionary = _values(a)
	var bv: Dictionary = _values(b)
	var rows: Array = []
	for entry in [["observations_completed", "count"], ["returned_data_mb", "MB"], ["score", "points"],
		["lowest_battery_wh", "Wh"], ["lowest_battery_percent", "percent"], ["highest_storage_mb", "MB"],
		["total_cost_credits", "credits"], ["total_mass_g", "g"]]:
		var id: String = entry[0]
		var known: bool = Evaluator._is_finite_number(av.get(id)) and Evaluator._is_finite_number(bv.get(id))
		rows.append({"id": id, "unit": entry[1], "delta_unit": "percentage_points" if entry[1] == "percent" else entry[1],
			"a": av.get(id), "b": bv.get(id), "available": known,
			"delta_b_minus_a": bv[id] - av[id] if known else null,
			"unavailable_reason": null if known else "Missing or invalid measurement; resource sampling must use the reviewed explicit fixture definition."})
	var parts: Array = []
	for key in ["bus_id", "instrument_id", "solar_id", "battery_id", "radio_id", "storage_id"]:
		if a.config.design.get(key) != b.config.design.get(key): parts.append({"field": key, "a": a.config.design.get(key), "b": b.config.design.get(key)})
	return {"ok": true, "proposal": true, "eligible": true, "classification": eligibility.classification,
		"outcomes": {"a": a.report.status, "b": b.report.status}, "measures": rows, "changed_parts": parts,
		"requirements": {"a": a.config.mission.duplicate(true), "b": b.config.mission.duplicate(true)},
		"goal_progress": {"a": a.report.get("goal_progress", null), "b": b.report.get("goal_progress", null)}.duplicate(true),
		"target_deliveries": {"a": a.final_state.get("observations_delivered_by_target", null), "b": b.final_state.get("observations_delivered_by_target", null)}.duplicate(true),
		"interpretation": "Measured B minus A for this pair only. Different manual operations combine design and operation effects; matching policy alone is not a general causal guarantee."}

static func _values(record: Dictionary) -> Dictionary:
	var values: Dictionary = {"observations_completed": record.report.observations_completed, "returned_data_mb": record.report.returned_data_mb, "score": record.report.score,
		"lowest_battery_wh": null, "lowest_battery_percent": null, "highest_storage_mb": null, "total_cost_credits": null, "total_mass_g": null}
	var metrics: Variant = record.validation.get("metrics")
	if metrics is Dictionary:
		for key in ["total_cost_credits", "total_mass_g"]:
			if Evaluator._is_whole_number(metrics.get(key)) and metrics[key] >= 0: values[key] = metrics[key]
	var samples: Variant = record.get("resource_samples")
	var final: Dictionary = record.final_state
	if record.get("resource_sampling_id") != "initial_and_each_accepted_poststep_v1_proposal" or not samples is Array or samples.size() != int(final.total_steps) + 1: return values
	var capacity: Variant = final.get("battery_capacity_wh")
	var storage: Variant = final.get("storage_capacity_mb")
	if not Evaluator._is_finite_number(capacity) or capacity <= 0 or not Evaluator._is_finite_number(storage) or storage < 0: return values
	var minimum: float = INF
	var peak: float = 0
	for index in samples.size():
		var sample: Variant = samples[index]
		if not sample is Dictionary or not Evaluator._is_whole_number(sample.get("step_index")) or sample.step_index != index: return values
		if not Evaluator._is_finite_number(sample.get("energy_wh")) or not Evaluator._is_finite_number(sample.get("stored_data_mb")): return values
		if sample.energy_wh < 0 or sample.energy_wh > capacity + 1e-8 or sample.stored_data_mb < 0 or sample.stored_data_mb > storage + 1e-8: return values
		minimum = minf(minimum, sample.energy_wh)
		peak = maxf(peak, sample.stored_data_mb)
	if samples[0].energy_wh != record.initial_state.energy_wh or samples[0].stored_data_mb != record.initial_state.stored_data_mb: return values
	if samples[-1].energy_wh != final.get("energy_wh") or samples[-1].stored_data_mb != final.get("stored_data_mb"): return values
	values.lowest_battery_wh = minimum
	values.lowest_battery_percent = 100.0 * minimum / float(capacity)
	values.highest_storage_mb = peak
	return values

static func _bound(record: Dictionary) -> bool:
	var encoded: Variant = record.get("key_preimage_utf8")
	if not encoded is String or not record.get("execution_key") is String or encoded.sha256_text() != record.execution_key: return false
	if not record.get("events") is Array or not record.config.get("mission") is Dictionary or not record.config.get("design") is Dictionary: return false
	if not _same(JSON.parse_string(encoded), [record.config, record.final_state, record.events, record.validation]): return false
	var state: Dictionary = record.final_state
	var report: Dictionary = record.report
	for field in Evaluator.REPORT_FIELDS:
		if not report.has(field): return false
	if JSON.stringify(report, "", true, true).sha256_text() != record.get("report_digest"): return false
	for version in [record.config.get("schema_version"), report.get("schema_version")]:
		if not Evaluator._is_whole_number(version) or (version != 1 and version != 2): return false
	if not _same(state.get("config_snapshot"), record.config) or not _same(state.get("event_log"), record.events): return false
	if record.validation.get("ready_to_launch") != true or state.get("scenario_id") != record.config.design.get("orbit_id"): return false
	if not Goals._events(state, record.events).ok: return false
	if not Evaluator._is_whole_number(state.get("total_steps")) or state.total_steps <= 0 or state.get("step_index") != state.total_steps: return false
	for key in ["run_id", "mission_id", "run_status", "observations_completed", "returned_data_mb"]:
		if report.get(key) != state.get(key) or not report.has(key): return false
	for key in ["run_id", "mission_id"]:
		if not state.get(key) is String or state[key].is_empty(): return false
	if report.has("objective") and report.objective != record.config.mission.get("objective"): return false
	for key in ["required_observations", "required_returned_data_mb"]:
		if report.get(key) != record.config.mission.get(key) or not Evaluator._is_finite_number(report.get(key)) or report[key] <= 0: return false
	if not Evaluator._is_whole_number(report.required_observations): return false
	if not Evaluator._is_whole_number(report.get("observations_completed")) or report.observations_completed < 0: return false
	if not Evaluator._is_finite_number(report.get("returned_data_mb")) or report.returned_data_mb < 0: return false
	if not report.get("status") in ["success", "partial", "failed"] or not Evaluator._is_whole_number(report.get("score")) or report.score < 0 or report.score > 100: return false
	var ids: Array = record.events.map(func(e): return e.event_id)
	if not report.get("root_causes") is Array: return false
	for cause in report.root_causes:
		if not cause is Dictionary or not cause.get("evidence_event_ids") is Array: return false
		for id in cause.evidence_event_ids:
			if not id in ids: return false
	return true

static func _requirements(config: Dictionary) -> Dictionary:
	var mission: Dictionary = config.mission.duplicate(true)
	mission.erase("title")
	if not mission.has("target_regions"): mission.target_regions = [mission.get("target_region")]
	var design: Dictionary = config.design.duplicate(true)
	for key in ["bus_id", "instrument_id", "solar_id", "battery_id", "radio_id", "storage_id"]: design.erase(key)
	return {"schema_version": config.get("schema_version"), "contract_revision": config.get("contract_revision"),
		"preset_id": config.get("preset_id"), "preset_revision": config.get("preset_revision"), "mission": mission, "setup": design}

static func _same(a: Variant, b: Variant) -> bool:
	# Semantic value comparison only. This is deliberately NOT execution-key hashing.
	return JSON.parse_string(JSON.stringify(a, "", true, true)) == JSON.parse_string(JSON.stringify(b, "", true, true))

static func _blocked(code: String, path: String) -> Dictionary:
	return {"ok": true, "proposal": true, "eligible": false, "classification": null,
		"reasons": [{"code": code, "field_path": path, "message": "Resolve the missing or mismatched " + path + " before comparing."}]}
