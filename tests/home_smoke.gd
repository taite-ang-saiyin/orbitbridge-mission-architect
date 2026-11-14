extends SceneTree
var quit_signal_seen = false
func _initialize() -> void:
	call_deferred("check")
func settle() -> void:
	for frame in 5:
		await process_frame
func inside(control: Control, area: Rect2) -> void:
	var rect = control.get_global_rect()
	assert(area.encloses(rect), "Clipped control: " + str(control.get_path()) + " " + str(rect))
func check() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	assert(app.current.screen_id == "Home", "Main must launch into Home")
	assert(not app.shell.visible)
	for resolution in [Vector2i(1280, 720), Vector2i(1024, 768)]:
		root.content_scale_size = resolution
		root.size = resolution
		await settle()
		var home = app.current
		var bounds = Rect2(Vector2.ZERO, Vector2(resolution))
		for node in [home.start, home.settings, home.quit, home.get_node("SafeArea/Composition/Hero/Brand/Title"), home.get_node("Footer"), home.get_node("Version")]:
			inside(node, bounds)
		home.settings.pressed.emit()
		await settle()
		assert(home.get_node("Modal").visible)
		assert(home.start.disabled, "Background actions must be disabled while settings is open")
		var panel = home.settings_panel
		inside(panel, bounds)
		panel.language.select(1)
		panel.language.item_selected.emit(1)
		assert(home.start.text == "开始任务")
		panel.appearance.select(1)
		panel.appearance.item_selected.emit(1)
		assert(app.preferences.theme == "ocean")
		assert(home.get_node("AtmosphereTint").color.a > 0.0)
		panel.get_node("Margin/Content/Done").pressed.emit()
		assert(not home.get_node("Modal").visible)
		assert(not home.start.disabled)
		home.start.pressed.emit()
		await settle()
		assert(app.current.screen_id == "MissionControl")
		assert(app.host.get_child_count() == 1)
		app.show_screen(1)
		app.state.name = "Preserved Mission"
		app.show_home()
		await settle()
		assert(app.current.start.text == "开始任务")
		assert(app.state.name == "Preserved Mission")
		# Restore English/Midnight through the actual settings controls.
		home = app.current
		home.open_settings()
		await settle()
		panel = home.settings_panel
		panel.language.select(0)
		panel.language.item_selected.emit(0)
		panel.appearance.select(0)
		panel.appearance.item_selected.emit(0)
		var escape = InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		home._unhandled_key_input(escape)
		assert(not home.get_node("Modal").visible)
		assert(home.start.text == "Start Mission")
		print("PASS: Home layout, settings, localization, theme, navigation at ", resolution)
	# Check Quit's signal without terminating the test process.
	var standalone = load("res://scenes/screens/home/Home.tscn").instantiate()
	root.add_child(standalone)
	standalone.quit_requested.connect(func(): quit_signal_seen = true)
	standalone.quit.pressed.emit()
	assert(quit_signal_seen)
	print("PASS: Quit dispatch")
	quit()
