extends SceneTree
var output_dir: String = "res://verification"
## Engine mouse/key input + literal provider replies; no human or live evidence.

const A := "SYNTHETIC-A06-RUN-A-001"
const B := "SYNTHETIC-A06-RUN-B-001"
const INITIAL := {"step": "0", "phase": "operating", "target_access": "On", "contact": "Off", "energy": "8 Wh", "generated": "0 MB", "stored": "0 MB", "returned": "0 MB", "observations": "0/3"}
const OBSERVED := {"step": "1", "phase": "operating", "target_access": "On", "contact": "Off", "energy": "7 Wh", "generated": "1 MB", "stored": "1 MB", "returned": "0 MB", "observations": "1/3"}
var entry: Control
var checks: int = 0
var failures: Array[String] = []
var records: Array = []
var capture_enabled: bool = false


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	for index in range(arguments.size()):
		if arguments[index] == "--output-dir" and index + 1 < arguments.size():
			output_dir = arguments[index + 1]
	DirAccess.make_dir_recursive_absolute(output_dir)
	_run.call_deferred()
	create_timer(30).timeout.connect(func():
		push_error("A06 fixture watchdog expired")
		quit(1))


func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)


func same(description: String, expected: Variant, actual: Variant) -> void:
	expect(expected == actual, description)
	records.append({"check": description, "expected": expected, "actual": actual, "status": "FIXTURE PASS" if expected == actual else "FAIL"})


func counts() -> Dictionary:
	return {"retry_intents": entry.retry_intents, "redesign_routes": entry.receiver.route_requests, "result_routes": entry.route_intents, "action_intents": entry.action_intents, "provider_actions": entry.provider.action_calls, "provider_starts": entry.provider.start_calls}


func flow() -> Dictionary:
	return {"hud": entry.operations.get_display_metrics(), "orbit": entry.operations.orbit_view.get_visual_snapshot(), "timeline": entry.operations.event_timeline.get_rows(), "inputs": entry.results.get_input_snapshot(), "debrief": entry.results.get_debrief_model(), "pending": entry.session._pending_request.duplicate(true)}


func mouse_click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
	await process_frame


func key_press(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)
	if code != KEY_TAB:
		var repeated := event.duplicate()
		repeated.echo = true
		root.push_input(repeated)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
	await process_frame


func capture(name: String) -> void:
	if not capture_enabled:
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(output_dir.path_join("a06-" + name + ".png")) == OK, "capture " + name)


func preserved(origin: Dictionary, draft: Dictionary, label: String) -> void:
	same(label + " all mission requirements", origin.context.config.mission, draft.mission)
	same(label + " fixed orbit", origin.context.config.design.orbit_id, draft.design.orbit_id)
	same(label + " scenario identity/version and pacing", origin.context.scenario, entry.receiver.get_scenario())
	var changes: Array = []
	for field in draft.design:
		if draft.design[field] != origin.context.config.design[field]:
			changes.append(field)
	expect(changes.size() <= 1 and (changes.is_empty() or changes[0] in ["radio_id", "battery_id"]), label + " only one player-selected component differs")
	records.append({"check": label + " component values", "original": origin.context.config.design, "edited": draft.design, "changed_fields": changes})


