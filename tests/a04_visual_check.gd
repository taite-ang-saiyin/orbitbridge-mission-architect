extends SceneTree
## SYNTHETIC snapshot/renderer evidence; no live simulation or human playtest.

const MARKERS := {
	0: [0.5, 0.18], 2: [0.8464101615, 0.34], 3: [0.9, 0.5],
	4: [0.8464101615, 0.66], 5: [0.7, 0.7771281292], 8: [0.1535898385, 0.66],
}
var entry: Control
var _checks: int = 0
var _failures: Array[String] = []
var _records: Array = []


class HeldProvider:
	extends RefCounted
	var source: RefCounted
	var delivery: Dictionary


	func _init(provider: RefCounted) -> void:
		source = provider


	func open_run(run_id: String) -> Dictionary:
		return source.open_run(run_id)


	func request_action_deferred(run_id: String, action_id: StringName, token: Dictionary, callback: Callable) -> void:
		delivery = {"token": token.duplicate(true), "reply": source.request_action(run_id, action_id).duplicate(true), "callback": callback}


	func fulfill() -> Dictionary:
		return delivery.callback.call(delivery.token.duplicate(true), delivery.reply.duplicate(true))


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
		push_error(description)


func _counts() -> Dictionary:
	return {"actions": entry.action_intents, "routes": entry.route_intents, "retry": entry.retry_intents,
		"provider_actions": entry.provider.action_calls, "provider_opens": entry.provider.open_calls}


func _delta(before: Dictionary) -> Dictionary:
	var after := _counts()
	for field in after:
		after[field] -= before[field]
	return after


func _snapshot() -> Dictionary:
	return {"hud": entry.operations.get_display_metrics(), "orbit": entry.operations.orbit_view.get_visual_snapshot(),
		"timeline": entry.operations.event_timeline.get_rows(), "current": entry.operations.event_timeline.get_current_text()}


func _same(label: String, expected: Dictionary, actual: Dictionary) -> void:
	_expect(expected == actual, label)
	_records.append({"case": label, "expected": expected, "actual": actual, "status": "FIXTURE PASS" if expected == actual else "FAIL"})


func _flag(value: Variant) -> String:
	return ("On" if value else "Off") if value is bool else "Unavailable"


func _sync(label: String) -> void:
	var input: Dictionary = entry.operations.get_input_snapshot()
	var actual := _snapshot()
	var expected_rows: Array = []
	for event in input.state.get("events", []):
		var stamp := "Step " + (str(event.step) if event.has("step") and event.step != null else "Unavailable")
		if event.has("time"):
			stamp = "Time " + str(event.time) if not event.has("step") else stamp + " | Time " + str(event.time)
		expected_rows.append({"run_id": input.context.run_id, "event_id": event.event_id, "stamp": stamp, "text": event.get("label", "Unavailable")})
	_same(label + ": exact supplied event order/text/IDs", {"rows": expected_rows}, {"rows": actual.timeline})
	_expect(actual.orbit.step == actual.hud.step, label + ": marker step equals HUD step")
	_expect(actual.orbit.target_access == actual.hud.target_access and actual.orbit.contact == actual.hud.contact, label + ": marker flags equal HUD flags")
	var expected_marker: Array = []
	if input.state.get("step") != null and MARKERS.has(input.state.step):
		expected_marker = MARKERS[input.state.step]
		_expect(actual.orbit.marker.size() == 2 and absf(actual.orbit.marker[0] - expected_marker[0]) < 0.00001 and absf(actual.orbit.marker[1] - expected_marker[1]) < 0.00001, label + ": marker matches independent diagram coordinate")
	else:
		_expect(actual.orbit.marker.is_empty(), label + ": missing step has no invented position")
	_expect(actual.orbit.target_access == _flag(input.state.get("target_access")) and actual.orbit.contact == _flag(input.state.get("contact_on")), label + ": explicit false and unavailable flags preserved")
	_expect(actual.orbit.run_id == str(input.context.get("run_id", "")), label + ": orbit uses active run identity")
	var expected_current := "Current state: Unavailable"
	if not input.state.is_empty():
		expected_current = "Current state: %s | Phase: %s | Step: %s" % [input.state.get("lifecycle", "Unavailable"), input.state.get("phase", "Unavailable"), input.state.get("step", "Unavailable")]
	_expect(actual.current == expected_current, label + ": supplied current state/phase/step visible")
	_records.append({"case": label + " synchronization", "expected": {"step": input.state.get("step", "Unavailable"), "marker": expected_marker, "target_access": _flag(input.state.get("target_access")), "contact": _flag(input.state.get("contact_on")), "current": expected_current}, "actual": actual})


