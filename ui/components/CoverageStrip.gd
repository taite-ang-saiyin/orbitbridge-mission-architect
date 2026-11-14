extends Control
## Six authored sample slots. This control does not compute visibility or coverage.
var slots: Array = [0, 2, 4]
func _ready() -> void:
	custom_minimum_size = Vector2(90, 30)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var gap = 4.0
	var width = (size.x - gap * 5) / 6.0
	for i in 6:
		var rect = Rect2(i * (width + gap), size.y * 0.5 - 4, width, 8)
		var color = Color("53ef74") if i in slots else Color("2a455f")
		draw_style_box(preload("res://ui/theme/WorkbenchTheme.gd").box(color, color, 0), rect)
