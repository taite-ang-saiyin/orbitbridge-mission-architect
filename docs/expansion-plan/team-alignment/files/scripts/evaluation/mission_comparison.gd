extends RefCounted
## Callable v1 Imaging analytical comparison plus internal expansion prototypes.
## SE owns Save A/runtime/UI wiring. Expansion normalization below remains proposed.
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const Goals = preload("res://scripts/evaluation/mission_goal_evidence.gd")

## Accept current SE records: {report, state, validation, execution_key}.
## Optional key_preimage_utf8 supports historical records transported through JSON.
## Optional operations metadata classifies requested choices, not hardware causality.
## Returns an independent {ok, comparison} result or the existing structured error.
static func compare_runs(a_record: Variant, b_record: Variant) -> Dictionary:
	var records: Array = []
	for entry in [["a", a_record], ["b", b_record]]:
		var checked: Dictionary = _published_record(entry[1], entry[0])
		if not checked.ok or checked.has("comparison"): return checked
		records.append(checked.record)
	var a: Dictionary = records[0]
	var b: Dictionary = records[1]
	if not _same(_requirements(a.config), _requirements(b.config)): return _unavailable("REQUIREMENTS_MISMATCH", "config")
	if not _same(a.final_state.scenario_snapshot, b.final_state.scenario_snapshot): return _unavailable("SCENARIO_MISMATCH", "state.scenario_snapshot")
	var av: Dictionary = _values(a)
	var bv: Dictionary = _values(b)
	var rows: Array = []
	for spec in [["observations_completed", "count"], ["returned_data_mb", "MB"], ["score", "points"], ["total_mass_g", "g"], ["total_cost_credits", "credits"], ["lowest_battery_wh", "Wh"], ["highest_storage_mb", "MB"]]:
		var id: String = spec[0]
		var known: bool = Evaluator._is_finite_number(av.get(id)) and Evaluator._is_finite_number(bv.get(id))
		rows.append({"id": id, "unit": spec[1], "a": av.get(id), "b": bv.get(id), "available": known,
			"delta_b_minus_a": bv[id] - av[id] if known else null,
			"unavailable_reason": null if known else "Optional measurement or agreed resource-sampling evidence is unavailable."})
	var classification: Variant = null
	var operations_a: Variant = a_record.get("operations")
	var operations_b: Variant = b_record.get("operations")
	if _operation_context(operations_a, a) and _operation_context(operations_b, b):
		classification = "Design" if _same(operations_a.policy, operations_b.policy) and _same(operations_a.manual_requests, operations_b.manual_requests) else "Design + operations"
	var parts: Array = []
	for key in ["bus_id", "instrument_id", "solar_id", "battery_id", "radio_id", "storage_id"]:
		if a.config.design.get(key) != b.config.design.get(key): parts.append({"field": key, "a": a.config.design.get(key), "b": b.config.design.get(key)})
	return {"ok": true, "comparison": {"eligible": true, "classification": classification, "objective": "imaging",
		"a_run_id": a.final_state.run_id, "b_run_id": b.final_state.run_id,
		"a_mission_id": a.final_state.mission_id, "b_mission_id": b.final_state.mission_id,
		"a_execution_key": a_record.execution_key, "b_execution_key": b_record.execution_key,
		"outcomes": {"a": a.report.status, "b": b.report.status}, "measures": rows, "changed_parts": parts,
		"reasons": [], "limitations": ["Descriptive v1 comparison of bound recorded results; no single-component causal guarantee.",
			"Operations classification requires explicit versioned requested-policy/manual context; missing context remains unclassified.",
			"Resource extrema, producer-version/initialization guarantees and expansion eligibility await their coordinated record contract."]}}

