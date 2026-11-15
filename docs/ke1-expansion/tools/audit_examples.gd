extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Catalog = preload("res://data/mock/DesignCatalog.gd")
const Adapter = preload("res://core/HPCContractAdapter.gd")
const EngineSteps = preload("res://core/MissionStepEngine.gd")
var results: Dictionary = {"base_main":"dce75db845f6c494b8c25c9028dd9c0648aabd91", "checks":[], "configs":{}, "plans":{}}
var failed: int = 0
var examples: String
var output: String
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	results.checks.append({"label":label,"passed":value})
	if not value:
		failed += 1
		printerr("FAIL: " + label)
func read_json(path: String) -> Variant: return JSON.parse_string(FileAccess.get_file_as_string(path))
func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	examples = args[0] if args.size() > 0 else "res://docs/ke1-expansion/examples"
	output = args[1] if args.size() > 1 else "user://ke1-example-audit.json"
	var loaded: Dictionary = Runtime.load_game_catalogs()
	check(loaded.ok, "Runtime-extended catalogs load")
	if not loaded.ok: finish(); return
	var registry: Dictionary = read_json(examples.path_join("mission-presets.proposed.json"))
	check(registry.presets.size() == 5, "Exactly five preset entries")
	var current: Dictionary = {
		"estuary_watch":["Estuary Watch","Coastal Region","Capture Imagery","Polar – 600 km"],
		"tropical_forest_watch":["Tropical Forest Watch","Tropical Forest","Capture Imagery","LEO – 400 km"],
		"polar_ice_survey":["Polar Ice Survey","Arctic Ice","Survey Target Regions","Polar – 600 km"]}
	for preset in registry.presets:
		var config: Dictionary = read_json(examples.path_join(preset.legacy_config_file))
		var config_before: String = JSON.stringify(config)
		var catalogs_before: String = JSON.stringify(loaded.catalogs)
		var verdict: Dictionary = Validator.validate(config, loaded.catalogs)
		check(verdict.ready_to_launch, "Current v1 setup passes: " + preset.preset_id)
		check(config_before == JSON.stringify(config) and catalogs_before == JSON.stringify(loaded.catalogs), "Validation preserves inputs: " + preset.preset_id)
		results.configs[preset.preset_id] = {"ready_to_launch":verdict.ready_to_launch,"metrics":verdict.metrics,"errors":verdict.errors}
		if current.has(preset.preset_id):
			var entry: Array = current[preset.preset_id]
			var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
			draft.name=entry[0]; draft.targets=[entry[1]];draft.target_limit=1;draft.target=entry[1];draft.objective=entry[2];draft.orbit=entry[3]
			var expected: Dictionary = JSON.parse_string(JSON.stringify(Runtime.config_for(draft)))
			results.configs[preset.preset_id].expected_existing_config = expected
			check(expected == config, "Preserve actual existing preset defaults: " + preset.preset_id)
	for filename in ["design-a.v1.json","design-b-radio.v1.json"]:
		var config: Dictionary = read_json(examples.path_join(filename))
		var verdict: Dictionary = Validator.validate(config,loaded.catalogs)
		check(verdict.ready_to_launch, "A/B input ready: " + filename)
		results.configs[filename]={"ready_to_launch":verdict.ready_to_launch,"metrics":verdict.metrics}
	var a: Dictionary=read_json(examples.path_join("design-a.v1.json"));var b: Dictionary=read_json(examples.path_join("design-b-radio.v1.json"))
	b.design.radio_id=a.design.radio_id
	check(a==b,"A/B pair changes only design.radio_id")
	var built: Dictionary=Adapter.build_scenario(loaded.catalogs,loaded.catalogs.orbit_catalog)
	check(built.ok,"Current adapter builds scenario for prepared inputs")
	if not built.ok:finish();return
	var weather_config: Dictionary=read_json(examples.path_join("legacy-configs/weather_monitoring.v1.json"))
	var comm_config: Dictionary=read_json(examples.path_join("legacy-configs/communication.v1.json"))
	var weather: Dictionary=simulate(weather_config,built.scenario,[1,11],[7,17],false,"weather_revisit_audit")
	var same_orbit: Dictionary=simulate(weather_config,built.scenario,[1,6],[7,17],false,"weather_same_orbit_audit")
	var auto_weather: Dictionary=simulate(weather_config,built.scenario,[],[],true,"weather_observe_first_audit")
	var comm: Dictionary=simulate(comm_config,built.scenario,[1,6],[7,10,17,20,27],false,"communication_audit")
	results.plans={"weather_revisit":weather,"weather_same_orbit":same_orbit,"weather_observe_first":auto_weather,"communication":comm}
	check(weather.get("completed",false) and weather.get("observed_orbit_indices",[]).size()==2 and weather.get("returned_mb",0)>=12,"Prepared revisit plan reaches two orbits and 12 MB")
	check(same_orbit.get("observed_orbit_indices",[]).size()==1,"Same-orbit captures do not create two visits")
	check(auto_weather.get("observed_orbit_indices",[]).size()==1,"Current Observe First exposes the repeat-visit policy gap")
	check(comm.get("completed",false) and comm.get("positive_transmit_steps",[]).size()>=2 and comm.get("returned_mb",0)>=12,"Prepared communication plan reaches two positive contacts and 12 MB")
	finish()
func simulate(config: Dictionary, scenario: Dictionary, observe: Array, transmit: Array, auto: bool, id: String) -> Dictionary:
	var started: Dictionary=EngineSteps.init_run(config,scenario,id,"preparation_only")
	if not started.ok:return {"completed":false,"error":started}
	var state: Dictionary=started.state
	var captures: Array=[];var orbits: Array=[];var positive: Array=[];var unavailable: Array=[]
	for guard in range(100):
		if state.phase=="finished":break
		var step: int=int(state.step_index)
		var action: String="power_save"
		if auto:
			for choice in ["observe","transmit"]:
				if state.available_actions[choice].allowed:action=choice;break
		elif step in observe:action="observe"
		elif step in transmit:action="transmit"
		if not state.available_actions[action].allowed:
			unavailable.append({"step":step,"action":action})
			action="power_save"
		var reply: Dictionary=EngineSteps.request_action(state,action)
		if not reply.get("ok",false):return {"completed":false,"error":reply}
		if int(reply.state.observations_completed)>int(state.observations_completed):
			captures.append(step)
			var orbit: int=step/10
			if not orbit in orbits:orbits.append(orbit)
		if float(reply.state.returned_data_mb)>float(state.returned_data_mb):positive.append(step)
		if int(reply.state.step_index)<=step:return {"completed":false,"error":"Action did not advance"}
		state=reply.state
	return {"completed":state.phase=="finished","capture_steps":captures,"observed_orbit_indices":orbits,"positive_transmit_steps":positive,"returned_mb":state.returned_data_mb,"observations":state.observations_completed,"unavailable_plan_actions":unavailable,"official_new_goal_score":null}
func finish() -> void:
	results.passed=results.checks.size()-failed;results.failed=failed
	var file=FileAccess.open(output,FileAccess.WRITE)
	if file == null:
		printerr("Cannot write audit evidence: " + output)
		quit(1)
		return
	file.store_string(JSON.stringify(results,"  "));file.close()
	print("KE1 preparation resource audit: %d checks passed; %d failed." % [results.passed,failed])
	quit(0 if failed==0 else 1)