func _press(action: String) -> void:
	entry.operations.find_child("Action_" + action, true, false).pressed.emit()


func _save_json(name: String, data: Dictionary) -> void:
	var file := FileAccess.open("res://verification/" + name, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))
	file.close()


func _capture(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_expect(root.get_texture().get_image().save_png("res://verification/" + path) == OK, "Captured " + path)


func _run() -> void:
	entry = load("res://preview/a04_preview.tscn").instantiate()
	root.add_child(entry)
	await process_frame
	var arguments := OS.get_cmdline_user_args()
	if "--restart-first" in arguments or "--restart-second" in arguments:
		_sync("Fresh process startup")
		_expect(entry.operations.get_display_metrics().step == "2" and entry.operations.event_timeline.get_rows().size() == 1, "Restart begins with A02 ready step 2 and one supplied event")
		_expect(_counts().actions == 0 and _counts().provider_actions == 0, "Restart generates no action")
		if "--capture" in arguments:
			await _capture("a04-restart-first.png" if "--restart-first" in arguments else "a04-restart-second.png")
		_save_json("a04-restart-first.json" if "--restart-first" in arguments else "a04-restart-second.json", {"snapshot": _snapshot(), "counts": _counts()})
		print("SYNTHETIC A04 RESTART: ", _checks, " checks; ", _failures.size(), " failures")
		print("FIXTURE PASS" if _failures.is_empty() else "FAIL")
		entry.free()
		quit(0 if _failures.is_empty() else 1)
		return
	var catalog: Dictionary = entry.provider.catalog()
	var original := catalog.duplicate(true)
	var baseline := _counts()
	for case_id in catalog:
		var reply: Dictionary = entry.select_fixture(case_id)
		if reply.accepted:
			_sync(case_id)
		else:
			_expect(case_id in ["report_stale_run", "report_dangling_event"], "Only deliberate A02 negative fixtures rejected")
			_expect(entry.operations.orbit_view.get_visual_snapshot().marker.is_empty() and entry.operations.event_timeline.get_rows().is_empty(), "Rejected payload clears orbit/events")
	_expect(entry.action_intents == baseline.actions and entry.provider.action_calls == baseline.provider_actions, "Snapshot selection/replay emits zero actions")
	# Observe and contact-on Transmit still go through accepted A03 provider replies.
	entry.select_fixture("ready_step_2")
	_press("observe")
	_sync("Observe reply")
	entry.select_fixture("contact_on")
	_press("downlink")
	_sync("Contact-on downlink reply")
	entry.select_fixture("observe_allowed")
	_press("power_save")
	_sync("Power-save reply")
	# A disabled click is distinct from receiving an existing scripted blocked reply.
	entry.select_fixture("observe_allowed")
	var snapshot_before := _snapshot()
	var counts_before := _counts()
	_expect(entry.operations.find_child("Action_downlink", true, false).disabled, "No-contact Transmit remains disabled")
	_press("downlink")
	_press("downlink")
	_same("Disabled no-contact clicks leave HUD/marker/timeline unchanged", snapshot_before, _snapshot())
	_same("Disabled Transmit: zero intents, zero provider calls, zero new rows", {"actions": 0, "routes": 0, "retry": 0, "provider_actions": 0, "provider_opens": 0}, _delta(counts_before))
	var run_id: String = entry.operations.get_input_snapshot().context.run_id
	counts_before = _counts()
	_expect(entry.session.request_action(run_id, &"downlink").accepted, "Existing A02 scripted blocked reply accepted through session")
	_sync("Scripted blocked reply")
	var rows: Array = entry.operations.event_timeline.get_rows()
	_same("Blocked event exact text and order", {"texts": ["SYNTHETIC ready, contact off", "SYNTHETIC Observe allowed", "SYNTHETIC Downlink blocked: no contact; no step advance"]}, {"texts": rows.map(func(row: Dictionary): return row.text)})
	_same("Blocked provider exercise dispatch counts", {"actions": 0, "routes": 0, "retry": 0, "provider_actions": 1, "provider_opens": 0}, _delta(counts_before))
	_expect(rows.size() == 3 and entry.operations.get_display_metrics().step == "3", "Blocked reply adds only its supplied row and advances no step")
	# Resize and redraw must not change the accepted model or send provider actions.
	entry.select_fixture("fresh_run_showcase")
	for requested_size in [Vector2i(1280, 960), Vector2i(900, 820), Vector2i(720, 900)]:
		snapshot_before = _snapshot()
		counts_before = _counts()
		root.size = requested_size
		await process_frame
		await process_frame
		_expect(root.size == requested_size, "Requested native Window size applied: " + str(requested_size))
		var viewport_size := root.get_visible_rect().size
		_expect(entry.operations._visual_grid.columns == (1 if requested_size.x < 850 else 2), "Responsive native-size column layout applied")
		for node in [entry.operations.orbit_view, entry.operations._metric_label, entry.operations.event_timeline]:
			var bounds: Rect2 = node.get_global_rect()
			_expect(bounds.position.x >= -1 and bounds.end.x <= viewport_size.x + 1 and bounds.size.x > 100, "Resized orbit/HUD/timeline fit horizontally: " + str(requested_size))
		_same("Resize preserves synchronized data at " + str(requested_size), snapshot_before, _snapshot())
		_same("Resize emits zero intents/provider calls at " + str(requested_size), {"actions": 0, "routes": 0, "retry": 0, "provider_actions": 0, "provider_opens": 0}, _delta(counts_before))
		_records.append({"case": "native resize", "display_driver": DisplayServer.get_name(), "expected_window_size": [requested_size.x, requested_size.y], "actual_window_size": [root.size.x, root.size.y], "viewport_size": [viewport_size.x, viewport_size.y], "columns": entry.operations._visual_grid.columns})
		if "--capture" in arguments and requested_size == Vector2i(720, 900):
			await _capture("a04-narrow.png")
		var scroll = entry.operations.find_children("*", "ScrollContainer", true, false)[0]
		scroll.ensure_control_visible(entry.operations.event_timeline)
		await process_frame
		await process_frame
		var timeline_bounds: Rect2 = entry.operations.event_timeline.get_global_rect()
		_expect(timeline_bounds.position.y >= 0 and timeline_bounds.end.y <= root.get_visible_rect().size.y, "Full timeline reachable by scrolling after resize")
		if "--capture" in arguments and requested_size == Vector2i(720, 900):
			await _capture("a04-narrow-timeline.png")
		scroll.scroll_vertical = 0
		await process_frame
	# Pulse is visual only, even while repeatedly rendering the same input.
	snapshot_before = _snapshot()
	counts_before = _counts()
	var pulse_before: float = entry.operations.orbit_view._pulse
	for index in range(30):
		var input: Dictionary = entry.operations.get_input_snapshot()
		entry.operations.set_inputs(input.context, input.state, input.report)
		await process_frame
	_expect(entry.operations.orbit_view._pulse != pulse_before, "Visual pulse actually ran")
	_same("Animation/rendering preserve step, marker and ordered timeline", snapshot_before, _snapshot())
	_same("Animation/rendering emit zero intents/provider calls", {"actions": 0, "routes": 0, "retry": 0, "provider_actions": 0, "provider_opens": 0}, _delta(counts_before))
	# Re-entry resumes the provider snapshot; rebuilding the rows must not append duplicates.
	counts_before = _counts()
	snapshot_before = _snapshot()
	for index in range(3):
		entry._tabs.current_tab = 1
		entry._tabs.current_tab = 0
	_same("Three screen re-entries preserve exactly seven event rows", snapshot_before, _snapshot())
	_same("Re-entry emits zero actions and fetches three snapshots", {"actions": 0, "routes": 0, "retry": 0, "provider_actions": 0, "provider_opens": 3}, _delta(counts_before))
	_expect(entry.operations.event_timeline.get_rows().size() == 7 and entry.operations.event_timeline._row_box.get_child_count() == 7, "No data rows or widget rows duplicated after re-entry")
	# Provider order is authoritative even if its supplied steps are not sorted.
	var payload: Dictionary = entry.operations.get_input_snapshot()
	payload.state.events = [payload.state.events[2], payload.state.events[0], payload.state.events[1]]
	payload.state.events[0].erase("step")
	payload.state.events[0].time = "T+00:05"
	_expect(entry.session.accept_payload(payload).accepted, "Time-only and non-sorted ordered events accepted")
	_sync("Time-only / provider-order fixture")
	rows = entry.operations.event_timeline.get_rows()
	_expect(rows[0].stamp == "Time T+00:05" and rows[1].stamp == "Step 0", "Supplied time and measured step zero preserved")
	# Missing position/flags are Unavailable, not false or a fictional position.
	payload.state.erase("step")
	payload.state.erase("contact_on")
	payload.state.erase("target_access")
	_expect(entry.session.accept_payload(payload).accepted, "Missing optional visual fields accepted")
	_sync("Missing visual fields")
	_expect(entry.operations.orbit_view.get_visual_snapshot().marker.is_empty(), "Missing step hides marker")
	_expect(entry.operations.orbit_view.get_visual_snapshot().contact == "Unavailable", "Missing contact is not Off")
	# A late action from OPS-001 cannot restore its events/marker after opening OPS-002.
	var held := HeldProvider.new(entry.provider)
	entry.session.bind_provider(held)
	entry.select_fixture("ready_step_2")
	_press("observe")
	_expect(entry.session.is_pending(), "Previous-run action held pending")
	var previous_run: String = held.delivery.token.run_id
	entry.select_fixture("fresh_run_empty")
	var fresh: Dictionary = entry.operations.get_input_snapshot()
	_expect(fresh.context.run_id != previous_run and fresh.context.run_id == "SYNTHETIC-KE3-RUN-OPS-002", "Fresh run has distinct stable run ID")
	_expect(entry.operations.event_timeline.get_rows().is_empty() and entry.operations.event_timeline._row_box.get_child_count() == 1, "Fresh run clears old events and displays empty-state row")
	snapshot_before = _snapshot()
	counts_before = _counts()
	var late := held.fulfill()
	_same("Previous-run late reply rejected", {"accepted": false, "error": "late_reply"}, late)
	_same("Late reply cannot restore old events, marker or HUD", snapshot_before, _snapshot())
	_same("Late reply emits no extra intent or provider call", {"actions": 0, "routes": 0, "retry": 0, "provider_actions": 0, "provider_opens": 0}, _delta(counts_before))
	_sync("Fresh empty run after late previous-run reply")
	# Finish on one representative run with every requested kind supplied together.
	entry.session.bind_provider(entry.provider)
	entry.select_fixture("fresh_run_showcase")
	_sync("Representative launch/orbit/Observe/blocked/Save/downlink timeline")
	_expect(entry.provider.catalog() == original, "All source fixture snapshots remain immutable")
	if "--capture" in arguments:
		root.size = Vector2i(1280, 960)
		await process_frame
		await process_frame
		await _capture("a04-orbit-hud-timeline.png")
		var viewport_size := root.get_visible_rect().size
		var bounds: Rect2 = entry.operations.event_timeline.get_global_rect()
		_expect(bounds.position.y >= 0 and bounds.end.y <= viewport_size.y, "Representative capture includes the entire timeline with orbit and HUD")
	_save_json("a04-evidence.json", {"synthetic": true, "display_driver": DisplayServer.get_name(), "checks": _checks, "failures": _failures, "records": _records, "final_snapshot": _snapshot()})
	print("SYNTHETIC A04 SUITE: ", _checks, " checks; ", _failures.size(), " failures")
	print("FIXTURE PASS" if _failures.is_empty() else "FAIL: " + str(_failures))
	entry.free()
	quit(0 if _failures.is_empty() else 1)
