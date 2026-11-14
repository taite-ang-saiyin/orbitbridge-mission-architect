extends SceneTree
func _initialize() -> void:
	call_deferred("check")
func settle() -> void:
	for frame in 8:
		await process_frame
func check_model(preview: Control) -> void:
	preview.zoom = 1.0
	preview.update_camera()
	var dimensions = Vector2(preview.get_node("SubViewport").size)
	var safe = Rect2(Vector2.ONE * 2, dimensions - Vector2.ONE * 4)
	for point in preview.framing_points():
		assert(not preview.camera.is_position_behind(point))
		var projected = preview.camera.unproject_position(point)
		assert(safe.has_point(projected), "Model clipped at " + str(dimensions) + ": " + str(projected))
func check() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	for index in [-1, 1, 2]:
		if index == -1:
			app.show_home()
		else:
			app.show_screen(index)
		for resolution in [Vector2i(1440, 900), Vector2i(1024, 768), Vector2i(1920, 1080), Vector2i(3360, 2100), Vector2i(1280, 720), Vector2i(1440, 900)]:
			root.size = resolution
			await settle()
			assert(app.size.is_equal_approx(root.get_visible_rect().size), "Layout must fill the scaled viewport")
			var page = app.current
			var bounds = Rect2(Vector2.ZERO, app.size)
			if index == -1:
				for button in [page.start, page.settings, page.quit]:
					assert(bounds.encloses(button.get_global_rect()))
					assert(button.size.y >= 44)
			else:
				assert(page.content.size.x <= page.scroll.size.x + 1, "Horizontal content overflow")
				assert(bounds.encloses(page.next_button.get_global_rect()))
				assert(page.next_button.size.y >= 44)
				if index == 1: assert((page.summary_column.get_parent() == page.workspace) == (page.size.x >= 1180))
				if index == 1:
					for button in page.duration_buttons.values():
						assert(button.size.y >= 44)
				else:
					for mode in ["3D Model", "Exploded View"]:
						page.preview.set_mode(mode)
						for angle in [-0.42, 1.2, 3.1]:
							page.preview.yaw = angle
							check_model(page.preview)
			if index == 1 and resolution in [Vector2i(1440, 900), Vector2i(1920, 1080), Vector2i(3360, 2100)]:
				assert(page.scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "Sidebar layouts must keep overflow content reachable")
				if index == 1:
					assert(page.target_grid.columns == 3)
					var cards = page.objective_buttons.values()
					assert(is_equal_approx(cards[0].global_position.y, cards[1].global_position.y))
					assert(cards[0].global_position.x < cards[1].global_position.x)
			print("PASS: live resizing ", page.screen_id, " at ", resolution)
	quit()
