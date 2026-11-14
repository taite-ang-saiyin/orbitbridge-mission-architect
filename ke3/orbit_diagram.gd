extends Control
## Illustrative 2D geometry only. No propagator, provider or mission timer.

var _run_id: String = ""
var _step: Variant = null
var _marker: Variant = null
var _target: String = "Unavailable"
var _contact: String = "Unavailable"
var _pulse: float = 0.0
var _title: Label
var _caption: Label
var _flags_row: HBoxContainer
var _target_label: Label
var _contact_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(300, 236)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = Label.new()
	_title.text = "Illustrative trajectory"
	_title.position = Vector2(12, 8)
	add_child(_title)
	_caption = Label.new()
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_caption)
	_flags_row = HBoxContainer.new()
	_flags_row.add_theme_constant_override("separation", 16)
	add_child(_flags_row)
	_target_label = Label.new()
	_contact_label = Label.new()
	_flags_row.add_child(_target_label)
	_flags_row.add_child(_contact_label)
	resized.connect(_layout_labels)
	_layout_labels()


func _process(delta: float) -> void:
	# Pulse changes appearance only; the marker remains tied to accepted step.
	_pulse = fmod(_pulse + delta * 2.0, TAU)
	queue_redraw()


func set_snapshot(context: Dictionary, state: Dictionary) -> void:
	_run_id = str(context.get("run_id", ""))
	if _run_id.is_empty() or state.get("run_id") != _run_id:
		state = {}
	_step = state.get("step")
	_marker = null
	if _step is int or _step is float:
		# Twelve diagram positions per turn. This is not elapsed time or physics.
		var angle := -PI / 2.0 + TAU * float(_step) / 12.0
		_marker = Vector2(0.5 + 0.4 * cos(angle), 0.5 + 0.32 * sin(angle))
	_target = _flag(state.get("target_access"))
	_contact = _flag(state.get("contact_on"))
	if is_node_ready():
		_layout_labels()
	queue_redraw()


func _flag(value: Variant) -> String:
	return ("On" if value else "Off") if value is bool else "Unavailable"


func get_visual_snapshot() -> Dictionary:
	return {"run_id": _run_id, "step": "Unavailable" if _step == null else str(_step),
		"marker": [] if _marker == null else [_marker.x, _marker.y],
		"target_access": _target, "contact": _contact}


func _layout_labels() -> void:
	_caption.position = Vector2(12, size.y - 54)
	_caption.size = Vector2(maxf(1.0, size.x - 24), 26)
	_caption.text = "Step: %s | Step-mapped diagram" % ["Unavailable" if _step == null else str(_step)]
	_flags_row.position = Vector2(12, size.y - 28)
	_target_label.text = "Target access: " + _target
	_contact_label.text = "Contact: " + _contact
	_target_label.modulate = _flag_color(_target)
	_contact_label.modulate = _flag_color(_contact)
	queue_redraw()


func _flag_color(value: String) -> Color:
	if value == "On":
		return Color(0.45, 0.95, 0.7)
	return Color(0.7, 0.75, 0.8) if value == "Off" else Color(1.0, 0.76, 0.3)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.07, 0.12))
	var area := Rect2(18, 36, maxf(1.0, size.x - 36), maxf(1.0, size.y - 100))
	var center := area.position + area.size * 0.5
	var path := PackedVector2Array()
	for index in range(97):
		var angle := TAU * float(index) / 96.0
		path.append(area.position + area.size * Vector2(0.5 + 0.4 * cos(angle), 0.5 + 0.32 * sin(angle)))
	draw_polyline(path, Color(0.4, 0.68, 0.9), 2.0, true)
	var radius := minf(area.size.x, area.size.y) * 0.22
	draw_circle(center, radius, Color(0.08, 0.32, 0.68))
	draw_arc(center, radius * 0.75, -PI * 0.7, PI * 0.7, 32, Color(0.25, 0.65, 0.8), 2.0, true)
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), Color(0.25, 0.65, 0.8), 1.0, true)
	if _marker != null:
		var point: Vector2 = area.position + area.size * _marker
		draw_circle(point, 12.0 + sin(_pulse) * 2.0, Color(1.0, 0.75, 0.3, 0.15))
		draw_rect(Rect2(point - Vector2(4, 5), Vector2(8, 10)), Color(1.0, 0.85, 0.45))
		draw_rect(Rect2(point - Vector2(15, 3), Vector2(9, 6)), Color(0.3, 0.7, 1.0))
		draw_rect(Rect2(point + Vector2(6, -3), Vector2(9, 6)), Color(0.3, 0.7, 1.0))
