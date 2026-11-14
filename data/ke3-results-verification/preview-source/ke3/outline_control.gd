extends Control
## Provisional presentation boundary. Owns only local snapshots and UI nodes.
## No autoloads, simulation, legality, evaluation, draft writes, or routing.

signal action_requested(run_id: String, action_id: StringName)
signal result_route_requested(run_id: String)
signal retry_requested(run_id: String)

@export_enum("Operations", "Results") var outline_kind: String = "Operations"

var _context: Dictionary = {}
var _state: Dictionary = {}
var _report: Dictionary = {}
var _identity_label: Label
var _boundary_label: Label
var _boundary_error: String = ""
var _context_label: Label
var _state_label: Label
var _report_label: Label
var _route_button: Button
var _retry_button: Button


func set_inputs(context: Dictionary, state: Dictionary, report: Dictionary) -> void:
	# JSON-compatible snapshots, never references to mutable team dictionaries.
	_context = context.duplicate(true)
	_state = state.duplicate(true)
	_report = report.duplicate(true)
	_boundary_error = ""
	if is_node_ready():
		_render()


func set_boundary_error(message: String) -> void:
	_boundary_error = message
	if is_node_ready():
		_render()


func get_input_snapshot() -> Dictionary:
	return {
		"context": _context.duplicate(true),
		"state": _state.duplicate(true),
		"report": _report.duplicate(true),
	}


func _ready() -> void:
	_build_outline()
	_render()


func _build_outline() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var scroll := ScrollContainer.new()
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	scroll.add_child(column)
	var banner := _label(column, "SYNTHETIC OUTLINE PREVIEW | NO LIVE DATA WIRED")
	banner.add_theme_color_override("font_color", Color(1.0, 0.76, 0.3))
	var title := _label(column, outline_kind + " Control")
	title.add_theme_font_size_override("font_size", 30)
	_label(column, "Provisional names. Rendering only; controls send intents to their owners.")
	_identity_label = _label(column, "")
	_boundary_label = _label(column, "")
	_boundary_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.4))
	if outline_kind == "Results":
		_report_label = _section(column, "REPORT / CREDITS - KE2")
		_context_label = _section(column, "CONFIG SELECTIONS / CONTEXT")
		_state_label = _section(column, "HPC STATE / EVENTS - KE1")
	else:
		_state_label = _section(column, "HPC STATE / EVENTS - KE1")
		_context_label = _section(column, "CONFIG SELECTIONS / CONTEXT")
		_report_label = _section(column, "REPORT / CREDITS - KE2")
	var intent_title := "ACTION / RESULT ROUTE INTENTS - SE + KE1"
	if outline_kind == "Results":
		intent_title = "RETRY INTENT - SE"
	_label(column, intent_title)
	if outline_kind == "Operations":
		var action_button := Button.new()
		action_button.text = "Action controls pending KE1 action identifiers and legality contract"
		action_button.disabled = true
		column.add_child(action_button)
		_route_button = Button.new()
		_route_button.text = "Request Results route"
		_route_button.pressed.connect(_request_result_route)
		column.add_child(_route_button)
	else:
		_retry_button = Button.new()
		_retry_button.text = "Request retry"
		_retry_button.pressed.connect(_request_retry)
		column.add_child(_retry_button)
	_label(column, "Missing data stays pending. No step, score, source credit, or outcome is invented.")


func _label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label


func _section(parent: Node, title: String) -> Label:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var padding := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(padding)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	padding.add_child(column)
	_label(column, title)
	return _label(column, "")


func _render() -> void:
	# Only writes this scene's labels and controls. Never emits an intent.
	var run_id := _matching_run_id()
	_boundary_label.text = "" if _boundary_error.is_empty() else "Input unavailable: " + _boundary_error
	_identity_label.text = "Run identity: pending / unavailable"
	if not run_id.is_empty():
		_identity_label.text = "Provisional run identity: " + run_id
	_context_label.text = _snapshot_text(_context, "SE context/config selections pending.")
	_state_label.text = _snapshot_text(_state, "KE1 HPC state/events pending; step unavailable.")
	_report_label.text = _snapshot_text(_report, "KE2 report/credits pending; evaluation and sources unconfirmed.")
	if is_instance_valid(_route_button):
		_route_button.disabled = run_id.is_empty()
	if is_instance_valid(_retry_button):
		_retry_button.disabled = run_id.is_empty()


func _snapshot_text(snapshot: Dictionary, missing_text: String) -> String:
	if snapshot.is_empty():
		return missing_text
	var summary: Array[String] = []
	if snapshot.has("status"):
		summary.append("Report: " + str(snapshot.status))
	if snapshot.has("step"):
		summary.append("Step: %s | Energy: %s Wh | Stored: %s MB | Returned: %s MB" % [snapshot.step, snapshot.get("energy_wh", "pending"), snapshot.get("stored_mb", "pending"), snapshot.get("returned_mb", "pending")])
	if snapshot.has("observations_completed"):
		summary.append("Observations: %s/%s" % [snapshot.observations_completed, snapshot.get("observations_requested", "pending")])
	if snapshot.has("return_threshold_mb"):
		summary.append("Returned: %s/%s MB" % [snapshot.get("returned_mb", "pending"), snapshot.return_threshold_mb])
	if snapshot.has("causes"):
		summary.append("Cause: " + str(snapshot.causes))
	if snapshot.has("suggested_changes"):
		summary.append("Suggested change: " + str(snapshot.suggested_changes))
	var prefix := "" if summary.is_empty() else "\n".join(summary) + "\n\n"
	return prefix + "UNWIRED SYNTHETIC SNAPSHOT (schema/units pending):\n" + JSON.stringify(snapshot, "  ")


func _matching_run_id() -> String:
	# Envelope correlation only. KE1 retains all action legality decisions.
	var candidate: Variant = _context.get("run_id")
	if not candidate is String or candidate.strip_edges().is_empty():
		return ""
	var required_snapshot: Dictionary = _state if outline_kind == "Operations" else _report
	if required_snapshot.get("run_id") != candidate:
		return ""
	for snapshot in [_state, _report]:
		if not snapshot.is_empty() and snapshot.get("run_id") != candidate:
			return ""
	return candidate


func request_action(action_id: StringName) -> void:
	# Explicit caller intent only; never called during render or on a timer.
	var run_id := _matching_run_id()
	if outline_kind == "Operations" and not run_id.is_empty() and not action_id.is_empty():
		action_requested.emit(run_id, action_id)


func _request_result_route() -> void:
	var run_id := _matching_run_id()
	if not run_id.is_empty():
		result_route_requested.emit(run_id)


func _request_retry() -> void:
	var run_id := _matching_run_id()
	if not run_id.is_empty():
		retry_requested.emit(run_id)
