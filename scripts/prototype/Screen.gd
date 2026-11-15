extends VBoxContainer
signal navigate(index: int)
signal retry_requested
signal modify_requested
signal new_mission_requested
const COPY = preload("res://scripts/settings/MyanmarText.gd")
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
var credits_button: Control
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
var score_label: Label
var report_tabs: TabBar
var report_body: VBoxContainer
var report_sections: Array = []
var flight_name: Label
const SUMMARY = preload("res://scripts/presentation/DebriefSummary.gd")
const GOAL_PROGRESS = preload("res://scripts/presentation/GoalProgress.gd")
var goal_labels: Array[Label] = []
var goal_headings: Array[BoxContainer] = []
var target_deliveries: VBoxContainer
var missed_goals: Label
var progress_evidence: Label
var run_identity: Label
var qa_notice: Label
var _goal_progress: Dictionary = {}
const DESIGN_LAB = preload("res://scripts/presentation/DesignLabView.gd")
var design_lab: VBoxContainer
var _selected_execution_trace: Dictionary = {}
var _lab_response: Dictionary = {}
var _lab_error: Dictionary = {}
var _lab_feedback: String = ""
var _auto_pair_enabled: bool = false
var report_surface: PanelContainer
var result_hero: BoxContainer
var goal_verdicts: Array[Label] = []
var goal_bars: Array[ProgressBar] = []
var full_explanation: Label
var score_gauge: Control
var outcome_badge: Label
var overview_layout: BoxContainer
var experiment_panel: PanelContainer
var hero_copy: VBoxContainer
var design_lab_shortcut: Button
func _ready():
	add_theme_constant_override("separation", 12)
	var titles = {"MissionControl": ["MISSION CONTROL / LOCAL PROTOTYPE", "Choose your next mission"], "Start": ["YOUR MISSION STARTS HERE", "OrbitBridge – Mission Architect"], "MissionCreator": ["01 / DEFINE", "Give your mission a purpose"], "SpacecraftBuilder": ["02 / DESIGN", "Build for the mission"], "FlightReadiness": ["03 / REVIEW", "Ready for the next horizon"], "MissionOperations": ["04 / OPERATE", "Mission control"], "DebriefCompare": ["", "Mission debrief"]}
	var kicker = UI.label(self, titles[screen_id][0], 12, "6fd9eb")
	if screen_id == "DebriefCompare": kicker.hide()
	UI.label(self, titles[screen_id][1], 20 if screen_id == "DebriefCompare" else 25)
	if screen_id == "DebriefCompare":
		qa_notice = UI.label(self, "", 14, "f4d38b")
		qa_notice.hide()
	var scroll = ScrollContainer.new()
	report_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	if screen_id == "DebriefCompare":
		var surface = StyleBoxFlat.new()
		surface.bg_color = Color(0,0,0,0)
		surface.set_corner_radius_all(12)
		surface.set_content_margin_all(2)
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
	var row = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	add_child(row)
	if back >= 0:
		UI.button(row, "Back", func(): navigate.emit(back))
	if screen_id == "DebriefCompare":
		design_lab_shortcut = UI.button(row, "Design comparison", open_design_lab)
		design_lab_shortcut.name = "OpenDesignLab"
		design_lab_shortcut.custom_minimum_size.y = 44
		design_lab_shortcut.add_theme_stylebox_override("normal", preload("res://ui/theme/WorkbenchTheme.gd").box(Color("1b555d"), Color("399fa9")))
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var forward = UI.button(row, text + "  >", func(): navigate.emit(next))
	if screen_id == "DebriefCompare":
		forward.name = "AnotherMission"
		for button in row.get_children():
			if button is Button:
				button.add_theme_font_size_override("font_size", 18)
				button.custom_minimum_size.y = 44
				button.custom_minimum_size.x = clampf(button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 28, 90, 280)
				button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(center)
	report_surface = PanelContainer.new()
	var sheet = StyleBoxFlat.new()
	sheet.bg_color = Color("061522f5")
	sheet.set_corner_radius_all(14)
	sheet.set_content_margin_all(26)
	report_surface.add_theme_stylebox_override("panel", sheet)
	center.add_child(report_surface)
	report_body = VBoxContainer.new()
	report_body.add_theme_constant_override("separation", 22)
	report_surface.add_child(report_body)
	var history: Array = result_history()
	var select = OptionButton.new()
	select.clip_text = true
	select.custom_minimum_size = Vector2(1, 36)
	select.add_theme_font_size_override("font_size", 15)
	for i in history.size():
		select.add_item("Flight %s" % [i + 1])
		select.set_item_tooltip(i, str(history[i].final_state.run_id))
	report_body.add_child(select)
	select.visible = history.size() > 1
	select.item_selected.connect(show_actual_run)
	select.selected = maxi(0, history.size() - 1)

	var hero = BoxContainer.new()
	result_hero = hero
	hero.add_theme_constant_override("separation", 18)
	report_body.add_child(hero)
	hero_copy = VBoxContainer.new()
	hero_copy.add_theme_constant_override("separation", 8)
	hero_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hero.add_child(hero_copy)
	flight_name = UI.label(hero_copy, "", 18, "8ea9bb")
	run_identity = UI.label(hero_copy, "", 16, "8ea9bb")
	outcome_title = UI.label(hero_copy, "", 28, "b9f4e7")
	outcome_badge = UI.label(hero_copy, "", 16, "f4d38b")
	results = UI.label(hero_copy, "", 18, "c2d9e6")
	var score_group = VBoxContainer.new()
	score_group.add_theme_constant_override("separation", 8)
	score_group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hero.add_child(score_group)
	var score_caption = UI.label(score_group, "MISSION SCORE", 12, "8ea9bb")
	score_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_gauge = preload("res://ui/components/MissionScore.gd").new()
	score_group.add_child(score_gauge)
	var alignment = CenterContainer.new()
	alignment.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	score_gauge.add_child(alignment)
	score_label = UI.label(alignment, "", 23)
	score_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	report_tabs = TabBar.new()
	report_tabs.add_theme_font_size_override("font_size", 14)
	for mode in ["tab_selected", "tab_unselected", "tab_hovered", "tab_focus"]:
		var tab_style = StyleBoxFlat.new()
		tab_style.bg_color = Color(0,0,0,0)
		tab_style.content_margin_left = 12
		tab_style.content_margin_right = 12
		tab_style.content_margin_top = 8
		tab_style.content_margin_bottom = 8
		if mode in ["tab_selected", "tab_focus"]:
			tab_style.border_color = Color("76ddd8")
			tab_style.border_width_bottom = 2
		report_tabs.add_theme_stylebox_override(mode, tab_style)
	for caption in ["Overview", "Flight log", "Sources", "Design Lab"]: report_tabs.add_tab(caption)
	report_tabs.tab_changed.connect(select_report_tab)
	report_body.add_child(report_tabs)
	for i in 4:
		var section = VBoxContainer.new()
		section.add_theme_constant_override("separation", 14)
		report_body.add_child(section)
		report_sections.append(section)
	overview_layout = BoxContainer.new()
	overview_layout.add_theme_constant_override("separation", 18)
	report_sections[0].add_child(overview_layout)
	results_row = VBoxContainer.new()
	results_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_row.size_flags_stretch_ratio = 1.65
	results_row.add_theme_constant_override("separation", 12)
	overview_layout.add_child(results_row)
	UI.label(results_row, "MISSION GOALS", 12, "8ea9bb")
	for caption in ["Photos taken", "Data sent to Earth"]:
		var goal = VBoxContainer.new()
		goal.add_theme_constant_override("separation", 7)
		results_row.add_child(goal)
		var heading = BoxContainer.new()
		heading.add_theme_constant_override("separation", 10)
		goal_headings.append(heading)
		goal.add_child(heading)
		var title = UI.label(heading, caption, 18, "c2d9e6")
		goal_labels.append(title)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value = UI.label(heading, "", 20)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		goal_cards.append(value)
		var bar = ProgressBar.new()
		bar.step = 0.0
		bar.show_percentage = false
		bar.custom_minimum_size.y = 6
		goal.add_child(bar)
		goal_bars.append(bar)
		goal_verdicts.append(UI.label(goal, "", 14))
	photo_goal_value = goal_cards[0]
	data_goal_value = goal_cards[1]
	target_deliveries = VBoxContainer.new()
	target_deliveries.add_theme_constant_override("separation", 6)
	results_row.add_child(target_deliveries)
	missed_goals = UI.label(results_row, "", 14, "f4d38b")
	progress_evidence = UI.label(results_row, "", 12, "8ea9bb")
	experiment_panel = PanelContainer.new()
	experiment_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	experiment_panel.size_flags_stretch_ratio = 1.0
	var experiment_style = StyleBoxFlat.new()
	experiment_style.bg_color = Color("0a2033")
	experiment_style.border_color = Color("377a9d")
	experiment_style.border_width_left = 3
	experiment_style.set_corner_radius_all(10)
	experiment_style.set_content_margin_all(20)
	experiment_panel.add_theme_stylebox_override("panel", experiment_style)
	overview_layout.add_child(experiment_panel)
	var next_box = VBoxContainer.new()
	next_box.add_theme_constant_override("separation", 12)
	experiment_panel.add_child(next_box)
	UI.label(next_box, "YOUR NEXT FLIGHT", 12, "8ea9bb")
	UI.label(next_box, "Try one change", 18, "b9f4e7")
	next_experiment = UI.label(next_box, "", 14)
	var buttons = HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 14)
	buttons.add_theme_constant_override("v_separation", 8)
	next_box.add_child(buttons)
	retry_button = UI.button(buttons, "Modify design", _request_retry)
	same_mission_button = UI.button(buttons, "Retry same mission", _request_same_retry)
	for button in buttons.get_children():
		button.custom_minimum_size.y = 44
		button.add_theme_font_size_override("font_size", 14)
	var primary = preload("res://ui/theme/WorkbenchTheme.gd").box(Color("1b555d"), Color("1b555d"), 12)
	retry_button.add_theme_stylebox_override("normal", primary)
	same_mission_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	flight_details = report_sections[1]
	full_explanation = UI.label(flight_details, "", 14)
	flight_facts = UI.label(flight_details, "", 14)
	UI.label(flight_details, "LINKED EVIDENCE", 14, "8ea9bb")
	evidence = UI.label(flight_details, "", 14)
	previous_flights = VBoxContainer.new()
	flight_details.add_child(previous_flights)
	var grid = GridContainer.new()
	grid.name = "RunHistory"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	previous_flights.add_child(grid)
	for cell in ["Flight", "Photos", "Sent (MB)"]: _history_cell(grid, cell)
	for i in history.size():
		for cell in ["Flight " + str(i + 1), LANGUAGE.amount(history[i].final_state.get("observations_completed")), LANGUAGE.amount(history[i].final_state.get("returned_data_mb"))]: _history_cell(grid, cell)
	source_disclosure = report_sections[2]
	credits_button = report_tabs
	UI.label(source_disclosure, "SOURCE CREDITS", 14, "8ea9bb")
	credits = UI.label(source_disclosure, "", 14)
	source_links = VBoxContainer.new()
	source_disclosure.add_child(source_links)
	UI.label(source_disclosure, "An educational simulation. Orbit paths, contact windows and most hardware values are illustrative.", 14, "9cb7c9")
	design_lab = DESIGN_LAB.new()
	report_sections[3].add_child(design_lab)
	design_lab.modify_current_requested.connect(_request_retry)
	design_lab.save_a_requested.connect(_lab_save)
	design_lab.modify_a_requested.connect(_lab_continue)
	design_lab.clear_a_requested.connect(_lab_clear)
	design_lab.compare_requested.connect(_lab_compare)
	design_lab.view_execution_requested.connect(_lab_open)
	resized.connect(_fit_results)
	report_scroll.resized.connect(_fit_results)
	_fit_results.call_deferred()
	show_actual_run(maxi(0, history.size() - 1), true)
	select_report_tab(0)
	actions(4, 0, "Another mission")

