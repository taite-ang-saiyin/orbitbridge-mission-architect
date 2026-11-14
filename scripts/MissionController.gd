extends Control
const SCREENS = ["MissionControl", "MissionCreator", "SpacecraftBuilder", "FlightReadiness", "MissionOperations", "DebriefCompare"]
var state = preload("res://data/mock/DesignCatalog.gd").DEFAULTS.duplicate(true)
var preferences = preload("res://scripts/settings/PrototypeSettings.gd").DEFAULTS.duplicate()
var shell: Control
var landing_host: Control
var host: Control
var current: Control
var shell_footer: Label
var sidebar: VBoxContainer
var flow_error: AcceptDialog
var retry_restore: Dictionary = {}
var design_lab_restore: Dictionary = {}
var comparison_provider: Callable
var sidebar_rail: PanelContainer
var scoped_language: Node
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
	status.text = "ORBITBRIDGE     •     MISSION LAB"
	status.add_theme_color_override("font_color", Color("33e5e9"))
	header.add_child(status)
	var home_button = Button.new()
	home_button.text = "Home"
	home_button.pressed.connect(request_screen.bind(0))
	header.add_child(home_button)
	host = Control.new()
	host.name = "ScreenHost"
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var dashboard = HBoxContainer.new()
	dashboard.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(dashboard)
	var rail = PanelContainer.new()
	sidebar_rail = rail
	rail.custom_minimum_size.x = 172
	dashboard.add_child(rail)
	sidebar = VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 5)
	rail.add_child(sidebar)
	for entry in [["Home", 0], ["Mission Creator", 1], ["Spacecraft Builder", 2], ["Flight Readiness", 3], ["Operations", 4], ["Debrief", 5]]:
		var link = Button.new()
		link.text = entry[0]
		link.alignment = HORIZONTAL_ALIGNMENT_LEFT
		link.custom_minimum_size.y = 46
		link.set_meta("screen_index", entry[1])
		link.pressed.connect(request_screen.bind(entry[1]))
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
	footer.text = "OrbitBridge Mission Lab"
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
	scoped_language = preload("res://scripts/settings/ScopedLanguage.gd").new()
	scoped_language.controller = self
	add_child(scoped_language)
	show_home()
	if "--verify-demo" in OS.get_cmdline_user_args(): verify_demo.call_deferred()

func fit_shell():
	var padding = 18 if size.x >= 1250 else 12
	for side in ["left", "right", "top", "bottom"]:
		shell.add_theme_constant_override("margin_" + side, padding)

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

func request_screen(index: int) -> void:
	# Review player setup without bypassing live-run edit and result guards.
	if index in [1, 2, 3] and is_operating():
		show_flow_error("Finish or stop the current mission before editing its design.")
		return
	if index == 4 and not is_operating():
		var readiness: Dictionary = preload("res://scripts/integration/mission_runtime.gd").review(state)
		if not readiness.ready_to_launch:
			show_screen(4)
			return
	var needs_review: bool = index in [2, 3] or (index == 4 and not is_operating())
	if needs_review and not preload("res://scripts/integration/mission_review.gd").is_confirmed(state):
		if not is_instance_valid(current) or current.screen_id != "MissionCreator": show_screen(1)
		current.open_mission_review()
		return
	show_screen(index)

func show_screen(index: int):
	if state.has("design_lab_route") and index in [0, 1]:
		show_flow_error("Mission requirements are fixed for Design B. Cancel Design B to leave this draft.")
		return
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
			var launched: Dictionary
			if state.has("design_lab_route"):
				launched = preload("res://scripts/integration/design_lab.gd").launch_b(state, str(state.design_lab_route.origin_execution_key))
			else: launched = preload("res://scripts/integration/mission_runtime.gd").launch(state)
			if not launched.ok:
				show_flow_error(launched.error.message)
				return
	if index == 4 and state.has("run_trace"): state.run_design = state.run_trace.config.duplicate(true)
	if index == 4:
		retry_restore.clear()
		design_lab_restore.clear()
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
	current.navigate.connect(request_screen)
	if current.has_signal("terminal_state"): current.terminal_state.connect(on_terminal_state)
	if current.has_signal("abort_requested"): current.abort_requested.connect(abort_current_run)
	if current.has_signal("retry_requested"): current.retry_requested.connect(retry_mission)
	if current.has_signal("modify_requested"): current.modify_requested.connect(modify_design)
	if current.has_signal("new_mission_requested"): current.new_mission_requested.connect(start_new_mission)
	sidebar_rail.visible = index != 0
	for i in sidebar.get_child_count():
		var link = sidebar.get_child(i)
		if link is Button: link.disabled = link.get_meta("screen_index", -1) == index
	shell_footer.visible = index not in [0, 1, 2, 3, 4]
	host.add_child(current)
	if not retry_restore.is_empty() and index in [2, 3]:
		var cancel = Button.new()
		cancel.text = "Cancel Retry"
		cancel.pressed.connect(cancel_retry)
		current.previous.get_parent().add_child(cancel)

	if not design_lab_restore.is_empty() and index in [2, 3]:
		var cancel = Button.new()
		cancel.text = "Cancel Design B"
		cancel.pressed.connect(func(): cancel_design_b(str(state.design_lab_route.origin_execution_key)))
		current.previous.get_parent().add_child(cancel)

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
	design_lab_restore.clear()
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
	if not OS.has_feature("editor") and OS.get_name() == "Windows":
		var packaged: Dictionary = verifier.check_packaging()
		print("Windows package checks: %d passed; %d failed." % [packaged.passed, packaged.failed])
		result.passed += packaged.passed
		result.failed += packaged.failed
	print("Windows demo verification: %d checks passed; %d failed." % [result.passed, result.failed])
	get_tree().quit(0 if result.failed == 0 else 1)


