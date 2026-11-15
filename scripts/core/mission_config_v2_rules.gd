extends RefCounted
## Shared pure shape/reference rules. No physics, file reads or launch approval.
const Support = preload("res://scripts/core/validation_support.gd")
const Loader = preload("res://scripts/core/catalog_loader.gd")
const V1 = preload("res://scripts/core/mission_validator.gd")
const CONTRACT = "expansion-goals-v2-draft-2"
const REGISTRY_REVISION = "five-presets-candidate-2"
const ROOT_FIELDS = ["schema_version", "contract_revision", "preset_id", "preset_revision", "mission", "design"]
const OBJECTIVES = ["imaging", "survey", "communication", "weather_monitoring"]
const PRESET_OBJECTIVES = {"estuary_watch":"imaging", "tropical_forest_watch":"imaging", "polar_ice_survey":"survey", "communication":"communication", "weather_monitoring":"weather_monitoring"}
const KINDS = {"imaging":"imaging", "survey":"survey_delivery", "communication":"communication_contacts", "weather_monitoring":"weather_revisit"}
const COUNTS = {"imaging":"", "survey":"minimum_complete_observations_per_target", "communication":"required_positive_contact_steps", "weather_monitoring":"required_distinct_orbits"}


static func inspect_configuration(config: Variant, catalogs: Variant, registry: Variant, capability_context: Variant) -> Dictionary:
	var result: Dictionary = {"config_valid":false, "checks":{}, "errors":[], "indexes":{}}
	for id in V1.CHECK_IDS:
		result.checks[id] = {"status":"not_evaluated", "passed":null, "message":"Waits for valid configuration and context."}
	var errors: Array = result.errors
	_shape(config, errors)
	_mark(result.checks, "input_schema", errors.is_empty())
	if not errors.is_empty(): return result
	var inspection: Dictionary = Loader.inspect_catalogs(catalogs)
	if not inspection.ok:
		errors.append_array(inspection.errors.duplicate(true))
		_mark(result.checks, "catalog_references", false)
		return result
	var presets: Dictionary = _registry(registry, errors)
	if errors.is_empty(): _references(config, catalogs, inspection.indexes, presets, capability_context, errors)
	_mark(result.checks, "catalog_references", errors.is_empty())
	if errors.is_empty():
		result.config_valid = true
		result.indexes = inspection.indexes.duplicate(true)
	return result

static func _shape(config: Variant, errors: Array) -> void:
	if not config is Dictionary:
		_add(errors, "INVALID_SCHEMA", "", "Provide a v2 configuration object."); return
	_keys(config, ROOT_FIELDS, [], "", errors)
	if config.has("schema_version") and (not Support.is_whole(config.schema_version) or config.schema_version != 2):
		_add(errors, "INVALID_SCHEMA", "schema_version", "This v2 rule set requires numeric version 2; supported v1 uses MissionValidator unchanged.")
	if config.has("contract_revision") and (not _text(config.contract_revision) or config.contract_revision != CONTRACT):
		_add(errors, "INVALID_SCHEMA", "contract_revision", "Use the current reviewed contract revision.")
	_text_field(config, "preset_id", "preset_id", errors)
	_whole(config, "preset_revision", "preset_revision", 1, Support.MAX_SAFE_INTEGER, errors)
	if config.has("mission"):
		if config.mission is Dictionary: _mission(config.mission, errors)
		else: _add(errors, "INVALID_SCHEMA", "mission", "Mission must be an object.")
	if config.has("design"):
		if not config.design is Dictionary:
			_add(errors, "INVALID_SCHEMA", "design", "Design must be an object.")
		else:
			_keys(config.design, V1.DESIGN_FIELDS, [], "design.", errors, "MISSING_COMPONENT")
			for field in V1.DESIGN_FIELDS: _text_field(config.design, field, "design." + field, errors)

