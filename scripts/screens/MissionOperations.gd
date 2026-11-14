extends "res://scripts/screens/Workbench.gd"
signal terminal_state(native_state: Dictionary)
signal abort_requested(reason: String)
var DATA = preload("res://scripts/integration/mission_playback.gd").new()
const ORBIT_VIEW = preload("res://scenes/ui/components/OperationsOrbitViewport.tscn")
const TRACK = preload("res://ui/components/GroundTrack.gd")
const THUMB = preload("res://ui/components/TargetThumbnail.gd")
## Independent validated config used by this HPC policy playback.
var run_configuration: Dictionary = {}
var event_index = 0
var playing = false
var speed = 1.0
var playhead = 0.0
var orbit_view: SubViewportContainer
var track_view: Control
var live_track: Control
var view_frame: Control
var data_view: ScrollContainer
var data_cells: Array = []
var data_table: GridContainer
var status: Label
var mission_details: Label
var target_rows: Array = []
var total_progress: ProgressBar
var total_label: Label
var telemetry: Label
var battery_bar: ProgressBar
var storage_bar: ProgressBar
var details: Label
var timeline: ItemList
var filter_select: OptionButton
var visible_events: Array = []
var timeline_event = -1
var next_events: Label
var orbit_badge: Label
var craft_badge: Label
var seek_slider: HSlider
var time_display: Label
var play_button: Button
var pause_button: Button
var step_button: Button
var skip_button: Button
var enlarged: AcceptDialog
var event_header: BoxContainer
var action_buttons: Dictionary = {}
var prediction_text: Label
const LANGUAGE = preload("res://scripts/presentation/PlayerLanguage.gd")
var photo_value: Label
var return_value: Label
var return_progress: ProgressBar
var action_help: Label
var action_feedback: Label
var battery_value: Label
var storage_value: Label
var player_panel: PanelContainer
var settings_button: MenuButton
var log_button: Button
var log_dialog: AcceptDialog
var player_home: Node
var player_home_index: int
var selected_view: String = "Earth & Orbit"
var speed_values: Array = [0.5, 1.0, 2.0, 4.0, 8.0]
var speed_menu: PopupMenu
var view_menu: PopupMenu

func flat_button(parent: Node, caption: String, callback: Callable, icon_path: String = "") -> Button:
	var button = UI.button(parent, caption, callback)
	style_control(button)
	if not icon_path.is_empty(): button.icon = load(icon_path)
	return button

func style_control(button: BaseButton, filled: bool = false) -> void:
	button.custom_minimum_size = Vector2(40, 40)
	button.add_theme_font_size_override("font_size", 15)
	for mode in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("153241") if filled else Color(0,0,0,0)
		if mode in ["hover", "pressed"]: style.bg_color = Color("234653")
		if mode == "disabled": style.bg_color = Color("101c28") if filled else Color(0,0,0,0)
		style.set_corner_radius_all(7)
		style.content_margin_left = 12
		style.content_margin_right = 12
		if mode == "focus":
			style.border_color = Color("69d7da")
			style.set_border_width_all(2)
		button.add_theme_stylebox_override(mode, style)

func _ready() -> void:
	screen_id = "MissionOperations"
	if not state.has("run_trace"):
		var launched: Dictionary = preload("res://scripts/integration/mission_runtime.gd").launch(state)
		if not launched.ok:
			call_deferred("return_to_readiness")
			return
	DATA.configure(state.run_trace)
	run_configuration = state.run_trace.config.duplicate(true)
	setup("05 / OPERATE", "Mission Operations", "", 3, 5, "View results")
	progress_nav.hide()
	heading.get_child(0).get_child(1).hide()
	content.add_theme_constant_override("separation", 10)
	build_hud()
	workspace = BoxContainer.new()
	content.add_child(workspace)
	build_player(workspace)
	build_log()
	scroll.follow_focus = true
	scroll.resized.connect(responsive)
	resized.connect(responsive)
	_connect_control_focus(self)
	var resume: Dictionary = state.get("active_run_state", {})
	if resume.get("run_id") != state.run_trace.final_state.run_id: resume = {}
	seek(float(resume.get("step_index", 0)) / maxf(1, state.run_trace.final_state.total_steps) * DATA.TOTAL_SECONDS)
	responsive.call_deferred()

