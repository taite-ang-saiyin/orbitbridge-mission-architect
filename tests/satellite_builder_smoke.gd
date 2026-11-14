extends SceneTree
func _initialize() -> void:
	call_deferred("check")
func settle() -> void:
	for frame in 8: await process_frame
func check() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.show_screen(2)
	await settle()
	var builder = app.current
	for key in builder.ADAPTER.GROUPS:
		for option in builder.ADAPTER.catalog(key):
			builder.select_component(key, option.id)
			assert(app.state[key] == option.id)
			assert(builder.preview.satellite_ids[key] == option.id)
			assert(builder.preview.model.get_child_count() > 0)
			assert(app.state.validated_design.selected_ids[key] == option.id)
	builder.select_component("body_id", "missing")
	assert(builder.next_button.disabled)
	assert(not builder.group_messages.body_id.text.is_empty())
	builder.reset_design()
	assert(not builder.next_button.disabled)
	for key in builder.ADAPTER.STARTER: assert(app.state[key] == builder.ADAPTER.STARTER[key])
	builder.select_component("wings_id", "dev_wings_3")
	app.show_screen(1)
	await settle()
	app.show_screen(2)
	await settle()
	assert(app.state.wings_id == "dev_wings_3")
	app.current.next_button.pressed.emit()
	await settle()
	assert(app.current.screen_id == "FlightReadiness")
	assert(app.current.preview.satellite_ids.wings_id == "dev_wings_3")
	var reviewed = app.state.validated_design.duplicate(true)
	app.current.next_button.pressed.emit()
	await settle()
	assert(app.state.run_design == reviewed.validation.config)
	assert(app.current.screen_id == "MissionOperations")
	assert(app.current.run_configuration == reviewed.validation.config)
	assert(app.current.orbit_view.stage.craft.get_node("ModelSlot").selected_ids == reviewed.selected_ids)
	print("PASS: nine assets, correct slots and IDs, validation, blockers, reset, navigation and run handoff")
	quit()
