extends SceneTree

const Validator = preload("res://scripts/core/mission_validator.gd")
const Loader = preload("res://scripts/core/catalog_loader.gd")
const Support = preload("res://scripts/core/validation_support.gd")

var passed: int = 0
var failed: int = 0
var config: Dictionary = {}
var catalogs: Dictionary = {}


func _initialize() -> void:
	var loaded: Dictionary = Loader.load_catalogs()
	_check(loaded["ok"], "Load the real KE1 catalog files")
	if not loaded["ok"]:
		print(JSON.stringify(loaded["errors"]))
		quit(1)
		return
	catalogs = loaded["catalogs"]
	var fixture_file: FileAccess = FileAccess.open("res://tests/fixtures/ke1_config.json", FileAccess.READ)
	config = JSON.parse_string(fixture_file.get_as_text())
	fixture_file.close()
	_test_real_data()
	_test_valid_lookup()
	_test_shape_failures()
	_test_numeric_boundaries()
	_test_references()
	_test_catalog_failures()
	_test_repeatability()
	print("KE1 K05/K06: %d checks passed; %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _test_real_data() -> void:
	_check(catalogs["components"].size() == 12, "Twelve component options are loaded")
	_check(catalogs["launch_profiles"].size() == 2, "Two profiles are loaded")
	_check(catalogs["launchers"].size() == 2, "Two launchers are loaded")
	_check(catalogs["orbit_ids"] == ["low_eq", "high_inc"], "Only agreed orbit identifiers are registered")
	_check(catalogs["target_region_ids"] == ["equator"], "Agreed target identifier is registered")
	var inspected: Dictionary = Loader.inspect_catalogs(catalogs)
	for category in Loader.CATEGORIES:
		var count: int = 0
		for entry in catalogs["components"]:
			if entry["category"] == category:
				count += 1
		_check(count >= 2, "Two selectable options for " + category)
	var sample: Dictionary = inspected["indexes"]["launch_profiles"]["cubesat_1u_sample"]["mass_rule"]
	_check(sample["threshold_g"] == 1330 and sample["comparator"] == "<", "Strict source mass criterion is stored correctly")
	_check(sample["source_id"] == "cubesat_101_1u_sample", "Source identifier is preserved")
	var alternative: Dictionary = inspected["indexes"]["launch_profiles"]["illustrative_alternative"]["mass_rule"]
	_check(alternative["threshold_g"] == 5000 and alternative["comparator"] == "<=", "Alternative profile has its own illustrative rule")
	_check(not alternative.has("source_id") and alternative.has("assumption_id"), "Alternative limit is not mislabeled as NASA data")
	for entry in catalogs["components"]:
		_check(Support.is_text(entry.get("assumption_id")), "Component assumptions are identified: " + entry["id"])
	var radio: Dictionary = _part(catalogs, "radio_basic")
	_check(radio.has("downlink_mb_per_hour") and not radio.has("downlink_mb_per_step"), "Radio uses the agreed hourly rate")
	inspected["indexes"]["components"]["bus_basic"]["mass_g"] = 999
	_check(_part(catalogs, "bus_basic")["mass_g"] == 300, "Returned catalog indexes are independent copies")
	var missing: Dictionary = Loader.load_catalogs("res://tests/fixtures/no_such_catalogs")
	_check(not missing["ok"] and not missing["errors"].is_empty(), "Missing catalog files return structured errors")
	var wrong_root: Dictionary = Loader.load_catalogs("res://tests/fixtures/catalog_wrong_shape")
	_check(not wrong_root["ok"] and not wrong_root["errors"].is_empty(), "Wrong JSON root returns structured errors")


func _test_valid_lookup() -> void:
	var result: Dictionary = Validator.validate(config, catalogs)
	_check(result["errors"].is_empty(), "Agreed mission config resolves all selected IDs")
	_check(result["checks"]["input_schema"]["passed"] == true, "Valid input shape passes")
	_check(result["checks"]["catalog_references"]["passed"] == true, "All references and categories pass")
	_check(result["ready_to_launch"] == false and result["metrics"] == null, "K05 foundation does not grant premature launch approval")
	for field in ["total_mass_g", "threshold_g", "comparator", "profile_id", "source_id"]:
		_check(result["checks"]["profile_mass"].has(field) and result["checks"]["profile_mass"][field] == null, "Future mass-check field is present without a fabricated value: " + field)
	for key in Validator.CHECK_IDS:
		if key not in ["input_schema", "catalog_references"]:
			_check(result["checks"][key]["status"] == "not_evaluated", "Future readiness check is explicitly pending: " + key)
	for entry in catalogs["components"]:
		var changed: Dictionary = config.duplicate(true)
		changed["design"][entry["category"] + "_id"] = entry["id"]
		_check(Validator.validate(changed, catalogs)["errors"].is_empty(), "Every actual component is selectable: " + entry["id"])
	for profile in catalogs["launch_profiles"]:
		var changed: Dictionary = config.duplicate(true)
		changed["design"]["launch_profile_id"] = profile["id"]
		_check(Validator.validate(changed, catalogs)["errors"].is_empty(), "Profile lookup: " + profile["id"])
	for launcher in catalogs["launchers"]:
		var changed: Dictionary = config.duplicate(true)
		changed["design"]["launcher_id"] = launcher["id"]
		_check(Validator.validate(changed, catalogs)["errors"].is_empty(), "Launcher lookup: " + launcher["id"])
	for orbit_id in catalogs["orbit_ids"]:
		var changed: Dictionary = config.duplicate(true)
		changed["design"]["orbit_id"] = orbit_id
		_check(Validator.validate(changed, catalogs)["errors"].is_empty(), "Orbit vocabulary lookup: " + orbit_id)


func _test_shape_failures() -> void:
	for value in [null, [], "mission", 12, true]:
		_expect_issue(Validator.validate(value, catalogs), "INVALID_SCHEMA", "", "Invalid configuration root")
	for field in ["schema_version", "mission", "design"]:
		var changed: Dictionary = config.duplicate(true)
		changed.erase(field)
		_expect_issue(Validator.validate(changed, catalogs), "INVALID_SCHEMA", field, "Missing root field " + field)
	for value in [null, [], "text", 3, false]:
		for field in ["mission", "design"]:
			var changed: Dictionary = config.duplicate(true)
			changed[field] = value
			_expect_issue(Validator.validate(changed, catalogs), "INVALID_SCHEMA", field, "Wrong nested object type")
	for field in Validator.MISSION_FIELDS:
		var changed: Dictionary = config.duplicate(true)
		changed["mission"].erase(field)
		_expect_issue(Validator.validate(changed, catalogs), "INVALID_SCHEMA", "mission." + field, "Missing mission field")
	for field in Validator.DESIGN_FIELDS:
		var changed: Dictionary = config.duplicate(true)
		changed["design"].erase(field)
		_expect_issue(Validator.validate(changed, catalogs), "MISSING_COMPONENT", "design." + field, "Missing selected ID")
	for value in [null, "", " ", [], 9, false, " bus_basic"]:
		var changed: Dictionary = config.duplicate(true)
		changed["design"]["bus_id"] = value
		_expect_issue(Validator.validate(changed, catalogs), "INVALID_VALUE", "design.bus_id", "Bad ID type/text")
	for value in [0, 2, true, "1", 1.5, INF, NAN]:
		var changed: Dictionary = config.duplicate(true)
		changed["schema_version"] = value
		_expect_issue(Validator.validate(changed, catalogs), "INVALID_SCHEMA", "schema_version", "Wrong schema version")
	for value in ["", "   ", " leading", "trailing ", "x".repeat(81), null, 1]:
		var changed: Dictionary = config.duplicate(true)
		changed["mission"]["title"] = value
		_expect_issue(Validator.validate(changed, catalogs), "INVALID_VALUE", "mission.title", "Invalid title")
	for section in ["", "mission", "design"]:
		var changed: Dictionary = config.duplicate(true)
		if section.is_empty():
			changed["unexpected"] = true
		else:
			changed[section]["unexpected"] = true
		var path: String = "unexpected" if section.is_empty() else section + ".unexpected"
		_expect_issue(Validator.validate(changed, catalogs), "INVALID_SCHEMA", path, "Unknown fields are not silently ignored")


func _test_numeric_boundaries() -> void:
	for field in ["required_observations", "duration_orbits", "budget_credits", "required_returned_data_mb"]:
		for value in [0, -1, null, "3", true, false, INF, NAN, []]:
			var changed: Dictionary = config.duplicate(true)
			changed["mission"][field] = value
			_expect_issue(Validator.validate(changed, catalogs), "INVALID_VALUE", "mission." + field, "Bad numeric mission field")
	for field in ["required_observations", "duration_orbits", "budget_credits"]:
		var changed: Dictionary = config.duplicate(true)
		changed["mission"][field] = 1.5
		_expect_issue(Validator.validate(changed, catalogs), "INVALID_VALUE", "mission." + field, "Fractional whole-value field")
	for pair in [["required_observations", 20, 21], ["duration_orbits", 12, 13]]:
		for accepted_value in [1, pair[1], 1.0]:
			var changed: Dictionary = config.duplicate(true)
			changed["mission"][pair[0]] = accepted_value
			_check(Validator.validate(changed, catalogs)["errors"].is_empty(), "Inclusive count range and whole JSON floats")
		var changed: Dictionary = config.duplicate(true)
		changed["mission"][pair[0]] = pair[2]
		_expect_issue(Validator.validate(changed, catalogs), "INVALID_VALUE", "mission." + pair[0], "Above allowed count range")
	var changed: Dictionary = config.duplicate(true)
	changed["mission"]["budget_credits"] = 1e25
	_expect_issue(Validator.validate(changed, catalogs), "INVALID_VALUE", "mission.budget_credits", "Unsafe whole value is rejected")
	changed = config.duplicate(true)
	changed["mission"]["required_returned_data_mb"] = 0.25
	_check(Validator.validate(changed, catalogs)["errors"].is_empty(), "Positive fractional MB targets are allowed")


func _test_references() -> void:
	for field in Validator.DESIGN_FIELDS:
		var changed: Dictionary = config.duplicate(true)
		changed["design"][field] = "unknown_id"
		var code: String = "UNKNOWN_COMPONENT"
		if field == "orbit_id":
			code = "UNKNOWN_ORBIT"
		elif field == "launcher_id":
			code = "UNKNOWN_LAUNCHER"
		elif field == "launch_profile_id":
			code = "UNKNOWN_PROFILE"
		_expect_issue(Validator.validate(changed, catalogs), code, "design." + field, "Unknown selected identifier")
	for field in ["objective", "target_region"]:
		var changed: Dictionary = config.duplicate(true)
		changed["mission"][field] = "unknown_id"
		_expect_issue(Validator.validate(changed, catalogs), "INVALID_VALUE", "mission." + field, "Unknown goal/target")
	var changed: Dictionary = config.duplicate(true)
	changed["design"]["instrument_id"] = "radio_basic"
	_expect_issue(Validator.validate(changed, catalogs), "WRONG_COMPONENT_CATEGORY", "design.instrument_id", "Known part in the wrong slot")


func _test_catalog_failures() -> void:
	for value in [null, [], "catalog", 7]:
		_expect_catalog_error(value, "Wrong catalog root")
	for field in ["schema_version", "contract_revision", "components", "launch_profiles", "launchers", "orbit_ids", "objective_ids", "target_region_ids"]:
		var changed: Dictionary = catalogs.duplicate(true)
		changed.erase(field)
		_expect_catalog_error(changed, "Missing catalog section: " + field)
	for value in [null, {}, [], [null]]:
		var changed: Dictionary = catalogs.duplicate(true)
		changed["components"] = value
		_expect_catalog_error(changed, "Malformed component collection")
	var changed: Dictionary = catalogs.duplicate(true)
	changed["components"][1]["id"] = changed["components"][0]["id"]
	_expect_catalog_error(changed, "Duplicate IDs")
	changed = catalogs.duplicate(true)
	_part(changed, "bus_basic")["category"] = "unknown"
	_expect_catalog_error(changed, "Unknown category")
	for value in [-1, 0, 1.5, "300", true, INF, NAN]:
		changed = catalogs.duplicate(true)
		_part(changed, "bus_basic")["mass_g"] = value
		_expect_catalog_error(changed, "Invalid component mass")
	for pair in [["bus_basic", "baseline_power_w"], ["instrument_basic", "data_per_observation_mb"], ["solar_standard", "generation_power_w"], ["battery_standard", "capacity_wh"], ["radio_basic", "downlink_mb_per_hour"], ["storage_standard", "capacity_mb"]]:
		changed = catalogs.duplicate(true)
		_part(changed, pair[0]).erase(pair[1])
		_expect_catalog_error(changed, "Missing category-specific value")
	for value in [-1, true, "12", 0.5, INF]:
		changed = catalogs.duplicate(true)
		_part(changed, "bus_basic")["cost_credits"] = value
		_expect_catalog_error(changed, "Invalid component cost")
	for value in [-0.1, 1.1, NAN]:
		changed = catalogs.duplicate(true)
		_part(changed, "battery_standard")["initial_charge_fraction"] = value
		_expect_catalog_error(changed, "Invalid initial charge fraction")
	changed = catalogs.duplicate(true)
	_part(changed, "instrument_basic")["supported_objectives"] = ["unknown"]
	_expect_catalog_error(changed, "Unregistered instrument objective")
	changed = catalogs.duplicate(true)
	_part(changed, "bus_basic").erase("assumption_id")
	_expect_catalog_error(changed, "Missing illustrative-value label")
	for replacement in [{"comparator": "<=", "threshold_g": 1330, "source_id": "cubesat_101_1u_sample"}, {"comparator": "<", "threshold_g": 1331, "source_id": "cubesat_101_1u_sample"}, {"comparator": "<", "threshold_g": 1330, "source_id": "wrong_source"}]:
		changed = catalogs.duplicate(true)
		changed["launch_profiles"][0]["mass_rule"] = replacement
		_expect_catalog_error(changed, "Source-backed rule cannot be silently weakened or miscredited")
	changed = catalogs.duplicate(true)
	changed["launch_profiles"][1]["mass_rule"].erase("assumption_id")
	_expect_catalog_error(changed, "Alternative profile assumption label required")
	changed = catalogs.duplicate(true)
	changed["launchers"][0]["supported_profile_ids"] = ["missing_profile"]
	_expect_catalog_error(changed, "Broken launcher/profile link")
	changed = catalogs.duplicate(true)
	changed["launchers"][0]["max_payload_g_by_orbit"].erase("high_inc")
	_expect_catalog_error(changed, "Missing supported-orbit payload limit")
	changed = catalogs.duplicate(true)
	changed["launchers"][0]["max_payload_g_by_orbit"]["polar"] = 1000
	_expect_catalog_error(changed, "Unregistered payload-limit orbit")
	changed = catalogs.duplicate(true)
	changed["orbit_ids"] = ["low_eq", "low_eq"]
	_expect_catalog_error(changed, "Duplicate/missing agreed orbit vocabulary")
	changed = catalogs.duplicate(true)
	changed["target_region_ids"] = ["equator", "polar"]
	_expect_catalog_error(changed, "Unagreed target vocabulary")


func _test_repeatability() -> void:
	var before_config: String = JSON.stringify(config)
	var before_catalogs: String = JSON.stringify(catalogs)
	var first: Dictionary = Validator.validate(config, catalogs)
	var second: Dictionary = Validator.validate(config, catalogs)
	_check(JSON.stringify(first) == JSON.stringify(second), "Identical input gives identical output")
	_check(JSON.stringify(config) == before_config, "Validator preserves config")
	_check(JSON.stringify(catalogs) == before_catalogs, "Validator preserves shared catalogs")
	var changed: Dictionary = config.duplicate(true)
	changed["mission"]["required_observations"] = 0
	changed["design"].erase("radio_id")
	var result: Dictionary = Validator.validate(changed, catalogs)
	_check(result["errors"].size() >= 2, "Independent input problems are reported together")
	for issue in result["errors"]:
		_check(issue.has("code") and issue.has("field_path") and issue.has("message") and issue.has("suggested_fix"), "Issues have the agreed UI fields")


func _part(bundle: Dictionary, id_value: String) -> Dictionary:
	for entry in bundle["components"]:
		if entry["id"] == id_value:
			return entry
	return {}


func _expect_catalog_error(value: Variant, label: String) -> void:
	var result: Dictionary = Validator.validate(config, value)
	_check(not result["errors"].is_empty() and not result["ready_to_launch"] and result["checks"]["catalog_references"]["status"] == "fail", label)
	for issue in result["errors"]:
		_check(issue.has("code") and issue.has("field_path") and issue.has("message") and issue.has("suggested_fix"), "Catalog issues have agreed fields")


func _expect_issue(result: Dictionary, code: String, path: String, label: String) -> void:
	var found: bool = false
	for issue in result["errors"]:
		if issue["code"] == code and issue["field_path"] == path:
			found = true
	_check(found and not result["ready_to_launch"], label + " (" + code + ": " + path + ")")


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)