func build_hud() -> void:
	var strip = HBoxContainer.new()
	strip.add_theme_constant_override("separation", 20)
	content.add_child(strip)
	for caption in ["PHOTOS", "SENT TO EARTH", "BATTERY", "ONBOARD DATA"]:
		var column = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 1)
		strip.add_child(column)
		UI.label(column, caption, 12, "84a5b8")
		var value = UI.label(column, "", 23)
		match caption:
			"PHOTOS": photo_value = value
			"SENT TO EARTH": return_value = value
			"BATTERY": battery_value = value
			"ONBOARD DATA": storage_value = value
	# Keep legacy telemetry models without duplicating them in the player.
	for field in ["total", "battery", "storage", "return"]:
		var bar = ProgressBar.new()
		bar.hide()
		add_child(bar)
		match field:
			"total": total_progress = bar
			"battery": battery_bar = bar
			"storage": storage_bar = bar
			"return": return_progress = bar
	total_label = Label.new()
	add_child(total_label)
	total_label.hide()

func build_player(parent: Node) -> void:
	player_panel = PanelContainer.new()
	player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var surface = StyleBoxFlat.new()
	surface.bg_color = Color("050d16")
	surface.set_corner_radius_all(12)
	surface.set_content_margin_all(10)
	player_panel.add_theme_stylebox_override("panel", surface)
	parent.add_child(player_panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	player_panel.add_child(box)
	view_frame = Control.new()
	view_frame.custom_minimum_size = Vector2(240, 280)
	box.add_child(view_frame)
	orbit_view = ORBIT_VIEW.instantiate()
	orbit_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view_frame.add_child(orbit_view)
	orbit_view.configure(state)
	orbit_view.orbit_caption.hide()
	track_view = TRACK.new()
	track_view.configure(state)
	track_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view_frame.add_child(track_view)
	data_view = ScrollContainer.new()
	data_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	data_view.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	view_frame.add_child(data_view)
	data_table = GridContainer.new()
	data_table.columns = 4
	data_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_table.add_theme_constant_override("h_separation", 16)
	data_table.add_theme_constant_override("v_separation", 12)
	data_view.add_child(data_table)
	_rebuild_data_view()
	var overlay = VBoxContainer.new()
	overlay.position = Vector2(14, 12)
	overlay.custom_minimum_size = Vector2(280, 70)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view_frame.add_child(overlay)
	status = UI.label(overlay, "", 16)
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	orbit_badge = UI.label(overlay, "", 13, "a0bacc")
	craft_badge = UI.label(overlay, "", 13, "84b9ae")
	mission_details = UI.label(overlay, "", 14)
	mission_details.hide()
	seek_slider = HSlider.new()
	seek_slider.max_value = DATA.TOTAL_SECONDS
	seek_slider.step = 1
	seek_slider.custom_minimum_size.y = 18
	var rail = StyleBoxFlat.new()
	rail.bg_color = Color("30414e")
	rail.set_corner_radius_all(2)
	rail.content_margin_top = 2
	rail.content_margin_bottom = 2
	seek_slider.add_theme_stylebox_override("slider", rail)
	var played = rail.duplicate()
	played.bg_color = Color("6ad4d7")
	seek_slider.add_theme_stylebox_override("grabber_area", played)
	seek_slider.add_theme_stylebox_override("grabber_area_highlight", played)
	seek_slider.value_changed.connect(func(value):
		playing = false
		seek(value))
	seek_slider.tooltip_text = "Seek through the flight"
	box.add_child(seek_slider)
	var controls = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 4)
	box.add_child(controls)
	play_button = flat_button(controls, "Play", toggle_playback, "res://assets/ui/icons/play.svg")
	pause_button = play_button
	step_button = flat_button(controls, "", step, "res://assets/ui/icons/player-step.svg")
	step_button.tooltip_text = "Next step"
	time_display = UI.label(controls, "", 14, "b8cbd8")
	time_display.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	time_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip_button = flat_button(controls, "Finish", skip_to_end)
	skip_button.tooltip_text = "Complete the remaining flight plan"
	settings_button = MenuButton.new()
	settings_button.icon = preload("res://assets/ui/icons/settings.svg")
	settings_button.tooltip_text = "Playback settings"
	style_control(settings_button)
	controls.add_child(settings_button)
	var menu = settings_button.get_popup()
	speed_menu = PopupMenu.new()
	speed_menu.name = "SpeedOptions"
	menu.add_child(speed_menu)
	view_menu = PopupMenu.new()
	view_menu.name = "ViewOptions"
	menu.add_child(view_menu)
	for popup in [menu, speed_menu, view_menu]:
		popup.add_theme_font_size_override("font_size", 16)
		popup.add_theme_constant_override("v_separation", 10)
		var background = StyleBoxFlat.new()
		background.bg_color = Color("101f2d")
		background.set_corner_radius_all(10)
		background.set_content_margin_all(14)
		popup.add_theme_stylebox_override("panel", background)
		popup.add_theme_color_override("font_color", Color("e3edf5"))
		popup.id_pressed.connect(_player_setting)
	for i in speed_values.size():
		speed_menu.add_radio_check_item(("Normal" if speed_values[i] == 1.0 else str(speed_values[i]) + "x"), 100 + i)
	for i in 3: view_menu.add_radio_check_item(["Earth", "Ground track", "Flight data"][i], 200 + i)
	menu.add_submenu_item("Playback speed · Normal", "SpeedOptions")
	menu.add_submenu_item("View · Earth", "ViewOptions")
	menu.add_separator()
	menu.add_item("Stop mission early", 300)
	flat_button(controls, "", expand_orbit, "res://assets/ui/icons/player-expand.svg").tooltip_text = "Expand flight player"
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	for entry in [["observe", "Observe"], ["transmit", "Transmit"], ["power_save", "Wait"]]:
		var button = flat_button(actions, entry[1], take_action.bind(entry[0]))
		style_control(button, true)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_buttons[entry[0]] = button
	log_button = flat_button(actions, "Flight log", show_log)
	action_help = UI.label(box, "", 14, "a5bdcc")
	action_help.custom_minimum_size.y = 38
	action_help.resized.connect(_refresh_focused_control)
	action_feedback = UI.label(box, "", 14, "f4d38b")
	action_feedback.hide()
	prediction_text = Label.new()
	prediction_text.hide()
	box.add_child(prediction_text)
	UI.label(content, "Illustrative orbit · Drag to look around", 12, "86a3b7")
	show_view("Earth & Orbit")

