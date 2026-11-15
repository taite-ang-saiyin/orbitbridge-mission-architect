extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Review = preload("res://scripts/integration/mission_review.gd")
const Copy = preload("res://scripts/settings/MyanmarText.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for id in ["communication", "weather_monitoring"]:
		var draft: Dictionary = preload("res://data/mock/DesignCatalog.gd").DEFAULTS.duplicate(true)
		assert(Runtime.select_preset(draft, id).ok)
		var config: Dictionary = Runtime.config_for(draft)
		assert(config.schema_version == 2 and config.preset_id == id)
		assert(config.mission.objective == id and config.mission.goal == draft.goal)
		var reviewed: Dictionary = Runtime.review(draft)
		assert(reviewed.ready_to_launch)
		assert(reviewed.metrics.total_mass_g == (1120 if id == "communication" else 1060))
		assert(reviewed.metrics.total_cost_credits == (89 if id == "communication" else 82))
		assert(Review.confirm(draft, Review.snapshot(draft)))
		draft.goal["required_positive_contact_steps" if id == "communication" else "required_distinct_orbits"] = 3
		assert(not Review.is_confirmed(draft))
		draft.goal["required_positive_contact_steps" if id == "communication" else "required_distinct_orbits"] = 2
		var launched: Dictionary = Runtime.launch(draft)
		if not launched.ok:
			print(launched); quit(1); return
		assert(draft.run_trace.config == Runtime.config_for(draft))
		assert(Copy.text(draft.objective, "my") != draft.objective)
		var app = load("res://scenes/Main.tscn").instantiate()
		root.add_child(app)
		app.preferences.language = "my"
		app.show_screen(0)
		assert(not app.find_child("LanguageSettings", true, false).visible)
		for frame in 5: await process_frame
		app.current.presets[draft.objective].pressed.emit()
		for frame in 5: await process_frame
		assert(app.state.preset_id == id and app.state.goal == Runtime.config_for(app.state).mission.goal)
		app.show_screen(3)
		for frame in 8: await process_frame
		assert(not app.current.next_button.disabled)
		assert(Copy.text("This mission can fly. Scoring is not available yet.", "my") in app.current.warning_label.text)
		assert(Review.confirm(app.state, Review.snapshot(app.state)))
		assert(Runtime.launch(app.state).ok)
		app.show_screen(4)
		for frame in 8: await process_frame
		assert(app.current.screen_id == "MissionOperations")
		assert(app.find_child("LanguageSettings", true, false).visible)
		check_copy(app.current)
		app.state.active_run_state = app.state.run_trace.final_state.duplicate(true)
		app.show_screen(5)
		for frame in 8: await process_frame
		assert(app.current.screen_id == "DebriefCompare")
		var progress: Dictionary = app.current.get_goal_progress()
		assert(progress.primary.known and progress.primary.actual == app.state.run_trace.final_state.goal_progress.actual_count)
		assert(progress.primary.required == 2)
		check_copy(app.current)
		app.queue_free()
		for frame in 3: await process_frame
		print("PASS ", id, ": authored config, hardware, readiness, stale review, native flight and translated display")
	quit(0)

func check_copy(node: Node) -> void:
	if node is Label or node is Button:
		var owners = RegEx.new()
		owners.compile("(?i)\\b(?:KE[123]|HPC|SE)\\b")
		assert(owners.search(node.text) == null)
	for child in node.get_children(): check_copy(child)
