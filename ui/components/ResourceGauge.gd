extends Control
## Presentation gauge. Caller supplies values and normalized utilization.
var fraction = 0.79
var caption = "Mass"
var value_text = "118.5 kg"
var limit_text = "≤ 150 kg"
func _ready() -> void:
	custom_minimum_size = Vector2(148, 118)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var language: String = get_meta("se_language", "en")
	var copy = preload("res://scripts/settings/MyanmarText.gd")
	var font = copy.myanmar_font() if language == "my" else ThemeDB.fallback_font
	var radius = minf(size.x * 0.44, 58)
	var center = Vector2(size.x * 0.5, 65)
	draw_arc(center, radius, PI, TAU, 64, Color("24415a"), 9, true)
	draw_arc(center, radius, PI, PI + PI * clampf(fraction, 0.0, 1.0), 64, Color("24ed83"), 9, true)
	var end = center + Vector2(cos(PI + PI * clampf(fraction, 0.0, 1.0)), sin(PI + PI * clampf(fraction, 0.0, 1.0))) * radius
	draw_circle(end, 4.5, Color("d5fff0"))
	for line in [[caption, 12, 48, "d0e0ed"], [value_text, 16, 72, "f1fff9"], [limit_text, 12, 98, "a4d4cf"]]:
		line[0] = copy.text(line[0], language)
		var width = font.get_string_size(line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[1]).x
		draw_string(font, Vector2((size.x - width) * 0.5, line[2]), line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[1], Color(line[3]))
