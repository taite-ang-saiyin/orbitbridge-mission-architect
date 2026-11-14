extends Button
## Progress navigation, not a feasibility or mission-result indicator.
var caption: String = ""
var number: int = 1
var complete: bool = false
var show_arrow: bool = true
var compact: bool = false
func _ready() -> void:
	text = ""
	custom_minimum_size.y = 54
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
func _draw() -> void:
	var center = Vector2(23, size.y * 0.5)
	var font: Font = get_theme_font("font")
	var active: bool = button_pressed
	draw_circle(center, 16, Color("018be8") if active else Color("16354d"))
	draw_arc(center, 16, 0, TAU, 48, Color("51eaff") if active else Color("92b1c8"), 1.6, true)
	if complete:
		draw_polyline(PackedVector2Array([center + Vector2(-7, 0), center + Vector2(-2, 5), center + Vector2(7, -6)]), Color("e5f6ff"), 2.5, true)
	else:
		var label = str(number)
		var width = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_string(font, center + Vector2(-width * 0.5, 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	var font_size: int = 11 if compact else 12
	var label_width: float = maxf(0, size.x - 52 - (22 if show_arrow else 8))
	var shown: String = caption
	if font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label_width:
		while shown.length() > 0 and font.get_string_size(shown + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label_width:
			shown = shown.substr(0, shown.length() - 1)
		shown += "…"
	draw_string(font, Vector2(46, center.y + 5), shown, HORIZONTAL_ALIGNMENT_LEFT, label_width, font_size, Color("f0f7ff"))
	if show_arrow:
		var tip = Vector2(size.x - 6, center.y)
		draw_line(tip - Vector2(13, 0), tip, Color("5b809a"), 2, true)
		draw_polyline(PackedVector2Array([tip + Vector2(-5, -5), tip, tip + Vector2(-5, 5)]), Color("5b809a"), 2, true)