static func _published_record(value: Variant, path: String) -> Dictionary:
	if not value is Dictionary: return _public_error(path, null)
	var state: Variant = value.get("state", value.get("final_state"))
	var id: Variant = state.get("run_id") if state is Dictionary else null
	if not state is Dictionary or not value.get("report") is Dictionary or not value.get("validation") is Dictionary: return _public_error(path, id)
	if state.get("phase") != "finished" or state.get("run_status") != "completed": return _unavailable("RUN_NOT_COMPLETED", path + ".state.run_status")
	var config: Variant = state.get("config_snapshot")
	if not config is Dictionary or not config.get("mission") is Dictionary or not config.get("design") is Dictionary or not state.get("event_log") is Array or not state.get("scenario_snapshot") is Dictionary: return _public_error(path + ".state", id)
	if value.has("config") and not _same(value.config, config): return _public_error(path + ".config", id)
	if not Evaluator._is_whole_number(value.report.get("schema_version")): return _public_error(path + ".report.schema_version", id)
	if config.mission.get("objective") != "imaging" or value.report.get("schema_version") != 1: return _unavailable("SCORING_CONTRACT_PENDING", path + ".report")
	if not state.scenario_snapshot.get("scenario_version") is String or state.scenario_snapshot.scenario_version.is_empty() or not state.scenario_snapshot.get("orbits") is Array: return _public_error(path + ".state.scenario_snapshot", id)
	if state.get("scenario_id") != config.design.get("orbit_id"): return _public_error(path + ".state.scenario_id", id)
	if value.report.size() != Evaluator.REPORT_FIELDS.size(): return _unavailable("REPORT_CONTRACT_PENDING", path + ".report")
	if value.validation.get("ready_to_launch") != true: return _public_error(path + ".validation", id)
	var inputs: Array = [config, state, state.event_log, value.validation]
	var key: Variant = value.get("execution_key")
	var matches: bool = key is String and JSON.stringify(inputs, "", true, true).sha256_text() == key
	if not matches:
		var retained: Variant = value.get("key_preimage_utf8")
		matches = key is String and retained is String and retained.sha256_text() == key and _same(JSON.parse_string(retained), inputs)
		if matches:
			# Parse ONLY already hash-verified, valid JSON. Variant parsing preserves the
			# original integer/float spellings needed to reproduce historical feedback.
			# No object-enabled deserialization or replacement execution key is used.
			var typed: Variant = str_to_var(retained)
			if not typed is Array or typed.size() != 4 or not _same(typed, inputs): return _public_error(path + ".execution_key", id)
			inputs = typed
			config = inputs[0]
			state = inputs[1]
	if not matches: return _public_error(path + ".execution_key", id)
	var history: Dictionary = Goals._events(state, state.event_log)
	if not history.ok: return _public_error(path + ".state.event_log", id)
	var evaluated: Dictionary = Evaluator.evaluate_mission(config, state, state.event_log)
	if not evaluated.get("ok", false): return _public_error(path + ".report", id)
	for field in Evaluator.REPORT_FIELDS:
		if not value.report.has(field) or (field != "comparison" and not _same(value.report[field], evaluated.report[field])): return _public_error(path + ".report." + field, id)
	return {"ok": true, "record": {"config": config.duplicate(true), "final_state": state.duplicate(true),
		"events": state.event_log.duplicate(true), "validation": value.validation.duplicate(true), "report": value.report.duplicate(true),
		"initial_state": {}, "resource_sampling_id": null}}

static func _operation_context(value: Variant, record: Dictionary) -> bool:
	if not value is Dictionary or not value.get("policy") is Dictionary or not value.get("manual_requests") is Array or not value.get("requested_actions") is Array: return false
	if not value.policy.get("id") is String or value.policy.id.is_empty() or not Evaluator._is_whole_number(value.policy.get("version")) or value.policy.version <= 0 or not value.policy.get("parameters") is Dictionary: return false
	var requested: Array = []
	for event in record.events:
		if event.get("type") in ["action_accepted", "action_blocked"]: requested.append({"step_index": event.step_index, "action": event.get("action")})
	if not _same(requested, value.requested_actions): return false
	var cursor: int = 0
	for manual in value.manual_requests:
		if not manual is Dictionary or not Evaluator._is_whole_number(manual.get("step_index")) or manual.step_index < 0 or not manual.get("action") in ["observe", "transmit", "power_save"]: return false
		while cursor < requested.size() and not _same(manual, requested[cursor]): cursor += 1
		if cursor == requested.size(): return false
		cursor += 1
	return true

static func _unavailable(code: String, path: String) -> Dictionary:
	var candidate: Dictionary = _blocked(code, path)
	candidate.erase("proposal")
	return {"ok": true, "comparison": {"eligible": false, "classification": null, "reasons": candidate.reasons}}

static func _public_error(path: String, id: Variant) -> Dictionary:
	if not id is String or id.strip_edges().is_empty(): id = null
	return Evaluator._error(Evaluator.INVALID_INPUT, path, "Comparison requires a bound completed v1 Imaging report and its original execution/readiness.",
		"Use SE's immutable report/state/validation/execution_key record. Preserve original hash bytes for JSON-transported inputs.", id)

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
