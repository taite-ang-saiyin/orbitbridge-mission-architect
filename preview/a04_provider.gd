extends "res://preview/a03_provider.gd"
## A02/A03 replies plus two authored snapshots for a distinct fresh run.

const FRESH_RUN := "SYNTHETIC-KE3-RUN-OPS-002"
var _extra_cases: Dictionary = {}


func _init(entry: Node = null) -> void:
	super(entry)
	if not _preview_active():
		return
	var original := super.catalog()
	var empty: Dictionary = original.ready_step_2.duplicate(true)
	empty.payload.context.run_id = FRESH_RUN
	empty.payload.state.run_id = FRESH_RUN
	empty.payload.state.events = []
	for action_id in empty.payload.state.action_availability:
		empty.payload.state.action_availability[action_id] = _capability(false, "Fresh-run snapshot; no scripted action replies")
	_extra_cases.fresh_run_empty = empty
	var showcase: Dictionary = original.downlink_contact_on.duplicate(true)
	showcase.payload.context.run_id = FRESH_RUN
	showcase.payload.state.run_id = FRESH_RUN
	showcase.payload.state.events = [
		_fresh_event("LAUNCH-000", 0, "SYNTHETIC Launch", "launch"),
		_fresh_event("ORBIT-001", 1, "SYNTHETIC Orbit insertion", "orbit"),
		_fresh_event("OBSERVE-003", 3, "SYNTHETIC Observe allowed", "observe"),
		_fresh_event("BLOCKED-003", 3, "SYNTHETIC Downlink blocked: no contact; no step advance", "blocked"),
		_fresh_event("SAVE-004", 4, "SYNTHETIC Power-save (Save) allowed", "save"),
		_fresh_event("CONTACT-004", 4, "SYNTHETIC contact on", "contact"),
		_fresh_event("DOWNLINK-005", 5, "SYNTHETIC Downlink allowed", "downlink"),
	]
	_extra_cases.fresh_run_showcase = showcase


func _fresh_event(suffix: String, step: int, label: String, kind: String) -> Dictionary:
	return {"run_id": FRESH_RUN, "event_id": FRESH_RUN + "-EVENT-" + suffix, "step": step, "label": label, "kind": kind}


func catalog() -> Dictionary:
	var cases := super.catalog()
	if _preview_active():
		cases.merge(_extra_cases.duplicate(true))
	return cases


func choose_case(case_id: String) -> bool:
	if _preview_active() and _extra_cases.has(case_id):
		_selected = case_id
		return true
	return super.choose_case(case_id)


func open_run(run_id: String) -> Dictionary:
	if not _extra_cases.has(_selected):
		return super.open_run(run_id)
	open_calls += 1
	if not _preview_active():
		return {"ok": false, "error": "preview_entry_required"}
	if run_id != FRESH_RUN:
		return {"ok": false, "error": "stale_run_id"}
	return _extra_cases[_selected].duplicate(true)


func request_action(run_id: String, action_id: StringName) -> Dictionary:
	if not _extra_cases.has(_selected):
		return super.request_action(run_id, action_id)
	action_calls += 1
	return {"ok": false, "error": "scripted_action_unavailable" if _preview_active() else "preview_entry_required"}
