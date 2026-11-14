class_name OrbitBridgeCatalogLoader
extends RefCounted

const Support = preload("res://scripts/core/validation_support.gd")
const CATEGORIES: Array = ["bus", "instrument", "solar", "battery", "radio", "storage"]
const ORBIT_IDS: Array = ["low_eq", "high_inc"]
const TARGET_IDS: Array = ["equator", "tropical_forest", "equatorial_ocean", "coastal_region", "temperate_land", "arctic_ice", "antarctic_region"]
const OBJECTIVE_IDS: Array = ["imaging", "survey"]


static func load_catalogs(base_path: String = "res://data") -> Dictionary:
	var errors: Array = []
	var bundle: Dictionary = {"schema_version": 1, "contract_revision": "v1.0-agreed"}
	for name in ["components", "launch_profiles", "launchers", "ke1_reference_ids"]:
		var path: String = base_path.path_join(name + ".json")
		var loaded: Dictionary = _read_document(path)
		if not loaded["ok"]:
			errors.append_array(loaded["errors"])
			continue
		var document: Dictionary = loaded["document"]
		if name == "ke1_reference_ids":
			for key in ["objective_ids", "orbit_ids", "target_region_ids"]:
				bundle[key] = document.get(key)
		else:
			bundle[name] = document.get(name)
	var orbit_path: String = base_path.path_join("orbits.json")
	if FileAccess.file_exists(orbit_path):
		var loaded_orbits: Dictionary = _read_document(orbit_path, false)
		if loaded_orbits["ok"]:
			bundle["orbit_catalog"] = loaded_orbits["document"]
		else:
			errors.append_array(loaded_orbits["errors"])
	if not errors.is_empty():
		return {"ok": false, "catalogs": {}, "errors": errors}
	var inspected: Dictionary = inspect_catalogs(bundle)
	return {"ok": inspected["ok"], "catalogs": bundle if inspected["ok"] else {}, "errors": inspected["errors"]}


