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
func debrief():
	var row = columns()
	var outcome = UI.panel(row, "MISSION TOTALS / HPC")
	var select = OptionButton.new()
	var history: Array = state.get("run_history", [])
	for trace in history: select.add_item(trace.final_state.run_id)
	outcome.add_child(select)
	results = UI.label(outcome, "", 20)
	select.item_selected.connect(func(index): show_actual_run(index))
	show_actual_run(maxi(0, history.size() - 1))
	select.selected = maxi(0, history.size() - 1)
	var compare = UI.panel(row, "RECENT RUNS")
	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 25)
	grid.add_theme_constant_override("v_separation", 16)
	compare.add_child(grid)
	for cell in ["RUN", "CAPTURED", "RETURNED MB"]: UI.label(grid, cell, 14)
	for trace in history:
		for cell in [trace.final_state.run_id, str(trace.final_state.observations_completed), "%.3f" % trace.final_state.returned_data_mb]: UI.label(grid, cell, 14)
	var explanation = UI.panel(content, "WHAT CAN WE LEARN?")
	UI.label(explanation, "These totals come from the HPC simulation using your selected policy. Captured observations and returned MB are independent goals. Mission scoring and causal feedback await KE2 integration. Orbital graphics are illustrative.", 16, "9cb0c8")
	var buttons = HBoxContainer.new()
	content.add_child(buttons)
	UI.button(buttons, "Modify Design", func(): navigate.emit(2))
	UI.button(buttons, "Start New Mission", new_mission)
	actions(4, 0, "Return Home")
func show_actual_run(index: int):
	var history: Array = state.get("run_history", [])
	if history.is_empty():
		results.text = "Launch a validated mission to view actual totals."
		return
	var trace: Dictionary = history[index]
	var final: Dictionary = trace.final_state
	results.text = "%s / %s\n%s\n\nCaptured %s / %s\nReturned %.3f / %s MB\nBattery %.3f Wh\nStored %.3f MB\n\nEvaluation pending KE2" % [final.run_id, final.run_status, trace.config.mission.title, final.observations_completed, trace.config.mission.required_observations, final.returned_data_mb, trace.config.mission.required_returned_data_mb, final.energy_wh, final.stored_data_mb]
	var captures_met: bool = final.observations_completed >= trace.config.mission.required_observations
	var data_met: bool = final.returned_data_mb + 0.00000001 >= trace.config.mission.required_returned_data_mb
	results.text += "\n\nCapture goal: " + ("met" if captures_met else "not met") + "\nReturned-data goal: " + ("met" if data_met else "not met")
	for target_id in trace.config.mission.get("target_regions", [trace.config.mission.target_region]):
		var count: int = int(final.get("observations_by_target", {}).get(target_id, 0))
		results.text += "\n%s: %s captures, %.3f MB returned" % [str(target_id).replace("_", " ").capitalize(), count, final.get("returned_data_by_target_mb", {}).get(target_id, 0.0)]
		if trace.config.mission.objective == "survey": results.text += " / " + ("survey delivery met" if int(final.get("observations_delivered_by_target", {}).get(target_id, 0)) > 0 else "survey delivery not met")

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
