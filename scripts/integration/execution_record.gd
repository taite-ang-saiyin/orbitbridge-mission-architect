extends RefCounted
## Portable evidence envelope. Original UTF-8 preimages, not JSON reserialization,
## are authoritative for hashes. Decoded records do not restore runtime sessions.
const RECORD_VERSION = 1
const KEY_VERSION = "godot-json-full-precision-v1"
const DIGEST_VERSION = "sha256-retained-utf8-v1"

static func failure(message: String) -> Dictionary:
	return {"ok":false,"error":{"code":"INVALID_EXECUTION_RECORD","message":message}}

static func input_values(trace: Dictionary) -> Array:
	return [trace.get("config"), trace.get("final_state"), trace.get("events"), trace.get("validation")]

static func is_json_value(value: Variant) -> bool:
	if value == null or value is String or value is StringName or value is bool: return true
	if value is int: return value >= -9007199254740991 and value <= 9007199254740991
	if value is float: return is_finite(value)
	if value is Array:
		for item in value:
			if not is_json_value(item): return false
		return true
	if value is Dictionary:
		for key in value:
			if not (key is String or key is StringName) or not is_json_value(value[key]): return false
		return true
	return false

static func same_json_values(a: Variant, b: Variant) -> bool:
	# Compare transport views; do not use these normalized bytes as historical keys.
	if not is_json_value(a) or not is_json_value(b): return false
	return JSON.stringify(JSON.parse_string(JSON.stringify(a, "", true, true)), "", true, true) == JSON.stringify(JSON.parse_string(JSON.stringify(b, "", true, true)), "", true, true)

static func content_fields(record: Dictionary) -> Dictionary:
	var content: Dictionary = record.duplicate(true)
	content.erase("content_digest")
	content.erase("content_preimage_utf8")
	return content

static func encode(packet: Dictionary, retained_key_preimage: String = "") -> Dictionary:
	if not is_json_value(packet) or not packet.get("trace") is Dictionary:
		return failure("A JSON-safe execution packet is required; nonfinite numbers and unsafe integers cannot be transported.")
	var bytes: String = retained_key_preimage
	if bytes.is_empty(): bytes = JSON.stringify(input_values(packet.trace), "", true, true)
	if bytes.sha256_text() != packet.get("execution_key") or not same_json_values(JSON.parse_string(bytes), input_values(packet.trace)):
		return failure("Retained key bytes must match both the original execution key and its input snapshots.")
	var record: Dictionary = packet.duplicate(true)
	# The in-memory packet digest has a different legacy scope. Do not relabel it.
	record.erase("content_digest")
	record.record_schema_version = RECORD_VERSION
	record.execution_key_version = KEY_VERSION
	record.execution_key_preimage_utf8 = bytes
	record.content_digest_version = DIGEST_VERSION
	var report: Dictionary = record.get("evaluation", {}).get("report", {})
	record.report_contract_revision = report.get("contract_revision")
	record.content_preimage_utf8 = JSON.stringify(content_fields(record), "", true, true)
	record.content_digest = record.content_preimage_utf8.sha256_text()
	return verify(record)

static func verify(record: Dictionary) -> Dictionary:
	if not is_json_value(record) or record.get("record_schema_version") != RECORD_VERSION or record.get("execution_key_version") != KEY_VERSION or record.get("content_digest_version") != DIGEST_VERSION:
		return failure("Unsupported record, key or content-digest version.")
	if not record.get("content_preimage_utf8") is String or not record.get("execution_key_preimage_utf8") is String:
		return failure("Exact UTF-8 preimages are required; hashes must not be reconstructed from JSON-loaded values.")
	var content: String = record.content_preimage_utf8
	if content.sha256_text() != record.get("content_digest") or not same_json_values(JSON.parse_string(content), content_fields(record)):
		return failure("Content bytes, digest and decoded record disagree.")
	var trace: Variant = record.get("trace")
	if not trace is Dictionary or not trace.get("final_state") is Dictionary or not trace.get("config") is Dictionary or not trace.get("events") is Array or not trace.get("validation") is Dictionary:
		return failure("Configuration, terminal state, ordered events and original readiness are required.")
	var key_bytes: String = record.execution_key_preimage_utf8
	if key_bytes.sha256_text() != record.get("execution_key") or not same_json_values(JSON.parse_string(key_bytes), input_values(trace)):
		return failure("Execution key bytes do not match the execution inputs.")
	var final: Dictionary = trace.final_state
	if record.get("run_id") != final.get("run_id") or record.get("mission_id") != final.get("mission_id") or not same_json_values(trace.config, final.get("config_snapshot")) or not same_json_values(trace.events, final.get("event_log")):
		return failure("Run identity, terminal configuration and events must match.")
	var evaluation: Variant = record.get("evaluation")
	if not evaluation is Dictionary: return failure("Original evaluator wrapper is required.")
	if evaluation.get("ok", false):
		var report: Variant = evaluation.get("report")
		if not report is Dictionary or report.get("run_id") != record.run_id or report.get("mission_id") != record.mission_id:
			return failure("Report identity differs from the saved execution.")
		for field in preload("res://scripts/evaluation/mission_evaluator.gd").REPORT_FIELDS:
			if not report.has(field): return failure("A required legacy report field is missing: " + field)
		if not (report.get("schema_version") is int or report.get("schema_version") is float) or (report.schema_version != 1 and report.schema_version != 2):
			return failure("Unsupported report schema version.")
		if report.schema_version == 2 and (report.get("contract_revision") != preload("res://scripts/integration/report_contract.gd").GOALS_REVISION or not report.get("goal_progress") is Array or not report.get("objective") is String):
			return failure("Expanded reports require their own contract revision, objective and goal progress.")
		for field in ["required_observations", "required_returned_data_mb"]:
			if report.get(field) != trace.config.mission.get(field): return failure("Report requirements differ from the frozen config.")
		for field in ["observations_completed", "returned_data_mb", "run_status"]:
			if report.get(field) != final.get(field): return failure("Report actuals differ from the terminal state.")
		if record.get("report_contract_revision") != report.get("contract_revision"):
			return failure("Report contract metadata differs from the retained report.")
		if report.has("objective") and report.objective != trace.config.mission.get("objective"):
			return failure("A proposed objective report cannot be bound to an Imaging proxy config.")
	return {"ok":true,"record":record.duplicate(true)}
