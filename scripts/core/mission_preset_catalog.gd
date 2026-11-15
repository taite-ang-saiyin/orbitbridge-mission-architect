extends RefCounted
## KE1 candidate registry, separate from the current MissionConfig v1 boundary.
## Loading a definition never authorizes a new objective or changes UI/runtime state.
const Support = preload("res://scripts/core/validation_support.gd")
const IDS = ["estuary_watch", "tropical_forest_watch", "polar_ice_survey", "communication", "weather_monitoring"]
const OBJECTIVES = ["imaging", "imaging", "survey", "communication", "weather_monitoring"]
const KINDS = ["imaging", "imaging", "survey_delivery", "communication_contacts", "weather_revisit"]
const AVAILABILITY = ["existing_imaging", "existing_imaging", "existing_unscored_survey", "requires_goal_extension", "requires_goal_extension"]
const CONTRACT = "expansion-goals-v2-draft-2"

static func load_registry(path: String = "res://data/mission_presets.json") -> Dictionary:
	if not FileAccess.file_exists(path): return _error("PRESET_FILE_MISSING", path, "Restore the five-preset definition file.")
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return _error("INVALID_PRESET_REGISTRY", path, "The preset file must contain valid JSON.")
	return inspect(parser.data)

static func inspect(value: Variant) -> Dictionary:
	var errors: Array = []
	if not value is Dictionary: return _error("INVALID_PRESET_REGISTRY", "registry", "A preset registry object is required.")
	if not Support.is_whole(value.get("schema_version")) or value.schema_version != 1:
		errors.append(_issue("registry.schema_version", "Registry format must be version 1; this is separate from candidate config version 2."))
	if value.get("contract_status") != "candidate_pending_owner_review" or value.get("goal_contract_revision") != CONTRACT:
		errors.append(_issue("registry.contract_status", "Preserve the unapproved candidate contract marker."))
	if not Support.is_text(value.get("registry_revision")) or not Support.is_text(value.get("base_main")):
		errors.append(_issue("registry", "Registry revision and source main revision are required."))
	var presets: Variant = value.get("presets")
	if not presets is Array or presets.size() != IDS.size():
		errors.append(_issue("registry.presets", "Provide exactly five presets: three retained and two new."))
	else:
		var seen: Array = []
		for index in presets.size():
			var entry: Variant = presets[index]
			var path: String = "presets[%d]" % index
			if not entry is Dictionary:
				errors.append(_issue(path, "Each preset must be an object.")); continue
			if entry.get("id") != IDS[index] or seen.has(entry.get("id")):
				errors.append(_issue(path + ".id", "Use unique canonical IDs and retain the original three-preset order."))
			seen.append(entry.get("id"))
			var revision_valid: bool = Support.is_whole(entry.get("revision")) and entry.revision > 0
			if not revision_valid:
				errors.append(_issue(path + ".revision", "Candidate preset revision must be a positive whole number."))
			if not Support.is_text(entry.get("display_name")) or not Support.is_text(entry.get("assumption_id")) or not Support.is_text(entry.get("limitation")):
				errors.append(_issue(path, "Name, assumption label and current limitation are required."))
			if entry.get("availability") != AVAILABILITY[index]:
				errors.append(_issue(path + ".availability", "Do not advertise unsupported goals as playable."))
			var candidate: Variant = entry.get("candidate_config_v2")
			if not candidate is Dictionary:
				errors.append(_issue(path + ".candidate_config_v2", "Provide the exact proposed v2 config.")); continue
			if candidate.get("schema_version") != 2 or not Support.is_whole(candidate.get("schema_version")) or candidate.get("contract_revision") != CONTRACT or candidate.get("preset_id") != entry.get("id") or not revision_valid or not Support.is_whole(candidate.get("preset_revision")) or candidate.get("preset_revision") != entry.get("revision"):
				errors.append(_issue(path + ".candidate_config_v2", "Config version, draft revision and preset identity must match."))
			var mission: Variant = candidate.get("mission")
			var design: Variant = candidate.get("design")
			if not mission is Dictionary or not design is Dictionary:
				errors.append(_issue(path + ".candidate_config_v2", "Mission and stock design objects are required.")); continue
			if mission.get("title") != entry.get("display_name") or mission.get("objective") != OBJECTIVES[index]:
				errors.append(_issue(path + ".candidate_config_v2.mission", "Title and logical objective must match the preset."))
			var targets: Variant = mission.get("target_regions")
			if not targets is Array or targets.is_empty() or targets.size() > 2:
				errors.append(_issue(path + ".target_regions", "Provide one or two target IDs."))
			else:
				var target_ids: Array = []
				for target in targets:
					if not Support.is_text(target) or target_ids.has(target): errors.append(_issue(path + ".target_regions", "Target IDs must be distinct nonempty strings."))
					target_ids.append(target)
				if targets[0] != mission.get("target_region"): errors.append(_issue(path + ".target_region", "Primary target must match the first target ID."))
			for field in ["required_observations", "duration_orbits", "budget_credits"]:
				if not Support.is_whole(mission.get(field)) or mission[field] <= 0: errors.append(_issue(path + ".mission." + field, "Use a positive whole number."))
			if not Support.is_number(mission.get("required_returned_data_mb")) or mission.required_returned_data_mb <= 0:
				errors.append(_issue(path + ".required_returned_data_mb", "Returned-data requirement must be positive and finite."))
			for field in ["bus_id", "instrument_id", "solar_id", "battery_id", "radio_id", "storage_id", "launch_profile_id", "launcher_id", "orbit_id"]:
				if not Support.is_text(design.get(field)): errors.append(_issue(path + ".design." + field, "Provide the stock design's catalog ID."))
			var goal: Variant = mission.get("goal")
			if not goal is Dictionary or goal.get("kind") != KINDS[index]:
				errors.append(_issue(path + ".mission.goal", "Use this preset's distinct goal kind."))
			else:
				var count_field: String = {"survey_delivery":"minimum_complete_observations_per_target", "communication_contacts":"required_positive_contact_steps", "weather_revisit":"required_distinct_orbits"}.get(KINDS[index], "")
				if not count_field.is_empty() and (not Support.is_whole(goal.get(count_field)) or goal[count_field] <= 0):
					errors.append(_issue(path + ".mission.goal." + count_field, "Goal count must be a positive whole number."))
				var allowed: Array = ["kind"] if count_field.is_empty() else ["kind", count_field]
				for key in goal:
					if not key in allowed: errors.append(_issue(path + ".mission.goal." + str(key), "Do not mix goal counts or duplicate the common MB requirement."))
			var legacy: Variant = entry.get("legacy_config_v1")
			if index < 3:
				var expected: Dictionary = candidate.duplicate(true)
				for key in ["contract_revision", "preset_id", "preset_revision"]: expected.erase(key)
				expected.schema_version = 1
				expected.mission.erase("goal")
				if not legacy is Dictionary or JSON.parse_string(JSON.stringify(expected)) != JSON.parse_string(JSON.stringify(legacy)):
					errors.append(_issue(path + ".legacy_config_v1", "Preserve the existing v1 config exactly; never replace it with a new objective."))
			elif legacy != null:
				errors.append(_issue(path + ".legacy_config_v1", "New missions must not expose an Imaging fallback."))
			var ui: Variant = entry.get("ui_defaults")
			if not ui is Dictionary or not ui.get("target_labels") is Array or ui.target_labels.is_empty() or not Support.is_text(ui.get("orbit_label")) or not Support.is_text(ui.get("objective_label")):
				errors.append(_issue(path + ".ui_defaults", "Provide display labels separately from canonical IDs."))
	return {"ok":errors.is_empty(), "registry":value.duplicate(true) if errors.is_empty() else {}, "errors":errors}

