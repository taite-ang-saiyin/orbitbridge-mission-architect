extends RefCounted
## Explicit loading outside pure validation; untouched legacy catalogs plus a v2 sidecar.
const Rules = preload("res://scripts/core/mission_config_v2_agreed_rules.gd")
const Presets = preload("res://scripts/core/mission_presets_v2.gd")
const Capabilities = preload("res://scripts/core/mission_capabilities_v2.gd")
const Support = preload("res://scripts/core/validation_support.gd")

static func load_context(effective_catalogs: Variant,base_path: String="res://data") -> Dictionary:
	var registry: Dictionary=_read(base_path.path_join("mission_presets_v2.json"))
	var capabilities: Dictionary=_read(base_path.path_join("mission_capabilities_v2.json"))
	if not registry.ok or not capabilities.ok:
		return {"ok":false,"catalogs":{},"errors":registry.errors+capabilities.errors}
	return attach(effective_catalogs,registry.document,capabilities.document)

static func attach(effective_catalogs: Variant,registry: Variant,capabilities: Variant) -> Dictionary:
	var context: Dictionary={"schema_version":1,"contract_revision":Rules.CONTRACT,"registry":registry,"capabilities":capabilities}
	var checked: Dictionary=inspect_context(context,effective_catalogs)
	if not checked.ok: return {"ok":false,"catalogs":{},"errors":checked.errors}
	var catalogs: Dictionary=effective_catalogs.duplicate(true)
	catalogs.mission_v2=context.duplicate(true)
	return {"ok":true,"catalogs":catalogs,"errors":[]}

static func inspect_context(value: Variant,catalogs: Variant) -> Dictionary:
	var errors: Array=[]
	if not value is Dictionary:
		errors.append(Support.issue("V2_CONTEXT_MISSING","catalogs.mission_v2","Config v2 requires an explicit agreed catalog context.","Load/attach MissionV2Context before validating a v2 config."))
		return {"ok":false,"errors":errors}
	for field in ["schema_version","contract_revision","registry","capabilities"]:
		if not value.has(field): _issue(errors,"catalogs.mission_v2."+field,"Required context field is missing.")
	for field in value:
		if not field in ["schema_version","contract_revision","registry","capabilities"]: _issue(errors,"catalogs.mission_v2."+str(field),"Unrecognized context field.")
	if not Support.is_whole(value.get("schema_version")) or value.schema_version!=1: _issue(errors,"catalogs.mission_v2.schema_version","Context format must be numeric 1.")
	if value.get("contract_revision")!=Rules.CONTRACT: _issue(errors,"catalogs.mission_v2.contract_revision","Use the agreed context revision.")
	if not errors.is_empty(): return {"ok":false,"errors":errors}
	var presets: Dictionary=Presets.inspect(value.registry)
	var capabilities: Dictionary=Capabilities.inspect(value.capabilities,catalogs)
	errors.append_array(presets.errors); errors.append_array(capabilities.errors)
	if not errors.is_empty(): return {"ok":false,"errors":errors}
	# Validate every authored stock definition against the same effective IDs,
	# selected-target windows and capability vocabulary used by selected configs.
	for entry in presets.registry.presets:
		var inspected: Dictionary=Rules.inspect_configuration(entry.config_v2,catalogs,presets.registry,capabilities.capability_context)
		for issue in inspected.errors:
			var copy: Dictionary=issue.duplicate(true)
			copy.field_path="catalogs.mission_v2.registry."+entry.id+"."+copy.field_path
			errors.append(copy)
	if not errors.is_empty(): return {"ok":false,"errors":errors}
	return {"ok":true,"registry":presets.registry.duplicate(true),"capability_context":capabilities.capability_context.duplicate(true),"errors":[]}

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"ok":false,"errors":[Support.issue("V2_DATA_FILE_MISSING",path,"The agreed v2 data file is missing.","Restore both agreed v2 JSON documents.")]}
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return {"ok":false,"errors":[Support.issue("INVALID_SCHEMA",path,"The v2 data file is not valid JSON.","Restore the matching agreed file.")]}
	return {"ok":true,"document":parser.data,"errors":[]}
static func _issue(errors: Array,path: String,message: String) -> void:
	errors.append(Support.issue("INVALID_V2_CONTEXT",path,message,"Restore the matching explicit v2 context."))
