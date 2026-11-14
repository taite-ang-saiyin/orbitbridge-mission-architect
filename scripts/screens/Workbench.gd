extends VBoxContainer
signal navigate(index: int)
const UI = preload("res://ui/components/UI.gd")
const CATALOG = preload("res://data/mock/DesignCatalog.gd")
var state: Dictionary = {}
var content: VBoxContainer
var workspace: HBoxContainer
var summary: Label
var summary_column: VBoxContainer
var form_columns: HBoxContainer
var scroll: ScrollContainer
var next_button: Button
var screen_id: String
var heading: HBoxContainer
var badge: Label
var previous: Button
var progress_nav: HBoxContainer
func setup(_kicker: String, title: String, subtitle: String, back: int, next: int, next_text: String) -> void:
	CATALOG.ensure(state)
	theme = preload("res://ui/theme/WorkbenchTheme.gd").build()
	add_theme_constant_override("separation", 10)
	heading = HBoxContainer.new()
	add_child(heading)
	var titles = VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(titles)
	
	UI.label(titles, title, 25)
	UI.label(titles, subtitle, 12, "9ab5c8")
	progress_nav = HBoxContainer.new()
	progress_nav.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress_nav.add_theme_constant_override("separation", 4)
	heading.add_child(progress_nav)
	for index in 6:
		var step = UI.button(progress_nav, "", func(): navigate.emit(index))
		step.toggle_mode = true
		step.set_pressed_no_signal(index == {"MissionCreator": 1, "SpacecraftBuilder": 2, "FlightReadiness": 3, "MissionOperations": 4}.get(screen_id, 0))
		step.add_theme_font_size_override("font_size", 12)
		step.custom_minimum_size.y = 36
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	add_child(actions)
	previous = UI.button(actions, "<  Back: " + {0: "Mission Control", 1: "Mission Creator", 2: "Spacecraft Builder", 3: "Flight Readiness"}.get(back, "Back"), func(): navigate.emit(back))
	previous.custom_minimum_size.y = 44
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	next_button = UI.button(actions, next_text + "  >", func(): navigate.emit(next))
	next_button.custom_minimum_size = Vector2(265, 48)
	next_button.add_theme_stylebox_override("normal", preload("res://ui/theme/WorkbenchTheme.gd").box(Color("007cdb"), Color("31eaff"), 10))
func section(parent: Node, title: String) -> VBoxContainer:
	var shell = PanelContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(shell)
	var panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 8)
	shell.add_child(panel)
	var line = HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	panel.add_child(line)
	var parts = title.split("   ", true, 1)
	if parts.size() == 2:
		var number = Label.new()
		number.text = str(int(parts[0]))
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.custom_minimum_size = Vector2(26, 26)
		number.add_theme_stylebox_override("normal", preload("res://ui/theme/WorkbenchTheme.gd").box(Color("007cc7"), Color("39e5ff"), 2))
		line.add_child(number)
	UI.label(line, parts[-1].capitalize(), 17).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return panel
func column(parent: Node, ratio: float = 1.0) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_stretch_ratio = ratio
	box.add_theme_constant_override("separation", 12)
	parent.add_child(box)
	return box
func row(parent: Node) -> HBoxContainer:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	parent.add_child(box)
	return box
func dropdown(parent: Node, options: Array, selected: String, change: Callable) -> OptionButton:
	var select = OptionButton.new()
	for option in options:
		select.add_item(option)
	select.selected = maxi(0, options.find(selected))
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.item_selected.connect(func(index): change.call(options[index]))
	parent.add_child(select)
	return select
func summary_text() -> String:
	return "%s\n\nOBJECTIVE\n%s\n\nTARGETS\n%s\n\nOBSERVATIONS   %s\nDURATION   %s orbits\nBUDGET   %s credits" % [state.name if not state.name.strip_edges().is_empty() else "Untitled Mission", state.objective, "\n".join(state.targets), state.observations, state.duration, state.budget]

func fit_navigation() -> void:
	# Preserve the reference's compact dashboard rhythm; larger windows reveal more canvas.
	var gap = 12 if size.x >= 1250 else 10
	add_theme_constant_override("separation", gap)
	previous.custom_minimum_size.y = 48
	next_button.custom_minimum_size = Vector2(270, 48)
	var names = ["Start", "Create", "Build", "Check", "Operate", "Debrief"] if size.x >= 1180 else ["", "", "", "", "", ""]
	for index in 6:
		progress_nav.get_child(index).text = str(index + 1) + "  " + names[index]

func fit_workbench() -> void:
	fit_navigation()
	var gap = 12 if size.x >= 1250 else 10
	workspace.add_theme_constant_override("separation", gap)
	form_columns.add_theme_constant_override("separation", gap)
	var destination: Node = content
	if size.x >= 1180:
		destination = workspace
	if summary_column.get_parent() != destination:
		summary_column.reparent(destination)

func choice_card(parent: Node, title: String, detail: String, action: Callable, height: float = 100) -> Button:
	var button = Button.new()
	button.toggle_mode = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, height)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(button)
	button.pressed.connect(action)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	button.add_child(margin)
	var layout = VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)
	UI.label(layout, title, 14).mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.label(layout, detail, 12, "b4c9d9").mouse_filter = Control.MOUSE_FILTER_IGNORE
	return button