static func _mission(mission: Dictionary, errors: Array) -> void:
	_keys(mission, V1.MISSION_FIELDS + ["goal"], ["target_regions"], "mission.", errors)
	for field in ["title", "objective", "target_region"]: _text_field(mission, field, "mission." + field, errors)
	if mission.get("title") is String and mission.title.length() > 80: _add(errors, "INVALID_VALUE", "mission.title", "Use at most 80 characters.")
	var observations_ok: bool = _whole(mission, "required_observations", "mission.required_observations", 1, 20, errors)
	var duration_ok: bool = _whole(mission, "duration_orbits", "mission.duration_orbits", 1, 12, errors)
	_whole(mission, "budget_credits", "mission.budget_credits", 1, Support.MAX_SAFE_INTEGER, errors)
	if mission.has("required_returned_data_mb") and (not Support.is_number(mission.required_returned_data_mb) or mission.required_returned_data_mb <= 0):
		_add(errors, "INVALID_VALUE", "mission.required_returned_data_mb", "Use positive finite decimal MB.")
	var objective: String = mission.objective if mission.get("objective") is String else ""
	if mission.has("objective") and not objective in OBJECTIVES: _add(errors, "INVALID_VALUE", "mission.objective", "Choose a proposed registered objective.")
	var targets: Variant = mission.get("target_regions", [mission.get("target_region")])
	var targets_ok: bool = targets is Array and not targets.is_empty() and targets.size() <= (1 if objective in ["communication", "weather_monitoring"] else 2)
	if targets_ok:
		var seen: Array = []
		for target in targets:
			if not _text(target) or seen.has(target): targets_ok = false
			seen.append(target)
	if not targets_ok: _add(errors, "INVALID_VALUE", "mission.target_regions", "Use distinct target strings and this objective's allowed target count.")
	elif _text(mission.get("target_region")) and targets[0] != mission.target_region:
		_add(errors, "INVALID_VALUE", "mission.target_region", "Primary target must equal the first selected target.")
	if not mission.has("goal"): return
	if not mission.goal is Dictionary:
		_add(errors, "INVALID_SCHEMA", "mission.goal", "Goal must be an object."); return
	if not objective in OBJECTIVES: return
	var goal: Dictionary = mission.goal
	var field: String = COUNTS[objective]
	_keys(goal, ["kind"] if field.is_empty() else ["kind", field], [], "mission.goal.", errors)
	if goal.has("kind") and (not _text(goal.kind) or goal.kind != KINDS[objective]): _add(errors, "INVALID_VALUE", "mission.goal.kind", "Use the goal kind matching the objective.")
	if field.is_empty(): return
	var maximum: int = 20 if objective == "survey" else (12 if objective == "weather_monitoring" else Support.MAX_SAFE_INTEGER)
	if not _whole(goal, field, "mission.goal." + field, 1, maximum, errors): return
	if objective == "survey" and goal[field] != 1:
		_add(errors, "INVALID_VALUE", "mission.goal." + field, "This agreed revision supports exactly one complete delivery per target; higher minima need an explicit extension.")
	if objective == "survey" and observations_ok and targets_ok and goal[field] > floorf(float(mission.required_observations) / targets.size()):
		_add(errors, "INVALID_VALUE", "mission.goal." + field, "Per-target deliveries cannot exceed the available capture quota.")
	if objective == "weather_monitoring" and observations_ok and duration_ok and (goal[field] > mission.required_observations or goal[field] > mission.duration_orbits):
		_add(errors, "INVALID_VALUE", "mission.goal." + field, "Visits cannot exceed duration or capture quota.")

