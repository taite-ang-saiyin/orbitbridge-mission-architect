extends "res://preview/fixture_provider.gd"
## SYNTHETIC A03 provider adapter. All added values/capabilities are authored here.

const TELEMETRY := {
	"ready_step_2": {"phase": "Operations", "target_access": true, "generated_mb": 2},
	"observe_allowed": {"phase": "Operations", "target_access": true, "generated_mb": 3},
	"contact_on": {"phase": "Operations", "target_access": false, "generated_mb": 3},
	"downlink_contact_on": {"phase": "Operations", "target_access": false, "generated_mb": 3},
	"downlink_no_contact": {"phase": "Operations", "target_access": true, "generated_mb": 3},
	"power_save": {"phase": "Operations", "target_access": false, "generated_mb": 3},
	"terminal": {"phase": "Terminal", "target_access": false, "generated_mb": 3},
	"report_success": {"phase": "Terminal", "target_access": false, "generated_mb": 4},
	"report_partial": {"phase": "Terminal", "target_access": false, "generated_mb": 3},
	"report_failure": {"phase": "Terminal", "target_access": false, "generated_mb": 0},
	"report_missing": {"phase": "Terminal", "target_access": false, "generated_mb": 3},
	"report_stale_run": {"phase": "Terminal", "target_access": false, "generated_mb": 3},
	"report_dangling_event": {"phase": "Terminal", "target_access": false, "generated_mb": 3},
}


func _init(entry: Node = null) -> void:
	super(entry)


func catalog() -> Dictionary:
	var cases := super.catalog()
	for case_id in cases:
		cases[case_id] = _decorate(cases[case_id], case_id)
	return cases


func open_run(run_id: String) -> Dictionary:
	return _decorate(super.open_run(run_id), _selected)


func request_action(run_id: String, action_id: StringName) -> Dictionary:
	# A03 authors a direct Power-save reply after Observe; A02 stays unchanged.
	if _preview_active() and _selected == "observe_allowed" and action_id == &"power_save" and _cases[_selected].payload.context.run_id == run_id:
		action_calls += 1
		_selected = "power_save"
		var reply: Dictionary = _cases.power_save.duplicate(true)
		reply.payload.state.events = [_cases.ready_step_2.payload.state.events[0].duplicate(true), _cases.observe_allowed.payload.state.events[1].duplicate(true), _cases.power_save.payload.state.events[3].duplicate(true)]
		return _decorate(reply, _selected)
	return _decorate(super.request_action(run_id, action_id), _selected)


func _capability(enabled: bool, reason: String = "") -> Dictionary:
	return {"enabled": enabled, "reason": reason}


func _decorate(reply: Dictionary, case_id: String) -> Dictionary:
	if reply.get("ok") != true:
		return reply
	var state: Dictionary = reply.payload.state
	state.merge(TELEMETRY[case_id].duplicate(true), true)
	var actions := {
		"observe": _capability(false, "No further scripted Observe reply"),
		"downlink": _capability(false, "No further scripted Transmit reply"),
		"power_save": _capability(false, "No further scripted Power-save reply"),
	}
	var route := _capability(false, "Provider has not enabled Results routing")
	match case_id:
		"ready_step_2":
			actions.observe = _capability(true)
			actions.downlink = _capability(false, "No contact")
		"observe_allowed", "downlink_no_contact":
			actions.downlink = _capability(false, "No contact")
			actions.power_save = _capability(true)
		"contact_on":
			actions.observe = _capability(false, "Target not accessible")
			actions.downlink = _capability(true)
		"terminal", "report_success", "report_partial", "report_failure", "report_missing", "report_stale_run", "report_dangling_event":
			for action_id in actions:
				actions[action_id] = _capability(false, "Run terminal")
			route = _capability(true)
	state.action_availability = actions
	state.results_route = route
	return reply