# v2 SE hooks: KE3 supplies an execution key from the selected result, never a title.
func get_execution(execution_key: String) -> Dictionary:
	return preload("res://scripts/integration/mission_results.gd").get_execution(state, execution_key)

func save_design_a(execution_key: String) -> Dictionary:
	return preload("res://scripts/integration/design_lab.gd").save_a(state, execution_key)

func get_saved_design_a() -> Dictionary:
	return preload("res://scripts/integration/design_lab.gd").saved_a(state)

func replace_design_a(execution_key: String, expected_a_execution_key: String) -> Dictionary:
	return preload("res://scripts/integration/design_lab.gd").replace_a(state, execution_key, expected_a_execution_key)

func clear_design_a(expected_a_execution_key: String) -> Dictionary:
	return preload("res://scripts/integration/design_lab.gd").clear_a(state, expected_a_execution_key)

func show_execution_result(execution_key: String) -> Dictionary:
	if is_operating(): return preload("res://scripts/integration/design_lab.gd").failure("RUN_ACTIVE", "Finish the current run first.")
	var result: Dictionary = get_execution(execution_key)
	if not result.ok: return result
	state.run_trace = result.execution.trace.duplicate(true)
	state.run_design = result.execution.trace.config.duplicate(true)
	state.active_run_state = result.execution.trace.final_state.duplicate(true)
	show_screen(5)
	current.show_execution(result.execution.trace.duplicate(true))
	return result

func modify_execution(execution_key: String) -> Dictionary:
	if not design_lab_restore.is_empty() or not retry_restore.is_empty():
		return preload("res://scripts/integration/design_lab.gd").failure("DRAFT_ACTIVE", "Cancel the existing draft first.")
	var result: Dictionary = preload("res://scripts/integration/design_lab.gd").modify_execution(state, execution_key)
	if not result.ok: return result
	design_lab_restore = state.duplicate(true)
	design_lab_restore.run_trace = result.execution.trace.duplicate(true)
	design_lab_restore.run_design = result.execution.trace.config.duplicate(true)
	design_lab_restore.active_run_state = result.execution.trace.final_state.duplicate(true)
	state = result.draft
	show_screen(2)
	return {"ok":true,"origin_execution_key":execution_key}

func cancel_design_b(origin_execution_key: String) -> Dictionary:
	if is_operating() or design_lab_restore.is_empty() or state.get("design_lab_route", {}).get("origin_execution_key") != origin_execution_key:
		return preload("res://scripts/integration/design_lab.gd").failure("EXECUTION_MISMATCH", "No cancellable draft matches this execution.")
	state = design_lab_restore.duplicate(true)
	design_lab_restore.clear()
	return show_execution_result(origin_execution_key)

func run_design_b(origin_execution_key: String) -> Dictionary:
	if not preload("res://scripts/integration/mission_review.gd").is_confirmed(state):
		return preload("res://scripts/integration/design_lab.gd").failure("REVIEW_REQUIRED", "Review the mission requirements before launch.")
	if is_operating(): return preload("res://scripts/integration/design_lab.gd").failure("RUN_ACTIVE", "A run is already operating.")
	var result: Dictionary = preload("res://scripts/integration/design_lab.gd").launch_b(state, origin_execution_key)
	if result.ok: show_screen(4)
	return result

func comparison_inputs(b_execution_key: String) -> Dictionary:
	return preload("res://scripts/integration/design_lab.gd").comparison_inputs(state, b_execution_key)

func compare_executions(b_execution_key: String) -> Dictionary:
	return preload("res://scripts/integration/design_lab.gd").compare(state, b_execution_key, comparison_provider)

# KE3's Continue button uses this entry point, independent of selected Results.
func continue_saved_design_a() -> Dictionary:
	var saved: Dictionary = get_saved_design_a()
	if not saved.ok: return saved
	if saved.execution == null:
		return preload("res://scripts/integration/design_lab.gd").failure("A_NOT_SAVED", "Save Design A before creating B.")
	return modify_execution(saved.execution.execution_key)

# A successful Save has already happened before this optional continuation offer.
# KE3 may use its own popup with save_design_a / continue_saved_design_a instead.
func offer_design_b(execution_key: String) -> Dictionary:
	var saved: Dictionary = save_design_a(execution_key)
	if not saved.ok: return saved
	var dialog = ConfirmationDialog.new()
	dialog.name = "DesignASavedDialog"
	dialog.title = "Design A saved"
	dialog.dialog_text = "Keep this result as your baseline. Modify the spacecraft and run Design B?\n\nSaved for this session only. Closing or refreshing clears the comparison."
	dialog.ok_button_text = "Create Design B"
	dialog.cancel_button_text = "Not now"
	dialog.confirmed.connect(func():
		var result: Dictionary = continue_saved_design_a()
		if not result.ok: show_flow_error(result.error.message)
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(480, 190))
	return saved

func export_saved_design_a() -> Dictionary:
	return preload("res://scripts/integration/design_lab.gd").export_saved_a(state)
