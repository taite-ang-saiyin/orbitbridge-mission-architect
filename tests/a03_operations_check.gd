extends SceneTree
var output_dir: String = "res://verification"
## SYNTHETIC A03 evidence. No human, live, browser or publication claim.

const READY := {"step": "2", "phase": "Operations", "target_access": "On", "contact": "Off", "energy": "8 Wh", "generated": "2 MB", "stored": "2 MB", "returned": "0 MB", "observations": "0/3"}
const OBSERVE := {"step": "3", "phase": "Operations", "target_access": "On", "contact": "Off", "energy": "7 Wh", "generated": "3 MB", "stored": "3 MB", "returned": "0 MB", "observations": "1/3"}
const TRANSMIT := {"step": "5", "phase": "Operations", "target_access": "Off", "contact": "On", "energy": "6 Wh", "generated": "3 MB", "stored": "1 MB", "returned": "2 MB", "observations": "1/3"}
const POWER_SAVE := {"step": "4", "phase": "Operations", "target_access": "Off", "contact": "Off", "energy": "8 Wh", "generated": "3 MB", "stored": "3 MB", "returned": "0 MB", "observations": "1/3"}
const TERMINAL := {"step": "8", "phase": "Terminal", "target_access": "Off", "contact": "Off", "energy": "5 Wh", "generated": "3 MB", "stored": "1 MB", "returned": "2 MB", "observations": "1/3"}
var _checks: int = 0
var _failures: Array[String] = []
var _evidence: Array = []
var _safety_evidence: Array = []
var entry: Control


class HeldProvider:
	extends RefCounted
	var source: RefCounted
	var deliveries: Array[Dictionary] = []
	var request_calls: int = 0
	var fail: bool = false
	var fail_open: bool = false


	func _init(provider: RefCounted) -> void:
		source = provider


	func open_run(run_id: String) -> Dictionary:
		if fail_open:
			return {"ok": false, "error": "SYNTHETIC_REENTRY_ERROR"}
		return source.open_run(run_id)


	func request_action_deferred(run_id: String, action_id: StringName, token: Dictionary, callback: Callable) -> void:
		request_calls += 1
		var reply: Dictionary = {"ok": false, "error": "SYNTHETIC_PROVIDER_ERROR"} if fail else source.request_action(run_id, action_id)
		deliveries.append({"token": token.duplicate(true), "reply": reply.duplicate(true), "callback": callback})


	func fulfill(index: int) -> Dictionary:
		var delivery := deliveries[index]
		return delivery.callback.call(delivery.token.duplicate(true), delivery.reply.duplicate(true))


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	for index in range(arguments.size()):
		if arguments[index] == "--output-dir" and index + 1 < arguments.size():
			output_dir = arguments[index + 1]
	DirAccess.make_dir_recursive_absolute(output_dir)
	_run.call_deferred()


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
		push_error(description)


func _metrics() -> Dictionary:
	return entry.operations.get_display_metrics()


func _press(action_id: String) -> void:
	entry.operations.find_child("Action_" + action_id, true, false).pressed.emit()


func _literal_metrics(expected: Dictionary, label: String) -> void:
	_expect(_metrics() == expected, label + ": exact literal display values")
	for value in expected.values():
		_expect(entry.operations._metric_label.text.contains(str(value)), label + ": metric text includes " + str(value))


func _record(label: String, expected: Dictionary, before: Dictionary, expected_counts: Dictionary) -> void:
	var actual_counts := {"actions": entry.action_intents - before.actions, "routes": entry.route_intents - before.routes, "provider_actions": entry.provider.action_calls - before.provider_actions}
	_literal_metrics(expected, label)
	_expect(actual_counts == expected_counts, label + ": exact intent and provider-dispatch counts")
	_evidence.append({"case": label, "expected_metrics": expected.duplicate(true), "actual_metrics": _metrics(), "expected_counts": expected_counts, "actual_counts": actual_counts, "status": "FIXTURE PASS" if _metrics() == expected and actual_counts == expected_counts else "FAIL"})
	print("SYNTHETIC A03 METRICS ", label, " expected=", expected, " actual=", _metrics(), " counts=", actual_counts)


func _counts() -> Dictionary:
	return {"actions": entry.action_intents, "routes": entry.route_intents, "provider_actions": entry.provider.action_calls}