func build_log() -> void:
	log_dialog = AcceptDialog.new()
	log_dialog.title = "Flight log"
	log_dialog.ok_button_text = "Back to flight"
	add_child(log_dialog)
	log_dialog.visibility_changed.connect(func():
		if not log_dialog.visible and is_inside_tree(): log_button.grab_focus())
	var scroller = ScrollContainer.new()
	scroller.custom_minimum_size = Vector2(460, 320)
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_dialog.add_child(scroller)
	var body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroller.add_child(body)
	event_header = BoxContainer.new()
	body.add_child(event_header)
	UI.label(event_header, "Recorded events", 16).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_select = OptionButton.new()
	for label in ["All events", "Photos", "Data sent", "Warnings"]: filter_select.add_item(label)
	filter_select.item_selected.connect(func(_i): rebuild_timeline())
	event_header.add_child(filter_select)
	timeline = ItemList.new()
	timeline.custom_minimum_size.y = 160
	timeline.add_theme_font_size_override("font_size", 15)
	timeline.item_selected.connect(func(i): select_event(visible_events[i]))
	body.add_child(timeline)
	details = UI.label(body, "", 15)
	telemetry = UI.label(body, "", 15, "a5bdcc")
	for target in state.targets:
		var label = UI.label(body, target, 15)
		var bar = ProgressBar.new()
		bar.custom_minimum_size.y = 5
		bar.show_percentage = false
		body.add_child(bar)
		target_rows.append([label, bar, target])
	live_track = TRACK.new()
	live_track.configure(state)
	live_track.custom_minimum_size.y = 70
	body.add_child(live_track)
	next_events = UI.label(body, "", 15, "a5bdcc")

