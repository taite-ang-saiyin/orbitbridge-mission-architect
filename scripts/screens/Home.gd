extends Control
signal start_requested
signal preferences_changed
signal quit_requested
const PREFS = preload("res://scripts/settings/PrototypeSettings.gd")
const SETTINGS = preload("res://scenes/ui/settings/SettingsPanel.tscn")
var preferences: Dictionary = {"language": "en", "theme": "midnight"}
var screen_id = "Home"
var settings_panel: Control
@onready var start: Button = $SafeArea/Composition/Hero/Actions/StartMission
@onready var settings: Button = $SafeArea/Composition/Hero/Actions/Secondary/Settings
@onready var quit: Button = $SafeArea/Composition/Hero/Actions/Secondary/Quit
func _ready() -> void:
	theme = preload("res://ui/theme/PrototypeTheme.gd").build()
	start.pressed.connect(func(): start_requested.emit())
	settings.pressed.connect(open_settings)
	quit.pressed.connect(func(): quit_requested.emit())
	$Modal/Dimmer.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			close_settings())
	refresh_preferences()
	resized.connect(resize_type)
	resize_type()
func resize_type() -> void:
	var density = clampf(minf(size.x / 1440.0, size.y / 900.0), 0.8, 1.25)
	$SafeArea.add_theme_constant_override("margin_left", roundi(size.x * 0.075))
	$SafeArea.add_theme_constant_override("margin_right", roundi(size.x * 0.06))
	$SafeArea.add_theme_constant_override("margin_top", roundi(size.y * 0.06))
	$SafeArea.add_theme_constant_override("margin_bottom", roundi(size.y * 0.13))
	$SafeArea/Composition/Hero.add_theme_constant_override("separation", roundi(20 * density))
	$SafeArea/Composition/Hero/Brand/Title.add_theme_font_size_override("font_size", roundi(90 * density))
	$SafeArea/Composition/Hero/Brand/Subtitle.add_theme_font_size_override("font_size", roundi(34 * density))
	$SafeArea/Composition/Hero/Tagline.add_theme_font_size_override("font_size", roundi(22 * density))
	start.custom_minimum_size = Vector2(340 * density, maxf(56, 64 * density))
	start.add_theme_font_size_override("font_size", roundi(24 * density))
	for button in [settings, quit]:
		button.custom_minimum_size = Vector2(240 * density, maxf(44, 48 * density))
		button.add_theme_font_size_override("font_size", roundi(18 * density))
	$Footer.offset_left = size.x * 0.03
	$Footer.offset_top = -maxf(70, size.y * 0.1)
func open_settings() -> void:
	if is_instance_valid(settings_panel):
		return
	settings_panel = SETTINGS.instantiate()
	settings_panel.values = preferences
	settings_panel.settings_changed.connect(func():
		refresh_preferences()
		preferences_changed.emit())
	settings_panel.closed.connect(close_settings)
	$Modal/Center.add_child(settings_panel)
	for button in [start, settings, quit]:
		button.disabled = true
	$Modal.show()
	settings_panel.get_node("Margin/Content/Language").grab_focus()
func close_settings() -> void:
	if is_instance_valid(settings_panel):
		$Modal/Center.remove_child(settings_panel)
		settings_panel.queue_free()
		settings_panel = null
	$Modal.hide()
	for button in [start, settings, quit]:
		button.disabled = false
	settings.grab_focus()
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and $Modal.visible:
		close_settings()
		get_viewport().set_input_as_handled()
func refresh_preferences() -> void:
	start.text = PREFS.word(preferences, "start")
	settings.text = PREFS.word(preferences, "settings")
	quit.text = PREFS.word(preferences, "quit")
	$SafeArea/Composition/Hero/Tagline.text = PREFS.word(preferences, "tagline")
	$SafeArea/Composition/Hero/Hint.text = PREFS.word(preferences, "hint")
	$Footer/Label.text = PREFS.word(preferences, "footer")
	$AtmosphereTint.color = Color(0.0, 0.17, 0.28, 0.22) if preferences.theme == "ocean" else Color(0, 0, 0, 0)
	var accent = Color("49e4df") if preferences.theme == "ocean" else Color("54beff")
	$SafeArea/Composition/Hero/Brand/Subtitle.add_theme_color_override("font_color", accent)
	for mode in ["normal", "hover", "pressed", "focus"]:
		var box = StyleBoxFlat.new()
		box.bg_color = (Color("086b82") if preferences.theme == "ocean" else Color("0859b8")) if mode == "normal" else (Color("0d8b9d") if preferences.theme == "ocean" else Color("1378d5"))
		if mode == "focus":
			box.bg_color = Color(0, 0, 0, 0)
		box.border_color = accent if mode != "focus" else Color.WHITE
		box.set_border_width_all(2)
		box.set_corner_radius_all(10)
		box.shadow_color = Color(accent.r, accent.g, accent.b, 0.17)
		box.shadow_size = 14 if mode == "normal" else 20
		start.add_theme_stylebox_override(mode, box)
