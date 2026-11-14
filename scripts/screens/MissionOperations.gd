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
var tab_buttons: Dictionary = {}
var speed_buttons: Dictionary = {}
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
var expanded_orbit: SubViewportContainer
var event_header: BoxContainer
var action_buttons: Dictionary = {}
var prediction_text: Label
const DISCLOSURE = preload("res://ui/components/Disclosure.gd")
const LANGUAGE = preload("res://scripts/presentation/PlayerLanguage.gd")
var goal_grid: GridContainer
var photo_value: Label
var return_value: Label
var return_progress: ProgressBar
var action_help: Label
var action_feedback: Label
var battery_value: Label
var storage_value: Label
var flight_details: VBoxContainer
var extra_controls: VBoxContainer

func _ready() -> void:
	screen_id = "MissionOperations"
	if not state.has("run_trace"):
		var launched: Dictionary = preload("res://scripts/integration/mission_runtime.gd").launch(state)
		if not launched.ok:
			call_deferred("return_to_readiness")
			return
	DATA.configure(state.run_trace)
	run_configuration = state.run_trace.config.duplicate(true)
	setup("05 / OPERATE", "Mission Operations", "Take photos of your target, then send the data back to Earth.", 3, 5, "View results")
	progress_nav.hide()
	heading.get_child(0).get_child(1).add_theme_font_size_override("font_size", 17)
	build_status(content)
	build_progress(content)
	workspace = BoxContainer.new()
	workspace.add_theme_constant_override("separation", 18)
	content.add_child(workspace)
	var center = column(workspace, 1.65)
	var right = column(workspace, 1.0)
	build_visualization(center)
	build_commands(right)
	build_telemetry(right)
	flight_details = DISCLOSURE.new("Flight details")
	content.add_child(flight_details)
	build_events(flight_details.body)
	build_lower_panels()
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.follow_focus = true
	_connect_control_focus(self)
	resized.connect(responsive)
	call_deferred("responsive")
	var resume: Dictionary = state.get("active_run_state", {})
	if resume.get("run_id") != state.run_trace.final_state.run_id: resume = {}
	seek(float(resume.get("step_index", 0)) / maxf(1, state.run_trace.final_state.total_steps) * DATA.TOTAL_SECONDS)

func build_status(parent: Node) -> void:
	status = UI.label(parent, "", 20, "b9f4e7")
	mission_details = UI.label(parent, "", 16, "b2c8d8")
	# The mission name is here once; no separate status/progress/telemetry cards.
	mission_details.hide()

func build_progress(parent: Node) -> void:
	goal_grid = GridContainer.new()
	goal_grid.columns = 2
	goal_grid.add_theme_constant_override("h_separation", 16)
	goal_grid.add_theme_constant_override("v_separation", 12)
	goal_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(goal_grid)
	for kind in ["photos", "data"]:
		var box = UI.panel(goal_grid, "Photos taken" if kind == "photos" else "Data sent to Earth")
		box.add_theme_constant_override("separation", 4)
		box.get_child(0).add_theme_font_size_override("font_size", 16)
		var value = UI.label(box, "", 28)
		var bar = ProgressBar.new()
		bar.custom_minimum_size.y = 6
		bar.show_percentage = false
		box.add_child(bar)
		if kind == "photos":
			photo_value = value
			total_progress = bar
		else:
			return_value = value
			return_progress = bar
	# Retained display model for existing integrations; individual goals above
	# are the readable default, rather than a repeated combined sentence.
	total_label = Label.new()
	parent.add_child(total_label)
	total_label.hide()

func build_visualization(parent: Node) -> void:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var tabs = row(box)
	for tab in ["Earth & Orbit", "Ground Track", "Data View"]:
		var button = UI.button(tabs, {"Earth & Orbit":"Earth", "Ground Track":"Ground track", "Data View":"Flight data"}[tab], show_view.bind(tab))
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		button.custom_minimum_size.y = 44
		tab_buttons[tab] = button
	view_frame = Control.new()
	view_frame.custom_minimum_size = Vector2(250, 280)
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
	data_table.add_theme_constant_override("h_separation", 12)
	data_table.add_theme_constant_override("v_separation", 12)
	data_view.add_child(data_table)
	_rebuild_data_view()
	var orbit_card = PanelContainer.new()
	orbit_card.position = Vector2(8, 8)
	orbit_card.custom_minimum_size = Vector2(160, 68)
	view_frame.add_child(orbit_card)
	orbit_badge = UI.label(orbit_card, "", 16, "b5eff7")
	orbit_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var craft_card = PanelContainer.new()
	craft_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	craft_card.offset_left = -160
	craft_card.offset_right = -8
	craft_card.offset_top = 8
	view_frame.add_child(craft_card)
	craft_badge = UI.label(craft_card, "", 16, "b9f4e7")
	craft_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.label(box, "Illustrative orbit — not a real flight path.", 14, "aac4d6")
	show_view("Earth & Orbit")

