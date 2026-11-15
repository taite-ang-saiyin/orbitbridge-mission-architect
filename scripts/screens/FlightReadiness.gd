extends "res://scripts/screens/Workbench.gd"
const STATUS = preload("res://ui/components/ReadinessStatus.gd")
const GAUGE = preload("res://ui/components/ResourceGauge.gd")
const PREVIEW = preload("res://scenes/ui/components/OperationsOrbitViewport.tscn")
var validation: Dictionary = {}
var check_buttons: Dictionary = {}
var check_details: Dictionary = {}
var preview: SubViewportContainer
var preview_frame: Control
var specs: Label
var orbit_label: Label
var warning_label: Label
var warning_details_button: Button
var warning_dialog: Control
var readiness_label: Label
var gauges: Dictionary = {}
var main_columns: BoxContainer
var banners: BoxContainer
var checklist: VBoxContainer
var coverage: VBoxContainer
var right_column: VBoxContainer
var lower_panels: BoxContainer
var preview_composition: BoxContainer
var specs_card: PanelContainer
var coverage_value: Label
func _ready() -> void:
	screen_id = "FlightReadiness"
	validation = preload("res://scripts/integration/mission_runtime.gd").review(state)
	setup("04 / PREFLIGHT REVIEW", "Flight Readiness", "Review system checks, resolve warnings, and prepare your mission for launch.", 2, 4, "Launch Mission")
	if state.has("design_lab_route"):
		next_button.text = "Launch Design B"
		UI.label(content, "DESIGN B · Saved A remains unchanged", 13, "6adacb")
	main_columns = flexible_row(content)
	workspace = main_columns
	checklist = section(main_columns, "READINESS CHECKLIST")
	checklist.get_parent().size_flags_stretch_ratio = 1.0
	checklist.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	build_checklist()
	var right = column(main_columns, 2.2)
	right_column = right
	build_preview(right)
	var lower = flexible_row(right)
	lower_panels = lower
	build_resources(lower)
	build_coverage(lower)
	build_banners()
	resized.connect(responsive)
	call_deferred("responsive")
	right_column.resized.connect(responsive)
	preview_frame.resized.connect(responsive)
	var result = preload("res://data/mock/SatelliteAdapter.gd").refresh(state)
	var part_names = []
	for key in preload("res://data/mock/SatelliteAdapter.gd").STARTER:
		for option in preload("res://data/mock/SatelliteAdapter.gd").catalog(key):
			if option.id == state[key]: part_names.append(option.name)
	specs.text = "\n".join(part_names) + "\n\n" + result.totals_text.replace("Baseline", "Standby power").replace("Capture", "Image size").replace("Radio", "Downlink")
	readiness_label.text = "LAUNCH READY" if result.can_proceed else "DESIGN BLOCKED"
	readiness_label.add_theme_color_override("font_color", Color("23ed82") if result.can_proceed else Color("ff7777"))
	warning_label.text = "All checks passed. Your spacecraft is ready to launch." if result.blockers.is_empty() else UI.user_message("\n".join(result.blockers.values()))
	next_button.disabled = not result.can_proceed
	if state.get("schema_version", 1) == 2:
		warning_label.text += "\nThis mission can fly. Scoring is not available yet."
	if state.objective == "Survey Target Regions": warning_label.text += "\nSurvey can fly, but its score will be unavailable."
	for connection in next_button.pressed.get_connections():
		next_button.pressed.disconnect(connection.callable)
	next_button.pressed.connect(func():
		var current_review: Dictionary = preload("res://scripts/integration/mission_runtime.gd").review(state)
		if not current_review.ready_to_launch:
			next_button.disabled = true
			warning_label.text = UI.user_message("\n".join(current_review.errors.map(func(issue): return issue.message)))
			return
		if not preload("res://scripts/integration/mission_review.gd").is_confirmed(state):
			navigate.emit(2)
			return
		if state.has("design_lab_route"):
			navigate.emit(4)
			return
		var launched: Dictionary = preload("res://scripts/integration/mission_runtime.gd").launch(state)
		if launched.ok: navigate.emit(4)
		else:
			next_button.disabled = true
			warning_label.text = UI.user_message(launched.error.message))