func _run() -> void:
	root.size = Vector2i(1280, 960)
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
	entry = load("res://preview/a06_preview.tscn").instantiate()
	root.add_child(entry)
	entry.manual_delivery = true
	await process_frame
	await process_frame
	var original: Dictionary = entry.results.get_input_snapshot()
	same("First completed run ID", A, original.context.run_id)
	same("First supplied report values", ["partial", "1/3", "2/4 MB", "42"], [entry.results.get_debrief_model().status, entry.results.get_debrief_model().observations, entry.results.get_debrief_model().returned, entry.results.get_debrief_model().score])
	var baseline: Dictionary = entry.receiver.get_completed()
	same("Initial eligible baseline and single completion", [A, [A]], [baseline.baseline_run_id, baseline.order])
	# Capture a genuine old request token before returning to completed A.
	entry.provider.choose_case("a06_a_initial")
	entry._tabs.current_tab = 0
	entry.session.open_run(A)
	entry.operations._action_buttons.observe.pressed.emit()
	expect(entry.session.is_pending(), "A request really pending before completion")
	same("Old request token identifies A", A, entry.provider.deliveries[0].token.run_id)
	entry._show_completed("a06_a_complete")
	same("A completion restored unchanged", original, entry.results.get_input_snapshot())
	# Mouse Retry, held rejected route, and multiple activation attempts.
	entry.route_reply_selector.select(1)
	var before := counts()
	await mouse_click(entry.results._retry_button)
	entry.results.set_inputs(original.context, original.state, original.report)
	entry.results._retry_button.pressed.emit()
	entry.results._request_retry()
	same("Mouse Retry sends one intent and one redesign route", [1, 1], [entry.retry_intents - before.retry_intents, entry.receiver.route_requests - before.redesign_routes])
	expect(entry.receiver.is_pending() and entry.results._retry_button.disabled, "Retry latched while route pending")
	same("Pending route does not start or simulate", [before.provider_starts, before.provider_actions], [entry.provider.start_calls, entry.provider.action_calls])
	same("Draft begins as deep copy", original.context.config, entry.receiver.get_draft())
	var external: Dictionary = entry.receiver.get_draft()
	external.mission.budget_credits = -99
	external.design.radio_id = "EXTERNAL-MUTATION"
	same("Getter cannot mutate owned editable draft", original.context.config, entry.receiver.get_draft())
	entry.draft_screen.value_selector.item_selected.emit(1)
	same("Player changes radio", "SYNTHETIC-RADIO-002", entry.receiver.get_draft().design.radio_id)
	preserved(original, entry.receiver.get_draft(), "Radio edit")
	var rejected: Dictionary = entry.deliver_route(0)
	same("Rejected redesign route reply", {"accepted": false, "reason": "SYNTHETIC redesign route rejected: Builder temporarily unavailable; draft retained."}, rejected)
	expect(not entry.draft_screen.component_selector.disabled and not entry.draft_screen.value_selector.disabled and entry.draft_screen.start_button.disabled and not entry.draft_screen.cancel_button.disabled, "Rejected route leaves draft editors and Cancel usable")
	entry.draft_screen.component_selector.item_selected.emit(1)
	same("Player can choose battery instead of supplied suggestion", ["SYNTHETIC-RADIO-001", "SYNTHETIC-BATTERY-002"], [entry.receiver.get_draft().design.radio_id, entry.receiver.get_draft().design.battery_id])
	preserved(original, entry.receiver.get_draft(), "Battery edit after rejection")
	expect(entry.draft_screen.get_visible_labels().experiment.contains(original.report.next_experiment), "KE2 experiment remains visible without applying it")
	records.append({"stage": "rejected editable draft", "labels": entry.draft_screen.get_visible_labels(), "counts": counts()})
	await capture("rejected-draft")
	same("Editing and rejection preserve completed snapshots", baseline, entry.receiver.get_completed())
	same("Editing and rejection preserve live completed A payload", original, entry.results.get_input_snapshot())
	await mouse_click(entry.draft_screen.cancel_button)
	same("Cancel returns original Debrief", original, entry.results.get_input_snapshot())
	same("Cancel preserves original config/report/history and baseline", baseline, entry.receiver.get_completed())
	expect(entry.receiver.get_draft().is_empty() and not entry.results._retry_button.disabled, "Cancel discards local edit and restores Retry")
	# Keyboard Space + echo, accepted route, same component requirements.
	entry.route_reply_selector.select(0)
	before = counts()
	entry.results._retry_button.grab_focus()
	await key_press(KEY_SPACE)
	entry.results._retry_button.pressed.emit()
	entry.results._request_retry()
	same("Keyboard Space Retry sends one intent and one redesign route", [1, 1], [entry.retry_intents - before.retry_intents, entry.receiver.route_requests - before.redesign_routes])
	var pending_route_labels: Dictionary = entry.draft_screen.get_visible_labels()
	same("Old route reply cannot settle newer redesign", "late_route_reply", entry.deliver_route(0).error)
	expect(entry.receiver.is_pending(), "New redesign still pending after stale route reply")
	same("Stale route reply cannot change draft reason", pending_route_labels, entry.draft_screen.get_visible_labels())
	same("Accepted redesign route reply", true, entry.deliver_route(1).accepted)
	entry.draft_screen.component_selector.item_selected.emit(0)
	same("Second draft changed radio only", ["SYNTHETIC-RADIO-002", "SYNTHETIC-BATTERY-001"], [entry.receiver.get_draft().design.radio_id, entry.receiver.get_draft().design.battery_id])
	preserved(original, entry.receiver.get_draft(), "Accepted redesign")
	var edited: Dictionary = entry.receiver.get_draft()
	entry.draft_screen.start_button.grab_focus()
	await capture("accepted-draft")
	await mouse_click(entry.draft_screen.start_button)
	await process_frame
	same("Distinct second run ID", B, entry.operations.get_input_snapshot().context.run_id)
	same("Second initial HUD exact supplied values", INITIAL, entry.operations.get_display_metrics())
	same("Second initial timeline only B launch", [B + "-EVENT-LAUNCH-000"], [entry.operations.event_timeline.get_rows()[0].event_id])
	same("Second initial timeline count", 1, entry.operations.event_timeline.get_rows().size())
	expect(entry.results.get_input_snapshot().report.is_empty() and entry.results.get_debrief_model().score == "Unavailable", "First report disappears on second start")
	same("B config is the edited copy", edited, entry.operations.get_input_snapshot().context.config)
	same("Completed A and baseline survive reset", baseline, entry.receiver.get_completed())
	same("Exactly one synthetic run start", 1, entry.provider.start_calls)
	await capture("second-initial-hud-timeline")
	# B has a new pending request when the actual stored A callback is delivered.
	entry.operations._action_buttons.observe.pressed.emit()
	expect(entry.session.is_pending(), "B action request pending")
	var pending_b := flow()
	same("Stored A callback rejected during B pending", {"accepted": false, "error": "late_reply"}, entry.provider.deliver(0))
	same("A callback changes no B telemetry/orbit/history/report/pending token", pending_b, flow())
	expect(entry.session.is_pending(), "B pending remains after A late reply")
	same("Repeated old callback still rejected", "late_reply", entry.provider.deliver(0).error)
	same("Second callback accepted", true, entry.provider.deliver(1).accepted)
	same("Second Observe exact supplied HUD", OBSERVED, entry.operations.get_display_metrics())
	same("Second timeline after Observe", [B + "-EVENT-LAUNCH-000", B + "-EVENT-OBSERVE-001"], [entry.operations.event_timeline.get_rows()[0].event_id, entry.operations.event_timeline.get_rows()[1].event_id])
	before = counts()
	await mouse_click(entry.finish_button)
	entry.operations._route_button.pressed.emit()
	await process_frame
	var model: Dictionary = entry.results.get_debrief_model()
	same("Second completed Debrief values", ["success", "completed", "3/3", "4/4 MB", "100%", "100%", "100"], [model.status, model.run_status, model.observations, model.returned, model.observation_percent, model.return_percent, model.score])
	same("Second Debrief run ID", B, entry.results.get_input_snapshot().report.run_id)
	same("One Results route from supplied terminal state", 1, entry.route_intents - before.result_routes)
	var completed: Dictionary = entry.receiver.get_completed()
	same("Exactly two unique completed run records", [A, B], completed.order)
	same("Original eligible baseline retained", A, completed.baseline_run_id)
	same("A config/report/history remain byte-for-byte value equivalent", original, completed.runs[A])
	same("B history only supplied B events", 4, completed.runs[B].state.events.size())
	for event in completed.runs[B].state.events:
		same("B event active run " + event.event_id, B, event.run_id)
	# Reopening Results is idempotent: no new run record or baseline replacement.
	for i in range(3):
		entry.back_button.pressed.emit()
		entry.operations._route_button.pressed.emit()
		same("Results re-entry " + str(i) + " retains exact completed history", completed, entry.receiver.get_completed())
		same("Results re-entry " + str(i) + " retains report", completed.runs[B], entry.results.get_input_snapshot())
	# Keyboard focus loop visibly reaches Back and Retry after the second result.
	entry.results._scroll.grab_focus()
	await key_press(KEY_TAB)
	same("Second Debrief keyboard reaches credits", entry.results._credits_button, root.gui_get_focus_owner())
	await key_press(KEY_TAB)
	same("Second Debrief keyboard reaches Back", entry.back_button, root.gui_get_focus_owner())
	await key_press(KEY_TAB)
	same("Second Debrief keyboard reaches Retry", entry.results._retry_button, root.gui_get_focus_owner())
	for control in [entry.back_button, entry.results._retry_button]:
		expect(not control.disabled and control.get_global_rect().end.y <= root.size.y, "Second result Back/Retry visible and enabled")
		expect(control.get_theme_stylebox("focus").border_width_left == 3, "Second result focus border3px")
	entry.results._scroll.scroll_vertical = 0
	records.append({"stage": "second Debrief", "labels": entry.results.get_visible_labels(), "counts": counts()})
	await capture("second-debrief")
	# Enter can Retry B; cancelling preserves B and the original A baseline.
	before = counts()
	await key_press(KEY_ENTER)
	same("Second Debrief Enter sends one Retry and route", [1, 1], [entry.retry_intents - before.retry_intents, entry.receiver.route_requests - before.redesign_routes])
	same("B Retry draft preserves B config", completed.runs[B].context.config, entry.receiver.get_draft())
	await mouse_click(entry.draft_screen.cancel_button)
	same("Cancel B pending redesign keeps completed runs and baseline", completed, entry.receiver.get_completed())
	same("Late route reply after Cancel rejected", "late_route_reply", entry.deliver_route(2).error)
	same("Cancelled route cannot replace B Debrief", completed.runs[B], entry.results.get_input_snapshot())
	# Read access returns copies, not mutable completed-run ownership.
	var copy: Dictionary = entry.receiver.get_completed()
	copy.runs[A].context.config.design.radio_id = "MUTATED-COPY"
	copy.runs[A].state.events.clear()
	same("Completed getters cannot mutate baseline", completed, entry.receiver.get_completed())
	same("Provider's completed A source unchanged", original, entry.provider.catalog().a06_a_complete.payload)
	var unmounted = preload("res://preview/a06_retry_receiver.gd").new()
	same("Unmounted route receiver gated", "preview_entry_required", unmounted.begin_redesign(original).error)
	var mock = preload("res://preview/a06_provider.gd").new()
	same("Unmounted A06 provider gated", {}, mock.catalog())
	same("Unmounted run creation gated", "preview_entry_required", mock.start_second(edited, original.context.scenario).error)
	same("Final exact lifecycle intent/call counts", {"retry_intents": 3, "redesign_routes": 3, "result_routes": 4, "action_intents": 2, "provider_actions": 2, "provider_starts": 1}, counts())
	same("P1 absent, supplied comparison remains null", null, entry.results.get_input_snapshot().report.comparison)
	var data := {"records": records, "run_ids": [A, B], "completed": completed, "counts": counts(), "renderer": RenderingServer.get_current_rendering_method(), "P1": "NOT TESTED / deferred: no revisioned KE2 comparison payload/schema; no comparison or component attribution computed locally", "evidence": "SYNTHETIC automated engine mouse/key fixture; not a human playtest"}
	entry.queue_free()
	await process_frame
	await _automatic_flow()
	data.checks = checks
	data.failures = failures
	var file := FileAccess.open(output_dir.path_join("a06-results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	print("SYNTHETIC A06 P0: ", checks, " checks; ", failures.size(), " failures")
	print("FIXTURE PASS" if failures.is_empty() else "FAIL")
	entry.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _automatic_flow() -> void:
	# A fresh explicit entry exercises the normal timer delivery, not test-held replies.
	entry = load("res://preview/a06_preview.tscn").instantiate()
	root.add_child(entry)
	await process_frame
	await process_frame
	same("Fresh explicit entry starts A with no old completions", [A], entry.receiver.get_completed().order)
	await mouse_click(entry.results._retry_button)
	expect(entry.receiver.is_pending(), "Default timer starts with held redesign route")
	await create_timer(0.7).timeout
	expect(entry.receiver.accepted and not entry.receiver.is_pending(), "Default timer delivers accepted route")
	entry.draft_screen.value_selector.item_selected.emit(1)
	await mouse_click(entry.draft_screen.start_button)
	same("Default route starts B initial snapshot", INITIAL, entry.operations.get_display_metrics())
	entry.operations._action_buttons.observe.pressed.emit()
	expect(entry.session.is_pending(), "Default action timer holds request")
	await create_timer(0.7).timeout
	expect(not entry.session.is_pending(), "Default action timer completes request")
	same("Default action timer delivers supplied Observe metrics", OBSERVED, entry.operations.get_display_metrics())
	await mouse_click(entry.finish_button)
	entry.operations._route_button.pressed.emit()
	same("Default interactive path reaches B report", [B, "100"], [entry.results.get_input_snapshot().report.run_id, entry.results.get_debrief_model().score])
	same("Default interactive path exact counts", {"retry_intents": 1, "redesign_routes": 1, "result_routes": 1, "action_intents": 1, "provider_actions": 1, "provider_starts": 1}, counts())
