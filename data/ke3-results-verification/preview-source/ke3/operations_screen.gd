extends "res://ke3/outline_control.gd"
## A03 presentation only. Provider supplies values, capabilities and reasons.

signal screen_exited

const ACTIONS := {"observe": "Observe", "downlink": "Transmit", "power_save": "Power-save"}
var _metric_label: Label
var _action_buttons: Dictionary = {}
var _reason_labels: Dictionary = {}
var _route_reason: Label
var _pending: bool = false
var _active: bool = true
var _route_sent: bool = false
var orbit_view: Control
var event_timeline: VBoxContainer
var _visual_grid: GridContainer


func _exit_tree() -> void:
	screen_exited.emit()


func _build_outline() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	var banner := _label(column, "SYNTHETIC A03 | PROVIDER-AUTHORED VALUES AND AVAILABILITY")
	banner.add_theme_color_override("font_color", Color(1.0, 0.76, 0.3))
	var title := _label(column, "Mission Operations")
	title.add_theme_font_size_override("font_size", 30)
	_identity_label = _label(column, "")
	_boundary_label = _label(column, "")
	_boundary_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.4))
	_visual_grid = GridContainer.new()
	_visual_grid.columns = 2
	_visual_grid.add_theme_constant_override("h_separation", 16)
	column.add_child(_visual_grid)
	orbit_view = preload("res://ke3/orbit_diagram.gd").new()
	orbit_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_visual_grid.add_child(orbit_view)
	var telemetry := VBoxContainer.new()
	telemetry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_visual_grid.add_child(telemetry)
	_metric_label = _section(telemetry, "TELEMETRY - NO LOCAL SIMULATION")
	event_timeline = preload("res://ke3/event_timeline.gd").new()
	column.add_child(event_timeline)
	resized.connect(_layout_visuals)
	_layout_visuals()
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	column.add_child(actions)
	for action_id in ACTIONS:
		var action_column := VBoxContainer.new()
		action_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(action_column)
		var button := Button.new()
		button.name = "Action_" + action_id
		button.text = ACTIONS[action_id]
		button.pressed.connect(request_action.bind(StringName(action_id)))
		button.focus_entered.connect(func(): _keep_action_focus_visible.call_deferred(button, scroll))
		action_column.add_child(button)
		_action_buttons[action_id] = button
		_reason_labels[action_id] = _label(action_column, "")
	_route_button = Button.new()
	_route_button.name = "ResultsRoute"
	_route_button.text = "Request Results route"
	_route_button.pressed.connect(_request_result_route)
	column.add_child(_route_button)
	_route_reason = _label(column, "")
	_label(column, "Read-only telemetry. Action availability and blocked reasons come from the provider.")
	_label(column, "Visual cues adapted from NASA Mission Viz. SYNTHETIC diagram; not a flight trajectory. See KE2 source notes.")


func _keep_action_focus_visible(button: Control, scroll: ScrollContainer) -> void:
	if not button.has_focus():
		return
	# Native follow_focus reveals the control; retain space for its focus outline.
	var clip := scroll.get_global_rect().grow(-4)
	var rect := button.get_global_rect()
	if rect.end.y > clip.end.y:
		scroll.scroll_vertical += ceili(rect.end.y - clip.end.y)
	elif rect.position.y < clip.position.y:
		scroll.scroll_vertical -= ceili(clip.position.y - rect.position.y)


func _layout_visuals() -> void:
	if is_instance_valid(_visual_grid):
		_visual_grid.columns = 2 if size.x >= 850 else 1


func _value(field: String, unit: String = "") -> String:
	if not _state.has(field) or _state[field] == null:
		return "Unavailable"
	return str(_state[field]) + unit


func _flag(field: String) -> String:
	if not _state.get(field) is bool:
		return "Unavailable"
	return "On" if _state[field] else "Off"


func get_display_metrics() -> Dictionary:
	return {
		"step": _value("step"), "phase": _value("phase"),
		"target_access": _flag("target_access"), "contact": _flag("contact_on"),
		"energy": _value("energy_wh", " Wh"), "generated": _value("generated_mb", " MB"),
		"stored": _value("stored_mb", " MB"), "returned": _value("returned_mb", " MB"),
		"observations": _value("observations_completed") + "/" + _value("observations_requested"),
	}


func set_interaction_pending(value: bool) -> void:
	_pending = value
	if is_node_ready():
		_render()


func set_screen_active(value: bool) -> void:
	_active = value
	if value:
		_route_sent = false
	if is_node_ready():
		_render()


func get_action_control_state(action_id: StringName) -> Dictionary:
	var availability: Variant = _state.get("action_availability", {})
	var capability: Dictionary = {}
	if availability is Dictionary and availability.get(String(action_id)) is Dictionary:
		capability = availability[String(action_id)]
	return _control_state(capability)


func get_route_control_state() -> Dictionary:
	var capability: Variant = _state.get("results_route", {})
	return _control_state(capability if capability is Dictionary else {})


func _control_state(capability: Dictionary) -> Dictionary:
	var reasons: Array[String] = []
	if capability.get("enabled") != true:
		var reason := str(capability.get("reason", "Unavailable"))
		reasons.append(reason if not reason.is_empty() else "Unavailable")
	if _matching_run_id().is_empty():
		reasons.append("Run identity Unavailable")
	if not _active:
		reasons.append("Screen inactive")
	if _pending:
		reasons.append("Request pending")
	if _route_sent:
		reasons.append("Route requested")
	return {"enabled": reasons.is_empty(), "reason": "; ".join(reasons)}


func _render() -> void:
	var metrics := get_display_metrics()
	orbit_view.set_snapshot(_context, _state)
	event_timeline.set_snapshot(_context, _state)
	_identity_label.text = "Run: " + (_matching_run_id() if not _matching_run_id().is_empty() else "Unavailable")
	_boundary_label.text = "" if _boundary_error.is_empty() else "Provider error: " + _boundary_error
	_boundary_label.visible = not _boundary_error.is_empty()
	_metric_label.text = "Step: %s | Phase: %s\nTarget access: %s | Contact: %s\nEnergy: %s\nGenerated: %s | Stored: %s | Returned: %s\nObservations: %s" % [metrics.step, metrics.phase, metrics.target_access, metrics.contact, metrics.energy, metrics.generated, metrics.stored, metrics.returned, metrics.observations]
	for action_id in ACTIONS:
		var control := get_action_control_state(StringName(action_id))
		_action_buttons[action_id].disabled = not control.enabled
		_reason_labels[action_id].text = ACTIONS[action_id] + ": " + ("Available" if control.enabled else control.reason)
	var route := get_route_control_state()
	_route_button.disabled = not route.enabled
	_route_reason.text = "Results route: " + ("Available" if route.enabled else route.reason)


func request_action(action_id: StringName) -> void:
	if not ACTIONS.has(String(action_id)) or not get_action_control_state(action_id).enabled:
		return
	# Latch before emitting, including when the receiver defers its provider call.
	set_interaction_pending(true)
	action_requested.emit(_matching_run_id(), action_id)


func _request_result_route() -> void:
	if not get_route_control_state().enabled:
		return
	_route_sent = true
	_render()
	result_route_requested.emit(_matching_run_id())