func build_checklist() -> void:
	for key in validation.checks:
		var item: Dictionary = validation.checks[key]
		var check: Array = [key, {"input_schema": "Mission details", "catalog_references": "Component selections", "profile_mass": "Spacecraft mass", "launcher_capacity": "Launcher capacity", "budget": "Mission budget", "launch_orbit": "Launch compatibility", "target_orbit": "Target access", "essential_power": "Power balance"}.get(key, key.capitalize()), str(item.status).to_upper(), UI.user_message(item.message), UI.user_message(item.message)]

		var card = PanelContainer.new()
		checklist.add_child(card)
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		card.add_child(box)
		var header = row(box)
		header.add_theme_constant_override("separation", 10)
		var status = STATUS.new()
		status.warning = check[2] != "PASS"
		status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(status)
		var text = column(header)
		text.add_theme_constant_override("separation", 3)
		UI.label(text, check[1], 14)
		UI.label(text, check[2].capitalize() + " · " + check[3], 12, "a9c0d1")
		var detail = UI.label(box, check[4] + "\n" + issue_text(check[0]), 12, "b8d2df")
		detail.hide()
		check_details[check[0]] = detail
		var toggle = UI.button(header, "+", func(): toggle_check(check[0]))
		toggle.custom_minimum_size = Vector2(32, 38)
		toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		toggle.tooltip_text = "Expand " + check[1] + " details / " + check[2]
		check_buttons[check[0]] = toggle
	UI.label(checklist, "Eight checks before launch", 16, "b4ccdc")
func toggle_check(key: String) -> void:
	var detail: Label = check_details[key]
	detail.visible = not detail.visible
	check_buttons[key].text = "-" if detail.visible else "+"
	check_buttons[key].tooltip_text = ("Collapse" if detail.visible else "Expand") + " details"
func build_preview(parent: Node) -> void:
	var box = section(parent, "SPACECRAFT & ORBIT PREVIEW")
	summary = UI.label(box.get_child(0), state.name, 12, "80d8e7")
	summary.custom_minimum_size.x = 160
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	preview_frame = PanelContainer.new()
	preview_frame.custom_minimum_size = Vector2.ZERO
	box.add_child(preview_frame)
	var backdrop = TextureRect.new()
	var source = preload("res://assets/ui/backgrounds/home-earth-v1.png")
	var crop = AtlasTexture.new()
	crop.atlas = source
	crop.region = Rect2(0, source.get_height() * 0.35, source.get_width(), source.get_height() * 0.65)
	backdrop.texture = crop
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.65, 0.8, 1, 1)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_frame.add_child(backdrop)
	var composition = BoxContainer.new()
	preview_composition = composition
	composition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	composition.add_theme_constant_override("separation", 10)
	preview_frame.add_child(composition)
	preview = PREVIEW.instantiate()
	preview.custom_minimum_size = Vector2(240, 280)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	composition.add_child(preview)
	preview.configure_satellite(state)
	preview.set_preview_playing(true)
	preview.orbit_selected.connect(func(id):
		for label in preload("res://scripts/integration/mission_runtime.gd").ORBITS:
			if preload("res://scripts/integration/mission_runtime.gd").ORBITS[label] == id: state.orbit = label
		navigate.emit(3))
	var card = PanelContainer.new()
	specs_card = card
	card.custom_minimum_size.x = 250
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	composition.add_child(card)
	var values = VBoxContainer.new()
	values.add_theme_constant_override("separation", 8)
	card.add_child(values)
	UI.label(values, "Spacecraft / Selected", 14)
	UI.label(values, "Selected configuration", 12, "86d5e5")
	values.add_child(HSeparator.new())
	specs = UI.label(values, "", 12)
	var orbit_card = PanelContainer.new()
	box.add_child(orbit_card)
	var orbit_text = VBoxContainer.new()
	orbit_card.add_child(orbit_text)
	orbit_label = UI.label(orbit_text, state.orbit, 13)
	UI.label(orbit_text, "Drag to rotate · scroll to zoom · choose an orbit.", 14, "b4ccdc")
func build_resources(parent: Node) -> void:
	var box = section(parent, "RESOURCE SUMMARY")
	var row_of_gauges = row(box)
	var m: Dictionary = validation.metrics if validation.metrics is Dictionary else {}
	var mass_check: Dictionary = validation.checks.get("profile_mass", {})
	var mass_limit: float = float(mass_check.get("threshold_g", 1330)) if mass_check.get("threshold_g") != null else 1330.0
	for entry in [["mass", "Mass", "%s g" % m.get("total_mass_g", "—"), float(m.get("total_mass_g", 0)) / mass_limit, "%s g profile limit" % mass_limit], ["power", "Baseline / solar", "%s / %s W" % [m.get("baseline_power_w", "—"), m.get("solar_generation_power_w", "—")], float(m.get("baseline_power_w", 0)) / maxf(0.001, float(m.get("solar_generation_power_w", 0))), "Sunlit balance"], ["storage", "Storage", "%s MB" % m.get("storage_capacity_mb", "—"), 0.0, "Empty at launch"]]:
		var gauge = GAUGE.new()
		gauge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gauge.caption = entry[1]
		gauge.value_text = entry[2]
		gauge.fraction = entry[3]
		gauge.limit_text = entry[4]
		row_of_gauges.add_child(gauge)
		gauges[entry[0]] = gauge

