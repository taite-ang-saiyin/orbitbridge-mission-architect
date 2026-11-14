extends "res://preview/a05_provider.gd"
## Literal two-run lifecycle fixtures; no simulation, evaluation or readiness.

const RUN_A := "SYNTHETIC-A06-RUN-A-001"
const RUN_B := "SYNTHETIC-A06-RUN-B-001"
const SCENARIO := {"scenario_id": "SYNTHETIC-A06-SCENARIO-001", "version": "fixture-v1", "step_duration_hours": 0.25, "steps_per_orbit": 8, "total_steps": 8}
const OPTIONS := {"radio_id": ["SYNTHETIC-RADIO-001", "SYNTHETIC-RADIO-002"], "battery_id": ["SYNTHETIC-BATTERY-001", "SYNTHETIC-BATTERY-002"]}
var _lifecycle_cases: Dictionary = {}
var deliveries: Array = []
var start_calls: int = 0
var _started: bool = false


func _init(entry: Node = null) -> void:
	super(entry)
	if not _preview_active():
		return
	var source := super.catalog()
	var a := _rename_run(source.debrief_partial, RUN_A)
	var config: Dictionary = a.payload.context.config
	config.schema_version = 1
	config.mission.merge({"objective": "imaging", "duration_orbits": 1, "budget_credits": 1200}, true)
	var parts: Dictionary = a.payload.context.config_selections.selected_part_ids
	for field in parts:
		config.design[field + "_id"] = parts[field]
	config.design.orbit_id = a.payload.context.config_selections.selected_orbit_id
	a.payload.context.scenario = SCENARIO.duplicate(true)
	a.payload.state.scenario_id = SCENARIO.scenario_id
	a.payload.context.component_options = OPTIONS.duplicate(true)
	_lifecycle_cases.a06_a_complete = a
	for definition in [["a06_a_initial", "ready_step_2"], ["a06_a_observed", "observe_allowed"]]:
		var old := _rename_run(source[definition[1]], RUN_A)
		old.payload.context = a.payload.context.duplicate(true)
		_lifecycle_cases[definition[0]] = old
	# B carries supplied values and a separate event namespace from its first frame.
	var b := _rename_run(source.debrief_success, RUN_B)
	b.payload.context = a.payload.context.duplicate(true)
	b.payload.context.run_id = RUN_B
	b.payload.report.explanation = "SYNTHETIC second run: supplied goals were met. No component causality or controlled comparison is claimed."
	b.payload.report.next_experiment = "SYNTHETIC: inspect another design choice; request a KE2 comparison before attributing a difference."
	var launch := _event_b("LAUNCH-000", 0, "launch", "RUN_STARTED", "SYNTHETIC B launch")
	var observe := _event_b("OBSERVE-001", 1, "observation", "OBSERVATION_COMPLETE", "SYNTHETIC B Observe accepted")
	var transmit := _event_b("TRANSMIT-006", 6, "downlink", "DATA_RETURNED", "SYNTHETIC B supplied downlink event")
	var terminal := _event_b("FINISHED-008", 8, "run_finished", "RUN_FINISHED", "SYNTHETIC B run finished")
	b.payload.state.merge({"step": 8, "step_index": 8, "total_steps": 8, "phase": "finished", "lifecycle": "terminal", "energy_wh": 4, "stored_mb": 0, "generated_mb": 4, "returned_mb": 4, "returned_data_mb": 4, "observations_completed": 3, "observations_requested": 3, "target_access": false, "contact_on": false, "events": [launch, observe, transmit, terminal], "scenario_id": SCENARIO.scenario_id}, true)
	_lifecycle_cases.a06_b_complete = b
	var initial := b.duplicate(true)
	initial.payload.report = {}
	initial.payload.state.merge({"step": 0, "step_index": 0, "phase": "operating", "lifecycle": "ready", "run_status": null, "energy_wh": 8, "stored_mb": 0, "generated_mb": 0, "returned_mb": 0, "returned_data_mb": 0, "observations_completed": 0, "target_access": true, "events": [launch], "action_availability": {"observe": {"enabled": true}, "downlink": {"enabled": false, "reason": "No contact"}, "power_save": {"enabled": false, "reason": "No scripted reply"}}, "results_route": {"enabled": false, "reason": "Awaiting supplied terminal snapshot"}}, true)
	_lifecycle_cases.a06_b_initial = initial
	var observed := initial.duplicate(true)
	observed.payload.state.merge({"step": 1, "step_index": 1, "energy_wh": 7, "stored_mb": 1, "generated_mb": 1, "observations_completed": 1, "events": [launch, observe], "action_availability": {"observe": {"enabled": false, "reason": "No further scripted reply"}, "downlink": {"enabled": false, "reason": "No contact"}, "power_save": {"enabled": false, "reason": "No scripted reply"}}}, true)
	_lifecycle_cases.a06_b_observed = observed


