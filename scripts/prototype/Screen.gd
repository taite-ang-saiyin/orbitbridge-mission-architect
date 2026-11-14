extends VBoxContainer
signal navigate(index: int)
signal retry_requested
signal modify_requested
signal new_mission_requested
const UI = preload("res://ui/components/UI.gd")
const ORBIT = preload("res://scenes/ui/components/OperationsOrbitViewport.tscn")
@export var screen_id: String
var state: Dictionary
var content: VBoxContainer
var summary: Label
const PRESENTATION = preload("res://scripts/presentation/DebriefPresentation.gd")
var report_scroll: ScrollContainer
var credits: Label
var retry_button: Button
var same_mission_button: Button
var credits_button: Button
var results_row: BoxContainer
var _retry_pending: bool = false
var _presentation_model: Dictionary = {}
const LANGUAGE = preload("res://scripts/presentation/PlayerLanguage.gd")
const DISCLOSURE = preload("res://ui/components/Disclosure.gd")
var outcome_title: Label
var photo_goal_value: Label
var data_goal_value: Label
var next_experiment: Label
var flight_facts: Label
var evidence: Label
var source_disclosure: VBoxContainer
var source_links: VBoxContainer
var previous_flights: VBoxContainer
var flight_details: VBoxContainer
var goal_cards: Array = []
func _ready():
	add_theme_constant_override("separation", 12)
	var titles = {"MissionControl": ["MISSION CONTROL / LOCAL PROTOTYPE", "Choose your next mission"], "Start": ["YOUR MISSION STARTS HERE", "OrbitBridge – Mission Architect"], "MissionCreator": ["01 / DEFINE", "Give your mission a purpose"], "SpacecraftBuilder": ["02 / DESIGN", "Build for the mission"], "FlightReadiness": ["03 / REVIEW", "Ready for the next horizon"], "MissionOperations": ["04 / OPERATE", "Mission control"], "DebriefCompare": ["YOUR FLIGHT / REVIEW", "Your mission results"]}
	UI.label(self, titles[screen_id][0], 12, "6fd9eb")
	UI.label(self, titles[screen_id][1], 30)
	var scroll = ScrollContainer.new()
	report_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	if screen_id == "DebriefCompare":
		var surface = StyleBoxFlat.new()
		surface.bg_color = Color("061522f5")
		surface.set_corner_radius_all(12)
		surface.set_content_margin_all(18)
		scroll.add_theme_stylebox_override("panel", surface)
		scroll.focus_mode = Control.FOCUS_ALL
		scroll.follow_focus = true
		scroll.gui_input.connect(_report_keys)
		var focus = StyleBoxFlat.new()
		focus.bg_color = Color(0,0,0,0)
		focus.border_color = Color("27e9ff")
		focus.set_border_width_all(3)
		scroll.add_theme_stylebox_override("focus",focus)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)
	match screen_id:
		"MissionControl": mission_control()
		"Start": start()
		"DebriefCompare": debrief()
func columns() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	content.add_child(row)
	return row
func actions(back: int, next: int, text: String = "Continue"):
	var row = HBoxContainer.new()
	add_child(row)
	if back >= 0:
		UI.button(row, "Back", func(): navigate.emit(back))
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	UI.button(row, text + "  >", func(): navigate.emit(next))
func choice(parent: Node, title: String, key: String, options: Array):
	UI.label(parent, title, 13, "9cb0c8")
	var select = OptionButton.new()
	for option in options:
		select.add_item(option)
	select.selected = maxi(0, options.find(state.get(key, options[0])))
	select.item_selected.connect(func(index):
		state[key] = options[index]
		refresh_summary())
	parent.add_child(select)
func number(parent: Node, title: String, key: String, maximum: int):
	UI.label(parent, title, 13, "9cb0c8")
	var spin = SpinBox.new()
	spin.min_value = 1
	spin.max_value = maximum
	spin.value = state[key]
	spin.value_changed.connect(func(value):
		state[key] = int(value)
		refresh_summary())
	parent.add_child(spin)