func open_design_lab() -> void:
	if _lab_response.is_empty() and design_lab.inputs.get("a_saved") and not design_lab.inputs.get("b", {}).is_empty(): _lab_compare()
	select_report_tab(3)
	_reveal_design_lab.call_deferred()

func _reveal_design_lab() -> void:
	if not is_instance_valid(design_lab): return
	if not _lab_response.is_empty():
		report_scroll.ensure_control_visible(design_lab.status_label)
		design_lab.status_label.focus_mode = Control.FOCUS_ALL
		design_lab.status_label.grab_focus()
		return
	report_scroll.ensure_control_visible(design_lab.modify_button.get_parent())
	var primary: Button = design_lab.compare_button if not design_lab.compare_button.disabled else (design_lab.save_button if not design_lab.save_button.disabled else design_lab.modify_button)
	if not primary.disabled: primary.grab_focus()

func select_report_tab(index: int) -> void:
	report_tabs.current_tab = index
	if is_instance_valid(result_hero): result_hero.visible = index != 3
	for i in report_sections.size(): report_sections[i].visible = i == index
	report_scroll.scroll_vertical = 0
	if index == 3 and is_instance_valid(design_lab) and _lab_response.is_empty() and design_lab.inputs.get("a_saved") and not design_lab.inputs.get("b", {}).is_empty(): _lab_compare()