func show_log() -> void:
	pause()
	log_dialog.popup_centered(Vector2i(mini(620, get_viewport_rect().size.x - 60), mini(540, get_viewport_rect().size.y - 80)))

func toggle_playback() -> void:
	if playing: pause()
	else: play()

func _player_setting(id: int) -> void:
	if id >= 100 and id < 105: set_speed(speed_values[id - 100])
	elif id >= 200 and id < 203: show_view(["Earth & Orbit", "Ground Track", "Data View"][id - 200])
	elif id == 300: abort_requested.emit("Operator requested abort")

func show_view(tab: String) -> void:
	if not is_instance_valid(orbit_view): return
	orbit_view.visible = tab == "Earth & Orbit"
	track_view.visible = tab == "Ground Track"
	data_view.visible = tab == "Data View"
	# Overlay cards only belong to the orbit view.
	orbit_badge.get_parent().visible = tab == "Earth & Orbit"
	craft_badge.get_parent().visible = tab == "Earth & Orbit"
	selected_view = tab
	for i in 3:
		view_menu.set_item_checked(view_menu.get_item_index(200 + i), ["Earth & Orbit", "Ground Track", "Data View"][i] == tab)
	settings_button.get_popup().set_item_text(1, "View · " + {"Earth & Orbit":"Earth", "Ground Track":"Ground track", "Data View":"Flight data"}[tab])
func rebuild_timeline() -> void:
	timeline_event = event_index
	visible_events.clear()
	timeline.clear()
	for i in DATA.EVENTS.size():
		var e = DATA.EVENTS[i]
		var visible_row = filter_select.selected == 0 or (filter_select.selected == 1 and e[0] == "OBSERVE") or (filter_select.selected == 2 and e[0] == "TX") or (filter_select.selected == 3 and DATA.frames[i].get("events", []).any(func(event): return event.get("type") == "action_blocked"))
		if visible_row:
			visible_events.append(i)
			timeline.add_item(DATA.time_label(e[1]) + "  " + _frame_event_name(i))
			if i == event_index: timeline.select(timeline.item_count - 1)
func seek(seconds: float) -> void:
	playhead = clampf(seconds, 0, playback_end())
	event_index = DATA.index_at(playhead)
	if playhead >= playback_end(): playing = false
	refresh()
func select_event(index: int) -> void:
	playing = false
	seek(DATA.EVENTS[clampi(index, 0, DATA.EVENTS.size() - 1)][1])
func play() -> void:
	playing = true
	if playhead >= playback_end():
		seek(0)
	else:
		refresh()
func pause() -> void:
	playing = false
	refresh()
func step() -> void:
	select_event(mini(event_index + 1, DATA.EVENTS.size() - 1))
func set_speed(multiplier: float) -> void:
	speed = float(multiplier)
	refresh()
func skip_to_end() -> void:
	playing = false
	seek(playback_end())
func _process(delta: float) -> void:
	if playing:
		seek(playhead + delta * DATA.PLAYBACK_RATE * speed)
