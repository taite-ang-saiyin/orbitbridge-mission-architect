extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Review = preload("res://scripts/integration/mission_review.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
const Lab = preload("res://scripts/integration/design_lab.gd")
var id: String
var out: String
var checks: Array = []
var runs: Array = []
var failures: int = 0
var requested: String = ""
func _initialize():
	var args=OS.get_cmdline_user_args()
	if not args.is_empty() and args[0] in ["communication","weather_monitoring"]:
		requested=args[0]
		out=args[1]
	else:
		var folder: String=args[0] if not args.is_empty() else "res://exports/new-missions-e2e"
		DirAccess.make_dir_recursive_absolute(folder)
		out=folder.path_join("new-missions-e2e.json")
	create_timer(300).timeout.connect(func(): push_error("E2E watchdog timeout"); quit(2))
	run.call_deferred()
func save():
	var f=FileAccess.open(out,FileAccess.WRITE)
	f.store_string(JSON.stringify({"mission":id,"passed":checks.size()-failures,"failed":failures,"checks":checks,"runs":runs},"  "))
func check(ok: bool,label: String):
	checks.append({"mission":id,"pass":ok,"check":label})
	if not ok: failures+=1; printerr("FAIL: ",id,": ",label)
	save()
func settle():
	for i in 5: await process_frame
func button(node: Node,text: String) -> Button:
	for item in node.find_children("*","Button",true,false):
		if item.text==text:return item
	return null
func finish(app):
	app.current.skip_to_end()
	await settle()
	app.current.next_button.pressed.emit()
	await settle()
	check(app.current.screen_id=="DebriefCompare","Operations View results reaches Debrief")
func facts(app,label: String):
	var s: Dictionary=app.state.active_run_state
	var p: Dictionary=app.current.get_goal_progress()
	var m: Dictionary=app.current.get_presentation_model()
	runs.append({"case":label,"run_id":s.run_id,"config":app.state.run_trace.config,"captures":s.observations_completed,"returned_data_mb":s.returned_data_mb,"goal_progress":s.get("goal_progress",{}),"displayed_goal":p,"presentation_state":m.state,"score":m.get("report",{}).get("score"),"headline":app.current.outcome_title.text,"badge":app.current.outcome_badge.text,"results":app.current.results.text})
	save()
func run():
	for mission in [requested] if not requested.is_empty() else ["communication","weather_monitoring"]:
		id=mission
		await run_mission()
	print("New mission E2E: ",checks.size()-failures," checks passed; ",failures," failed")
	quit(0 if failures==0 else 1)
func run_mission():
	var title: String="Communication" if id=="communication" else "Weather Monitoring"
	var app=load("res://scenes/Main.tscn").instantiate()
	root.add_child(app);await settle()
	app.show_screen(0);await settle()
	app.current.presets[title].pressed.emit();await settle()
	check(app.current.screen_id=="MissionCreator" and app.state.preset_id==id,"Mission card selects matching Creator preset")
	check(Runtime.config_for(app.state).schema_version==2 and Runtime.config_for(app.state).mission.objective==id,"Config v2 keeps the correct objective")
	app.current.next_button.pressed.emit();await settle()
	check(app.current.review_dialog.visible and app.current.review_dialog.continue_button.disabled,"Creator requires mission review")
	app.current.review_dialog.acknowledgement.button_pressed=true
	app.current.review_dialog.continue_button.pressed.emit();await settle()
	check(app.current.screen_id=="SpacecraftBuilder","Reviewed Creator enters Builder")
	app.current.select_engineering_component("instrument","instrument_advanced")
	check(app.current.next_button.disabled and not Runtime.review(app.state).ready_to_launch,"Heavy camera cannot bypass the mass limit")
	app.current.select_engineering_component("instrument","instrument_basic")
	check(not app.current.next_button.disabled,"Restoring basic camera restores readiness")
	app.current.next_button.pressed.emit();await settle()
	check(app.current.screen_id=="FlightReadiness" and not app.current.next_button.disabled,"Builder reaches passing Flight Readiness")
	check(app.current.validation.metrics.total_mass_g==(1120 if id=="communication" else 1060),"Correct starter mass")
	check(app.current.validation.metrics.total_cost_credits==(89 if id=="communication" else 82),"Correct starter cost")
	var config: Dictionary=Runtime.config_for(app.state).duplicate(true)
	app.current.next_button.pressed.emit();await settle()
	check(app.current.screen_id=="MissionOperations" and app.state.active_run_state.config_snapshot==config,"Launch enters native Operations with frozen v2 goals")
	check(not app.state.has("evaluation_store"),"Future policy playback is not evaluated before completion")
	app.current.pause();app.current.step();await settle()
	var paused: Dictionary=app.state.active_run_state.duplicate(true)
	app.return_to_start();await settle();app.resume_from_start();await settle()
	check(app.current.screen_id=="MissionOperations" and not app.current.playing and app.state.active_run_state==paused,"Home and Resume preserve the paused native state")
	await finish(app)
	facts(app,"default_starter")
	var progress: Dictionary=app.current.get_goal_progress()
	check(app.state.active_run_state.returned_data_mb==24.0,"Default starter returns its actual 24 MB")
	check(progress.primary.known and progress.primary.actual==2,"Default goal count matches native evidence")
	check(app.current.get_presentation_model().state=="report" and app.current.get_presentation_model().report.score==100,"Both starter goals earn the agreed score of 100")
	app.current.open_design_lab();await settle()
	check(app.current.design_lab.get_model().a.execution_key==Results.input_key(app.state.run_trace) and app.current.design_lab.get_model().b.is_empty(),"First flight is unsaved A, with no B")
	check(app.current.design_lab.cells.returned_data_mb[1].text=="-","Empty B values use a dash")
	var a_key: String=Results.input_key(app.state.run_trace)
	app.current.design_lab.save_button.pressed.emit();await settle()
	check(app.get_saved_design_a().execution.execution_key==a_key,"Save A stores this exact completed execution")
	app.get_node("DesignASavedDialog").canceled.emit();await settle()
	var original: Dictionary=app.get_saved_design_a().execution.duplicate(true)
	check(app.continue_saved_design_a().ok,"Not now preserves A and allows Continue B")
	await settle()
	button(app.current,"Cancel Design B").pressed.emit();await settle()
	check(app.current.get_presentation_model().execution_key==a_key and app.get_saved_design_a().execution==original,"Cancel B restores unchanged A")
	check(app.continue_saved_design_a().ok,"Create another B draft")
	await settle()
	app.current.select_engineering_component("radio","radio_basic" if id=="communication" else "radio_fast")
	app.current.next_button.pressed.emit();await settle()
	check(app.current.screen_id=="FlightReadiness" and not app.current.next_button.disabled,"Edited B passes its own readiness")
	app.current.next_button.pressed.emit();await settle()
	check(app.state.active_run_state.run_id!=original.run_id and app.state.active_run_state.step_index==0 and app.state.active_run_state.event_log.is_empty(),"B starts with a distinct run ID and clean counters")
	check(app.state.run_trace.config.mission==original.trace.config.mission,"B keeps A's frozen mission requirements")
	await finish(app)
	check(app.current.report_tabs.current_tab==3 and app.current.design_lab.get_model().state=="comparison","B automatically opens the actual A/B comparison")
	var comparison: Dictionary=app.current.design_lab.get_model().comparison
	check(comparison.a_execution_key==a_key and comparison.b_execution_key==Results.input_key(app.state.run_trace),"Comparison binds both exact executions")
	check(comparison.metrics.returned_data_mb.delta==comparison.metrics.returned_data_mb.b-comparison.metrics.returned_data_mb.a,"Returned data delta is B minus A")
	check(comparison.scored and comparison.metrics.score.a==100 and comparison.metrics.score.b==100,"Comparison uses both published mission scores")
	check(app.get_saved_design_a().execution==original,"Completing B never overwrites A")
	app.current.select_report_tab(0);await settle()
	var b_config: Dictionary=app.state.run_trace.config.duplicate(true)
	var b_id: String=app.state.active_run_state.run_id
	app.current.same_mission_button.pressed.emit();await settle()
	check(app.current.screen_id=="MissionOperations" and app.state.run_trace.config==b_config and app.state.active_run_state.run_id!=b_id,"Retry same mission preserves v2 configuration with a fresh run ID")
	check(app.state.active_run_state.step_index==0 and app.state.active_run_state.event_log.is_empty(),"Retry resets all native counters and events")
	await finish(app)
	check(app.get_saved_design_a().execution==original,"Rerunning B preserves saved A")
	var before_edit: Dictionary=app.state.duplicate(true)
	app.current.retry_button.pressed.emit();await settle()
	app.current.select_engineering_component("instrument","instrument_advanced")
	check(app.current.next_button.disabled,"An invalid modified retry remains blocked")
	button(app.current,"Cancel Retry").pressed.emit();await settle()
	check(app.state==before_edit,"Cancel Retry restores the full original result and session")
	app.current.same_mission_button.pressed.emit();await settle()
	app.abort_current_run("New mission E2E abort control");await settle()
	check(app.state.active_run_state.run_status=="aborted","Abort records an aborted native run")
	check(not Lab.eligible(app.state,Results.input_key(app.state.run_trace)).ok,"Aborted flight cannot be saved or compared")
	check("stop" in app.current.outcome_title.text.to_lower() or "abort" in app.current.outcome_title.text.to_lower() or "STOPPED" in app.current.outcome_badge.text,"Aborted new mission is visibly labelled as stopped, not complete")
	facts(app,"aborted")
	app.start_new_mission();await settle()
	check(not app.state.has("design_lab") and not app.state.has("evaluation_store") and not app.state.has("goal"),"New Mission clears comparison, results and old v2 goal")
	for kind in ["goal_met","count_shortfall","no_delivery"]:
		app.show_screen(0);await settle()
		app.current.presets[title].pressed.emit();await settle()
		check(Review.confirm(app.state,Review.snapshot(app.state)),kind+": confirm supplied mission")
		var observe: Array=[1,6] if id=="communication" else [1,11]
		if kind=="count_shortfall": observe=[1] if id=="communication" else [1,6]
		var plan: Array=[]
		for step in 30:
			plan.append({"step_index":step,"action":"observe" if step in observe else ("transmit" if step in [7,10,17,20,27] and kind!="no_delivery" else "power_save")})
		var launch: Dictionary=Runtime.launch(app.state,{}, {"action_plan":plan})
		check(launch.ok,kind+": controlled action plan launches through native validation")
		if not launch.ok: continue
		app.show_screen(4);await settle();await finish(app)
		facts(app,kind)
		var p: Dictionary=app.current.get_goal_progress()
		check(p.primary.known and p.data.known,kind+": same-run goal evidence is available")
		var expected_count: int=0 if id=="communication" and kind=="no_delivery" else (1 if kind=="count_shortfall" else 2)
		check(p.primary.actual==expected_count,kind+": independent qualifying count is correct")
		check(p.primary.reached==(expected_count>=2),kind+": count verdict matches qualifying events")
		check(p.data.reached==(kind!="no_delivery"),kind+": data verdict does not depend on count")
		var expected_score: int=100 if kind=="goal_met" else (75 if kind=="count_shortfall" else (0 if id=="communication" else 50))
		check(app.current.get_presentation_model().report.score==expected_score,kind+": exact goal-specific score")
		if id=="weather_monitoring" and kind!="count_shortfall":check(app.state.active_run_state.goal_progress.qualifying_revolution_indices==[0,1],kind+": visits belong to distinct zero-based orbits")
		app.start_new_mission();await settle()
	app.queue_free();await settle()
	save()
	print("TARGETED E2E ",id,": ",checks.size()-failures," passed; ",failures," failed")