func _history_cell(parent: Node,value: String) -> void:
	var label: Label = UI.label(parent,value,16)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
func _fit_results() -> void:
	if not is_inside_tree() or is_queued_for_deletion(): return
	if is_instance_valid(report_body): report_body.custom_minimum_size.x = minf(1000, maxf(280, report_scroll.size.x - 78))
	if is_instance_valid(result_hero): result_hero.vertical = report_scroll.size.x < 820
	if is_instance_valid(overview_layout): overview_layout.vertical = report_scroll.size.x < 960
	for i in goal_headings.size(): goal_headings[i].vertical = report_scroll.size.x < 600 or goal_labels[i].text.length() > 24
	if is_instance_valid(score_gauge):
		var compact: bool = get_viewport_rect().size.y < 800
		score_gauge.custom_minimum_size = Vector2(104,104) if compact else Vector2(118,118)
		report_body.add_theme_constant_override("separation", 10 if compact else 14)
		outcome_title.add_theme_font_size_override("font_size", 28)
		report_surface.get_theme_stylebox("panel").set_content_margin_all(14 if compact else 18)
		experiment_panel.get_theme_stylebox("panel").set_content_margin_all(12)
		hero_copy.add_theme_constant_override("separation", 4 if compact else 8)
func _report_keys(event: InputEvent) -> void:
	if not report_scroll.has_focus() or not event is InputEventKey or not event.pressed: return
	if event.alt_pressed or event.ctrl_pressed or event.meta_pressed: return
	var maximum: int = maxi(0,floori(report_scroll.get_v_scroll_bar().max_value-report_scroll.get_v_scroll_bar().page))
	var distance: int = 0
	match event.keycode:
		KEY_DOWN: distance = 32
		KEY_UP: distance = -32
		KEY_PAGEDOWN: distance = maxi(32,int(report_scroll.size.y)-32)
		KEY_PAGEUP: distance = -maxi(32,int(report_scroll.size.y)-32)
		KEY_HOME: distance = -maximum
		KEY_END: distance = maximum
		_: return
	if maximum == 0: return
	report_scroll.scroll_vertical = clampi(report_scroll.scroll_vertical+distance,0,maximum)
	report_scroll.accept_event()
