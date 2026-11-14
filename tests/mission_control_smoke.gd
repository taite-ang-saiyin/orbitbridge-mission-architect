extends SceneTree
func _initialize() -> void: call_deferred("check")
func settle() -> void:
	for frame in 8: await process_frame
func check() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	for resolution in [Vector2i(1024, 768), Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		app.show_screen(0)
		await settle()
		var page = app.current
		assert(page.screen_id == "MissionControl")
		assert(page.content.size.x <= page.scroll.size.x + 1, "Mission Control overflows horizontally")
		var heading = page.get_child(0)
		assert(heading.size.y <= 45, "Header grows vertically from collapsed text")
		assert(heading.get_child(1).size.y <= 30 and heading.get_child(1).size.x >= 90, "Local status must remain on one line")
		assert(page.scroll.position.y < 60, "Dashboard pushed down by oversized header")
		assert(page.presets.size() == 3)
		assert("No completed missions" in page.recent_text.text)
		assert(page.earth.stage.orbit_paths.size() == 2)
		page.presets["Polar Ice Survey"].pressed.emit()
		await settle()
		assert(app.current.screen_id == "MissionCreator")
		assert(app.state.targets == ["Arctic Ice"] and app.state.objective == "Survey Target Regions")
		assert(app.state.orbit == "Polar – 600 km")
		app.show_screen(0)
		await settle()
		app.current.quick_start.pressed.emit()
		await settle()
		assert(app.current.screen_id == "MissionCreator" and app.state.name == "Untitled Mission")
		print("PASS Mission Control dashboard, preset routing and new mission at ", resolution)
	app.queue_free()
	quit(0)
