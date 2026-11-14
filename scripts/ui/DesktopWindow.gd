extends RefCounted
## Fullscreen startup with a centered, resizable desktop fallback.
static func configure(window: Window) -> void:
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	if not window.size_changed.is_connected(sync_canvas.bind(window)):
		window.size_changed.connect(sync_canvas.bind(window))
	sync_canvas(window)
	if DisplayServer.get_name() == "headless":
		return
	window.unresizable = false
	window.mode = Window.MODE_FULLSCREEN

static func toggle(window: Window) -> void:
	if window.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]:
		window.mode = Window.MODE_WINDOWED
		fit_window(window)
	else:
		window.mode = Window.MODE_FULLSCREEN

static func fit_window(window: Window) -> void:
	var usable = DisplayServer.screen_get_usable_rect(window.current_screen)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return
	var available = (usable.size - Vector2i(40, 64)).max(Vector2i(640, 480))
	window.unresizable = false
	window.min_size = Vector2i(1024, 720).min(available)
	window.size = Vector2i(1440, 900).min(available)
	window.position = usable.position + (usable.size - window.size) / 2

static func sync_canvas(window: Window) -> void:
	# Large/Retina screens scale a complete desktop layout; small windows still reflow.
	var canvas = Vector2i(mini(window.size.x, 1440), mini(window.size.y, 900))
	if canvas.x > 0 and canvas.y > 0 and window.content_scale_size != canvas:
		window.content_scale_size = canvas