func _request_retry() -> void:
	if retry_button.disabled or _retry_pending or _presentation_model.get("state") not in ["report", "evaluation_error", "unsupported_report"]: return
	_retry_pending = true
	retry_button.disabled = true
	same_mission_button.disabled = true
	modify_requested.emit()
func _request_same_retry() -> void:
	if same_mission_button.disabled or _retry_pending or _presentation_model.get("state") not in ["report", "evaluation_error", "unsupported_report"]: return
	_retry_pending = true
	retry_button.disabled = true
	same_mission_button.disabled = true
	retry_requested.emit()
func get_presentation_model() -> Dictionary:
	return _presentation_model.duplicate(true)
func show_actual_run(index: int, auto_compare: bool = false):
	var history: Array = result_history()
	if history.is_empty():
		outcome_title.text = "Your results will appear here"
		results.text = "Finish a flight to see how you did."
		return
	var trace: Dictionary = history[clampi(index, 0, history.size() - 1)]
	show_execution(trace, auto_compare)

func show_execution(trace: Dictionary, auto_compare: bool = true) -> void:
	_auto_pair_enabled = auto_compare
	_selected_execution_trace = trace.duplicate(true)
	_lab_response.clear()
	_lab_error.clear()
	_lab_feedback = ""
	_presentation_model = PRESENTATION.build(trace, state.get("evaluation_store", {}))
	_presentation_model.execution_key = preload("res://scripts/integration/mission_results.gd").input_key(trace)
	var player: Dictionary = LANGUAGE.report(_presentation_model, trace)
	outcome_title.text = player.headline
	var outcome_color = "b9f4e7" if _presentation_model.get("report", {}).get("status") == "success" else "f4d38b"
	outcome_title.add_theme_color_override("font_color", Color(outcome_color))
	photo_goal_value.text = "%s / %s" % [player.photos, player.photo_goal]
	data_goal_value.text = "%s / %s MB" % [player.data, player.data_goal]
	COPY.raw(flight_name, "text", str(trace.config.mission.get("title", "Your flight")))
	score_label.text = player.score
	score_label.add_theme_font_size_override("font_size", 18)
	score_label.tooltip_text = "Mission score"
	score_gauge.set_score(_presentation_model.get("report", {}).get("score"), Color(outcome_color))
	var report: Dictionary = _presentation_model.get("report", {})
	outcome_badge.text = {"success":"SUCCESS", "partial":"PARTIAL RESULT", "failed":"GOALS NOT REACHED"}.get(report.get("status"), "RESULT NOT AVAILABLE")
	if report.get("run_status", trace.final_state.get("run_status")) == "aborted" and _presentation_model.get("state") != "stale_report": outcome_badge.text = "STOPPED EARLY · NOT SCORED"
	outcome_badge.add_theme_color_override("font_color", Color(outcome_color))
	var summary: Dictionary = SUMMARY.build(_presentation_model, trace)
	results.text = summary.text if trace.config.mission.get("objective") == "imaging" and not summary.text.is_empty() else player.summary
	if _presentation_model.get("state") == "report":
		COPY.bind(full_explanation, "text", "Producer explanation\n{0}", [str(report.get("explanation", "Unavailable"))])
	elif _presentation_model.get("state") == "evaluation_error":
		var error: Dictionary = _presentation_model.get("evaluation_error", {})
		var prefix: String = "Your Survey flight is complete. Survey scoring is not available yet; you can still review the photos and data you collected." if trace.config.mission.get("objective") == "survey" else "Evaluation unavailable for this flight. Your recorded measurements are shown below."
		COPY.bind(full_explanation, "text", prefix + "\n{0} · {1}\n{2}", [error.get("code", "Unavailable"), error.get("field_path", "Unavailable"), error.get("message", "Unavailable")])
	else: COPY.bind(full_explanation, "text", player.summary, [])
	render_goal_progress(trace, _presentation_model)
	var suggestion: Variant = report.get("next_experiment") if _presentation_model.get("state") == "report" else _presentation_model.get("evaluation_error", {}).get("suggested_fix")
	if suggestion is String and not suggestion.is_empty(): COPY.raw(next_experiment, "text", suggestion)
	else: COPY.bind(next_experiment, "text", player.next, [])
	flight_facts.text = player.targets + "\nBattery remaining: %s Wh\nData still on the spacecraft: %s MB\n\nCaptured observations and returned data are separate measurements. A complete delivery is counted only after the whole observation reaches Earth." % [player.battery, player.stored]
	COPY.bind(flight_facts, "tooltip_text", "Flight {0}", [trace.final_state.run_id])
	if not player.evidence_parts.is_empty(): COPY.pieces(evidence, "text", player.evidence_parts)
	else: COPY.bind(evidence, "text", "No specific cause was established by the recorded events.", [])
	var latest: Dictionary = state.get("run_trace", {})
	var selected_is_latest: bool = _presentation_model.execution_key == preload("res://scripts/integration/mission_results.gd").input_key(latest)
	# The current controller's generic Modify/Retry acts on run_trace, not the picker.
	# Historical actions need SE's execution-specific route before they can be enabled.
	var retry_allowed: bool = selected_is_latest and not _retry_pending and _presentation_model.state in ["report", "evaluation_error", "unsupported_report"]
	retry_button.disabled = not retry_allowed
	same_mission_button.disabled = not retry_allowed
	for button in [retry_button, same_mission_button]:
		button.tooltip_text = "" if selected_is_latest else "Return to the latest flight to modify or retry."
	refresh_design_lab()
	_open_pair_after_flight.call_deferred(trace.duplicate(true))
	COPY.pieces(credits, "text", LANGUAGE.credit_parts(_presentation_model))
	for link in source_links.get_children():
		source_links.remove_child(link)
		link.queue_free()
	var sources: Array = _presentation_model.get("source_credits", []).duplicate(true)
	var mass: Dictionary = _presentation_model.get("readiness_credit", {})
	if mass.get("source_id") == "cubesat_101_1u_sample":

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
		COPY.raw(link, "tooltip_text", str(source.get("title", "Reference")) + "\n" + url)
		link.custom_minimum_size.y = 44
		link.add_theme_font_size_override("font_size", 17)
		link.pressed.connect(func(): OS.shell_open(url))
		source_links.add_child(link)

