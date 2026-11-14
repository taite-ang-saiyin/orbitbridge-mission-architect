extends Control
var slider: HSlider
func _ready() -> void:
	custom_minimum_size.y = 24
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	slider.resized.connect(queue_redraw)
func position_for(value: float) -> float:
	var inset: float = slider.get_theme_icon("grabber").get_width() * 0.5
	return inset + (slider.size.x - inset * 2.0) * (value - slider.min_value) / (slider.max_value - slider.min_value)
func _draw() -> void:
	var font = ThemeDB.fallback_font
	for value in range(int(slider.min_value), int(slider.max_value) + 1, 10):
		var x: float = position_for(value)
		var text: String = str(value)
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_line(Vector2(x, 0), Vector2(x, 4), Color("8cabc0"))
		draw_string(font, Vector2(clampf(x - width * 0.5, 0, size.x - width), 20), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8cabc0"))
