extends SceneTree
func _initialize() -> void:
	call_deferred("check")
func settle() -> void:
	for frame in 6:
		await process_frame
func check() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	for resolution in [Vector2i(1280, 720), Vector2i(1024, 768)]:
		root.content_scale_size = resolution
		root.size = resolution
		app.show_screen(1)
		await settle()
		var creator = app.current
		assert(creator.progress_nav.get_parent() == (creator if creator.size.x < 1180 else creator.heading))
		assert(creator.progress_nav.get_child(1).button_pressed)
		assert(creator.progress_nav.get_child(0).complete)
		for step in creator.progress_nav.get_children():
			assert(step.size.y >= 50)
			assert(not step.caption.is_empty())
		assert(creator.scroll.get_child(0).size.x <= creator.scroll.size.x + 1)
		creator.name_input.text = ""
		creator.name_input.text_changed.emit("")
		assert(creator.next_button.disabled)
		creator.name_input.text = "Coastal Science"
		creator.name_input.text_changed.emit("Coastal Science")
		assert(not creator.next_button.disabled)
		creator.description_input.text = "A".repeat(215)
		creator.description_input.text_changed.emit()
		assert(app.state.description.length() == 200)
		assert(not creator.objective_buttons["Survey Target Regions"].disabled)
		assert(not creator.target_buttons["Arctic Ice"].disabled)
		creator.set_target_limit(1)
		assert(app.state.targets == ["Equator"])
		creator.observation_input.value = 8
		creator.budget_input.value = 150
		creator.duration_buttons[9].pressed.emit()
		assert(app.state.observations == 8 and app.state.budget == 150 and app.state.duration == 9)
		creator.next_button.pressed.emit()
		await settle()
		var builder = app.current
		assert(builder.screen_id == "SpacecraftBuilder")
		assert(builder.progress_nav.get_child(2).button_pressed)
		assert(builder.progress_nav.get_child(0).complete and builder.progress_nav.get_child(1).complete)
		assert(not builder.progress_nav.get_child(3).complete)
		assert("Coastal Science" in builder.summary.text)
		assert(builder.scroll.get_child(0).size.x <= builder.scroll.size.x + 1)
		for key in builder.ADAPTER.GROUPS:
			var selected = builder.ADAPTER.catalog(key)[1]
			builder.select_component(key, selected.id)
			assert(app.state[key] == selected.id)
			assert(selected.name in builder.selected_label.text)
		builder.auto_button.pressed.emit()
		assert(builder.preview.auto_rotate)
		builder.next_button.pressed.emit()
		await settle()
		assert(app.current.screen_id == "FlightReadiness")
		assert("Coastal Science" in app.current.summary.text)
		app.show_screen(1)
		await settle()
		assert(app.current.name_input.text == "Coastal Science")
		assert(app.state.body_id == "dev_body_2")
		print("PASS: creator rules, state round trip, satellite components, rotation and navigation at ", resolution)
	quit()