static func inspect_catalogs(catalogs: Variant) -> Dictionary:
	var errors: Array = []
	var indexes: Dictionary = {"components": {}, "launch_profiles": {}, "launchers": {}}
	if typeof(catalogs) != TYPE_DICTIONARY:
		_catalog_error(errors, "catalogs", "Catalogs must be a dictionary.")
		return {"ok": false, "indexes": {}, "errors": errors}
	var bundle: Dictionary = catalogs
	if not Support.is_whole(bundle.get("schema_version")) or bundle.get("schema_version") != 1:
		_catalog_error(errors, "catalogs.schema_version", "Catalog schema_version must be 1.")
	if bundle.get("contract_revision") != "v1.0-agreed":
		_catalog_error(errors, "catalogs.contract_revision", "Catalogs must identify the agreed contract revision.")
	for key in ["components", "launch_profiles", "launchers"]:
		if typeof(bundle.get(key)) != TYPE_ARRAY or bundle[key].is_empty():
			_catalog_error(errors, "catalogs." + key, "A nonempty array is required.")
	_check_ids(bundle.get("objective_ids"), "catalogs.objective_ids", errors, OBJECTIVE_IDS)
	_check_ids(bundle.get("orbit_ids"), "catalogs.orbit_ids", errors, ORBIT_IDS)
	_check_ids(bundle.get("target_region_ids"), "catalogs.target_region_ids", errors, TARGET_IDS)
	if not errors.is_empty():
		return {"ok": false, "indexes": {}, "errors": errors}
	for orbit_id in ORBIT_IDS:
		if not bundle["orbit_ids"].has(orbit_id):
			_catalog_error(errors, "catalogs.orbit_ids", "Both agreed orbit IDs must be registered.")
	var seen: Dictionary = {}
	var present_categories: Dictionary = {}
	for index in range(bundle["components"].size()):
		var entry: Variant = bundle["components"][index]
		var path: String = "catalogs.components[%d]" % index
		if typeof(entry) != TYPE_DICTIONARY:
			_catalog_error(errors, path, "A component must be a dictionary.")
			continue
		_check_base_entry(entry, path, errors)
		var category: Variant = entry.get("category")
		if not CATEGORIES.has(category):
			_catalog_error(errors, path + ".category", "Unknown component category.")
		else:
			present_categories[category] = true
			_check_component(entry, str(category), path, errors, bundle["objective_ids"])
		_add_entry(indexes["components"], entry, path, seen, errors)
	for category in CATEGORIES:
		if not present_categories.has(category):
			_catalog_error(errors, "catalogs.components", "Missing component category: " + category)
	for index in range(bundle["launch_profiles"].size()):
		var entry: Variant = bundle["launch_profiles"][index]
		var path: String = "catalogs.launch_profiles[%d]" % index
		if typeof(entry) != TYPE_DICTIONARY:
			_catalog_error(errors, path, "A launch profile must be a dictionary.")
			continue
		_check_base_entry(entry, path, errors)
		_check_ids(entry.get("supported_orbit_ids"), path + ".supported_orbit_ids", errors, bundle["orbit_ids"])
		_check_mass_rule(entry, path, errors)
		_add_entry(indexes["launch_profiles"], entry, path, seen, errors)
	for index in range(bundle["launchers"].size()):
		var entry: Variant = bundle["launchers"][index]
		var path: String = "catalogs.launchers[%d]" % index
		if typeof(entry) != TYPE_DICTIONARY:
			_catalog_error(errors, path, "A launcher must be a dictionary.")
			continue
		_check_base_entry(entry, path, errors)
		_number(entry, "cost_credits", path, errors, true, true)
		_check_ids(entry.get("supported_profile_ids"), path + ".supported_profile_ids", errors, indexes["launch_profiles"].keys())
		var orbit_ids: Variant = entry.get("supported_orbit_ids")
		var valid_orbits: bool = _check_ids(orbit_ids, path + ".supported_orbit_ids", errors, bundle["orbit_ids"])
		var limits: Variant = entry.get("max_payload_g_by_orbit")
		if typeof(limits) != TYPE_DICTIONARY:
			_catalog_error(errors, path + ".max_payload_g_by_orbit", "Orbit-specific payload limits must be a dictionary.")
		elif valid_orbits:
			for orbit_id in orbit_ids:
				_number(limits, orbit_id, path + ".max_payload_g_by_orbit", errors, false, true)
			for orbit_id in limits:
				if not orbit_ids.has(orbit_id):
					_catalog_error(errors, path + ".max_payload_g_by_orbit", "A payload limit names an unsupported orbit.")
		_add_entry(indexes["launchers"], entry, path, seen, errors)
	return {"ok": errors.is_empty(), "indexes": indexes if errors.is_empty() else {}, "errors": errors}


