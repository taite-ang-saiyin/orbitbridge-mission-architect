extends VBoxContainer
signal navigate(index: int)
const UI = preload("res://ui/components/UI.gd")
const ORBIT = preload("res://scenes/ui/components/OperationsOrbitViewport.tscn")
@export var screen_id: String
var state: Dictionary
var content: VBoxContainer
var summary: Label
func _ready():
	add_theme_constant_override("separation", 12)
	var titles = {"MissionControl": ["MISSION CONTROL / LOCAL PROTOTYPE", "Choose your next mission"], "Start": ["YOUR MISSION STARTS HERE", "OrbitBridge – Mission Architect"], "MissionCreator": ["01 / DEFINE", "Give your mission a purpose"], "SpacecraftBuilder": ["02 / DESIGN", "Build for the mission"], "FlightReadiness": ["03 / REVIEW", "Ready for the next horizon"], "MissionOperations": ["04 / OPERATE", "Mission control"], "DebriefCompare": ["05 / LEARN", "Every mission tells a story"]}
	UI.label(self, titles[screen_id][0], 12, "6fd9eb")
	UI.label(self, titles[screen_id][1], 30)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
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
	reset_state()
	state.name = "Untitled Mission"
	navigate.emit(1)
func refresh_summary():
	if not is_instance_valid(summary):
		return
	summary.text = "%s\n\n%s\n%s\n\n%s observations\n%s orbits\n%s cr budget" % [mission_name(), state.objective, state.target, state.observations, state.duration, state.budget]
func mission_name() -> String:
	return state.name if not state.name.strip_edges().is_empty() else "Untitled Mission"
var results: Label
var report_view: Control
var recent_runs: Tree
var debrief_traces: Array = []
var selected_trace: Dictionary = {}
func debrief():
	var outcome = UI.panel(content, "SELECTED RUN")
	var select = OptionButton.new()
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.fit_to_longest_item = false
	debrief_traces = state.get("run_history", []).duplicate(true)
	var active: Dictionary = state.get("run_trace", {})
	var active_index: int = -1
	for index in range(debrief_traces.size()):
		if debrief_traces[index].get("evaluation_key") == active.get("evaluation_key"):
			active_index = index
	if active_index < 0 and not active.is_empty():
		debrief_traces.append(active)
		active_index = debrief_traces.size() - 1
	for trace in debrief_traces:
		select.add_item(trace.final_state.run_id)
	outcome.add_child(select)
	results = UI.label(outcome, "", 16)
	select.item_selected.connect(func(index): show_actual_run(index))
	var compare = UI.panel(content, "RECENT RUNS")
	recent_runs = Tree.new()
	recent_runs.name = "RecentRuns"
	recent_runs.columns = 4
	recent_runs.hide_root = true
	recent_runs.column_titles_visible = true
	recent_runs.custom_minimum_size.y = 112
	recent_runs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	compare.add_child(recent_runs)
	var titles: Array = ["Run", "Captured", "Returned MB", "Score"]
	for column in range(4):
		recent_runs.set_column_title(column, titles[column])
		recent_runs.set_column_expand(column, column == 0)
		recent_runs.set_column_custom_minimum_width(column, [140, 90, 130, 70][column])
	var tree_root: TreeItem = recent_runs.create_item()
	for trace in state.get("run_history", []):
		var item: TreeItem = recent_runs.create_item(tree_root)
		var report: Dictionary = trace.get("evaluation", {}).get("report", {})
		for column in range(4):
			item.set_text(column, [str(trace.final_state.run_id), str(report.get("observations_completed", "—")), str(report.get("returned_data_mb", "—")), str(report.get("score", "—"))][column])
		item.set_tooltip_text(0, str(trace.final_state.run_id))
	report_view = preload("res://ke3/results_control.tscn").instantiate()
	report_view.custom_minimum_size.y = 560
	report_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(report_view)
	report_view.retry_requested.connect(_retry_selected_run)
	show_actual_run(maxi(0, active_index))
	select.selected = maxi(0, active_index)
	var buttons = HBoxContainer.new()
	content.add_child(buttons)
	UI.button(buttons, "Modify Design", func(): navigate.emit(2))
	UI.button(buttons, "Start New Mission", new_mission)
	actions(4, 0, "Return Home")
func show_actual_run(index: int):
	if debrief_traces.is_empty():
		results.text = "Launch a validated mission to view actual totals."
		return
	var trace: Dictionary = debrief_traces[index]
	selected_trace = trace
	var final: Dictionary = trace.final_state
	var payload: Dictionary = preload("res://scripts/integration/mission_results.gd").presentation(trace)
	report_view.set_inputs(payload.context, payload.state, payload.report)
	if payload.report.is_empty():
		var error: Dictionary = payload.context.get("evaluation_error", {})
		results.text = "%s\n%s\n%s" % [final.run_id, error.get("message", "Evaluation unavailable"), error.get("suggested_fix", "")]
	else:
		results.text = "%s • %s • Score %s\nBattery %.3f Wh • Stored %.3f MB" % [final.run_id, payload.report.status, payload.report.score, final.energy_wh, final.stored_data_mb]

func _retry_selected_run(run_id: String) -> void:
	if selected_trace.get("final_state", {}).get("run_id") != run_id:
		return
	var retried: Dictionary = preload("res://scripts/integration/mission_runtime.gd").retry(state, selected_trace)
	if retried.get("ok", false):
		navigate.emit(4)
	else:
		results.text = retried.get("error", {}).get("message", "Retry unavailable")
		report_view.set_retry_pending(false)

func show_run(_key: String):
	show_actual_run(maxi(0, state.get("run_history", []).size() - 1))

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
