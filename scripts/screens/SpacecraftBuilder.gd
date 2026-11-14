extends "res://scripts/screens/Workbench.gd"
const ADAPTER = preload("res://data/mock/SatelliteAdapter.gd")
const PREVIEW = preload("res://scenes/ui/components/CraftPreview.tscn")
var preview: SubViewportContainer
var option_buttons: Dictionary = {}
var group_messages: Dictionary = {}
var total_values: Label
var selected_label: Label
var compatibility: Label
var mission_context: Label
var review_columns: BoxContainer
var review_status: PanelContainer
var auto_button: Button
var visual: VBoxContainer
var kit_options: VBoxContainer
var model_caption: Label
var expand_button: Button
var model_dialog: Control
var expanded_preview: SubViewportContainer
var engineering_selectors: Dictionary = {}
var engineering_catalog: Dictionary = {}
const SLOT_NAMES = {"bus": "Bus", "instrument": "Instrument", "solar": "Solar panels", "battery": "Battery", "radio": "Radio", "storage": "Storage"}
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
			button.custom_minimum_size = Vector2(0, 68)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 12)
			option_buttons[option.id] = button
		group_messages[key] = UI.label(box, "", 12, "ffbe79")
	build_engineering_choices(selections)
	visual = column(form_columns, 1.35)
	form_columns.move_child(visual, 0)
	var box = section(visual, "DESIGN STUDIO")
	model_caption = UI.label(box, "", 11, "6adacb")
	preview = add_studio_preview(box, Vector2(280, 360))
	var controls = row(box)
	auto_button = UI.button(controls, "Rotate Preview", func(): preview.auto_rotate = not preview.auto_rotate)
	auto_button.toggle_mode = true
	preview.auto_rotation_changed.connect(func(enabled): auto_button.set_pressed_no_signal(enabled))
	UI.button(controls, "Reset to Starter Design", reset_design)
	expand_button = UI.button(controls, "Expand Model", expand_model)
	var mission_controls = section(visual, "ORBIT & OPERATING POLICY")
	var selectors = row(mission_controls)
	var orbit_controls = column(selectors)
	UI.label(orbit_controls, "Orbit", 11, "8ca8bc")
	dropdown(orbit_controls, CATALOG.ORBITS, state.orbit, func(value): state.orbit = value; refresh())
	var policy_controls = column(selectors)
	UI.label(policy_controls, "Policy", 11, "8ca8bc")
	dropdown(policy_controls, ["Observe First", "Downlink First"], state.policy, func(value): state.policy = value; refresh())
	var launch_options = row(mission_controls)
	var profile_controls = column(launch_options)
	UI.label(profile_controls, "Launch profile / mass limit", 11, "8ca8bc")
	dropdown(profile_controls, ["Sample 1U (<1330 g)", "Alternative (≤5000 g)"], "Alternative (≤5000 g)" if state.get("launch_profile_id") == "illustrative_alternative" else "Sample 1U (<1330 g)", func(value):
		state.launch_profile_id = "illustrative_alternative" if value.begins_with("Alternative") else "cubesat_1u_sample"
		refresh())
	var launcher_controls = column(launch_options)
	UI.label(launcher_controls, "Launch vehicle", 11, "8ca8bc")
	dropdown(launcher_controls, ["Small launcher", "Medium launcher"], "Medium launcher" if state.get("launcher_id") == "medium" else "Small launcher", func(value):
		state.launcher_id = "medium" if value == "Medium launcher" else "small"
		refresh())
	UI.label(box, "Drag to rotate · scroll to zoom. Expand for a closer look.", 12, "a9cbdc")
	
	
	summary_column = column(visual)
	box = section(summary_column, "MISSION & DESIGN CHECK")
	summary = UI.label(box, "", 18, "e5f5ff")
	mission_context = UI.label(box, "", 12, "98bacd")
	review_columns = BoxContainer.new()
	review_columns.add_theme_constant_override("separation", 10)
	box.add_child(review_columns)
	for title in ["Selected spacecraft", "Resource totals"]:
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", preload("res://ui/theme/WorkbenchTheme.gd").box(Color("0a2639"), Color("28566c"), 10))
		review_columns.add_child(card)
		var values = VBoxContainer.new()
		values.add_theme_constant_override("separation", 8)
		card.add_child(values)
		UI.label(values, title, 12, "75c9dc")
		if title == "Selected spacecraft": selected_label = UI.label(values, "", 13)
		else: total_values = UI.label(values, "", 13)
	review_status = PanelContainer.new()
	box.add_child(review_status)
	compatibility = UI.label(review_status, "", 12)
	box.resized.connect(func(): review_columns.vertical = box.size.x < 580)

	resized.connect(responsive)
	call_deferred("responsive")
	refresh()
