extends RefCounted
## Candidate transport/binding helper; SE still owns persistence and Save A lifecycle.
const Evaluation = preload("res://scripts/evaluation/mission_expansion_candidate.gd")
const Comparison = preload("res://scripts/evaluation/mission_comparison.gd")
const REVISION = "ke2-execution-record-candidate-1"
const SAMPLING = "initial_and_each_accepted_poststep_v1_proposal"

static func build_record(config: Dictionary, state: Dictionary, events: Array, validation: Dictionary, context: Dictionary, policy: Dictionary = {}) -> Dictionary:
	var selected: Dictionary = Evaluation.default_policy() if policy.is_empty() else policy.duplicate(true)
	var evaluated: Dictionary = Evaluation.evaluate_with_policy(config, state, events, selected)
	if not evaluated.ok: return evaluated
	var record: Dictionary = {"record_schema_version": 1, "record_revision": REVISION,
		"report_contract_revision": Evaluation.REPORT_REVISION, "evaluator_revision": Evaluation.EVALUATOR_REVISION,
		"run_id": state.run_id, "mission_id": state.mission_id, "config_snapshot": config.duplicate(true),
		"final_state": state.duplicate(true), "events": events.duplicate(true), "validation_snapshot": validation.duplicate(true),
		"report": evaluated.report, "evaluation_policy": selected, "context": context.duplicate(true)}
	var encoded: String = JSON.stringify([config, state, events, validation], "", true, true)
	record.key_preimage_utf8 = encoded
	record.execution_key = encoded.sha256_text()
	var sealed: Dictionary = seal(record)
	var checked: Dictionary = validate_record(sealed)
	if not checked.ok: return checked
	return {"ok": true, "record": sealed}

static func seal(record: Dictionary) -> Dictionary:
	# Integrity, not authentication. Caller must only seal trusted captured inputs.
	var result: Dictionary = record.duplicate(true)
	result.erase("content_preimage_utf8")
	result.erase("content_digest")
	result.digest_algorithm = "sha256-utf8-json-sorted-fullprecision"
	result.content_preimage_utf8 = JSON.stringify(result, "", true, true)
	result.content_digest = result.content_preimage_utf8.sha256_text()
	return result

