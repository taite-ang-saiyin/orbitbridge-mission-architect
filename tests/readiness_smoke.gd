extends SceneTree
func _initialize() -> void:
	call_deferred("check")
func settle() -> void:
	for frame in 10:
		await process_frame
func check() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	app.state.name = "Readiness Review"
	app.state.components.bus = "BUS-M2 (Medium)"
	app.state.components.battery = "BAT-90 (90 Wh)"
	app.state.orbit = "LEO – 500 km"
	app.state.policy = "Downlink First"
	for resolution in [Vector2i(1440, 900), Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(1920, 1080), Vector2i(3360, 2100)]:
		root.size = resolution
		app.show_screen(3)
		await settle()
		var page = app.current
		assert(page.screen_id == "FlightReadiness")
		assert(page.progress_nav.get_child(3).button_pressed)
		assert(not app.nav.visible and not app.shell_footer.visible)
		assert(page.content.size.x <= page.scroll.size.x + 1, "Horizontal overflow")
		assert(Rect2(Vector2.ZERO, app.size).encloses(page.next_button.get_global_rect()))
		assert("Readiness Review" in page.summary.text)
		assert("136.0 kg" in page.specs.text and "90 Wh" in page.specs.text)
		assert(page.orbit_label.text == "LEO – 500 km")
		assert(page.readiness_label.text == "LAUNCH READY")
		assert(page.check_buttons.size() == 6)
		assert(page.gauges.mass.value_text == "136.0 kg")
		assert(is_equal_approx(page.gauges.mass.fraction, 0.91))
		for key in page.check_buttons:
			assert(not page.check_details[key].visible)
			page.check_buttons[key].pressed.emit()
			assert(page.check_details[key].visible)
			page.check_buttons[key].pressed.emit()
			assert(not page.check_details[key].visible)
		await settle()
		if resolution in [Vector2i(1440, 900), Vector2i(1920, 1080), Vector2i(3360, 2100)]:
			print("Readiness content ", page.content.size, " available ", page.scroll.size)
			assert(page.content.size.y <= page.scroll.size.y + 1, "Desktop readiness panels should fit without vertical scrolling")
		page.warning_details_button.pressed.emit()
		assert(page.warning_dialog.visible)
		assert("Readiness Review" in page.warning_dialog.dialog_text)
		page.warning_dialog.hide()
		page.next_button.pressed.emit()
		await settle()
		assert(app.current.screen_id == "MissionOperations")
		assert("Readiness Review" in app.current.status.text)
		app.show_screen(3)
		await settle()
		app.current.previous.pressed.emit()
		await settle()
		assert(app.current.screen_id == "SpacecraftBuilder")
		assert(app.state.components.bus == "BUS-M2 (Medium)")
		print("PASS: readiness state, six expandable checks, warning details, layout, back and launch at ", resolution)
	quit()