func select_component(key: String, id: String) -> void:
	state.satellite_id = "kit"
	state[key] = id
	if state.has("engineering_parts"):
		var runtime = preload("res://scripts/integration/mission_runtime.gd")
		if key == "body_id" and runtime.BODIES.has(id):
			for i in 4: state.engineering_parts[["bus", "instrument", "battery", "storage"][i]] = runtime.BODIES[id][i]
		elif key == "wings_id": state.engineering_parts.solar = runtime.SOLAR.get(id, "")
		elif key == "radio_id": state.engineering_parts.radio = runtime.RADIOS.get(id, "")
	state.erase("run_design")
	refresh()
func reset_design() -> void:
	state.satellite_id = "kit"
	for key in ADAPTER.STARTER: state[key] = ADAPTER.STARTER[key]
	state.erase("engineering_parts")
	state.launch_profile_id = "cubesat_1u_sample"
	state.launcher_id = "small"
	state.erase("run_design")
	refresh()
func refresh() -> void:
	var result = ADAPTER.refresh(state)
	kit_options.visible = true
	for category in engineering_selectors:
		var select: OptionButton = engineering_selectors[category]
		var id: String = result.validation.config.design[category + "_id"]
		select.select(-1)
		for i in select.item_count:
			if select.get_item_metadata(i) == id:
				select.select(i)
				select.tooltip_text = select.get_popup().get_item_tooltip(i)

	
	model_caption.text = "Spacecraft preview"
	summary.text = state.name
	mission_context.text = "%s · %s orbits · %s credits budget" % [state.objective, state.duration, state.budget]
	var names = []
	for key in ADAPTER.GROUPS:
		for option in ADAPTER.catalog(key):
			var selected = state[key] == option.id
			option_buttons[option.id].text = ("●  " if selected else "○  ") + option.name + "\n" + ("Selected" if selected else "Select")
			option_buttons[option.id].set_pressed_no_signal(selected)
			option_buttons[option.id].tooltip_text = "Visual style: " + option.name
			if selected:
				names.append("%s: %s" % [ADAPTER.GROUPS[key][0], option.name])
				group_messages[key].text = selected_specifications(key, result.validation.config.design)
		if result.blockers.has(key): group_messages[key].text = UI.user_message(result.blockers[key])
	selected_label.text = "\n".join(names)
	total_values.text = result.totals_text.replace("Baseline", "Standby power").replace("Capture", "Image size").replace("Radio", "Downlink")
	compatibility.text = "Ready for flight checks." if result.blockers.is_empty() else UI.user_message("\n".join(result.blockers.values()))
	var ready: bool = result.can_proceed
	review_status.add_theme_stylebox_override("panel", preload("res://ui/theme/WorkbenchTheme.gd").box(Color("07372e") if ready else Color("352914"), Color("218b70") if ready else Color("96713d"), 10))
	compatibility.add_theme_color_override("font_color", Color("8ee8ca") if ready else Color("ffd395"))
	next_button.disabled = not result.can_proceed
	preview.configure_satellite(state)
func responsive() -> void:
	fit_navigation()
	preview.custom_minimum_size.y = clampf(size.y * 0.43, 260, 420)

func expand_model() -> void:
	if not is_instance_valid(model_dialog):
		var layer = CanvasLayer.new()
		layer.layer = 100
		add_child(layer)
		model_dialog = Control.new()
		layer.add_child(model_dialog)
		model_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		model_dialog.focus_mode = Control.FOCUS_ALL
		var shade = ColorRect.new()
		shade.color = Color(0.0, 0.01, 0.025, 0.92)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		model_dialog.add_child(shade)
		var margins = MarginContainer.new()
		margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left", "right", "top", "bottom"]: margins.add_theme_constant_override("margin_" + side, 24)
		model_dialog.add_child(margins)
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", preload("res://ui/theme/WorkbenchTheme.gd").box(Color("071a29"), Color("347a91"), 12))
		margins.add_child(card)
		var body = VBoxContainer.new()
		body.add_theme_constant_override("separation", 10)
		card.add_child(body)
		var header = row(body)
		UI.label(header, "Satellite Model / Expanded View", 18).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UI.button(header, "Close  ×", func(): model_dialog.hide())
		expanded_preview = add_studio_preview(body, Vector2(240, 200), true)
		expanded_preview.get_node("SubViewport").render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
		var tools = row(body)
		var rotate = UI.button(tools, "Auto Rotate", func(): expanded_preview.auto_rotate = not expanded_preview.auto_rotate)
		rotate.toggle_mode = true
		expanded_preview.auto_rotation_changed.connect(func(enabled): rotate.set_pressed_no_signal(enabled))
		UI.button(tools, "Reset View", func(): expanded_preview.reset_view())
		UI.label(body, "Drag to rotate · scroll to zoom. Viewing controls do not change your spacecraft design.", 12, "a9cbdc")
		model_dialog.visibility_changed.connect(func(): expanded_preview.set_process(model_dialog.visible))
		model_dialog.gui_input.connect(func(event):
			if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
				model_dialog.hide()
				model_dialog.accept_event())
	expanded_preview.configure_satellite(state.duplicate(true))
	expanded_preview.yaw = preview.yaw
	expanded_preview.pitch = preview.pitch
	expanded_preview.zoom = preview.zoom
	expanded_preview.auto_rotate = preview.auto_rotate
	expanded_preview.zoom = 1.05
	model_dialog.show()
	model_dialog.grab_focus()
	expanded_preview.update_camera.call_deferred()

