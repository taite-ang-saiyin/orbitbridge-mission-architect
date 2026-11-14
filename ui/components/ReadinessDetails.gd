extends Control
## In-game, scrollable review. No separate OS dialog or changes to validation.
const UI = preload("res://ui/components/UI.gd")
const STYLE = preload("res://ui/theme/WorkbenchTheme.gd")
const NAMES = {"input_schema": "Mission details", "catalog_references": "Component selections", "profile_mass": "Spacecraft mass", "launcher_capacity": "Launcher capacity", "budget": "Mission budget", "launch_orbit": "Launch compatibility", "target_orbit": "Target access", "essential_power": "Power balance"}
var dialog_text: String = ""
var margins: MarginContainer
var card: PanelContainer
var status_text: Label
var description: Label
var checks_box: VBoxContainer
var close_button: Button
var title_label: Label
var footnote: Label
var previous_focus: Control
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.025, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	shade.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed: close())
	margins = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margins)
	card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", STYLE.box(Color("061d2f"), Color("3cbdd4"), 18))
	margins.add_child(card)
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	card.add_child(body)
	var header = HBoxContainer.new()
	body.add_child(header)
	title_label = UI.label(header, "Flight readiness details", 20)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button = UI.button(header, "Close  ×", close)
	close_button.custom_minimum_size.y = 40
	status_text = UI.label(body, "", 15, "54e4b3")
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	var contents = VBoxContainer.new()
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.add_theme_constant_override("separation", 12)
	scroll.add_child(contents)
	description = UI.label(contents, "", 13, "bdd3e1")
	checks_box = VBoxContainer.new()
	checks_box.add_theme_constant_override("separation", 8)
	contents.add_child(checks_box)
	footnote = UI.label(body, "Passing these checks allows launch. Flight results depend on your design and decisions.", 11, "89adbf")
	get_viewport().size_changed.connect(fit_panel)
	fit_panel()
	hide()
func fit_panel() -> void:
	var dimensions: Vector2 = get_viewport_rect().size
	for side in ["left", "right"]: margins.add_theme_constant_override("margin_" + side, maxi(20, int((dimensions.x - 640) * 0.5)))
	for side in ["top", "bottom"]: margins.add_theme_constant_override("margin_" + side, maxi(20, int((dimensions.y - 680) * 0.5)))
func show_review(validation: Dictionary, issues: String) -> void:
	previous_focus = get_viewport().gui_get_focus_owner()
	dialog_text = "All readiness checks pass. Your spacecraft is ready for launch." if issues.is_empty() else issues
	description.text = dialog_text
	status_text.text = "✓  Ready to launch" if validation.ready_to_launch else "Review the checks below before launch"
	status_text.add_theme_color_override("font_color", Color("54e4b3") if validation.ready_to_launch else Color("ffbe79"))
	for child in checks_box.get_children():
		checks_box.remove_child(child)
		child.queue_free()
	for key in validation.checks:
		var check: Dictionary = validation.checks[key]
		var passed: bool = check.status == "pass"
		var item = PanelContainer.new()
		item.add_theme_stylebox_override("panel", STYLE.box(Color("0b2639"), Color("28556a"), 10))
		checks_box.add_child(item)
		var labels = VBoxContainer.new()
		labels.add_theme_constant_override("separation", 4)
		item.add_child(labels)
		UI.label(labels, ("✓  " if passed else "!  ") + NAMES.get(key, key.capitalize()), 13, "68e3bc" if passed else "ffbe79")
		UI.label(labels, UI.user_message(check.message), 12, "b7cedd")
	fit_panel()
	show()
	close_button.grab_focus()
func close() -> void:
	hide()
	if is_instance_valid(previous_focus): previous_focus.grab_focus()
func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