static func validate_record(value: Variant) -> Dictionary:
	if not value is Dictionary: return _bad("record")
	var encoded: Variant = value.get("content_preimage_utf8")
	if not encoded is String or not value.get("content_digest") is String or encoded.sha256_text() != value.content_digest: return _bad("record.content_digest")
	var payload: Dictionary = value.duplicate(true)
	payload.erase("content_preimage_utf8"); payload.erase("content_digest")
	var parsed: Variant = JSON.parse_string(encoded)
	if not parsed is Dictionary or not Comparison._same(parsed, payload): return _bad("record.content_preimage_utf8")
	# Only decode text already verified as JSON. Variant parsing preserves original
	# integer/decimal types, so transported execution keys are never regenerated.
	var typed: Variant = str_to_var(encoded)
	if not typed is Dictionary or not Comparison._same(typed, parsed) or not _json_value(typed): return _bad("record.content_preimage_utf8")
	var record: Dictionary = typed
	if not Evaluation.Base._is_whole_number(record.get("record_schema_version")) or record.record_schema_version != 1 or record.get("record_revision") != REVISION or record.get("digest_algorithm") != "sha256-utf8-json-sorted-fullprecision": return _bad("record.record_revision")
	if record.get("report_contract_revision") != Evaluation.REPORT_REVISION or record.get("evaluator_revision") != Evaluation.EVALUATOR_REVISION: return _bad("record.evaluator_revision")
	for field in ["config_snapshot", "final_state", "validation_snapshot", "report", "context", "evaluation_policy"]:
		if not record.get(field) is Dictionary: return _bad("record." + field)
	if not record.get("events") is Array: return _bad("record.events")
	var state: Dictionary = record.final_state
	if record.get("run_id") != state.get("run_id") or record.get("mission_id") != state.get("mission_id"): return _bad("record.run_id")
	var key_bytes: Variant = record.get("key_preimage_utf8")
	if not key_bytes is String or key_bytes.sha256_text() != record.get("execution_key") or not Comparison._same(JSON.parse_string(key_bytes), [record.config_snapshot, state, record.events, record.validation_snapshot]): return _bad("record.execution_key")
	# A decimal parser may round a last bit; the verified original UTF-8 preimage
	# is authoritative for hashing. Never substitute a reserialized key.
	if record.validation_snapshot.get("ready_to_launch") != true: return _bad("record.validation_snapshot")
	if record.validation_snapshot.has("config") and record.validation_snapshot.config != record.config_snapshot: return _bad("record.validation_snapshot.config")
	var evaluated: Dictionary = Evaluation.evaluate_with_policy(record.config_snapshot, state, record.events, record.evaluation_policy)
	if not evaluated.ok: return evaluated
	if not _equivalent(evaluated.report, record.report): return _bad("record.report")
	var context: Dictionary = record.context
	for field in ["initial_state", "catalogs_snapshot", "source_versions", "source_credits", "display_context"]:
		if not context.get(field) is Dictionary: return _bad("record.context." + field)
	if not context.get("verification_scope") in ["native_modules", "typed_proxy_fixture"]: return _bad("record.context.verification_scope")
	if context.get("initialization_policy") != "full_battery_empty_v1_proposal" or context.get("legacy_identity_policy") != "exact_requirements_v1_proposal": return _bad("record.context.initialization_policy")
	for field in ["engine", "adapter", "catalogs", "scenario", "evaluator", "report"]:
		if not context.source_versions.get(field) is String or context.source_versions[field].is_empty(): return _bad("record.context.source_versions." + field)
	if context.source_versions.evaluator != Evaluation.EVALUATOR_REVISION or context.source_versions.report != Evaluation.REPORT_REVISION or context.source_versions.scenario != state.scenario_snapshot.scenario_version: return _bad("record.context.source_versions")
	var initial: Dictionary = context.initial_state
	for field in ["run_id", "mission_id", "config_snapshot", "scenario_snapshot", "battery_capacity_wh", "storage_capacity_mb"]:
		if initial.get(field) != state.get(field): return _bad("record.context.initial_state." + field)
	if initial.get("phase") != "operating" or initial.get("step_index") != 0 or initial.get("energy_wh") != state.battery_capacity_wh: return _bad("record.context.initial_state")
	for field in ["stored_data_mb", "returned_data_mb", "observations_completed"]:
		if initial.get(field) != 0: return _bad("record.context.initial_state." + field)
	if not initial.get("event_log") is Array or not initial.event_log.is_empty(): return _bad("record.context.initial_state.event_log")
	# Catalogs are retained separately for SE; bind them to the actual scenario.
	if context.catalogs_snapshot != state.scenario_snapshot: return _bad("record.context.catalogs_snapshot")
	if context.has("operations") and context.operations != null and not Comparison._operation_context(context.operations, {"events": record.events}): return _bad("record.context.operations")
	record.content_preimage_utf8 = encoded
	record.content_digest = value.content_digest
	return {"ok": true, "record": record}

static func _json_value(value: Variant) -> bool:
	if value == null or value is String or value is bool or value is int: return true
	if value is float: return is_finite(value)
	if value is Array:
		for item in value:
			if not _json_value(item): return false
		return true
	if value is Dictionary:
		for key in value:
			if not key is String or not _json_value(value[key]): return false
		return true
	return false

static func _equivalent(a: Variant, b: Variant) -> bool:
	# Permit only parser roundoff in decimals. Counts, scores, booleans, nulls,
	# strings, field sets, ordering and verdicts must still reproduce exactly.
	if a is float and b is float: return absf(a - b) <= 1e-14 * maxf(1.0, maxf(absf(a), absf(b)))
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not _equivalent(a[key], b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not _equivalent(a[i], b[i]): return false
		return true
	return a == b

static func _bad(path: String) -> Dictionary:
	return Evaluation._bad(path, {})
