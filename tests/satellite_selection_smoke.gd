extends SceneTree
func _initialize(): call_deferred("check")
func settle():
	for i in 10: await process_frame
func check():
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	for number in range(1, 4):
		app.show_screen(2)
		await settle()
		var id = "dev_body_" + str(number)
		app.current.select_component("body_id", id)
		app.show_screen(1)
		await settle()
		app.show_screen(2)
		await settle()
		assert(app.state.body_id == id)
		assert(app.current.option_buttons[id].button_pressed)
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.current.next_button.pressed.emit()
		await settle()
		assert(app.current.preview.model.selected_ids.body_id == id)
		if number == 3:
			app.state.launch_profile_id = "illustrative_alternative"
			app.state.launcher_id = "medium"
			app.state.budget = 120
			app.show_screen(3)
			await settle()
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.current.next_button.pressed.emit()
		await settle()
		assert(app.current.run_configuration.design.bus_id == app.state.run_design.design.bus_id)
		assert(app.current.orbit_view.stage.craft.get_node("ModelSlot").selected_ids.body_id == id)
		app.current.skip_to_end()
	app.show_screen(2)
	await settle()
	app.current.reset_design()
	assert(app.state.body_id == "dev_body_1")
	print("PASS: three reference bodies, persistence, Readiness and Operations consistency, reset")
	quit()
