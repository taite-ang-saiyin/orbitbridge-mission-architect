extends SceneTree

const Results = preload("res://scripts/integration/mission_results.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Catalog = preload("res://data/mock/DesignCatalog.gd")
const PACKET = "res://data/fixtures/se_d60d224_run_001/"
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("preview" if "--preview" in OS.get_cmdline_user_args() else "check")

func expect(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL " + message)

func settle() -> void:
	for frame in range(6):
		await process_frame

func check() -> void:
	var trace: Dictionary = {
		"config": read_json("config.json"), "final_state": read_json("final-state.json"),
		"events": read_json("events.json"), "validation": read_json("readiness.json"),
	}
	var provenance: Dictionary = read_json("provenance.json")
	for file in ["config.json", "final-state.json", "events.json", "readiness.json"]:
		expect(FileAccess.get_sha256(PACKET + file) == provenance.sha256[file], "packet hash " + file)
	var before: Dictionary = trace.duplicate(true)
	var evaluated: Dictionary = Results.evaluate_trace(trace)
	expect(evaluated.get("ok", false), "packet evaluation succeeds")
	var report: Dictionary = evaluated.get("report", {})
	expect(report.get("run_id") == "run_001" and report.get("mission_id") == "mission_local", "packet identity")
	expect(report.get("status") == "success" and report.get("score") == 100, "packet success score 100")
	expect(report.get("observations_completed") == 4 and report.get("required_observations") == 4, "packet captures")
	expect(report.get("returned_data_mb") == 48 and report.get("required_returned_data_mb") == 30, "packet returned actuals")
	expect(report.get("root_causes") == [] and report.get("source_ids") == [], "success preserves empty causes and report sources")
	expect(trace.events.size() == 61, "complete 61-event history")
	expect(Results.evaluate_trace(trace) == evaluated, "repeat evaluation stable")
	for field in before:
		expect(trace[field] == before[field], "packet input preserved " + field)
	var payload: Dictionary = Results.presentation(trace)
	expect(payload.state.events == trace.events, "presentation receives all ordered events")
	expect(payload.context.applicable_source_credits.size() == 1, "success receives exactly readiness credit")
	expect(payload.context.applicable_source_credits[0].credit_scope == "readiness", "readiness scope")
	expect(payload.context.applicable_source_credits[0].source_id == "cubesat_101_1u_sample", "readiness source resolves")
	var old_key: String = trace.evaluation_key
	var collision: Dictionary = before.duplicate(true)
	collision.config.mission.required_returned_data_mb = 60
	collision.final_state.config_snapshot = collision.config.duplicate(true)
	expect(Results.evaluate_trace(collision).report.score == 90, "same run ID different config gets own report")
	expect(collision.evaluation_key != old_key, "same-ID input fingerprint differs")
	var mismatched: Dictionary = before.duplicate(true)
	mismatched.events.pop_back()
	expect(not Results.evaluate_trace(mismatched).ok, "partial event history rejected")
	expect(not Results.evaluate_trace({"config": null, "events": null, "final_state": null}).ok, "malformed trace returns structured error")
	var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
	Catalog.ensure(draft)
	draft.name = "Valid 1U feasible baseline"
	draft.observations = 4
	draft.required_returned_data_mb = 30
	draft.orbit = "Polar – 600 km"
	var launched: Dictionary = Runtime.launch(draft)
	expect(launched.ok, "real KE1 and HPC launch")
	expect(draft.run_trace.evaluation.report.score == 100, "real launch evaluates in normal path")
	var original_run_id: String = draft.run_trace.final_state.run_id
	var history_before: Array = draft.run_history.duplicate(true)
	Runtime.publish_results(draft)
	Runtime.publish_results(draft)
	expect(draft.run_history == history_before, "duplicate terminal publication preserves history")
	var second_session: Dictionary = Catalog.DEFAULTS.duplicate(true)
	Catalog.ensure(second_session)
	Runtime.launch(second_session)
	expect(second_session.run_trace.final_state.run_id != original_run_id, "fresh sessions have distinct IDs")
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.state = draft
	for resolution in [Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(1440, 900)]:
		root.size = resolution
		app.show_screen(5)
		await settle()
		var page = app.current
		var model: Dictionary = page.report_view.get_debrief_model()
		expect(model.status == "success" and model.score == "100", "Results binds KE2 verdict at " + str(resolution))
		expect(model.returned == "48/30 MB", "Results preserves over-target actual")
		expect(page.report_view.get_input_snapshot().state.events == draft.run_trace.events, "Results evidence snapshot")
		expect(page.recent_runs.size.x >= 430, "Recent Runs retains readable columns")
		expect(page.recent_runs.get_column_width(1) >= 90 and page.recent_runs.get_column_width(2) >= 130, "numeric columns retain width")
		expect(page.content.size.x <= page.get_child(2).size.x + 1, "Results fits horizontal viewport")
		var count: int = draft.run_history.size()
		app.show_screen(5)
		await settle()
		expect(draft.run_history.size() == count, "reopening Results preserves history")
	var previous_trace: Dictionary = draft.run_trace.duplicate(true)
	expect(Runtime.retry(draft, previous_trace).ok, "Retry revalidates and launches")
	expect(draft.run_trace.final_state.run_id != original_run_id, "Retry creates new run ID")
	expect(draft.comparison_baseline.run_id == original_run_id, "Retry preserves completed baseline")
	expect(draft.run_trace.events[0].event_id == "evt_000", "Retry resets event sequence")
	var error_history: Array = draft.run_history.duplicate(true)
	var unsupported: Dictionary = draft.run_trace.duplicate(true)
	unsupported.config.mission.objective = "survey"
	unsupported.final_state.config_snapshot = unsupported.config.duplicate(true)
	draft.run_trace = unsupported
	var unsupported_result: Dictionary = Runtime.publish_results(draft)
	expect(not unsupported_result.ok and unsupported_result.error.field_path == "config.mission.objective", "Survey returns evaluator error")
	expect(draft.run_history == error_history, "evaluation error preserves history")
	app.show_screen(5)
	await settle()
	expect(app.current.report_view.get_debrief_model().presentation_state == "evaluation_error", "Results shows error and correction")
	Catalog.reset(draft)
	expect(not draft.has("comparison_baseline") and not draft.has("run_history"), "New Mission clears baseline and history")
	app.queue_free()
	var out_dir: String = "res://docs/handoffs/se-d60d224-run001"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var output = FileAccess.open(out_dir + "/evaluation-v0.1.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(evaluated, "\t", true, true) + "\n")
	output.close()
	var context_file = FileAccess.open(out_dir + "/context-v0.1.json", FileAccess.WRITE)
	context_file.store_string(JSON.stringify(payload.context, "\t", true, true) + "\n")
	context_file.close()
	print("KE2 Results integration: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)

func preview() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
	Catalog.ensure(draft)
	draft.name = "Valid 1U feasible baseline"
	draft.observations = 4
	draft.required_returned_data_mb = 30
	draft.orbit = "Polar – 600 km"
	Runtime.launch(draft)
	app.state = draft
	app.show_screen(5)
	await settle()
	var directory: String = "res://docs/handoffs/se-d60d224-run001/evidence"
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/results-1280x720.png")
	var scroll: ScrollContainer = app.current.get_child(2)
	scroll.ensure_control_visible(app.current.report_view)
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/report-1280x720.png")
	app.current.report_view._credits_button.pressed.emit()
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/credits-1280x720.png")
	print("PASS rendered Results, report and scoped credits at 1280x720")
	quit(0)

func read_json(file: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(PACKET + file))
