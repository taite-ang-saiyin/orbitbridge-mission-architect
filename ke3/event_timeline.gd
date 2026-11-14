extends VBoxContainer
## Replaces rows from the accepted snapshot; never appends speculative events.

var _rows: Array[Dictionary] = []
var _current_text: String = "Current state: Unavailable"
var _current_label: Label
var _row_box: VBoxContainer


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "Event timeline | provider order"
	add_child(title)
	_current_label = _label(self, _current_text)
	_row_box = VBoxContainer.new()
	_row_box.add_theme_constant_override("separation", 5)
	add_child(_row_box)
	_rebuild()


func _label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _field(data: Dictionary, field: String) -> String:
	return "Unavailable" if not data.has(field) or data[field] == null else str(data[field])


func set_snapshot(context: Dictionary, state: Dictionary) -> void:
	var run_id := str(context.get("run_id", ""))
	var next_rows: Array[Dictionary] = []
	var valid_run: bool = not run_id.is_empty() and state.get("run_id") == run_id
	if valid_run:
		for event in state.get("events", []):
			if event.get("run_id") != run_id:
				continue
			var stamp := "Step " + _field(event, "step")
			if event.has("time"):
				stamp = "Time " + _field(event, "time") if not event.has("step") else stamp + " | Time " + _field(event, "time")
			next_rows.append({"event_id": event.event_id, "run_id": run_id, "stamp": stamp, "text": _field(event, "label")})
	var next_current := "Current state: Unavailable"
	if valid_run:
		next_current = "Current state: %s | Phase: %s | Step: %s" % [_field(state, "lifecycle"), _field(state, "phase"), _field(state, "step")]
	if _rows == next_rows and _current_text == next_current:
		return
	_rows = next_rows
	_current_text = next_current
	if is_node_ready():
		_rebuild()


func get_rows() -> Array:
	return _rows.duplicate(true)


func get_current_text() -> String:
	return _current_text


func _rebuild() -> void:
	_current_label.text = _current_text
	for child in _row_box.get_children():
		child.free()
	if _rows.is_empty():
		_label(_row_box, "No events supplied for the active run.")
	for row in _rows:
		var label := _label(_row_box, row.stamp + " | " + row.text)
		label.tooltip_text = row.event_id
