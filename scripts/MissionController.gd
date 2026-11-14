extends Control
const SCREENS = ["MissionControl", "MissionCreator", "SpacecraftBuilder", "FlightReadiness", "MissionOperations", "DebriefCompare"]
const Workflow = preload("res://scripts/integration/mission_workflow.gd")
var state = Workflow.new_draft()
var flow_error: AcceptDialog
var preferences = preload("res://scripts/settings/PrototypeSettings.gd").DEFAULTS.duplicate()
var shell: Control
var landing_host: Control
var host: Control
var current: Control
var nav: HBoxContainer
var shell_footer: Label
var sidebar: VBoxContainer
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
	status.text = "◉  MISSION CONTROL     •     TRAINING SIMULATOR"
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
	sidebar.add_theme_constant_override("separation", 12)
	rail.add_child(sidebar)
	for entry in [["⌂  Home", -1], ["＋  New Mission", 1], ["◉  Mission Control", 0], ["◇  Spacecraft Builder", 2], ["✓  Flight Readiness", 3], ["▷  Operations", 4], ["≡  Debrief", 5]]:
		var link = Button.new()
		link.text = entry[0]
		link.alignment = HORIZONTAL_ALIGNMENT_LEFT
		link.custom_minimum_size.y = 46
		if entry[0] == "＋  New Mission":
			link.pressed.connect(begin_new_mission)
		else:
			link.pressed.connect(show_screen.bind(entry[1]))
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
	footer.text = "ILLUSTRATIVE TRAINING MODEL   •   OrbitBridge Mission Lab"
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
	if "--verify-demo" in OS.get_cmdline_user_args():
		verify_demo.call_deferred()

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
	if index < 0 or index >= SCREENS.size():
		return
	# Guard every entry route, including sidebar and progress navigation.
	if index in [1, 2, 3] and Workflow.is_operating(state):
		show_flow_error("Finish or stop the current mission before editing its design.")
		return
	if index == 4 and state.get("active_run", {}).is_empty():
		var started: Dictionary = Workflow.start_run(state)
		if not started.ok:
			show_flow_error(started.error.message)
			return
	if index == 5:
		var evaluated: Dictionary = Workflow.evaluation(state)
		if evaluated.is_empty():
			show_flow_error("Finish the mission before viewing a result.")
			return
	clear_screen()
	shell.show()
	landing_host.hide()
	var path = "res://scenes/screens/mission_control/MissionControl.tscn" if index == 0 else "res://scenes/screens/" + SCREENS[index] + ".tscn"
	current = load(path).instantiate()
	current.state = state
	current.navigate.connect(show_screen)
	nav.visible = false
	for i in sidebar.get_child_count():
		var link = sidebar.get_child(i)
		if link is Button: link.disabled = [-1, 1, 0, 2, 3, 4, 5][i] == index
	shell_footer.visible = index not in [1, 2, 3, 4]
	host.add_child(current)
	for i in nav.get_child_count():
		nav.get_child(i).disabled = i == index

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		preload("res://scripts/ui/DesktopWindow.gd").toggle(get_window())
		get_viewport().set_input_as_handled()

func show_flow_error(message: String) -> void:
	flow_error.dialog_text = message
	flow_error.popup_centered(Vector2i(440, 160))

func begin_new_mission() -> void:
	if Workflow.is_operating(state):
		show_flow_error("Finish or stop the current mission before starting a new one.")
		return
	Workflow.reset(state)
	show_screen(1)

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
