extends SceneTree
const Candidate = preload("res://scripts/core/mission_validator_v2_candidate.gd")
const V1 = preload("res://scripts/core/mission_validator.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Native = preload("res://core/MissionStepEngine.gd")
const Rules = preload("res://scripts/core/mission_config_v2_rules.gd")
const ROOT = "res://docs/ke1-expansion/examples/k20-review"
var passed: int = 0
var failed: int = 0
var evidence: Dictionary = {"candidate_revision":Candidate.REVISION,"cases":{},"live_v2_launch_enabled":false,"pending_confirmation_owners":["HPC"]}
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1; printerr("FAIL: " + label)
func read_json(path: String) -> Variant: return JSON.parse_string(FileAccess.get_file_as_string(path))
func has_issue(reply: Dictionary, code: String, path: String) -> bool:
	for issue in reply.errors:
		if issue.code == code and issue.field_path == path: return true
	return false
func blocked(reply: Dictionary) -> bool:
	return not reply.ready_to_launch and reply.candidate_only and not reply.launch_blockers.is_empty() and reply.pending_confirmation_owners == ["HPC"]
func run() -> void:
	var loaded: Dictionary = Runtime.load_game_catalogs()
	check(loaded.ok,"Effective source catalogs load")
	if not loaded.ok: quit(1); return
	var catalogs: Dictionary = loaded.catalogs
	var registry: Dictionary = read_json("res://data/mission_presets.json")
	var capabilities: Dictionary = read_json("res://data/mission_capabilities_v2.draft.json")
	var manifest: Dictionary = read_json(ROOT.path_join("manifest.json"))
	for item in manifest.cases:
		var config: Dictionary = read_json(ROOT.path_join(item.file))
		var context: Dictionary = capabilities.duplicate(true)
		if item.has("context"):
			for instrument in context.instruments:
				if instrument.instrument_id == config.design.instrument_id: instrument.objective_ids.erase(item.context.remove_objective_from_instrument)
		var before: String = JSON.stringify([config,catalogs,registry,context])
		var reply: Dictionary = Candidate.validate(config,catalogs,registry,context)
		check(blocked(reply), item.id + ": v2 never obtains launch permission")
		check(reply.physical_setup_ready == item.proposed_issues.is_empty(),item.id + ": expected physical/field result")
		for expected in item.proposed_issues:
			check(has_issue(reply,expected.code,expected.field_path), item.id + ": expected structured issue")
		check(reply.checks.size()==8,item.id + ": all eight readiness gates retained")
		check(JSON.stringify([config,catalogs,registry,context])==before,item.id + ": all input contexts unchanged")
		check(Candidate.validate(config,catalogs,registry,context)==reply,item.id + ": deterministic output")
		if item.proposed_issues.is_empty():
			check(reply.config_snapshot==config and reply.config_snapshot.schema_version==2 and reply.config_snapshot.mission.goal==config.mission.goal,item.id + ": full v2 goals retained without a surrogate")
			check(not V1.validate(config,catalogs).ready_to_launch,item.id + ": live validator still rejects v2")
			check(not Native.init_validated_run(config,catalogs,"candidate_"+item.id,"candidate_test").ok,item.id + ": native launch still rejects v2")
		evidence.cases[item.id]=reply
	var communication: Dictionary = registry.presets[3].candidate_config_v2.duplicate(true)
	var survey: Dictionary = registry.presets[2].candidate_config_v2.duplicate(true)
	boundary_checks(communication,survey,catalogs,registry,capabilities)
	legacy_checks(catalogs,registry,capabilities)
	context_checks(communication,catalogs,registry,capabilities)
	evidence.passed=passed; evidence.failed=failed
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if not args.is_empty():
		DirAccess.make_dir_recursive_absolute(args[0])
		var file=FileAccess.open(args[0].path_join("v2-candidate-check.json"),FileAccess.WRITE)
		if file==null: check(false,"Evidence is writable")
		else: file.store_string(JSON.stringify(evidence,"  ")); file.close()
	print("K22 v2 candidate validator: %d checks passed; %d failed." % [passed,failed])
	quit(0 if failed==0 else 1)
func boundary_checks(config: Dictionary,survey: Dictionary,catalogs: Dictionary,registry: Dictionary,caps: Dictionary) -> void:
	for mass in [1329,1330,1331]:
		var changed: Dictionary=catalogs.duplicate(true)
		for part in changed.components:
			if part.id=="bus_basic": part.mass_g+=mass-1120
		var reply: Dictionary=Candidate.validate(config,changed,registry,caps)
		check(reply.config_valid and reply.metrics.total_mass_g==mass and reply.physical_setup_ready==(mass<1330) and blocked(reply),"Strict mass boundary: "+str(mass))
		check(reply.checks.profile_mass.source_id=="cubesat_101_1u_sample","Mass source retained")
	for budget in [88,89,90]:
		var changed: Dictionary=config.duplicate(true); changed.mission.budget_credits=budget
		var reply: Dictionary=Candidate.validate(changed,catalogs,registry,caps)
		check(reply.metrics.total_cost_credits==89 and reply.physical_setup_ready==(budget>=89),"Budget equality and excess: "+str(budget))
	var changed: Dictionary=config.duplicate(true)
	changed.design.launcher_id="medium"; changed.design.launch_profile_id="illustrative_alternative"; changed.mission.budget_credits=200
	var reply: Dictionary=Candidate.validate(changed,catalogs,registry,caps)
	check(reply.physical_setup_ready and reply.checks.profile_mass.comparator=="<=" and reply.checks.profile_mass.threshold_g==5000,"Alternate profile uses its own rule")
	changed.design.launcher_id="small"
	check(has_issue(Candidate.validate(changed,catalogs,registry,caps),"LAUNCH_ORBIT_INCOMPATIBLE","design.launcher_id"),"Profile and launcher compatibility retained")
	var dark: Dictionary=catalogs.duplicate(true)
	for part in dark.components:
		if part.id=="solar_standard": part.generation_power_w=1
	check(has_issue(Candidate.validate(config,dark,registry,caps),"ESSENTIAL_POWER_INFEASIBLE","design"),"Passing mass does not bypass power")
	changed=config.duplicate(true); changed.design.orbit_id="low_eq"; changed.mission.target_region="arctic_ice"; changed.mission.target_regions=["arctic_ice"]
	check(has_issue(Candidate.validate(changed,catalogs,registry,caps),"TARGET_ORBIT_INCOMPATIBLE","mission.target_region"),"Target opportunity gate retained")
	changed=config.duplicate(true); changed.mission.required_observations=1
	check(Candidate.validate(changed,catalogs,registry,caps).physical_setup_ready,"Capture quota does not cap Communication transmission steps")
	changed=survey.duplicate(true); changed.mission.goal.minimum_complete_observations_per_target=2
	check(has_issue(Candidate.validate(changed,catalogs,registry,caps),"INVALID_VALUE","mission.goal.minimum_complete_observations_per_target"),"Current agreed Survey revision rejects a minimum above one")
	changed=survey.duplicate(true); changed.mission.title="A player's edited title"; changed.mission.budget_credits=120
	check(Candidate.validate(changed,catalogs,registry,caps).physical_setup_ready,"Compatible edits retain authored lineage")
	changed.mission.objective="imaging"; changed.mission.goal={"kind":"imaging"}
	check(has_issue(Candidate.validate(changed,catalogs,registry,caps),"INVALID_VALUE","mission.objective"),"Objective cannot retain unrelated preset lineage")
	var copy: Dictionary=Candidate.validate(config,catalogs,registry,caps)
	copy.config_snapshot.mission.goal.required_positive_contact_steps=999
	copy.metrics.total_mass_g=-1; copy.checks.input_schema.status="changed"; copy.launch_blockers.clear()
	reply=Candidate.validate(config,catalogs,registry,caps)
	check(reply.config_snapshot==config and reply.metrics.total_mass_g==1120 and blocked(reply),"Output mutations cannot alter input or later results")
func legacy_checks(catalogs: Dictionary,registry: Dictionary,caps: Dictionary) -> void:
	for preset in registry.presets:
		if preset.legacy_config_v1==null: continue
		var config: Dictionary=preset.legacy_config_v1.duplicate(true)
		var before: String=JSON.stringify([config,catalogs,registry,caps])
		check(Candidate.validate(config,catalogs)==V1.validate(config,catalogs),"Supported v1 result is byte-for-field equivalent: "+preset.id)
		check(Candidate.validate(config,catalogs,false,false)==V1.validate(config,catalogs),"V1 does not require or inspect v2 contexts: "+preset.id)
		config.mission.budget_credits=1
		check(Candidate.validate(config,catalogs,registry,caps)==V1.validate(config,catalogs),"Invalid v1 retains original error envelope: "+preset.id)
		config.mission.extra="invalid"
		check(Candidate.validate(config,catalogs)==V1.validate(config,catalogs),"Malformed v1 preserves original shape errors: "+preset.id)
		check(before==JSON.stringify([preset.legacy_config_v1,catalogs,registry,caps]),"Legacy source contexts not mutated: "+preset.id)
func context_checks(config: Dictionary,catalogs: Dictionary,registry: Dictionary,caps: Dictionary) -> void:
	for value in [null,false,[],{},"config"]:
		var reply: Dictionary=Candidate.validate(value,catalogs,registry,caps)
		check(blocked(reply) and not reply.config_valid and reply.metrics==null,"Malformed config cannot reach arithmetic")
	for version in [true,false,null,"2",1.5,3,INF,NAN]:
		var changed: Dictionary=config.duplicate(true); changed.schema_version=version
		check(has_issue(Candidate.validate(changed,catalogs,registry,caps),"INVALID_SCHEMA","schema_version"),"Invalid versions never fall back to v1")
	for field in Rules.ROOT_FIELDS:
		var changed: Dictionary=config.duplicate(true); changed.erase(field)
		check(has_issue(Candidate.validate(changed,catalogs,registry,caps),"INVALID_SCHEMA",field),"Required v2 root field: "+field)
	for section in ["mission","design"]:
		var changed: Dictionary=config.duplicate(true); changed[section].unexpected=1
		check(has_issue(Candidate.validate(changed,catalogs,registry,caps),"INVALID_SCHEMA",section+".unexpected"),"Unknown fields rejected: "+section)
	for value in [null,false,[],{},"capability"]:
		var reply: Dictionary=Candidate.validate(config,catalogs,registry,value)
		check(not reply.config_valid and reply.metrics==null and blocked(reply),"Missing capability declaration fails closed")
	var changed_caps: Dictionary=caps.duplicate(true); changed_caps.production_enabled=true
	check(not Candidate.validate(config,catalogs,registry,changed_caps).config_valid,"Caller cannot approve launch through capability metadata")
	for value in [null,false,[],{},"catalogs"]:
		var reply: Dictionary=Candidate.validate(config,value,registry,caps)
		check(not reply.config_valid and reply.metrics==null and blocked(reply),"Invalid catalogs fail before totals")
	for value in [null,false,[],{},"registry"]:
		check(not Candidate.validate(config,catalogs,value,caps).config_valid,"No implicit registry identity")
	var changed: Dictionary=config.duplicate(true); changed.preset_revision=1
	check(has_issue(Candidate.validate(changed,catalogs,registry,caps),"INVALID_VALUE","preset_revision"),"Communication requires authored revision two")
	var overflow: Dictionary=catalogs.duplicate(true)
	for part in overflow.components:
		if part.id in ["bus_basic","instrument_basic"]: part.mass_g=9007199254740991
	var reply: Dictionary=Candidate.validate(config,overflow,registry,caps)
	check(reply.config_valid and reply.metrics==null and has_issue(reply,"INVALID_VALUE","metrics.total_mass_g") and not reply.physical_setup_ready,"Overflow fails before unsafe totals")
