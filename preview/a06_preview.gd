extends "res://preview/a05_preview.gd"
## All route, draft and run-creation stand-ins stay in this explicit entry.

var receiver: RefCounted
var draft_screen: Control
var manual_delivery: bool = false
var route_deliveries: Array = []
var route_reply_selector: OptionButton
var finish_button: Button
var back_button: Button


func _ready() -> void:
	super._ready()
	_selector.hide()
	_tabs.tabs_visible = false
	receiver = preload("res://preview/a06_retry_receiver.gd").new(self)
	draft_screen = preload("res://preview/a06_draft_screen.gd").new()
	draft_screen.name = "SyntheticRedesignDraft"
	_tabs.add_child(draft_screen)
	draft_screen.component_changed.connect(_edit_component)
	draft_screen.route_requested.connect(_request_redesign_route)
	draft_screen.start_requested.connect(_start_second)
	draft_screen.cancel_requested.connect(_cancel_redesign)
	var toolbar := HBoxContainer.new()
	var column: VBoxContainer = get_child(0)
	column.add_child(toolbar)
	column.move_child(toolbar, 3)
	var caption := Label.new()
	caption.text = "SYNTHETIC route reply: "
	toolbar.add_child(caption)
	route_reply_selector = OptionButton.new()
	route_reply_selector.add_item("Accepted")
	route_reply_selector.add_item("Rejected (supplied reason)")
	toolbar.add_child(route_reply_selector)
	finish_button = Button.new()
	finish_button.text = "Deliver B terminal snapshot (fixture)"
	finish_button.pressed.connect(_finish_second)
	toolbar.add_child(finish_button)
	back_button = Button.new()
	back_button.text = "Back to Operations"
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(_back_to_operations)
	results._retry_button.get_parent().add_child(back_button)
	back_button.add_theme_stylebox_override("focus", results._retry_button.get_theme_stylebox("focus").duplicate())
	results._credits_button.focus_next = results._credits_button.get_path_to(back_button)
	back_button.focus_previous = back_button.get_path_to(results._credits_button)
	back_button.focus_next = back_button.get_path_to(results._retry_button)
	results._retry_button.focus_previous = results._retry_button.get_path_to(back_button)
	_show_completed("a06_a_complete")
	receiver.record_completed(results.get_input_snapshot())


func _make_provider() -> RefCounted:
	return preload("res://preview/a06_provider.gd").new(self)


func _entry_banner() -> String:
	return "SYNTHETIC A06 RETRY | LOCAL DRAFT / ROUTE STAND-IN | NO PRODUCTION WIRING"


func _case_prefix() -> String:
	return "SYNTHETIC A06 / "


func _show_completed(case_id: String) -> void:
	provider.choose_case(case_id)
	_tabs.current_tab = 1
	var payload: Dictionary = provider.catalog()[case_id].payload
	session.open_run(payload.context.run_id)
	session.leave_screen()
	results.set_retry_pending(false)
	finish_button.hide()
	_status.text = "SYNTHETIC completed Debrief: " + payload.context.run_id
	results._retry_button.grab_focus()


func _on_retry_requested(run_id: String) -> void:
	if not is_instance_valid(receiver) or receiver.is_pending() or not receiver.get_draft().is_empty():
		return
	var payload: Dictionary = results.get_input_snapshot()
	if payload.context.get("run_id") != run_id:
		results.set_retry_pending(false)
		return
	retry_intents += 1
	var reply: Dictionary = receiver.begin_redesign(payload)
	if not reply.accepted:
		results.set_retry_pending(false)
		_status.text = str(reply)
		return
	session.leave_screen()
	_tabs.current_tab = 3
	_queue_route(reply.token)
	_refresh_draft()
	draft_screen.component_selector.grab_focus()


func _request_redesign_route() -> void:
	var reply: Dictionary = receiver.request_route()
	if reply.accepted:
		_queue_route(reply.token)
	_refresh_draft()


func _queue_route(token: Dictionary) -> void:
	var accepted := route_reply_selector.selected == 0
	var reply := {"accepted": accepted, "reason": "SYNTHETIC redesign route accepted; editable draft retained." if accepted else "SYNTHETIC redesign route rejected: Builder temporarily unavailable; draft retained."}
	route_deliveries.append({"token": token.duplicate(true), "reply": reply})
	if not manual_delivery:
		_auto_route(route_deliveries.size() - 1)


func _auto_route(index: int) -> void:
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		deliver_route(index)


func deliver_route(index: int) -> Dictionary:
	var delivery: Dictionary = route_deliveries[index]
	var reply: Dictionary = receiver.receive_route(delivery.token, delivery.reply)
	if reply.get("error") == "late_route_reply":
		return reply
	results.set_retry_pending(false)
	_refresh_draft()
	return reply


func _edit_component(field: String, value: String) -> void:
	receiver.edit_component(field, value)
	_refresh_draft()


func _refresh_draft() -> void:
	if not receiver.get_draft().is_empty():
		draft_screen.set_draft(receiver.get_origin(), receiver.get_draft(), receiver.get_scenario(), receiver.is_pending(), receiver.accepted, receiver.reason)
	_status.text = "SYNTHETIC redesign: " + receiver.reason


func _cancel_redesign() -> void:
	var origin: Dictionary = receiver.close_draft()
	if origin.is_empty():
		return
	_show_completed("a06_a_complete" if origin.context.run_id == provider.RUN_A else "a06_b_complete")


func _start_second() -> void:
	if receiver.is_pending() or not receiver.accepted:
		return
	var reply: Dictionary = provider.start_second(receiver.get_draft(), receiver.get_scenario())
	if reply.get("ok") != true:
		receiver.reason = str(reply.get("error", "Unavailable"))
		_refresh_draft()
		return
	var origin: Dictionary = receiver.close_draft()
	session.invalidate_for_retry(origin.context.run_id)
	_tabs.current_tab = 0
	session.open_run(reply.run_id)
	finish_button.show()
	_status.text = "SYNTHETIC B initial snapshot; original completed run remains immutable."


func _on_action_requested(run_id: String, action_id: StringName) -> void:
	super._on_action_requested(run_id, action_id)
	if session.is_pending() and not manual_delivery:
		_auto_action(provider.deliveries.size() - 1)


func _auto_action(index: int) -> void:
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		provider.deliver(index)


func _finish_second() -> void:
	if session.is_pending():
		_status.text = "SYNTHETIC pending action: terminal delivery held."
		return
	var reply: Dictionary = provider.finish_second()
	if reply.get("ok") == true:
		var accepted: Dictionary = session.accept_payload(reply.payload)
		if accepted.accepted:
			receiver.record_completed(reply.payload)
			_status.text = "SYNTHETIC B finished. Use Request Results route."


func _on_route_requested(run_id: String) -> void:
	receiver.record_completed(results.get_input_snapshot())
	super._on_route_requested(run_id)
	_status.text = "SYNTHETIC Results: " + run_id + " | supplied report; completed snapshots retained"
	finish_button.hide()
	results._retry_button.grab_focus()


func _back_to_operations() -> void:
	_tabs.current_tab = 0
	finish_button.visible = operations.get_input_snapshot().context.get("run_id") == provider.RUN_B
