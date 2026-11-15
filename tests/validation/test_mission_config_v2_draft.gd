extends SceneTree
const Draft = preload("res://scripts/core/mission_config_v2_draft_checker.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const V1 = preload("res://scripts/core/mission_validator.gd")
const Steps = preload("res://core/MissionStepEngine.gd")
const Presets = preload("res://scripts/core/mission_preset_catalog.gd")
const UI = preload("res://data/mock/DesignCatalog.gd")
const EXAMPLES = "res://docs/ke1-expansion/examples/k20-review"
var passed: int = 0
var failed: int = 0
var records: Dictionary = {"checker_revision":"k22-v2-review-1", "base_main":"dce75db", "examples":{}, "production_launch_enabled":false}
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1; printerr("FAIL: " + label)
func read_json(path: String) -> Variant: return JSON.parse_string(FileAccess.get_file_as_string(path))
func has_issue(result: Dictionary, code: String, path: String) -> bool:
	for issue in result.errors:
		if issue.code == code and issue.field_path == path: return true
	return false
func run() -> void:
	var loaded: Dictionary = Runtime.load_game_catalogs()
	check(loaded.ok, "Effective catalogs load")
	var registry: Dictionary = read_json("res://data/mission_presets.json")
	var proposal: Dictionary = read_json(EXAMPLES.path_join("parts.proposed.json"))
	var cases: Dictionary = read_json(EXAMPLES.path_join("manifest.json"))
	if not loaded.ok: quit(1); return
	var catalogs: Dictionary = loaded.catalogs
	for item in cases.cases:
		var config: Dictionary = read_json(EXAMPLES.path_join(item.file))
		var capability: Dictionary = proposal.duplicate(true)
		if item.has("context"): capability.proposed_instrument_objectives[config.design.instrument_id].erase(item.context.remove_objective_from_instrument)
		var before: String = JSON.stringify([config, catalogs, registry, capability])
		var review: Dictionary = Draft.check(config, catalogs, registry, capability)
		check(not review.ready_to_launch and review.draft_only and not review.launch_blockers.is_empty(), item.id + ": draft always blocks launch")
		check(review.review_valid == item.proposed_issues.is_empty(), item.id + ": matches proposed review expectation")
		for expected in item.proposed_issues:
			check(has_issue(review, expected.code, expected.field_path), item.id + ": expected code/path")
		check(before == JSON.stringify([config, catalogs, registry, capability]), item.id + ": all inputs unchanged")
		check(review == Draft.check(config, catalogs, registry, capability), item.id + ": repeatable result")
		check(review.checks.size() == 8, item.id + ": retains eight readiness gates")
		if item.proposed_issues.is_empty():
			check(review.config_valid and review.physical_setup_ready and review.errors.is_empty(), item.id + ": valid draft and physical setup remain separate from launch")
			check(not V1.validate(config, catalogs).ready_to_launch, item.id + ": current production v2 rejection preserved")
			var native: Dictionary = Steps.init_validated_run(config, catalogs, "k22_rejected_" + item.id, "k22_test")
			check(not native.ok and not native.has("state"), item.id + ": native validated launch refuses v2")
		records.examples[item.id] = review
	var communication: Dictionary = read_json(EXAMPLES.path_join("candidate-valid/communication.json"))
	var weather: Dictionary = read_json(EXAMPLES.path_join("candidate-valid/weather_monitoring.json"))
	robustness_cases(communication, catalogs, registry, proposal)
	context_cases(communication, catalogs, registry, proposal)
	boundary_cases(communication, catalogs, registry, proposal)
	legacy_cases(catalogs, registry, proposal, communication, weather)
	records.passed = passed; records.failed = failed
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		DirAccess.make_dir_recursive_absolute(args[0])
		var file = FileAccess.open(args[0].path_join("v2-draft-check.json"), FileAccess.WRITE)
		if file == null: check(false, "Evidence file writable")
		else: file.store_string(JSON.stringify(records, "  ")); file.close()
	print("K22 draft v2 checker: %d checks passed; %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)
func robustness_cases(config: Dictionary, catalogs: Dictionary, registry: Dictionary, proposal: Dictionary) -> void:
	for value in [null, true, false, 2, 2.0, "config", [], Vector2(1,2)]:
		var reply: Dictionary = Draft.check(value, catalogs, registry, proposal)
		check(not reply.review_valid and not reply.ready_to_launch and has_issue(reply, "INVALID_SCHEMA", ""), "Non-object config fails safely")
	var mutations: Array = []
	for field in Draft.ROOT_FIELDS:
		var bad: Dictionary = config.duplicate(true); bad.erase(field); mutations.append(bad)
	for section in ["mission", "design"]:
		for value in [null, false, [], "object", 3]:
			var bad: Dictionary = config.duplicate(true); bad[section] = value; mutations.append(bad)
	for field in ["schema_version", "preset_revision"]:
		for value in [true, false, null, "2", 1.5, NAN, INF, -INF, 9007199254740992.0]:
			var bad: Dictionary = config.duplicate(true); bad[field] = value; mutations.append(bad)
	for field in ["required_observations", "duration_orbits", "budget_credits", "required_returned_data_mb"]:
		for value in [true, false, null, "2", NAN, INF, -INF]:
			var bad: Dictionary = config.duplicate(true); bad.mission[field] = value; mutations.append(bad)
	for value in [true, null, "2", 1.5, 0, -1, NAN, INF, -INF]:
		var bad: Dictionary = config.duplicate(true); bad.mission.goal.required_positive_contact_steps = value; mutations.append(bad)
	for field in ["title", "objective", "target_region"]:
		for value in [true, [], {}, null, 2]:
			var bad: Dictionary = config.duplicate(true); bad.mission[field] = value; mutations.append(bad)
	for value in [true, null, {}, [], [true], ["equator", true]]:
		var bad: Dictionary = config.duplicate(true); bad.mission.target_regions = value; mutations.append(bad)
	for value in [true, null, [], "kind"]:
		var bad: Dictionary = config.duplicate(true); bad.mission.goal = value; mutations.append(bad)
	for value in [true, null, [], {}]:
		var bad: Dictionary = config.duplicate(true); bad.mission.goal.kind = value; mutations.append(bad)
	var extra: Dictionary = config.duplicate(true); extra.mission.extra = 1; mutations.append(extra)
	extra = config.duplicate(true); extra.design.extra = 1; mutations.append(extra)
	extra = config.duplicate(true); extra.mission.title = "x".repeat(81); mutations.append(extra)
	for index in mutations.size():
		var reply: Dictionary = Draft.check(mutations[index], catalogs, registry, proposal)
		check(not reply.review_valid and not reply.ready_to_launch and not reply.errors.is_empty() and reply.metrics == null, "Malformed/numeric input fails before arithmetic: " + str(index))
	var whole: Dictionary = config.duplicate(true)
	whole.schema_version = 2.0; whole.preset_revision = 2.0
	whole.mission.required_observations = 2.0; whole.mission.duration_orbits = 3.0; whole.mission.budget_credits = 100.0; whole.mission.goal.required_positive_contact_steps = 2.0
	check(Draft.check(whole, catalogs, registry, proposal).review_valid, "Whole numeric floats accepted without coercing invalid types")
	var fractional: Dictionary = config.duplicate(true); fractional.mission.required_returned_data_mb = 12.5
	check(Draft.check(fractional, catalogs, registry, proposal).review_valid, "Positive finite decimal MB accepted")
	var no_array: Dictionary = config.duplicate(true); no_array.mission.erase("target_regions")
	check(Draft.check(no_array, catalogs, registry, proposal).review_valid, "Omitted target array uses the primary target")
	var safe_budget: Dictionary = config.duplicate(true); safe_budget.mission.budget_credits = 9007199254740991
	check(Draft.check(safe_budget, catalogs, registry, proposal).review_valid, "Maximum safe integer budget accepted")
	var copy: Dictionary = Draft.check(config, catalogs, registry, proposal)
	copy.metrics.total_mass_g = -1; copy.checks.input_schema.status = "changed"; copy.launch_blockers.clear()
	var fresh: Dictionary = Draft.check(config, catalogs, registry, proposal)
	check(fresh.metrics.total_mass_g == 1120 and fresh.checks.input_schema.status == "pass" and not fresh.launch_blockers.is_empty(), "Returned review data cannot mutate future calls")
func context_cases(config: Dictionary, catalogs: Dictionary, registry: Dictionary, proposal: Dictionary) -> void:
	for value in [null, false, [], {}, "catalogs"]:
		check(not Draft.check(config, value, registry, proposal).review_valid, "Malformed catalog context rejected")
	for value in [null, false, [], {}, "registry"]:
		check(not Draft.check(config, catalogs, value, proposal).review_valid, "Malformed registry context rejected")
	var invalid_registries: Array = []
	for value in [true, null, 0, "2", NAN]:
		var bad: Dictionary = registry.duplicate(true); bad.presets[3].revision = value; invalid_registries.append(bad)
	var bad: Dictionary = registry.duplicate(true); bad.presets[3].candidate_config_v2.preset_revision = false; invalid_registries.append(bad)
	bad = registry.duplicate(true); bad.presets[3].candidate_config_v2.mission.objective = true; invalid_registries.append(bad)
	bad = registry.duplicate(true); bad.presets[3].id = []; invalid_registries.append(bad)
	bad = registry.duplicate(true); bad.presets[3] = null; invalid_registries.append(bad)
	bad = registry.duplicate(true); bad.contract_status = "agreed"; invalid_registries.append(bad)
	for value in invalid_registries:
		var result: Dictionary = Draft.check(config, catalogs, value, proposal)
		check(not result.review_valid and not result.ready_to_launch and result.metrics == null, "Malformed/spoofed registry rejected safely")
	for value in [null, false, [], {}, "capabilities"]:
		check(not Draft.check(config, catalogs, registry, value).review_valid, "No implicit instrument capability context")
	var capabilities: Array = []
	bad = proposal.duplicate(true); bad.new_objectives_currently_enabled = true; capabilities.append(bad)
	bad = proposal.duplicate(true); bad.proposed_instrument_objectives.instrument_basic = true; capabilities.append(bad)
	bad = proposal.duplicate(true); bad.proposed_instrument_objectives.bus_basic = ["communication"]; capabilities.append(bad)
	bad = proposal.duplicate(true); bad.proposed_instrument_objectives.instrument_basic = [false]; capabilities.append(bad)
	bad = proposal.duplicate(true); bad.proposed_instrument_objectives.instrument_basic = ["communication", "communication"]; capabilities.append(bad)
	for value in capabilities:
		check(not Draft.check(config, catalogs, registry, value).review_valid, "Malformed/spoofed capability metadata rejected")
	var timing: Dictionary = catalogs.duplicate(true)
	for orbit in timing.orbit_catalog.orbits:
		if orbit.id == "high_inc": orbit.steps_per_orbit = 5
	var over_bound: Dictionary = config.duplicate(true); over_bound.mission.goal.required_positive_contact_steps = 16
	check(has_issue(Draft.check(over_bound, timing, registry, proposal), "INVALID_VALUE", "mission.goal.required_positive_contact_steps"), "Contact bound derives from actual timing, not fixed ten steps")
	for value in [true, null, 0, 1.5, INF, 9007199254740991]:
		timing = catalogs.duplicate(true)
		for orbit in timing.orbit_catalog.orbits:
			if orbit.id == "high_inc": orbit.steps_per_orbit = value
		check(has_issue(Draft.check(config, timing, registry, proposal), "INVALID_SCHEMA", "catalogs.orbit_catalog.orbits.steps_per_orbit"), "Invalid/overflowing timing fails before multiplication")
func legacy_cases(catalogs: Dictionary, registry: Dictionary, proposal: Dictionary, communication: Dictionary, weather: Dictionary) -> void:
	for preset in registry.presets:
		if preset.legacy_config_v1 == null: continue
		var config: Dictionary = preset.legacy_config_v1.duplicate(true)
		var before: Dictionary = V1.validate(config, catalogs)
		check(before.ready_to_launch, "Original v1 preset still ready: " + preset.id)
		check(not Draft.check(config, catalogs, registry, proposal).ready_to_launch, "Separate v2 checker never acts as v1 launch authority")
		check(V1.validate(config, catalogs) == before, "Legacy result unchanged after draft call: " + preset.id)
		var no_targets: Dictionary = config.duplicate(true); no_targets.mission.erase("target_regions")
		check(V1.validate(no_targets, catalogs).ready_to_launch, "Legacy omitted target_regions remains supported: " + preset.id)
	for config in [communication, weather]:
		var id: String = config.preset_id
		check(not Presets.existing_v1_config(registry, id).ok, "Registry still refuses new-goal legacy fallback: " + id)
		var legacy: Dictionary = config.duplicate(true)
		for field in ["contract_revision", "preset_id", "preset_revision"]: legacy.erase(field)
		legacy.schema_version = 1; legacy.mission.erase("goal")
		check(not V1.validate(legacy, catalogs).ready_to_launch, "Stripping v2 fields cannot register new objective: " + id)
		check(not Steps.init_validated_run(legacy, catalogs, "blocked_" + id, "test").ok, "Native v1 new-objective launch remains blocked: " + id)
		var draft: Dictionary = UI.DEFAULTS.duplicate(true); draft.objective = config.mission.title
		check(not Runtime.review(draft).ready_to_launch and not Runtime.launch(draft).ok, "Existing UI mapping cannot launch new objective: " + id)

func boundary_cases(config: Dictionary, catalogs: Dictionary, registry: Dictionary, proposal: Dictionary) -> void:
	for field in V1.MISSION_FIELDS + ["goal"]:
		var missing: Dictionary = config.duplicate(true); missing.mission.erase(field)
		check(has_issue(Draft.check(missing, catalogs, registry, proposal), "INVALID_SCHEMA", "mission." + field), "Required mission field: " + field)
	for field in V1.DESIGN_FIELDS:
		var missing: Dictionary = config.duplicate(true); missing.design.erase(field)
		check(has_issue(Draft.check(missing, catalogs, registry, proposal), "MISSING_COMPONENT", "design." + field), "Required design slot: " + field)
		missing = config.duplicate(true); missing.design[field] = true
		check(has_issue(Draft.check(missing, catalogs, registry, proposal), "INVALID_VALUE", "design." + field), "Boolean ID rejected: " + field)
	for item in [["launch_profile_id","UNKNOWN_PROFILE"],["launcher_id","UNKNOWN_LAUNCHER"],["orbit_id","UNKNOWN_ORBIT"]]:
		var unknown: Dictionary = config.duplicate(true); unknown.design[item[0]] = "unknown"
		check(has_issue(Draft.check(unknown, catalogs, registry, proposal), item[1], "design." + item[0]), "Unknown catalog ID has the specific code")
	for observations in [1,20]:
		var edge: Dictionary = config.duplicate(true); edge.mission.required_observations = observations
		check(Draft.check(edge, catalogs, registry, proposal).review_valid, "Capture bounds are independent of contact counts")
	for duration in [1,12]:
		var edge: Dictionary = config.duplicate(true); edge.mission.duration_orbits = duration
		check(Draft.check(edge, catalogs, registry, proposal).review_valid, "Duration endpoint accepted for draft readiness, not outcome feasibility")
	var equality: Dictionary = config.duplicate(true); equality.mission.budget_credits = 89
	check(Draft.check(equality, catalogs, registry, proposal).review_valid, "Budget equality accepted")
	for mass in [1329,1330,1331]:
		var changed: Dictionary = catalogs.duplicate(true)
		for part in changed.components:
			if part.id == "bus_basic": part.mass_g += mass - 1120
		var review: Dictionary = Draft.check(config, changed, registry, proposal)
		check(review.config_valid and review.metrics.total_mass_g == mass and review.review_valid == (mass < 1330) and not review.ready_to_launch, "Delegated strict mass boundary retained: " + str(mass))
	var survey: Dictionary = read_json(EXAMPLES.path_join("candidate-valid/polar_ice_survey.json"))
	var changed: Dictionary = catalogs.duplicate(true)
	for part in changed.components:
		if part.id == "instrument_basic": part.supported_objectives = ["imaging"]
	check(has_issue(Draft.check(survey, changed, registry, proposal), "INSTRUMENT_OBJECTIVE_UNSUPPORTED", "design.instrument_id"), "Draft proposal cannot override actual legacy instrument capability")
