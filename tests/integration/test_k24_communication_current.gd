extends SceneTree
## Offline physical/evidence diagnostic only. This is not a production evaluator.
## The original agreed v2 config is always retained; v1 proxies are explicit.
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Context = preload("res://scripts/core/mission_v2_context.gd")
const Presets = preload("res://scripts/core/mission_presets_v2.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Native = preload("res://core/MissionStepEngine.gd")
const Support = preload("res://scripts/core/validation_support.gd")
var passed: int=0
var failed: int=0
var output: Dictionary={"revision":"k24-agreed-communication-1","scope":"EXPLICIT_V1_PHYSICS_AND_OFFLINE_RULE_DIAGNOSTICS_NOT_PRODUCTION_V2_OUTCOMES","official_new_goal_score":null,"cases":{},"counter_controls":{}}
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1; printerr("FAIL: "+label)
func run() -> void:
	var base: Dictionary=Runtime.load_game_catalogs()
	var loaded: Dictionary=Context.load_context(base.catalogs)
	check(base.ok and loaded.ok,"Effective catalogs and agreed context load")
	if not loaded.ok: quit(1); return
	var starter: Dictionary=Presets.config_for(loaded.catalogs.mission_v2.registry,"communication").config
	check(starter.preset_revision==2 and starter.design.radio_id=="radio_fast" and starter.mission.required_observations==2,"Exact agreed Communication revision-2 starter")
	var before: String=JSON.stringify([starter,loaded.catalogs,base.catalogs])
	var edits: Array=[
		{"id":"fast_starter_pass","observe":[1,6],"transmit":[7,10],"radio":"radio_fast","mb_target":12,"expected_steps":[7,10],"expected_mb":24},
		{"id":"same_config_count_shortfall","observe":[1],"transmit":[7,10],"radio":"radio_fast","mb_target":12,"expected_steps":[7],"expected_mb":12},
		{"id":"edited_25mb_data_shortfall","observe":[1,6],"transmit":[7,10],"radio":"radio_fast","mb_target":25,"expected_steps":[7,10],"expected_mb":24},
		{"id":"captures_without_transmission","observe":[1,6],"transmit":[],"radio":"radio_fast","mb_target":12,"expected_steps":[],"expected_mb":0},
		{"id":"basic_radio_quota_not_success_gate","observe":[1],"transmit":[7,10],"radio":"radio_basic","mb_target":12,"expected_steps":[7,10],"expected_mb":12}
	]
	for item in edits:
		var config: Dictionary=starter.duplicate(true)
		config.design.radio_id=item.radio
		config.mission.required_returned_data_mb=item.mb_target
		var readiness: Dictionary=Validator.validate(config,loaded.catalogs)
		check(readiness.ready_to_launch,item.id+": exact agreed v2 design passes public readiness")
		var attempt: Dictionary=Native.init_validated_run(config,loaded.catalogs,"k24_actual_v2_"+item.id,"k24_agreed")
		check(not attempt.ok and not attempt.has("state"),item.id+": current native v2 gap is explicit; no silent fallback")
		# Separate test-only physical input, never returned as a production config.
		var proxy: Dictionary=config.duplicate(true)
		for field in ["contract_revision","preset_id","preset_revision"]: proxy.erase(field)
		proxy.schema_version=1; proxy.mission.erase("goal"); proxy.mission.objective="imaging"
		var measured: Dictionary=physical_trial(proxy,base.catalogs,item)
		if measured.is_empty(): continue
		var final: Dictionary=measured.final_state
		var counted: Dictionary=count_contacts(final.event_log,final.run_id,int(final.total_steps))
		check(counted.ok and counted.positive_steps==item.expected_steps,item.id+": exact positive transmission steps")
		check(absf(final.returned_data_mb-float(item.expected_mb))<0.000001,item.id+": exact returned data")
		var count_met: bool=counted.ok and counted.positive_steps.size()>=config.mission.goal.required_positive_contact_steps
		var data_met: bool=final.returned_data_mb>=config.mission.required_returned_data_mb
		check(count_met==(item.id in ["fast_starter_pass","edited_25mb_data_shortfall","basic_radio_quota_not_success_gate"]),item.id+": count goal independent")
		check(data_met==(item.id in ["fast_starter_pass","same_config_count_shortfall","basic_radio_quota_not_success_gate"]),item.id+": MB goal independent")
		output.cases[item.id]={"agreed_config_v2":config,"v2_readiness":readiness,"native_v2_attempt":attempt,"explicit_test_only_v1_physical_input":proxy,"native_physical_trace":measured,"contact_diagnostic":counted,"count_requirement_met":count_met,"returned_mb_requirement_met":data_met,"capture_quota_met":final.observations_completed>=config.mission.required_observations,"official_new_goal_outcome":null,"official_new_goal_score":null}
	if output.cases.size()!=5:
		printerr("FAIL: Required physical cases are missing; no complete K24 result is claimed.")
		quit(1); return
	var passing: Dictionary=output.cases.fast_starter_pass
	var shortfall: Dictionary=output.cases.same_config_count_shortfall
	check(passing.agreed_config_v2==shortfall.agreed_config_v2,"Count-only shortfall uses the exact same v2 config; only requested actions change")
	check(shortfall.returned_mb_requirement_met and not shortfall.count_requirement_met,"Count-only failure isolated from MB")
	var basic: Dictionary=output.cases.basic_radio_quota_not_success_gate
	check(not basic.capture_quota_met and basic.count_requirement_met and basic.returned_mb_requirement_met,"One capture can satisfy both Communication requirements; capture quota is not an extra success target")
	counter_controls(passing.native_physical_trace.final_state)
	check(JSON.stringify([starter,loaded.catalogs,base.catalogs])==before,"Agreed starter/defaults and shared catalogs remain unchanged")
	output.passed=passed; output.failed=failed
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.is_empty(): printerr("Provide an evidence output folder after --"); quit(1); return
	DirAccess.make_dir_recursive_absolute(args[0])
	var file=FileAccess.open(args[0].path_join("communication-current-check.json"),FileAccess.WRITE)
	if file==null: printerr("FAIL: Evidence cannot be written"); quit(1); return
	file.store_string(JSON.stringify(output,"  ")); file.close()
	print("K24 current Communication audit: %d checks passed; %d failed." % [passed,failed])
	quit(0 if failed==0 else 1)
func physical_trial(config: Dictionary,catalogs: Dictionary,item: Dictionary) -> Dictionary:
	var initial: Dictionary=Native.init_validated_run(config,catalogs,"k24_proxy_"+item.id,"k24_explicit_v1_physical")
	check(initial.ok,item.id+": explicit supported v1 physical trial starts")
	if not initial.ok: return {}
	var state: Dictionary=initial.state
	var samples: Array=[resource_sample(state)]
	var requested: Array=[]
	var blocked: Array=[]
	for index in range(int(state.total_steps)):
		if index in [0,2]:
			for probe in (2 if index==0 else 1):
				var prior: String=JSON.stringify(state)
				var probe_result: Dictionary=Native.request_action(state,"transmit")
				check(prior==JSON.stringify(state),item.id+": rejected probe does not mutate input")
				check(probe_result.ok and not probe_result.allowed,item.id+": empty/off-window probe rejected")
				check(same_resources(state,probe_result.state),item.id+": rejected probe advances no resources/time")
				blocked.append_array(probe_result.events.duplicate(true)); state=probe_result.state
		var action: String="observe" if item.observe.has(index) else ("transmit" if item.transmit.has(index) else "power_save")
		requested.append({"pre_action_step":index,"action":action})
		var before: String=JSON.stringify(state)
		var result: Dictionary=Native.request_action(state,action)
		check(before==JSON.stringify(state),item.id+": requested action leaves input unchanged")
		check(result.ok,item.id+": native action returns a result")
		if not result.ok: return {}
		if not result.allowed:
			check(item.id=="same_config_count_shortfall" and index==10 and result.events[0].code=="NO_DATA",item.id+": only planned empty-buffer request is blocked")
			check(same_resources(state,result.state),item.id+": blocked request changes no resources/time")
			blocked.append_array(result.events.duplicate(true)); state=result.state
			result=Native.request_action(state,"power_save")
			check(result.ok and result.allowed,item.id+": explicit power-save advances after blocked action")
		state=result.state
		check(state.step_index==index+1,item.id+": accepted step advances once")
		check(state.energy_wh>=0 and state.energy_wh<=state.battery_capacity_wh and state.stored_data_mb>=0 and state.stored_data_mb<=state.storage_capacity_mb,item.id+": accepted post-clamp resources bounded")
		samples.append(resource_sample(state))
	check(state.phase=="finished" and state.run_status=="completed",item.id+": physical trial completes")
	check(samples.size()==int(state.total_steps)+1 and samples.back().phase=="finished",item.id+": sample range includes initialization and terminal")
	check(state.config_snapshot==config,item.id+": exact explicit v1 physical config remains frozen")
	return {"scope":"VERIFIED_NATIVE_V1_PHYSICS_ONLY","initial_state":initial.state,"final_state":state,"requested_plan":requested,"blocked_attempts":blocked,"resource_samples":samples}
func resource_sample(state: Dictionary) -> Dictionary:
	return {"scope":"projection_from_observed_native_post_clamp_state","run_id":state.run_id,"step_index":state.step_index,"energy_wh":state.energy_wh,"stored_data_mb":state.stored_data_mb,"phase":state.phase}
func same_resources(a: Dictionary,b: Dictionary) -> bool:
	for field in ["step_index","energy_wh","stored_data_mb","returned_data_mb","observations_completed"]:
		if a[field]!=b[field]: return false
	return true
func count_contacts(events: Variant,run_id: String,total_steps: int) -> Dictionary:
	# A deliberately local offline audit. Invalid provenance means unavailable,
	# not zero progress. KE2 still owns the production evidence validator/scorer.
	var errors: Array=[]; var steps: Array=[]; var ids: Dictionary={}
	if not events is Array: return {"ok":false,"positive_steps":null,"errors":["event array unavailable"]}
	for event in events:
		if not event is Dictionary or event.get("run_id")!=run_id or not Support.is_text(event.get("event_id")):
			errors.append("missing/foreign native run identity"); continue
		if ids.has(event.event_id):
			if ids[event.event_id]!=event: errors.append("conflicting duplicate event identity")
			continue
		ids[event.event_id]=event.duplicate(true)
		if event.get("type")!="action_accepted" or event.get("action")!="transmit": continue
		if not Support.is_whole(event.get("step_index")) or event.step_index<0 or event.step_index>=total_steps or not Support.is_number(event.get("delta_returned_data_mb")) or event.delta_returned_data_mb<0:
			errors.append("invalid accepted transmission evidence"); continue
		if event.delta_returned_data_mb>0 and not steps.has(event.step_index): steps.append(event.step_index)
	return {"ok":errors.is_empty(),"positive_steps":steps if errors.is_empty() else null,"errors":errors}
func counter_controls(state: Dictionary) -> void:
	var events: Array=state.event_log.duplicate(true)
	var baseline: Dictionary=count_contacts(events,state.run_id,state.total_steps)
	var sample: Dictionary={}
	for event in events:
		if event.type=="action_accepted" and event.action=="transmit" and event.delta_returned_data_mb>0: sample=event.duplicate(true); break
	var duplicate: Array=events.duplicate(true); duplicate.append(sample.duplicate(true))
	check(count_contacts(duplicate,state.run_id,state.total_steps).positive_steps==baseline.positive_steps,"Repeated evidence counts once")
	var zero: Dictionary=sample.duplicate(true); zero.event_id="zero_control"; zero.delta_returned_data_mb=0
	duplicate=events.duplicate(true); duplicate.append(zero)
	check(count_contacts(duplicate,state.run_id,state.total_steps).positive_steps==baseline.positive_steps,"Accepted zero-data evidence adds no contact")
	for kind in ["foreign","conflicting_id","fractional_step","negative_data","missing_events"]:
		var bad: Dictionary=sample.duplicate(true)
		var used: Variant=events.duplicate(true)
		if kind=="foreign": bad.run_id="different_run"; bad.event_id="foreign"
		elif kind=="conflicting_id": bad.delta_returned_data_mb+=1
		elif kind=="fractional_step": bad.event_id="fractional"; bad.step_index=7.5
		elif kind=="negative_data": bad.event_id="negative"; bad.delta_returned_data_mb=-1
		if kind=="missing_events": used=null
		else: used.append(bad)
		var reply: Dictionary=count_contacts(used,state.run_id,state.total_steps)
		check(not reply.ok and reply.positive_steps==null,"Malformed/foreign evidence stays unavailable: "+kind)
		output.counter_controls[kind]=reply
