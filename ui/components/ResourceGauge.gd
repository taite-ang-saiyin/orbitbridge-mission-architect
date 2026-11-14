extends Control
## Fixed gauge fraction from the mock fixture, not a resource calculation.
var fraction = 0.79
var caption = "Mass"
var value_text = "118.5 kg"
var limit_text = "≤ 150 kg"
func _ready() -> void:
	custom_minimum_size = Vector2(78, 118)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var font = ThemeDB.fallback_font
	var radius = minf(size.x * 0.44, 58)
	var center = Vector2(size.x * 0.5, 65)
	draw_arc(center, radius, PI, TAU, 64, Color("24415a"), 9, true)
	draw_arc(center, radius, PI, PI + PI * fraction, 64, Color("24ed83"), 9, true)
	var end = center + Vector2(cos(PI + PI * fraction), sin(PI + PI * fraction)) * radius
	draw_circle(end, 4.5, Color("d5fff0"))
	for line in [[caption, 12, 48, "d0e0ed"], [value_text, 16, 72, "f1fff9"], [limit_text, 12, 98, "a4d4cf"]]:
		var width = font.get_string_size(line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[1]).x
		draw_string(font, Vector2((size.x - width) * 0.5, line[2]), line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[1], Color(line[3]))
