extends SceneTree
const Runtime=preload("res://scripts/integration/mission_runtime.gd")
const Results=preload("res://scripts/integration/mission_results.gd")
const Catalog=preload("res://data/mock/DesignCatalog.gd")
const Validator=preload("res://scripts/core/mission_validator.gd")
const HPC=preload("res://core/MissionStepEngine.gd")
const Presenter=preload("res://scripts/presentation/DebriefPresentation.gd")
var out: String
var count: int=0
var failed: int=0
var checks: Array=[]
func _initialize() -> void:
	out=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("run")
func check(value: bool,message: String) -> void:
	count+=1
	checks.append({"pass":value,"check":message})
	if not value:
		failed+=1
		print("FAIL ",message)
func save(name: String,data: Variant) -> void:
	var f=FileAccess.open(out.path_join(name+".json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"  "))
func draft_for(orbit: String,duration: int,goal: int) -> Dictionary:
	var draft: Dictionary=Catalog.DEFAULTS.duplicate(true)
	Catalog.ensure(draft)
	draft.name="Valid 1U feasible baseline"
	draft.observations=4
	draft.required_returned_data_mb=goal
	draft.orbit=orbit
	draft.duration=duration
	draft.policy="Observe First"
	return draft
func normalize_trace(trace: Dictionary) -> Dictionary:
	var copied: Dictionary=trace.duplicate(true)
	copied.final_state.erase("run_id")
	copied.final_state.erase("mission_id")
	copied.erase("frames")
	for field in ["evaluation_key","evaluation","result_context"]: copied.erase(field)
	copied.final_state.erase("event_log")
	for event in copied.events:
		event.erase("run_id")
		event.erase("mission_id")
	return copied
func run() -> void:
	var definitions: Array=[
		["goals-met","Polar – 600 km",6,30,100],
		["low_eq_3orbits","LEO – 400 km",3,30,87],
		["return_goal_60mb","Polar – 600 km",6,60,90]]
	var launched_cases: Array=[]
	for definition in definitions:
		var draft: Dictionary=draft_for(definition[1],definition[2],definition[3])
		var launched: Dictionary=Runtime.launch(draft)
		check(launched.ok,definition[0]+" real validated launch")
		var trace: Dictionary=launched.trace
		var original: Dictionary=trace.duplicate(true)
		var reply: Dictionary=Results.evaluate_trace(trace)
		check(reply.ok and reply.report.score==definition[4],definition[0]+" fresh KE2 score")
		check(reply.report.run_id==trace.final_state.run_id and reply.report.required_returned_data_mb==definition[3],definition[0]+" own run/goals")
		check(reply.report.root_causes==[] and reply.report.source_ids==[] and reply.report.comparison==null,definition[0]+" neutral report unchanged")
		check(trace.config==original.config and trace.events==original.events and trace.final_state==original.final_state,definition[0]+" evaluator adapter retains source snapshots")
		check(trace.events==trace.final_state.event_log and trace.final_state.step_index==trace.final_state.total_steps,definition[0]+" ordered full duration evidence")
		var before: Dictionary=trace.duplicate(true)
		check(Results.evaluate_trace(trace)==reply and trace==before,definition[0]+" deterministic repeat evaluation")
		var second: Dictionary=Runtime.launch(draft_for(definition[1],definition[2],definition[3])).trace
		check(normalize_trace(trace)==normalize_trace(second),definition[0]+" same config/actions reproduce physics/history excluding new identity/cache")
		if definition[0]!="goals-met":
			var folder: String=OS.get_cmdline_user_args()[1].path_join(definition[0])
			var archived_config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("config.json")))
			var archived_events: Array=JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("events.json")))
			check(JSON.parse_string(JSON.stringify(trace.config))==archived_config,definition[0]+" fresh config equals archived candidate")
			var schedule: Array=[]
			var archived_schedule: Array=[]
			for event in trace.events: schedule.append([event.step_index,event.action,event.type])
			for event in archived_events: archived_schedule.append([event.step_index,event.action,event.type])
			check(JSON.parse_string(JSON.stringify(schedule))==archived_schedule,definition[0]+" fresh action schedule equals archived sequence (JSON numeric normalization)")
		save(definition[0],{"trace":trace,"report":reply.report,"execution_key":Results.input_key(trace)})
		launched_cases.append({"case_id":definition[0],"run_id":trace.final_state.run_id,"execution_key":Results.input_key(trace),"score":reply.report.score,"captured":reply.report.observations_completed,"returned_mb":reply.report.returned_data_mb})
	# Actual mass boundary through public validator and matching catalog clone.
	var loaded: Dictionary=Runtime.load_game_catalogs()
	var config: Dictionary=Runtime.config_for(draft_for("Polar – 600 km",6,30))
	for mass in [1329,1330]:
		var catalogs: Dictionary=loaded.catalogs.duplicate(true)
		for part in catalogs.components:
			if part.id=="bus_basic": part.mass_g+=mass-1060
		var validated: Dictionary=Validator.validate(config,catalogs)
		check(validated.metrics.total_mass_g==mass and validated.checks.profile_mass.passed==(mass==1329),"Strict executed mass boundary "+str(mass))
		save("mass-"+str(mass),validated)
	var app=load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	for i in 8: await process_frame
	for definition in definitions:
		app.state=draft_for(definition[1],definition[2],definition[3])
		app.show_screen(1)
		for i in 8: await process_frame
		# Acknowledge fixture mission intent; engineering checks still run.
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.current.next_button.pressed.emit()
		if app.current.screen_id == "MissionCreator" and is_instance_valid(app.current.review_dialog) and app.current.review_dialog.visible:
			app.current.review_dialog.acknowledgement.button_pressed = true
			app.current.review_dialog.continue_button.pressed.emit()
		for i in 8: await process_frame
		check(app.current.screen_id=="SpacecraftBuilder",definition[0]+" fresh Creator→Builder")
		# Acknowledge fixture mission intent; engineering checks still run.
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.current.next_button.pressed.emit()
		if app.current.screen_id == "MissionCreator" and is_instance_valid(app.current.review_dialog) and app.current.review_dialog.visible:
			app.current.review_dialog.acknowledgement.button_pressed = true
			app.current.review_dialog.continue_button.pressed.emit()
		for i in 8: await process_frame
		check(app.current.screen_id=="FlightReadiness" and not app.current.next_button.disabled,definition[0]+" fresh actual Readiness gate")
		# Acknowledge fixture mission intent; engineering checks still run.
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.current.next_button.pressed.emit()
		if app.current.screen_id == "MissionCreator" and is_instance_valid(app.current.review_dialog) and app.current.review_dialog.visible:
			app.current.review_dialog.acknowledgement.button_pressed = true
			app.current.review_dialog.continue_button.pressed.emit()
		for i in 8: await process_frame
		check(app.current.screen_id=="MissionOperations",definition[0]+" fresh Operations route")
		app.current.skip_to_end()
		# Acknowledge fixture mission intent; engineering checks still run.
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.current.next_button.pressed.emit()
		if app.current.screen_id == "MissionCreator" and is_instance_valid(app.current.review_dialog) and app.current.review_dialog.visible:
			app.current.review_dialog.acknowledgement.button_pressed = true
			app.current.review_dialog.continue_button.pressed.emit()
		for i in 8: await process_frame
		var model: Dictionary=app.current.get_presentation_model()
		check(model.state=="report" and model.report.score==definition[4] and model.report.run_id==app.state.active_run_state.run_id,definition[0]+" fresh UI own matching KE2 report")
		save(definition[0]+"-ui",{"state":app.state.active_run_state,"trace":app.state.run_trace,"model":model,"execution_key":Results.input_key(app.state.run_trace)})
		if DisplayServer.get_name()!="headless":
			root.mode=Window.MODE_WINDOWED
			root.size=Vector2i(1280,720)
			for i in 8: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join(definition[0]+"-ui.png"))
	app.state=draft_for("Polar – 600 km",6,30)
	app.state.engineering_parts={"instrument":"instrument_advanced"}
	app.show_screen(4)
	for i in 8: await process_frame
	check(app.current.screen_id=="FlightReadiness" and app.current.next_button.disabled and not app.state.has("run_trace"),"1380g heavy fixture gates Operations")
	check(app.current.validation.checks.profile_mass.status=="fail" and app.current.validation.checks.launcher_capacity.status=="pass","Heavy case fails profile not launcher1500g")
	save("heavy-gate",app.current.validation)
	var survey: Dictionary=draft_for("Polar – 600 km",6,30)
	survey.objective="Survey Target Regions"
	var survey_run: Dictionary=Runtime.launch(survey)
	check(survey_run.ok,"SE Survey still validates and simulates")
	var survey_reply: Dictionary=Results.evaluate_trace(survey_run.trace)
	check(not survey_reply.ok and survey_reply.error.field_path=="config.mission.objective","Actual KE2 explicit Survey unsupported")
	save("survey",{"validation":survey_run.trace.validation,"state":survey_run.trace.final_state,"evaluation":survey_reply})
	# Low battery is an independent component probe, not the unavailable full failure case.
	var state: Dictionary=launched_cases[0] # replaced below by real copied initial frame
	var seed: Dictionary=Runtime.launch(draft_for("Polar – 600 km",6,30)).trace
	for frame in seed.frames:
		if frame.state.step_index==1:
			state=frame.state.duplicate(true)
			break
	state.energy_wh=0.0
	var blocked: Dictionary=HPC.request_action(state,"observe")
	check(blocked.ok and not blocked.allowed and blocked.events[0].code=="LOW_BATTERY","Real low-energy request blocked")
	check(blocked.state.energy_wh==state.energy_wh and blocked.state.step_index==state.step_index and blocked.state.observations_completed==state.observations_completed,"Low-energy block unchanged resources/step")
	save("separate-low-energy-probe",{"before":state,"reply":blocked,"scope":"Injected energy on copied real frame; NOT a UI-run history or validated full power failure"})
	# Independent component run with an actual rejected request. Never add this
	# deliberate request to the normal policy/UI runs above.
	var started: Dictionary=HPC.init_validated_run(config,loaded.catalogs,"component_blocked_credit_probe","component_probe_mission")
	check(started.ok,"Separate blocked-evidence run uses actual validated entry")
	var current: Dictionary=started.state
	var rejected_once: bool=false
	while current.phase=="operating":
		var action: String="power_save"
		if current.step_index==1: action="observe"
		elif current.step_index==7: action="transmit"
		elif current.step_index==8 and not rejected_once:
			action="transmit"
			rejected_once=true
		var step: Dictionary=HPC.request_action(current,action)
		current=step.state
	var component: Dictionary={"config":config,"final_state":current,"events":current.event_log.duplicate(true),"validation":started.validation_result.duplicate(true)}
	component.validation.config=config.duplicate(true)
	var component_reply: Dictionary=Results.evaluate_trace(component)
	check(component_reply.ok and component_reply.report.root_causes.size()==1 and component_reply.report.root_causes[0].evidence_event_ids==["evt_008"],"Fresh separate component report resolves actual no-contact cause")
	var component_store: Dictionary={"run_history":[component]}
	var published: Dictionary=Results.publish(component_store,current)
	check(published.ok,"Actual blocked-evidence report publishes")
	var component_model: Dictionary=Presenter.build(component,component_store.evaluation_store)
	check("Scope: feedback_vocabulary" in component_model.credits and "Scope: readiness" in component_model.credits,"Real ledger credits both actual readiness and emitted feedback vocabulary")
	check("evt_008 | Step 8" in component_model.text,"Real component evidence links canonical step")
	component_store.evaluation_store.reports[current.run_id].mission_id="stale"
	var rejected_model: Dictionary=Presenter.build(component,component_store.evaluation_store)
	check(rejected_model.state=="stale_report" and not "Scope: feedback_vocabulary" in rejected_model.credits and "Scope: readiness" in rejected_model.credits,"Real scoped credit removed with rejected report while readiness retained")
	save("separate-component-feedback",{"trace":component,"report":component_reply.report,"accepted_model":component_model,"rejected_model":rejected_model,"scope":"Separate actual component request sequence; NOT part of any UI-run history"})
	save("summary",{"passed":count-failed,"failed":failed,"checks":checks,"fresh_cases":launched_cases,"full_power_failure":"WAITING ON INPUT: validated config/catalog/scenario/full terminal trace needed"})
	print("KE3 CHECKPOINT CASES: ",count-failed," passed; ",failed," failed")
	app.queue_free()
	await process_frame
	quit(1 if failed else 0)
