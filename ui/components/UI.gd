extends RefCounted
static func label(parent: Node, text: String, size: int = 15, color: String = "e6edf8") -> Label:
	var n = Label.new()
	n.text = text
	n.add_theme_font_size_override("font_size", size)
	n.add_theme_color_override("font_color", Color(color))
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(n)
	return n
static func button(parent: Node, text: String, action: Callable) -> Button:
	var n = Button.new()
	n.text = text
	n.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	n.pressed.connect(action)
	parent.add_child(n)
	return n
static func panel(parent: Node, title: String) -> VBoxContainer:
	var shell = PanelContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(shell)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	shell.add_child(box)
	label(box, title, 14, "6fd9eb")
	return box
