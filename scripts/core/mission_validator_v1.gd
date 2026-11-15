extends RefCounted

const Support = preload("res://scripts/core/validation_support.gd")
const CatalogLoader = preload("res://scripts/core/catalog_loader.gd")
const CHECK_IDS: Array = ["input_schema", "catalog_references", "profile_mass", "launcher_capacity", "budget", "launch_orbit", "target_orbit", "essential_power"]
const MISSION_FIELDS: Array = ["title", "objective", "target_region", "required_observations", "required_returned_data_mb", "duration_orbits", "budget_credits"]
const DESIGN_FIELDS: Array = ["bus_id", "instrument_id", "solar_id", "battery_id", "radio_id", "storage_id", "launch_profile_id", "launcher_id", "orbit_id"]


static func validate(config: Variant, catalogs: Variant) -> Dictionary:
	var checks: Dictionary = {}
	for id_value in CHECK_IDS:
		checks[id_value] = {"status": "not_evaluated", "passed": null, "message": "Not evaluated until valid inputs and design totals are available."}
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
	var totals: Dictionary = _calculate_metrics(config, inspection["indexes"])
	if not totals["ok"]:
		result["errors"].append_array(totals["errors"])
		for key in CHECK_IDS:
			if key not in ["input_schema", "catalog_references"]:
				checks[key]["message"] = "Not evaluated because design totals exceed the safe numeric range."
		return result
	result["metrics"] = totals["metrics"]
	_run_readiness(config, catalogs, inspection["indexes"], result)
	result["ready_to_launch"] = result["errors"].is_empty()
	for key in CHECK_IDS:
		if checks[key]["status"] != "pass":
			result["ready_to_launch"] = false
	return result


static func _calculate_metrics(config: Dictionary, indexes: Dictionary) -> Dictionary:
	var design: Dictionary = config["design"]
	var parts: Dictionary = indexes["components"]
	var launcher: Dictionary = indexes["launchers"][design["launcher_id"]]
	var mass: int = 0
	var cost: int = int(launcher["cost_credits"])
	for category in CatalogLoader.CATEGORIES:
		var part: Dictionary = parts[design[category + "_id"]]
		var part_mass: int = int(part["mass_g"])
		var part_cost: int = int(part["cost_credits"])
		if mass > Support.MAX_SAFE_INTEGER - part_mass:
			return {"ok": false, "errors": [Support.issue("INVALID_VALUE", "metrics.total_mass_g", "Combined spacecraft mass exceeds the safe numeric range.", "Use component masses whose combined total fits the documented numeric range.")]}
		if cost > Support.MAX_SAFE_INTEGER - part_cost:
			return {"ok": false, "errors": [Support.issue("INVALID_VALUE", "metrics.total_cost_credits", "Combined cost exceeds the safe numeric range.", "Use component and launch costs whose combined total fits the documented numeric range.")]}
		mass += part_mass
		cost += part_cost
	var bus: Dictionary = parts[design["bus_id"]]
	var instrument: Dictionary = parts[design["instrument_id"]]
	var solar: Dictionary = parts[design["solar_id"]]
	var battery: Dictionary = parts[design["battery_id"]]
	var radio: Dictionary = parts[design["radio_id"]]
	var storage: Dictionary = parts[design["storage_id"]]
	var initial_energy: float = float(battery["capacity_wh"]) * float(battery["initial_charge_fraction"])
	if not is_finite(initial_energy):
		return {"ok": false, "errors": [Support.issue("INVALID_VALUE", "metrics.initial_energy_wh", "Initial energy cannot be represented safely.", "Correct the battery capacity and initial-charge values.")]}
	return {"ok": true, "metrics": {
		"total_mass_g": mass,
		"total_cost_credits": cost,
		"baseline_power_w": bus["baseline_power_w"],
		"solar_generation_power_w": solar["generation_power_w"],
		"battery_capacity_wh": battery["capacity_wh"],
		"initial_energy_wh": initial_energy,
		"storage_capacity_mb": storage["capacity_mb"],
		"data_per_observation_mb": instrument["data_per_observation_mb"],
		"downlink_mb_per_hour": radio["downlink_mb_per_hour"]
	}, "errors": []}


