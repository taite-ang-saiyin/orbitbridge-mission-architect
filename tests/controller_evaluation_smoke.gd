extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
const Step = preload("res://core/MissionStepEngine.gd")
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
func _initialize() -> void: call_deferred("check")
func settle() -> void:
	for frame in 6: await process_frame
func check() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/valid_1u_feasible.json"))
	var loaded: Dictionary = Runtime.load_game_catalogs()
	var built: Dictionary = preload("res://core/HPCContractAdapter.gd").build_scenario(loaded.catalogs, loaded.catalogs.orbit_catalog)
	var native: Dictionary = Step.init_run(config, built.scenario, "se_reference_reproduction_01", "se_reference_mission").state
	assert(not Evaluator.evaluate_hpc_state(native).ok)
	while native.phase != "finished":
		var action: String = "observe" if native.step_index == 1 else ("transmit" if native.step_index == 7 else "power_save")
		native = Step.request_action(native, action).state
	var evaluation: Dictionary = Evaluator.evaluate_hpc_state(native)
	assert(evaluation.ok and evaluation.report.status == "partial" and evaluation.report.score == 25)
	assert(evaluation.report.observations_completed == 1 and is_equal_approx(evaluation.report.returned_data_mb, 7.7333333328))
	var evidence: Dictionary = {"kind": "local_reproduction_not_original_ke3_handoff", "evaluator_base": "f313e6fbf5c0eed7f67885edb45ce5ba45b85bba", "native_state": native, "validation": preload("res://scripts/core/mission_validator.gd").validate(config, loaded.catalogs), "report": evaluation.report}
	var file: FileAccess = FileAccess.open("res://docs/integration-evidence/controller-reference-reproduction.json", FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(evidence, "  "))
	file.close()
	print("REFERENCE REPRODUCTION ", native.run_id, ": ", JSON.stringify(evaluation.report))
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
	app.show_screen(3)
	await settle()
	assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
	app.current.next_button.pressed.emit()
	await settle()
	var id: String = app.state.run_trace.final_state.run_id
	assert(app.state.active_run_state.step_index == 0 and app.state.active_run_state.event_log.is_empty())
	app.current.skip_to_end()
	assert(app.state.evaluation_store.history.size() == 1)
	var original: Dictionary = app.state.evaluation_store.duplicate(true)
	app.on_terminal_state(app.state.run_trace.final_state)
	assert(app.state.evaluation_store == original)
	app.show_screen(5)
	await settle()
	assert("Score:" in app.current.results.text and "NASA CubeSat 101" in app.current.results.text)
	app.show_screen(5)
	await settle()
	assert(app.state.evaluation_store == original)
	assert(app.state.evaluation_store.history[0].validation == app.state.run_trace.validation)
	assert(Results.baseline_for(app.state, app.state.run_trace.config) != null)
	var bad: Dictionary = app.state.run_trace.final_state.duplicate(true)
	bad.run_id = "bad_input_run"
	bad.erase("config_snapshot")
	assert(not app.on_terminal_state(bad).ok)
	assert(app.state.evaluation_store.history == original.history)
	assert(app.state.evaluation_store.baseline == original.baseline)
	assert(press(app.current, "Retry Mission"))
	await settle()
	assert(app.state.run_trace.final_state.run_id != id)
	assert(app.state.active_run_state.step_index == 0 and app.state.active_run_state.observations_completed == 0)
	assert(app.state.active_run_state.event_log.is_empty())
	assert(app.state.evaluation_store.baseline == original.baseline)
	app.current.step()
	assert(press(app.current, "Abort Mission"))
	await settle()
	var aborted_report: Dictionary = app.state.evaluation_store.reports[app.state.active_run_state.run_id]
	assert(aborted_report.run_status == "aborted" and aborted_report.score == null)
	assert(app.state.evaluation_store.history.size() == 2)
	assert(app.state.evaluation_store.baseline == original.baseline)
	app.state.objective = "Survey Target Regions"
	assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
	assert(press(app.current, "Retry Mission"))
	await settle()
	app.current.skip_to_end()
	app.show_screen(5)
	await settle()
	assert("Scoring is currently unavailable for survey missions" in app.current.results.text)
	assert(not "KE2" in app.current.results.text and not "HPC" in app.current.results.text)
	assert(app.state.evaluation_store.history.size() == 2 and app.state.evaluation_store.baseline == original.baseline)
	assert(press(app.current, "Start New Mission"))
	await settle()
	assert(not app.state.has("evaluation_store") and not app.state.has("run_trace"))
	print("PASS controller Launch/terminal/Results/Retry/Abort/New Mission; one report per ID; history, source validation and baseline retained")
	app.queue_free()
	quit(0)

func press(node: Node, text: String) -> bool:
	for child in node.get_children():
		if child is Button and child.text == text:
			child.pressed.emit()
			return true
		if press(child, text): return true
	return false
