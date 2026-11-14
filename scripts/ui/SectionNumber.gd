extends Control
var number: int = 1
func _ready() -> void:
	custom_minimum_size = Vector2(30, 30)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var center = size * 0.5
	draw_circle(center, 13, Color("008de8"))
	draw_arc(center, 13, 0, TAU, 48, Color("45edff"), 1.5, true)
	var font = ThemeDB.fallback_font
	var text = str(number)
	var width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(font, center + Vector2(-width * 0.5, 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
