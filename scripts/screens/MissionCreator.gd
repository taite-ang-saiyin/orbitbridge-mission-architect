extends "res://scripts/screens/Workbench.gd"
const REVIEW = preload("res://scripts/integration/mission_review.gd")
const THUMB = preload("res://ui/components/TargetThumbnail.gd")
var name_input: LineEdit
var description_input: TextEdit
var description_count: Label
var observation_input: SpinBox
var returned_data_input: SpinBox
var budget_input: HSlider
var budget_label: Label
var target_note: Label
var coverage_rows: VBoxContainer
var target_buttons: Dictionary = {}
var objective_buttons: Dictionary = {}
var duration_buttons: Dictionary = {}
var count_buttons: Dictionary = {}
var target_limit = 2
var region = "All"
var target_grid: GridContainer
var coverage_view: SubViewportContainer
var budget_ticks: Control
var orbit_select: OptionButton
var coverage_frame: Control
var region_buttons: Dictionary = {}
var right_column: VBoxContainer
var requirements_row: BoxContainer
var review_dialog: Control
func _ready() -> void:
	screen_id = "MissionCreator"
	setup("02 / MISSION DESIGN", "Mission Creator", "Define the objective, targets and boundaries of your mission.", 0, 2, "Next: Spacecraft Builder")
	target_limit = state.target_limit
	workspace = row(content)
	form_columns = row(workspace)
	form_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_columns.size_flags_stretch_ratio = 4.2
	var left = column(form_columns)
	left.add_theme_constant_override("separation", 8)
	var center = column(form_columns, 1.1)
	right_column = center
	build_details(left)
	build_objectives(left)
	build_targets(left)
	build_coverage(center)
	build_requirements(center)
	resized.connect(responsive)
	right_column.resized.connect(responsive)
	call_deferred("responsive")
	for connection in next_button.pressed.get_connections(): next_button.pressed.disconnect(connection.callable)
	next_button.pressed.connect(continue_to_builder)
	refresh()
func build_details(parent: Node) -> void:
	var box = section(parent, "01   MISSION DETAILS")
	box.add_theme_constant_override("separation", 5)
	UI.label(box, "Mission name *", 12, "a8c1d2")
	name_input = LineEdit.new()
	name_input.text = state.name
	name_input.max_length = 48
	name_input.placeholder_text = "Name your mission"
	box.add_child(name_input)
	name_input.text_changed.connect(func(value):
		state.name = value
		refresh())
	UI.label(box, "Description / optional", 12, "a8c1d2")
	description_input = TextEdit.new()
	description_input.custom_minimum_size.y = 52
	description_input.add_theme_font_size_override("font_size", 13)
	description_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	description_input.text = state.description
	box.add_child(description_input)
	description_count = UI.label(box, "", 11, "7e9cb3")
	description_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	description_input.text_changed.connect(func():
		if description_input.text.length() > 200:
			description_input.text = description_input.text.left(200)
			description_input.set_caret_column(200)
		state.description = description_input.text
		refresh())
func build_objectives(parent: Node) -> void:
	var box = section(parent, "02   MISSION OBJECTIVE")
	if state.get("schema_version", 1) == 2:
		UI.label(box, state.objective + " · Complete the goal and return the required data", 13, "9bddd5")
		if state.get("preset_id") == "communication":
			UI.label(box, "Count accepted transmissions that return data; empty or rejected attempts do not count.", 12, "a5bed0")
		elif state.get("preset_id") == "weather_monitoring":
			UI.label(box, "Observe the selected region on different orbits and return the required data.", 12, "a5bed0")
	else:
		UI.label(box, "Choose pooled imagery or a survey across each selected target.", 12, "a5bed0")
		UI.label(box, "Survey can simulate target deliveries; a Survey score is not available in this build.", 11, "efc371")
	var cards = row(box)
	for entry in [["Capture Imagery", "Capture images and return the required MB to Earth."], ["Survey Target Regions", "Return at least one complete observation from every selected target."]]:
		var button = choice_card(cards, entry[0], entry[1], func():
			if state.get("schema_version", 1) == 2: return
			state.objective = entry[0]
			refresh(), 92)
		objective_buttons[entry[0]] = button
