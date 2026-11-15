extends SceneTree
const Presets = preload("res://scripts/core/mission_preset_catalog.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Catalog = preload("res://data/mock/DesignCatalog.gd")
var passed: int = 0
var failed: int = 0
var evidence: Dictionary = {"base_main":"dce75db", "stock_setups":{}, "new_goals_playable":false}
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)
func normalized(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value))
func run() -> void:
	var loaded: Dictionary = Presets.load_registry()
	check(loaded.ok,"Five-preset candidate file loads")
	if not loaded.ok: print(loaded); quit(1); return
	var registry: Dictionary = loaded.registry
	evidence.registry_revision = registry.registry_revision
	evidence.goal_contract_revision = registry.goal_contract_revision
	check(registry.registry_revision=="five-presets-candidate-2","Candidate registry revision identifies fast-radio review")
	check(registry.goal_contract_revision=="expansion-goals-v2-draft-2","Draft revision matches current KE2-aligned review")
	var communication: Dictionary = Presets.get_preset(registry,"communication").preset
	check(communication.revision==2 and communication.candidate_config_v2.preset_revision==2,"Communication design change has a new preset revision")
	check(communication.candidate_config_v2.design=={"bus_id":"bus_basic","instrument_id":"instrument_basic","solar_id":"solar_standard","battery_id":"battery_standard","radio_id":"radio_fast","storage_id":"storage_standard","launch_profile_id":"cubesat_1u_sample","launcher_id":"small","orbit_id":"high_inc"},"Communication uses the exact proposed fast-radio stock design")
	var communication_mission: Dictionary = communication.candidate_config_v2.mission
	check(communication_mission.target_region=="equator" and communication_mission.required_observations==2 and communication_mission.duration_orbits==3 and communication_mission.required_returned_data_mb==12 and communication_mission.budget_credits==100 and communication_mission.goal.required_positive_contact_steps==2,"Communication preserves all KE2 starter goals")
	var original: String = JSON.stringify(registry)
	var catalogs: Dictionary = Runtime.load_game_catalogs()
	check(catalogs.ok,"Current runtime catalogs load")
	if not catalogs.ok: quit(1); return
	check(registry.presets.size()==5,"Exactly three retained presets and two new definitions")
	var entries: Dictionary = {
		"estuary_watch":["Estuary Watch","Coastal Region","Capture Imagery","Polar – 600 km"],
		"tropical_forest_watch":["Tropical Forest Watch","Tropical Forest","Capture Imagery","LEO – 400 km"],
		"polar_ice_survey":["Polar Ice Survey","Arctic Ice","Survey Target Regions","Polar – 600 km"]}
	for id in Presets.IDS:
		var selected: Dictionary = Presets.get_preset(registry,id)
		check(selected.ok,"Lookup canonical ID " + id)
		var preset: Dictionary = selected.preset
		var config: Dictionary = preset.candidate_config_v2.duplicate(true)
		var rejected: Dictionary = Validator.validate(config,catalogs.catalogs)
		check(not rejected.ready_to_launch,"Current v1 boundary rejects unapproved v2 input: " + id)
		# Test current physical setup only. This surrogate is never returned by the catalog API.
		for field in ["contract_revision","preset_id","preset_revision"]: config.erase(field)
		config.schema_version=1
		config.mission.erase("goal")
		if not id in entries: config.mission.objective="imaging"
		var config_before: String = JSON.stringify(config)
		var catalogs_before: String = JSON.stringify(catalogs.catalogs)
		var verdict: Dictionary = Validator.validate(config,catalogs.catalogs)
		check(verdict.ready_to_launch,"Current stock hardware/targets pass readiness: " + id)
		check(verdict.checks.size()==8,"All eight readiness gates retained: " + id)
		if id=="communication":
			check(verdict.metrics.total_mass_g==1120 and verdict.metrics.total_cost_credits==89,"Fast-radio Communication totals are 1120 g and 89 credits")
		check(config_before==JSON.stringify(config) and catalogs_before==JSON.stringify(catalogs.catalogs),"Stock validation preserves inputs: " + id)
		evidence.stock_setups[id]={"physical_setup_ready":verdict.ready_to_launch,"metrics":verdict.metrics,"logical_goal_evaluated":false}
		var existing: Dictionary = Presets.existing_v1_config(registry,id)
		if id in entries:
			check(existing.ok,"Existing v1 setup remains available: " + id)
			var entry: Array = entries[id]
			var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
			draft.name=entry[0];draft.targets=[entry[1]];draft.target=entry[1];draft.target_limit=1;draft.objective=entry[2];draft.orbit=entry[3]
			check(normalized(Runtime.config_for(draft))==normalized(existing.config),"Original UI defaults remain exact: " + id)
			check(existing.scoring_supported==(id!="polar_ice_survey"),"Survey scoring limitation remains explicit: " + id)
		else:
			check(not existing.ok and existing.errors[0].code=="GOAL_EXTENSION_PENDING" and not existing.has("config"),"No Imaging fallback or launch config for new goal: " + id)
	selected_copy_checks(registry)
	check(JSON.stringify(registry)==original,"Lookups and validation never mutate registry")
	check(not Presets.get_preset(registry,"unknown").ok,"Unknown preset rejected")
	check(not Presets.load_registry("res://data/no-such-presets.json").ok,"Missing registry fails clearly")
	check(not Presets.inspect(null).ok,"Null registry rejected")
	check(not Presets.inspect([]).ok,"Non-object registry rejected")
	var mutations: Array = []
	var bad: Dictionary=registry.duplicate(true);bad.presets.pop_back();mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[1].id=bad.presets[0].id;mutations.append(bad)
	bad=registry.duplicate(true);bad.contract_status="agreed";mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[0].candidate_config_v2.preset_id="communication";mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[4].candidate_config_v2.mission.goal.kind="communication_contacts";mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[3].candidate_config_v2.mission.goal.required_positive_contact_steps=true;mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[3].candidate_config_v2.mission.goal.required_positive_contact_steps=1.5;mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[4].candidate_config_v2.mission.goal.required_distinct_orbits=0;mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[4].candidate_config_v2.mission.required_returned_data_mb=NAN;mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[3].legacy_config_v1=registry.presets[0].legacy_config_v1.duplicate(true);mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[4].availability="existing_imaging";mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[0].legacy_config_v1.mission.required_observations=3;mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[4].candidate_config_v2.mission.target_regions=[];mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[3].candidate_config_v2.mission.goal.required_returned_data_mb=12;mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[3].candidate_config_v2.preset_revision=1;mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[3].revision=0;mutations.append(bad)
	bad=registry.duplicate(true);bad.presets[3].revision=true;mutations.append(bad)
	bad=registry.duplicate(true);bad.goal_contract_revision="expansion-goals-v2-draft-1";mutations.append(bad)
	for index in mutations.size():
		var invalid: Dictionary=Presets.inspect(mutations[index])
		check(not invalid.ok and invalid.registry.is_empty() and not invalid.errors.is_empty(),"Malformed/unsafe candidate rejected: %d" % index)
	evidence.passed=passed;evidence.failed=failed
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if not args.is_empty():
		DirAccess.make_dir_recursive_absolute(args[0])
		var file=FileAccess.open(args[0].path_join("mission-presets-check.json"),FileAccess.WRITE)
		if file!=null: file.store_string(JSON.stringify(evidence,"  "));file.close()
	print("K20/K21 preset checks: %d passed; %d failed." % [passed,failed])
	quit(0 if failed==0 else 1)
func selected_copy_checks(registry: Dictionary) -> void:
	var first: Dictionary=Presets.get_preset(registry,"estuary_watch")
	first.preset.candidate_config_v2.mission.title="Changed copy"
	check(Presets.get_preset(registry,"estuary_watch").preset.display_name=="Estuary Watch","Retrieved definitions are isolated copies")
	var legacy: Dictionary=Presets.existing_v1_config(registry,"estuary_watch")
	legacy.config.design.radio_id="changed"
	check(Presets.existing_v1_config(registry,"estuary_watch").config.design.radio_id=="radio_basic","Legacy config copies cannot rewrite stock definitions")