func build_coverage(parent: Node) -> void:
	coverage = section(parent, "MISSION COVERAGE")
	UI.label(coverage, "Observation opportunities per target, per orbit", 11, "b5cfdf")
	for target in state.targets:
		var line = row(coverage)
		UI.label(line, target, 12).custom_minimum_size.x = 112
		coverage_value = UI.label(line, "%s windows / orbit" % CATALOG.window_count(target, state.orbit), 12)
		coverage_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		coverage_value.custom_minimum_size.x = 150
	UI.label(coverage, "Static suitability is not a prediction of mission success.", 10, "7199ae")

func build_banners() -> void:
	banners = flexible_row(content)
	var ready_panel = PanelContainer.new()
	ready_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ready_panel.size_flags_stretch_ratio = 1.1
	ready_panel.add_theme_stylebox_override("panel", banner_style("042c24ee", "24a780") if validation.ready_to_launch else banner_style("302414ee", "bd8b43"))
	banners.add_child(ready_panel)
	var ready_box = VBoxContainer.new()
	ready_box.add_theme_constant_override("separation", 4)
	ready_panel.add_child(ready_box)
	UI.label(ready_box, "Readiness Status", 16)
	readiness_label = UI.label(ready_box, "LAUNCH READY", 25, "23ed82")
	UI.label(ready_box, "Launch requires every readiness check to pass.", 12, "c5e1d4")
	var warnings_panel = PanelContainer.new()
	warnings_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warnings_panel.add_theme_stylebox_override("panel", banner_style("072438ee", "347b97"))
	banners.add_child(warnings_panel)
	var warnings = VBoxContainer.new()
	warnings.add_theme_constant_override("separation", 5)
	warnings_panel.add_child(warnings)
	var header = row(warnings)
	var status = STATUS.new()
	status.warning = not validation.ready_to_launch
	header.add_child(status)
	UI.label(header, "Readiness details", 15, "bce9f6").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warning_details_button = UI.button(header, "View Details  >", show_warning_details)
	warning_details_button.add_theme_font_size_override("font_size", 12)
	warning_label = UI.label(warnings, "Review the returned validation messages.", 13)
	if validation.checks.get("profile_mass", {}).get("source_id") != null:
		UI.label(warnings, "Sample mass rule: NASA CubeSat 101. See readiness details.", 11, "b5cfdf")
	UI.label(warnings, "Passing readiness does not guarantee mission success.", 11, "d5cfa9")
func banner_style(background: String, border: String) -> StyleBoxFlat:
	var box = preload("res://ui/theme/WorkbenchTheme.gd").box(Color(background), Color(border), 14)
	box.set_border_width_all(1)
	box.shadow_size = 7
	box.shadow_color = Color(Color(border), 0.18)
	return box
func show_warning_details() -> void:
	if not is_instance_valid(warning_dialog):
		var layer = CanvasLayer.new()
		layer.layer = 100
		add_child(layer)
		warning_dialog = preload("res://ui/components/ReadinessDetails.gd").new()
		layer.add_child(warning_dialog)
	var result: Dictionary = preload("res://data/mock/SatelliteAdapter.gd").refresh(state)
	warning_dialog.show_review(validation, UI.user_message("\n".join(result.blockers.values())))

func flexible_row(parent: Node) -> BoxContainer:
	var box = BoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	return box

func responsive() -> void:
	if not is_instance_valid(preview_frame): return
	fit_navigation()
	main_columns.vertical = size.x < 1100
	banners.vertical = size.x < 900
	lower_panels.vertical = right_column.size.x < 940
	preview_composition.vertical = preview_frame.size.x < 650
	specs_card.custom_minimum_size.x = 0 if preview_composition.vertical else 250
	preview.custom_minimum_size.y = clampf(size.y * 0.35, 250, 340)
	preview.custom_minimum_size.x = 240

func issue_text(_check: String) -> String:
	var messages: Array = []
	for issue in validation.errors:
		messages.append(issue.message + " " + issue.suggested_fix)
	return UI.user_message("\n".join(messages))