func build_targets(parent: Node) -> void:
	var box = section(parent, "03   SELECT TARGETS")
	var counts = row(box)
	counts.add_theme_constant_override("separation", 5)
	UI.label(counts, "Number of targets", 11, "9db9cb").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for count in [1, 2]:
		var button = UI.button(counts, str(count), func(): set_target_limit(count))
		button.toggle_mode = true
		count_buttons[count] = button
	var selector = row(box)
	var regions = VBoxContainer.new()
	regions.custom_minimum_size.x = 95
	selector.add_child(regions)
	UI.label(regions, "Target region", 11, "a5bed0")
	for entry in [["Equatorial", "Equatorial"], ["Mid-Latitude", "Mid-latitude"], ["Polar", "Polar"]]:
		var region_button = UI.button(regions, entry[1], func():
			region = "All" if region == entry[0] else entry[0]
			refresh_targets())
		region_button.toggle_mode = true
		region_button.add_theme_font_size_override("font_size", 11)
		region_button.custom_minimum_size.y = 32
		region_buttons[entry[0]] = region_button
	var locations = column(selector)
	UI.label(locations, "Target locations", 11, "a5bed0")
	target_grid = GridContainer.new()
	target_grid.columns = 3
	target_grid.add_theme_constant_override("h_separation", 8)
	target_grid.add_theme_constant_override("v_separation", 8)
	locations.add_child(target_grid)
	for entry in CATALOG.TARGETS:
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 78)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.tooltip_text = entry[0] + " / " + entry[1]
		target_grid.add_child(button)
		var margin = MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 5)
		button.add_child(margin)
		var layout = VBoxContainer.new()
		layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layout.add_theme_constant_override("separation", 4)
		margin.add_child(layout)
		var thumb = THUMB.new()
		thumb.terrain = entry[2]
		layout.add_child(thumb)
		var caption = UI.label(layout, entry[0].replace("Antarctic Region", "Antarctic"), 10)
		caption.custom_minimum_size.y = 28
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fit_card = func(): button.custom_minimum_size.y = margin.get_combined_minimum_size().y
		margin.minimum_size_changed.connect(fit_card)
		fit_card.call_deferred()
		button.pressed.connect(toggle_target.bind(entry[0]))
		target_buttons[entry[0]] = button
	target_note = UI.label(box, "", 11, "79c9d6")
func build_coverage(parent: Node) -> void:
	var box = section(parent, "04   ORBIT COVERAGE PREVIEW")
	UI.label(box, "Preview the selected orbit and target access.", 12, "8ca9bd")
	orbit_select = dropdown(box.get_child(0), CATALOG.ORBITS, state.orbit, func(value):
		state.orbit = value
		refresh())
	var view = preload("res://scenes/ui/components/OperationsOrbitViewport.tscn").instantiate()
	view.set_script(preload("res://scripts/visualization/CreatorOrbitViewport.gd"))
	coverage_view = view
	coverage_frame = Control.new()
	coverage_frame.custom_minimum_size = Vector2(230, 320)
	box.add_child(coverage_frame)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coverage_frame.add_child(view)
	view.configure(state)
	view.set_preview_playing(true)
	view.orbit_selected.connect(func(id):
		for label in preload("res://scripts/integration/mission_runtime.gd").ORBITS:
			if preload("res://scripts/integration/mission_runtime.gd").ORBITS[label] == id: state.orbit = label
		refresh())
	var coverage_overlay = PanelContainer.new()
	coverage_overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	coverage_overlay.offset_left = -154
	coverage_overlay.offset_right = -8
	coverage_overlay.offset_top = 10
	coverage_frame.add_child(coverage_overlay)
	coverage_rows = VBoxContainer.new()
	coverage_rows.add_theme_constant_override("separation", 4)
	coverage_overlay.add_child(coverage_rows)
	UI.label(box, "Drag to rotate · scroll to zoom · click an orbit to select.", 11, "7897ad")
