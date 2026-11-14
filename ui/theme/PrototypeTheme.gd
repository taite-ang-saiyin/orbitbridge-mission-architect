extends RefCounted
static func build() -> Theme:
	var t = Theme.new()
	t.default_font_size = 15
	t.set_color("font_color", "Label", Color("e6edf8"))
	for kind in ["Button", "OptionButton", "LineEdit", "SpinBox"]:
		t.set_color("font_color", kind, Color("e6edf8"))
		for style in ["normal", "hover", "pressed", "focus", "disabled"]:
			var box = StyleBoxFlat.new()
			box.bg_color = Color("163049") if style in ["hover", "pressed"] else Color("101f32")
			box.border_color = Color("43c9e8") if style in ["focus", "pressed"] else Color("29435e")
			box.set_border_width_all(1)
			box.set_corner_radius_all(7)
			box.content_margin_left = 14
			box.content_margin_right = 14
			box.content_margin_top = 10
			box.content_margin_bottom = 10
			t.set_stylebox(style, kind, box)
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color("102034")
	panel.border_color = Color("263d55")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(12)
	panel.content_margin_left = 20
	panel.content_margin_right = 20
	panel.content_margin_top = 18
	panel.content_margin_bottom = 18
	t.set_stylebox("panel", "PanelContainer", panel)
	return t
