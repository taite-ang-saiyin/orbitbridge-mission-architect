extends RefCounted
static func box(color: Color, border: Color, padding: int = 9) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(11)
	s.content_margin_left = padding
	s.content_margin_right = padding
	s.content_margin_top = padding
	s.content_margin_bottom = padding
	return s
static func build() -> Theme:
	var t = preload("res://ui/theme/PrototypeTheme.gd").build()
	t.default_font_size = 13
	t.set_stylebox("panel", "PanelContainer", box(Color("031625ed"), Color("28627d")))
	for kind in ["Button", "OptionButton", "LineEdit", "TextEdit"]:
		for mode in ["normal", "hover", "pressed", "focus"]:
			var selected = mode in ["pressed", "focus"]
			var style = box(Color("07394d") if selected else (Color("102e43") if mode == "hover" else Color("0a2033")), Color("27e9ff") if selected else Color("345b76"), 7)
			if selected:
				style.shadow_size = 8
				style.shadow_color = Color(0, 0.8, 1, 0.2)
			t.set_stylebox(mode, kind, style)
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			t.set_color(color_name, kind, Color("e9f5ff"))
	t.set_stylebox("background", "ProgressBar", box(Color("18374d"), Color("18374d"), 0))
	t.set_stylebox("fill", "ProgressBar", box(Color("2de58a"), Color("2de58a"), 0))
	t.set_stylebox("panel", "AcceptDialog", box(Color("0a2033"), Color("345b76"), 16))
	var border = box(Color("091b2c"), Color("3d88a3"), 4)
	border.content_margin_top = 30
	t.set_stylebox("embedded_border", "Window", border)
	t.set_stylebox("embedded_unfocused_border", "Window", border)
	t.set_color("title_color", "Window", Color("bfe8f8"))
	t.set_stylebox("panel", "ItemList", box(Color("081d30"), Color("284d65"), 5))
	t.set_stylebox("selected", "ItemList", box(Color("0a4257"), Color("39ccdd"), 2))
	t.set_stylebox("selected_focus", "ItemList", box(Color("0a4257"), Color("39ccdd"), 2))
	t.set_color("font_color", "ItemList", Color("c7deeb"))
	t.set_color("font_selected_color", "ItemList", Color("eaffff"))
	return t
