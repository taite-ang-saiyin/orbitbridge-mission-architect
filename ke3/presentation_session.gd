extends RefCounted
## Provisional provider seam. No fixture selection, simulation or evaluation.

var last_error: String = ""
var _provider: Object
var _operations: Control
var _results: Control
var _active_run_id: String = ""
var _generation: int = 0
var _request_serial: int = 0
var _pending_request: Dictionary = {}
var _screen_active: bool = true
var _current_payload: Dictionary = {}


func bind_views(operations: Control, results: Control) -> void:
	_set_view_active(false)
	_invalidate_pending()
	_operations = operations
	_results = results
	_clear_views()
	if _screen_active and not _current_payload.is_empty():
		_present(_current_payload)
	_set_view_active(_screen_active)


func bind_provider(provider: Object) -> void:
	_invalidate_pending()
	_provider = provider
	_active_run_id = ""
	_current_payload = {}
	last_error = ""
	_clear_views()


func open_run(run_id: String) -> Dictionary:
	_invalidate_pending()
	_screen_active = true
	_set_view_active(true)
	_active_run_id = run_id
	if run_id.is_empty() or not is_instance_valid(_provider) or not _provider.has_method("open_run"):
		return _reject("provider_unavailable")
	return _receive_reply(_provider.call("open_run", run_id))


func request_action(run_id: String, action_id: StringName) -> Dictionary:
	if not _screen_active:
		return {"accepted": false, "error": "screen_inactive"}
	if not _pending_request.is_empty():
		return {"accepted": false, "error": "request_pending"}
	if run_id != _active_run_id or run_id.is_empty():
		return _reject("stale_run_id")
	if not is_instance_valid(_provider):
		return _reject("provider_unavailable")
	if not _provider.has_method("request_action") and not _provider.has_method("request_action_deferred"):
		return _reject("provider_unavailable")
	_request_serial += 1
	_pending_request = {"generation": _generation, "request_id": _request_serial, "run_id": run_id}
	var token := _pending_request.duplicate(true)
	_set_view_pending(true)
	if _provider.has_method("request_action_deferred"):
		_provider.call("request_action_deferred", run_id, action_id, token, receive_action_reply)
		return {"accepted": true, "pending": true, "error": ""}
	return receive_action_reply(token, _provider.call("request_action", run_id, action_id))


func receive_action_reply(token: Dictionary, reply: Variant) -> Dictionary:
	# Ignore old delivery without clearing a newer pending request or new view.
	if not _screen_active or _pending_request.is_empty() or token != _pending_request:
		return {"accepted": false, "error": "late_reply"}
	_pending_request = {}
	_set_view_pending(false)
	return _receive_reply(reply)


func leave_screen() -> void:
	if _screen_active:
		_screen_active = false
		_invalidate_pending()
	_set_view_active(false)


func enter_screen() -> void:
	_invalidate_pending()
	_screen_active = true
	_set_view_active(true)
	if not _active_run_id.is_empty():
		if is_instance_valid(_provider) and _provider.has_method("open_run"):
			_receive_reply(_provider.call("open_run", _active_run_id))
		else:
			_reject("provider_unavailable")


func invalidate_for_retry(run_id: String) -> Dictionary:
	if run_id.is_empty() or run_id != _active_run_id:
		return {"accepted": false, "error": "stale_run_id"}
	leave_screen()
	# Presentation cancellation only. SE/provider owns the new run and draft.
	_active_run_id = ""
	_current_payload = {}
	_clear_views()
	return {"accepted": true, "error": ""}


func is_pending() -> bool:
	return not _pending_request.is_empty()


func _invalidate_pending() -> void:
	_generation += 1
	_pending_request = {}
	_set_view_pending(false)


func _set_view_pending(value: bool) -> void:
	if is_instance_valid(_operations) and _operations.has_method("set_interaction_pending"):
		_operations.set_interaction_pending(value)


func _set_view_active(value: bool) -> void:
	if is_instance_valid(_operations) and _operations.has_method("set_screen_active"):
		_operations.set_screen_active(value)


func _receive_reply(reply: Variant) -> Dictionary:
	if not reply is Dictionary or reply.get("ok") != true:
		var reason := "provider_unavailable"
		if reply is Dictionary:
			reason = str(reply.get("error", reason))
		return _reject(reason)
	if not reply.get("payload") is Dictionary:
		return _reject("missing_payload")
	return accept_payload(reply.payload)


func accept_payload(payload: Dictionary) -> Dictionary:
	# Display correlation/reference checks only; producer semantics stay upstream.
	if not _screen_active:
		return {"accepted": false, "error": "late_reply"}
	for field in ["context", "state", "report"]:
		if not payload.get(field) is Dictionary:
			return _reject("missing_" + field)
	var context: Dictionary = payload.context
	var state: Dictionary = payload.state
	var report: Dictionary = payload.report
	if _active_run_id.is_empty() or context.get("run_id") != _active_run_id or state.get("run_id") != _active_run_id:
		return _reject("stale_run_id")
	if not report.is_empty() and report.get("run_id") != _active_run_id:
		return _reject("stale_run_id")
	var events: Variant = state.get("events", [])
	if not events is Array:
		return _reject("invalid_event_envelope")
	var event_ids: Dictionary = {}
	for event in events:
		if not event is Dictionary or event.get("run_id") != _active_run_id:
			return _reject("stale_event_run_id")
		var event_id: Variant = event.get("event_id")
		if not event_id is String or event_id.is_empty() or event_ids.has(event_id):
			return _reject("invalid_event_id")
		event_ids[event_id] = true
	# Missing report evidence is an availability condition, not a stale report.
	# Keep current-run reports intact; the Debrief resolves links in this history.
	last_error = ""
	_current_payload = payload.duplicate(true)
	_present(_current_payload)
	return {"accepted": true, "error": ""}


func _present(payload: Dictionary) -> void:
	if is_instance_valid(_operations):
		_operations.set_inputs(payload.context, payload.state, payload.report)
	if is_instance_valid(_results):
		_results.set_inputs(payload.context, payload.state, payload.report)


func _reject(reason: String) -> Dictionary:
	_invalidate_pending()
	last_error = reason
	_current_payload = {}
	_clear_views()
	for view in [_operations, _results]:
		if is_instance_valid(view):
			view.set_boundary_error(reason)
	return {"accepted": false, "error": reason}


func _clear_views() -> void:
	for view in [_operations, _results]:
		if is_instance_valid(view):
			view.set_inputs({}, {}, {})
