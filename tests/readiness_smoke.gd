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
	app.state.orbit = "Polar – 600 km"
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
		assert("1060 g" in page.specs.text and page.validation.metrics.battery_capacity_wh == 25)
		assert(page.orbit_label.text == "Polar – 600 km")
		assert(page.readiness_label.text == "LAUNCH READY")
		assert(page.check_buttons.size() == 8)
		assert(page.preview_frame.get_global_rect().grow(1).encloses(page.specs_card.get_global_rect()), "Specs escape preview frame")
		assert(page.specs_card.get_global_rect().grow(1).encloses(page.specs.get_global_rect()), "Specs text escapes its card")
		assert(page.coverage_value.size.x >= 150 and page.coverage_value.size.y < 60, "Coverage text collapsed")
		assert(page.lower_panels.global_position.y >= page.preview_frame.get_global_rect().end.y, "Resource panels overlap preview")
		assert(page.gauges.mass.value_text == "1060 g")
		assert(is_equal_approx(page.gauges.mass.fraction, 1060.0 / 1330.0))
		for key in page.check_buttons:
			assert(not page.check_details[key].visible)
			page.check_buttons[key].pressed.emit()
			assert(page.check_details[key].visible)
			page.check_buttons[key].pressed.emit()
			assert(not page.check_details[key].visible)
		await settle()
		if resolution in [Vector2i(1440, 900), Vector2i(1920, 1080), Vector2i(3360, 2100)]:
			print("Readiness content ", page.content.size, " available ", page.scroll.size)
			assert(page.scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED)
		page.warning_details_button.pressed.emit()
		assert(page.warning_dialog.visible)
		assert("readiness" in page.warning_dialog.dialog_text)
		page.warning_dialog.hide()
		page.next_button.pressed.emit()
		await settle()
		assert(app.current.screen_id == "MissionOperations")
		assert("Readiness Review" in app.current.status.text)
		app.current.skip_to_end()
		app.show_screen(3)
		await settle()
		app.current.previous.pressed.emit()
		await settle()
		assert(app.current.screen_id == "SpacecraftBuilder")
		assert(app.state.components.bus == "BUS-M2 (Medium)")
		print("PASS: readiness state, eight expandable checks, warning details, layout, back and launch at ", resolution)
	app.state.body_id = "dev_body_3"
	app.state.launch_profile_id = "illustrative_alternative"
	app.state.launcher_id = "medium"
	app.state.budget = 120
	app.show_screen(3)
	await settle()
	assert(app.current.gauges.mass.limit_text.contains("5000"))
	assert(is_equal_approx(app.current.gauges.mass.fraction, 1380.0 / 5000.0))
	print("PASS: flexible content bounds, coverage text and selected profile mass limit")
	quit()