static func get_preset(registry: Variant, id: String) -> Dictionary:
	var checked: Dictionary = inspect(registry)
	if not checked.ok: return checked
	for preset in checked.registry.presets:
		if preset.id == id: return {"ok":true, "preset":preset.duplicate(true), "errors":[]}
	return _error("UNKNOWN_PRESET", "preset_id", "Choose one of the five registered IDs.")

static func existing_v1_config(registry: Variant, id: String) -> Dictionary:
	var found: Dictionary = get_preset(registry, id)
	if not found.ok: return found
	if found.preset.legacy_config_v1 == null:
		return _error("GOAL_EXTENSION_PENDING", "preset_id", "This new goal needs K20 agreement and v2 engine/evaluator support; Imaging fallback is forbidden.")
	return {"ok":true, "config":found.preset.legacy_config_v1.duplicate(true), "scoring_supported":found.preset.availability == "existing_imaging", "limitation":found.preset.limitation, "errors":[]}

static func _issue(path: String, message: String) -> Dictionary:
	return Support.issue("INVALID_PRESET_REGISTRY", path, message, "Correct the candidate definition and rerun its checks.")

static func _error(code: String, path: String, message: String) -> Dictionary:
	return {"ok":false, "registry":{}, "errors":[Support.issue(code, path, message, "Review data/mission_presets.json and the K20 proposal.")]}