func build_commands(parent: Node) -> void:
	var box = UI.panel(parent, "Your next move")
	box.add_theme_constant_override("separation", 8)
	box.get_child(0).add_theme_font_size_override("font_size", 20)
	action_help = UI.label(box, "", 16, "c2d9e6")
	action_help.resized.connect(_refresh_focused_control)
	for entry in [["observe", "Observe / take a photo"], ["transmit", "Send data to Earth"], ["power_save", "Save power / wait"]]:
		var button = UI.button(box, entry[1], take_action.bind(entry[0]))
		button.add_theme_font_size_override("font_size", 17)
		button.custom_minimum_size.y = 44
		action_buttons[entry[0]] = button
	action_feedback = UI.label(box, "", 16, "f4d38b")
	action_feedback.hide()
	var playback = HBoxContainer.new()
	playback.add_theme_constant_override("separation", 8)
	box.add_child(playback)
	play_button = UI.button(playback, "Play", play)
	pause_button = UI.button(playback, "Pause", pause)
	step_button = UI.button(playback, "Step", step)
	for button in [play_button, pause_button, step_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		button.add_theme_font_size_override("font_size", 16)
	play_button.tooltip_text = "Follow your chosen flight plan automatically. Pause to choose your own action."
	step_button.tooltip_text = "Advance one step using your chosen flight plan."
	extra_controls = DISCLOSURE.new("More flight controls")
	box.add_child(extra_controls)
	var speeds = HBoxContainer.new()
	extra_controls.body.add_child(speeds)
	UI.label(speeds, "Speed", 16)
	for multiplier in [1, 2, 4, 8]:
		var button = UI.button(speeds, str(multiplier) + "x", set_speed.bind(multiplier))
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		speed_buttons[multiplier] = button
	skip_button = UI.button(extra_controls.body, "Skip to End", skip_to_end)
	skip_button.tooltip_text = "Finish the remaining steps with your selected flight plan."
	UI.button(extra_controls.body, "Expand Earth view", expand_orbit)
	UI.button(extra_controls.body, "Stop mission early", func(): abort_requested.emit("Operator requested abort"))
	var scrub = column(extra_controls.body)
	seek_slider = HSlider.new()
	seek_slider.max_value = DATA.TOTAL_SECONDS
	seek_slider.step = 1
	seek_slider.custom_minimum_size.y = 30
	seek_slider.value_changed.connect(func(value):
		playing = false
		seek(value))
	scrub.add_child(seek_slider)
	time_display = UI.label(scrub, "", 16)
	prediction_text = UI.label(extra_controls.body, "", 16, "efc371")
	prediction_text.hide()

func build_telemetry(parent: Node) -> void:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	parent.add_child(box)
	battery_value = UI.label(box, "", 16)
	battery_value.tooltip_text = "Watt-hours (Wh) measure the energy left in the battery."
	battery_bar = ProgressBar.new()
	battery_bar.show_percentage = false
	battery_bar.custom_minimum_size.y = 8
	box.add_child(battery_bar)
	storage_value = UI.label(box, "", 16)
	storage_value.tooltip_text = "Data held on the spacecraft still needs to be sent to Earth. MB means megabytes."
	storage_bar = ProgressBar.new()
	storage_bar.show_percentage = false
	storage_bar.custom_minimum_size.y = 8
	box.add_child(storage_bar)

func build_events(parent: Node) -> void:
	var box = UI.panel(parent, "Mission log")
	event_header = BoxContainer.new()
	event_header.add_theme_constant_override("separation", 8)
	box.add_child(event_header)
	UI.label(event_header, "Flight events", 16).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_select = OptionButton.new()
	for caption in ["All events", "Photos", "Data sent", "Warnings"]:
		filter_select.add_item(caption)
	filter_select.add_theme_font_size_override("font_size", 16)
	filter_select.custom_minimum_size.y = 44
	filter_select.item_selected.connect(func(_index): rebuild_timeline())
	event_header.add_child(filter_select)
	timeline = ItemList.new()
	timeline.custom_minimum_size = Vector2(0, 160)
	timeline.add_theme_font_size_override("font_size", 16)
	timeline.item_selected.connect(func(index): select_event(visible_events[index]))
	box.add_child(timeline)
	details = UI.label(box, "", 16, "c2d9e6")
	telemetry = UI.label(box, "", 16, "c2d9e6")
	var targets = UI.panel(parent, "Your targets")
	for target in state.targets:
		var text = UI.label(targets, target, 16)
		var bar = ProgressBar.new()
		bar.custom_minimum_size.y = 8
		bar.show_percentage = false
		targets.add_child(bar)
		target_rows.append([text, bar, target])

func build_lower_panels() -> void:
	var map_box = UI.panel(flight_details.body, "Ground track")
	live_track = TRACK.new()
	live_track.configure(state)
	map_box.add_child(live_track)
	live_track.custom_minimum_size.y = 80
	UI.label(map_box, "Green: spacecraft   Blue/purple: targets   Gold: ground station", 16, "aac4d6")
	var box = UI.panel(flight_details.body, "Next steps in your flight plan")
	next_events = UI.label(box, "", 16, "c2d9e6")

func show_view(tab: String) -> void:
	if not is_instance_valid(orbit_view): return
	orbit_view.visible = tab == "Earth & Orbit"
	track_view.visible = tab == "Ground Track"
	data_view.visible = tab == "Data View"
	# Overlay cards only belong to the orbit view.
	orbit_badge.get_parent().visible = tab == "Earth & Orbit"
	craft_badge.get_parent().visible = tab == "Earth & Orbit"
	for tab_name in tab_buttons:
		tab_buttons[tab_name].set_pressed_no_signal(tab_name == tab)
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
func set_speed(multiplier: int) -> void:
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
	battery_value.text = "Battery: %s Wh remaining" % LANGUAGE.amount(snapshot.get("energy_wh"))
	storage_value.text = "Onboard data: %s / %s MB" % [LANGUAGE.amount(snapshot.get("stored_data_mb")), LANGUAGE.amount(snapshot.get("storage_capacity_mb"))]
	var presentation = preload("res://scripts/presentation/DebriefPresentation.gd")
	telemetry.text = "Step %s / %s\nCaptured %s · Returned %s MB\nBattery %s / %s Wh\nStored %s / %s MB\n%s · %s" % [presentation.text(snapshot.get("step_index")), presentation.text(snapshot.get("total_steps")), presentation.text(snapshot.get("observations_completed")), presentation.number(snapshot,"returned_data_mb"), presentation.number(snapshot,"energy_wh"), presentation.text(snapshot.get("battery_capacity_wh")), presentation.number(snapshot,"stored_data_mb"), presentation.text(snapshot.get("storage_capacity_mb")), e[8], e[10]]
	telemetry.tooltip_text = "Run " + presentation.text(snapshot.get("run_id")) + "\nMission " + presentation.text(snapshot.get("mission_id"))
	battery_bar.value = e[3]
	storage_bar.value = e[4]
	details.text = "%s (%s) / T+ %s\n%s" % [_frame_event_name(event_index), e[0], DATA.time_label(e[1]), LANGUAGE.sentence(e[2])]
	for event in DATA.frames[event_index].get("events", []):
		details.text += "\n%s | Step %s | %s" % [presentation.text(event.get("event_id")), presentation.text(event.get("step_index")), presentation.text(event.get("code"))]
	orbit_badge.text = "Orbit %s / %s\nT+ %s" % [orbit_number, state.duration, DATA.time_label(playhead)]
	craft_badge.text = "Your spacecraft\n" + ("In sunlight" if snapshot.is_sunlit else "In Earth's shadow")
	seek_slider.set_value_no_signal(playhead)
	time_display.text = DATA.time_label(playhead) + " / " + DATA.time_label(DATA.TOTAL_SECONDS)
	orbit_view.set_frame(progress, e[0])
	track_view.progress = progress
	live_track.progress = progress
	for i in data_cells.size():
		for cell in data_cells[i]:
			cell.add_theme_color_override("font_color", Color("62e7ee") if i == event_index else Color("8caabd"))
	for multiplier in speed_buttons:
		speed_buttons[multiplier].set_pressed_no_signal(float(multiplier) == speed)
	play_button.text = "Replay" if snapshot.phase == "finished" else "Play"
	play_button.disabled = playing
	pause_button.disabled = not playing
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
	if is_instance_valid(expanded_orbit): expanded_orbit.set_frame(progress, e[0])
func expand_orbit() -> void:
	if is_instance_valid(enlarged): enlarged.queue_free()
	enlarged = AcceptDialog.new()
	enlarged.title = "Earth & orbit"
	add_child(enlarged)
	expanded_orbit = ORBIT_VIEW.instantiate()
	expanded_orbit.custom_minimum_size = Vector2(420, 300)
	enlarged.add_child(expanded_orbit)
	expanded_orbit.configure(state)
	expanded_orbit.set_frame(playhead / DATA.TOTAL_SECONDS, DATA.EVENTS[event_index][0])
	enlarged.popup_centered(Vector2i(int(get_viewport_rect().size.x * 0.86), int(get_viewport_rect().size.y * 0.83)))
	enlarged.unresizable = false
func responsive() -> void:
	if not is_instance_valid(view_frame): return
	fit_navigation()
	progress_nav.hide()
	workspace.vertical = size.x < 950
	goal_grid.columns = 1 if size.x < 540 else 2
	if is_instance_valid(event_header): event_header.vertical = size.x < 1000
	view_frame.custom_minimum_size.y = 260 if workspace.vertical else clampf(size.y * 0.43, 260, 350)

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
		action_feedback.show()
		return
	DATA = preload("res://scripts/integration/mission_playback.gd").new()
	DATA.configure(state.run_trace)
	_rebuild_data_view()
	timeline_event = -1
	seek(float(reply.state.step_index) / maxf(1, reply.state.total_steps) * DATA.TOTAL_SECONDS)
	if not reply.state.event_log.is_empty():
		action_feedback.text = LANGUAGE.sentence(reply.state.event_log[-1].get("message", ""))
		action_feedback.show()

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
