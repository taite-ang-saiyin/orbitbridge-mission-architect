extends Control
## Synthetic editable view only. Its receiver owns this preview's draft.

signal component_changed(field: String, value: String)
signal route_requested
signal start_requested
signal cancel_requested

var _requirements: Label
var _experiment: Label
var _design: Label
var _reason: Label
var component_selector: OptionButton
var value_selector: OptionButton
var route_button: Button
var start_button: Button
var cancel_button: Button
var _options: Dictionary = {}
var _selected_field: String = "radio_id"
var _values: Array = []


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	_label(column, "SYNTHETIC REDESIGN DRAFT | SE STAND-IN | NO REAL READINESS CHECK").add_theme_color_override("font_color", Color(1, 0.76, 0.3))
	_label(column, "Choose one component for the next attempt").add_theme_font_size_override("font_size", 28)
	_experiment = _label(column, "")
	_reason = _label(column, "")
	_reason.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	_requirements = _label(content, "")
	_label(content, "Your component choice (the supplied suggestion is not applied automatically)")
	component_selector = OptionButton.new()
	component_selector.add_item("Radio")
	component_selector.add_item("Battery")
	content.add_child(component_selector)
	value_selector = OptionButton.new()
	content.add_child(value_selector)
	component_selector.item_selected.connect(func(index: int):
		_selected_field = "radio_id" if index == 0 else "battery_id"
		component_changed.emit(_selected_field, _options[_selected_field][1]))
	value_selector.item_selected.connect(func(index: int): component_changed.emit(_selected_field, _values[index]))
	_design = _label(content, "")
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	column.add_child(footer)
	route_button = _button(footer, "Request redesign route", func(): route_requested.emit())
	start_button = _button(footer, "Start second SYNTHETIC run", func(): start_requested.emit())
	cancel_button = _button(footer, "Back / Cancel", func(): cancel_requested.emit())
	var controls: Array[Control] = [component_selector, value_selector, route_button, start_button, cancel_button]
	for i in range(controls.size()):
		controls[i].focus_next = controls[i].get_path_to(controls[(i + 1) % controls.size()])
		controls[i].focus_previous = controls[i].get_path_to(controls[(i + controls.size() - 1) % controls.size()])


func _label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func set_draft(origin: Dictionary, draft: Dictionary, scenario: Dictionary, pending: bool, accepted: bool, reason: String) -> void:
	_options = origin.context.component_options.duplicate(true)
	_experiment.text = "Supplied KE2 experiment: " + str(origin.report.next_experiment) + "\nChoose your own component; orbit/scenario remain fixed."
	_reason.text = reason
	var mission: Dictionary = draft.mission
	_requirements.text = "Original run: %s\nTarget: %s | Objective: %s\nGoal: %s observations; %s MB returned\nDuration: %s orbit / %s supplied steps | Budget: %s credits\nOrbit: %s\nScenario: %s | Version: %s\nThese requirements are preserved in the draft." % [origin.context.run_id, mission.target_region, mission.objective, mission.required_observations, mission.required_returned_data_mb, mission.duration_orbits, scenario.total_steps, mission.budget_credits, draft.design.orbit_id, scenario.scenario_id, scenario.version]
	for field in _options:
		if draft.design[field] != origin.context.config.design[field]:
			_selected_field = field
	component_selector.select(0 if _selected_field == "radio_id" else 1)
	_values = _options[_selected_field].duplicate()
	value_selector.clear()
	for value in _values:
		value_selector.add_item(value)
	value_selector.select(_values.find(draft.design[_selected_field]))
	_design.text = "Original radio: %s\nDraft radio: %s\nOriginal battery: %s\nDraft battery: %s\nAll other selected parts are preserved.\nComparison deferred: these fixtures do not establish a component effect." % [origin.context.config.design.radio_id, draft.design.radio_id, origin.context.config.design.battery_id, draft.design.battery_id]
	route_button.disabled = pending or accepted
	start_button.disabled = pending or not accepted
	# Pending/rejected routing never locks the local component editors or Cancel.
	for control in [component_selector, value_selector, route_button, start_button, cancel_button]:
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color(0, 0, 0, 0)
		focus.border_color = Color(1, 0.8, 0.25)
		focus.set_border_width_all(3)
		control.add_theme_stylebox_override("focus", focus)


func get_visible_labels() -> Dictionary:
	return {"requirements": _requirements.text, "experiment": _experiment.text, "design": _design.text, "route": _reason.text}