func refresh() -> void:
	if not is_instance_valid(telemetry): return
	var e = DATA.EVENTS[event_index]
	var snapshot: Dictionary = DATA.frames[event_index].state
	var progress = playhead / DATA.TOTAL_SECONDS
	var orbit_number = mini(run_configuration.mission.duration_orbits, 1 + int(progress * run_configuration.mission.duration_orbits))
	var mission_status = str(snapshot.run_status).to_upper() if snapshot.phase == "finished" else ("PLAYING" if playing else "PAUSED")
	status.text = (state.name if not state.name.strip_edges().is_empty() else "Untitled Mission") + "  ·  " + LANGUAGE.event_name(mission_status)
	mission_details.text = "%s\n%s\nOrbit %s / %s  ·  %s\nRemaining   %s" % [state.objective, state.orbit, orbit_number, state.duration, DATA.time_label(playhead), DATA.time_label(DATA.TOTAL_SECONDS - playhead)]
	for i in target_rows.size():
		var count = DATA.TARGET_CAPTURE[event_index][i]
		var delivered = DATA.TARGET_DELIVERY[event_index][i]
		var target_id: String = run_configuration.mission.get("target_regions", [run_configuration.mission.target_region])[i]
		var fully_delivered: int = int(DATA.frames[event_index].state.get("observations_delivered_by_target", {}).get(target_id, 0))
		target_rows[i][0].text = "%s\n%s captured / %s delivered\n%.3f MB returned" % [target_rows[i][2], count, fully_delivered, delivered]
		target_rows[i][1].value = float(count) / state.observations * 100
	total_label.text = "Captured %s / %s · Returned %.3f / %s MB" % [e[5], run_configuration.mission.required_observations, e[6], run_configuration.mission.required_returned_data_mb]
	total_progress.value = 100.0 * e[5] / run_configuration.mission.required_observations
	photo_value.text = "%s / %s" % [e[5], run_configuration.mission.required_observations]
	return_value.text = "%s / %s MB" % [LANGUAGE.amount(e[6]), LANGUAGE.amount(run_configuration.mission.required_returned_data_mb)]
	return_progress.value = 100.0 * e[6] / run_configuration.mission.required_returned_data_mb
	battery_value.text = "%s Wh" % LANGUAGE.amount(snapshot.get("energy_wh"))
	storage_value.text = "%s / %s MB" % [LANGUAGE.amount(snapshot.get("stored_data_mb")), LANGUAGE.amount(snapshot.get("storage_capacity_mb"))]
	var presentation = preload("res://scripts/presentation/DebriefPresentation.gd")
	telemetry.text = "Step %s / %s\nCaptured %s · Returned %s MB\nBattery %s / %s Wh\nStored %s / %s MB\n%s · %s" % [presentation.text(snapshot.get("step_index")), presentation.text(snapshot.get("total_steps")), presentation.text(snapshot.get("observations_completed")), presentation.number(snapshot,"returned_data_mb"), presentation.number(snapshot,"energy_wh"), presentation.text(snapshot.get("battery_capacity_wh")), presentation.number(snapshot,"stored_data_mb"), presentation.text(snapshot.get("storage_capacity_mb")), e[8], e[10]]
	telemetry.tooltip_text = "Run " + presentation.text(snapshot.get("run_id")) + "\nMission " + presentation.text(snapshot.get("mission_id"))
	battery_bar.value = e[3]
	storage_bar.value = e[4]
	details.text = "%s (%s) / T+ %s\n%s" % [_frame_event_name(event_index), e[0], DATA.time_label(e[1]), LANGUAGE.sentence(e[2])]
	for event in DATA.frames[event_index].get("events", []):
		details.text += "\n%s | Step %s | %s" % [presentation.text(event.get("event_id")), presentation.text(event.get("step_index")), presentation.text(event.get("code"))]
	orbit_badge.text = "Orbit %s of %s" % [orbit_number, state.duration]
	craft_badge.text = "Sunlight" if snapshot.is_sunlit else "Earth's shadow"
	seek_slider.set_value_no_signal(playhead)
	time_display.text = DATA.time_label(playhead) + " / " + DATA.time_label(DATA.TOTAL_SECONDS)
	orbit_view.set_frame(progress, e[0])
	track_view.progress = progress
	live_track.progress = progress
	for i in data_cells.size():
		for cell in data_cells[i]:
			cell.add_theme_color_override("font_color", Color("62e7ee") if i == event_index else Color("8caabd"))
	for i in speed_values.size():
		speed_menu.set_item_checked(speed_menu.get_item_index(100 + i), speed_values[i] == speed)
	settings_button.get_popup().set_item_text(0, "Playback speed · " + ("Normal" if speed == 1.0 else str(speed) + "x"))
	play_button.text = "Pause" if playing else ("Replay" if snapshot.phase == "finished" else "Play")
	play_button.icon = preload("res://assets/ui/icons/player-pause.svg") if playing else preload("res://assets/ui/icons/play.svg")
	play_button.tooltip_text = "Pause" if playing else "Play your selected flight plan"
	play_button.disabled = false
	state.active_run_state = snapshot.duplicate(true)
	next_button.disabled = snapshot.phase != "finished"
	if snapshot.phase == "finished": terminal_state.emit(snapshot.duplicate(true))
	var projections: PackedStringArray = []
	var stored: Dictionary = state.get("evaluation_store", {})
	var published: bool = stored.get("reports", {}).has(snapshot.run_id) or stored.get("errors", {}).has(snapshot.run_id)
	for action in action_buttons:
		var available: Dictionary = snapshot.available_actions.get(action, {})
		action_buttons[action].disabled = playing or published or snapshot.phase != "operating" or not available.get("allowed", false)
		var predicted: Dictionary = preload("res://core/MissionStepEngine.gd").predict_next_step(snapshot, action)
		if predicted.get("ok", false) and predicted.prediction.allowed:
			projections.append("%s: %.2f Wh battery, %.2f MB stored" % [action_buttons[action].text, predicted.prediction.energy_wh_after, predicted.prediction.stored_data_mb_after])
		action_buttons[action].tooltip_text = str(available.get("reason", "")) if available.get("reason") != null else ""
		if predicted.get("ok", false) and predicted.prediction.allowed:
			action_buttons[action].tooltip_text = "After this step: %.2f Wh battery, %.2f MB stored." % [predicted.prediction.energy_wh_after, predicted.prediction.stored_data_mb_after]
		if published or snapshot.phase == "finished":
			action_buttons[action].tooltip_text = "This flight is recorded. Retry from results to make new choices."
		elif playing:
			action_buttons[action].tooltip_text = "Pause the flight plan to choose an action yourself."
	prediction_text.text = "After the next step:\n" + "\n".join(projections)
	var previous_guidance: String = action_help.text
	_refresh_action_help(snapshot, published)
	if action_help.text != previous_guidance: _refresh_focused_control()
	previous.disabled = snapshot.phase == "operating"
	if timeline_event != event_index: rebuild_timeline()
	var upcoming = []
	for i in range(event_index + 1, mini(event_index + 4, DATA.EVENTS.size())):
		upcoming.append("T+ %s   %s  /  %s" % [DATA.time_label(DATA.EVENTS[i][1]), _frame_event_name(i), DATA.EVENTS[i][8]])
	next_events.text = "\n".join(upcoming) if not upcoming.is_empty() else "Flight complete. Open results to see how you did."

