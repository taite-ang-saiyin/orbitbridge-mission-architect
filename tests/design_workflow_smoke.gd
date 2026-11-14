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
		app.state.erase("mission_review_snapshot")
		app.show_screen(1)
		await settle()
		var creator = app.current
		assert(creator.form_columns.get_child_count() == 2)
		assert(creator.coverage_frame.size.y >= 320)
		assert(creator.summary_column == null, "Creator must not show an inline summary panel")
		assert(creator.scroll.get_child(0).size.x <= creator.scroll.size.x + 1)
		var tallest_content: float = 0
		for card in creator.target_buttons.values():
			tallest_content = maxf(tallest_content, card.get_child(0).get_combined_minimum_size().y)
		for card in creator.target_buttons.values():
			assert(card.size.y <= tallest_content + 1, "Target cards must fit the tallest caption without empty padding")
			for label in card.find_children("*", "Label", true, false):
				assert(label.get_global_rect().end.y <= card.get_global_rect().end.y + 1, "Target caption must fit inside its card")
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
		creator.toggle_target("Tropical Forest")
		assert("Tropical Forest" in app.state.targets)
		creator.set_target_limit(2)
		creator.toggle_target("Coastal Region")
		assert(app.state.targets == ["Tropical Forest", "Coastal Region"])
		creator.set_target_limit(1)
		creator.toggle_target("Equator")
		creator.observation_input.value = 8
		creator.budget_input.value = 150
		creator.duration_buttons[9].pressed.emit()
		assert(app.state.observations == 8 and app.state.budget == 150 and app.state.duration == 9)
		creator.next_button.pressed.emit()
		await settle()
		assert(creator.review_dialog.visible and creator.review_dialog.continue_button.disabled)
		creator.review_dialog.acknowledgement.button_pressed = true
		creator.review_dialog.continue_button.pressed.emit()
		await settle()
		var builder = app.current
		assert(builder.screen_id == "SpacecraftBuilder")
		assert("Coastal Science" in builder.summary.text)
		assert(builder.scroll.get_child(0).size.x <= builder.scroll.size.x + 1)
		for key in builder.ADAPTER.GROUPS:
			var selected = builder.ADAPTER.catalog(key)[1]
			builder.select_component(key, selected.id)
			assert(app.state[key] == selected.id)
			assert(selected.name in builder.selected_label.text)
			assert(not "Gameplay" in builder.group_messages[key].text)
			assert(not "bus_" in builder.group_messages[key].text)
			assert("·" in builder.group_messages[key].text)
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
