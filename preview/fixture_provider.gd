extends RefCounted
## Only a mounted, explicit preview entry can activate this provider.

var _cases: Dictionary = {}
var _selected: String = "ready_step_2"
var _authorized: bool = false
var _entry_ref: WeakRef
var open_calls: int = 0
var action_calls: int = 0


func _init(preview_entry: Node = null) -> void:
	_authorized = _is_preview_entry(preview_entry)
	if _authorized:
		_entry_ref = weakref(preview_entry)
		_cases = load("res://preview/mission_fixtures.gd").new().all_cases()


func _preview_active() -> bool:
	if not _authorized or _entry_ref == null:
		return false
	var entry: Node = _entry_ref.get_ref()
	return _is_preview_entry(entry)


func _is_preview_entry(entry: Node) -> bool:
	return is_instance_valid(entry) and entry.is_inside_tree() and entry.get_script() != null and entry.get_script().resource_path in ["res://preview/mission_preview.gd", "res://preview/a03_preview.gd", "res://preview/a04_preview.gd", "res://preview/a05_preview.gd", "res://preview/a06_preview.gd"]


func catalog() -> Dictionary:
	return _cases.duplicate(true) if _preview_active() else {}


func choose_case(case_id: String) -> bool:
	if not _preview_active() or not _cases.has(case_id):
		return false
	_selected = case_id
	return true


func open_run(run_id: String) -> Dictionary:
	open_calls += 1
	if not _preview_active():
		return {"ok": false, "error": "preview_entry_required"}
	if _cases[_selected].payload.context.run_id != run_id:
		return {"ok": false, "error": "stale_run_id"}
	return _cases[_selected].duplicate(true)


func request_action(run_id: String, action_id: StringName) -> Dictionary:
	action_calls += 1
	if not _preview_active():
		return {"ok": false, "error": "preview_entry_required"}
	if _cases[_selected].payload.context.run_id != run_id:
		return {"ok": false, "error": "stale_run_id"}
	# Scripted case transitions only. No legality or numerical state calculations.
	var replies := {
		"ready_step_2": {"observe": "observe_allowed"},
		"observe_allowed": {"downlink": "downlink_no_contact"},
		"downlink_no_contact": {"power_save": "power_save"},
		"contact_on": {"downlink": "downlink_contact_on"},
	}
	var next_case: String = replies.get(_selected, {}).get(String(action_id), "")
	if next_case.is_empty():
		return {"ok": false, "error": "scripted_action_unavailable"}
	_selected = next_case
	return _cases[_selected].duplicate(true)
