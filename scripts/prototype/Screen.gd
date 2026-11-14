extends VBoxContainer
signal navigate(index: int)
const UI = preload("res://ui/components/UI.gd")
const DATA = preload("res://data/mock/PrototypeData.gd")
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
		popup.dialog_text = "1. Define a mission.\n2. Select a spacecraft and policy.\n3. Review the fixed readiness checks.\n4. Play or step through mock events.\n5. Compare illustrative runs.\n\nAll values are local demonstration fixtures."
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
	var outcome = UI.panel(row, "MISSION OUTCOME / MOCK RESULTS")
	var select = OptionButton.new()
	select.add_item("Run A / Baseline (400 km)")
	select.add_item("Run B / Modified (500 km)")
	outcome.add_child(select)
	results = UI.label(outcome, "", 20)
	select.item_selected.connect(func(index): show_run("Run A" if index == 0 else "Run B"))
	show_run("Run A")
	var compare = UI.panel(row, "COMPARE THE TRADEOFFS")
	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 25)
	grid.add_theme_constant_override("v_separation", 16)
	compare.add_child(grid)
	var run_a = DATA.RUNS["Run A"]
	var run_b = DATA.RUNS["Run B"]
	for cell in ["METRIC", "RUN A", "RUN B", "Captured", str(run_a.captured), str(run_b.captured), "Delivered", str(run_a.delivered), str(run_b.delivered), "Returned data", run_a.data, run_b.data, "Battery min", run_a.battery, run_b.battery, "Storage peak", run_a.storage, run_b.storage, "Outcome", run_a.outcome, run_b.outcome]:
		UI.label(grid, cell, 14).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var explanation = UI.panel(content, "WHAT CAN WE LEARN?")
	UI.label(explanation, "In this reference comparison, Run A delivers all five observations. Run B uses a higher orbit preset and delivers four. These are authored examples; changing the design does not calculate a new result.", 16, "9cb0c8")
	var buttons = HBoxContainer.new()
	content.add_child(buttons)
	UI.button(buttons, "Modify Design", func(): navigate.emit(2))
	UI.button(buttons, "Start New Mission", new_mission)
	actions(4, 0, "Return Home")
func show_run(key: String):
	var run = DATA.RUNS[key]
	results.text = "%s  /  %s\n\nCaptured   %s\nDelivered   %s\nReturned data   %s\n\nBattery   %s\nStorage   %s" % [key, run.outcome, run.captured, run.delivered, run.data, run.battery, run.storage]

func mission_control():
	var row = columns()
	var intro = UI.panel(row, "ORBITBRIDGE / MISSION ARCHITECT")
	UI.label(intro, "Design. Plan. Execute.", 28)
	UI.label(intro, "Turn a science goal into a spacecraft mission. Define your targets, explore a design, and review an illustrative flight.", 17, "9cb0c8")
	var globe = ORBIT.instantiate()
	globe.custom_minimum_size = Vector2(280, 310)
	intro.add_child(globe)
	globe.configure(state)
	UI.label(intro, "All mission data and system results are local mock fixtures.", 13, "9cb0c8")
	var quick = UI.panel(row, "QUICK START")
	UI.button(quick, "Create New Mission  >", new_mission)
	UI.label(quick, "MISSION PRESETS", 14, "6fd9eb")
	for preset in ["Estuary Watch", "Tropical Forest Watch", "Polar Ice Survey"]:
		UI.button(quick, preset + "  >", func():
			reset_state()
			state.name = preset
			state.targets = ["Arctic Ice"] if preset == "Polar Ice Survey" else (["Tropical Forest"] if preset == "Tropical Forest Watch" else ["Tropical Forest", "Coastal Region"])
			state.target = ", ".join(state.targets)
			navigate.emit(1))
	UI.label(quick, "Choose a preset to begin with an example brief, or create a mission of your own. All results use illustrative mock data.", 14, "9cb0c8")
	actions(-1, 1, "Continue Mission")
