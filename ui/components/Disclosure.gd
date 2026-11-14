extends VBoxContainer
## Keeps secondary information available without crowding the main task.
var body: VBoxContainer
var toggle: Button
var caption: String

func _init(title: String = "Details") -> void:
	caption = title
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle = Button.new()
	toggle.text = "Show " + caption.to_lower()
	toggle.toggle_mode = true
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.custom_minimum_size.y = 40
	toggle.add_theme_font_size_override("font_size", 16)
	add_child(toggle)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	body.hide()
	add_child(body)
	toggle.toggled.connect(set_expanded)

func set_expanded(expanded: bool) -> void:
	toggle.set_pressed_no_signal(expanded)
	toggle.text = ("Hide " if expanded else "Show ") + caption.to_lower()
	body.visible = expanded
