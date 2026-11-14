extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Catalog = preload("res://data/mock/DesignCatalog.gd")
func _initialize() -> void:
	call_deferred("check")
func settle() -> void:
	for frame in 8: await process_frame
func check() -> void:
	var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
	Catalog.ensure(draft)
	draft.targets = ["Arctic Ice", "Antarctic Region"]
	draft.objective = "Survey Target Regions"
	draft.observations = 2
	assert(not Runtime.review(draft).ready_to_launch, "LEO must not grant polar target access")
	draft.orbit = "Polar – 600 km"
	assert(Runtime.review(draft).ready_to_launch)
	for duration in [3, 6, 9]:
		for objective in ["Capture Imagery", "Survey Target Regions"]:
			draft.duration = duration
			draft.objective = objective
			var run: Dictionary = Runtime.launch(draft)
			assert(run.ok)
			var final: Dictionary = run.trace.final_state
			assert(final.total_steps == duration * 10 and final.step_index == duration * 10)
			assert(final.observations_completed == 2)
			assert(final.observations_by_target.arctic_ice == 1 and final.observations_by_target.antarctic_region == 1)
			assert(final.observations_delivered_by_target.arctic_ice == 1 and final.observations_delivered_by_target.antarctic_region == 1)
			var returned: float = 0.0
			for value in final.returned_data_by_target_mb.values(): returned += value
			assert(is_equal_approx(returned, final.returned_data_mb))
			assert(is_equal_approx(final.stored_data_mb + final.returned_data_mb, 24.0))
			assert(is_equal_approx(final.returned_data_mb, 24.0))
	draft.observations = 1
	assert(not Runtime.review(draft).ready_to_launch)
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	for resolution in [Vector2i(1024, 768), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		app.show_screen(1)
		await settle()
		var creator = app.current
		assert(not creator.objective_buttons["Survey Target Regions"].disabled)
		for button in creator.target_buttons.values(): assert(not button.disabled)
		creator.objective_buttons["Survey Target Regions"].pressed.emit()
		creator.set_target_limit(2)
		creator.toggle_target("Arctic Ice")
		creator.toggle_target("Antarctic Region")
		assert(app.state.targets.size() == 2)
		creator.coverage_view.orbit_selected.emit("high_inc")
		assert(app.state.orbit == "Polar – 600 km" and creator.orbit_select.selected == 1)
		assert(is_equal_approx(creator.coverage_view.stage.get_node("OrbitPlane").rotation_degrees.z, 97.8))
		assert(creator.coverage_view.stage.orbit_paths.size() == 2)
		creator.budget_input.value = 120
		assert(app.state.budget == 120)
		var ticks = creator.budget_ticks
		var inset: float = creator.budget_input.get_theme_icon("grabber").get_width() * 0.5
		assert(is_equal_approx(ticks.position_for(120), inset + (creator.budget_input.size.x - 2 * inset) * 2.0 / 3.0))
		assert(creator.content.size.x <= creator.scroll.size.x + 1)
		for duration in [3, 6, 9]:
			creator.duration_buttons[duration].pressed.emit()
			creator.coverage_view.set_preview_playing(false)
			creator.coverage_view.set_frame(1.0, "MISSION_FINISHED")
			assert(is_equal_approx(creator.coverage_view.stage.unwrapped_angle, duration * TAU))
		# Exercise actual camera input, not only programmatic configuration.
		var zoom: float = creator.coverage_view.stage.view_zoom
		var wheel = InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.pressed = true
		creator.coverage_view.interact(wheel)
		assert(creator.coverage_view.stage.view_zoom < zoom)
		print("PASS selectable missions/targets, source orbit inclination, full orbit count, budget scale and interaction at ", resolution)
	print("PASS multi-target conservation, survey requirements, LEO/polar compatibility and 3/6/9 orbit runs")
	app.queue_free()
	quit(0)
