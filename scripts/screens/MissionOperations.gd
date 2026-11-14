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
func _ready() -> void:
	screen_id = "MissionOperations"
	if not state.has("run_trace"):
		var launched: Dictionary = preload("res://scripts/integration/mission_runtime.gd").launch(state)
		if not launched.ok:
			call_deferred("return_to_readiness")
			return
	DATA.configure(state.run_trace)
	run_configuration = state.run_trace.config.duplicate(true)
	setup("05 / MISSION PLAYBACK", "Mission Operations", "Explore the HPC simulation generated from your validated design and operating policy.", 3, 5, "View Debrief")
	workspace = row(content)
	var left = column(workspace, 0.9)
	var center = column(workspace, 2.2)
	var right = column(workspace, 1.15)
	build_status(left)
	build_progress(left)
	build_visualization(center)
	build_telemetry(right)
	build_events(right)
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
	var box = section(parent, "MISSION STATUS")
	status = UI.label(box, "", 15, "58e4b5")
	mission_details = UI.label(box, "", 12, "c2d9e6")
	UI.label(box, "HPC SIMULATION / POLICY PLAYBACK", 10, "78a6bf")
func build_progress(parent: Node) -> void:
	var box = section(parent, "MISSION PROGRESS")
	for target in state.targets:
		var line = row(box)
		line.add_theme_constant_override("separation", 8)
		var thumb = THUMB.new()
		thumb.custom_minimum_size = Vector2(48, 38)
		thumb.terrain = "coast" if "Coastal" in target else ("ice" if target in ["Arctic Ice", "Antarctic Region"] else "forest")
		line.add_child(thumb)
		var info = column(line)
		info.add_theme_constant_override("separation", 4)
		var text = UI.label(info, target, 12)
		var bar = ProgressBar.new()
		bar.custom_minimum_size.y = 9
		bar.show_percentage = false
		info.add_child(bar)
		target_rows.append([text, bar, target])
	total_label = UI.label(box, "", 13)
	total_progress = ProgressBar.new()
	total_progress.show_percentage = false
	total_progress.custom_minimum_size.y = 12
	box.add_child(total_progress)
	UI.label(box, "Captured observations and returned MB are separate goals.", 10, "789eb4")
func build_visualization(parent: Node) -> void:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var tabs = row(box)
	for tab in ["Earth & Orbit", "Ground Track", "Data View"]:
		var button = UI.button(tabs, tab, show_view.bind(tab))
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 12)
		tab_buttons[tab] = button
	view_frame = Control.new()
	view_frame.custom_minimum_size = Vector2(250, 285)
	box.add_child(view_frame)
	orbit_view = ORBIT_VIEW.instantiate()
	orbit_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view_frame.add_child(orbit_view)
	orbit_view.configure(state)
	track_view = TRACK.new()
	track_view.configure(state)
	track_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view_frame.add_child(track_view)
	data_view = ScrollContainer.new()
	data_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	data_view.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	view_frame.add_child(data_view)
	var table = GridContainer.new()
	table.columns = 5
	table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table.add_theme_constant_override("h_separation", 10)
	table.add_theme_constant_override("v_separation", 12)
	data_view.add_child(table)
	for caption in ["TIME", "EVENT", "BATTERY", "CAPTURED", "RETURNED MB"]:
		UI.label(table, caption, 10, "64d9ed").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for e in DATA.EVENTS:
		var cells = []
		for value in [DATA.time_label(e[1]), e[0], str(e[3]) + "%", str(e[5]), str(e[6])]:
			cells.append(UI.label(table, value, 11))
		data_cells.append(cells)
	var orbit_card = PanelContainer.new()
	orbit_card.position = Vector2(8, 8)
	orbit_card.custom_minimum_size = Vector2(146, 68)
	view_frame.add_child(orbit_card)
	orbit_badge = UI.label(orbit_card, "", 12, "b5eff7")
	orbit_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var craft_card = PanelContainer.new()
	craft_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	craft_card.offset_left = -140
	craft_card.offset_right = -8
	craft_card.offset_top = 8
	view_frame.add_child(craft_card)
	craft_badge = UI.label(craft_card, "", 11, "65e8ae")
	craft_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var controls = HFlowContainer.new()
	controls.add_theme_constant_override("h_separation", 5)
	controls.add_theme_constant_override("v_separation", 5)
	box.add_child(controls)
	play_button = UI.button(controls, "Play", play)
	pause_button = UI.button(controls, "Pause", pause)
	step_button = UI.button(controls, "Step", step)
	for multiplier in [1, 2, 4, 8]:
		var button = UI.button(controls, str(multiplier) + "x", set_speed.bind(multiplier))
		button.toggle_mode = true
		speed_buttons[multiplier] = button
	skip_button = UI.button(controls, "Skip to End", skip_to_end)
	UI.button(controls, "Expand", expand_orbit)
	UI.button(controls, "Abort Mission", func(): abort_requested.emit("Operator requested abort"))
	for entry in [["observe", "Observe"], ["transmit", "Send data"], ["power_save", "Save power"]]:
		action_buttons[entry[0]] = UI.button(controls, entry[1], take_action.bind(entry[0]))
	prediction_text = UI.label(box, "", 11, "efc371")
	prediction_text.hide()
	for button in controls.get_children():
		button.add_theme_font_size_override("font_size", 11)
		button.custom_minimum_size.y = 34
	var scrub = row(box)
	seek_slider = HSlider.new()
	seek_slider.max_value = DATA.TOTAL_SECONDS
	seek_slider.step = 1
	seek_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seek_slider.custom_minimum_size.y = 24
	seek_slider.value_changed.connect(func(value):
		playing = false
		seek(value))
	scrub.add_child(seek_slider)
	time_display = UI.label(scrub, "", 11)
	time_display.custom_minimum_size.x = 148
	UI.label(box, "ILLUSTRATIVE VIEW / HPC SIMULATION PLAYBACK", 10, "79a5bc")
	show_view("Earth & Orbit")
