extends RefCounted
## Explicit review-only loading. Never changes the v1 catalog or authorizes launch.
const Support = preload("res://scripts/core/validation_support.gd")
const Catalogs = preload("res://scripts/core/catalog_loader.gd")
const PATH = "res://data/mission_capabilities_v2.draft.json"
const REVISION = "v2-capabilities-draft-1"
const CONTRACT = "expansion-goals-v2-draft-2"
const OBJECTIVES = ["imaging", "survey", "communication", "weather_monitoring"]
const FIELDS = ["schema_version", "capability_revision", "config_contract_revision", "approval_status", "production_enabled", "notice", "instruments"]

static func load_review(catalogs: Variant, path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path): return _failure("CAPABILITY_FILE_MISSING", "capability_path", "The explicit draft capability file is missing.")
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return _failure("INVALID_CAPABILITY_DRAFT", "capability_path", "Draft capability file must contain valid JSON.")
	return inspect_review(parser.data, catalogs)

static func inspect_review(value: Variant, catalogs: Variant) -> Dictionary:
	var result: Dictionary = {"ok":false, "draft_only":true, "ready_to_launch":false, "production_enabled":false, "capability_revision":null, "document":{}, "checker_context":{}, "errors":[]}
	var errors: Array = result.errors
	if not value is Dictionary:
		_issue(errors, "capabilities", "Provide a draft capability object."); return result
	_keys(value, FIELDS, "capabilities.", errors)
	if not Support.is_whole(value.get("schema_version")) or value.schema_version != 1: _issue(errors, "capabilities.schema_version", "Capability-file format must be numeric 1, separate from MissionConfig v2.")
	for pair in [["capability_revision",REVISION],["config_contract_revision",CONTRACT],["approval_status","draft_not_approved"]]:
		if not _text(value.get(pair[0])) or value[pair[0]] != pair[1]: _issue(errors, "capabilities." + pair[0], "Retain the supported unapproved review revision.")
	if typeof(value.get("production_enabled")) != TYPE_BOOL or value.production_enabled: _issue(errors, "capabilities.production_enabled", "This draft loader only accepts production_enabled=false.")
	if not _text(value.get("notice")): _issue(errors, "capabilities.notice", "A nonempty training/draft limitation notice is required.")
	if not value.get("instruments") is Array or value.instruments.is_empty(): _issue(errors, "capabilities.instruments", "Provide explicit instrument capability entries.")
	if not errors.is_empty(): return result
	var inspected: Dictionary = Catalogs.inspect_catalogs(catalogs)
	if not inspected.ok:
		errors.append_array(inspected.errors.duplicate(true)); return result
	var parts: Dictionary = inspected.indexes.components
	var mapping: Dictionary = {}
	for index in value.instruments.size():
		var entry: Variant = value.instruments[index]
		var path: String = "capabilities.instruments[%d]." % index
		if not entry is Dictionary:
			_issue(errors, path.trim_suffix("."), "Every capability entry must be an object."); continue
		_keys(entry, ["instrument_id", "objective_ids", "assumption_id"], path, errors)
		if not _text(entry.get("instrument_id")):
			_issue(errors, path + "instrument_id", "Provide a registered instrument ID."); continue
		var id: String = entry.instrument_id
		if mapping.has(id):
			_issue(errors, path + "instrument_id", "Instrument IDs must be unique."); continue
		if not parts.has(id) or parts[id].category != "instrument":
			_issue(errors, path + "instrument_id", "Capability IDs must resolve to existing instrument parts."); continue
		if not _text(entry.get("assumption_id")) or entry.assumption_id != parts[id].assumption_id: _issue(errors, path + "assumption_id", "Preserve the existing part's training assumption label.")
		if not entry.get("objective_ids") is Array:
			_issue(errors, path + "objective_ids", "Provide an explicit objective array; an empty array declares no draft support."); continue
		var objectives: Array = []
		for objective in entry.objective_ids:
			if not _text(objective) or not OBJECTIVES.has(objective) or objectives.has(objective): _issue(errors, path + "objective_ids", "Objectives must be unique known strings.")
			objectives.append(objective)
		mapping[id] = objectives
	if not errors.is_empty(): return result
	result.ok = true
	result.capability_revision = REVISION
	result.document = value.duplicate(true)
	result.checker_context = {"status":"PROPOSED_NOT_REGISTERED_FOR_NEW_OBJECTIVES", "new_objectives_currently_enabled":false, "proposed_instrument_objectives":mapping.duplicate(true)}
	return result

static func _keys(value: Dictionary, fields: Array, prefix: String, errors: Array) -> void:
	for field in fields:
		if not value.has(field): _issue(errors, prefix + field, "Required capability field is missing.")
	for field in value:
		if not fields.has(field): _issue(errors, prefix + str(field), "Unrecognized capability field.")

static func _text(value: Variant) -> bool: return Support.is_text(value) and value == value.strip_edges()
static func _issue(errors: Array, path: String, message: String) -> void:
	errors.append(Support.issue("INVALID_CAPABILITY_DRAFT", path, message, "Correct the explicit review document; production approval remains pending."))
static func _failure(code: String, path: String, message: String) -> Dictionary:
	return {"ok":false,"draft_only":true,"ready_to_launch":false,"production_enabled":false,"capability_revision":null,"document":{},"checker_context":{},"errors":[Support.issue(code,path,message,"Review the explicit draft capability path.")]}
