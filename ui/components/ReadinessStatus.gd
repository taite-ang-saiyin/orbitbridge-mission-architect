extends Control
var warning = false
func _ready() -> void:
	custom_minimum_size = Vector2(28, 28)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var c = size * 0.5
	if warning:
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -12), c + Vector2(13, 11), c + Vector2(-13, 11)]), Color("ffd72b"))
		draw_line(c + Vector2(0, -5), c + Vector2(0, 3), Color("182421"), 2.4, true)
		draw_circle(c + Vector2(0, 7), 1.4, Color("182421"))
	else:
		draw_circle(c, 12, Color("25ef83"))
		draw_polyline(PackedVector2Array([c + Vector2(-5, 0), c + Vector2(-1, 4), c + Vector2(6, -5)]), Color("05252b"), 2.5, true)
