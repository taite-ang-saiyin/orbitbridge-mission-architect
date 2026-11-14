extends "res://scripts/screens/Workbench.gd"
const REPORT = preload("res://data/mock/ReadinessFixture.gd")
const STATUS = preload("res://ui/components/ReadinessStatus.gd")
const GAUGE = preload("res://ui/components/ResourceGauge.gd")
const STRIP = preload("res://ui/components/CoverageStrip.gd")
const PREVIEW = preload("res://scenes/ui/components/CraftPreview.tscn")
var check_buttons: Dictionary = {}
var check_details: Dictionary = {}
var preview: SubViewportContainer
var preview_frame: Control
var specs: Label
var orbit_label: Label
var warning_label: Label
var warning_details_button: Button
var warning_dialog: AcceptDialog
var readiness_label: Label
var gauges: Dictionary = {}
var main_columns: HBoxContainer
var banners: HBoxContainer
var checklist: VBoxContainer
var coverage: VBoxContainer
func _ready() -> void:
	screen_id = "FlightReadiness"
	setup("04 / PREFLIGHT REVIEW", "Flight Readiness", "Review system checks, resolve warnings, and prepare your mission for launch.", 2, 4, "Launch Mission")
	main_columns = row(content)
	workspace = main_columns
	checklist = section(main_columns, "READINESS CHECKLIST")
	checklist.get_parent().size_flags_stretch_ratio = 1.0
	checklist.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	build_checklist()
	var right = column(main_columns, 2.2)
	build_preview(right)
	var lower = row(right)
	build_resources(lower)
	build_coverage(lower)
	build_banners()
	resized.connect(responsive)
	call_deferred("responsive")
	var result = preload("res://data/mock/SatelliteAdapter.gd").refresh(state)
	var part_names = []
	for key in preload("res://data/mock/SatelliteAdapter.gd").STARTER:
		for option in preload("res://data/mock/SatelliteAdapter.gd").catalog(key):
			if option.id == state[key]: part_names.append(option.name)
	specs.text = "\n".join(part_names) + "\n\n" + result.totals_text
	readiness_label.text = "DEVELOPMENT PREVIEW" if result.can_proceed else "DESIGN BLOCKED"
	warning_label.text = "\n".join(result.warnings) + "\n" + "\n".join(result.blockers.values())
	next_button.disabled = not result.can_proceed
	for connection in next_button.pressed.get_connections():
		next_button.pressed.disconnect(connection.callable)
	next_button.pressed.connect(func():
		var validated = preload("res://data/mock/SatelliteAdapter.gd").refresh(state)
		if validated.can_proceed:
			state.run_design = validated.duplicate(true)
			navigate.emit(4))
func context_for(key: String) -> String:
	match key:
		"mission":
			return "%s\n%s\nTargets: %s\n%s observations / %s orbits / %s credits" % [state.name, state.objective, ", ".join(state.targets), state.observations, state.duration, state.budget]
		"payload": return "Selected instrument: " + state.components.payload
		"resources": return "Selected bus: %s\nBattery: %s\nStorage: %s" % [state.components.bus, state.components.battery, state.components.storage]
		"coverage": return "Orbit: %s\nTargets: %s\nDuration: %s orbits" % [state.orbit, ", ".join(state.targets), state.duration]
		"launcher": return "%s / %s" % [state.launcher, state.orbit]
		"policy": return "Selected policy: " + state.policy
	return ""
func short_description(key: String, fallback: String) -> String:
	match key:
		"payload": return state.components.payload + " configured."
		"launcher": return state.launcher + " / " + state.orbit
		"policy": return state.policy + " policy configured."
	return fallback
func build_checklist() -> void:
	for check in REPORT.CHECKS:
		var card = PanelContainer.new()
		checklist.add_child(card)
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		card.add_child(box)
		var header = row(box)
		header.add_theme_constant_override("separation", 10)
		var status = STATUS.new()
		status.warning = check[2] == "WARNING"
		status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(status)
		var text = column(header)
		text.add_theme_constant_override("separation", 3)
		UI.label(text, check[1], 15)
		UI.label(text, short_description(check[0], check[3]), 12, "a9c0d1")
		var detail = UI.label(box, context_for(check[0]) + "\n\n" + check[4], 12, "b8d2df")
		detail.hide()
		check_details[check[0]] = detail
		var toggle = UI.button(header, "+", func(): toggle_check(check[0]))
		toggle.custom_minimum_size = Vector2(32, 38)
		toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		toggle.tooltip_text = "Expand " + check[1] + " details / fixed " + check[2]
		check_buttons[check[0]] = toggle
	UI.label(checklist, "FIXED MOCK REPORT / 5 PASS · 1 WARNING", 10, "77a8c0")
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
	preview_frame = Control.new()
	preview_frame.custom_minimum_size = Vector2(260, 270)
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
	var composition = HBoxContainer.new()
	composition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	composition.add_theme_constant_override("separation", 10)
	preview_frame.add_child(composition)
	preview = PREVIEW.instantiate()
	preview.custom_minimum_size = Vector2.ZERO
	composition.add_child(preview)
	preview.configure_satellite(state)
	var card = PanelContainer.new()
	card.custom_minimum_size.x = 185
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	composition.add_child(card)
	var values = VBoxContainer.new()
	values.add_theme_constant_override("separation", 8)
	card.add_child(values)
	UI.label(values, "Spacecraft / Selected", 14)
	UI.label(values, state.components.bus, 12, "86d5e5")
	values.add_child(HSeparator.new())
	var profile = CATALOG.BUS_PROFILES[state.components.bus]
	specs = UI.label(values, "Mass             %s\n\nPower (Peak)   %s\n\nBattery          %s\n\nStorage          %s" % [profile[0], profile[1], battery_value(), storage_value()], 12)
	var orbit_card = PanelContainer.new()
	orbit_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	orbit_card.offset_left = 10
	orbit_card.offset_top = -88
	orbit_card.offset_right = 190
	orbit_card.offset_bottom = -8
	preview_frame.add_child(orbit_card)
	var orbit_text = VBoxContainer.new()
	orbit_card.add_child(orbit_text)
	orbit_label = UI.label(orbit_text, state.orbit, 13)
	UI.label(orbit_text, REPORT.ORBIT_NOTES[state.orbit], 11, "b4ccdc")