static func _run_readiness(config: Dictionary, catalogs: Dictionary, indexes: Dictionary, result: Dictionary) -> void:
	var checks: Dictionary = result["checks"]
	var metrics: Dictionary = result["metrics"]
	var design: Dictionary = config["design"]
	var profile: Dictionary = indexes["launch_profiles"][design["launch_profile_id"]]
	var launcher: Dictionary = indexes["launchers"][design["launcher_id"]]
	var rule: Dictionary = profile["mass_rule"]
	var orbit_id: String = design["orbit_id"]
	var mass: int = metrics["total_mass_g"]
	var threshold: int = int(rule["threshold_g"])
	var mass_passed: bool = mass < threshold if rule["comparator"] == "<" else mass <= threshold
	_set_check(checks, "profile_mass", mass_passed, "Spacecraft mass meets the selected profile rule." if mass_passed else "Spacecraft mass does not meet the selected profile rule.")
	checks["profile_mass"].merge({"total_mass_g": mass, "threshold_g": threshold, "comparator": rule["comparator"], "profile_id": profile["id"], "source_id": rule.get("source_id")}, true)
	if rule.has("assumption_id"):
		checks["profile_mass"]["assumption_id"] = rule["assumption_id"]
	if not mass_passed:
		var issue: Dictionary = Support.issue("PROFILE_MASS_EXCEEDED", "design.launch_profile_id", "Spacecraft mass is %d g; this profile requires mass %s %d g." % [mass, rule["comparator"], threshold], "Choose lighter parts or a suitable alternative launch profile.")
		if rule.has("source_id"):
			issue["source_id"] = rule["source_id"]
		result["errors"].append(issue)
	if launcher["supported_orbit_ids"].has(orbit_id):
		var capacity: int = int(launcher["max_payload_g_by_orbit"][orbit_id])
		var capacity_passed: bool = mass <= capacity
		_set_check(checks, "launcher_capacity", capacity_passed, "Spacecraft fits the launcher capacity for this orbit." if capacity_passed else "Spacecraft exceeds the launcher capacity for this orbit.")
		if not capacity_passed:
			result["errors"].append(Support.issue("LAUNCHER_CAPACITY_EXCEEDED", "design.launcher_id", "Spacecraft mass is %d g; launcher capacity for %s is %d g." % [mass, orbit_id, capacity], "Choose a stronger launcher or lighter parts."))
	else:
		checks["launcher_capacity"]["message"] = "This launcher has no payload limit for the selected unsupported orbit."
	var budget_passed: bool = metrics["total_cost_credits"] <= config["mission"]["budget_credits"]
	_set_check(checks, "budget", budget_passed, "Design and launch costs fit the budget." if budget_passed else "Design and launch costs exceed the budget.")
	if not budget_passed:
		result["errors"].append(Support.issue("BUDGET_EXCEEDED", "mission.budget_credits", "Parts plus launch cost %d credits; budget is %d credits." % [metrics["total_cost_credits"], int(config["mission"]["budget_credits"])], "Choose cheaper parts/launch or increase the mission budget."))
	var compatibility_errors: Array = []
	if not profile["supported_orbit_ids"].has(orbit_id):
		compatibility_errors.append(Support.issue("LAUNCH_ORBIT_INCOMPATIBLE", "design.orbit_id", "The selected launch profile does not support this orbit.", "Choose an orbit supported by the profile or change profile."))
	if not launcher["supported_profile_ids"].has(profile["id"]):
		compatibility_errors.append(Support.issue("LAUNCH_ORBIT_INCOMPATIBLE", "design.launcher_id", "This launcher does not support the selected launch profile.", "Choose a launcher that supports this profile."))
	if not launcher["supported_orbit_ids"].has(orbit_id):
		compatibility_errors.append(Support.issue("LAUNCH_ORBIT_INCOMPATIBLE", "design.orbit_id", "This launcher does not support the selected orbit.", "Choose an orbit supported by the launcher or change launcher."))
	_set_check(checks, "launch_orbit", compatibility_errors.is_empty(), "Profile, launcher and orbit are compatible." if compatibility_errors.is_empty() else "The selected profile, launcher and orbit are not compatible.")
	result["errors"].append_array(compatibility_errors)
	for target_id in config.mission.get("target_regions", [config.mission.target_region]):
		var target: Dictionary = _check_target(catalogs.get("orbit_catalog"), orbit_id, target_id)
		if checks.target_orbit.status == "not_evaluated" or target.check.status != "pass":
			checks.target_orbit = target.check
		for issue in target.errors:
			issue.message = str(target_id) + ": " + issue.message
		result.errors.append_array(target.errors)
	var power_passed: bool = metrics["battery_capacity_wh"] > 0 and metrics["initial_energy_wh"] > 0 and metrics["initial_energy_wh"] <= metrics["battery_capacity_wh"] and metrics["solar_generation_power_w"] >= metrics["baseline_power_w"]
	_set_check(checks, "essential_power", power_passed, "Design meets the illustrative pre-launch power rule; mission energy is still simulated separately." if power_passed else "Design fails the illustrative pre-launch power rule.")
	if not power_passed:
		result["errors"].append(Support.issue("ESSENTIAL_POWER_INFEASIBLE", "design", "Use positive battery capacity/initial charge and sunlit solar power at least equal to the baseline load.", "Choose more solar power, a lower-load bus or a charged battery."))


