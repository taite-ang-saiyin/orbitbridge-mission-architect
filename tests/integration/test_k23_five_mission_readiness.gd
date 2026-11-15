extends SceneTree
## Current agreed v2 readiness/native gate plus exact supported legacy game runs.
## This audit never claims physical readiness is production mission success.
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Context = preload("res://scripts/core/mission_v2_context.gd")
const Presets = preload("res://scripts/core/mission_presets_v2.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Native = preload("res://core/MissionStepEngine.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
const UI = preload("res://data/mock/DesignCatalog.gd")
var passed: int=0
var failed: int=0
var output: Dictionary={"report_revision":"k23-live-readiness-2","contract_revision":"expansion-goals-v2-agreed-1","scope":"CURRENT_PUBLIC_READINESS_AND_NATIVE_GATE_NOT_BROWSER_ACCEPTANCE","missions":{}}
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1; printerr("FAIL: "+label)
func normalized(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value))
func run() -> void:
	var base: Dictionary=Runtime.load_game_catalogs()
	check(base.ok,"Current game catalogs load")
	if not base.ok: quit(1); return
	var loaded: Dictionary=Context.load_context(base.catalogs)
	check(loaded.ok,"Agreed v2 context loads")
	if not loaded.ok: printerr(loaded.errors); quit(1); return
	var catalogs: Dictionary=loaded.catalogs
	var registry: Dictionary=catalogs.mission_v2.registry
	var frozen_sources: String=JSON.stringify([base.catalogs,catalogs,registry])
	for preset in registry.presets:
		var config: Dictionary=Presets.config_for(registry,preset.id).config
		var before: String=JSON.stringify(config)
		var validation: Dictionary=Validator.validate(config,catalogs)
		check(validation.ready_to_launch and validation.errors.is_empty(),preset.id+": agreed v2 physical readiness")
		check(validation.checks.size()==8,preset.id+": eight readiness gates")
		for gate in validation.checks:
			check(validation.checks[gate].status=="pass" and validation.checks[gate].passed,preset.id+": "+gate)
		check(validation.metrics.total_mass_g==(1120 if preset.id=="communication" else 1060),preset.id+": stock mass")
		check(validation.metrics.total_cost_credits==(89 if preset.id=="communication" else 82),preset.id+": stock cost")
		check(validation.checks.profile_mass.comparator=="<" and validation.checks.profile_mass.threshold_g==1330 and validation.checks.profile_mass.source_id=="cubesat_101_1u_sample",preset.id+": correct profile/source rule")
		var native: Dictionary=Native.init_validated_run(config,catalogs,"k23_v2_"+preset.id,"k23_agreed_stock")
		if native.ok:
			check(native.state.config_snapshot==config and native.state.config_snapshot.mission.goal==config.mission.goal,preset.id+": native acceptance retains full v2 goals")
		else:
			check(not native.has("state") and native.get("error") is Dictionary and not native.error.get("code","").is_empty(),preset.id+": unsupported launch is explicit and creates no state")
		check(JSON.stringify(config)==before,preset.id+": full input config unchanged")
		var record: Dictionary={"display_name":preset.display_name,"config_v2":config.duplicate(true),"validation":validation,"native_launch":native,"native_v2_initialized":native.ok,"v2_end_to_end_accepted":false,"official_v2_outcome":null,"legacy_game_runs":{}}
		if preset.legacy_config_v1 is Dictionary:
			for policy in ["Observe First","Downlink First"]:
				record.legacy_game_runs[policy]=legacy_game_run(preset,base.catalogs,policy)
		if preset.id in ["tropical_forest_watch","polar_ice_survey"]:
			var variant: Dictionary=preset.duplicate(true)
			variant.legacy_config_v1.design.radio_id="radio_fast"
			var variant_config: Dictionary=config.duplicate(true)
			variant_config.design.radio_id="radio_fast"
			var variant_ready: Dictionary=Validator.validate(variant_config,catalogs)
			check(variant_ready.ready_to_launch and variant_ready.metrics.total_mass_g==1120 and variant_ready.metrics.total_cost_credits==89,preset.id+": fast-radio player design is physically valid")
			var trial: Dictionary=legacy_game_run(variant,base.catalogs,"Observe First","_fast_radio")
			if trial.ok:
				check(trial.final_state.observations_completed>=config.mission.required_observations and trial.final_state.returned_data_mb>=config.mission.required_returned_data_mb,preset.id+": tested redesign meets aggregate capture/data requirements")
				check(trial.final_state.run_id!=record.legacy_game_runs["Observe First"].final_state.run_id,preset.id+": redesign uses a distinct run identity")
			record.player_redesign={"scope":"EXPLICIT_RADIO_ONLY_DESIGN_OPTION_NOT_A_DEFAULT_CHANGE_OR_FORMAL_AB_ACCEPTANCE","config_v2":variant_config,"validation":variant_ready,"legacy_game_run":trial}
		output.missions[preset.id]=record
	check(JSON.stringify([base.catalogs,catalogs,registry])==frozen_sources,"All physical/context/preset input snapshots unchanged")
	output.passed=passed; output.failed=failed
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.is_empty(): printerr("Provide an evidence output folder after --"); quit(1); return
	DirAccess.make_dir_recursive_absolute(args[0])
	var file=FileAccess.open(args[0].path_join("five-mission-readiness-current.json"),FileAccess.WRITE)
	if file==null: printerr("FAIL: Evidence file cannot be written"); quit(1); return
	file.store_string(JSON.stringify(output,"  ")); file.close()
	print("K23 current five-mission audit: %d checks passed; %d failed." % [passed,failed])
	quit(0 if failed==0 else 1)
