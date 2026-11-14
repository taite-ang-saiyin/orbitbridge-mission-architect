extends SceneTree

const Validator = preload("res://scripts/core/mission_validator.gd")
const Loader = preload("res://scripts/core/catalog_loader.gd")
const FIXTURES = "res://tests/fixtures/"

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	var loaded: Dictionary = Loader.load_catalogs()
	_check(loaded["ok"], "Real catalogs load")
	var manifest: Variant = _read_json(FIXTURES + "ke1_readiness_cases.json")
	if not loaded["ok"] or not manifest is Dictionary or not manifest.get("cases") is Array:
		_check(false, "Saved case manifest and catalogs must be usable")
		_finish()
		return
	var catalogs: Dictionary = loaded["catalogs"]
	var original_catalogs: String = JSON.stringify(catalogs)
	for case_value in manifest["cases"]:
		_run_case(case_value, catalogs)
	_check(JSON.stringify(catalogs) == original_catalogs, "All cases preserve the shared catalogs")
	_finish()


func _run_case(case_value: Dictionary, catalogs: Dictionary) -> void:
	var label: String = case_value["id"]
	var config: Variant = _read_json(FIXTURES + case_value["config_file"])
	if not config is Dictionary:
		_check(false, label + ": config must be an object")
		return
	var case_catalogs: Dictionary = catalogs.duplicate(true)
	# Boundary masses are test-only overrides on a copy, never game catalog edits.
	if case_value.has("test_only_bus_mass_g"):
		var found: bool = false
		for component in case_catalogs["components"]:
			if component["id"] == "bus_basic":
				component["mass_g"] = case_value["test_only_bus_mass_g"]
				found = true
		_check(found, label + ": boundary bus exists")
	var before_config: String = JSON.stringify(config)
	var before_catalogs: String = JSON.stringify(case_catalogs)
	var result: Dictionary = Validator.validate(config, case_catalogs)
	_expect_subset(result, case_value["expected"], label)
	var codes: Array = []
	for issue in result["errors"]:
		codes.append(issue["code"])
		for key in ["code", "field_path", "message", "suggested_fix"]:
			_check(issue.has(key) and issue[key] is String and not issue[key].is_empty(), label + ": actionable error " + key)
		if issue["code"] == "PROFILE_MASS_EXCEEDED":
			if result["checks"]["profile_mass"]["source_id"] == null:
				_check(not issue.has("source_id"), label + ": illustrative error has no source claim")
			else:
				_check(issue.get("source_id") == "cubesat_101_1u_sample", label + ": source-backed error keeps source ID")
	_expect_subset(codes, case_value["expected_error_codes"], label + ": exact error codes")
	_check(result["checks"]["profile_mass"].has("assumption_id") == case_value["expected_assumption"], label + ": assumption applies only to illustrative rule")
	var all_pass: bool = result["metrics"] != null and result["errors"].is_empty()
	for check_id in Validator.CHECK_IDS:
		var check: Dictionary = result["checks"][check_id]
		_check(check["passed"] == {"pass": true, "fail": false, "not_evaluated": null}[check["status"]], label + ": status matches verdict " + check_id)
		all_pass = all_pass and check["status"] == "pass"
	_check(result["ready_to_launch"] == all_pass, label + ": all checks control launch permission")
	_check(JSON.stringify(result) == JSON.stringify(Validator.validate(config, case_catalogs)), label + ": repeat gives same result")
	_check(before_config == JSON.stringify(config), label + ": config preserved")
	_check(before_catalogs == JSON.stringify(case_catalogs), label + ": case catalogs preserved")
	print("CASE %s: ready=%s; mass=%s; errors=%s" % [label, str(result["ready_to_launch"]), str(result["checks"]["profile_mass"]["total_mass_g"]), str(codes)])


func _expect_subset(actual: Variant, expected: Variant, label: String) -> void:
	if expected is Dictionary:
		if not actual is Dictionary:
			_check(false, label + ": expected an object")
			return
		for key in expected:
			if not actual.has(key):
				_check(false, label + ": missing " + key)
			else:
				_expect_subset(actual[key], expected[key], label + "." + key)
	elif expected is Array:
		if not actual is Array:
			_check(false, label + ": expected an array")
			return
		_check(actual.size() == expected.size(), label + ": array size")
		for index in mini(actual.size(), expected.size()):
			_expect_subset(actual[index], expected[index], label + "[%d]" % index)
	else:
		_check(actual == expected, label + ": expected %s, got %s" % [str(expected), str(actual)])


func _read_json(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_check(false, "Cannot open " + path)
		return null
	var parser := JSON.new()
	var error: Error = parser.parse(file.get_as_text())
	file.close()
	_check(error == OK, "Parse " + path)
	return parser.data if error == OK else null


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)


func _finish() -> void:
	print("KE1 K09/K10 saved fixtures: %d checks passed; %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)