func battery_value() -> String:
	return "90 Wh" if "90" in state.components.battery else "60 Wh"
func storage_value() -> String:
	return "64 GB" if "64" in state.components.storage else "32 GB"
func build_resources(parent: Node) -> void:
	var box = section(parent, "RESOURCE SUMMARY")
	var row_of_gauges = row(box)
	var profile = CATALOG.BUS_PROFILES[state.components.bus]
	for entry in [["mass", "Mass", profile[0]], ["power", "Power (Peak)", profile[1]], ["storage", "Storage", storage_value()]]:
		var gauge = GAUGE.new()
		gauge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gauge.caption = entry[1]
		gauge.value_text = entry[2]
		gauge.fraction = REPORT.STORAGE_GAUGES[state.components.storage] if entry[0] == "storage" else REPORT.BUS_GAUGES[state.components.bus][entry[0]]
		gauge.limit_text = REPORT.GAUGES[entry[0]][1]
		row_of_gauges.add_child(gauge)
		gauges[entry[0]] = gauge
	UI.label(box, "Illustrative limits and fixed gauge positions", 10, "7199ae")
func build_coverage(parent: Node) -> void:
	coverage = section(parent, "MISSION COVERAGE")
	var headings = row(coverage)
	UI.label(headings, "Target", 11, "b5cfdf").custom_minimum_size.x = 112
	UI.label(headings, "Observation windows / 6 orbits", 11, "b5cfdf").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for index in state.targets.size():
		var target = state.targets[index]
		var line = row(coverage)
		line.add_theme_constant_override("separation", 8)
		UI.label(line, target, 12).custom_minimum_size.x = 112
		var strip = STRIP.new()
		strip.slots = REPORT.SLOT_SAMPLES[index % REPORT.SLOT_SAMPLES.size()]
		line.add_child(strip)
		var status = STATUS.new()
		status.warning = index == state.targets.size() - 1
		line.add_child(status)
	UI.label(coverage, "Fixed six-orbit sample / not recalculated", 10, "7199ae")
func build_banners() -> void:
	banners = row(content)
	var ready_panel = PanelContainer.new()
	ready_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ready_panel.size_flags_stretch_ratio = 1.1
	ready_panel.add_theme_stylebox_override("panel", banner_style("042c24ee", "24ee81"))
	banners.add_child(ready_panel)
	var ready_box = VBoxContainer.new()
	ready_box.add_theme_constant_override("separation", 4)
	ready_panel.add_child(ready_box)
	UI.label(ready_box, "Readiness Status", 16)
	readiness_label = UI.label(ready_box, "LAUNCH READY", 28, "23ed82")
	UI.label(ready_box, "Mock report: 5 checks passed. 1 optional warning to review.", 12, "c5e1d4")
	var warnings_panel = PanelContainer.new()
	warnings_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warnings_panel.add_theme_stylebox_override("panel", banner_style("292407ee", "ebc52a"))
	banners.add_child(warnings_panel)
	var warnings = VBoxContainer.new()
	warnings.add_theme_constant_override("separation", 5)
	warnings_panel.add_child(warnings)
	var header = row(warnings)
	var status = STATUS.new()
	status.warning = true
	header.add_child(status)
	UI.label(header, "Warnings (1)", 17, "ffdf55").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warning_details_button = UI.button(header, "View Details  >", show_warning_details)
	warning_details_button.add_theme_font_size_override("font_size", 12)
	warning_label = UI.label(warnings, "Limited coverage for %s." % state.targets[-1], 13)
	UI.label(warnings, "Consider a different orbit duration or target. Example warning only.", 11, "d5cfa9")
func banner_style(background: String, border: String) -> StyleBoxFlat:
	var box = preload("res://ui/theme/WorkbenchTheme.gd").box(Color(background), Color(border), 14)
	box.set_border_width_all(1)
	box.shadow_size = 7
	box.shadow_color = Color(Color(border), 0.18)
	return box
func show_warning_details() -> void:
	if not is_instance_valid(warning_dialog):
		warning_dialog = AcceptDialog.new()
		warning_dialog.title = "Orbit & Coverage / Mock Warning"
		warning_dialog.get_ok_button().text = "Close"
		add_child(warning_dialog)
	warning_dialog.dialog_text = "Mission: %s\nOrbit: %s\nTargets: %s\n\nThis is a fixed example warning, not a validation result.\nThe preview shows authored windows for six reference orbits.\nChanging the design does not calculate a new readiness report.\n\nUse Back to modify your design, or Launch Mission to explore the mock flight." % [state.name, state.orbit, ", ".join(state.targets)]
	warning_dialog.popup_centered(Vector2i(550, 300))
func responsive() -> void:
	if not is_instance_valid(preview_frame):
		return
	fit_navigation()
	preview_frame.custom_minimum_size.y = clampf(size.y * 0.33, 210, 280)
