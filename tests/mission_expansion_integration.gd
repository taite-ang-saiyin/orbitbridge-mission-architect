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
		assert(not Runtime.launch(draft).ok and not draft.has("run_trace"))
		assert(Copy.text(draft.objective, "my") != draft.objective)
		var app = load("res://scenes/Main.tscn").instantiate()
		root.add_child(app)
		app.preferences.language = "my"
		app.show_screen(0)
		for frame in 5: await process_frame
		app.current.presets[draft.objective].pressed.emit()
		for frame in 5: await process_frame
		assert(app.state.preset_id == id and app.state.goal == Runtime.config_for(app.state).mission.goal)
		app.show_screen(3)
		for frame in 8: await process_frame
		assert(app.current.next_button.disabled)
		assert(app.current.warning_label.text == Copy.text("Design checks are available. Launch and scoring for this mission are not available yet.", "my"))
		app.queue_free()
		for frame in 3: await process_frame
		print("PASS ", id, ": authored config, hardware, readiness, stale review, native launch gate and translated display")
	quit(0)
