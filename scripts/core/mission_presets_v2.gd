extends RefCounted
## Agreed five-preset definitions. Loading never launches or scores a mission.
const Rules = preload("res://scripts/core/mission_config_v2_agreed_rules.gd")
const Support = preload("res://scripts/core/validation_support.gd")
const IDS = ["estuary_watch","tropical_forest_watch","polar_ice_survey","communication","weather_monitoring"]
const AVAILABILITY = ["existing_imaging","existing_imaging","existing_unscored_survey","requires_goal_extension","requires_goal_extension"]
const ROOT_FIELDS = ["schema_version","registry_revision","contract_status","goal_contract_revision","base_main","notice","presets"]
const ENTRY_FIELDS = ["id","revision","display_name","availability","ui_defaults","assumption_id","limitation","legacy_config_v1","config_v2"]

static func inspect(value: Variant) -> Dictionary:
	var errors: Array=[]
	if not value is Dictionary: return _failure("registry","Provide an agreed registry object.")
	_keys(value,ROOT_FIELDS,"registry.",errors)
	for field in ["base_main","notice"]:
		if not _text(value.get(field)): _issue(errors,"registry."+field,"Retain the source revision and scope notice.")
	var index: Dictionary=Rules._registry(value,errors)
	if not errors.is_empty(): return {"ok":false,"registry":{},"errors":errors}
	for position in value.presets.size():
		var entry: Dictionary=value.presets[position]
		var path: String="registry.presets[%d]." % position
		_keys(entry,ENTRY_FIELDS,path,errors)
		if entry.id != IDS[position]: _issue(errors,path+"id","Retain canonical ordering and unique preset identities.")
		for field in ["display_name","assumption_id","limitation"]:
			if not _text(entry.get(field)): _issue(errors,path+field,"Provide a trimmed nonempty label.")
		if entry.get("availability") != AVAILABILITY[position]: _issue(errors,path+"availability","Do not advertise unfinished launch/scoring integration.")
		var config: Dictionary=entry.config_v2
		var shape: Array=[]
		Rules._shape(config,shape)
		for issue in shape:
			issue.field_path=path+"config_v2."+issue.field_path
			errors.append(issue)
		if not shape.is_empty(): continue
		if config.mission.title != entry.get("display_name"): _issue(errors,path+"display_name","Stock title must match its displayed preset name.")
		var legacy: Variant=entry.get("legacy_config_v1")
		if position < 3:
			var expected: Dictionary=config.duplicate(true)
			for field in ["contract_revision","preset_id","preset_revision"]: expected.erase(field)
			expected.schema_version=1; expected.mission.erase("goal")
			if not legacy is Dictionary or JSON.parse_string(JSON.stringify(expected)) != JSON.parse_string(JSON.stringify(legacy)): _issue(errors,path+"legacy_config_v1","Preserve the original supported v1 configuration exactly.")
		elif legacy != null: _issue(errors,path+"legacy_config_v1","New goals cannot expose a v1 Imaging fallback.")
		var ui: Variant=entry.get("ui_defaults")
		if not ui is Dictionary:
			_issue(errors,path+"ui_defaults","Provide separate display defaults."); continue
		_keys(ui,["target_labels","orbit_label","objective_label"],path+"ui_defaults.",errors)
		if not ui.get("target_labels") is Array or ui.target_labels.is_empty() or ui.target_labels.size()>2:
			_issue(errors,path+"ui_defaults.target_labels","Provide one or two target display labels.")
		else:
			for label in ui.target_labels:
				if not _text(label): _issue(errors,path+"ui_defaults.target_labels","Use trimmed nonempty labels.")
		for field in ["orbit_label","objective_label"]:
			if not _text(ui.get(field)): _issue(errors,path+"ui_defaults."+field,"Provide a display label.")
	return {"ok":errors.is_empty(),"registry":value.duplicate(true) if errors.is_empty() else {},"errors":errors}

static func config_for(registry: Variant,id: String) -> Dictionary:
	var checked: Dictionary=inspect(registry)
	if not checked.ok: return checked
	for entry in checked.registry.presets:
		if entry.id==id: return {"ok":true,"config":entry.config_v2.duplicate(true),"errors":[]}
	return {"ok":false,"errors":[Support.issue("UNKNOWN_PRESET","preset_id","Choose one of the five registered presets.","Use a canonical preset ID.")]}

static func legacy_config_for(registry: Variant,id: String) -> Dictionary:
	var checked: Dictionary=inspect(registry)
	if not checked.ok: return checked
	for entry in checked.registry.presets:
		if entry.id != id: continue
		if entry.legacy_config_v1==null:
			return {"ok":false,"errors":[Support.issue("NO_LEGACY_FALLBACK","preset_id","This goal requires the v2 integration path.","Do not substitute Imaging.")]}
		return {"ok":true,"config":entry.legacy_config_v1.duplicate(true),"errors":[]}
	return config_for(registry,id)

static func _keys(value: Dictionary,fields: Array,prefix: String,errors: Array) -> void:
	for key in fields:
		if not value.has(key): _issue(errors,prefix+key,"Required field is missing.")
	for key in value:
		if not fields.has(key): _issue(errors,prefix+str(key),"Unrecognized registry field.")
static func _text(value: Variant) -> bool: return Support.is_text(value) and value==value.strip_edges()
static func _issue(errors: Array,path: String,message: String) -> void:
	errors.append(Support.issue("INVALID_PRESET_REGISTRY",path,message,"Restore the matching agreed five-preset definition."))
static func _failure(path: String,message: String) -> Dictionary:
	var errors: Array=[]; _issue(errors,path,message)
	return {"ok":false,"registry":{},"errors":errors}
