extends SceneTree
const Runtime=preload("res://scripts/integration/mission_runtime.gd")
const HPC=preload("res://core/MissionStepEngine.gd")
const Results=preload("res://scripts/integration/mission_results.gd")
const Catalog=preload("res://data/mock/DesignCatalog.gd")
const Presenter=preload("res://scripts/presentation/DebriefPresentation.gd")
var out: String
var checks: Array=[]
var failed: int=0
func _initialize() -> void:
	out=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("run")
func check(value: bool,message: String) -> void:
	checks.append({"pass":value,"check":message})
	if not value:
		failed+=1
		print("FAIL ",message)
func save(name: String,data: Variant) -> void:
	var f=FileAccess.open(out.path_join(name+".json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"  "))
func power_draft() -> Dictionary:
	var d: Dictionary=Catalog.DEFAULTS.duplicate(true)
	Catalog.ensure(d)
	d.name="KE3 stock-catalog power-limited acceptance"
	d.observations=8
	d.required_returned_data_mb=192
	d.duration=9
	d.budget=150
	d.orbit="Polar – 600 km"
	d.launch_profile_id="illustrative_alternative"
	d.launcher_id="medium"
	d.policy="Observe First"
	d.engineering_parts={"bus":"bus_basic","instrument":"instrument_advanced","solar":"solar_standard","battery":"battery_standard","radio":"radio_fast","storage":"storage_large"}
	return d
func execute(config: Dictionary,catalogs: Dictionary,id: String) -> Dictionary:
	var initialized: Dictionary=HPC.init_validated_run(config,catalogs,id,"ke3_stock_power_acceptance")
	check(initialized.ok,"KE1 launch-approved stock power case "+id)
	if not initialized.ok: return initialized
	var state: Dictionary=initialized.state
	var initial: Dictionary=state.duplicate(true)
	var frames: Array=[{"state":state.duplicate(true),"events":[]}]
	var actions: Array=[]
	var rejected_no_contact: bool=false
	var request_count: int=0
	while state.phase=="operating" and request_count<300:
		var action: String="power_save"
		if state.step_index==8 and not rejected_no_contact:
			action="transmit"
			rejected_no_contact=true
		# Capture once per orbit at authored target slot1; this spreads24MB packets
		# across contacts rather than fabricating energy or using an impossible goal.
		elif state.step_index%10==1 and state.observations_completed<config.mission.required_observations: action="observe"
		elif state.in_ground_contact and state.stored_data_mb>0: action="transmit"
		var before: Dictionary=state.duplicate(true)
		var result: Dictionary=HPC.request_action(state,action)
		request_count+=1
		check(result.ok,"Power sequence provider reply "+str(request_count))
		if not result.ok: return result
		state=result.state
		actions.append({"step":before.step_index,"action":action,"allowed":result.allowed,"event_ids":result.events.map(func(e): return e.event_id)})
		frames.append({"state":state.duplicate(true),"events":result.events.duplicate(true)})
		check(state.energy_wh>=0 and state.energy_wh<=state.battery_capacity_wh and state.stored_data_mb>=0 and state.stored_data_mb<=state.storage_capacity_mb,"Bounded provider resources "+str(request_count))
		if not result.allowed:
			for field in ["step_index","energy_wh","stored_data_mb","returned_data_mb","observations_completed"]:
				check(state[field]==before[field],"Blocked "+result.events[0].code+" unchanged "+field)
			var saved: Dictionary=HPC.request_action(state,"power_save")
			check(saved.ok and saved.allowed,"Fallback power_save supplied by HPC")
			actions.append({"step":state.step_index,"action":"power_save","allowed":saved.allowed,"event_ids":saved.events.map(func(e): return e.event_id)})
			state=saved.state
			frames.append({"state":state.duplicate(true),"events":saved.events.duplicate(true)})
	check(state.phase=="finished" and state.step_index==state.total_steps,"Full power-limited mission reaches planned terminal")
	var validation: Dictionary=initialized.validation_result.duplicate(true)
	validation.config=config.duplicate(true)
	var trace: Dictionary={"config":config.duplicate(true),"validation":validation,"events":state.event_log.duplicate(true),"final_state":state.duplicate(true),"frames":frames,"policy":"explicit stock-catalog acceptance action sequence (API-driven, not policy UI)"}
	var reply: Dictionary=Results.evaluate_trace(trace)
	return {"ok":true,"trace":trace,"initial_state":initial,"actions":actions,"evaluation":reply,"scope":"Validated KE1→HPC full run→KE2 provider integration. No injected energy/catalog values. Deliberate illegal actions are API requests, not manual UI clicks."}
func normalized(record: Dictionary) -> Dictionary:
	var value: Dictionary={"config":record.trace.config.duplicate(true),"state":record.trace.final_state.duplicate(true),"events":record.trace.events.duplicate(true),"report":record.evaluation.report.duplicate(true),"actions":record.actions.duplicate(true)}
	for field in ["run_id","mission_id","event_log"]: value.state.erase(field)
	for event in value.events:
		event.erase("run_id")
		event.erase("mission_id")
	for field in ["run_id","mission_id"]: value.report.erase(field)
	return value
func run() -> void:
	var loaded: Dictionary=Runtime.load_game_catalogs()
	var draft: Dictionary=power_draft()
	var config: Dictionary=Runtime.config_for(draft)
	var run_a: Dictionary=execute(config,loaded.catalogs,"ke3_stock_power8_a")
	if not run_a.ok:
		save("blocked-setup",run_a)
		quit(1)
		return
	var events: Array=run_a.trace.events
	var lows: Array=events.filter(func(e): return e.code=="LOW_BATTERY")
	var no_contact: Array=events.filter(func(e): return e.code=="NO_LINK_WINDOW")
	check(not lows.is_empty(),"Stock catalog causes actual low-energy blocked requests without state injection")
	check(no_contact.size()==1,"Same full journey includes rejected no-contact Transmit")
	check(run_a.evaluation.ok,"Full power-limited trace accepted by actual KE2")
	var report: Dictionary=run_a.evaluation.get("report",{})
	var supported_power_cause: bool=false
	for cause in report.get("root_causes",[]):
		if cause.code=="LOW_BATTERY":
			for id in cause.evidence_event_ids:
				if events.any(func(e):return e.event_id==id and e.code=="LOW_BATTERY" and e.type=="action_blocked"): supported_power_cause=true
	check(supported_power_cause,"KE2 power cause resolves to this run's actual blocked event")
	var order_ok: bool=true
	var last_step: int=-1
	for i in events.size():
		if events[i].event_id!="evt_%03d"%i or events[i].step_index<last_step or events[i].run_id!="ke3_stock_power8_a": order_ok=false
		last_step=events[i].step_index
	check(order_ok,"Actual power-run event identity/order intact")
	save("power-a",run_a)
	var run_b: Dictionary=execute(config,loaded.catalogs,"ke3_stock_power8_b")
	check(normalized(run_a)==normalized(run_b),"Identical stock config/scenario/action policy repeats exactly excluding identity")
	save("power-b",run_b)
	# Render the actual run report through the existing Results presentation;
	# clearly separate this provider-driven run from normal policy UI dispatch.
	var session: Dictionary={"run_history":[run_a.trace]}
	check(Results.publish(session,run_a.trace.final_state).ok,"Power report published through actual SE result hook")
	var page=load("res://scenes/screens/DebriefCompare.tscn").instantiate()
	page.theme=preload("res://ui/theme/WorkbenchTheme.gd").build()
	page.state=session
	root.add_child(page)
	for i in 8: await process_frame
	check(page.get_presentation_model().report==report,"Power report displayed unchanged with own execution")
	page.flight_details.set_expanded(true)
	check(page.get_presentation_model().report.root_causes.any(func(cause):return cause.code == "LOW_BATTERY") and "Evidence:" in page.evidence.text and "battery" in page.evidence.text.to_lower(),"Actual power cause retained and readable evidence available in flight details")
	if DisplayServer.get_name()!="headless":
		root.mode=Window.MODE_WINDOWED
		root.min_size=Vector2i(640,480)
		root.size=Vector2i(1280,720)
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("power-report.png"))
	page.queue_free()
	for i in 8: await process_frame
	# All-stock1810g configuration exceeds the actual high_inc small capacity1500g.
	var heavy: Dictionary=power_draft()
	heavy.name="KE3 launcher-capacity1810g rejection"
	heavy.observations=4
	heavy.required_returned_data_mb=30
	heavy.launcher_id="small"
	heavy.launch_profile_id="cubesat_1u_sample"
	heavy.engineering_parts.solar="solar_large"
	heavy.engineering_parts.battery="battery_large"
	var app=load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	for i in 8: await process_frame
	app.state=heavy
	app.show_screen(2)
	for i in 8: await process_frame
	app.current.next_button.pressed.emit()
	for i in 8: await process_frame
	var validation: Dictionary=app.current.validation
	var codes: Array=validation.errors.map(func(e):return e.code)
	check(validation.metrics.total_mass_g==1810 and codes.has("LAUNCHER_CAPACITY_EXCEEDED"),"All-stock1810g actually fails launcher1500g capacity")
	check(codes.has("PROFILE_MASS_EXCEEDED"),"Concurrent1U profile failure explicitly retained")
	check(app.current.next_button.disabled,"Capacity case disables real Launch")
	app.show_screen(4)
	for i in 8: await process_frame
	check(app.current.screen_id=="FlightReadiness" and not app.state.has("run_trace"),"Launcher-capacity failure blocks Operations and creates no run")
	save("launcher-capacity",{"draft":heavy,"config":Runtime.config_for(heavy),"validation":validation,"error_codes":codes,"ui_screen":app.current.screen_id,"scope":"Stock small/high_inc; both profile1330g and launcher1500g exceeded; not falsely attributed to only one rule"})
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("launcher-capacity-block.png"))
	save("checks",{"passed":checks.size()-failed,"failed":failed,"checks":checks,"power_summary":{"run_id":run_a.trace.final_state.run_id,"status":report.get("status"),"score":report.get("score"),"captured":report.get("observations_completed"),"returned_mb":report.get("returned_data_mb"),"required_mb":report.get("required_returned_data_mb"),"low_battery_events":lows.size(),"no_contact_events":no_contact.size(),"events":events.size()},"manual_ui":"NOT TESTED: policy playback only"})
	print("KE3 POWER/CAPACITY: ",checks.size()-failed," passed; ",failed," failed. Actual outcome ",report.get("status")," score ",report.get("score")," low-energy events ",lows.size())
	app.queue_free()
	await process_frame
	quit(1 if failed else 0)
