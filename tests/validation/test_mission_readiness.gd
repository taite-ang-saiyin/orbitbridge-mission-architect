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
	_check(loaded["ok"], "Real catalogs including HPC orbit file load")
	if not loaded["ok"]:
		print(JSON.stringify(loaded["errors"]))
		quit(1)
		return
	catalogs = loaded["catalogs"]
	var file: FileAccess = FileAccess.open("res://tests/fixtures/ke1_config.json", FileAccess.READ)
	config = JSON.parse_string(file.get_as_text())
	file.close()
	_test_totals()
	_test_mass_and_profiles()
	_test_budget_and_launcher()
	_test_power()
	_test_orbit_data()
	_test_bad_totals_and_inputs()
	_test_combined_failures()
	_test_preservation()
	print("KE1 K07/K08: %d checks passed; %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _test_totals() -> void:
	var result: Dictionary = _run(config, catalogs)
	_check(result["ready_to_launch"], "Base design is launch-ready")
	var expected: Dictionary = {"total_mass_g": 1060, "total_cost_credits": 82, "baseline_power_w": 2, "solar_generation_power_w": 3, "battery_capacity_wh": 25, "initial_energy_wh": 25, "storage_capacity_mb": 64, "data_per_observation_mb": 12, "downlink_mb_per_hour": 48}
	_check(result["metrics"].size() == expected.size(), "Only the agreed metric fields are returned")
	for key in expected:
		_check(is_equal_approx(float(result["metrics"][key]), float(expected[key])), "Base metric matches its independently specified value: " + key)
	_check(typeof(result["metrics"]["total_mass_g"]) == TYPE_INT and typeof(result["metrics"]["total_cost_credits"]) == TYPE_INT, "Mass and cost totals remain whole integers")
	for change in [
		["bus_id", "bus_light", 980, 90, "baseline_power_w", 1.2],
		["instrument_id", "instrument_advanced", 1380, 96, "data_per_observation_mb", 24],
		["solar_id", "solar_large", 1180, 89, "solar_generation_power_w", 6],
		["battery_id", "battery_large", 1260, 92, "battery_capacity_wh", 50],
		["radio_id", "radio_fast", 1120, 89, "downlink_mb_per_hour", 120],
		["storage_id", "storage_large", 1110, 87, "storage_capacity_mb", 256]
	]:
		var changed: Dictionary = config.duplicate(true)
		changed["design"][change[0]] = change[1]
		var actual: Dictionary = _run(changed, catalogs)["metrics"]
		_check(actual["total_mass_g"] == change[2] and actual["total_cost_credits"] == change[3], "Part swap counted exactly once: " + change[1])
		_check(actual[change[4]] == change[5], "Subsystem metric updated: " + change[1])
	var changed_catalogs: Dictionary = catalogs.duplicate(true)
	_part(changed_catalogs, "battery_standard")["initial_charge_fraction"] = 0.5
	_check(_run(config, changed_catalogs)["metrics"]["initial_energy_wh"] == 12.5, "Initial energy uses the selected battery fraction")
	var changed: Dictionary = config.duplicate(true)
	changed["design"]["launcher_id"] = "medium"
	changed["mission"]["budget_credits"] = 200
	changed_catalogs = catalogs.duplicate(true)
	changed_catalogs["launchers"][1]["mass_g"] = 999999
	var medium: Dictionary = _run(changed, changed_catalogs)
	_check(medium["metrics"]["total_mass_g"] == 1060 and medium["metrics"]["total_cost_credits"] == 102, "Launcher cost included; launcher mass excluded")


func _test_mass_and_profiles() -> void:
	for pair in [[1329, true], [1330, false], [1331, false]]:
		var changed: Dictionary = catalogs.duplicate(true)
		_part(changed, "bus_basic")["mass_g"] = pair[0] - 760
		var result: Dictionary = _run(config, changed)
		_check(result["checks"]["profile_mass"]["passed"] == pair[1], "Strict sample mass boundary %d g" % pair[0])
		_check(result["ready_to_launch"] == pair[1], "Mass boundary drives overall launch readiness")
		if not pair[1]:
			_check(_has_issue(result, "PROFILE_MASS_EXCEEDED"), "Mass failure has an actionable issue")
			_check(result["errors"][0].get("source_id") == "cubesat_101_1u_sample", "Source-backed failure is credited")
	var changed_config: Dictionary = config.duplicate(true)
	changed_config["design"]["instrument_id"] = "instrument_advanced"
	var heavy: Dictionary = _run(changed_config, catalogs)
	_check(not heavy["ready_to_launch"] and heavy["metrics"]["total_mass_g"] == 1380, "Advanced camera exceeds sample mass limit")
	changed_config["design"]["launch_profile_id"] = "illustrative_alternative"
	changed_config["design"]["launcher_id"] = "medium"
	changed_config["mission"]["budget_credits"] = 200
	var alternative: Dictionary = _run(changed_config, catalogs)
	_check(alternative["ready_to_launch"], "Same heavy design can use its compatible alternative profile/launcher")
	_check(alternative["checks"]["profile_mass"]["threshold_g"] == 5000 and alternative["checks"]["profile_mass"]["source_id"] == null, "Alternative uses its own illustrative threshold and no fake NASA source")
	for pair in [[5000, true], [5001, false]]:
		var changed: Dictionary = catalogs.duplicate(true)
		_part(changed, "bus_basic")["mass_g"] = pair[0] - 1080
		var result: Dictionary = _run(changed_config, changed)
		_check(result["checks"]["profile_mass"]["passed"] == pair[1], "Alternative <= rule at %d g" % pair[0])


func _test_budget_and_launcher() -> void:
	for pair in [[82, true], [81, false]]:
		var changed: Dictionary = config.duplicate(true)
		changed["mission"]["budget_credits"] = pair[0]
		var result: Dictionary = _run(changed, catalogs)
		_check(result["checks"]["budget"]["passed"] == pair[1] and result["ready_to_launch"] == pair[1], "Budget equality/excess boundary")
		if not pair[1]:
			_check(_has_issue(result, "BUDGET_EXCEEDED") and result["checks"]["profile_mass"]["passed"], "Passing mass does not bypass failed budget")
	for pair in [[1060, true], [1059, false]]:
		var changed: Dictionary = catalogs.duplicate(true)
		changed["launchers"][0]["max_payload_g_by_orbit"]["high_inc"] = pair[0]
		var result: Dictionary = _run(config, changed)
		_check(result["checks"]["launcher_capacity"]["passed"] == pair[1], "Launcher capacity uses selected orbit and allows equality")
		if not pair[1]:
			_check(_has_issue(result, "LAUNCHER_CAPACITY_EXCEEDED"), "Launcher capacity failure is explicit")
	var changed_config: Dictionary = config.duplicate(true)
	changed_config["design"]["launch_profile_id"] = "illustrative_alternative"
	_check(_has_issue(_run(changed_config, catalogs), "LAUNCH_ORBIT_INCOMPATIBLE"), "Launcher/profile mismatch is rejected")
	var changed: Dictionary = catalogs.duplicate(true)
	changed["launch_profiles"][0]["supported_orbit_ids"] = ["low_eq"]
	_check(_has_issue(_run(config, changed), "LAUNCH_ORBIT_INCOMPATIBLE"), "Profile/orbit mismatch is rejected")
	changed = catalogs.duplicate(true)
	changed["launchers"][0]["supported_orbit_ids"] = ["low_eq"]
	changed["launchers"][0]["max_payload_g_by_orbit"].erase("high_inc")
	var result: Dictionary = _run(config, changed)
	_check(_has_issue(result, "LAUNCH_ORBIT_INCOMPATIBLE"), "Launcher/orbit mismatch is rejected")
	_check(result["checks"]["launcher_capacity"]["status"] == "not_evaluated", "Unsupported orbit never borrows another orbit's capacity")


func _test_power() -> void:
	for pair in [[3, true], [2, true], [1.9, false], [0, false]]:
		var changed: Dictionary = catalogs.duplicate(true)
		_part(changed, "solar_standard")["generation_power_w"] = pair[0]
		var result: Dictionary = _run(config, changed)
		_check(result["checks"]["essential_power"]["passed"] == pair[1], "Sunlit solar/baseline rule with equality")
		if not pair[1]:
			_check(_has_issue(result, "ESSENTIAL_POWER_INFEASIBLE"), "Power failure returns a correction")
	var changed: Dictionary = catalogs.duplicate(true)
	_part(changed, "battery_standard")["initial_charge_fraction"] = 0
	var result: Dictionary = _run(config, changed)
	_check(result["metrics"]["initial_energy_wh"] == 0 and _has_issue(result, "ESSENTIAL_POWER_INFEASIBLE"), "Zero initial charge prevents launch without corrupting metrics")


func _test_orbit_data() -> void:
	for orbit_id in ["low_eq", "high_inc"]:
		var changed: Dictionary = config.duplicate(true)
		changed["design"]["orbit_id"] = orbit_id
		_check(_run(changed, catalogs)["checks"]["target_orbit"]["passed"], "Published HPC target windows support equator in " + orbit_id)
	var changed: Dictionary = catalogs.duplicate(true)
	_orbit(changed, "high_inc")["target_windows"]["equator"] = []
	var result: Dictionary = _run(config, changed)
	_check(_has_issue(result, "TARGET_ORBIT_INCOMPATIBLE") and result["metrics"] != null, "No target windows fails suitability but keeps computed metrics")
	changed = catalogs.duplicate(true)
	changed.erase("orbit_catalog")
	result = _run(config, changed)
	_check(not result["ready_to_launch"] and result["checks"]["target_orbit"]["passed"] == null and _has_issue(result, "INVALID_SCHEMA"), "Missing actual orbit data never silently passes")
	_check(result["metrics"]["total_mass_g"] == 1060, "Missing orbit metadata does not fabricate or erase valid totals")
	for value in [null, [], "orbits"]:
		changed = catalogs.duplicate(true)
		changed["orbit_catalog"] = value
		_expect_bad_orbit(changed, "Wrong orbit file root")
	changed = catalogs.duplicate(true)
	changed["orbit_catalog"]["orbits"] = [changed["orbit_catalog"]["orbits"][0]]
	_expect_bad_orbit(changed, "Missing selected preset")
	changed = catalogs.duplicate(true)
	changed["orbit_catalog"]["orbits"].append(changed["orbit_catalog"]["orbits"][1].duplicate(true))
	_expect_bad_orbit(changed, "Duplicate preset ID")
	for field in ["step_duration_hours", "steps_per_orbit", "target_windows"]:
		changed = catalogs.duplicate(true)
		_orbit(changed, "high_inc").erase(field)
		_expect_bad_orbit(changed, "Missing selected preset field: " + field)
	for value in [0, -1, NAN, INF, true, "0.1"]:
		changed = catalogs.duplicate(true)
		_orbit(changed, "high_inc")["step_duration_hours"] = value
		_expect_bad_orbit(changed, "Invalid scenario time")
	for value in [[-1], [10], [1.5], [NAN], [true], "1"]:
		changed = catalogs.duplicate(true)
		_orbit(changed, "high_inc")["target_windows"]["equator"] = value
		_expect_bad_orbit(changed, "Invalid target-window indices")
	changed = catalogs.duplicate(true)
	changed["orbit_catalog"]["unit_conventions"]["data_unit"] = "binary_mb"
	_expect_bad_orbit(changed, "Silent unit mismatch is rejected")


func _test_bad_totals_and_inputs() -> void:
	var changed: Dictionary = catalogs.duplicate(true)
	_part(changed, "bus_basic")["mass_g"] = Support.MAX_SAFE_INTEGER
	var result: Dictionary = _run(config, changed)
	_check(result["metrics"] == null and _has_issue(result, "INVALID_VALUE") and not result["ready_to_launch"], "Unsafe aggregate mass is rejected before overflow")
	changed = catalogs.duplicate(true)
	_part(changed, "bus_basic")["cost_credits"] = Support.MAX_SAFE_INTEGER
	result = _run(config, changed)
	_check(result["metrics"] == null and _has_issue(result, "INVALID_VALUE"), "Unsafe aggregate cost is rejected before overflow")
	var bad_config: Dictionary = config.duplicate(true)
	bad_config["design"]["radio_id"] = "missing"
	result = _run(bad_config, catalogs)
	_check(result["metrics"] == null and result["checks"]["profile_mass"]["status"] == "not_evaluated", "Missing parts do not become zero-valued totals")


func _test_combined_failures() -> void:
	var changed_config: Dictionary = config.duplicate(true)
	changed_config["design"]["instrument_id"] = "instrument_advanced"
	changed_config["mission"]["budget_credits"] = 1
	var changed: Dictionary = catalogs.duplicate(true)
	changed["launchers"][0]["max_payload_g_by_orbit"]["high_inc"] = 1000
	changed["launch_profiles"][0]["supported_orbit_ids"] = ["low_eq"]
	_orbit(changed, "high_inc")["target_windows"]["equator"] = []
	_part(changed, "solar_standard")["generation_power_w"] = 0
	var result: Dictionary = _run(changed_config, changed)
	var codes: Array = []
	for issue in result["errors"]:
		codes.append(issue["code"])
	_check(codes == ["PROFILE_MASS_EXCEEDED", "LAUNCHER_CAPACITY_EXCEEDED", "BUDGET_EXCEEDED", "LAUNCH_ORBIT_INCOMPATIBLE", "TARGET_ORBIT_INCOMPATIBLE", "ESSENTIAL_POWER_INFEASIBLE"], "All independent failures are returned in stable check order")
	_check(result["metrics"] != null, "Failed design checks keep valid metrics for the UI")


func _test_preservation() -> void:
	var config_before: String = JSON.stringify(config)
	var catalogs_before: String = JSON.stringify(catalogs)
	var first: Dictionary = _run(config, catalogs)
	var second: Dictionary = _run(config, catalogs)
	_check(JSON.stringify(first) == JSON.stringify(second), "Readiness is deterministic")
	_check(config_before == JSON.stringify(config), "Readiness preserves mission config")
	_check(catalogs_before == JSON.stringify(catalogs), "Readiness preserves catalogs and original HPC metadata")
	first["checks"]["profile_mass"]["source_id"] = "changed"
	_check(catalogs_before == JSON.stringify(catalogs), "Returned source record cannot mutate shared catalog rules")


func _run(chosen_config: Variant, chosen_catalogs: Variant) -> Dictionary:
	var result: Dictionary = Validator.validate(chosen_config, chosen_catalogs)
	var all_pass: bool = result["metrics"] != null and result["errors"].is_empty()
	for key in Validator.CHECK_IDS:
		var check: Dictionary = result["checks"][key]
		_check(check["passed"] == {"pass": true, "fail": false, "not_evaluated": null}[check["status"]], "Check status and Boolean/null agree")
		all_pass = all_pass and check["status"] == "pass"
	_check(result["ready_to_launch"] == all_pass, "Overall readiness is derived from every required check")
	for issue in result["errors"]:
		_check(issue.has("code") and issue.has("field_path") and issue.has("message") and issue.has("suggested_fix"), "Readiness issues have agreed actionable fields")
	return result


func _part(bundle: Dictionary, id_value: String) -> Dictionary:
	for entry in bundle["components"]:
		if entry["id"] == id_value:
			return entry
	return {}


func _orbit(bundle: Dictionary, id_value: String) -> Dictionary:
	for entry in bundle["orbit_catalog"]["orbits"]:
		if entry["id"] == id_value:
			return entry
	return {}


func _has_issue(result: Dictionary, code: String) -> bool:
	for issue in result["errors"]:
		if issue["code"] == code:
			return true
	return false


func _expect_bad_orbit(bundle: Dictionary, label: String) -> void:
	var result: Dictionary = _run(config, bundle)
	_check(not result["ready_to_launch"] and result["checks"]["target_orbit"]["status"] == "not_evaluated" and _has_issue(result, "INVALID_SCHEMA"), label)


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)
