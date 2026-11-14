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

static func user_message(value: String) -> String:
	# Keep owner names in source diagnostics, outside player-facing messages.
	if "cached KE2 version" in value:
		return "Scoring is currently unavailable for survey missions. Recorded flight totals are still available."
	if "survey-capable evaluator" in value:
		return "Review the flight totals, or choose Capture Imagery for a scored mission."
	if value == "HPC metadata provides observation opportunities for this target; individual actions still depend on the current step.":
		return "Observation opportunities are available; individual actions depend on the current step."
	var owners = RegEx.new()
	owners.compile("(?i)\\b(?:KE[123]|HPC)\\b(?:'s)?")
	return owners.sub(value, "the mission system", true)