func build_telemetry(parent: Node) -> void:
	var box = section(parent, "SPACECRAFT TELEMETRY")
	box.add_theme_constant_override("separation", 5)
	for entry in [["Battery", "battery"], ["Storage buffer", "storage"]]:
		var line = row(box)
		UI.label(line, entry[0], 12).custom_minimum_size.x = 90
		var bar = ProgressBar.new()
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(60, 22)
		bar.add_theme_font_size_override("font_size", 11)
		line.add_child(bar)
		if entry[1] == "battery": battery_bar = bar
		else: storage_bar = bar
	telemetry = UI.label(box, "", 12)
func build_events(parent: Node) -> void:
	var box = section(parent, "RECENT EVENTS")
	var original_header: Control=box.get_child(0)
	var title: Label=original_header.get_child(0)
	event_header=BoxContainer.new()
	event_header.add_theme_constant_override("separation",8)
	box.add_child(event_header)
	box.move_child(event_header,0)
	title.reparent(event_header)
	title.autowrap_mode=TextServer.AUTOWRAP_OFF
	original_header.queue_free()
	filter_select = OptionButton.new()
	for caption in ["All Events", "Observations", "Downlink", "Warnings"]:
		filter_select.add_item(caption)
	filter_select.add_theme_font_size_override("font_size", 11)
	filter_select.item_selected.connect(func(_index): rebuild_timeline())
	event_header.add_child(filter_select)
	timeline = ItemList.new()
	timeline.custom_minimum_size = Vector2(0, 114)
	timeline.add_theme_font_size_override("font_size", 11)
	timeline.item_selected.connect(func(index): select_event(visible_events[index]))
	box.add_child(timeline)
	UI.label(box, "SELECTED EVENT", 10, "65c8db")
	details = UI.label(box, "", 11, "b8cedd")
	details.custom_minimum_size.y = 54
