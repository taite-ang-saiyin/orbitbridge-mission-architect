extends Control
## Explicit opt-in entry. Neither startup nor the general provider seam loads it.

var session = preload("res://ke3/presentation_session.gd").new()
var provider: RefCounted
var operations: Control
var results: Control
var _case_ids: Array = []
var _selector: OptionButton
var _status: Label


func _ready() -> void:
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(column)
	var banner := Label.new()
	banner.text = "SYNTHETIC MISSION FIXTURES | EXPLICIT PREVIEW ENTRY | NO LIVE PROVIDER"
	banner.add_theme_color_override("font_color", Color(1.0, 0.76, 0.3))
	column.add_child(banner)
	_selector = OptionButton.new()
	column.add_child(_selector)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	for action in ["observe", "downlink", "power_save"]:
		var button := Button.new()
		button.text = "SYNTHETIC " + action
		button.pressed.connect(func(): operations.request_action(StringName(action)))
		actions.add_child(button)
	_status = Label.new()
	column.add_child(_status)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	operations = preload("res://ke3/operations_control.tscn").instantiate()
	results = preload("res://ke3/results_control.tscn").instantiate()
	tabs.add_child(operations)
	tabs.add_child(results)
	session.bind_views(operations, results)
	provider = preload("res://preview/fixture_provider.gd").new(self)
	session.bind_provider(provider)
	operations.action_requested.connect(_on_action_requested)
	_case_ids = provider.catalog().keys()
	for case_id in _case_ids:
		_selector.add_item("SYNTHETIC / " + case_id)
	_selector.item_selected.connect(func(index: int): select_fixture(_case_ids[index]))
	select_fixture("ready_step_2")


func select_fixture(case_id: String) -> Dictionary:
	if not provider.choose_case(case_id):
		return {"accepted": false, "error": "unknown_fixture"}
	var case_data: Dictionary = provider.catalog()[case_id]
	var reply: Dictionary = session.open_run(case_data.payload.context.run_id)
	_selector.select(_case_ids.find(case_id))
	_status.text = "SYNTHETIC / " + case_id + " / " + str(reply)
	return reply


func _on_action_requested(run_id: String, action_id: StringName) -> void:
	var reply: Dictionary = session.request_action(run_id, action_id)
	_status.text = "SYNTHETIC / " + String(action_id) + " / " + str(reply)
