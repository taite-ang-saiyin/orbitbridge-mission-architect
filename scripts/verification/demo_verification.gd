extends RefCounted
## Explicit --verify-demo mode checks the same screens inside an exported game.
const Workflow = preload("res://scripts/integration/mission_workflow.gd")
var passed: int = 0
var failed: int = 0
var cases: Array = []

func run(app: Control) -> Dictionary:
	await _settle(app)
	app.show_screen(2)
	await _settle(app)
	var builder = app.current
	_check(builder.total_values.text.contains("1060 g") and builder.total_values.text.contains("82 credits"), "Starter totals are displayed")
	_check(not builder.next_button.disabled, "Starter design is ready")
	_record(app, "starter")
	builder.option_buttons.instrument_advanced.pressed.emit()
	_check(builder.total_values.text.contains("1380 g"), "Heavy camera changes the visible weight")
	_check(builder.next_button.disabled, "Heavy camera blocks Continue")
	_check(app.state.validation.checks.profile_mass.passed == false and app.state.validation.checks.launcher_capacity.passed == true, "1380 g fails the strict sample rule, not the 1500 g launcher limit")
	app.show_screen(3)
	await _settle(app)
	_check(app.current.warning_label.text.contains("1330"), "Weight failure explains the selected limit")
	_check(app.current.source_label.text.contains("NASA CubeSat 101"), "Source credit is visible")
	_record(app, "heavy_camera_1380g")
	await _blocked_launch(app, "Heavy camera")
	app.show_screen(2)
	await _settle(app)
	app.state.budget = 120
	app.current.option_buttons.battery_large.pressed.emit()
	_check(app.current.total_values.text.contains("1580 g"), "Heavy camera plus large battery reaches 1580 g")
	_check(app.state.validation.checks.launcher_capacity.passed == false and app.state.validation.checks.budget.passed == true, "Small launcher independently fails while budget passes")
	app.show_screen(3)
	await _settle(app)
	_check(app.current.check_details.launcher_capacity.text.begins_with("FAIL"), "Launcher capacity failure is displayed")
	_record(app, "heavy_camera_small_launcher_1580g")
	await _blocked_launch(app, "Small-launcher capacity")
	Workflow.reset(app.state)
	app.state.budget = 81
	app.show_screen(3)
	await _settle(app)
	_check(app.state.validation.metrics.total_mass_g == 1060 and app.state.validation.checks.profile_mass.passed == true, "Low-budget design still passes the weight check")
	_check(app.current.check_details.budget.text.begins_with("FAIL") and app.current.warning_label.text.contains("82"), "Cost 82 versus budget 81 is displayed as a blocker")
	_record(app, "passing_mass_failing_budget")
	await _blocked_launch(app, "Low budget")
	Workflow.reset(app.state)
	app.state.targets = ["Coastal Region"]
	app.show_screen(3)
	await _settle(app)
	_check(app.state.validation.metrics == null and not app.state.validation.ready_to_launch, "Unsupported target is rejected without fabricated totals")
	_check(app.current.warning_label.text.contains("Equator"), "Unsupported-target correction names the available target")
	_record(app, "unsupported_target")
	await _blocked_launch(app, "Unsupported target")
	app.show_screen(1)
	await _settle(app)
	app.current.target_buttons["Equator"].pressed.emit()
	_check(app.state.targets == ["Equator"] and not app.current.next_button.disabled, "Choosing Equator explicitly fixes the target")
	app.show_screen(3)
	await _settle(app)
	_check(not app.current.next_button.disabled, "Supported target restores readiness")
	app.current.next_button.pressed.emit()
	await _settle(app)
	_check(app.current.screen_id == "MissionOperations", "Valid design launches in this build")
	_check(app.current.run_configuration.mission.target_region == "equator", "The selected target reaches the launch snapshot unchanged")
	app.current.finish_run()
	_check(app.state.active_run.state.step_index == 60 and app.state.active_run.state.returned_data_mb == 48, "Real high-inclination mission completes 60 steps and returns 48 MB")
	app.current.next_button.pressed.emit()
	await _settle(app)
	_check(app.current.results.text.contains("SUCCESS") and app.current.results.text.contains("Score: 100"), "Actual success and score reach the Results screen")
	_check(app.current.results.text.contains("48.00 / 30.00 MB"), "Actual returned MB and goal are visible in Results")
	_record_run(app, "high_inc_completed")
	app.show_screen(5)
	await _settle(app)
	_check(app.state.reports.size() == 1, "Reopening Results keeps one report")
	app.current.retry()
	await _settle(app)
	_check(app.state.active_run.state.step_index == 0 and app.state.active_run.state.event_log.is_empty(), "Retry clears live counters and events")
	app.current.stop_run()
	app.current.next_button.pressed.emit()
	await _settle(app)
	_check(app.current.results.text.contains("FAILED") and app.current.results.text.contains("Score: —"), "Stopping a run produces a null-score failed result")
	app.begin_new_mission()
	await _settle(app)
	_check(app.state.active_run.is_empty() and app.state.reports.is_empty(), "New Mission clears history")
	app.show_screen(2)
	await _settle(app)
	app.current.selectors.orbit.item_selected.emit(0)
	_check(app.state.orbit == "low_eq" and not app.current.next_button.disabled, "The other authored orbit remains suitable for Equator")
	app.show_screen(3)
	await _settle(app)
	app.current.next_button.pressed.emit()
	await _settle(app)
	app.current.finish_run()
	app.current.next_button.pressed.emit()
	await _settle(app)
	_check(app.current.results.text.contains("SUCCESS"), "The low-equatorial orbit also reaches actual success")
	_check(app.state.active_run.evaluation.report.returned_data_mb >= 30, "Low-equatorial return is measured from its own contact windows")
	_record_run(app, "low_eq_completed")
	print("K14 scenarios: %d checks passed; %d failed." % [passed, failed])
	print("K14_EVIDENCE " + JSON.stringify({"passed": passed, "failed": failed, "cases": cases}))
	return {"passed": passed, "failed": failed, "cases": cases}

