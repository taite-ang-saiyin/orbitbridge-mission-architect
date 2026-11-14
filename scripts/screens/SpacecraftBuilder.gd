extends "res://scripts/screens/Workbench.gd"
const ADAPTER = preload("res://data/mock/SatelliteAdapter.gd")
const PREVIEW = preload("res://scenes/ui/components/CraftPreview.tscn")
var preview: SubViewportContainer
var option_buttons: Dictionary = {}
var group_messages: Dictionary = {}
var total_values: Label
var selected_label: Label
var compatibility: Label
var auto_button: Button
var visual: VBoxContainer
var kit_options: VBoxContainer
var model_caption: Label
func _ready() -> void:
	screen_id = "SpacecraftBuilder"
	setup("03", "Satellite Builder", "Build your spacecraft: choose a body, solar wings and radio.", 1, 3, "Continue to Readiness")
	ADAPTER.ensure(state)
	state.satellite_id = "kit"
	workspace = row(content)
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_columns = row(workspace)
	form_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var selections = column(form_columns, 1.0)
	kit_options = column(selections)
	for key in ADAPTER.GROUPS:
		var group = ADAPTER.GROUPS[key]
		var box = section(kit_options, group[0])
		UI.label(box, group[1], 11, "8ca8bc")
		var choices = row(box)
		choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for option in ADAPTER.catalog(key):
			var button = UI.button(choices, "", select_component.bind(key, option.id))
			button.toggle_mode = true
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size = Vector2(0, 78)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 12)
			option_buttons[option.id] = button
		group_messages[key] = UI.label(box, "", 12, "ffbe79")
	visual = column(form_columns, 1.35)
	form_columns.move_child(visual, 0)
	var box = section(visual, "DESIGN STUDIO  /  GAMEPLAY PRESETS")
	model_caption = UI.label(box, "", 11, "6adacb")
	preview = PREVIEW.instantiate()
	preview.custom_minimum_size = Vector2(280, 360)
	box.add_child(preview)
	var controls = row(box)
	auto_button = UI.button(controls, "Rotate Preview", func(): preview.auto_rotate = not preview.auto_rotate)
	auto_button.toggle_mode = true
	preview.auto_rotation_changed.connect(func(enabled): auto_button.set_pressed_no_signal(enabled))
	UI.button(controls, "Reset to Starter Design", reset_design)
	var mission_controls = section(visual, "ORBIT & OPERATING POLICY")
	var selectors = row(mission_controls)
	var orbit_controls = column(selectors)
	UI.label(orbit_controls, "Orbit", 11, "8ca8bc")
	dropdown(orbit_controls, CATALOG.ORBITS, state.orbit, func(value): state.orbit = value; refresh())
	var policy_controls = column(selectors)
	UI.label(policy_controls, "Policy", 11, "8ca8bc")
	dropdown(policy_controls, ["Observe First", "Downlink First"], state.policy, func(value): state.policy = value; refresh())
	var launch_options = row(mission_controls)
	dropdown(launch_options, ["Sample 1U (<1330 g)", "Alternative (≤5000 g)"], "Alternative (≤5000 g)" if state.get("launch_profile_id") == "illustrative_alternative" else "Sample 1U (<1330 g)", func(value):
		state.launch_profile_id = "illustrative_alternative" if value.begins_with("Alternative") else "cubesat_1u_sample"
		refresh())
	dropdown(launch_options, ["Small launcher", "Medium launcher"], "Medium launcher" if state.get("launcher_id") == "medium" else "Small launcher", func(value):
		state.launcher_id = "medium" if value == "Medium launcher" else "small"
		refresh())
	UI.label(box, "Appearance shows your selected parts. Specifications describe their mission capabilities.", 12, "a9cbdc")
	
	
	summary_column = column(visual)
	box = section(summary_column, "MISSION & DESIGN CHECK")
	summary = UI.label(box, "", 13)
	selected_label = UI.label(box, "", 13, "61deef")
	total_values = UI.label(box, "", 13)
	compatibility = UI.label(box, "", 12, "efc371")
	UI.label(box, "Check the warnings and resolve all blockers before continuing.", 12)
	resized.connect(responsive)
	call_deferred("responsive")
	refresh()
func select_component(key: String, id: String) -> void:
	state.satellite_id = "kit"
	state[key] = id
	state.erase("run_design")
	refresh()
func reset_design() -> void:
	state.satellite_id = "kit"
	for key in ADAPTER.STARTER: state[key] = ADAPTER.STARTER[key]
	state.launch_profile_id = "cubesat_1u_sample"
	state.launcher_id = "small"
	state.erase("run_design")
	refresh()
func refresh() -> void:
	var result = ADAPTER.refresh(state)
	kit_options.visible = true
	
	model_caption.text = "CUSTOM SATELLITE / BODY · WINGS · RADIO"
	summary.text = "%s  ·  %s\n%s orbits  /  %s credits" % [state.name, state.objective, state.duration, state.budget]
	var names = []
	for key in ADAPTER.GROUPS:
		for option in ADAPTER.catalog(key):
			var selected = state[key] == option.id
			option_buttons[option.id].text = ("●  " if selected else "○  ") + option.name + "\n" + ("SELECTED" if selected else "Select variant")
			option_buttons[option.id].set_pressed_no_signal(selected)
			option_buttons[option.id].tooltip_text = option.description + "\n" + option.specifications
			if selected:
				names.append(option.name)
				group_messages[key].text = option.specifications
		if result.blockers.has(key): group_messages[key].text = result.blockers[key]
	selected_label.text = " / ".join(names)
	total_values.text = result.totals_text
	compatibility.text = "\n".join(result.warnings) + "\n" + "\n".join(result.blockers.values())
	next_button.disabled = result.validation.metrics == null
	preview.configure_satellite(state)
func responsive() -> void:
	fit_navigation()
	preview.custom_minimum_size.y = clampf(size.y * 0.43, 260, 420)
