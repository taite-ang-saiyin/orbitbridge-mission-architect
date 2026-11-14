extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Presenter = preload("res://scripts/presentation/DebriefPresentation.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
const HPC = preload("res://core/MissionStepEngine.gd")
var checks: Array = []
var failed: int = 0
var out: String
func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("run")
func check(value: bool, message: String) -> void:
	checks.append({"check":message,"pass":value})
	if not value:
		failed += 1
		print("FAIL ",message)
func save(name: String, data: Variant) -> void:
	var f = FileAccess.open(out.path_join(name+".json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"  "))
func settle() -> void:
	for i in 10: await process_frame
func key(code: Key, shift: bool = false) -> void:
	for pressed in [true,false]:
		var event = InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		event.shift_pressed = shift
		Input.parse_input_event(event)
		await process_frame
	await settle()
func press(node: Node, text: String) -> bool:
	for child in node.get_children():
		if child is Button and child.text == text:
			child.pressed.emit()
			return true
		if press(child,text): return true
	return false
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func history_labels(node: Node) -> Array:
	var labels: Array = []
	if node is GridContainer:
		for child in node.get_children():
			if child is Label: labels.append(child)
	for child in node.get_children(): labels.append_array(history_labels(child))
	return labels
func run() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	root.mode = Window.MODE_WINDOWED
	root.min_size = Vector2i(640,480)
	root.size = Vector2i(1280,720)
	# Set the exact candidate via current SE canonical selectors, then use normal routes.
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/valid_1u_feasible.json"))
	app.state.name = fixture.mission.title
	app.state.observations = int(fixture.mission.required_observations)
	app.state.required_returned_data_mb = fixture.mission.required_returned_data_mb
	app.state.orbit = "Polar – 600 km"
	app.show_screen(1)
	await settle()
	app.current.name_input.text = fixture.mission.title
	app.current.name_input.text_changed.emit(fixture.mission.title)
	app.current.observation_input.value = fixture.mission.required_observations
	app.current.returned_data_input.value = fixture.mission.required_returned_data_mb
	app.current.next_button.pressed.emit()
	await settle()
	check(app.current.screen_id == "SpacecraftBuilder","Actual Creator Continue→Builder")
	for category in ["bus","instrument","solar","battery","radio","storage"]:
		app.current.select_engineering_component(category,fixture.design[category+"_id"])
	app.current.next_button.pressed.emit()
	await settle()
	check(app.current.validation.ready_to_launch and app.current.validation.checks.size() == 8,"Real readiness passes8 checks")
	var validation: Dictionary = app.current.validation.duplicate(true)
	app.current.next_button.pressed.emit()
	await settle()
	check(app.current.screen_id == "MissionOperations","Real Launch→Operations")
	check(app.state.run_trace.validation == validation,"Launch-time validation snapshot matches readiness")
	check(app.state.active_run_state.step_index == 0 and app.state.active_run_state.event_log.is_empty(),"Initial actual state zero history/step")
	var trace: Dictionary = app.state.run_trace.duplicate(true)
	check(not app.state.has("evaluation_store"),"Future precomputed terminal state has not been evaluated early")
	# Every playback frame is bound to HPC. Includes legitimate0 and false values.
	for i in trace.frames.size():
		app.current.select_event(i)
		var state: Dictionary = trace.frames[i].state
		check(app.state.active_run_state == state,"Active snapshot equals HPC frame"+str(i))
		check("Step %s / %s" % [state.step_index,state.total_steps] in app.current.telemetry.text and "Returned %.3f MB" % state.returned_data_mb in app.current.telemetry.text,"HUD step/decimalMB match frame"+str(i))
		for event in trace.frames[i].events:
			check(event.event_id in app.current.details.text,"Selected frame retains raw event ID "+event.event_id)
	check(app.state.evaluation_store.history.size() == 1,"Terminal published once")
	check(trace.events == trace.final_state.event_log,"Ordered accumulated event history intact")
	var last_step: int = -1
	for i in trace.events.size():
		var event: Dictionary = trace.events[i]
		check(event.event_id == "evt_%03d" % i and event.run_id == trace.final_state.run_id and event.step_index >= last_step,"Run-bound event order"+str(i))
		last_step = event.step_index
	var before_store: Dictionary = app.state.evaluation_store.duplicate(true)
	app.current.next_button.pressed.emit()
	await settle()
	var report: Dictionary = app.state.evaluation_store.reports[trace.final_state.run_id].duplicate(true)
	check(app.current.screen_id == "DebriefCompare" and app.current.get_presentation_model().report == report,"Results binds real KE2 reply unchanged")
	check(report.run_id == trace.final_state.run_id and report.observations_completed == trace.final_state.observations_completed and report.returned_data_mb == trace.final_state.returned_data_mb,"KE2 counters match exact run")
	check(str(report.score)+" / 100" in app.current.score_label.text,"Visible score supplied by KE2")
	check(report.source_ids == [] and report.comparison == null,"Optional source_ids/comparison preserved")
	check("Scope: readiness" in app.current.get_presentation_model().credits and "Feedback-vocabulary credit metadata: Unavailable" in app.current.get_presentation_model().credits and "NASA CubeSat 101" in app.current.credits.text,"Actual attribution preserved internally and readable reference displayed")
	save("run-a",{"trace":trace,"report":report,"validation":validation})
	await capture("results-1280")
	app.show_screen(5)
	await settle()
	check(app.state.evaluation_store == before_store,"Results reentry does not republish or duplicate history")
	# Preserve report on missing evidence; reject a stale/mismatched report; preserve score0.
	var fault_store: Dictionary = before_store.duplicate(true)
	var rid: String = trace.final_state.run_id
	fault_store.reports[rid].root_causes = [{"code":"TEST_ONLY","explanation":"Presentation-only missing evidence test","evidence_event_ids":["not-in-this-run"]}]
	fault_store.reports[rid].score = 0
	fault_store.reports[rid].root_causes[0].evidence_event_ids = [trace.events[1].event_id]
	check("Evidence: %s | Step %s" % [trace.events[1].event_id,trace.events[1].step_index] in Presenter.build(trace,fault_store).text,"Evidence resolves provider ID and canonical step")
	fault_store.reports[rid].root_causes[0].evidence_event_ids = ["not-in-this-run"]
	var model: Dictionary = Presenter.build(trace,fault_store)
	check(model.state == "report" and "Score: 0" in model.text and "Evidence Unavailable: not-in-this-run" in model.text,"Missing link retains readable report and zero score")
	model.report.source_ids.append("caller-edit")
	check(fault_store.reports[rid].source_ids.is_empty(),"Presentation getter returns independent report copy")
	fault_store.reports[rid].run_id = "old-run"
	check(Presenter.build(trace,fault_store).state == "stale_report","Stale run report rejected")
	fault_store = before_store.duplicate(true)
	fault_store.reports[rid].mission_id = "old-mission"
	check(Presenter.build(trace,fault_store).state == "stale_report","Mismatched mission report rejected")
	var error_reply: Dictionary = Results.publish({},trace.final_state,func(_state): return {"ok":true,"report":{"run_id":"stale","mission_id":"stale"}})
	check(not error_reply.ok and error_reply.error.code == "STALE_EVALUATION","Publication rejects stale evaluator reply")
	var missing: Dictionary = trace.duplicate(true)
	missing.final_state.erase("energy_wh")
	check("Unavailable Wh" in Presenter.build(missing,before_store).text,"Missing optional battery is Unavailable, not zero")
	check(Presenter.text(false) == "false" and Presenter.text(0) == "0","Valid false and zero retained")
	# Optional metadata wrapper: test-only supplied scope, never inserted into report fields.
	var metadata_store: Dictionary = before_store.duplicate(true)
	metadata_store.history[0].source_credit_metadata = {"applicable_source_credits":[{"credit_scope":"feedback_vocabulary","title":"TEST supplied vocabulary credit","url":"https://example.invalid/test-only","attribution_text":"TEST fixture metadata","actual_use":"TEST report vocabulary"}]}
	check("Scope: feedback_vocabulary" in Presenter.build(trace,metadata_store).credits and metadata_store.reports[rid] == report,"Supplied scoped metadata displays without altering report")
	# Long-content keyboard/layout checks on real Results at all requested sizes.
	for resolution in [Vector2i(1280,720),Vector2i(1024,768),Vector2i(900,680)]:
		root.size = resolution
		app.state.evaluation_store.reports[rid].explanation = "Long presentation test. ".repeat(700)
		app.show_screen(5)
		await settle()
		var page = app.current
		var preserved: Dictionary = page.get_presentation_model()
		page.select_report_tab(1)
		await settle()
		for label in history_labels(page): check(label.size.y <= 30,"History cell readable "+str(resolution)+" "+label.text)
		page.select_report_tab(1)
		await settle()
		check(page.content.size.x <= page.report_scroll.size.x+1,"No Results horizontal overflow "+str(resolution))
		page.report_scroll.grab_focus()
		if resolution.x == 900: await capture("focused-report-900")
		await key(KEY_PAGEDOWN)
		check(page.report_scroll.scroll_vertical > 0,"Focused PageDown scrolls "+str(resolution))
		await key(KEY_PAGEUP)
		check(page.report_scroll.scroll_vertical == 0,"Focused PageUp returns "+str(resolution))
		await key(KEY_DOWN)
		check(page.report_scroll.scroll_vertical > 0,"Focused Down scrolls "+str(resolution))
		await key(KEY_UP)
		check(page.report_scroll.scroll_vertical == 0,"Focused Up returns "+str(resolution))
		await key(KEY_TAB)
		check(root.gui_get_focus_owner() != page.report_scroll,"Tab exits report region "+str(resolution))
		await key(KEY_TAB,true)
		check(root.gui_get_focus_owner() == page.report_scroll,"ShiftTab returns report focus "+str(resolution))
		page.report_tabs.grab_focus()
		await key(KEY_RIGHT)
		check(page.report_tabs.current_tab == 2 and page.credits.is_visible_in_tree(),"Keyboard opens Sources tab "+str(resolution))
		check(page.get_presentation_model() == preserved,"Scrolling/focus preserves report values "+str(resolution))
		await capture("long-results-"+str(resolution.x))
	app.state.evaluation_store = before_store.duplicate(true)
	root.size = Vector2i(1280,720)
	app.show_screen(5)
	await settle()
	# Retry is a single intent into existing controller, now staged for editable review.
	var button: Button = app.current.retry_button
	button.grab_focus()
	await key(KEY_SPACE)
	check(app.current.screen_id == "SpacecraftBuilder" and not app.retry_restore.is_empty(),"Keyboard Retry opens editable owned draft")
	var pending: Dictionary = app.state.duplicate(true)
	app.retry_mission()
	check(app.state == pending,"Duplicate pending Retry does not dispatch again")
	app.current.select_engineering_component("instrument","instrument_advanced")
	app.current.next_button.pressed.emit()
	await settle()
	check(app.current.next_button.disabled,"Invalid retry draft is blocked before Operations")
	check(press(app.current,"Cancel Retry"),"Cancel Retry available after blocked review")
	await settle()
	check(app.current.screen_id == "DebriefCompare" and app.state.run_trace == trace and app.state.evaluation_store == before_store,"Cancel restores original completed run/report exactly")
	app.current.retry_button.grab_focus()
	await key(KEY_ENTER)
	check(app.current.screen_id == "SpacecraftBuilder","Enter activates Retry once")
	await capture("retry-edit")
	app.current.select_engineering_component("radio","radio_fast")
	app.current.next_button.pressed.emit()
	await settle()
	check(not app.current.next_button.disabled,"Edited radio passes real readiness")
	app.current.next_button.pressed.emit()
	await settle()
	var b: Dictionary = app.state.run_trace.duplicate(true)
	check(b.config.mission == trace.config.mission,"Retry holds mission requirements fixed")
	var changed: Array = []
	for field in trace.config.design:
		if b.config.design[field] != trace.config.design[field]: changed.append(field)
	check(changed == ["radio_id"],"Exactly one canonical radio field changed")
	check(b.final_state.run_id != rid and app.state.active_run_state.step_index == 0 and app.state.active_run_state.event_log.is_empty() and app.state.active_run_state.observations_completed == 0,"Distinct RunB starts fresh")
	check(app.state.run_history[0] == trace and app.state.evaluation_store.reports[rid] == report,"RunA snapshot/report remain immutable")
	# Focus alone cannot advance playback or request an HPC action.
	root.size = Vector2i(900,680)
	await settle()
	var page = app.current
	page.show_log()
	await settle()
	check(page.event_header.get_child(0).size.y<=30,"900px event heading readable without character columns")
	page.log_dialog.hide()
	await settle()
	for control in [page.play_button,page.step_button,page.skip_button]:
		if control.disabled: continue

		var retained: Dictionary = app.state.active_run_state.duplicate(true)
		control.grab_focus()
		await settle()
		check(app.state.active_run_state == retained,"Operations focus dispatches zero actions "+control.text)
		if page.scroll.is_ancestor_of(control): check(page.scroll.get_global_rect().encloses(control.get_global_rect().grow(4)),"Operations focused outline visible "+control.text)
	await capture("operations-900")
	app.current.skip_to_end()
	app.current.next_button.pressed.emit()
	await settle()
	var b_report: Dictionary = app.state.evaluation_store.reports[b.final_state.run_id]
	check(app.current.get_presentation_model().report == b_report and b_report.run_id == b.final_state.run_id,"Second Results owns second real KE2 report")
	var retained_model: Dictionary = app.current.get_presentation_model()
	app.on_terminal_state(trace.final_state)
	app.current.show_actual_run(app.current.result_history().size()-1)
	check(app.current.get_presentation_model() == retained_model,"Late RunA publication cannot replace RunB Debrief")
	save("run-b",{"trace":b,"report":b_report,"changed_fields":changed})
	await capture("second-results")
	# Separate engine probe, excluded from both UI-run histories.
	for frame in trace.frames:
		if frame.state.phase == "operating" and not frame.state.in_ground_contact and frame.state.stored_data_mb > 0:
			var before: Dictionary = frame.state.duplicate(true)
			var rejected: Dictionary = HPC.request_action(before,"transmit")
			check(rejected.ok and not rejected.allowed and rejected.events[0].code == "NO_LINK_WINDOW","Separate engine no-contact rejection")
			for field in ["step_index","energy_wh","stored_data_mb","returned_data_mb","observations_completed"]: check(before[field] == rejected.state[field],"Rejected request unchanged "+field)
			save("separate-no-contact-probe",{"before":before,"reply":rejected})
			break
	save("checks",{"passed":checks.size()-failed,"failed":failed,"checks":checks,"run_ids":[rid,b.final_state.run_id],"manual_actions":"NOT TESTED: policy playback only","browser_human":"NOT TESTED"})
	print("KE3 TEAM CHECK: ",checks.size()-failed," passed; ",failed," failed; ",rid," → ",b.final_state.run_id)
	app.queue_free()
	await process_frame
	quit(1 if failed else 0)
