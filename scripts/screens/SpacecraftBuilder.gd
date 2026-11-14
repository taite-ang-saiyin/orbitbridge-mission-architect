extends "res://scripts/screens/Workbench.gd"
const Workflow = preload("res://scripts/integration/mission_workflow.gd")
const Loader = preload("res://scripts/core/catalog_loader.gd")
const PREVIEW = preload("res://scenes/ui/components/CraftPreview.tscn")
const SLOT_NAMES = {"bus": "Bus", "instrument": "Instrument", "solar": "Solar panels", "battery": "Battery", "radio": "Radio", "storage": "Storage"}
var preview: SubViewportContainer
var option_buttons: Dictionary = {}
var group_messages: Dictionary = {}
var total_values: Label
var compatibility: Label
var catalog_data: Dictionary = {}
var selectors: Dictionary = {}

func _ready() -> void:
	screen_id = "SpacecraftBuilder"
	setup("03", "Satellite Builder", "Choose your parts and check the weight, cost and power before launch.", 1, 3, "Continue to Readiness")
	workspace = row(content)
	form_columns = row(workspace)
	form_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var choices = column(form_columns, 1.5)
	var loaded: Dictionary = Loader.load_catalogs()
	if loaded.ok: catalog_data = loaded.catalogs
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	choices.add_child(grid)
	for category in SLOT_NAMES:
		var box = section(grid, SLOT_NAMES[category])
		for part in catalog_data.get("components", []):
			if part.category != category: continue
			var button = UI.button(box, part.display_name, select_component.bind(category, part.id))
			button.toggle_mode = true
			button.custom_minimum_size.y = 38
			button.tooltip_text = "%d g / %d credits. Illustrative training part." % [part.mass_g, part.cost_credits]
			option_buttons[part.id] = button
		group_messages[category] = UI.label(box, "", 11, "8dd9e2")
	var launch_box = section(choices, "Launch and orbit")
	for entry in [["Orbit", CATALOG.ORBITS, "orbit"], ["Launch profile", _ids("launch_profiles"), "launch_profile"], ["Launcher", _ids("launchers"), "launcher"], ["Operating policy", ["Observe First", "Downlink First"], "policy"]]:
		var line = row(launch_box)
		UI.label(line, entry[0], 12).custom_minimum_size.x = 110
		var field: String = entry[2]
		var select = OptionButton.new()
		var ids: Array = entry[1]
		for id in ids: select.add_item(_choice_label(field, id))
		select.selected = ids.find(state[field])
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select.item_selected.connect(func(index): state[field] = ids[index]; refresh())
		line.add_child(select)
		selectors[field] = select
	summary_column = column(form_columns, 1.0)
	var art = section(summary_column, "Spacecraft preview")
	preview = PREVIEW.instantiate()
	preview.custom_minimum_size = Vector2(270, 280)
	art.add_child(preview)
	var tools = row(art)
	UI.button(tools, "Rotate", func(): preview.auto_rotate = not preview.auto_rotate)
	UI.button(tools, "Reset parts", reset_design)
	UI.label(art, "Illustrative appearance. The selected parts determine the numbers below.", 11, "8baabd")
	var result_box = section(summary_column, "Mission and design check")
	summary = UI.label(result_box, "", 13)
	total_values = UI.label(result_box, "", 13, "7fe5ee")
	compatibility = UI.label(result_box, "", 12, "f6cb8f")
	resized.connect(responsive)
	call_deferred("responsive")
	refresh()

func _ids(collection: String) -> Array:
	var ids: Array = []
	for entry in catalog_data.get(collection, []): ids.append(entry.id)
	return ids

func _choice_label(field: String, id: String) -> String:
	if field == "orbit":
		for orbit in catalog_data.get("orbit_catalog", {}).get("orbits", []):
			if orbit.id == id: return orbit.get("label", id)
	var collection: String = "launch_profiles" if field == "launch_profile" else "launchers"
	for entry in catalog_data.get(collection, []):
		if entry.id == id: return entry.display_name
	return id

func select_component(category: String, id: String) -> void:
	state.components["payload" if category == "instrument" else category] = id
	refresh()

func reset_design() -> void:
	state.components = CATALOG.DEFAULTS.components.duplicate(true)
	refresh()

func refresh() -> void:
	var result: Dictionary = Workflow.review(state)
	summary.text = "%s\n%s · %s orbits · Budget: %s credits" % [state.name, CATALOG.orbit_label(state.orbit), state.duration, state.budget]
	total_values.text = Workflow.totals_text(result)
	compatibility.text = Workflow.issue_text(result)
	for category in SLOT_NAMES:
		var selected: Variant = state.components.get("payload" if category == "instrument" else category)
		group_messages[category].text = "Choose a valid part."
		for part in catalog_data.get("components", []):
			if part.category != category: continue
			option_buttons[part.id].set_pressed_no_signal(selected == part.id)
			if selected == part.id:
				group_messages[category].text = "%d g · %d credits" % [part.mass_g, part.cost_credits]
	next_button.disabled = not result.ready_to_launch
	state.body_id = "dev_body_2" if state.components.bus == "bus_light" else "dev_body_1"
	state.wings_id = "dev_wings_2" if state.components.solar == "solar_large" else "dev_wings_1"
	state.radio_id = "dev_radio_2" if state.components.radio == "radio_fast" else "dev_radio_1"
	preview.configure_satellite(state)

func responsive() -> void:
	if not is_instance_valid(preview): return
	fit_navigation()
	preview.custom_minimum_size.y = clampf(size.y * 0.33, 220, 340)
