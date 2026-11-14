extends SceneTree
## Player-facing layout/copy and native-input checks; simulation stays provider-owned.
const Verify = preload("res://scripts/verification/demo_verification.gd")
const Language = preload("res://scripts/presentation/PlayerLanguage.gd")
var passed: int = 0
var failed: int = 0
var out: String

func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://exports/player-ui"
	DirAccess.make_dir_recursive_absolute(out)
	create_timer(70).timeout.connect(func(): printerr("FAIL: player UI watchdog"); quit(1))
	call_deferred("run")

func settle() -> void:
	for i in 10: await process_frame

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))

func visible_text(node: Node) -> String:
	if node is CanvasItem and not node.is_visible_in_tree(): return ""
	var result: String = ""
	if node is Label or node is Button: result += node.text + "\n"
	for child in node.get_children(): result += visible_text(child)
	return result

func player_copy(node: Node, label: String) -> void:
	var expression = RegEx.new()
	expression.compile("\\b(?:HPC|KE1|KE2|KE3)\\b|source_ids|SUPPLIED SCOPES")
	check(expression.search(visible_text(node)) == null, label + " has no team/development jargon")

func key(code: Key) -> void:
	for down in [true, false]:
		var event = InputEventKey.new()
		event.keycode = code
		event.pressed = down
		root.push_input(event)
		await process_frame
	await settle()

