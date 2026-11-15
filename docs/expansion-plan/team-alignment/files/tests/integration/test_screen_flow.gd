extends SceneTree
const Verify = preload("res://scripts/verification/demo_verification.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): printerr("FAIL: Screen merge check timed out"); quit(1))
	call_deferred("_run")

func settle() -> void:
	for frame in 5: await process_frame

func _run() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	var helper = Verify.new()
	helper.fresh(app)
	app.show_screen(0)
	await settle()
	_check(app.current.presets.size() == 5 and app.current.earth.stage.orbit_paths.size() == 2, "SE dashboard retains presets and real orbit presentation")
	app.show_screen(2)
	await settle()
	helper.choose(app.current, "instrument", "instrument_advanced")
	app.state.launch_profile_id = "illustrative_alternative"
	app.state.launcher_id = "medium"
	app.state.budget = 120
	app.current.refresh()
	_check(Runtime.review(app.state).ready_to_launch, "Advanced part works with its valid alternative profile")
	app.show_screen(3)
	await settle()
	_check(app.current.validation.checks.profile_mass.threshold_g == 5000 and app.current.validation.checks.profile_mass.source_id == null, "Alternative profile keeps its own threshold and no NASA source claim")
	# Acknowledge fixture mission intent; engineering checks still run.
	assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
	app.current.next_button.pressed.emit()
	await settle()
	var operations = app.current
	var launch: Dictionary = operations.run_configuration.duplicate(true)
	var native: Dictionary = app.state.active_run_state.duplicate(true)
	operations.refresh()
	operations.refresh()
	_check(app.state.active_run_state == native, "Repeated presentation/prediction leaves native state unchanged")
	operations.take_action("power_save")
	_check(app.state.active_run_state.step_index == 1, "Manual action still works in SE Operations")
	operations.take_action("observe")
	_check(app.state.active_run_state.observations_completed == 1, "Manual Observe records an actual capture")
	_check(app.state.active_run_state.stored_data_mb == 24, "Manual Observe uses the selected advanced instrument")
	_check(operations.run_configuration == launch and app.state.active_run_state.config_snapshot == launch, "UI and engine preserve one launch config")
	app.show_screen(0)
	await settle()
	var saved_targets: Array = app.state.targets.duplicate()
	app.current.presets["Polar Ice Survey"].pressed.emit()
	_check(app.state.targets == saved_targets, "Mission preset cannot reset an operating run")
	app.flow_error.hide()
	app.show_screen(4)
	await settle()
	_check(app.state.active_run_state.step_index == 2, "Returning to Operations resumes its current state")
	app.current.skip_to_end()
	var id: String = app.state.active_run_state.run_id
	var recorded: Dictionary = app.state.evaluation_store.reports[id].duplicate(true)
	app.current.play()
	_check(app.state.active_run_state.step_index == 0, "SE replay controls still inspect the recorded trace")
	var denied: Dictionary = Runtime.take_action(app.state, "power_save")
	_check(not denied.ok and app.state.evaluation_store.reports[id] == recorded, "Replay cannot rewrite an already published run")
	app.abort_current_run("Must not alter an already recorded run")
	_check(app.state.evaluation_store.reports[id] == recorded, "Abort cannot contradict a previously published report")
	app.flow_error.hide()
	app.current.skip_to_end()
	app.show_screen(5)
	await settle()
	var baseline: Variant = app.state.evaluation_store.baseline.duplicate(true)
	var bad: Dictionary = app.state.active_run_state.duplicate(true)
	bad.run_id = "malformed_merge_check"
	bad.erase("config_snapshot")
	var reply: Dictionary = app.on_terminal_state(bad)
	_check(not reply.ok and app.state.evaluation_store.history.size() == 1, "Malformed evaluation does not create a report")
	_check(app.state.evaluation_store.baseline == baseline, "Evaluation error preserves the eligible baseline")
	app.start_new_mission()
	await settle()
	app.state.name = "Survey merge check"
	app.state.objective = "Survey Target Regions"
	app.state.targets = ["Arctic Ice", "Antarctic Region"]
	app.state.target_limit = 2
	app.state.orbit = "Polar – 600 km"
	app.state.observations = 2
	app.state.required_returned_data_mb = 24
	app.show_screen(3)
	await settle()
	_check(not app.current.next_button.disabled and app.current.warning_label.text.contains("score will be unavailable"), "Survey is usable with an explicit scoring limitation")
	# Acknowledge fixture mission intent; engineering checks still run.
	assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
	app.current.next_button.pressed.emit()
	await settle()
	app.current.skip_to_end()
	var final: Dictionary = app.state.active_run_state
	_check(final.observations_delivered_by_target.arctic_ice == 1 and final.observations_delivered_by_target.antarctic_region == 1, "Survey records full real deliveries for both regions")
	_check(not app.state.evaluation_store.reports.has(final.run_id) and app.state.evaluation_store.errors.has(final.run_id), "Current KE2 guard prevents an invented Survey score")
	app.show_screen(5)
	await settle()
	_check(app.current.results.text.contains("Survey scoring is not available yet") and app.current.get_presentation_model().state == "evaluation_error", "Results explain unsupported Survey scoring in player language")
	app.queue_free()
	await settle()
	print("Merged screen edge cases: %d checks passed; %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)
