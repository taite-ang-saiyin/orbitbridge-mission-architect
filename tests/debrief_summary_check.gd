extends SceneTree
const Verify = preload("res://scripts/verification/demo_verification.gd")
const Summary = preload("res://scripts/presentation/DebriefSummary.gd")
var passed = 0
var failed = 0
var out: String

func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://exports/debrief-refine"
	DirAccess.make_dir_recursive_absolute(out)
	create_timer(45).timeout.connect(func(): printerr("FAIL: Debrief check timeout");quit(1))
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func settle() -> void:
	for i in 10: await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))

func run() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	root.mode = Window.MODE_WINDOWED
	root.min_size = Vector2i(640,480)
	Verify.new().fresh(app)
	app.state.name = "Equator watch"
	app.state.orbit = "LEO – 400 km"
	app.state.observations = 5
	app.state.duration = 6
	app.state.required_returned_data_mb = 60
	app.show_screen(4)
	await settle()
	app.current.skip_to_end()
	var raw: Dictionary = app.state.evaluation_store.reports[app.state.active_run_state.run_id].duplicate(true)
	check(raw.status == "partial" and raw.score == 87, "Native example produces actual partial/87")
	for size in [Vector2i(1440,900), Vector2i(1280,720), Vector2i(1024,768), Vector2i(900,680)]:
		root.size = size
		app.show_screen(5)
		await settle()
		var page = app.current
		check(page.goal_verdicts[0].text == "Reached", "Photo verdict explicit " + str(size))
		check(page.goal_verdicts[1].text == "Short by 15.68 MB", "Data shortfall explicit " + str(size))
		check(is_equal_approx(page.goal_bars[1].value, raw.data_return_completion_ratio * 100), "Progress uses supplied ratio " + str(size))
		check(page.score_label.text == "87 / 100", "Authoritative score retained " + str(size))
		check(page.score_gauge.score == raw.score, "Circular score uses supplied score " + str(size))
		check("All requested photos were taken" in page.results.text and not "5/5" in page.results.text, "Overview explains without repeating fraction totals " + str(size))
		check(page.full_explanation.text.contains(raw.explanation), "Unmodified producer explanation retained in log " + str(size))
		check(page.content.size.x <= page.report_scroll.size.x + 1, "No horizontal overflow " + str(size))
		if size.x >= 1280:
			check(page.report_scroll.get_global_rect().encloses(page.retry_button.get_global_rect()), "Primary Retry action visible without scrolling " + str(size))
		check(page.report_surface.get_global_rect().size.y <= page.report_body.get_combined_minimum_size().y + 55, "Report surface follows content instead of empty viewport " + str(size))
		check(page.get_presentation_model().report == raw, "View does not rewrite report " + str(size))
		await capture("debrief-" + str(size.x))
		page.select_report_tab(1)
		await settle()
		check(page.full_explanation.is_visible_in_tree() and page.evidence.is_visible_in_tree(), "Log exposes explanation/evidence " + str(size))
		page.select_report_tab(2)
		await settle()
		check(page.source_links.get_child_count() > 0, "Sources remain accessible " + str(size))
	check(app.state.evaluation_store.reports[raw.run_id] == raw, "Reentry and tabs retain exact report")
	var model: Dictionary = app.current.get_presentation_model()
	var before: Dictionary = model.duplicate(true)
	model.report.data_return_completion_ratio = 0.125
	check(Summary.build(model, app.state.run_trace).data.progress == 12.5, "Supplied ratio is not recomputed from displayed totals")
	model.report.erase("returned_data_mb")
	check(not Summary.build(model, app.state.run_trace).data.known, "Missing metric cannot claim reached/shortfall")
	model.state = "stale_report"
	var stale = Summary.build(model, app.state.run_trace)
	check(not stale.photos.known and not stale.data.progress_known and stale.text.is_empty(), "Rejected report produces no trusted verdicts")
	model = before.duplicate(true)
	model.report.run_status = "aborted"
	model.report.score = null
	check("ended early" in Summary.build(model, app.state.run_trace).text, "Abort remains separate from completed mission")
	check(model.report.score == null, "Display does not manufacture aborted score")
	app.queue_free()
	await settle()
	print("DEBRIEF SUMMARY: %s passed; %s failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
