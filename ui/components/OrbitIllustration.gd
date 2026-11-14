extends Control
var progress = 0.0:
	set(value):
		progress = value
		queue_redraw()
func _ready():
	custom_minimum_size = Vector2(300, 235)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw():
	var c = size * Vector2(0.5, 0.48)
	var r = minf(size.x * 0.20, size.y * 0.28)
	for i in 36:
		var star = Vector2(fmod(i * 137.0 + 17, size.x), fmod(i * 73.0 + 23, size.y))
		draw_circle(star, 1, Color("34516b"))
	draw_circle(c, r + 7, Color("173f59"))
	draw_circle(c, r, Color("19648b"))
	draw_arc(c, r * 0.75, -1.2, 1.4, 30, Color("53b6b3"), 13, true)
	draw_arc(c, r * 0.48, 1.6, 3.7, 30, Color("419caa"), 17, true)
	var points = PackedVector2Array()
	for i in 97:
		var a = i * TAU / 96.0
		points.append(c + Vector2(cos(a) * r * 2.1, sin(a) * r * 1.22))
	draw_polyline(points, Color("407c9b"), 1.5, true)
	var angle = progress * TAU - 0.7
	var sat = c + Vector2(cos(angle) * r * 2.1, sin(angle) * r * 1.22)
	draw_line(sat - Vector2(24, 0), sat + Vector2(24, 0), Color("55d8ed"), 9, true)
	draw_rect(Rect2(sat - Vector2(6, 9), Vector2(12, 18)), Color("e5f5ff"))
	draw_circle(c + Vector2(-r * 0.65, r * 0.52), 5, Color("f6bd71"))
	draw_circle(c + Vector2(r * 0.55, -r * 0.38), 5, Color("6ce5c0"))
