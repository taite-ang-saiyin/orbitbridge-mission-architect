extends HBoxContainer
## Home-only navigation overview; all steps use the same compact circle-and-arrow style.
signal navigate(index: int)
const LABELS = ["Create", "Build", "Check", "Operate", "Debrief"]
func _ready() -> void:
	custom_minimum_size = Vector2(220, 70)
	add_theme_constant_override("separation", 0)
	for i in LABELS.size():
		var button = Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = ["Mission Creator", "Spacecraft Builder", "Flight Readiness", "Operations", "Debrief"][i]
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(func(): navigate.emit(i + 1))
		button.resized.connect(queue_redraw)
		button.focus_entered.connect(queue_redraw)
		button.focus_exited.connect(queue_redraw)
		button.mouse_entered.connect(queue_redraw)
		button.mouse_exited.connect(queue_redraw)
		add_child(button)
	resized.connect(queue_redraw)
func _draw() -> void:
	if get_child_count() != 5: return
	var font: Font = get_theme_font("font")
	for i in 5:
		var button: Button = get_child(i)
		var center = Vector2(button.position.x + button.size.x * 0.5, 24)
		var active: bool = i == 0 or button.has_focus() or button.is_hovered()
		if i < 4:
			var next: Button = get_child(i + 1)
			var end = Vector2(next.position.x + next.size.x * 0.5 - 19, 24)
			draw_line(center + Vector2(19, 0), end, Color("527991"), 1.5, true)
			if end.x - center.x > 25:
				draw_polyline(PackedVector2Array([end + Vector2(-4, -3), end, end + Vector2(-4, 3)]), Color("77a9bf"), 1.5, true)
		if active:
			draw_circle(center, 21, Color(0.0, 0.85, 1.0, 0.10))
			draw_circle(center, 18, Color(0.0, 0.85, 1.0, 0.16))
		draw_circle(center, 15, Color("009cbb") if active else Color("0c263b"))
		draw_arc(center, 15, 0, TAU, 48, Color("46efff") if active else Color("7597b1"), 1.8, true)
		var number: String = str(i + 1)
		var width: float = font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(font, center + Vector2(-width * 0.5, 5), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("edfbff"))
		var caption: String = ["ဖန်တီး", "ဆောက်", "စစ်ဆေး", "ထိန်းချုပ်", "သုံးသပ်"][i] if get_meta("se_language", "en") == "my" else LABELS[i]
		var text_width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, Vector2(center.x - text_width * 0.5, 59), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("46efff") if active else Color("c1d7e5"))