static func _read_document(path: String, require_contract_revision: bool = true) -> Dictionary:
	var errors: Array = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_catalog_error(errors, path, "The catalog file could not be read.")
		return {"ok": false, "errors": errors}
	var parser: JSON = JSON.new()
	var parse_status: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_status != OK:
		_catalog_error(errors, path, "Invalid JSON at line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return {"ok": false, "errors": errors}
	if typeof(parser.data) != TYPE_DICTIONARY:
		_catalog_error(errors, path, "The catalog file root must be a dictionary.")
		return {"ok": false, "errors": errors}
	var document: Dictionary = parser.data
	if not Support.is_whole(document.get("schema_version")) or document.get("schema_version") != 1:
		_catalog_error(errors, path + ".schema_version", "Catalog file schema_version must be 1.")
	if require_contract_revision and document.get("contract_revision") != "v1.0-agreed":
		_catalog_error(errors, path + ".contract_revision", "The catalog file must identify v1.0-agreed.")
	return {"ok": errors.is_empty(), "document": document, "errors": errors}


static func _check_base_entry(entry: Dictionary, path: String, errors: Array) -> void:
	for key in ["id", "display_name", "assumption_id"]:
		if not Support.is_text(entry.get(key)) or entry[key] != entry[key].strip_edges():
			_catalog_error(errors, path + "." + key, "A nonempty trimmed string is required.")


static func _check_component(entry: Dictionary, category: String, path: String, errors: Array, objectives: Array) -> void:
	_number(entry, "mass_g", path, errors, false, true)
	_number(entry, "cost_credits", path, errors, true, true)
	match category:
		"bus":
			_number(entry, "baseline_power_w", path, errors, true)
		"instrument":
			_number(entry, "observe_power_w", path, errors, true)
			_number(entry, "data_per_observation_mb", path, errors)
			_check_ids(entry.get("supported_objectives"), path + ".supported_objectives", errors, objectives)
		"solar":
			_number(entry, "generation_power_w", path, errors, true)
		"battery":
			_number(entry, "capacity_wh", path, errors)
			_number(entry, "initial_charge_fraction", path, errors, true)
			if Support.is_number(entry.get("initial_charge_fraction")) and entry["initial_charge_fraction"] > 1:
				_catalog_error(errors, path + ".initial_charge_fraction", "Charge fraction must be between 0 and 1.")
		"radio":
			_number(entry, "transmit_power_w", path, errors, true)
			_number(entry, "downlink_mb_per_hour", path, errors)
		"storage":
			_number(entry, "capacity_mb", path, errors)


static func _check_mass_rule(entry: Dictionary, path: String, errors: Array) -> void:
	var rule: Variant = entry.get("mass_rule")
	if typeof(rule) != TYPE_DICTIONARY:
		_catalog_error(errors, path + ".mass_rule", "A mass rule dictionary is required.")
		return
	_number(rule, "threshold_g", path + ".mass_rule", errors, false, true)
	if not ["<", "<="].has(rule.get("comparator")):
		_catalog_error(errors, path + ".mass_rule.comparator", "Use < or <= for the profile mass rule.")
	if entry.get("id") == "cubesat_1u_sample":
		if rule.get("threshold_g") != 1330 or rule.get("comparator") != "<" or rule.get("source_id") != "cubesat_101_1u_sample":
			_catalog_error(errors, path + ".mass_rule", "The cited sample profile requires mass < 1330 g and its agreed source ID.")
	elif not Support.is_text(rule.get("assumption_id")):
		_catalog_error(errors, path + ".mass_rule.assumption_id", "An illustrative profile rule must identify its assumption.")


static func _add_entry(index: Dictionary, entry: Dictionary, path: String, seen: Dictionary, errors: Array) -> void:
	var id_value: Variant = entry.get("id")
	if not Support.is_text(id_value):
		return
	if seen.has(id_value):
		_catalog_error(errors, path + ".id", "Duplicate catalog ID: " + str(id_value))
		return
	seen[id_value] = true
	index[id_value] = entry.duplicate(true)


static func _number(entry: Dictionary, key: String, path: String, errors: Array, allow_zero: bool = false, require_whole: bool = false) -> void:
	var value: Variant = entry.get(key)
	if not Support.is_number(value) or (require_whole and not Support.is_whole(value)):
		_catalog_error(errors, path + "." + key, "Use a finite number" + (" with a whole value." if require_whole else "."))
	elif value < 0 or (not allow_zero and value == 0):
		_catalog_error(errors, path + "." + key, "Value must be " + ("nonnegative." if allow_zero else "positive."))


static func _check_ids(value: Variant, path: String, errors: Array, allowed: Array) -> bool:
	var start_size: int = errors.size()
	if typeof(value) != TYPE_ARRAY or value.is_empty():
		_catalog_error(errors, path, "Use a nonempty array of stable string IDs.")
		return false
	var seen: Dictionary = {}
	for item in value:
		if not Support.is_text(item):
			_catalog_error(errors, path, "Each ID must be a nonempty string.")
		elif seen.has(item):
			_catalog_error(errors, path, "Duplicate ID: " + str(item))
		else:
			seen[item] = true
			if not allowed.has(item):
				_catalog_error(errors, path, "Unknown referenced ID: " + str(item))
	return errors.size() == start_size


static func _catalog_error(errors: Array, path: String, message: String) -> void:
	errors.append(Support.issue("INVALID_SCHEMA", path, message, "Correct the catalog data using data/README.md and the agreed contract."))
