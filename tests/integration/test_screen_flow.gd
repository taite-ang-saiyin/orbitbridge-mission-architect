extends SceneTree
const Workflow = preload("res://scripts/integration/mission_workflow.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): printerr("FAIL: Screen test timed out"); quit(1))
	call_deferred("_run")

func _settle() -> void:
	for frame in 4: await process_frame

func _run() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await _settle()
	app.show_screen(1)
	await _settle()
	_check(app.current.screen_id == "MissionCreator", "Real Creator opens")
	_check(app.current.data_input.value == 30 and not app.current.next_button.disabled, "Creator includes independent returned-MB goal")
	app.current.data_input.value = 31
	_check(app.state.required_returned_data_mb == 31, "Editing the data goal updates the real draft")
	app.current.data_input.value = 30
	app.current.next_button.pressed.emit()
	await _settle()
	var builder = app.current
	_check(builder.screen_id == "SpacecraftBuilder", "Creator Continue opens real Builder")
	_check(builder.total_values.text.contains("1060 g") and builder.total_values.text.contains("82 credits"), "Builder displays calculated baseline totals")
	_check(not builder.next_button.disabled, "Valid design can continue")
	builder.option_buttons.instrument_advanced.pressed.emit()
	_check(builder.total_values.text.contains("1380 g") and builder.total_values.text.contains("96 credits"), "A real component button updates displayed mass and cost")
	_check(builder.next_button.disabled and builder.compatibility.text.contains("1330"), "Heavy camera blocks Continue and explains the selected limit")
	app.show_screen(3)
	await _settle()
	var readiness = app.current
	_check(readiness.next_button.disabled and readiness.readiness_label.text == "LAUNCH BLOCKED", "Readiness Launch is blocked for overweight design")
	_check(readiness.check_details.profile_mass.text.begins_with("FAIL") and readiness.source_label.text.contains("NASA CubeSat 101"), "Real failed mass check and source are displayed")
	readiness.next_button.pressed.emit()
	await _settle()
	_check(app.current == readiness and app.state.active_run.is_empty(), "Even a forced disabled-button signal cannot launch invalid input")
	app.show_screen(4)
	await _settle()
	_check(app.current == readiness and app.state.active_run.is_empty(), "Sidebar/progress Operations entry cannot bypass launch validation")
	app.flow_error.hide()
	app.show_screen(2)
	await _settle()
	builder = app.current
	builder.selectors.launch_profile.item_selected.emit(1)
	builder.selectors.launcher.item_selected.emit(1)
	_check(app.state.launch_profile == "illustrative_alternative" and app.state.launcher == "medium", "Each real dropdown updates its own launch selection")
	_check(builder.total_values.text.contains("116 credits") and builder.next_button.disabled, "Alternative still blocks a budget that is too small")
	app.state.budget = 120
	builder.refresh()
	_check(not builder.next_button.disabled, "Compatible alternative passes when all independent checks pass")
	app.show_screen(3)
	await _settle()
	_check(app.current.source_label.text.contains("not a NASA") and not app.current.next_button.disabled, "Alternative displays its own assumption rather than a NASA source claim")
	# A passing screen result becomes stale as soon as the draft changes.
	app.state.budget = 1
	app.current.next_button.pressed.emit()
	await _settle()
	_check(app.state.active_run.is_empty() and app.current.next_button.disabled, "Launch click revalidates a stale passing screen")
	Workflow.reset(app.state)
	app.show_screen(3)
	await _settle()
	app.current.next_button.pressed.emit()
	await _settle()
	var operations = app.current
	_check(operations.screen_id == "MissionOperations", "Valid Launch reaches real Operations screen")
	_check(operations.run_configuration.mission.required_observations == 4 and operations.run_configuration.design.instrument_id == "instrument_basic", "Operations receives the launch snapshot with original IDs and goals")
	_check(operations.next_button.disabled and operations.telemetry.text.contains("25.00"), "Operations shows live battery and prevents premature results")
	app.show_screen(5)
	_check(app.current == operations, "Debrief route cannot invent a result before completion")
	app.flow_error.hide()
	app.show_screen(2)
	_check(app.current == operations, "An operating mission cannot be edited behind its launch snapshot")
	app.flow_error.hide()
	operations.finish_run()
	_check(not operations.next_button.disabled and operations.status.text.contains("COMPLETED"), "Real engine completion enables View Debrief")
	_check(operations.telemetry.text.contains("Returned: 48.00 / 30.00 MB") and operations.timeline.item_count > 0, "Operations displays actual returned data and HPC events")
	operations.next_button.pressed.emit()
	await _settle()
	_check(app.current.screen_id == "DebriefCompare" and app.current.results.text.contains("SUCCESS") and app.current.results.text.contains("Score: 100"), "Result screen displays the real KE2 report")
	_check(app.current.results.text.contains("48.00 / 30.00 MB"), "Result totals match the Operations screen")
	var previous_id: String = app.state.active_run.state.run_id
	app.show_screen(5)
	await _settle()
	_check(app.state.reports.size() == 1, "Reopening results does not duplicate history")
	app.current.retry()
	await _settle()
	_check(app.current.screen_id == "MissionOperations" and app.state.active_run.state.run_id != previous_id and app.state.active_run.state.step_index == 0, "Retry button starts a clean new run through the same real flow")
	app.current.stop_run()
	app.current.next_button.pressed.emit()
	await _settle()
	_check(app.current.results.text.contains("FAILED") and app.current.results.text.contains("Score: —"), "Stopped mission displays a failed result without a fake numeric score")
	app.begin_new_mission()
	await _settle()
	_check(app.current.screen_id == "MissionCreator" and app.state.active_run.is_empty() and app.state.reports.is_empty(), "New Mission route clears live state and prior reports")
	app.queue_free()
	await _settle()
	print("K12/K13 screen flow: %d checks passed; %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)
