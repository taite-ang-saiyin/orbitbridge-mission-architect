extends Control
const SCREENS = ["MissionControl", "MissionCreator", "SpacecraftBuilder", "FlightReadiness", "MissionOperations", "DebriefCompare"]
var state = preload("res://data/mock/DesignCatalog.gd").DEFAULTS.duplicate(true)
var preferences = preload("res://scripts/settings/PrototypeSettings.gd").DEFAULTS.duplicate()
var shell: Control
var landing_host: Control
var host: Control
var current: Control
var nav: HBoxContainer
var shell_footer: Label
var sidebar: VBoxContainer
var flow_error: AcceptDialog
var retry_restore: Dictionary = {}
func _ready():
	preload("res://scripts/ui/DesktopWindow.gd").configure(get_window())
	theme = preload("res://ui/theme/WorkbenchTheme.gd").build()
	var bg = TextureRect.new()
	bg.texture = preload("res://assets/ui/backgrounds/home-earth-v1.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var shade = ColorRect.new()
	shade.color = Color(0.005, 0.025, 0.045, 0.70)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin = MarginContainer.new()
	shell = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	var title = Label.new()
	title.text = "OrbitBridge\nMission Architect"
	title.add_theme_font_size_override("font_size", 20)
	var mark = TextureRect.new()
	mark.texture = preload("res://assets/ui/icons/orbit-mark.svg")
	mark.custom_minimum_size = Vector2(46, 46)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var header = HBoxContainer.new()
	layout.add_child(header)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(mark)
	header.add_child(title)
	var status = Label.new()
	status.text = "MISSION CONTROL"
	status.add_theme_color_override("font_color", Color("33e5e9"))
	header.add_child(status)
	var home_button = Button.new()
	home_button.text = "Home"
	home_button.pressed.connect(show_home)
	header.add_child(home_button)
	nav = HBoxContainer.new()
	layout.add_child(nav)
	for i in SCREENS.size():
		var button = Button.new()
		button.text = str(i + 1) + "  " + ["Control", "Mission Creator", "Spacecraft", "Readiness", "Operations", "Debrief"][i]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(show_screen.bind(i))
		nav.add_child(button)
	host = Control.new()
	host.name = "ScreenHost"
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var dashboard = HBoxContainer.new()
	dashboard.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(dashboard)
	var rail = PanelContainer.new()
	rail.custom_minimum_size.x = 172
	dashboard.add_child(rail)
	sidebar = VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 5)
	rail.add_child(sidebar)
	for entry in [["Home", -1], ["New Mission", 1], ["Mission Control", 0], ["Spacecraft Builder", 2], ["Flight Readiness", 3], ["Operations", 4], ["Debrief", 5]]:
		var link = Button.new()
		link.text = entry[0]
		link.alignment = HORIZONTAL_ALIGNMENT_LEFT
		link.custom_minimum_size.y = 42
		link.add_theme_font_size_override("font_size", 15)
		for mode in ["normal", "hover", "disabled"]:
			var style = StyleBoxFlat.new()
			style.bg_color = Color("133341") if mode == "disabled" else (Color("112a38") if mode == "hover" else Color(0,0,0,0))
			style.set_corner_radius_all(7)
			style.content_margin_left = 12
			link.add_theme_stylebox_override(mode, style)
		link.add_theme_color_override("font_disabled_color", Color("a0eeec"))
		if entry[0] == "New Mission": link.pressed.connect(start_new_mission)
		else: link.pressed.connect(show_screen.bind(entry[1]))
		sidebar.add_child(link)
	var rail_spacer = Control.new()
	rail_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(rail_spacer)
	var rail_note = Label.new()
	rail_note.text = "ORBITBRIDGE\nMISSION LAB"
	rail_note.add_theme_color_override("font_color", Color("67a9c4"))
	rail_note.add_theme_font_size_override("font_size", 12)
	sidebar.add_child(rail_note)
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard.add_child(host)
	var footer = Label.new()
	shell_footer = footer
	footer.text = "OrbitBridge · Explore, experiment, learn."
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_theme_font_size_override("font_size", 12)
	layout.add_child(footer)
	landing_host = Control.new()
	landing_host.name = "LandingHost"
	landing_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(landing_host)
	resized.connect(fit_shell)
	fit_shell()
	flow_error = AcceptDialog.new()
	flow_error.title = "Mission check"
	add_child(flow_error)
	show_home()
	if "--verify-demo" in OS.get_cmdline_user_args(): verify_demo.call_deferred()

