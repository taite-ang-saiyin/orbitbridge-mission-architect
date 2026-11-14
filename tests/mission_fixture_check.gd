extends SceneTree
## SYNTHETIC checks, including fail-closed provider selection. Not a live test.

var _failures: Array[String] = []
var _checks: int = 0


class FailedLiveProvider:
	extends RefCounted
	var calls: int = 0


	func open_run(_run_id: String) -> Dictionary:
		calls += 1
		return {"ok": false, "error": "live_provider_failed"}


	func request_action(_run_id: String, _action_id: StringName) -> Variant:
		calls += 1
		return null


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
		push_error(description)


func _empty_views(entry: Control) -> bool:
	var empty := {"context": {}, "state": {}, "report": {}}
	return entry.operations.get_input_snapshot() == empty and entry.results.get_input_snapshot() == empty


func _state(entry: Control) -> Dictionary:
	return entry.operations.get_input_snapshot().state


func _press_preview_button(entry: Control, text: String) -> void:
	for button in entry.find_children("*", "Button", true, false):
		if button.text == text:
			_expect(not button.disabled, "Explicit preview action button enabled: " + text)
			button.pressed.emit()
			return
	_expect(false, "Preview action button found: " + text)


func _run() -> void:
	var fixture_script = load("res://preview/fixture_provider.gd")
	var unauthorized = fixture_script.new()
	_expect(unauthorized.catalog().is_empty(), "No entry: fixture data not activated")
	_expect(unauthorized.open_run("SYNTHETIC-KE3-RUN-OPS-001").error == "preview_entry_required", "Direct mock provider requires explicit preview entry")
	_expect(not unauthorized.choose_case("ready_step_2"), "No entry: cannot select a mock case")
	var detached = load("res://preview/mission_preview.gd").new()
	var detached_provider = fixture_script.new(detached)
	_expect(detached_provider.catalog().is_empty(), "Detached preview object cannot activate mocks")
	detached.free()
	_expect(ProjectSettings.get_setting("application/run/main_scene") == "res://ke3/operations_control.tscn", "Normal startup remains the empty outline, not the mock entry")
	var entry = load("res://preview/mission_preview.tscn").instantiate()
	root.add_child(entry)
	await process_frame
	var catalog: Dictionary = entry.provider.catalog()
	_expect(catalog.size() == 13, "All 13 requested scenario fixtures exist")
	var fresh: Dictionary = load("res://preview/mission_fixtures.gd").new().all_cases()
	_expect(catalog == fresh, "Run/event identifiers and values are stable across construction")
	var event_index: Dictionary = {}
	var render_intents := {"count": 0}
	entry.operations.action_requested.connect(func(_run: String, _action: StringName): render_intents.count += 1)
	entry.operations.result_route_requested.connect(func(_run: String): render_intents.count += 1)
	entry.results.retry_requested.connect(func(_run: String): render_intents.count += 1)
	for case_id in catalog:
		var fixture: Dictionary = catalog[case_id]
		var original := fixture.duplicate(true)
		var mission: Dictionary = fixture.payload.context.config_selections
		_expect(mission.observations_requested == 3 and mission.return_threshold_mb == 4, case_id + ": mission requirements are literal 3 observations / 4 MB")
		_expect(mission.duration_steps == 8 and mission.budget_credits == 1200 and not mission.target_id.is_empty(), case_id + ": duration, budget and target present")
		_expect(mission.selected_part_ids.size() == 7 and mission.selected_orbit_id.begins_with("SYNTHETIC-"), case_id + ": selected part/orbit IDs present")
		_expect(mission.profile_label.begins_with("SYNTHETIC") and mission.source_labels[0].begins_with("SYNTHETIC"), case_id + ": profile/source labels explicitly synthetic")
		for event in fixture.payload.state.events:
			_expect(event.run_id == fixture.payload.context.run_id and not event.event_id.is_empty(), case_id + ": event has correlated stable identity")
			if event_index.has(event.event_id):
				_expect(event_index[event.event_id] == event, case_id + ": reused event ID has identical content")
			event_index[event.event_id] = event
		var reply: Dictionary = entry.select_fixture(case_id)
		_expect(reply.accepted == fixture.expected.accepted, case_id + ": expected presentation acceptance")
		if fixture.expected.accepted:
			_expect(entry.operations.get_input_snapshot() == fixture.payload, case_id + ": Operations uses the shared set_inputs boundary")
			_expect(entry.results.get_input_snapshot() == fixture.payload, case_id + ": Results uses the shared set_inputs boundary")
			for field in fixture.expected:
				if field == "accepted":
					continue
				if case_id == "report_missing":
					_expect(entry.results.get_input_snapshot().report.is_empty(), "Missing report stays empty, never computed")
				elif case_id.begins_with("report_"):
					_expect(fixture.payload.report.get(field) == fixture.expected[field], case_id + ": direct expected report field " + field)
				else:
					_expect(_state(entry).get(field) == fixture.expected[field], case_id + ": direct expected state field " + field)
		else:
			_expect(reply.error == fixture.expected.error and _empty_views(entry), case_id + ": stale data rejected without leaking into either view")
		if case_id == "report_dangling_event":
			_expect(reply.accepted and not entry.results.get_input_snapshot().report.is_empty(), "A05: current-run report retained when linked evidence is missing")
		_expect(fixture == original, case_id + ": provider/presentation did not mutate fixture data")
		print("SYNTHETIC CASE ", case_id, " => ", reply, " expected=", fixture.expected)
	_expect(render_intents.count == 0, "Selecting/rendering all fixtures emitted no gameplay intents")
	# Independent literals verify the specifically requested values, beyond table consistency.
	entry.select_fixture("ready_step_2")
	_expect(_state(entry).step == 2 and _state(entry).energy_wh == 8 and _state(entry).stored_mb == 2 and _state(entry).returned_mb == 0 and not _state(entry).contact_on, "Ready step 2: 8 Wh / 2 MB stored / 0 MB returned / contact off")
	_press_preview_button(entry, "SYNTHETIC observe")
	_expect(_state(entry).step == 3 and _state(entry).energy_wh == 7 and _state(entry).stored_mb == 3 and _state(entry).observations_completed == 1 and _state(entry).observations_requested == 3, "Observe intent through shared provider path returns literal step 3 / 7 Wh / 3 MB / 1 of 3")
	_press_preview_button(entry, "SYNTHETIC downlink")
	_expect(_state(entry).step == 3 and _state(entry).energy_wh == 7 and _state(entry).stored_mb == 3 and _state(entry).returned_mb == 0, "Blocked no-contact reply leaves step and resources unchanged")
	_press_preview_button(entry, "SYNTHETIC power_save")
	_expect(_state(entry).step == 4 and _state(entry).energy_wh == 8 and _state(entry).stored_mb == 3, "Power-save reply uses directly supplied step 4 / 8 Wh / 3 MB")
	entry.select_fixture("contact_on")
	_press_preview_button(entry, "SYNTHETIC downlink")
	_expect(_state(entry).step == 5 and _state(entry).energy_wh == 6 and _state(entry).stored_mb == 1 and _state(entry).returned_mb == 2 and _state(entry).contact_on, "Contact-on downlink returns literal step 5 / 6 Wh / 1 MB stored / 2 MB returned")
	entry.select_fixture("terminal")
	_expect(_state(entry).lifecycle == "terminal" and _state(entry).step == 8, "Terminal snapshot is explicit")
	_expect(entry.provider.request_action(_state(entry).run_id, &"observe").error == "scripted_action_unavailable", "Terminal fixture has no scripted action transition")
	entry.select_fixture("report_partial")
	var partial: Dictionary = entry.results.get_input_snapshot().report
	_expect(partial.status == "partial" and partial.observations_completed == 1 and partial.observations_requested == 3 and partial.returned_mb == 2 and partial.return_threshold_mb == 4, "Partial report is literal 1/3 observations and 2/4 MB returned")
	_expect(partial.causes.size() == 1 and partial.suggested_changes.size() == 1, "Partial has exactly one cause and one suggested change")
	entry.select_fixture("report_missing")
	for button in entry.results.find_children("*", "Button", true, false):
		_expect(button.disabled, "Missing report disables retry")
	# Fail a live provider after a preview was used: even then, no mock fallback.
	var old_fixture_provider: RefCounted = entry.provider
	var old_open_calls: int = old_fixture_provider.open_calls
	var old_action_calls: int = old_fixture_provider.action_calls
	var failed := FailedLiveProvider.new()
	entry.session.bind_provider(failed)
	var live_reply: Dictionary = entry.session.open_run("LIVE-RUN-NO-PAYLOAD")
	_expect(not live_reply.accepted and live_reply.error == "live_provider_failed" and _empty_views(entry), "Failed live open clears presentation and does not activate fixtures")
	var failed_action: Dictionary = entry.session.request_action("LIVE-RUN-NO-PAYLOAD", &"observe")
	_expect(not failed_action.accepted and failed_action.error == "provider_unavailable" and _empty_views(entry), "Malformed live action reply cannot activate fixtures")
	_expect(old_fixture_provider.open_calls == old_open_calls and old_fixture_provider.action_calls == old_action_calls, "Live failure made zero calls to the previously used mock provider")
	entry.session.bind_provider(null)
	_expect(entry.session.open_run("LIVE-RUN-MISSING-PROVIDER").error == "provider_unavailable" and _empty_views(entry), "Missing live provider cannot select mocks")
	entry.session.bind_provider(unauthorized)
	_expect(entry.session.open_run("SYNTHETIC-KE3-RUN-OPS-001").error == "preview_entry_required" and _empty_views(entry), "Shared provider seam cannot bypass explicit preview entry")
	root.remove_child(entry)
	_expect(old_fixture_provider.catalog().is_empty(), "Removing explicit preview entry deactivates mock selection")
	_expect(old_fixture_provider.open_run("SYNTHETIC-KE3-RUN-OPS-001").error == "preview_entry_required", "Provider retained outside the preview cannot serve mocks")
	root.add_child(entry)
	# Retain an inspectable manifest; no production scene reads verification files.
	DirAccess.make_dir_recursive_absolute("res://verification")
	var manifest := FileAccess.open("res://verification/mission-fixtures.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify(catalog, "  "))
	manifest.close()
	if "--capture" in OS.get_cmdline_user_args():
		entry.session.bind_provider(old_fixture_provider)
		entry.select_fixture("report_partial")
		(entry.results.get_parent() as TabContainer).current_tab = 1
		await process_frame
		await RenderingServer.frame_post_draw
		_expect(root.get_texture().get_image().save_png("res://verification/mission-partial.png") == OK, "Partial fixture screenshot saved")
	print("SYNTHETIC FIXTURE SUITE: ", _checks, " checks; ", _failures.size(), " failures")
	print("FIXTURE PASS" if _failures.is_empty() else "FAIL: " + str(_failures))
	entry.free()
	quit(0 if _failures.is_empty() else 1)
