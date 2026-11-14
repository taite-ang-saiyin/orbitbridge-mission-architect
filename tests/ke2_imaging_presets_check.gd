extends SceneTree
## KE2 regression: actual preset buttons -> native run -> published report -> Debrief.
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
const OUTPUT = "res://exports/check-logs/ke2_imaging_presets.json"
var passed: int = 0
var failed: int = 0
var cases: Array = []

func _initialize() -> void:
	create_timer(45).timeout.connect(func(): printerr("FAIL Imaging preset timeout"); quit(1))
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		printerr("FAIL " + message)

func settle() -> void:
	for frame in 8:
		await process_frame

func run() -> void:
	for entry in [
		["Estuary Watch", "coastal_region", "high_inc", 60.0, 100, "success", [2.0, 5.0], [0.0, 7.0]],
		["Tropical Forest Watch", "tropical_forest", "low_eq", 44.3200000032, 87, "partial", [2.0], [8.0]],
	]:
		await run_preset(entry)
	DirAccess.make_dir_recursive_absolute("res://exports/check-logs")
	var file = FileAccess.open(OUTPUT, FileAccess.WRITE)
	check(file != null, "Evidence file writable")
	if file != null:
		file.store_string(JSON.stringify({
			"engine": Engine.get_version_info().string,
			"verification": "Actual preset buttons, integrated native modules and headless Debrief nodes; no exported browser run.",
			"passed": passed, "failed": failed, "cases": cases,
		}, "\t", true, true) + "\n")
	print("KE2 IMAGING PRESETS: %d passed; %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func run_preset(entry: Array) -> void:
	var title: String = entry[0]
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.show_screen(0)
	await settle()
	check(app.current.presets.has(title), title + " actual card exists")
	if not app.current.presets.has(title):
		app.queue_free()
		await settle()
		return
	app.current.presets[title].pressed.emit()
	await settle()
	check(app.current.screen_id == "MissionCreator" and app.state.name == title, title + " routes to Creator")
	# Use the card's untouched default hardware, policy, goals and orbit.
	app.show_screen(4)
	await settle()
	if not app.state.has("run_trace"):
		check(false, title + " actual launch failed")
		app.queue_free()
		await settle()
		return
	check(app.state.run_trace.validation.ready_to_launch, title + " native readiness")
	check(not app.state.has("evaluation_store"), title + " no future report published")
	app.current.skip_to_end()
	var trace: Dictionary = app.state.run_trace
	var frozen: Dictionary = trace.duplicate(true)
	var config: Dictionary = trace.config
	var final: Dictionary = trace.final_state
	check(config.mission.objective == "imaging" and config.mission.title == title, title + " Imaging config")
	check(config.mission.target_region == entry[1] and config.mission.target_regions == [entry[1]], title + " own target")
	check(config.design.orbit_id == entry[2], title + " own orbit")
	check(config.mission.required_observations == 5 and config.mission.required_returned_data_mb == 60, title + " independent 5-capture / 60-MB thresholds")
	check(config.mission.duration_orbits == 6 and final.total_steps == 60, title + " six-orbit schedule")
	var orbit: Dictionary = {}
	for candidate: Dictionary in final.scenario_snapshot.orbits:
		if candidate.id == entry[2]:
			orbit = candidate
	check(orbit.get("target_windows", {}).get(entry[1]) == entry[6] and orbit.get("ground_contact_windows") == entry[7], title + " pinned own target/contact windows")
	check(orbit.get("steps_per_orbit") == 10 and absf(float(orbit.get("step_duration_hours", 0.0)) - (0.1611111111 if entry[2] == "high_inc" else 0.1538888889)) < 1e-12, title + " pinned timing")
	check(app.state.active_run_state.run_status == "completed" and app.state.active_run_state.step_index == 60, title + " reached actual terminal state")
	var reply: Dictionary = Evaluator.evaluate_mission(config, final, trace.events)
	check(reply.get("ok", false), title + " evaluates")
	if not reply.get("ok", false):
		app.queue_free()
		await settle()
		return
	var report: Dictionary = reply.report
	check(report.observations_completed == 5 and final.observations_by_target.get(entry[1]) == 5, title + " actual selected-target captures")
	check(absf(report.returned_data_mb - float(entry[3])) < 1e-8, title + " pinned actual returned MB")
	check(absf(final.stored_data_mb + final.returned_data_mb - 60.0) < 1e-8, title + " packet conservation")
	check(report.status == entry[5] and report.score == entry[4], title + " literal status and score")
	check(report.observation_completion_ratio == 1.0 and absf(report.data_return_completion_ratio - float(entry[3]) / 60.0) < 1e-8, title + " independent goal ratios")
	var transmitted: float = 0.0
	var sends: Array = []
	for event: Dictionary in trace.events:
		if event.get("type") == "action_accepted" and event.get("action") == "transmit":
			transmitted += float(event.get("delta_returned_data_mb", 0.0))
			sends.append(event.duplicate(true))
	check(absf(transmitted - report.returned_data_mb) < 1e-8, title + " Earth-return event reconciliation")
	check(Evaluator.evaluate_mission(config, final, trace.events) == reply and trace == frozen, title + " deterministic input-preserving evaluation")
	check(app.state.evaluation_store.reports[final.run_id] == report, title + " published native report")
	var history: Dictionary = app.state.evaluation_store.duplicate(true)
	check(Results.publish(app.state, final).get("existing", false) and app.state.evaluation_store == history, title + " publication idempotent")
	app.show_screen(5)
	await settle()
	var page = app.current
	check(page.get_presentation_model().report == report, title + " Debrief bound to unchanged report")
	check(page.photo_goal_value.text == "5 / 5" and page.data_goal_value.text == ("60 / 60 MB" if entry[2] == "high_inc" else "44.32 / 60 MB"), title + " Debrief actuals and goal labels")
	check(page.goal_verdicts[0].text == "Reached" and (page.goal_verdicts[1].text == "Reached" if entry[5] == "success" else page.goal_verdicts[1].text.begins_with("Short by ")), title + " separate goal verdicts")
	check(page.score_label.text == "%d / 100" % int(entry[4]) and page.outcome_badge.text == ("SUCCESS" if entry[5] == "success" else "PARTIAL RESULT"), title + " authoritative score and outcome")
	cases.append({"preset": title, "config": config.duplicate(true),
		"scenario_version": final.scenario_snapshot.scenario_version, "orbit": orbit.duplicate(true), "policy": trace.policy,
		"report": report.duplicate(true), "stored_data_mb": final.stored_data_mb,
		"positive_transmit_events": sends,
		"debrief": {"photos": page.photo_goal_value.text, "data": page.data_goal_value.text,
			"photo_verdict": page.goal_verdicts[0].text, "data_verdict": page.goal_verdicts[1].text,
			"score": page.score_label.text, "outcome": page.outcome_badge.text}})
	print("MEASURED %s: %s captures, %.10f returned MB, %.10f stored MB, %s / %s" % [title, report.observations_completed, report.returned_data_mb, final.stored_data_mb, report.status, report.score])
	app.queue_free()
	await settle()