static func _check_target(orbit_catalog: Variant, orbit_id: String, target_id: String) -> Dictionary:
	if typeof(orbit_catalog) != TYPE_DICTIONARY:
		return _bad_orbit("catalogs.orbit_catalog", "HPC orbit information is missing or malformed.")
	var metadata: Dictionary = orbit_catalog
	if not Support.is_whole(metadata.get("schema_version")) or metadata.get("schema_version") != 1:
		return _bad_orbit("catalogs.orbit_catalog.schema_version", "HPC orbit schema_version must be 1.")
	if not Support.is_text(metadata.get("scenario_version")):
		return _bad_orbit("catalogs.orbit_catalog.scenario_version", "The orbit scenario version is missing.")
	var units: Variant = metadata.get("unit_conventions")
	if typeof(units) != TYPE_DICTIONARY or units.get("step_duration") != "hours" or units.get("data_unit") != "decimal_mb" or units.get("kilobytes_per_megabyte") != 1000:
		return _bad_orbit("catalogs.orbit_catalog.unit_conventions", "HPC orbit units must use hours and decimal MB (1000 KB per MB).")
	var orbits: Variant = metadata.get("orbits")
	if typeof(orbits) != TYPE_ARRAY or orbits.is_empty():
		return _bad_orbit("catalogs.orbit_catalog.orbits", "A nonempty array of HPC orbit presets is required.")
	var seen: Dictionary = {}
	var selected: Dictionary = {}
	for entry in orbits:
		if typeof(entry) != TYPE_DICTIONARY or not Support.is_text(entry.get("id")):
			return _bad_orbit("catalogs.orbit_catalog.orbits", "Every orbit preset needs a valid ID.")
		if seen.has(entry["id"]) or not CatalogLoader.ORBIT_IDS.has(entry["id"]):
			return _bad_orbit("catalogs.orbit_catalog.orbits", "Orbit IDs must be unique and match the agreed vocabulary.")
		seen[entry["id"]] = true
		if entry["id"] == orbit_id:
			selected = entry
	if selected.is_empty():
		return _bad_orbit("catalogs.orbit_catalog.orbits", "HPC metadata does not contain the selected orbit.")
	if not Support.is_number(selected.get("step_duration_hours")) or selected["step_duration_hours"] <= 0:
		return _bad_orbit("catalogs.orbit_catalog.orbits.step_duration_hours", "The selected orbit needs a positive finite step duration in hours.")
	if not Support.is_whole(selected.get("steps_per_orbit")) or selected["steps_per_orbit"] < 1:
		return _bad_orbit("catalogs.orbit_catalog.orbits.steps_per_orbit", "The selected orbit needs a positive whole number of steps per orbit.")
	var windows: Variant = selected.get("target_windows")
	if typeof(windows) != TYPE_DICTIONARY:
		return _bad_orbit("catalogs.orbit_catalog.orbits.target_windows", "Target observation-window metadata is missing or malformed.")
	for key in windows:
		if not Support.is_text(key) or typeof(windows[key]) != TYPE_ARRAY:
			return _bad_orbit("catalogs.orbit_catalog.orbits.target_windows", "Target IDs must map to arrays of observation steps.")
		for step in windows[key]:
			if not Support.is_whole(step) or step < 0 or step >= selected["steps_per_orbit"]:
				return _bad_orbit("catalogs.orbit_catalog.orbits.target_windows", "Observation steps must be whole indices within the orbit.")
	var passed: bool = windows.has(target_id) and not windows[target_id].is_empty()
	var errors: Array = []
	if not passed:
		errors.append(Support.issue("TARGET_ORBIT_INCOMPATIBLE", "mission.target_region", "The selected orbit has no authored observation window for this target.", "Choose a suitable orbit/target using HPC's scenario data."))
	return {"check": {"status": "pass" if passed else "fail", "passed": passed, "message": "HPC metadata provides observation opportunities for this target; individual actions still depend on the current step." if passed else "No observation opportunity is defined for this target in the selected orbit."}, "errors": errors}


static func _bad_orbit(path: String, message: String) -> Dictionary:
	return {"check": {"status": "not_evaluated", "passed": null, "message": message}, "errors": [Support.issue("INVALID_SCHEMA", path, message, "Supply the matching data/orbits.json from HPC or its documented orbit_catalog dictionary; do not guess coverage.")]}


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
	_unknown(mission, MISSION_FIELDS + ["target_regions"], "mission", errors)
	if mission.has("target_regions"):
		var targets: Variant = mission.target_regions
		if not targets is Array or targets.is_empty() or targets.size() > 2:
			errors.append(Support.issue("INVALID_VALUE", "mission.target_regions", "Choose one or two target regions.", "Select up to two different targets."))
		else:
			var seen: Array = []
			for target in targets:
				if not Support.is_text(target) or seen.has(target):
					errors.append(Support.issue("INVALID_VALUE", "mission.target_regions", "Target IDs must be unique registered strings.", "Choose different targets."))
				seen.append(target)
			if targets[0] != mission.get("target_region"):
				errors.append(Support.issue("INVALID_VALUE", "mission.target_region", "Primary target must match the first target region.", "Keep both target fields consistent."))
			if mission.get("objective") == "survey" and Support.is_whole(mission.get("required_observations")) and mission.required_observations < targets.size():
				errors.append(Support.issue("INVALID_VALUE", "mission.required_observations", "Survey needs at least one capture per selected target.", "Increase required observations."))
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
	for target in mission.get("target_regions", [mission.target_region]):
		if not catalogs.target_region_ids.has(target):
			errors.append(Support.issue("INVALID_VALUE", "mission.target_regions", "Unknown target ID: " + str(target), "Choose a registered target."))
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