func _event_b(suffix: String, step: int, kind: String, code: String, message: String) -> Dictionary:
	return {"run_id": RUN_B, "event_id": RUN_B + "-EVENT-" + suffix, "step_index": step, "step": step, "type": kind, "code": code, "message": message, "label": message}


func _rename_run(source: Dictionary, run_id: String) -> Dictionary:
	var reply := source.duplicate(true)
	var previous: String = reply.payload.context.run_id
	reply.payload.context.run_id = run_id
	reply.payload.state.run_id = run_id
	for event in reply.payload.state.events:
		event.run_id = run_id
		event.event_id = String(event.event_id).replace(previous, run_id)
	if not reply.payload.report.is_empty():
		reply.payload.report.run_id = run_id
		for cause in reply.payload.report.get("root_causes", []):
			for i in range(cause.evidence_event_ids.size()):
				cause.evidence_event_ids[i] = String(cause.evidence_event_ids[i]).replace(previous, run_id)
	return reply


func catalog() -> Dictionary:
	var cases := super.catalog()
	if _preview_active():
		cases.merge(_lifecycle_cases.duplicate(true))
	return cases


func choose_case(case_id: String) -> bool:
	if _preview_active() and _lifecycle_cases.has(case_id):
		_selected = case_id
		return true
	return super.choose_case(case_id)


func open_run(run_id: String) -> Dictionary:
	if not _preview_active():
		return {"ok": false, "error": "preview_entry_required"}
	if not _lifecycle_cases.has(_selected):
		return super.open_run(run_id)
	open_calls += 1
	if _lifecycle_cases[_selected].payload.context.run_id != run_id:
		return {"ok": false, "error": "stale_run_id"}
	return _lifecycle_cases[_selected].duplicate(true)


func start_second(config: Dictionary, scenario: Dictionary) -> Dictionary:
	if not _preview_active():
		return {"ok": false, "error": "preview_entry_required"}
	start_calls += 1
	if _started:
		return {"ok": false, "error": "SYNTHETIC two-run fixture exhausted; no third run supplied"}
	var original: Dictionary = _lifecycle_cases.a06_a_complete.payload.context.config
	if config.mission != original.mission or scenario != SCENARIO or config.design.orbit_id != original.design.orbit_id:
		return {"ok": false, "error": "SYNTHETIC fixture requires unchanged mission/scenario/orbit"}
	# Identity/config projection only. Telemetry remains the literal reply above.
	for case_id in ["a06_b_initial", "a06_b_observed", "a06_b_complete"]:
		var context: Dictionary = _lifecycle_cases[case_id].payload.context
		context.config = config.duplicate(true)
		context.scenario = scenario.duplicate(true)
		for field in context.config_selections.selected_part_ids:
			context.config_selections.selected_part_ids[field] = config.design[field + "_id"]
	_started = true
	_selected = "a06_b_initial"
	return {"ok": true, "run_id": RUN_B}


func request_action_deferred(run_id: String, action: StringName, token: Dictionary, callback: Callable) -> void:
	action_calls += 1
	var next: String = {"a06_a_initial": "a06_a_observed", "a06_b_initial": "a06_b_observed"}.get(_selected, "") if action == &"observe" else ""
	var reply := {"ok": false, "error": "scripted_action_unavailable"}
	if _preview_active() and not next.is_empty() and _lifecycle_cases[_selected].payload.context.run_id == run_id:
		reply = _lifecycle_cases[next].duplicate(true)
	deliveries.append({"token": token.duplicate(true), "reply": reply, "callback": callback, "next": next})


func deliver(index: int) -> Dictionary:
	if not _preview_active():
		return {"accepted": false, "error": "preview_entry_required"}
	var delivery: Dictionary = deliveries[index]
	var result: Dictionary = delivery.callback.call(delivery.token.duplicate(true), delivery.reply.duplicate(true))
	if result.get("accepted") == true:
		_selected = delivery.next
	return result


func finish_second() -> Dictionary:
	if not _preview_active() or not _started or not _selected.begins_with("a06_b_"):
		return {"ok": false, "error": "SYNTHETIC second run not active"}
	_selected = "a06_b_complete"
	return _lifecycle_cases[_selected].duplicate(true)