func _lab_controller() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("offer_design_b") and node.has_method("get_saved_design_a"): return node
		node = node.get_parent()
	return null

func refresh_design_lab() -> void:
	var controller: Node = _lab_controller()
	if controller == null:
		design_lab.set_inputs(DESIGN_LAB.from_session(state, _selected_execution_trace))
		return
	var saved: Dictionary = controller.get_saved_design_a()
	var a: Dictionary = {}
	if saved.get("ok") and saved.get("execution") is Dictionary:
		var packet: Dictionary = saved.execution
		a = DESIGN_LAB.record(packet.trace, packet.evaluation.get("report", {}))
	var candidate: Dictionary = {}
	var key: String = str(_presentation_model.get("execution_key", ""))
	var selected: Dictionary = controller.get_execution(key)
	if selected.get("ok") and _presentation_model.get("state") in ["report", "evaluation_error"]:
		candidate = DESIGN_LAB.record(selected.execution.trace, _presentation_model.report)
	var b: Dictionary = {}
	var selection: Dictionary = state.get("design_lab", {})
	if not a.is_empty() and selection.get("selected_b_a") == a.get("execution_key"):
		var paired: Dictionary = controller.get_execution(str(selection.get("selected_b", "")))
		if paired.get("ok"):
			b = DESIGN_LAB.record(paired.execution.trace, paired.execution.evaluation.get("report", {}))
	if b.is_empty() and candidate.get("execution_key") != a.get("execution_key"): b = candidate
	if _lab_response.get("a_execution_key") != a.get("execution_key") or _lab_response.get("b_execution_key") != b.get("execution_key"): _lab_response.clear()
	var error: Dictionary = _lab_error.duplicate(true)
	if not saved.get("ok", false): error = saved.get("error", {}).duplicate(true)
	design_lab.set_inputs({"a":a, "b":b, "candidate":candidate,
		"a_saved":not a.is_empty(), "storage_available":true,
		"modify_saved_available":not a.is_empty(), "modify_current_available":not retry_button.disabled,
		"comparison_available":controller.comparison_available(),
		"comparison":_lab_response, "error":error, "feedback":_lab_feedback})