func expand_orbit() -> void:
	if is_instance_valid(enlarged) and enlarged.visible:
		enlarged.hide()
		return
	if is_instance_valid(enlarged): enlarged.queue_free()
	player_home = player_panel.get_parent()
	player_home_index = player_panel.get_index()
	enlarged = AcceptDialog.new()
	enlarged.title = "Flight player"
	enlarged.ok_button_text = "Back to flight"
	add_child(enlarged)
	player_panel.reparent(enlarged)
	enlarged.visibility_changed.connect(func():
		if not enlarged.visible and is_inside_tree() and is_instance_valid(player_home):
			player_panel.reparent(player_home)
			player_home.move_child(player_panel, player_home_index)
			responsive.call_deferred()
			play_button.grab_focus())
	var dimensions = Vector2i(get_viewport_rect().size * 0.92)
	view_frame.custom_minimum_size.y = maxf(180, dimensions.y - 220)
	enlarged.popup_centered(dimensions)

func responsive() -> void:
	if not is_instance_valid(view_frame): return
	fit_navigation()
	progress_nav.hide()
	if is_instance_valid(enlarged) and enlarged.visible: return
	var overhead: float = content.get_combined_minimum_size().y - view_frame.custom_minimum_size.y
	var wanted: float = clampf(scroll.size.y - overhead - 4, 170, 500)
	if absf(view_frame.custom_minimum_size.y - wanted) > 1:
		view_frame.custom_minimum_size.y = wanted
	if is_instance_valid(event_header): event_header.vertical = false

func return_to_readiness() -> void:
	navigate.emit(3)