func _blocked_launch(app: Control, label: String) -> void:
	var readiness = app.current
	_check(readiness.next_button.disabled, label + ": Launch button is disabled")
	readiness.next_button.pressed.emit()
	await _settle(app)
	_check(app.current == readiness and app.state.active_run.is_empty(), label + ": forced button signal cannot start a run")
	app.show_screen(4)
	await _settle(app)
	_check(app.current == readiness and app.state.active_run.is_empty(), label + ": navigation cannot bypass the gate")
	app.flow_error.hide()

func _settle(app: Control) -> void:
	for frame in 4: await app.get_tree().process_frame

func _record(app: Control, id: String) -> void:
	var validation: Dictionary = app.state.validation
	var codes: Array = []
	for issue in validation.errors: codes.append(issue.code)
	cases.append({"id": id, "ready_to_launch": validation.ready_to_launch, "metrics": validation.metrics, "error_codes": codes})

func _record_run(app: Control, id: String) -> void:
	cases.append({"id": id, "report": app.state.active_run.evaluation.report})

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
	for name in ["components", "launch_profiles", "launchers", "ke1_reference_ids", "orbits"]:
		_check(FileAccess.file_exists("res://data/" + name + ".json"), "Packaged runtime data exists: " + name)
	for path in ["AGENTS.md", "GEMINI.md", "tasks.md", "docs/team-agreement.md", "docs/references/NASA_CubeSat_101.pdf"]:
		_check(not FileAccess.file_exists("res://" + path), "Private/source documentation excluded: " + path)
	_check(not ResourceLoader.exists("res://tests/acceptance/test_k14_acceptance.gd"), "Editor acceptance test source is excluded")
	return {"passed": passed - previous_passed, "failed": failed - previous_failed}