func _lab_result(reply: Dictionary, success: String = "") -> bool:
	_lab_error = reply.get("error", {}).duplicate(true) if not reply.get("ok", false) else {}
	_lab_feedback = success if reply.get("ok", false) else ""
	refresh_design_lab()
	return reply.get("ok", false)

func _lab_save(_run_id: String, key: String, replace: bool) -> void:
	var controller: Node = _lab_controller()
	if controller == null: return
	if replace:
		_lab_result(controller.replace_design_a(key, design_lab.confirmed_expected_a_key), "Saved A replaced. Both flights remain in history.")
	else:
		if not _lab_result(controller.offer_design_b(key), "Design A saved. Continue with Design B now, or choose Not now."): return
		var dialog: Node = controller.get_node_or_null("DesignASavedDialog")
		if dialog != null: dialog.tree_exited.connect(_lab_offer_closed)

func _lab_offer_closed() -> void:
	# The popup and storage belong to SE; dismissal performs no mutation here.
	if not is_inside_tree() or is_queued_for_deletion(): return
	_lab_feedback = "Design A stays saved. Continue with Design B whenever you are ready."
	refresh_design_lab()
	if design_lab.is_visible_in_tree() and not design_lab.modify_button.disabled: design_lab.modify_button.grab_focus()

func _lab_continue(_run_id: String, _key: String) -> void:
	var controller: Node = _lab_controller()
	if controller == null: return
	var reply: Dictionary = controller.continue_saved_design_a()
	if not reply.get("ok", false): _lab_result(reply)

