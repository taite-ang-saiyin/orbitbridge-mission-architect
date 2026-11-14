extends Control
## Explicit SYNTHETIC A03 entry. Demonstration tabs, not SE's production router.

var session = preload("res://ke3/presentation_session.gd").new()
var provider: RefCounted
var operations: Control
var results: Control
var route_intents: int = 0
var retry_intents: int = 0
var action_intents: int = 0
var _case_ids: Array = []
var _selector: OptionButton
var _status: Label
var _tabs: TabContainer


func _ready() -> void:
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(column)
	var banner := Label.new()
	banner.text = _entry_banner()
	banner.add_theme_color_override("font_color", Color(1.0, 0.76, 0.3))
	column.add_child(banner)
	_selector = OptionButton.new()
	column.add_child(_selector)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_tabs)
	operations = preload("res://ke3/operations_screen.tscn").instantiate()
	results = _make_results()
	_tabs.add_child(operations)
	_tabs.add_child(results)
	session.bind_views(operations, results)
	provider = _make_provider()
	session.bind_provider(provider)
	operations.action_requested.connect(_on_action_requested)
	operations.result_route_requested.connect(_on_route_requested)
	operations.screen_exited.connect(session.leave_screen)
	results.retry_requested.connect(_on_retry_requested)
	_tabs.tab_changed.connect(_on_tab_changed)
	_case_ids = provider.catalog().keys()
	for case_id in _case_ids:
		_selector.add_item(_case_prefix() + case_id)
	_selector.item_selected.connect(func(index: int): select_fixture(_case_ids[index]))
	select_fixture("ready_step_2")


func _make_provider() -> RefCounted:
	return preload("res://preview/a03_provider.gd").new(self)


func _make_results() -> Control:
	return preload("res://ke3/results_control.tscn").instantiate()


func _entry_banner() -> String:
	return "SYNTHETIC A03 PREVIEW | NO LIVE PROVIDER | A02 VALUES REUSED"


func _case_prefix() -> String:
	return "SYNTHETIC A03 / "


func select_fixture(case_id: String) -> Dictionary:
	if not provider.choose_case(case_id):
		return {"accepted": false, "error": "unknown_fixture"}
	_tabs.current_tab = 0
	var case_data: Dictionary = provider.catalog()[case_id]
	var reply: Dictionary = session.open_run(case_data.payload.context.run_id)
	_selector.select(_case_ids.find(case_id))
	_status.text = "SYNTHETIC / " + case_id + " / " + str(reply)
	return reply


func _on_action_requested(run_id: String, action_id: StringName) -> void:
	action_intents += 1
	var reply: Dictionary = session.request_action(run_id, action_id)
	_status.text = "SYNTHETIC / " + String(action_id) + " / " + str(reply)


func _on_route_requested(_run_id: String) -> void:
	route_intents += 1
	session.leave_screen()
	_tabs.current_tab = 1
	_status.text = "SYNTHETIC Results route intent; no provider step advanced"


func _on_retry_requested(run_id: String) -> void:
	retry_intents += 1
	var reply: Dictionary = session.invalidate_for_retry(run_id)
	_status.text = "SYNTHETIC Retry intent; awaiting SE/provider new run / " + str(reply)


func _on_tab_changed(index: int) -> void:
	if index == 0:
		session.enter_screen()
	else:
		session.leave_screen()