func _late(provider: HeldProvider, index: int, label: String, expected_pending: bool) -> void:
	var metrics_before := _metrics()
	var counts_before := _counts()
	var reply := provider.fulfill(index)
	_expect(reply == {"accepted": false, "error": "late_reply"}, label + ": exact late-reply diagnostic")
	_expect(entry.session.is_pending() == expected_pending, label + ": newer pending state preserved")
	_expect(_metrics() == metrics_before and _counts() == counts_before, label + ": no telemetry or intent mutation")
	_safety_evidence.append({"case": label, "expected_reply": {"accepted": false, "error": "late_reply"}, "actual_reply": reply, "expected_pending": expected_pending, "actual_pending": entry.session.is_pending(), "expected_metrics": metrics_before, "actual_metrics": _metrics(), "expected_counts": counts_before, "actual_counts": _counts()})


func _held(case_id: String = "ready_step_2") -> HeldProvider:
	var provider := HeldProvider.new(entry.provider)
	entry.session.bind_provider(provider)
	entry.select_fixture(case_id)
	return provider


func _run() -> void:
	entry = load("res://preview/a03_preview.tscn").instantiate()
	root.add_child(entry)
	await process_frame
	var source_before: Dictionary = entry.provider.catalog()
	_literal_metrics(READY, "Initial ready snapshot")
	var before := _counts()
	_press("observe")
	_record("Observe", OBSERVE, before, {"actions": 1, "routes": 0, "provider_actions": 1})
	before = _counts()
	_press("power_save")
	_record("Power-save", POWER_SAVE, before, {"actions": 1, "routes": 0, "provider_actions": 1})
	entry.select_fixture("contact_on")
	before = _counts()
	_press("downlink")
	_record("Contact-on Transmit", TRANSMIT, before, {"actions": 1, "routes": 0, "provider_actions": 1})
	entry.select_fixture("observe_allowed")
	before = _counts()
	_expect(entry.operations.find_child("Action_downlink", true, false).disabled, "No-contact Transmit disabled by provider capability")
	_expect(entry.operations._reason_labels.downlink.text.contains("No contact"), "Blocked no-contact reason visible beside disabled button")
	_press("downlink") # Even artificial pressed emission cannot bypass the guard.
	_press("downlink")
	_record("Blocked no-contact Transmit", OBSERVE, before, {"actions": 0, "routes": 0, "provider_actions": 0})
	# The provider can still return the A02 blocked reply; presentation never simulates it.
	var blocked_reply: Dictionary = entry.provider.request_action(entry.operations.get_input_snapshot().context.run_id, &"downlink")
	_expect(blocked_reply.reply_status == "blocked_no_contact" and blocked_reply.payload.state.step == 3 and blocked_reply.payload.state.energy_wh == 7, "Provider's scripted blocked reply remains authoritative")
	_expect(entry.session.accept_payload(blocked_reply.payload).accepted, "Blocked provider payload uses the shared acceptance/rendering path")
	_literal_metrics(OBSERVE, "Provider blocked reply unchanged metrics")
	# One terminal route intent; never automatic routing from render.
	entry.select_fixture("terminal")
	before = _counts()
	entry.operations.set_inputs(entry.operations.get_input_snapshot().context, entry.operations.get_input_snapshot().state, {})
	_expect(entry.route_intents == before.routes, "Rendering terminal state emits no automatic route")
	entry.operations.find_child("ResultsRoute", true, false).pressed.emit()
	entry.operations.find_child("ResultsRoute", true, false).pressed.emit()
	_record("Terminal route request", TERMINAL, before, {"actions": 0, "routes": 1, "provider_actions": 0})
	_expect(entry._tabs.current_tab == 1, "Preview route intent reaches demonstration Results tab")
	# Measured zeros and missing fields have independent, explicit expectations.
	entry.select_fixture("ready_step_2")
	var payload: Dictionary = entry.operations.get_input_snapshot()
	for key in ["step", "energy_wh", "generated_mb", "stored_mb", "returned_mb", "observations_completed"]:
		payload.state[key] = 0
	payload.state.target_access = false
	payload.state.erase("phase")
	_expect(entry.session.accept_payload(payload).accepted, "Zero telemetry snapshot accepted")
	_literal_metrics({"step": "0", "phase": "Unavailable", "target_access": "Off", "contact": "Off", "energy": "0 Wh", "generated": "0 MB", "stored": "0 MB", "returned": "0 MB", "observations": "0/3"}, "Zero is measured; absent phase is Unavailable")
	_expect(entry.operations.get_action_control_state(&"observe").enabled, "Zero energy does not invent local action legality")
	for key in ["step", "phase", "target_access", "contact_on", "energy_wh", "generated_mb", "stored_mb", "returned_mb", "observations_completed", "observations_requested"]:
		payload.state.erase(key)
	payload.state.energy_wh = null
	_expect(entry.session.accept_payload(payload).accepted, "Partial telemetry snapshot accepted")
	_literal_metrics({"step": "Unavailable", "phase": "Unavailable", "target_access": "Unavailable", "contact": "Unavailable", "energy": "Unavailable", "generated": "Unavailable", "stored": "Unavailable", "returned": "Unavailable", "observations": "Unavailable/Unavailable"}, "Missing/null telemetry")
	# Pending is observable before the callback; duplicate UI and session calls are suppressed.
	var held := _held()
	before = _counts()
	_press("observe")
	_press("observe")
	var duplicate: Dictionary = entry.session.request_action(entry.operations.get_input_snapshot().context.run_id, &"observe")
	_expect(duplicate.error == "request_pending" and held.request_calls == 1, "Pending duplicate calls do not dispatch a second request")
	_expect(entry.action_intents - before.actions == 1 and entry.session.is_pending(), "Exactly one accepted-click intent while pending")
	_record("Pending duplicate Observe clicks", READY, before, {"actions": 1, "routes": 0, "provider_actions": 1})
	_literal_metrics(READY, "Pending Observe does not advance local metrics")
	_expect(entry.operations._reason_labels.downlink.text.contains("No contact") and entry.operations._reason_labels.downlink.text.contains("Request pending"), "Provider blocked reason stays visible while pending")
	_expect(held.fulfill(0).accepted and not entry.session.is_pending(), "Matching deferred reply accepted once")
	_literal_metrics(OBSERVE, "Deferred Observe reply")
	_late(held, 0, "Duplicate completed delivery", false)
	_literal_metrics(OBSERVE, "Duplicate delivery leaves display unchanged")
	# Route exit, same-run re-entry and a new pending request cannot admit old replies.
	held = _held()
	_press("observe")
	entry._tabs.current_tab = 1
	_expect(not entry.session.is_pending(), "Route change cancels pending presentation request")
	_late(held, 0, "Reply after route change", false)
	_literal_metrics(READY, "Late route reply did not overwrite last accepted snapshot")
	entry._tabs.current_tab = 0
	_literal_metrics(OBSERVE, "Re-entry obtains fresh provider snapshot without replaying action")
	before = _counts()
	_press("power_save")
	_expect(entry.action_intents - before.actions == 1 and held.request_calls == 2, "Re-entry has one receiver and one new action dispatch")
	_late(held, 0, "Old same-run reply after re-entry with newer request", true)
	_literal_metrics(OBSERVE, "Old reply cannot overwrite re-entered screen")
	_expect(held.fulfill(1).accepted, "New re-entry reply accepted")
	_literal_metrics(POWER_SAVE, "Fresh Power-save reply after re-entry")
	# Replacing the view is another generation boundary; no stale pointers or callbacks.
	held = _held()
	_press("observe")
	var old_view: Control = entry.operations
	var new_view = load("res://ke3/operations_screen.tscn").instantiate()
	new_view.name = "OperationsScreenA03"
	entry._tabs.add_child(new_view)
	entry._tabs.move_child(new_view, 0)
	entry.session.bind_views(new_view, entry.results)
	_expect(not old_view.get_action_control_state(&"observe").enabled, "Retired screen remains inactive after rebinding")
	before = _counts()
	old_view.request_action(&"observe")
	_expect(_counts() == before, "Retired screen cannot emit another accepted-click intent")
	entry.operations = new_view
	new_view.action_requested.connect(entry._on_action_requested)
	new_view.result_route_requested.connect(entry._on_route_requested)
	new_view.screen_exited.connect(entry.session.leave_screen)
	old_view.free()
	new_view.name = "OperationsScreenA03"
	entry.session.enter_screen()
	_late(held, 0, "Reply targeting replaced screen", false)
	_literal_metrics(OBSERVE, "Replacement screen refreshed from provider")
	before = _counts()
	_press("power_save")
	_expect(entry.action_intents - before.actions == 1 and held.request_calls == 2, "Replacement screen dispatches exactly one intent")
	_expect(held.fulfill(1).accepted, "Replacement screen accepts only its new request")
	# Retry invalidates old work even when the provider later reuses the same run ID.
	held = _held()
	_press("observe")
	var run_id: String = entry.operations.get_input_snapshot().context.run_id
	_expect(entry.session.invalidate_for_retry(run_id).accepted, "Retry cancels presentation without resetting provider simulation")
	_late(held, 0, "Reply after Retry", false)
	_expect(_metrics().energy == "Unavailable", "Retry leaves energy Unavailable")
	entry.select_fixture("ready_step_2")
	_press("observe")
	_late(held, 0, "Old Retry-era reply with newer same-ID request", true)
	_expect(held.fulfill(1).accepted, "New post-Retry request accepted")
	_literal_metrics(OBSERVE, "Post-Retry fresh snapshot")
	entry.session.bind_provider(entry.provider)
	entry.select_fixture("report_partial")
	var retry_before: int = entry.retry_intents
	before = _counts()
	entry.results._retry_button.pressed.emit()
	entry.results._retry_button.pressed.emit()
	_expect(entry.retry_intents - retry_before == 1 and entry.provider.action_calls == before.provider_actions, "Retry button emits once and causes no provider step/reset")
	_expect(_metrics().step == "Unavailable", "Retry clears old screen until SE/provider opens a run")
	# Provider failures release pending, show an error and never activate fallback mocks.
	held = _held()
	held.fail = true
	before = _counts()
	_press("observe")
	_expect(entry.action_intents - before.actions == 1 and held.request_calls == 1, "Error path still has one accepted-click intent and one dispatch")
	_expect(not held.fulfill(0).accepted and not entry.session.is_pending(), "Provider error releases pending guard")
	_expect(entry.session.last_error == "SYNTHETIC_PROVIDER_ERROR" and entry.operations._boundary_label.visible and entry.operations._boundary_label.text.contains("SYNTHETIC_PROVIDER_ERROR"), "Provider error visibly reported")
	_expect(_metrics().energy == "Unavailable" and entry.provider.action_calls == before.provider_actions, "Failed provider does not invent metrics or dispatch to fixture fallback")
	held.fail = false
	entry.select_fixture("ready_step_2")
	_press("observe")
	_expect(held.fulfill(1).accepted, "Explicit reopen recovers from provider error")
	_literal_metrics(OBSERVE, "Provider recovery snapshot")
	entry.session.leave_screen()
	held.fail_open = true
	entry.session.enter_screen()
	_expect(entry.session.last_error == "SYNTHETIC_REENTRY_ERROR" and _metrics().step == "Unavailable", "Re-entry provider error clears stale telemetry")
	# Restore the direct provider for inspectable captures; render emits no new intents.
	entry.session.bind_provider(entry.provider)
	entry.select_fixture("ready_step_2")
	_expect(entry.provider.catalog() == source_before, "A03 fixture catalog remained immutable through actions and lifecycle changes")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		_expect(root.get_texture().get_image().save_png(output_dir.path_join("a03-ready.png")) == OK, "A03 ready screenshot saved")
		entry.select_fixture("observe_allowed")
		await process_frame
		await RenderingServer.frame_post_draw
		_expect(root.get_texture().get_image().save_png(output_dir.path_join("a03-blocked.png")) == OK, "A03 blocked screenshot saved")
		entry.select_fixture("terminal")
		await process_frame
		await RenderingServer.frame_post_draw
		_expect(root.get_texture().get_image().save_png(output_dir.path_join("a03-terminal.png")) == OK, "A03 terminal screenshot saved")
	var file := FileAccess.open(output_dir.path_join("a03-metrics.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"synthetic": true, "checks": _checks, "failures": _failures, "operations": _evidence, "late_reply_evidence": _safety_evidence}, "  "))
	file.close()
	print("SYNTHETIC A03 SUITE: ", _checks, " checks; ", _failures.size(), " failures")
	print("FIXTURE PASS" if _failures.is_empty() else "FAIL: " + str(_failures))
	entry.free()
	quit(0 if _failures.is_empty() else 1)