func build_lower_panels() -> void:
	var lower = row(content)
	var map_box = section(lower, "LIVE GROUND TRACK / ILLUSTRATIVE")
	map_box.get_parent().size_flags_stretch_ratio = 1.1
	live_track = TRACK.new()
	live_track.configure(state)
	map_box.add_child(live_track)
	live_track.custom_minimum_size.y = 60
	UI.label(map_box, "GREEN  Current position   CYAN / PURPLE  Targets   GOLD  Ground station", 10, "7db4c7")
	var box = section(lower, "NEXT EVENTS")
	next_events = UI.label(box, "", 12, "b4d6e5")
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
		var visible_row = filter_select.selected == 0 or (filter_select.selected == 1 and e[0] == "OBSERVE") or (filter_select.selected == 2 and e[0] == "TX") or (filter_select.selected == 3 and e[0] == "SKIP_POWER")
		if visible_row:
			visible_events.append(i)
			timeline.add_item(DATA.time_label(e[1]) + "  " + e[0])
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
	status.text = (state.name if not state.name.strip_edges().is_empty() else "Untitled Mission") + "\n" + mission_status
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
	var presentation = preload("res://scripts/presentation/DebriefPresentation.gd")
	telemetry.text = "Step %s / %s\nCaptured %s · Returned %s MB\nBattery %s / %s Wh\nStored %s / %s MB\n%s · %s" % [presentation.text(snapshot.get("step_index")), presentation.text(snapshot.get("total_steps")), presentation.text(snapshot.get("observations_completed")), presentation.number(snapshot,"returned_data_mb"), presentation.number(snapshot,"energy_wh"), presentation.text(snapshot.get("battery_capacity_wh")), presentation.number(snapshot,"stored_data_mb"), presentation.text(snapshot.get("storage_capacity_mb")), e[8], e[10]]
	telemetry.tooltip_text = "Run " + presentation.text(snapshot.get("run_id")) + "\nMission " + presentation.text(snapshot.get("mission_id"))
	battery_bar.value = e[3]
	storage_bar.value = e[4]
	details.text = "%s / T+ %s\n%s" % [e[0], DATA.time_label(e[1]), e[2]]
	for event in DATA.frames[event_index].get("events", []):
		details.text += "\n%s | Step %s | %s" % [presentation.text(event.get("event_id")), presentation.text(event.get("step_index")), presentation.text(event.get("code"))]
	orbit_badge.text = "Orbit %s / %s\nT+ %s" % [orbit_number, state.duration, DATA.time_label(playhead)]
	craft_badge.text = "SPACECRAFT\n%s\n%s" % [state.get("body_id", "NASA Satellite Kit").trim_prefix("dev_").replace("_", " ").capitalize(), e[8]]
	if state.get("satellite_id", "") in preload("res://data/mock/SatelliteAdapter.gd").SATELLITES:
		craft_badge.text = "SPACECRAFT\n%s\n%s" % [preload("res://data/mock/SatelliteAdapter.gd").SATELLITES[state.satellite_id][0], e[8]]
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
	prediction_text.text = "After the next step:\n" + "\n".join(projections)
	previous.disabled = snapshot.phase == "operating"
	if timeline_event != event_index: rebuild_timeline()
	var upcoming = []
	for i in range(event_index + 1, mini(event_index + 4, DATA.EVENTS.size())):
		upcoming.append("T+ %s   %s  /  %s" % [DATA.time_label(DATA.EVENTS[i][1]), DATA.EVENTS[i][0], DATA.EVENTS[i][8]])
	next_events.text = "\n".join(upcoming) if not upcoming.is_empty() else "Simulation playback complete.\nOpen Debrief for actual run totals."
	if is_instance_valid(expanded_orbit): expanded_orbit.set_frame(progress, e[0])
func expand_orbit() -> void:
	if is_instance_valid(enlarged): enlarged.queue_free()
	enlarged = AcceptDialog.new()
	enlarged.title = "Earth & Orbit / HPC Playback"
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
	if is_instance_valid(event_header): event_header.vertical = size.x < 1000
	view_frame.custom_minimum_size.y = clampf(size.y * 0.36, 230, 290)

func return_to_readiness() -> void:
	navigate.emit(3)

func _connect_control_focus(node: Node) -> void:
	if node is BaseButton:
		node.focus_entered.connect(func(): _reveal_focused.call_deferred(node))
	for child in node.get_children(): _connect_control_focus(child)

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
		prediction_text.text = reply.error.message
		prediction_text.show()
		return
	DATA = preload("res://scripts/integration/mission_playback.gd").new()
	DATA.configure(state.run_trace)
	seek(float(reply.state.step_index) / maxf(1, reply.state.total_steps) * DATA.TOTAL_SECONDS)

func finish_run() -> void:
	skip_to_end()
