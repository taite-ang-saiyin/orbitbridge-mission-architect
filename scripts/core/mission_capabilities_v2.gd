extends RefCounted
## One explicit agreed capability source for config-v2 validation/producer use.
const Support = preload("res://scripts/core/validation_support.gd")
const Catalogs = preload("res://scripts/core/catalog_loader.gd")
const REVISION = "v2-capabilities-agreed-1"
const CONTRACT = "expansion-goals-v2-agreed-1"
const OBJECTIVES = ["imaging", "survey", "communication", "weather_monitoring"]
const FIELDS = ["schema_version", "capability_revision", "config_contract_revision", "status", "notice", "instruments"]

static func inspect(value: Variant, catalogs: Variant) -> Dictionary:
	var result: Dictionary = {"ok":false, "document":{}, "capability_context":{}, "errors":[]}
	var errors: Array = result.errors
	if not value is Dictionary:
		_issue(errors,"capabilities","Provide the explicit agreed capability document."); return result
	_keys(value,FIELDS,"capabilities.",errors)
	if not Support.is_whole(value.get("schema_version")) or value.schema_version != 1: _issue(errors,"capabilities.schema_version","Capability document format must be numeric 1.")
	for pair in [["capability_revision",REVISION],["config_contract_revision",CONTRACT],["status","agreed"]]:
		if value.get(pair[0]) != pair[1]: _issue(errors,"capabilities."+pair[0],"Use the agreed capability/config revision and status.")
	if not _text(value.get("notice")): _issue(errors,"capabilities.notice","Retain a nonempty training limitation notice.")
	if not value.get("instruments") is Array or value.instruments.is_empty(): _issue(errors,"capabilities.instruments","Provide explicit instrument entries.")
	if not errors.is_empty(): return result
	var inspected: Dictionary = Catalogs.inspect_catalogs(catalogs)
	if not inspected.ok:
		errors.append_array(inspected.errors.duplicate(true)); return result
	var parts: Dictionary=inspected.indexes.components
	var mapping: Dictionary={}
	for index in value.instruments.size():
		var entry: Variant=value.instruments[index]
		var path: String="capabilities.instruments[%d]." % index
		if not entry is Dictionary:
			_issue(errors,path.trim_suffix("."),"Every entry must be an object."); continue
		_keys(entry,["instrument_id","objective_ids","assumption_id"],path,errors)
		if not _text(entry.get("instrument_id")):
			_issue(errors,path+"instrument_id","Provide a registered instrument ID."); continue
		var id: String=entry.instrument_id
		if mapping.has(id):
			_issue(errors,path+"instrument_id","Instrument IDs must be unique."); continue
		if not parts.has(id) or parts[id].category != "instrument":
			_issue(errors,path+"instrument_id","Use a registered instrument, not a different part category."); continue
		if entry.get("assumption_id") != parts[id].assumption_id: _issue(errors,path+"assumption_id","Preserve the existing instrument assumption label.")
		if not entry.get("objective_ids") is Array:
			_issue(errors,path+"objective_ids","Provide an explicit array; no support is inferred."); continue
		var objectives: Array=[]
		for objective in entry.objective_ids:
			if not _text(objective) or not OBJECTIVES.has(objective) or objectives.has(objective): _issue(errors,path+"objective_ids","Objectives must be unique registered strings.")
			objectives.append(objective)
		mapping[id]=objectives
	if not errors.is_empty(): return result
	result.ok=true
	result.document=value.duplicate(true)
	result.capability_context={"status":"AGREED_CONFIG_V2_CAPABILITIES","config_contract_revision":CONTRACT,"capability_revision":REVISION,"instrument_objectives":mapping.duplicate(true)}
	return result

static func _keys(value: Dictionary,fields: Array,prefix: String,errors: Array) -> void:
	for key in fields:
		if not value.has(key): _issue(errors,prefix+key,"Required field is missing.")
	for key in value:
		if not fields.has(key): _issue(errors,prefix+str(key),"Unrecognized capability field.")
static func _text(value: Variant) -> bool: return Support.is_text(value) and value == value.strip_edges()
static func _issue(errors: Array,path: String,message: String) -> void:
	errors.append(Support.issue("INVALID_CAPABILITY_CATALOG",path,message,"Restore the matching agreed capability document and part catalog."))