func build_engineering_choices(parent: Node) -> void:
	var box = section(parent, "ENGINEERING COMPONENTS")
	UI.label(box, "Fine-tune each component. Mass, cost and capabilities update below.", 11, "8ca8bc")
	var loaded: Dictionary = preload("res://scripts/integration/mission_runtime.gd").load_game_catalogs()
	if not loaded.ok:
		UI.label(box, "Catalog unavailable. Launch remains blocked.", 12, "ffbe79")
		return
	engineering_catalog = loaded.catalogs
	for category in SLOT_NAMES:
		var line = row(box)
		UI.label(line, SLOT_NAMES[category], 12).custom_minimum_size.x = 85
		var select = OptionButton.new()
		select.fit_to_longest_item = false
		select.clip_text = true
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select.custom_minimum_size.y = 36
		for part in engineering_catalog.components:
			if part.category != category: continue
			select.add_item("%s · %s g · %s cr" % [part.display_name, part.mass_g, part.cost_credits])
			select.set_item_metadata(select.item_count - 1, part.id)
			var details: String = ""
			match category:
				"bus": details = "%s W baseline" % part.baseline_power_w
				"instrument": details = "%s MB/capture · %s W active" % [part.data_per_observation_mb, part.observe_power_w]
				"solar": details = "%s W generation" % part.generation_power_w
				"battery": details = "%s Wh capacity" % part.capacity_wh
				"radio": details = "%s MB/hour · %s W active" % [part.downlink_mb_per_hour, part.transmit_power_w]
				"storage": details = "%s MB capacity" % part.capacity_mb
			select.get_popup().set_item_tooltip(select.item_count - 1, select.get_item_text(select.item_count - 1) + "\n" + details)
		select.item_selected.connect(func(index): select_engineering_component(category, select.get_item_metadata(index)))
		line.add_child(select)
		engineering_selectors[category] = select

func select_engineering_component(category: String, id: String) -> void:
	if not SLOT_NAMES.has(category): return
	if not state.has("engineering_parts"):
		state.engineering_parts = {}
		var config: Dictionary = preload("res://scripts/integration/mission_runtime.gd").config_for(state)
		for slot in SLOT_NAMES: state.engineering_parts[slot] = config.design[slot + "_id"]
	state.engineering_parts[category] = id
	if category == "bus": state.body_id = "dev_body_2" if id == "bus_light" else "dev_body_1"
	elif category == "solar": state.wings_id = "dev_wings_2" if id == "solar_large" else "dev_wings_1"
	elif category == "radio": state.radio_id = "dev_radio_2" if id == "radio_fast" else "dev_radio_1"
	state.erase("run_design")
	refresh()

func selected_specifications(key: String, design: Dictionary) -> String:
	var slots: Array = {"body_id": ["bus", "instrument", "battery", "storage"], "wings_id": ["solar"], "radio_id": ["radio"]}[key]
	var lines: Array[String] = []
	for slot in slots:
		for part in engineering_catalog.get("components", []):
			if part.id != design[slot + "_id"]: continue
			var value: String = ""
			match slot:
				"bus": value = "%s W standby" % part.baseline_power_w
				"instrument": value = "%s MB/image" % part.data_per_observation_mb
				"battery": value = "%s Wh" % part.capacity_wh
				"storage": value = "%s MB" % part.capacity_mb
				"solar": value = "%s W generation" % part.generation_power_w
				"radio": value = "%s MB/hour · %s W transmitting" % [part.downlink_mb_per_hour, part.transmit_power_w]
			lines.append("%s · %s" % [part.display_name, value])
	return "\n".join(lines)

func add_studio_preview(parent: Node, minimum: Vector2, expand: bool = false) -> SubViewportContainer:
	var frame = PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if expand: frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", preload("res://ui/theme/WorkbenchTheme.gd").box(Color("081d2c"), Color("285a71"), 3))
	parent.add_child(frame)
	var background = TextureRect.new()
	background.texture = preload("res://assets/ui/backgrounds/studio-space-v1.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(background)
	var view = PREVIEW.instantiate()
	view.custom_minimum_size = minimum
	frame.add_child(view)
	view.get_node("SubViewport/Stage/PreviewEarth").hide()
	view.get_node("SubViewport").transparent_bg = true
	var world_environment: WorldEnvironment = view.get_node("SubViewport/Stage/Environment")
	world_environment.environment = world_environment.environment.duplicate()
	world_environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	return view
