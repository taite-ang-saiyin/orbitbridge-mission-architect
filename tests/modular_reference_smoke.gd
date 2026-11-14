extends SceneTree
func _initialize(): call_deferred("check")
func settle():
	for i in 6: await process_frame
func check():
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
	app.show_screen(2)
	await settle()
	var builder = app.current
	for body in builder.ADAPTER.catalog("body_id"):
		for wings in builder.ADAPTER.catalog("wings_id"):
			for radio in builder.ADAPTER.catalog("radio_id"):
				for entry in [["body_id",body.id],["wings_id",wings.id],["radio_id",radio.id]]:
					var before = builder.preview.model.get_node_or_null(NodePath("body_id"))
					builder.select_component(entry[0],entry[1])
					assert(app.state[entry[0]] == entry[1])
					assert(builder.preview.satellite_ids[entry[0]] == entry[1])
					if entry[0] != "body_id": assert(builder.preview.model.get_node("body_id") == before)
				assert(builder.preview.model.get_child_count() == 3)
				assert(builder.preview.group_bounds.size() == 3)
	app.state.launch_profile_id = "illustrative_alternative"
	app.state.launcher_id = "medium"
	app.state.budget = 150
	assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
	builder.next_button.pressed.emit()
	await settle()
	assert(app.current.preview.model.selected_ids == app.state.validated_design.selected_ids)
	assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
	app.current.next_button.pressed.emit()
	await settle()
	assert(app.current.orbit_view.stage.craft.get_node("ModelSlot").selected_ids == app.state.validated_design.selected_ids)
	print("PASS: 27 reference part combinations, isolated replacement and run consistency")
	quit()
