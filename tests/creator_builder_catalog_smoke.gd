extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
func _initialize() -> void: call_deferred("check")
func settle() -> void:
	for frame in 8: await process_frame
func choose(page: Node, slot: String, id: String) -> void:
	var select: OptionButton = page.engineering_selectors[slot]
	for i in select.item_count:
		if select.get_item_metadata(i) == id:
			select.select(i)
			select.item_selected.emit(i)
			return
	assert(false, "Missing catalog component " + id)
func check() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	for resolution in [Vector2i(1024, 768), Vector2i(1440, 900)]:
		root.size = resolution
		if app.is_operating():
			app.abort_current_run("End previous test iteration")
			await settle()
		app.start_new_mission()
		await settle()
		app.current.name_input.text_changed.emit("Independent engineering trial")
		app.current.observation_input.value = 4
		app.current.returned_data_input.value = 30
		app.current.observation_input.value = 5
		assert(app.state.required_returned_data_mb == 30)
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.show_screen(2)
		await settle()
		var builder = app.current
		assert(builder.engineering_selectors.size() == 6)
		assert(builder.content.size.x <= builder.scroll.size.x + 1)
		assert("1060 g" in builder.total_values.text)
		choose(builder, "instrument", "instrument_advanced")
		var reviewed: Dictionary = Runtime.review(app.state)
		assert(reviewed.metrics.total_mass_g == 1380 and reviewed.metrics.total_cost_credits == 96)
		assert(not reviewed.ready_to_launch)
		assert(reviewed.config.mission.required_returned_data_mb == 30)
		app.state.launch_profile_id = "illustrative_alternative"
		app.state.launcher_id = "medium"
		app.state.budget = 120
		builder.refresh()
		assert(Runtime.review(app.state).ready_to_launch)
		choose(builder, "battery", "battery_large")
		var changed: Dictionary = Runtime.review(app.state)
		assert(changed.metrics.battery_capacity_wh == 50 and changed.metrics.initial_energy_wh == 50)
		assert(changed.config.design.instrument_id == "instrument_advanced")
		choose(builder, "battery", "battery_standard")
		choose(builder, "storage", "storage_large")
		assert(Runtime.review(app.state).metrics.storage_capacity_mb == 256)
		choose(builder, "storage", "storage_standard")
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		builder.next_button.pressed.emit()
		await settle()
		assert(not app.current.next_button.disabled)
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.current.next_button.pressed.emit()
		await settle()
		assert(app.current.screen_id == "MissionOperations")
		assert(app.state.run_design.design.instrument_id == "instrument_advanced")
		assert(app.state.run_trace.validation.ready_to_launch)
		assert(app.state.run_design.mission.required_returned_data_mb == 30)
		print("PASS six independent catalog slots, source metrics, power/storage, profile switching and validated launch at ", resolution)
	# A stale successful review cannot authorize a changed over-budget design.
	app.state.budget = 60
	var loaded: Dictionary = Runtime.load_game_catalogs()
	var blocked: Dictionary = preload("res://core/MissionStepEngine.gd").init_validated_run(Runtime.config_for(app.state), loaded.catalogs, "must_not_start", "mission_test")
	assert(not blocked.ok and not blocked.validation_result.ready_to_launch)
	print("PASS upstream HPC validated entry point blocks stale launch permission")
	app.queue_free()
	quit(0)
