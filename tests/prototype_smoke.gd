extends SceneTree
func _initialize():
	call_deferred("check")
func descendants(node: Node) -> Array[Node]:
	var found: Array[Node] = []
	for child in node.get_children():
		found.append(child)
		found.append_array(descendants(child))
	return found
func press(screen: Node, text: String):
	for node in descendants(screen):
		if node is Button and node.text == text:
			node.pressed.emit()
			return
	assert(false, "Missing button: " + text)
func check():
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	for resolution in [Vector2i(1280, 720), Vector2i(1024, 768)]:
		root.content_scale_size = resolution
		root.size = resolution
		for i in 6:
			app.show_screen(i)
			for frame in 4:
				await process_frame
			assert(app.host.get_child_count() == 1)
			assert(app.current.screen_id == app.SCREENS[i])
			assert(app.size.x <= resolution.x + 1)
			for node in descendants(app.current):
				if node is ScrollContainer:
					assert(node.get_child(0).size.x <= node.size.x + 1, "Horizontal overflow: " + app.current.screen_id)
			if i == 1:
				for node in descendants(app.current):
					if node is LineEdit and node.get_parent() is VBoxContainer:
						node.text = "Test Mission"
						node.text_changed.emit(node.text)
						break
				assert("Test Mission" in app.current.summary.text)
			if i == 2:
				app.current.select_component("body_id", "dev_body_2")
				assert(app.state.body_id == "dev_body_2")
				assert("1030 g" in app.current.total_values.text)
			if i == 4:
				press(app.current, "Step")
				assert(app.current.event_index == 1)
				press(app.current, "Play")
				app.current._process(8.0)
				assert(app.current.event_index > 1)
				press(app.current, "Pause")
				assert(not app.current.playing)
				press(app.current, "Skip to End")
				assert(app.current.event_index == app.current.DATA.EVENTS.size() - 1)
				assert("MB" in app.current.telemetry.text)
			if i == 5:
				app.current.show_run("Run B")
				assert("Score:" in app.current.results.text)
		print("PASS: screens, layout, inputs, components, playback, comparison at ", resolution)
	app.show_screen(2)
	press(app.current, "<  Back: Mission Creator")
	assert(app.current.screen_id == "MissionCreator")
	press(app.current, "Next: Spacecraft Builder  >")
	assert(app.current.screen_id == "SpacecraftBuilder")
	print("PASS: Back and Continue signals")
	quit()
