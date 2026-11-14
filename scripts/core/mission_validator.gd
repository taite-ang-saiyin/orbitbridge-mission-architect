class_name MissionValidator
extends RefCounted

const Support = preload("res://scripts/core/validation_support.gd")
const CatalogLoader = preload("res://scripts/core/catalog_loader.gd")
const CHECK_IDS: Array = ["input_schema", "catalog_references", "profile_mass", "launcher_capacity", "budget", "launch_orbit", "target_orbit", "essential_power"]
const MISSION_FIELDS: Array = ["title", "objective", "target_region", "required_observations", "required_returned_data_mb", "duration_orbits", "budget_credits"]
const DESIGN_FIELDS: Array = ["bus_id", "instrument_id", "solar_id", "battery_id", "radio_id", "storage_id", "launch_profile_id", "launcher_id", "orbit_id"]


static func validate(config: Variant, catalogs: Variant) -> Dictionary:
	var checks: Dictionary = {}
	for id_value in CHECK_IDS:
		checks[id_value] = {"status": "not_evaluated", "passed": null, "message": "Full design checks are not implemented yet (K07-K09). Launch is not approved."}
	checks["profile_mass"].merge({"total_mass_g": null, "threshold_g": null, "comparator": null, "profile_id": null, "source_id": null})
	var result: Dictionary = {"schema_version": 1, "ready_to_launch": false, "metrics": null, "checks": checks, "errors": [], "warnings": []}
	var shape_errors: Array = _check_shape(config)
	result["errors"].append_array(shape_errors)
	_set_check(checks, "input_schema", shape_errors.is_empty(), "Mission fields are valid." if shape_errors.is_empty() else "Correct the listed mission fields.")
	var inspection: Dictionary = CatalogLoader.inspect_catalogs(catalogs)
	if not inspection["ok"]:
		result["errors"].append_array(inspection["errors"])
		_set_check(checks, "catalog_references", false, "The supplied catalogs are invalid.")
	elif shape_errors.is_empty():
		var reference_errors: Array = _check_references(config, catalogs, inspection["indexes"])
		result["errors"].append_array(reference_errors)
		_set_check(checks, "catalog_references", reference_errors.is_empty(), "All selected IDs were found in their proper categories." if reference_errors.is_empty() else "Correct the listed selections.")
	else:
		checks["catalog_references"]["message"] = "Selection lookup waits for valid mission fields."
	if not result["errors"].is_empty():
		for key in CHECK_IDS:
			if key not in ["input_schema", "catalog_references"]:
				checks[key]["message"] = "Not evaluated because mission fields or catalogs have errors."
	return result


static func _check_shape(config: Variant) -> Array:
	var errors: Array = []
	if typeof(config) != TYPE_DICTIONARY:
		errors.append(Support.issue("INVALID_SCHEMA", "", "Mission configuration must be a dictionary.", "Provide schema_version, mission and design objects."))
		return errors
	var root: Dictionary = config
	_required(root, ["schema_version", "mission", "design"], "", errors)
	_unknown(root, ["schema_version", "mission", "design"], "", errors)
	if root.has("schema_version") and (not Support.is_whole(root["schema_version"]) or root["schema_version"] != 1):
		errors.append(Support.issue("INVALID_SCHEMA", "schema_version", "Supported schema_version is 1.", "Use numeric schema_version 1."))
	if root.has("mission"):
		if typeof(root["mission"]) != TYPE_DICTIONARY:
			errors.append(Support.issue("INVALID_SCHEMA", "mission", "Mission must be a dictionary.", "Provide the required mission fields."))
		else:
			_check_mission(root["mission"], errors)
	if root.has("design"):
		if typeof(root["design"]) != TYPE_DICTIONARY:
			errors.append(Support.issue("INVALID_SCHEMA", "design", "Design must be a dictionary.", "Provide selected component, profile, launcher and orbit IDs."))
		else:
			var design: Dictionary = root["design"]
			_required(design, DESIGN_FIELDS, "design", errors, "MISSING_COMPONENT")
			_unknown(design, DESIGN_FIELDS, "design", errors)
			for field in DESIGN_FIELDS:
				if design.has(field):
					_check_text(design[field], "design." + field, errors)
	return errors