func fit_shell():
	var padding = 18 if size.x >= 1250 else 12
	for side in ["left", "right", "top", "bottom"]:
		shell.add_theme_constant_override("margin_" + side, padding)
	for button in nav.get_children():
		button.custom_minimum_size.y = 44
		button.add_theme_font_size_override("font_size", 14 if size.x >= 1200 else 13)

func clear_screen():
	if is_instance_valid(current):
		current.get_parent().remove_child(current)
		current.queue_free()
		current = null

func show_home():
	clear_screen()
	shell.hide()
	landing_host.show()
	current = preload("res://scenes/screens/home/Home.tscn").instantiate()
	current.preferences = preferences
	current.start_requested.connect(show_screen.bind(0))
	current.quit_requested.connect(func(): get_tree().quit())
	landing_host.add_child(current)

func show_screen(index: int):
	if index == -1:
		show_home()
		return
	if index < 0 or index >= SCREENS.size(): return
	if index in [1, 2, 3] and is_operating():
		show_flow_error("Finish or stop the current mission before editing its design.")
		return
	if index == 4 and not is_operating():
		var review: Dictionary = preload("res://scripts/integration/mission_runtime.gd").review(state)
		if not review.ready_to_launch:
			show_flow_error("Resolve the readiness checks before launch.")
			if not is_instance_valid(current) or current.screen_id != "FlightReadiness": show_screen(3)
			return
		if not state.has("run_trace") or state.run_trace.config != review.config or state.run_trace.policy != state.policy:
			var launched: Dictionary = preload("res://scripts/integration/mission_runtime.gd").launch(state)
			if not launched.ok:
				show_flow_error(launched.error.message)
				return
	if index == 4 and state.has("run_trace"): state.run_design = state.run_trace.config.duplicate(true)
	if index == 4: retry_restore.clear()
	if index == 5:
		if not state.has("active_run_state") or state.active_run_state.phase != "finished":
			show_flow_error("Finish the mission before viewing a result.")
			return
		on_terminal_state(state.active_run_state)
	clear_screen()
	shell.show()
	landing_host.hide()
	var path = "res://scenes/screens/mission_control/MissionControl.tscn" if index == 0 else "res://scenes/screens/" + SCREENS[index] + ".tscn"
	current = load(path).instantiate()
	current.state = state
	current.navigate.connect(show_screen)
	if current.has_signal("terminal_state"): current.terminal_state.connect(on_terminal_state)
	if current.has_signal("abort_requested"): current.abort_requested.connect(abort_current_run)
	if current.has_signal("retry_requested"): current.retry_requested.connect(retry_mission)
	if current.has_signal("modify_requested"): current.modify_requested.connect(modify_design)
	if current.has_signal("new_mission_requested"): current.new_mission_requested.connect(start_new_mission)
	nav.visible = false
	for i in sidebar.get_child_count():
		var link = sidebar.get_child(i)
		if link is Button: link.disabled = [-1, 1, 0, 2, 3, 4, 5][i] == index
	shell_footer.visible = index not in [1, 2, 3, 4]
	host.add_child(current)
	if not retry_restore.is_empty() and index in [2, 3]:
		var cancel = Button.new()
		cancel.text = "Cancel Retry"
		cancel.pressed.connect(cancel_retry)
		current.previous.get_parent().add_child(cancel)
	for i in nav.get_child_count(): nav.get_child(i).disabled = i == index

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		preload("res://scripts/ui/DesktopWindow.gd").toggle(get_window())
		get_viewport().set_input_as_handled()

