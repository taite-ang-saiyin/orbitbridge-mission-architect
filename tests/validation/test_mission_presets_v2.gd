extends SceneTree
const Presets = preload("res://scripts/core/mission_presets_v2.gd")
const Caps = preload("res://scripts/core/mission_capabilities_v2.gd")
const Context = preload("res://scripts/core/mission_v2_context.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
var passed: int=0
var failed: int=0
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1; printerr("FAIL: "+label)
func read_json(path: String) -> Variant: return JSON.parse_string(FileAccess.get_file_as_string(path))
func run() -> void:
	var loaded: Dictionary=Runtime.load_game_catalogs()
	check(loaded.ok,"Effective catalogs load")
	if not loaded.ok: quit(1); return
	var registry: Dictionary=read_json("res://data/mission_presets_v2.json")
	var old: Dictionary=read_json("res://data/mission_presets.json")
	var caps: Dictionary=read_json("res://data/mission_capabilities_v2.json")
	var before: String=JSON.stringify([loaded.catalogs,registry,caps])
	var attached: Dictionary=Context.load_context(loaded.catalogs)
	check(attached.ok,"Agreed registry/capability context loads")
	if not attached.ok: printerr(attached.errors); quit(1); return
	var stripped: Dictionary=attached.catalogs.duplicate(true); stripped.erase("mission_v2")
	check(stripped==loaded.catalogs,"Explicit v2 loading does not change legacy parts/objective IDs/windows")
	check(Presets.inspect(registry).ok,"Exactly five agreed authored presets inspect")
	check(registry.registry_revision=="five-presets-agreed-1" and registry.contract_status=="agreed","Agreed registry marker is explicit")
	for index in 5:
		var entry: Dictionary=registry.presets[index]
		var found: Dictionary=Presets.config_for(registry,entry.id)
		check(found.ok and found.config.preset_id==entry.id,"Canonical config lookup: "+entry.id)
		var expected: Dictionary=old.presets[index].candidate_config_v2.duplicate(true)
		expected.contract_revision="expansion-goals-v2-agreed-1"
		check(found.config==expected,"All authored mission/design settings unchanged: "+entry.id)
		check(entry.revision==(2 if entry.id=="communication" else 1),"Authored revision preserved: "+entry.id)
		var legacy: Dictionary=Presets.legacy_config_for(registry,entry.id)
		if index<3:
			check(legacy.ok and legacy.config==old.presets[index].legacy_config_v1,"Original v1 preset preserved: "+entry.id)
			check(Validator.validate(legacy.config,attached.catalogs)==Validator.validate(legacy.config,loaded.catalogs),"V2 sidecar leaves legacy verdict unchanged: "+entry.id)
		else: check(not legacy.ok and legacy.errors[0].code=="NO_LEGACY_FALLBACK","No Imaging fallback: "+entry.id)
		found.config.mission.title="changed"; found.config.mission.goal.kind="changed"
		check(Presets.config_for(registry,entry.id).config==expected,"Lookup returns isolated nested copies: "+entry.id)
	check(not Presets.config_for(registry,"unknown").ok,"Unknown preset rejected")
	check(before==JSON.stringify([loaded.catalogs,registry,caps]),"All loading/lookup inputs unchanged")
	check(not Context.load_context(loaded.catalogs,"res://not_a_v2_data_folder").ok,"Missing v2 files fail explicitly")
	for value in [null,true,false,[],{},"registry",2]:
		check(not Presets.inspect(value).ok,"Malformed registry rejected safely")
	for field in Presets.ROOT_FIELDS:
		var invalid: Dictionary=registry.duplicate(true); invalid.erase(field)
		check(not Presets.inspect(invalid).ok,"Required registry field: "+field)
	var bad: Dictionary=registry.duplicate(true); bad.unexpected=1
	check(not Presets.inspect(bad).ok,"Unknown registry field rejected")
	for field in Presets.ENTRY_FIELDS:
		bad=registry.duplicate(true); bad.presets[0].erase(field)
		check(not Presets.inspect(bad).ok,"Required preset field: "+field)
	for value in [true,null,0,1.5,3,INF,NAN]:
		bad=registry.duplicate(true); bad.presets[3].revision=value
		check(not Presets.inspect(bad).ok,"Unknown or malformed authored revision rejected")
	bad=registry.duplicate(true); bad.presets[0].legacy_config_v1.mission.required_observations=4
	check(not Presets.inspect(bad).ok,"Original legacy settings cannot drift from authored definition")
	bad=registry.duplicate(true); bad.presets[3].legacy_config_v1=old.presets[0].legacy_config_v1
	check(not Presets.inspect(bad).ok,"New goal cannot acquire an Imaging fallback")
	bad=registry.duplicate(true); bad.presets.reverse()
	check(not Presets.inspect(bad).ok,"Canonical card ordering is stable")
	for value in [null,true,false,[],{},"capabilities"]:
		check(not Caps.inspect(value,loaded.catalogs).ok,"Malformed capability document rejected")
	for field in Caps.FIELDS:
		bad=caps.duplicate(true); bad.erase(field)
		check(not Caps.inspect(bad,loaded.catalogs).ok,"Required capability field: "+field)
	var bad_caps: Array=[]
	bad=caps.duplicate(true); bad.production_enabled=true; bad_caps.append(bad)
	bad=caps.duplicate(true); bad.instruments.append(bad.instruments[0].duplicate(true)); bad_caps.append(bad)
	bad=caps.duplicate(true); bad.instruments[0].instrument_id="bus_basic"; bad_caps.append(bad)
	bad=caps.duplicate(true); bad.instruments[0].objective_ids=["communication","communication"]; bad_caps.append(bad)
	bad=caps.duplicate(true); bad.instruments[0].objective_ids=["unknown"]; bad_caps.append(bad)
	bad=caps.duplicate(true); bad.instruments[0].assumption_id="wrong"; bad_caps.append(bad)
	for value in bad_caps: check(not Caps.inspect(value,loaded.catalogs).ok,"Malformed/unknown capability entry rejected")
	var inspected: Dictionary=Caps.inspect(caps,loaded.catalogs)
	check(inspected.ok and inspected.capability_context.instrument_objectives.instrument_basic.has("communication"),"V2 capability source explicitly supports new objective")
	inspected.capability_context.instrument_objectives.instrument_basic.clear()
	check(Caps.inspect(caps,loaded.catalogs).capability_context.instrument_objectives.instrument_basic.size()==4,"Capability results are isolated copies")
	for value in [null,true,[],{},"context"]:
		check(not Context.inspect_context(value,loaded.catalogs).ok,"Missing context is not inferred")
	var ctx: Dictionary=attached.catalogs.mission_v2.duplicate(true)
	ctx.extra=true
	check(not Context.inspect_context(ctx,loaded.catalogs).ok,"Unknown context field rejected")
	var new_v1: Dictionary=old.presets[3].candidate_config_v2.duplicate(true)
	for field in ["contract_revision","preset_id","preset_revision"]: new_v1.erase(field)
	new_v1.schema_version=1; new_v1.mission.erase("goal")
	check(not Validator.validate(new_v1,attached.catalogs).ready_to_launch,"V2 capability registration never silently enables a v1 new objective")
	print("K21 agreed preset/context checks: %d passed; %d failed." % [passed,failed])
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if not args.is_empty():
		DirAccess.make_dir_recursive_absolute(args[0])
		var file=FileAccess.open(args[0].path_join("agreed-presets-check.json"),FileAccess.WRITE)
		if file!=null: file.store_string(JSON.stringify({"passed":passed,"failed":failed,"registry_revision":registry.registry_revision,"legacy_settings_preserved":true,"live_v2_launch_claimed":false},"  ")); file.close()
	quit(0 if failed==0 else 1)
