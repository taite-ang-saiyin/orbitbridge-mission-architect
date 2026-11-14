extends VBoxContainer
signal navigate(index: int)
signal retry_requested
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
var credits_button: Button
var results_row: BoxContainer
var _retry_pending: bool = false
var _presentation_model: Dictionary = {}
func _ready():
	add_theme_constant_override("separation", 12)
	var titles = {"MissionControl": ["MISSION CONTROL / LOCAL PROTOTYPE", "Choose your next mission"], "Start": ["YOUR MISSION STARTS HERE", "OrbitBridge – Mission Architect"], "MissionCreator": ["01 / DEFINE", "Give your mission a purpose"], "SpacecraftBuilder": ["02 / DESIGN", "Build for the mission"], "FlightReadiness": ["03 / REVIEW", "Ready for the next horizon"], "MissionOperations": ["04 / OPERATE", "Mission control"], "DebriefCompare": ["05 / LEARN", "Every mission tells a story"]}
	UI.label(self, titles[screen_id][0], 12, "6fd9eb")
	UI.label(self, titles[screen_id][1], 30)
	var scroll = ScrollContainer.new()
	report_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	if screen_id == "DebriefCompare":
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
		popup.dialog_text = "1. Define a mission.\n2. Select a spacecraft and policy.\n3. Review KE1 readiness checks.\n4. Play or step through HPC events.\n5. Inspect actual run totals.\n\nAll values are local demonstration fixtures."
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
	var row = BoxContainer.new()
	results_row = row
	row.add_theme_constant_override("separation",18)
	content.add_child(row)
	resized.connect(_fit_results)
	_fit_results.call_deferred()
	var outcome = UI.panel(row, "MISSION RESULTS / KE2")
	outcome.get_parent().size_flags_stretch_ratio = 1.6
	var select = OptionButton.new()
	var history: Array = result_history()
	for trace in history: select.add_item(trace.final_state.run_id)
	outcome.add_child(select)
	results = UI.label(outcome, "", 20)
	select.item_selected.connect(func(index): show_actual_run(index))
	show_actual_run(maxi(0, history.size() - 1))
	select.selected = maxi(0, history.size() - 1)
	var compare = UI.panel(row, "RUN HISTORY")
	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 25)
	grid.add_theme_constant_override("v_separation", 16)
	compare.add_child(grid)
	for cell in ["RUN", "CAPTURED", "RETURNED MB"]: _history_cell(grid,cell)
	for trace in history:
		for cell in [PRESENTATION.text(trace.final_state.get("run_id")), PRESENTATION.text(trace.final_state.get("observations_completed")), PRESENTATION.number(trace.final_state,"returned_data_mb")]: _history_cell(grid,cell)
	var explanation = UI.panel(content, "WHAT CAN WE LEARN?")
	UI.label(explanation, "These totals come from the HPC simulation using your selected policy. Captured observations and returned MB are independent goals. KE2 reports and feedback are published once per run. Survey-specific scoring requires the current KE2 handoff. Orbital graphics are illustrative.", 16, "9cb0c8")
	var buttons = HBoxContainer.new()
	content.add_child(buttons)
	credits_button = UI.button(buttons,"Show credits",func(): report_scroll.ensure_control_visible(credits))
	retry_button = UI.button(buttons, "Retry Mission", _request_retry)
	UI.button(buttons, "Modify Design", func(): navigate.emit(2))
	UI.button(buttons, "Start New Mission", new_mission)
	var credit_panel = UI.panel(content,"SOURCE CREDITS / SUPPLIED SCOPES")
	credits = UI.label(credit_panel,"",14)
	show_actual_run(maxi(0,history.size()-1))
	actions(4, 0, "Return Home")
func _history_cell(parent: Node,value: String) -> void:
	var label: Label = UI.label(parent,value,14)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
func _fit_results() -> void:
	if is_instance_valid(results_row): results_row.vertical = size.x < 1000
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
	if _retry_pending: return
	_retry_pending = true
	retry_button.disabled = true
	retry_requested.emit()
func get_presentation_model() -> Dictionary:
	return _presentation_model.duplicate(true)
func show_actual_run(index: int):
	var history: Array = result_history()
	if history.is_empty():
		results.text = "Launch a validated mission to view actual totals."
		return
	var trace: Dictionary = history[clampi(index,0,history.size()-1)]
	_presentation_model = PRESENTATION.build(trace,state.get("evaluation_store",{}))
	results.text = _presentation_model.text
	if is_instance_valid(credits): credits.text = _presentation_model.credits
	# Keep the existing readiness attribution visible beside the report as well.
	if "NASA CubeSat 101" in _presentation_model.credits:
		results.text += "\n\nLaunch source: NASA CubeSat 101 (readiness; details under Show credits)."

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
	UI.label(intro, "KE1 readiness and HPC flight simulation / illustrative gameplay values.", 13, "9cb0c8")
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
