extends SceneTree
const Validator = preload("res://scripts/core/mission_validator.gd")
const Legacy = preload("res://scripts/core/mission_validator_v1.gd")
const Context = preload("res://scripts/core/mission_v2_context.gd")
const Presets = preload("res://scripts/core/mission_presets_v2.gd")
const Rules = preload("res://scripts/core/mission_config_v2_agreed_rules.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Native = preload("res://core/MissionStepEngine.gd")
const EXAMPLES = "res://docs/ke1-expansion/examples/k20-review"
var passed: int=0
var failed: int=0
var records: Dictionary={"contract_revision":Rules.CONTRACT,"presets":{},"cases":{},"native_v2_launch_supported":true}
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1; printerr("FAIL: "+label)
func read_json(path: String) -> Variant: return JSON.parse_string(FileAccess.get_file_as_string(path))
func issue(reply: Dictionary,code: String,path: String="*") -> bool:
	for item in reply.errors:
		if item.code==code and (path=="*" or item.field_path==path): return true
	return false
func run() -> void:
	var loaded: Dictionary=Runtime.load_game_catalogs()
	var ready: Dictionary=Context.load_context(loaded.catalogs)
	check(loaded.ok and ready.ok,"Explicit agreed v2 context loads")
	if not ready.ok: printerr(ready.errors); quit(1); return
	var catalogs: Dictionary=ready.catalogs
	var registry: Dictionary=catalogs.mission_v2.registry
	for entry in registry.presets:
		var config: Dictionary=Presets.config_for(registry,entry.id).config
		var before: String=JSON.stringify([config,catalogs])
		var result: Dictionary=Validator.validate(config,catalogs)
		check(result.ready_to_launch and result.errors.is_empty(),"Live public validator accepts valid v2 design: "+entry.id)
		check(result.schema_version==1 and result.checks.size()==8,"Validation envelope/gates remain version 1: "+entry.id)
		check(result.metrics.total_mass_g==(1120 if entry.id=="communication" else 1060),"Expected mass: "+entry.id)
		check(result.metrics.total_cost_credits==(89 if entry.id=="communication" else 82),"Expected credits: "+entry.id)
		check(Validator.validate(config,catalogs)==result,"Deterministic result: "+entry.id)
		check(JSON.stringify([config,catalogs])==before,"Full goal/config/catalog inputs unchanged: "+entry.id)
		check(not Validator.validate(config,loaded.catalogs).ready_to_launch,"V2 never infers missing agreed context: "+entry.id)
		var launched: Dictionary=Native.init_validated_run(config,catalogs,"v2_blocked_"+entry.id,"v2_test")
		check(launched.ok and launched.state.config_snapshot == config and launched.state.schema_version == 1 and launched.state.step_index == 0 and launched.state.event_log.is_empty(),"Native v2 launch retains exact config and clean compatible state: "+entry.id)
		records.presets[entry.id]={"validation":result,"native_result":launched}
	var manifest: Dictionary=read_json(EXAMPLES.path_join("manifest.json"))
	for item in manifest.cases:
		var config: Dictionary=read_json(EXAMPLES.path_join(item.file))
		if config.get("contract_revision")=="expansion-goals-v2-draft-2": config.contract_revision=Rules.CONTRACT
		var used: Dictionary=catalogs.duplicate(true)
		if item.has("context"):
			for instrument in used.mission_v2.capabilities.instruments:
				if instrument.instrument_id==config.design.instrument_id: instrument.objective_ids.erase(item.context.remove_objective_from_instrument)
		var before: String=JSON.stringify([config,used])
		var result: Dictionary=Validator.validate(config,used)
		check(result.ready_to_launch==item.proposed_issues.is_empty(),item.id+": agreed rule outcome")
		for expected in item.proposed_issues:
			check(issue(result,expected.code,expected.field_path if not item.has("context") else "*"),item.id+": structured expected error")
		check(result.checks.size()==8,item.id+": all gates present")
		check(JSON.stringify([config,used])==before,item.id+": no input mutation")
		check(Validator.validate(config,used)==result,item.id+": repeatable")
		records.cases[item.id]=result
	var config: Dictionary=Presets.config_for(registry,"communication").config
	boundaries(config,catalogs)
	malformed(config,catalogs)
	legacy_checks(loaded.catalogs,catalogs)
	records.passed=passed; records.failed=failed
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if not args.is_empty():
		DirAccess.make_dir_recursive_absolute(args[0])
		var file=FileAccess.open(args[0].path_join("live-v2-validation-check.json"),FileAccess.WRITE)
		if file!=null: file.store_string(JSON.stringify(records,"  ")); file.close()
	print("K22 live v2 validation: %d checks passed; %d failed." % [passed,failed])
	quit(0 if failed==0 else 1)
func boundaries(config: Dictionary,catalogs: Dictionary) -> void:
	for mass in [1329,1330,1331]:
		var changed: Dictionary=catalogs.duplicate(true)
		for part in changed.components:
			if part.id=="bus_basic": part.mass_g+=mass-1120
		var result: Dictionary=Validator.validate(config,changed)
		check(result.metrics.total_mass_g==mass and result.ready_to_launch==(mass<1330),"Strict profile mass boundary: "+str(mass))
		check(result.checks.profile_mass.source_id=="cubesat_101_1u_sample" and result.checks.profile_mass.threshold_g==1330,"Mass source/profile retained")
	for budget in [88,89,90]:
		var changed: Dictionary=config.duplicate(true); changed.mission.budget_credits=budget
		check(Validator.validate(changed,catalogs).ready_to_launch==(budget>=89),"Budget equality/excess independent of mass")
	var changed: Dictionary=config.duplicate(true)
	changed.design.launcher_id="medium"; changed.design.launch_profile_id="illustrative_alternative"; changed.mission.budget_credits=200
	var result: Dictionary=Validator.validate(changed,catalogs)
	check(result.ready_to_launch and result.checks.profile_mass.comparator=="<=" and result.checks.profile_mass.threshold_g==5000,"Alternate profile uses its own rule")
	changed.design.launcher_id="small"
	check(issue(Validator.validate(changed,catalogs),"LAUNCH_ORBIT_INCOMPATIBLE","design.launcher_id"),"Profile/launcher compatibility enforced")
	var dark: Dictionary=catalogs.duplicate(true)
	for part in dark.components:
		if part.id=="solar_standard": part.generation_power_w=1
	check(issue(Validator.validate(config,dark),"ESSENTIAL_POWER_INFEASIBLE","design"),"Power failure blocks passing mass")
	changed=config.duplicate(true); changed.mission.target_region="arctic_ice"; changed.mission.target_regions=["arctic_ice"]; changed.design.orbit_id="low_eq"
	check(issue(Validator.validate(changed,catalogs),"TARGET_ORBIT_INCOMPATIBLE","mission.target_region"),"Authored target opportunity required")
	changed=config.duplicate(true); changed.mission.required_observations=1
	check(Validator.validate(changed,catalogs).ready_to_launch,"Communication quota does not cap transmission-step count")
	changed=Presets.config_for(catalogs.mission_v2.registry,"weather_monitoring").config
	changed.mission.required_observations=1
	check(issue(Validator.validate(changed,catalogs),"INVALID_VALUE","mission.goal.required_distinct_orbits"),"Weather distinct visits cannot exceed capture supply")
	changed=Presets.config_for(catalogs.mission_v2.registry,"polar_ice_survey").config
	changed.mission.goal.minimum_complete_observations_per_target=2
	check(issue(Validator.validate(changed,catalogs),"INVALID_VALUE","mission.goal.minimum_complete_observations_per_target"),"Survey minimum above one requires a new revision")
	changed=Presets.config_for(catalogs.mission_v2.registry,"polar_ice_survey").config
	changed.mission.target_regions=["arctic_ice","antarctic_region"]
	check(Validator.validate(changed,catalogs).ready_to_launch,"Survey permits two registered compatible targets")
	changed=config.duplicate(true); changed.mission.title="My edited mission"; changed.mission.budget_credits=120
	check(Validator.validate(changed,catalogs).ready_to_launch,"Compatible Creator edits retain template lineage")
	changed.mission.objective="imaging"; changed.mission.goal={"kind":"imaging"}
	check(issue(Validator.validate(changed,catalogs),"INVALID_VALUE","mission.objective"),"Objective switch needs matching lineage")
	var copy: Dictionary=Validator.validate(config,catalogs)
	copy.metrics.total_mass_g=-1; copy.checks.profile_mass.source_id="changed"; copy.errors.append({})
	check(Validator.validate(config,catalogs).metrics.total_mass_g==1120,"Returned data cannot mutate later results")
func malformed(config: Dictionary,catalogs: Dictionary) -> void:
	for field in Rules.ROOT_FIELDS:
		var bad: Dictionary=config.duplicate(true); bad.erase(field)
		var result: Dictionary=Validator.validate(bad,catalogs)
		check(not result.ready_to_launch and result.metrics==null and not result.errors.is_empty(),"Missing root field: "+field)
	for section in ["mission","design"]:
		for value in [null,true,[],"object"]:
			var bad: Dictionary=config.duplicate(true); bad[section]=value
			check(not Validator.validate(bad,catalogs).ready_to_launch,"Wrong object type rejected")
	for field in ["required_observations","duration_orbits","budget_credits","required_returned_data_mb"]:
		for value in [null,true,false,"2",INF,-INF,NAN,0,-1]:
			var bad: Dictionary=config.duplicate(true); bad.mission[field]=value
			var result: Dictionary=Validator.validate(bad,catalogs)
			check(not result.ready_to_launch and result.metrics==null and issue(result,"INVALID_VALUE","mission."+field),"Invalid/unsafe numeric field: "+field)
	for value in [true,false,null,"2",1.5,INF,NAN,0,-1]:
		var bad: Dictionary=config.duplicate(true); bad.mission.goal.required_positive_contact_steps=value
		check(not Validator.validate(bad,catalogs).ready_to_launch,"Invalid goal count cannot truncate or become zero")
	for value in [null,true,[],{},"catalogs"]:
		check(not Validator.validate(config,value).ready_to_launch,"Missing/malformed catalog context fails safely")
	for value in [null,true,[],{},"context"]:
		var bad: Dictionary=catalogs.duplicate(true); bad.mission_v2=value
		check(not Validator.validate(config,bad).ready_to_launch,"Missing/malformed explicit v2 context rejected")
	var bad: Dictionary=config.duplicate(true); bad.extra=1
	check(issue(Validator.validate(bad,catalogs),"INVALID_SCHEMA","extra"),"Unknown root keys rejected")
	bad=config.duplicate(true); bad.design.instrument_id="bus_basic"
	check(issue(Validator.validate(bad,catalogs),"WRONG_COMPONENT_CATEGORY","design.instrument_id"),"Wrong component slot rejected")
	for field in Legacy.DESIGN_FIELDS:
		bad=config.duplicate(true); bad.design.erase(field)
		check(issue(Validator.validate(bad,catalogs),"MISSING_COMPONENT","design."+field),"Missing required design slot: "+field)
	var float_config: Dictionary=config.duplicate(true)
	float_config.schema_version=2.0; float_config.preset_revision=2.0; float_config.mission.goal.required_positive_contact_steps=2.0
	float_config.mission.required_returned_data_mb=12.5
	check(Validator.validate(float_config,catalogs).ready_to_launch,"Whole floats and positive decimal MB remain supported")
	var overflow: Dictionary=catalogs.duplicate(true)
	for part in overflow.components:
		if part.id in ["bus_basic","instrument_basic"]: part.mass_g=9007199254740991
	var result: Dictionary=Validator.validate(config,overflow)
	check(result.metrics==null and issue(result,"INVALID_VALUE","metrics.total_mass_g"),"Safe-integer overflow rejected before totals")
func legacy_checks(base: Dictionary,v2: Dictionary) -> void:
	var fixtures: Dictionary=read_json("res://tests/fixtures/ke1_readiness_cases.json")
	for entry in fixtures.cases:
		var config: Dictionary=read_json("res://tests/fixtures/"+entry.config_file)
		check(Validator.validate(config,base)==Legacy.validate(config,base),"V1 public result unchanged: "+entry.id)
		check(Validator.validate(config,v2)==Legacy.validate(config,base),"V2 context cannot alter v1 verdict: "+entry.id)
	for value in [null,true,false,[],{},"config",1]:
		check(Validator.validate(value,base)==Legacy.validate(value,base),"Malformed legacy result unchanged")