static func _registry(value: Variant, errors: Array) -> Dictionary:
	var index: Dictionary = {}
	if not value is Dictionary:
		_add(errors, "INVALID_SCHEMA", "registry", "Supply the explicit candidate-registry context."); return index
	if not Support.is_whole(value.get("schema_version")) or value.schema_version != 1:
		_add(errors, "INVALID_SCHEMA", "registry.schema_version", "Registry format must be numeric 1.")
	for field in ["registry_revision", "goal_contract_revision", "contract_status"]:
		var expected: String = {"registry_revision":REGISTRY_REVISION, "goal_contract_revision":CONTRACT, "contract_status":"candidate_pending_owner_review"}[field]
		if not _text(value.get(field)) or value[field] != expected: _add(errors, "INVALID_SCHEMA", "registry." + field, "Supply the current unapproved registry revision.")
	if not value.get("presets") is Array or value.presets.size() != 5:
		_add(errors, "INVALID_SCHEMA", "registry.presets", "Exactly five canonical authored identities are required."); return index
	for entry in value.presets:
		if not entry is Dictionary or not _text(entry.get("id")):
			_add(errors, "INVALID_SCHEMA", "registry.presets", "Every entry needs a string ID."); continue
		var id: String = entry.id
		if not PRESET_OBJECTIVES.has(id) or index.has(id):
			_add(errors, "INVALID_SCHEMA", "registry.presets", "IDs must be canonical and unique."); continue
		if not Support.is_whole(entry.get("revision")) or entry.revision <= 0:
			_add(errors, "INVALID_SCHEMA", "registry.presets." + id + ".revision", "Preset revision must be positive and whole."); continue
		var candidate: Variant = entry.get("candidate_config_v2")
		if not candidate is Dictionary or not candidate.get("mission") is Dictionary:
			_add(errors, "INVALID_SCHEMA", "registry.presets." + id, "Provide candidate identity and objective metadata."); continue
		if not Support.is_whole(candidate.get("schema_version")) or candidate.schema_version != 2 or not Support.is_whole(candidate.get("preset_revision")) or candidate.preset_revision != entry.revision:
			_add(errors, "INVALID_SCHEMA", "registry.presets." + id, "Candidate version/revision must match the registry."); continue
		if not _text(candidate.get("preset_id")) or candidate.preset_id != id or not _text(candidate.get("contract_revision")) or candidate.contract_revision != CONTRACT or not _text(candidate.mission.get("objective")) or candidate.mission.objective != PRESET_OBJECTIVES[id]:
			_add(errors, "INVALID_SCHEMA", "registry.presets." + id, "Candidate lineage must match its canonical objective and contract."); continue
		index[id] = {"revision":entry.revision, "objective":PRESET_OBJECTIVES[id]}
	return index

static func _references(config: Dictionary, catalogs: Dictionary, indexes: Dictionary, presets: Dictionary, proposal: Variant, errors: Array) -> void:
	var mission: Dictionary = config.mission; var design: Dictionary = config.design
	if not presets.has(config.preset_id): _add(errors, "INVALID_VALUE", "preset_id", "Choose a registered authored preset identity.")
	else:
		if config.preset_revision != presets[config.preset_id].revision: _add(errors, "INVALID_VALUE", "preset_revision", "Use the selected preset's published revision.")
		if mission.objective != presets[config.preset_id].objective: _add(errors, "INVALID_VALUE", "mission.objective", "Objective must match authored preset lineage.")
	for target in mission.get("target_regions", [mission.target_region]):
		if not catalogs.target_region_ids.has(target): _add(errors, "INVALID_VALUE", "mission.target_regions", "Choose registered target IDs from the effective catalogs.")
	if not catalogs.target_region_ids.has(mission.target_region): _add(errors, "INVALID_VALUE", "mission.target_region", "Choose a registered primary target.")
	for category in Loader.CATEGORIES:
		var field: String = category + "_id"
		if not indexes.components.has(design[field]): _add(errors, "UNKNOWN_COMPONENT", "design." + field, "Choose an existing part ID.")
		elif indexes.components[design[field]].category != category: _add(errors, "WRONG_COMPONENT_CATEGORY", "design." + field, "Choose a part in the correct slot.")
	for pair in [["launch_profile_id", "launch_profiles", "UNKNOWN_PROFILE"], ["launcher_id", "launchers", "UNKNOWN_LAUNCHER"]]:
		if not indexes[pair[1]].has(design[pair[0]]): _add(errors, pair[2], "design." + pair[0], "Choose a registered ID.")
	if not catalogs.orbit_ids.has(design.orbit_id): _add(errors, "UNKNOWN_ORBIT", "design.orbit_id", "Choose a registered orbit.")
	if mission.objective in ["imaging", "survey"] and not catalogs.objective_ids.has(mission.objective): _add(errors, "INVALID_VALUE", "mission.objective", "The effective legacy catalog must register this objective.")
	if not errors.is_empty(): return
	_capability(mission.objective, design.instrument_id, indexes.components, proposal, errors)
	if mission.objective == "communication":
		var total: int = _total_steps(catalogs, design.orbit_id, int(mission.duration_orbits), errors)
		if total > 0 and mission.goal.required_positive_contact_steps > total:
			_add(errors, "INVALID_VALUE", "mission.goal.required_positive_contact_steps", "Contacts cannot exceed the selected frozen scenario's total steps.")