static func _check_mission(mission: Dictionary, errors: Array) -> void:
	_required(mission, MISSION_FIELDS, "mission", errors)
	_unknown(mission, MISSION_FIELDS, "mission", errors)
	for field in ["title", "objective", "target_region"]:
		if mission.has(field):
			_check_text(mission[field], "mission." + field, errors)
	if typeof(mission.get("title")) == TYPE_STRING and mission["title"].length() > 80:
		errors.append(Support.issue("INVALID_VALUE", "mission.title", "Mission title is longer than 80 characters.", "Shorten the title to 80 characters or fewer."))
	for field in ["required_observations", "duration_orbits", "budget_credits"]:
		if not mission.has(field):
			continue
		var value: Variant = mission[field]
		var maximum: int = 20 if field == "required_observations" else (12 if field == "duration_orbits" else Support.MAX_SAFE_INTEGER)
		if not Support.is_whole(value) or value < 1 or value > maximum:
			errors.append(Support.issue("INVALID_VALUE", "mission." + field, "Use a positive whole number within the allowed range.", "Choose 1-%d; values must be finite and reliably representable." % maximum))
	if mission.has("required_returned_data_mb"):
		var value: Variant = mission["required_returned_data_mb"]
		if not Support.is_number(value) or value <= 0:
			errors.append(Support.issue("INVALID_VALUE", "mission.required_returned_data_mb", "Returned-data target must be a positive finite number.", "Choose a positive amount of data in MB."))


static func _check_references(config: Dictionary, catalogs: Dictionary, indexes: Dictionary) -> Array:
	var errors: Array = []
	var mission: Dictionary = config["mission"]
	var design: Dictionary = config["design"]
	for pair in [["objective", "objective_ids"], ["target_region", "target_region_ids"]]:
		if not catalogs[pair[1]].has(mission[pair[0]]):
			errors.append(Support.issue("INVALID_VALUE", "mission." + pair[0], "Unknown " + pair[0] + ": " + mission[pair[0]], "Choose an ID from the registered mission choices."))
	for category in CatalogLoader.CATEGORIES:
		var field: String = category + "_id"
		var id_value: String = design[field]
		if not indexes["components"].has(id_value):
			errors.append(Support.issue("UNKNOWN_COMPONENT", "design." + field, "Unknown component: " + id_value, "Choose an existing " + category + " from the component catalog."))
		elif indexes["components"][id_value]["category"] != category:
			errors.append(Support.issue("WRONG_COMPONENT_CATEGORY", "design." + field, "This component does not belong in the " + category + " slot.", "Select a component from the correct category."))
	for pair in [["launch_profile_id", "launch_profiles", "UNKNOWN_PROFILE"], ["launcher_id", "launchers", "UNKNOWN_LAUNCHER"]]:
		if not indexes[pair[1]].has(design[pair[0]]):
			errors.append(Support.issue(pair[2], "design." + pair[0], "Unknown selected ID: " + design[pair[0]], "Choose an ID from the corresponding catalog."))
	if not catalogs["orbit_ids"].has(design["orbit_id"]):
		errors.append(Support.issue("UNKNOWN_ORBIT", "design.orbit_id", "Unknown orbit ID: " + design["orbit_id"], "Choose low_eq or high_inc."))
	return errors


static func _check_text(value: Variant, path: String, errors: Array) -> void:
	if not Support.is_text(value) or value != value.strip_edges():
		errors.append(Support.issue("INVALID_VALUE", path, "Use a nonempty string without leading or trailing whitespace.", "Provide the title or exact registered ID as a trimmed string."))


static func _required(record: Dictionary, fields: Array, path: String, errors: Array, code: String = "INVALID_SCHEMA") -> void:
	for field in fields:
		if not record.has(field):
			var field_path: String = field if path.is_empty() else path + "." + field
			errors.append(Support.issue(code, field_path, "Required field is missing.", "Provide " + field_path + "."))


static func _unknown(record: Dictionary, fields: Array, path: String, errors: Array) -> void:
	for field in record:
		if not fields.has(field):
			var field_path: String = str(field) if path.is_empty() else path + "." + str(field)
			errors.append(Support.issue("INVALID_SCHEMA", field_path, "Unrecognized configuration field.", "Use only the field names in the agreed contract."))


static func _set_check(checks: Dictionary, key: String, passed: bool, message: String) -> void:
	checks[key] = {"status": "pass" if passed else "fail", "passed": passed, "message": message}
