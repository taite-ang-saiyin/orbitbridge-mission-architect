extends "res://ui/components/ReadinessDetails.gd"
signal confirmed(reviewed: Dictionary)
const REVIEW = preload("res://scripts/integration/mission_review.gd")
var acknowledgement: CheckBox
var continue_button: Button
var reviewed_snapshot: Dictionary = {}
func _ready() -> void:
	super._ready()
	title_label.text = "Mission summary"
	close_button.text = "Edit mission  ×"
	footnote.text = "You can return to Creator and change these requirements later. Changes require another review."
	var body = card.get_child(0)
	acknowledgement = CheckBox.new()
	acknowledgement.text = "I’ve reviewed these mission details."
	acknowledgement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	acknowledgement.add_theme_font_size_override("font_size", 13)
	body.add_child(acknowledgement)
	continue_button = UI.button(body, "Confirm & Continue to Builder  →", confirm_review)
	continue_button.custom_minimum_size.y = 44
	continue_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	continue_button.add_theme_stylebox_override("normal", STYLE.box(Color("007cbb"), Color("31eaff"), 10))
	acknowledgement.toggled.connect(func(enabled): continue_button.disabled = not enabled or not REVIEW.can_confirm(reviewed_snapshot))
func show_summary(draft: Dictionary) -> void:
	previous_focus = get_viewport().gui_get_focus_owner()
	reviewed_snapshot = REVIEW.snapshot(draft)
	status_text.text = "Review your mission before building"
	status_text.add_theme_color_override("font_color", Color("69deee"))
	dialog_text = "Check your targets, goals, orbit, duration and budget. Then confirm below to continue."
	description.text = dialog_text
	for child in checks_box.get_children():
		checks_box.remove_child(child)
		child.queue_free()
	var values: Dictionary = REVIEW.details(draft)
	for key in values:
		var item = PanelContainer.new()
		item.add_theme_stylebox_override("panel", STYLE.box(Color("0b2639"), Color("28556a"), 10))
		checks_box.add_child(item)
		var labels = VBoxContainer.new()
		labels.add_theme_constant_override("separation", 4)
		item.add_child(labels)
		UI.label(labels, key, 11, "86b7cd")
		UI.label(labels, str(values[key]), 13, "e0f1fb")
	acknowledgement.set_pressed_no_signal(false)
	continue_button.disabled = true
	if not REVIEW.can_confirm(draft):
		status_text.text = "Complete the mission details first"
		description.text = "Enter a mission name. Surveys need at least one observation for each selected target."
	fit_panel()
	show()
	acknowledgement.grab_focus()
func confirm_review() -> void:
	if not acknowledgement.button_pressed or not REVIEW.can_confirm(reviewed_snapshot): return
	var reviewed: Dictionary = reviewed_snapshot.duplicate(true)
	close()
	confirmed.emit(reviewed)
func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed: return
	if event.keycode == KEY_TAB:
		var controls: Array[Control] = [close_button, acknowledgement]
		if not continue_button.disabled: controls.append(continue_button)
		var current: int = controls.find(get_viewport().gui_get_focus_owner())
		controls[posmod(current + (-1 if event.shift_pressed else 1), controls.size())].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