func start():
	var row = columns()
	var left = UI.panel(row, "DESIGN. LAUNCH. LEARN.")
	UI.label(left, "A small spacecraft.\nA world of possibilities.", 32)
	UI.label(left, "Shape an observation mission, configure your spacecraft, and explore the decisions behind a successful flight.", 17, "9cb0c8")
	UI.button(left, "Start New Mission  >", new_mission)
	UI.button(left, "Practice Example", func():
		reset_state()
		navigate.emit(1))
	UI.button(left, "How to Play", func():
		var popup = AcceptDialog.new()
		popup.title = "How to Play"
		popup.dialog_text = "1. Define a mission.\n2. Select a spacecraft and policy.\n3. Check that your design is ready.\n4. Take photos and send data to Earth.\n5. Review what happened and try a change.\n\nThis is an educational simulation."
		add_child(popup)
		popup.popup_centered(Vector2i(490, 300)))
	var right = UI.panel(row, "EARTH OBSERVATION / CONCEPT VIEW")
	var globe = ORBIT.instantiate()
	globe.custom_minimum_size = Vector2(280, 300)
	right.add_child(globe)
	globe.configure(state)
	UI.label(right, "One planet. A new perspective.", 20)
	UI.label(right, "Illustration only • No orbital simulation", 13, "9cb0c8")
func reset_state():
	preload("res://data/mock/DesignCatalog.gd").reset(state)
func new_mission():
	new_mission_requested.emit()

func refresh_summary():
	if not is_instance_valid(summary):
		return
	summary.text = "%s\n\n%s\n%s\n\n%s observations\n%s orbits\n%s cr budget" % [mission_name(), state.objective, state.target, state.observations, state.duration, state.budget]
func mission_name() -> String:
	return state.name if not state.name.strip_edges().is_empty() else "Untitled Mission"
var results: Label
func debrief():
	var history: Array = result_history()
	var select = OptionButton.new()
	select.clip_text = true
	select.custom_minimum_size = Vector2(1, 44)
	select.add_theme_font_size_override("font_size", 16)
	for i in history.size():
		var trace: Dictionary = history[i]
		select.add_item("Flight %s · %s" % [i + 1, trace.config.mission.get("title", "Untitled Mission")])
		select.set_item_tooltip(i, str(trace.final_state.run_id))
	content.add_child(select)
	select.item_selected.connect(show_actual_run)
	select.selected = maxi(0, history.size() - 1)
	outcome_title = UI.label(content, "", 30, "b9f4e7")
	results_row = BoxContainer.new()
	results_row.add_theme_constant_override("separation", 16)
	content.add_child(results_row)
	for caption in ["Photos taken", "Data sent to Earth"]:
		var box = UI.panel(results_row, caption)
		box.get_child(0).add_theme_font_size_override("font_size", 16)
		var value = UI.label(box, "", 28)
		goal_cards.append(value)
	photo_goal_value = goal_cards[0]
	data_goal_value = goal_cards[1]
	UI.label(content, "What happened", 20, "b9f4e7")
	results = UI.label(content, "", 18)
	UI.label(content, "Try this next", 20, "b9f4e7")
	next_experiment = UI.label(content, "", 18)
	var buttons = HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 12)
	buttons.add_theme_constant_override("v_separation", 12)
	content.add_child(buttons)
	retry_button = UI.button(buttons, "Modify design", _request_retry)
	same_mission_button = UI.button(buttons, "Retry same mission", _request_same_retry)
	UI.button(buttons, "Start New Mission", new_mission)
	for button in buttons.get_children():
		button.custom_minimum_size.y = 48
		button.add_theme_font_size_override("font_size", 17)
	var details_panel = DISCLOSURE.new("Flight details")
	flight_details = details_panel
	content.add_child(details_panel)
	flight_facts = UI.label(details_panel.body, "", 18)
	evidence = UI.label(details_panel.body, "", 18)
	previous_flights = DISCLOSURE.new("Previous flights")
	content.add_child(previous_flights)
	var grid = GridContainer.new()
	grid.name = "RunHistory"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 12)
	previous_flights.body.add_child(grid)
	for cell in ["Flight", "Photos", "Sent (MB)"]: _history_cell(grid, cell)
	for i in history.size():
		var trace: Dictionary = history[i]
		for cell in ["Flight " + str(i + 1), LANGUAGE.amount(trace.final_state.get("observations_completed")), LANGUAGE.amount(trace.final_state.get("returned_data_mb"))]: _history_cell(grid, cell)
	source_disclosure = DISCLOSURE.new("Sources")
	content.add_child(source_disclosure)
	credits_button = source_disclosure.toggle
	credits = UI.label(source_disclosure.body, "", 17)
	source_links = VBoxContainer.new()
	source_links.add_theme_constant_override("separation", 12)
	source_disclosure.body.add_child(source_links)
	credits_button.toggled.connect(func(opened):
		if opened: report_scroll.ensure_control_visible.call_deferred(credits))
	UI.label(content, "An educational simulation. Orbit paths, contact windows and most hardware values are illustrative.", 15, "b2c8d8")
	resized.connect(_fit_results)
	_fit_results.call_deferred()
	show_actual_run(maxi(0, history.size() - 1))
	actions(4, 0, "Return Home")