func on_terminal_state(native_state: Dictionary) -> Dictionary:
	return preload("res://scripts/integration/mission_results.gd").publish(state, native_state)

func retry_mission() -> void:
	if not retry_restore.is_empty(): return
	if is_operating():
		show_flow_error("Finish or stop the current mission before retrying.")
		return
	var previous: Dictionary = state.get("run_trace", {}).duplicate(true)
	preload("res://scripts/integration/mission_results.gd").retry(state)
	var launched: Dictionary = preload("res://scripts/integration/mission_runtime.gd").launch(state, previous)
	if launched.ok: show_screen(4)
	else: show_flow_error(launched.error.message)

func modify_design() -> void:
	if is_operating():
		show_flow_error("Finish or stop the current mission before modifying its design.")
		return
	if not retry_restore.is_empty() or not state.has("run_trace"): return
	retry_restore = state.duplicate(true)
	state = state.duplicate(true)
	preload("res://scripts/integration/mission_results.gd").retry(state)
	show_screen(2)

func cancel_retry() -> void:
	if retry_restore.is_empty() or is_operating(): return
	state = retry_restore.duplicate(true)
	retry_restore.clear()
	show_screen(5)

func start_new_mission() -> void:
	if is_operating():
		show_flow_error("Finish or stop the current mission before starting a new one.")
		return
	retry_restore.clear()
	preload("res://data/mock/DesignCatalog.gd").reset(state)
	state.name = "Untitled Mission"
	show_screen(1)

func abort_current_run(reason: String = "Operator requested abort") -> void:
	if not state.has("active_run_state"): return
	var recorded: Dictionary = state.get("evaluation_store", {})
	if recorded.get("reports", {}).has(state.active_run_state.run_id) or recorded.get("errors", {}).has(state.active_run_state.run_id):
		show_flow_error("This run is already recorded. Retry it to begin another mission.")
		return
	var aborted: Dictionary = preload("res://core/MissionStepEngine.gd").abort_run(state.active_run_state, reason)
	if not aborted.ok: return
	state.active_run_state = aborted.state.duplicate(true)
	var frames: Array = []
	for frame in state.run_trace.frames:
		if frame.state.step_index < aborted.state.step_index: frames.append(frame)
	frames.append({"state": aborted.state.duplicate(true), "events": aborted.events.duplicate(true)})
	state.run_trace.frames = frames
	state.run_trace.final_state = aborted.state.duplicate(true)
	state.run_trace.events = aborted.state.event_log.duplicate(true)
	for i in state.run_history.size():
		if state.run_history[i].final_state.run_id == aborted.state.run_id: state.run_history[i] = state.run_trace.duplicate(true)
	on_terminal_state(aborted.state)
	show_screen(5)

func is_operating() -> bool:
	return state.get("active_run_state", {}).get("phase") == "operating"

func show_flow_error(message: String) -> void:
	flow_error.dialog_text = message
	flow_error.popup_centered(Vector2i(440, 160))

func begin_new_mission() -> void:
	start_new_mission()

func verify_demo() -> void:
	get_tree().create_timer(90).timeout.connect(func(): printerr("FAIL: Demo verification timed out"); get_tree().quit(1))
	var verifier = preload("res://scripts/verification/demo_verification.gd").new()
	var result: Dictionary = await verifier.run(self)
	if not OS.has_feature("editor"):
		var packaged: Dictionary = verifier.check_packaging()
		print("Windows package checks: %d passed; %d failed." % [packaged.passed, packaged.failed])
		result.passed += packaged.passed
		result.failed += packaged.failed
	print("Windows demo verification: %d checks passed; %d failed." % [result.passed, result.failed])
	get_tree().quit(0 if result.failed == 0 else 1)