func _connect_control_focus(node: Node) -> void:
	if node is BaseButton:
		node.focus_entered.connect(func(): _reveal_after_layout(node))
	for child in node.get_children(): _connect_control_focus(child)

func _refresh_focused_control() -> void:
	var control: Control = get_viewport().gui_get_focus_owner()
	if control is BaseButton and scroll.is_ancestor_of(control): _reveal_after_layout(control)

func _reveal_after_layout(control: Control) -> void:
	# Wrapped guidance can change height after focus has entered a button.
	# Let both container layout and scrollbar bounds settle before fitting its outline.
	await get_tree().process_frame
	if not is_instance_valid(control) or not control.has_focus(): return
	_reveal_focused(control)
	await get_tree().process_frame
	if is_instance_valid(control) and control.has_focus(): _reveal_focused(control)

func _reveal_focused(control: Control) -> void:
	if not is_instance_valid(control) or not scroll.is_ancestor_of(control): return
	scroll.ensure_control_visible(control)
	var clip: Rect2 = scroll.get_global_rect()
	var rect: Rect2 = control.get_global_rect().grow(4)
	if rect.end.y > clip.end.y: scroll.scroll_vertical += ceili(rect.end.y - clip.end.y)
	elif rect.position.y < clip.position.y: scroll.scroll_vertical -= ceili(clip.position.y - rect.position.y)

func playback_end() -> float:
	return float(DATA.EVENTS[-1][1]) if not DATA.EVENTS.is_empty() else DATA.TOTAL_SECONDS

func take_action(action: String) -> void:
	playing = false
	var reply: Dictionary = preload("res://scripts/integration/mission_runtime.gd").take_action(state, action)
	if not reply.ok:
		action_feedback.text = LANGUAGE.sentence(reply.error.message)
		action_help.text = action_feedback.text
		return
	DATA = preload("res://scripts/integration/mission_playback.gd").new()
	DATA.configure(state.run_trace)
	_rebuild_data_view()
	timeline_event = -1
	seek(float(reply.state.step_index) / maxf(1, reply.state.total_steps) * DATA.TOTAL_SECONDS)
	if not reply.state.event_log.is_empty():
		action_feedback.text = LANGUAGE.sentence(reply.state.event_log[-1].get("message", ""))
		action_help.text = action_feedback.text

func finish_run() -> void:
	skip_to_end()

func _refresh_action_help(snapshot: Dictionary, published: bool) -> void:
	if snapshot.phase == "finished":
		action_help.text = "Flight finished. Open results to see which goals you reached."
	elif published:
		action_help.text = "Reviewing a recorded flight. Retry from results to make new choices."
	elif playing:
		action_help.text = "Your flight plan is running. Pause to choose an action yourself."
	elif snapshot.available_actions.get("transmit", {}).get("allowed", false):
		action_help.text = "A ground station is in range. Send your onboard data home."
	elif snapshot.available_actions.get("observe", {}).get("allowed", false):
		action_help.text = "Your target is in view. Take a photo to collect data."
	elif not snapshot.get("in_ground_contact", false):
		action_help.text = "No ground station is in range. Save power or use Step to reach the next contact window."
	else:
		action_help.text = "No photo or transmission is available. Save power to advance one step."

func _frame_event_name(index: int) -> String:
	for event in DATA.frames[index].get("events", []):
		if event.get("type") == "action_blocked":
			return {"transmit":"Data transfer blocked", "observe":"Photo not taken"}.get(event.get("action"), "Action unavailable")
	return LANGUAGE.event_name(DATA.EVENTS[index][0])

func _rebuild_data_view() -> void:
	data_cells.clear()
	for cell in data_table.get_children():
		data_table.remove_child(cell)
		cell.queue_free()
	for caption in ["Time", "Action", "Photos", "Sent (MB)"]:
		UI.label(data_table, caption, 16, "8ce4ef").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in DATA.EVENTS.size():
		var event: Array = DATA.EVENTS[i]
		var cells: Array = []
		for value in [DATA.time_label(event[1]), _frame_event_name(i), str(event[5]), LANGUAGE.amount(event[6])]:
			cells.append(UI.label(data_table, value, 16))
		data_cells.append(cells)
