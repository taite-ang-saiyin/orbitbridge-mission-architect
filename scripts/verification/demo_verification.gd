extends RefCounted
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Catalog = preload("res://data/mock/DesignCatalog.gd")
var passed: int = 0
var failed: int = 0
var cases: Array = []

func run(app: Control) -> Dictionary:
	await _settle(app)
	fresh(app)
	app.show_screen(1)
	await _settle(app)
	_check(app.current.returned_data_input.value == 30, "Independent returned-MB goal is retained")
	app.show_screen(2)
	await _settle(app)
	_check(app.current.total_values.text.contains("1060") and app.current.total_values.text.contains("82"), "Starter totals are displayed")
	_check(not app.current.next_button.disabled, "Starter design is ready")
	_record(app, "starter")
	choose(app.current, "instrument", "instrument_advanced")
	_check(app.current.total_values.text.contains("1380"), "Heavy camera changes displayed weight")
	_check(app.current.next_button.disabled, "Heavy camera blocks Continue")
	var result: Dictionary = Runtime.review(app.state)
	_check(result.checks.profile_mass.passed == false and result.checks.launcher_capacity.passed == true, "1380 g fails the strict sample rule, not launcher capacity")
	app.show_screen(3)
	await _settle(app)
	_check(app.current.warning_label.text.contains("1330"), "Weight failure explains the selected limit")
	_check(all_text(app.current).contains("NASA CubeSat 101"), "Source credit remains visible")
	_record(app, "heavy_camera_1380g")
	await _blocked(app, "Heavy camera")
	app.show_screen(2)
	await _settle(app)
	app.state.budget = 120
	choose(app.current, "battery", "battery_large")
	result = Runtime.review(app.state)
	_check(result.metrics.total_mass_g == 1580, "Heavy camera and large battery reach 1580 g")
	_check(result.checks.launcher_capacity.passed == false and result.checks.budget.passed == true, "Small launcher independently fails while budget passes")
	app.show_screen(3)
	await _settle(app)
	_record(app, "heavy_camera_small_launcher_1580g")
	await _blocked(app, "Small launcher")
	fresh(app)
	app.state.budget = 81
	app.show_screen(3)
	await _settle(app)
	result = Runtime.review(app.state)
	_check(result.metrics.total_mass_g == 1060 and result.checks.profile_mass.passed == true, "Low budget design still passes mass")
	_check(result.checks.budget.passed == false and app.state.budget == 81, "Cost 82 versus exact budget 81 stays blocked without rounding")
	_record(app, "passing_mass_failing_budget")
	await _blocked(app, "Low budget")
	fresh(app)
	app.state.targets = ["Unknown target"]
	app.show_screen(3)
	await _settle(app)
	_check(Runtime.review(app.state).metrics == null and app.current.next_button.disabled, "Unregistered target is rejected without false totals")
	_record(app, "unregistered_target")
	await _blocked(app, "Unregistered target")
	app.show_screen(1)
	await _settle(app)
	app.current.target_buttons["Equator"].pressed.emit()
	_check(app.state.targets == ["Equator"], "Explicit target selection repairs the draft")
	app.show_screen(3)
	await _settle(app)
	_check(not app.current.next_button.disabled, "Supported target restores readiness")
	# A previously passing screen never authorizes a later invalid config.
	app.state.budget = 1
	app.current.next_button.pressed.emit()
	await _settle(app)
	_check(not app.state.has("run_trace"), "Launch click rechecks stale permissions")
	app.state.budget = 100
	app.show_screen(3)
	await _settle(app)
	app.current.next_button.pressed.emit()
	await _settle(app)
	_check(app.current.screen_id == "MissionOperations", "Validated launch opens Operations")
	_check(app.current.run_configuration.mission.target_region == "equator", "Target reaches the native launch snapshot")
	var operations = app.current
	var before: Dictionary = app.state.active_run_state.duplicate(true)
	operations.take_action("power_save")
	_check(app.state.active_run_state.step_index == before.step_index + 1, "Preserved manual action advances the real engine once")
	_check(app.state.active_run_state.config_snapshot == before.config_snapshot, "Manual action preserves launch goals and IDs")
	_check(operations.action_buttons.power_save.tooltip_text.contains("Wh"), "Native next-step prediction is available on the action control")
	app.show_screen(5)
	_check(app.current == operations, "Navigation cannot show an invented early result")
	app.flow_error.hide()
	app.show_screen(2)
	_check(app.current == operations, "Operating snapshot cannot be edited behind the run")
	app.flow_error.hide()
	operations.skip_to_end()
	_check(app.state.active_run_state.step_index == 60 and app.state.active_run_state.returned_data_mb == 48, "Real run completes 60 steps and returns 48 MB")
	operations.next_button.pressed.emit()
	await _settle(app)
	_check(app.current.results.text.to_lower().contains("success") and app.current.results.text.contains("Score: 100"), "Real evaluation reaches Results")
	_record_run(app, "high_inc_completed")
	app.show_screen(5)
	await _settle(app)
	_check(app.state.evaluation_store.history.size() == 1, "Repeated results are published only once")
	_check(app.current.same_mission_button.text == "Retry same mission" and app.current.retry_button.text == "Modify design", "Both Retry choices are available in the packaged Results screen")
	var completed_session: Dictionary = app.state.duplicate(true)
	app.current.retry_button.pressed.emit()
	await _settle(app)
	_check(app.current.screen_id == "SpacecraftBuilder" and not app.retry_restore.is_empty(), "Modify design opens an editable copy")
	app.cancel_retry()
	await _settle(app)
	_check(app.current.screen_id == "DebriefCompare", "Cancel returns to the completed result")
	_check(app.state == completed_session, "Cancel restores the exact mission, report and baseline")
	var frozen: Dictionary = app.state.run_trace.config.duplicate(true)
	var old_id: String = app.state.run_trace.final_state.run_id
	app.state.observations = 20
	app.current.same_mission_button.pressed.emit()
	await _settle(app)
	_check(app.state.run_trace.config == frozen and app.state.run_trace.final_state.run_id != old_id, "Retry restores exact original config and a new run ID")
	_check(app.state.active_run_state.step_index == 0 and app.state.active_run_state.event_log.is_empty(), "Retry resets counters and events")
	app.abort_current_run("Stopped by verification")
	await _settle(app)
	var aborted: Dictionary = app.state.evaluation_store.reports[app.state.active_run_state.run_id]
	_check(aborted.status == "failed" and aborted.score == null and app.current.results.text.contains("Not scored"), "Abort retains failed/null-score behavior")
	app.start_new_mission()
	await _settle(app)
	_check(not app.state.has("run_trace") and not app.state.has("evaluation_store"), "New Mission clears history")
	fresh(app)
	app.state.orbit = "LEO – 400 km"
	app.show_screen(3)
	await _settle(app)
	_check(not app.current.next_button.disabled, "Other native orbit remains suitable")
	app.current.next_button.pressed.emit()
	await _settle(app)
	app.current.skip_to_end()
	app.current.next_button.pressed.emit()
	await _settle(app)
	var report: Dictionary = app.state.evaluation_store.reports[app.state.active_run_state.run_id]
	_check(report.status == "success" and report.returned_data_mb >= 30, "Other orbit reaches actual success")
	_record_run(app, "low_eq_completed")
	print("K14 scenarios: %d checks passed; %d failed." % [passed, failed])
	print("K14_EVIDENCE " + JSON.stringify({"passed": passed, "failed": failed, "cases": cases}))
	return {"passed": passed, "failed": failed, "cases": cases}