func _history_cell(parent: Node,value: String) -> void:
	var label: Label = UI.label(parent,value,16)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
func _fit_results() -> void:
	if is_instance_valid(results_row): results_row.vertical = size.x < 620
func _report_keys(event: InputEvent) -> void:
	if not report_scroll.has_focus() or not event is InputEventKey or not event.pressed: return
	if event.alt_pressed or event.ctrl_pressed or event.meta_pressed: return
	var distance: int = 0
	match event.keycode:
		KEY_DOWN: distance = 32
		KEY_UP: distance = -32
		KEY_PAGEDOWN: distance = maxi(32,int(report_scroll.size.y)-32)
		KEY_PAGEUP: distance = -maxi(32,int(report_scroll.size.y)-32)
		_: return
	var maximum: int = maxi(0,floori(report_scroll.get_v_scroll_bar().max_value-report_scroll.get_v_scroll_bar().page))
	if maximum == 0: return
	report_scroll.scroll_vertical = clampi(report_scroll.scroll_vertical+distance,0,maximum)
	report_scroll.accept_event()
func _request_retry() -> void:
	if _retry_pending or _presentation_model.get("state") not in ["report", "evaluation_error"]: return
	_retry_pending = true
	retry_button.disabled = true
	same_mission_button.disabled = true
	modify_requested.emit()
func _request_same_retry() -> void:
	if _retry_pending or _presentation_model.get("state") not in ["report", "evaluation_error"]: return
	_retry_pending = true
	retry_button.disabled = true
	same_mission_button.disabled = true
	retry_requested.emit()
func get_presentation_model() -> Dictionary:
	return _presentation_model.duplicate(true)