static func _capability(objective: String, instrument: String, parts: Dictionary, proposal: Variant, errors: Array) -> void:
	if not proposal is Dictionary:
		_add(errors, "INVALID_SCHEMA", "capability_proposal", "Supply explicit unapproved capability context; no default support is inferred."); return
	if not _text(proposal.get("status")) or proposal.status != "PROPOSED_NOT_REGISTERED_FOR_NEW_OBJECTIVES" or typeof(proposal.get("new_objectives_currently_enabled")) != TYPE_BOOL or proposal.new_objectives_currently_enabled:
		_add(errors, "INVALID_SCHEMA", "capability_proposal.status", "Capability context must retain its review-only marker.")
	var mapping: Variant = proposal.get("proposed_instrument_objectives")
	if not mapping is Dictionary:
		_add(errors, "INVALID_SCHEMA", "capability_proposal.proposed_instrument_objectives", "Provide explicit instrument capability arrays."); return
	for key in mapping:
		if not _text(key) or not parts.has(key) or parts[key].category != "instrument":
			_add(errors, "INVALID_SCHEMA", "capability_proposal.proposed_instrument_objectives", "Capability keys must be registered instruments."); continue
		var values: Variant = mapping[key]
		if not values is Array:
			_add(errors, "INVALID_SCHEMA", "capability_proposal." + str(key), "Instrument capabilities must be arrays."); continue
		var seen: Array = []
		for value in values:
			if not _text(value) or not OBJECTIVES.has(value) or seen.has(value): _add(errors, "INVALID_SCHEMA", "capability_proposal." + str(key), "Capabilities must be unique known objective strings.")
			seen.append(value)
	if not mapping.get(instrument) is Array or not mapping[instrument].has(objective):
		_add(errors, "INSTRUMENT_OBJECTIVE_UNSUPPORTED", "design.instrument_id", "The review context does not declare this instrument/objective combination.")
	elif objective in ["imaging", "survey"] and not parts[instrument].supported_objectives.has(objective):
		_add(errors, "INSTRUMENT_OBJECTIVE_UNSUPPORTED", "design.instrument_id", "The effective legacy catalog must retain this instrument's declared objective support.")

static func _total_steps(catalogs: Dictionary, orbit_id: String, duration: int, errors: Array) -> int:
	var metadata: Variant = catalogs.get("orbit_catalog")
	if metadata is Dictionary and metadata.get("orbits") is Array:
		for row in metadata.orbits:
			if row is Dictionary and _text(row.get("id")) and row.id == orbit_id:
				var steps: Variant = row.get("steps_per_orbit")
				if Support.is_whole(steps) and steps > 0 and steps <= floorf(float(Support.MAX_SAFE_INTEGER) / duration): return int(steps) * duration
	_add(errors, "INVALID_SCHEMA", "catalogs.orbit_catalog.orbits.steps_per_orbit", "Supply safe positive timing metadata for the selected orbit; no fixed divisor is assumed.")
	return -1

static func _keys(value: Dictionary, required: Array, optional: Array, prefix: String, errors: Array, missing_code: String = "INVALID_SCHEMA") -> void:
	for key in required:
		if not value.has(key): _add(errors, missing_code, prefix + key, "Required field is missing.")
	for key in value:
		if not key in required and not key in optional: _add(errors, "INVALID_SCHEMA", prefix + str(key), "Unrecognized configuration field.")

static func _whole(value: Dictionary, key: String, path: String, minimum: int, maximum: int, errors: Array) -> bool:
	if not value.has(key): return false
	if not Support.is_whole(value[key]) or value[key] < minimum or value[key] > maximum:
		_add(errors, "INVALID_VALUE", path, "Use a finite whole number in the proposed range %d-%d." % [minimum, maximum]); return false
	return true

static func _text(value: Variant) -> bool:
	return Support.is_text(value) and value == value.strip_edges()

static func _text_field(value: Dictionary, key: String, path: String, errors: Array) -> void:
	if value.has(key) and not _text(value[key]): _add(errors, "INVALID_VALUE", path, "Use a trimmed nonempty string.")

static func _mark(checks: Dictionary, id: String, ok: bool) -> void:
	checks[id] = {"status":"pass" if ok else "fail", "passed":ok, "message":"Draft review phase passed." if ok else "Correct the draft review issues."}

static func _add(errors: Array, code: String, path: String, message: String) -> void:
	errors.append(Support.issue(code, path, message, "Correct the configuration or explicit validation context; launch approval is separate."))