func build_requirements(parent: Node) -> void:
	requirements_row = BoxContainer.new()
	requirements_row.add_theme_constant_override("separation", 12)
	parent.add_child(requirements_row)
	var box = section(requirements_row, "05   REQUIRED OBSERVATIONS")
	var captures = row(box)
	UI.label(captures, "Images (1–8)", 12, "a5bed0").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	observation_input = SpinBox.new()
	observation_input.min_value = 1
	observation_input.max_value = 20
	observation_input.value = state.observations
	observation_input.custom_minimum_size = Vector2(100, 38)
	observation_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	captures.add_child(observation_input)
	observation_input.value_changed.connect(func(value):
		state.observations = int(value)
		refresh())
	UI.label(box, "Range: 1–20", 11, "a5bed0")
	var returned = row(box)
	UI.label(returned, "Return data (MB)", 12, "a5bed0").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not state.has("required_returned_data_mb"): state.required_returned_data_mb = float(state.observations) * 12.0
	returned_data_input = SpinBox.new()
	returned_data_input.min_value = 0.1
	returned_data_input.max_value = 10000
	returned_data_input.step = 0.1
	returned_data_input.value = state.required_returned_data_mb
	returned_data_input.custom_minimum_size = Vector2(100, 38)
	returned_data_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	returned.add_child(returned_data_input)
	returned_data_input.value_changed.connect(func(value):
		state.required_returned_data_mb = value
		refresh())
	box = section(requirements_row, "06   MISSION DURATION")

	var durations = row(box)
	durations.add_theme_constant_override("separation", 5)
	for duration in [3, 6, 9]:
		var button = UI.button(durations, "%s\nOrbits" % duration, func():
			state.duration = duration
			refresh())
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 76)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 12)
		duration_buttons[duration] = button
	box = section(parent, "07   BUDGET")
	var budget_header = box.get_child(0)
	budget_label = UI.label(budget_header, "", 14, "d9f5ff")
	budget_label.custom_minimum_size.x = 110
	budget_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	budget_input = HSlider.new()
	budget_input.min_value = 60
	budget_input.max_value = 150
	budget_input.step = 1
	budget_input.value = state.budget
	budget_input.custom_minimum_size.y = 28
	box.add_child(budget_input)
	budget_input.value_changed.connect(func(value):
		state.budget = int(value)
		refresh())
	budget_ticks = preload("res://scripts/ui/BudgetTicks.gd").new()
	budget_ticks.slider = budget_input
	box.add_child(budget_ticks)

func set_target_limit(limit: int) -> void:
	target_limit = limit
	state.target_limit = limit
	while state.targets.size() > limit:
		state.targets.pop_back()
	refresh()
func toggle_target(target: String) -> void:
	if target in state.targets:
		if state.targets.size() > 1:
			state.targets.erase(target)
	elif state.targets.size() < target_limit:
		state.targets.append(target)
	else:
		# A full selection is replaced by the newly chosen target.
		state.targets.pop_back()
		state.targets.append(target)
	refresh()
func refresh_targets() -> void:
	for key in region_buttons:
		region_buttons[key].set_pressed_no_signal(region == key)
	for entry in CATALOG.TARGETS:
		target_buttons[entry[0]].visible = region == "All" or region == entry[1]
		target_buttons[entry[0]].set_pressed_no_signal(entry[0] in state.targets)
func refresh() -> void:
	if not is_instance_valid(coverage_view): return
	state.target = ", ".join(state.targets)
	next_button.text = "Next: Spacecraft Builder  →"

	description_count.text = "%s / 200" % state.description.length()
	budget_label.text = "%s Credits" % state.budget
	target_note.text = "%s / %s selected · Click the region again to show all." % [state.targets.size(), target_limit]
	for objective in objective_buttons:
		objective_buttons[objective].set_pressed_no_signal(state.objective == objective)
	for duration in duration_buttons:
		duration_buttons[duration].set_pressed_no_signal(state.duration == duration)
	for count in count_buttons:
		count_buttons[count].set_pressed_no_signal(target_limit == count)
	refresh_targets()
	coverage_view.configure(state)
	orbit_select.select(maxi(0, CATALOG.ORBITS.find(state.orbit)))
	for child in coverage_rows.get_children():
		coverage_rows.remove_child(child)
		child.queue_free()
	for target in state.targets:
		var count = CATALOG.window_count(target, state.orbit)
		UI.label(coverage_rows, "%s\n%s windows" % [target, count], 10, "66e6b7" if count > 0 else "efc371")
		var bar = ProgressBar.new()
		bar.max_value = 4
		bar.value = count
		bar.show_percentage = false
		bar.custom_minimum_size.y = 5
		coverage_rows.add_child(bar)
	next_button.disabled = (state.name.strip_edges().is_empty() or (state.objective == "Survey Target Regions" and state.observations < state.targets.size()))
	next_button.tooltip_text = "Enter a name and request at least one capture per survey target." if next_button.disabled else "Continue to spacecraft design"
func responsive() -> void:
	if not is_instance_valid(right_column):
		return
	fit_navigation()
	form_columns.add_theme_constant_override("separation", 12)
	requirements_row.vertical = right_column.size.x < 560
	coverage_frame.custom_minimum_size.y = clampf(size.y * 0.52, 320, 480)

func continue_to_builder() -> void:
	open_mission_review()

func open_mission_review() -> void:
	if not is_instance_valid(review_dialog):
		var layer = CanvasLayer.new()
		layer.layer = 100
		add_child(layer)
		review_dialog = preload("res://ui/components/MissionSummaryReview.gd").new()
		layer.add_child(review_dialog)
		review_dialog.confirmed.connect(func(reviewed):
			if REVIEW.confirm(state, reviewed):
				refresh()
				navigate.emit(2)
			else:
				refresh()
				open_mission_review())
	review_dialog.show_summary(state)
