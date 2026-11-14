extends Control
## Static display of the supplied mission score, not a scoring algorithm.
var score: Variant = null
var accent = Color("76ddd8")

func _init() -> void:
	custom_minimum_size = Vector2(150,150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_score(value: Variant, color: Color) -> void:
	score = value
	accent = color
	queue_redraw()

func _draw() -> void:
	var center = size * 0.5
	var radius = minf(size.x, size.y) * 0.5 - 9
	draw_circle(center, radius - 6, Color("0a2033"))
	draw_arc(center, radius, 0, TAU, 96, Color("18374d"), 7, true)
	if (score is int or score is float) and is_finite(score) and score > 0:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(score) / 100,0,1), 96, accent, 7, true)
