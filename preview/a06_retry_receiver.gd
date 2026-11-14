extends RefCounted
## Explicit preview stand-in for SE's route/draft owner. Never used by KE3 scenes.

var route_requests: int = 0
var _entry_ref: WeakRef
var _completed: Dictionary = {}
var _order: Array[String] = []
var _baseline_id: String = ""
var _origin: Dictionary = {}
var _draft: Dictionary = {}
var _scenario: Dictionary = {}
var _generation: int = 0
var _serial: int = 0
var _pending: Dictionary = {}
var accepted: bool = false
var reason: String = ""


func _init(entry: Node = null) -> void:
	if is_instance_valid(entry):
		_entry_ref = weakref(entry)


func _active() -> bool:
	var entry: Node = _entry_ref.get_ref() if _entry_ref != null else null
	return is_instance_valid(entry) and entry.is_inside_tree() and entry.get_script().resource_path == "res://preview/a06_preview.gd"


func record_completed(payload: Dictionary) -> bool:
	if not _active():
		return false
	var report: Dictionary = payload.get("report", {})
	var run_id: String = report.get("run_id", "")
	if run_id.is_empty() or payload.context.get("run_id") != run_id or payload.state.get("run_id") != run_id or payload.state.get("phase") != "finished":
		return false
	if _completed.has(run_id):
		return _completed[run_id] == payload
	_completed[run_id] = payload.duplicate(true)
	_order.append(run_id)
	if _baseline_id.is_empty() and report.get("run_status") == "completed":
		_baseline_id = run_id
	return true


func begin_redesign(payload: Dictionary) -> Dictionary:
	if not _active():
		return {"accepted": false, "error": "preview_entry_required"}
	if not _pending.is_empty() or not _draft.is_empty():
		return {"accepted": false, "error": "redesign_already_open"}
	if not record_completed(payload):
		return {"accepted": false, "error": "completed_snapshot_required"}
	_generation += 1
	_origin = payload.duplicate(true)
	_draft = payload.context.config.duplicate(true)
	_scenario = payload.context.scenario.duplicate(true)
	return request_route()


func request_route() -> Dictionary:
	if not _active():
		return {"accepted": false, "error": "preview_entry_required"}
	if not _pending.is_empty() or _draft.is_empty():
		return {"accepted": false, "error": "route_pending_or_draft_missing"}
	_serial += 1
	route_requests += 1
	accepted = false
	reason = "SYNTHETIC redesign route pending"
	_pending = {"generation": _generation, "request_id": _serial, "run_id": _origin.context.run_id}
	return {"accepted": true, "token": _pending.duplicate(true)}


func receive_route(token: Dictionary, reply: Dictionary) -> Dictionary:
	if not _active() or _pending.is_empty() or token != _pending:
		return {"accepted": false, "error": "late_route_reply"}
	_pending = {}
	accepted = reply.get("accepted") == true
	reason = str(reply.get("reason", "Unavailable"))
	return {"accepted": accepted, "reason": reason}


func edit_component(field: String, value: String) -> bool:
	if not _active() or _draft.is_empty():
		return false
	var options: Dictionary = _origin.context.component_options
	if not options.has(field) or value not in options[field]:
		return false
	# This preview offers one editable component at a time. Requirements stay fixed.
	_draft.design = _origin.context.config.design.duplicate(true)
	_draft.design[field] = value
	return true


func get_draft() -> Dictionary:
	return _draft.duplicate(true)


func get_scenario() -> Dictionary:
	return _scenario.duplicate(true)


func get_origin() -> Dictionary:
	return _origin.duplicate(true)


func get_completed() -> Dictionary:
	return {"order": _order.duplicate(), "runs": _completed.duplicate(true), "baseline_run_id": _baseline_id}


func is_pending() -> bool:
	return not _pending.is_empty()


func close_draft() -> Dictionary:
	if not _active():
		return {}
	var origin := _origin.duplicate(true)
	_generation += 1
	_pending = {}
	_origin = {}
	_draft = {}
	_scenario = {}
	accepted = false
	reason = ""
	return origin