func legacy_game_run(preset: Dictionary,catalogs: Dictionary,policy: String,tag: String="") -> Dictionary:
	var expected: Dictionary=preset.legacy_config_v1
	var draft: Dictionary=UI.DEFAULTS.duplicate(true)
	draft.name=expected.mission.title
	draft.objective=preset.ui_defaults.objective_label
	draft.targets=preset.ui_defaults.target_labels.duplicate(true)
	draft.orbit=preset.ui_defaults.orbit_label
	draft.observations=expected.mission.required_observations
	draft.required_returned_data_mb=expected.mission.required_returned_data_mb
	draft.duration=expected.mission.duration_orbits
	draft.budget=expected.mission.budget_credits
	draft.launcher_id=expected.design.launcher_id
	draft.launch_profile_id=expected.design.launch_profile_id
	draft.engineering_parts={}
	for category in ["bus","instrument","solar","battery","radio","storage"]: draft.engineering_parts[category]=expected.design[category+"_id"]
	draft.policy=policy
	draft.run_session_id="k23_"+preset.id+"_"+("observe" if policy=="Observe First" else "downlink")+tag
	check(normalized(Runtime.config_for(draft))==normalized(expected),preset.id+": actual UI/runtime mapping matches exact configured legacy design")
	var prior: String=JSON.stringify(catalogs)
	var launched: Dictionary=Runtime.launch(draft)
	check(launched.ok,preset.id+": supported legacy game launch: "+policy)
	if not launched.ok: return {"ok":false,"error":launched.get("error")}
	var trace: Dictionary=launched.trace
	check(normalized(trace.config)==normalized(expected),preset.id+": actual frozen game config matches the requested design")
	check(trace.final_state.phase=="finished" and trace.final_state.run_status=="completed",preset.id+": legacy game run completes")
	check(trace.final_state.config_snapshot==trace.config and trace.final_state.event_log==trace.events,preset.id+": exact config/event binding")
	check(trace.frames.size()==int(trace.final_state.total_steps)+1,preset.id+": initialization plus every accepted post-step resource state")
	var sample_range: Array=[]
	for frame in trace.frames:
		var state: Dictionary=frame.state
		check(state.energy_wh>=0 and state.energy_wh<=state.battery_capacity_wh and state.stored_data_mb>=0 and state.stored_data_mb<=state.storage_capacity_mb,preset.id+": native clamped resource bounds")
		sample_range.append({"step_index":state.step_index,"run_id":state.run_id,"energy_wh":state.energy_wh,"stored_data_mb":state.stored_data_mb,"phase":state.phase})
	var evaluated: Dictionary=Results.evaluate_trace(trace)
	if expected.mission.objective=="imaging":
		check(evaluated.ok and evaluated.report.run_id==trace.final_state.run_id and evaluated.report.mission_id==trace.final_state.mission_id,preset.id+": real supported report belongs to this execution")
	else:
		check(not evaluated.ok and evaluated.get("error") is Dictionary,preset.id+": unsupported Survey evaluation remains explicit")
	check(JSON.stringify(catalogs)==prior,preset.id+": game run leaves shared catalogs unchanged")
	return {"ok":true,"scope":"EXACT_SUPPORTED_LEGACY_GAME_RUNTIME_NOT_V2_ACCEPTANCE","policy":policy,"config":trace.config,"validation":trace.validation,"initial_state":trace.frames[0].state,"final_state":trace.final_state,"events":trace.events,"resource_samples":sample_range,"evaluation":evaluated}