func show_actual_run(index: int):
	var history: Array = result_history()
	if history.is_empty():
		outcome_title.text = "Your results will appear here"
		results.text = "Finish a flight to see how you did."
		return
	var trace: Dictionary = history[clampi(index, 0, history.size() - 1)]
	_presentation_model = PRESENTATION.build(trace, state.get("evaluation_store", {}))
	var player: Dictionary = LANGUAGE.report(_presentation_model, trace)
	outcome_title.text = player.headline
	var outcome_color = "b9f4e7" if _presentation_model.get("report", {}).get("status") == "success" else "f4d38b"
	outcome_title.add_theme_color_override("font_color", Color(outcome_color))
	photo_goal_value.text = "%s / %s" % [player.photos, player.photo_goal]
	data_goal_value.text = "%s / %s MB" % [player.data, player.data_goal]
	results.text = "Score: %s\n\n%s" % [player.score, player.summary]
	if not player.targets.is_empty(): results.text += "\n\n" + player.targets.strip_edges()
	next_experiment.text = player.next
	flight_facts.text = "Battery remaining: %s Wh\nData still on the spacecraft: %s MB\n\nCollecting photos and sending them home are separate goals. Photos still on board have not yet reached Earth." % [player.battery, player.stored]
	flight_facts.tooltip_text = "Flight " + str(trace.final_state.run_id)
	evidence.text = player.evidence if not player.evidence.is_empty() else "No specific cause was established by the recorded events."
	var retry_allowed: bool = not _retry_pending and _presentation_model.state in ["report", "evaluation_error"]
	retry_button.disabled = not retry_allowed
	same_mission_button.disabled = not retry_allowed
	credits.text = LANGUAGE.credits(_presentation_model)
	for link in source_links.get_children():
		source_links.remove_child(link)
		link.queue_free()
	var sources: Array = _presentation_model.get("source_credits", []).duplicate(true)
	var mass: Dictionary = _presentation_model.get("readiness_credit", {})
	if mass.get("source_id") == "cubesat_101_1u_sample":
		results.text += "\n\nReference: NASA CubeSat 101 (see Sources)."
		var ledger: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/nasa_sources.json"))
		if ledger is Dictionary:
			for source in ledger.get("sources", []):
				if source.get("source_id") == mass.source_id: sources.append(source)
	var urls: Array = []
	for source in sources:
		if not source is Dictionary: continue
		var url: String = str(source.get("url", ""))
		if not url.begins_with("https://") or urls.has(url): continue
		urls.append(url)
		var link = LinkButton.new()
		link.text = "Open reference " + str(urls.size())
		link.tooltip_text = str(source.get("title", "Reference")) + "\n" + url
		link.custom_minimum_size.y = 44
		link.add_theme_font_size_override("font_size", 17)
		link.pressed.connect(func(): OS.shell_open(url))
		source_links.add_child(link)

func show_run(_key: String):
	show_actual_run(maxi(0, result_history().size() - 1))

func mission_control():
	var row = columns()
	var intro = UI.panel(row, "ORBITBRIDGE / MISSION ARCHITECT")
	UI.label(intro, "Design. Plan. Execute.", 28)
	UI.label(intro, "Turn a science goal into a spacecraft mission. Define your targets, explore a design, and review an illustrative flight.", 17, "9cb0c8")
	var globe = ORBIT.instantiate()
	globe.custom_minimum_size = Vector2(280, 310)
	intro.add_child(globe)
	globe.configure(state)
	UI.label(intro, "An educational mission simulation with illustrative hardware and orbit paths.", 13, "9cb0c8")
	var quick = UI.panel(row, "QUICK START")
	UI.button(quick, "Create New Mission  >", new_mission)
	UI.label(quick, "MISSION PRESETS", 14, "6fd9eb")
	for preset in ["Equator Watch", "Equator Imaging", "Equator Survey"]:
		UI.button(quick, preset + "  >", func():
			reset_state()
			state.name = preset
			state.targets = ["Equator"]
			state.target = ", ".join(state.targets)
			navigate.emit(1))
	UI.label(quick, "Choose an equatorial imaging preset or create a mission. Results use your actual selected gameplay components.", 14, "9cb0c8")
	actions(-1, 1, "Continue Mission")

func result_history() -> Array:
	var history: Array = []
	var ids: Array = []
	for record in state.get("evaluation_store", {}).get("history", []):
		history.append({"config": record.state.config_snapshot, "final_state": record.state, "validation": record.validation, "events": record.state.event_log.duplicate(true)})
		ids.append(record.state.run_id)
	for trace in state.get("run_history", []):
		if ids.has(trace.final_state.run_id): continue
		var display: Dictionary = trace.duplicate(true)
		if state.get("active_run_state", {}).get("run_id") == trace.final_state.run_id:
			display.final_state = state.active_run_state.duplicate(true)
		history.append(display)
	return history