func _lab_clear() -> void:
	var controller: Node = _lab_controller()
	if controller != null: _lab_result(controller.clear_design_a(design_lab.confirmed_expected_a_key), "Saved A cleared. Your flight history is preserved.")

func _lab_compare(requested_b_key: String = "") -> void:
	var controller: Node = _lab_controller()
	if controller == null: return
	var key: String = requested_b_key if not requested_b_key.is_empty() else str(design_lab.inputs.get("b", {}).get("execution_key", ""))
	var reply: Dictionary = controller.compare_executions(key)
	_lab_response.clear()
	if reply.get("ok", false):
		_lab_response = reply.get("comparison", {}).duplicate(true)
		# The provider's pair keys are checked by SE. Add display context only.
		if not _lab_response.has("mode"): _lab_response.mode = reply.get("mode")
		# Run and mission identities must come from the provider, never the selected page.
	_lab_result(reply)

func _lab_open(key: String) -> void:
	var controller: Node = _lab_controller()
	if controller == null: return
	var reply: Dictionary = controller.show_execution_result(key)
	if not reply.get("ok", false): _lab_result(reply)

func render_goal_progress(trace: Dictionary, model: Dictionary, supplied_details: Dictionary = {}) -> void:
	# Optional details are a view input only; runtime never creates pending-goal configs.
	_goal_progress = GOAL_PROGRESS.build(model, trace, supplied_details)
	var run_id: String = str(trace.get("final_state", {}).get("run_id", ""))
	var number: int = run_id.get_slice("_", run_id.get_slice_count("_") - 1).to_int()
	var caption: String = "Design B · Flight {0}" if trace.has("comparison_context") else "Flight {0}"
	var controller: Node = _lab_controller()
	if controller != null:
		var saved: Dictionary = controller.get_saved_design_a()
		if saved.get("execution") != null and saved.execution.execution_key == _presentation_model.get("execution_key"): caption = "Design A · Flight {0}"
	COPY.bind(run_identity, "text", caption, [number if number > 0 else {"copy":"Unavailable"}])
	COPY.raw(run_identity, "tooltip_text", run_id)
	COPY.raw(qa_notice, "text", str(_goal_progress.get("fixture_label", "")))
	qa_notice.visible = not qa_notice.text.is_empty()
	for i in 2:
		var goal: Dictionary = _goal_progress.primary if i == 0 else _goal_progress.data
		goal_labels[i].text = goal.label
		var actual: String = LANGUAGE.amount(goal.get("actual"))
		var required: String = LANGUAGE.amount(goal.get("required"))
		var unit: String = str(goal.value).trim_prefix(actual + " / " + required)
		COPY.bind(goal_cards[i], "text", "{0} / {1}{2}", [{"copy":"Unavailable"} if actual == "Unavailable" else actual, {"copy":"Unavailable"} if required == "Unavailable" else required, unit])
		goal_verdicts[i].text = goal.verdict
		var tint = Color("b9f4e7") if goal.known and goal.reached else Color("f4d38b")
		goal_verdicts[i].add_theme_color_override("font_color", tint)
		goal_bars[i].value = goal.progress
		goal_bars[i].visible = goal.progress_known
		var fill = StyleBoxFlat.new()
		fill.bg_color = tint
		fill.set_corner_radius_all(3)
		goal_bars[i].add_theme_stylebox_override("fill", fill)
	for child in target_deliveries.get_children():
		target_deliveries.remove_child(child)
		child.queue_free()
	var extra_goals: Array = _goal_progress.get("extra_goals", [])
	target_deliveries.visible = not _goal_progress.deliveries.is_empty() or not extra_goals.is_empty()
	if target_deliveries.visible:
		UI.label(target_deliveries, "COMPLETE DELIVERIES BY TARGET", 12, "8ea9bb")
		for goal in extra_goals:
			UI.label(target_deliveries, goal.label + " · " + goal.value, 16)
			UI.label(target_deliveries, goal.verdict, 13, "b9f4e7" if goal.known and goal.reached else "f4d38b")
		for delivery in _goal_progress.deliveries:
			UI.label(target_deliveries, delivery.label + " · " + delivery.value, 16)
			UI.label(target_deliveries, delivery.verdict, 13, "b9f4e7" if delivery.known and delivery.reached else "f4d38b")
			UI.label(target_deliveries, delivery.get("context_text", "Target measurements: Unavailable"), 14, "8ea9bb")
		UI.label(target_deliveries, "Captured-only and partial packets are not complete deliveries.", 12, "8ea9bb")
	missed_goals.text = "Goal progress\n" + _goal_progress.missed_text
	COPY.bind(progress_evidence, "text", "Same-run events\n{0}", [_goal_progress.evidence_text if not _goal_progress.evidence_ids.is_empty() else {"copy":"Unavailable"}])
	_fit_results.call_deferred()