func fresh(app: Control) -> void:
	Catalog.reset(app.state)
	app.state.name = "Verification imaging trial"
	app.state.targets = ["Equator"]
	app.state.target_limit = 1
	app.state.observations = 4
	app.state.required_returned_data_mb = 30
	app.state.duration = 6
	app.state.budget = 100
	app.state.orbit = "Polar – 600 km"

func choose(page: Control, slot: String, id: String) -> void:
	var select: OptionButton = page.engineering_selectors[slot]
	for index in select.item_count:
		if select.get_item_metadata(index) == id:
			select.select(index)
			select.item_selected.emit(index)
			return
	_check(false, "Missing catalog choice: " + id)

func all_text(node: Node) -> String:
	var text: String = node.text if node is Label else ""
	for child in node.get_children(): text += "\n" + all_text(child)
	return text

func _blocked(app: Control, label: String) -> void:
	var readiness = app.current
	_check(readiness.next_button.disabled, label + ": Launch is disabled")
	readiness.next_button.pressed.emit()
	await _settle(app)
	_check(app.current == readiness and not app.state.has("run_trace"), label + ": forced button cannot launch")
	app.show_screen(4)
	await _settle(app)
	_check(app.current == readiness and not app.state.has("run_trace"), label + ": navigation cannot bypass checks")
	app.flow_error.hide()

func _record(app: Control, id: String) -> void:
	var result: Dictionary = Runtime.review(app.state)
	var codes: Array = []
	for issue in result.errors: codes.append(issue.code)
	cases.append({"id": id, "ready_to_launch": result.ready_to_launch, "metrics": result.metrics, "error_codes": codes})

func _record_run(app: Control, id: String) -> void:
	cases.append({"id": id, "report": app.state.evaluation_store.reports[app.state.active_run_state.run_id]})

func _settle(app: Control) -> void:
	for frame in 4: await app.get_tree().process_frame

func _check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func check_packaging() -> Dictionary:
	var previous_passed: int = passed
	var previous_failed: int = failed
	var version: Dictionary = Engine.get_version_info()
	_check(version.major == 4 and version.minor == 7 and version.patch == 2, "Export runs the confirmed Godot version")
	var art = preload("res://data/mock/SatelliteAdapter.gd")
	for slot in art.STARTER:
		for option in art.catalog(slot):
			_check(ResourceLoader.exists(option.asset) and load(option.asset) is PackedScene, "Packaged art variant exists: " + option.id)
	for name in ["components", "launch_profiles", "launchers", "ke1_reference_ids", "orbits", "mission_scenarios"]:
		_check(FileAccess.file_exists("res://data/" + name + ".json"), "Packaged runtime data exists: " + name)
	for path in ["AGENTS.md", "GEMINI.md", "tasks.md", "docs/team-agreement.md", "docs/references/NASA_CubeSat_101.pdf"]:
		_check(not FileAccess.file_exists("res://" + path), "Private/source documentation excluded: " + path)
	_check(not ResourceLoader.exists("res://tests/acceptance/test_k14_acceptance.gd"), "Editor acceptance test source is excluded")
	return {"passed": passed - previous_passed, "failed": failed - previous_failed}