func run() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	root.mode = Window.MODE_WINDOWED
	root.min_size = Vector2i(640, 480)
	for resolution in [Vector2i(1440,900), Vector2i(1280,720), Vector2i(1024,768), Vector2i(900,680)]:
		Verify.new().fresh(app)
		root.size = resolution
		app.show_screen(4)
		await settle()
		var page = app.current
		check(not page.progress_nav.visible, "Operations removes redundant six-step row " + str(resolution))
		check(not page.flight_details.body.visible and not page.extra_controls.body.visible, "Secondary panels are initially collapsed " + str(resolution))
		check(page.content.size.x <= page.scroll.size.x + 1, "Operations has no horizontal overflow " + str(resolution))
		check(page.photo_value.get_theme_font_size("font_size") >= 28 and page.action_help.get_theme_font_size("font_size") >= 16, "Readable goal/help type " + str(resolution))
		var camera: Camera3D = page.orbit_view.stage.get_node("Camera3D")
		var safe = Rect2(Vector2.ONE * 4, Vector2(page.orbit_view.get_node("SubViewport").size) - Vector2.ONE * 8)
		for point in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
			check(safe.has_point(camera.unproject_position(point * 1.15)), "Earth/orbit framing stays inside panel " + str(resolution) + str(point))
		player_copy(app.shell, "Operations " + str(resolution))
		var input: Dictionary = app.state.active_run_state.duplicate(true)
		page.refresh()
		page.extra_controls.set_expanded(true)
		page.extra_controls.set_expanded(false)
		check(app.state.active_run_state == input, "Disclosure/render does not dispatch or alter native state " + str(resolution))
		check(page.action_buttons.transmit.disabled, "Send data starts disabled without onboard data " + str(resolution))
		page.scroll.ensure_control_visible(page.action_buttons.transmit)
		await settle()
		for down in [true, false]:
			var click = InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = page.action_buttons.transmit.get_global_rect().get_center()
			click.pressed = down
			root.push_input(click)
		await settle()
		check(app.state.active_run_state == input, "Disabled Send data click dispatches zero actions " + str(resolution))
		page.scroll.scroll_vertical = 0
		await settle()
		await capture("operations-" + str(resolution.x))
		var contact_index: int = -1
		for i in page.DATA.frames.size():
			if page.DATA.frames[i].state.available_actions.get("transmit", {}).get("allowed", false):
				contact_index = i
				break
		check(contact_index >= 0, "Real contact-on frame exists " + str(resolution))
		if contact_index >= 0:
			page.select_event(contact_index)
			var before: Dictionary = app.state.active_run_state.duplicate(true)
			page.action_buttons.transmit.grab_focus()
			await settle()
			if not page.scroll.get_global_rect().encloses(page.action_buttons.transmit.get_global_rect().grow(4)):
				print("FOCUS GEOMETRY ", resolution, " scroll=", page.scroll.get_global_rect(), " button=", page.action_buttons.transmit.get_global_rect(), " value=", page.scroll.scroll_vertical, " owner=", root.gui_get_focus_owner().get("text"), " target_focus=", page.action_buttons.transmit.has_focus(), " disabled=", page.action_buttons.transmit.disabled, " connections=", page.action_buttons.transmit.focus_entered.get_connections().size())
			check(page.scroll.get_global_rect().encloses(page.action_buttons.transmit.get_global_rect().grow(4)), "Focused Send data fully visible " + str(resolution))
			check(before == app.state.active_run_state, "Focus dispatches zero actions " + str(resolution))
			await key(KEY_SPACE)
			check(app.state.active_run_state.step_index == before.step_index + 1, "Space on Send data dispatches exactly once " + str(resolution))
			check(app.state.active_run_state.returned_data_mb > before.returned_data_mb, "Native data return changes after enabled send " + str(resolution))
			check(page.data_cells.size() == page.DATA.frames.size(), "Flight data refreshes after a manual action " + str(resolution))
		# Explicit API-only blocked request checks the presentation of a native reply;
		# it is not evidence that the disabled player button dispatches an action.
		for i in page.DATA.frames.size():
			var probe: Dictionary = page.DATA.frames[i].state
			if probe.phase != "operating" or probe.in_ground_contact or probe.stored_data_mb <= 0: continue
			page.select_event(i)
			var before: Dictionary = app.state.active_run_state.duplicate(true)
			page.take_action("transmit")
			check(app.state.active_run_state.step_index == before.step_index and app.state.active_run_state.returned_data_mb == before.returned_data_mb and app.state.active_run_state.energy_wh == before.energy_wh, "Blocked provider request preserves time/resources " + str(resolution))
			check(page._frame_event_name(page.event_index) == "Data transfer blocked", "Blocked transfer is not labelled as data sent " + str(resolution))
			check(page.data_cells[page.event_index][1].text == "Data transfer blocked", "Flight data reflects the blocked native event " + str(resolution))
			break
		page.skip_to_end()
		page.next_button.pressed.emit()
		await settle()
		var result = app.current
		check(result.screen_id == "DebriefCompare", "Actual terminal route reaches results " + str(resolution))
		check(result.content.size.x <= result.report_scroll.size.x + 1, "Results has no horizontal overflow " + str(resolution))
		check(not result.source_disclosure.body.visible, "Sources initially secondary " + str(resolution))
		check(result.results.get_theme_font_size("font_size") >= 18, "Results body is readable " + str(resolution))
		player_copy(app.shell, "Results " + str(resolution))
		var raw: Dictionary = app.state.evaluation_store.reports[app.state.active_run_state.run_id].duplicate(true)
		check(result.get_presentation_model().report == raw, "Displayed report retains exact authoritative snapshot " + str(resolution))
		result.report_scroll.scroll_vertical = 0
		await settle()
		await capture("results-" + str(resolution.x))
		result.source_disclosure.set_expanded(true)
		result.report_scroll.ensure_control_visible(result.credits)
		await settle()
		check(result.source_links.get_child_count() > 0 and "NASA CubeSat 101" in result.credits.text, "Actual readiness credit and accessible reference link " + str(resolution))
		check(app.state.evaluation_store.reports[raw.run_id] == raw, "Credit/disclosure changes preserve report " + str(resolution))
		player_copy(app.shell, "Expanded sources " + str(resolution))
		await capture("sources-" + str(resolution.x))
	check(Language.amount(44.3200000032) == "44.32", "Returned data display rounds to two decimals")
	check(Language.amount(null) == "Not available" and Language.amount(0) == "0", "Missing numeric data does not become zero")
	check(Language.amount(0.001) == "< 0.01", "Small nonzero data is not presented as zero")
	var sample: Dictionary = {"state":"report", "report":{"status":"failed", "run_status":"aborted", "score":null, "root_causes":[]}}
	var cloned: Dictionary = sample.duplicate(true)
	check(Language.report(sample, {}).score == "Not scored" and sample == cloned, "Aborted/null-score display never fabricates a score or mutates input")
	sample.report.run_status = "completed"
	sample.report.score = 0
	check(Language.report(sample, {}).score == "0 / 100", "A legitimate zero score remains zero")
	# A real shortfall uses the same production pipeline, separate from captures above.
	Verify.new().fresh(app)
	app.state.name = "Equator watch"
	app.state.orbit = "LEO – 400 km"
	app.state.duration = 3
	app.state.observations = 4
	app.state.required_returned_data_mb = 30
	root.size = Vector2i(1280,720)
	app.show_screen(4)
	await settle()
	app.current.skip_to_end()
	app.show_screen(5)
	await settle()
	check(app.current.get_presentation_model().report.status == "partial" and app.current.outcome_title.text == "Some goals reached", "Actual shortfall has clear honest partial heading")
	await capture("partial-results-1280")
	app.queue_free()
	await settle()
	print("PLAYER UI: %d passed; %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