func get_goal_progress() -> Dictionary:
	return _goal_progress.duplicate(true)

func report_score_unavailable(model: Dictionary) -> bool:
	return model.get("report", {}).get("score") == null

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
		var stored: Dictionary = preload("res://scripts/integration/mission_results.gd").get_execution(state, str(record.get("execution_key", "")))
		if stored.ok: history.append(stored.execution.trace.duplicate(true))
		else: history.append({"config": record.state.config_snapshot, "final_state": record.state, "validation": record.validation, "events": record.state.event_log.duplicate(true)})
		ids.append(record.state.run_id)
	for trace in state.get("run_history", []):
		if ids.has(trace.final_state.run_id): continue
		var display: Dictionary = trace.duplicate(true)
		if state.get("active_run_state", {}).get("run_id") == trace.final_state.run_id:
			display.final_state = state.active_run_state.duplicate(true)
		history.append(display)
	return history

func _open_pair_after_flight(trace: Dictionary) -> void:
	if not _auto_pair_enabled or not is_inside_tree() or _presentation_model.get("execution_key") != preload("res://scripts/integration/mission_results.gd").input_key(trace): return
	var origin: Dictionary = trace.get("comparison_context", {})
	if origin.is_empty(): return
	var controller: Node = _lab_controller()
	if controller == null: return
	var saved: Dictionary = controller.get_saved_design_a()
	if saved.get("execution") == null or saved.execution.execution_key != origin.get("saved_a"): return
	_lab_compare(preload("res://scripts/integration/mission_results.gd").input_key(trace))
	open_design_lab()
