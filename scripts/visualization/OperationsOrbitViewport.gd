extends SubViewportContainer
signal orbit_selected(id: String)
var preview_playing: bool = false
var preview_seconds: float = 0.0
var preview_progress: float = 0.0
var drag_distance: float = 0.0
var orbit_caption: Label
@onready var stage: Node3D = $SubViewport/OperationsStage
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(interact)
	focus_mode = Control.FOCUS_ALL
	$SubViewport.size_changed.connect(fit_view)
	resized.connect(fit_view)
	orbit_caption = Label.new()
	orbit_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orbit_caption.position = Vector2(8, 8)
	orbit_caption.add_theme_font_size_override("font_size", 11)
	orbit_caption.add_theme_color_override("font_color", Color("74efff"))
	add_child(orbit_caption)
	call_deferred("fit_view")
func fit_view() -> void:
	if is_instance_valid(stage) and stage.is_inside_tree():
		stage.fit_view($SubViewport.size)
func set_frame(progress: float, event_type: String) -> void:
	stage.set_frame(progress, event_type)
	if is_instance_valid(orbit_caption):
		var orbit_number: int = mini(stage.duration_orbits, 1 + floori(progress * stage.duration_orbits))
		orbit_caption.text = "%s · %s km\nOrbit %s / %s" % ["LEO" if stage.orbit_parameters.get("id") == "low_eq" else "Polar", stage.orbit_parameters.get("altitude_km", "—"), orbit_number, stage.duration_orbits]
func configure(components: Dictionary) -> void:
	var previous_duration: int = stage.duration_orbits
	var previous_orbit: String = str(stage.orbit_parameters.get("id", ""))
	stage.configure(components)
	if stage.duration_orbits != previous_duration or stage.orbit_parameters.get("id", "") != previous_orbit:
		preview_seconds = 0.0
		preview_progress = 0.0
		if preview_playing: stage.set_frame(0.0, "PREVIEW")

func set_preview_playing(enabled: bool) -> void:
	preview_playing = enabled
func _process(delta: float) -> void:
	if not preview_playing or stage.orbit_parameters.is_empty(): return
	preview_seconds += delta
	var total: float = maxf(1.0, stage.duration_orbits * 4.0)
	preview_progress = fmod(preview_seconds / total, 1.0)
	set_frame(preview_progress, "PREVIEW")
func interact(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		drag_distance += event.relative.length()
		stage.view_yaw -= event.relative.x * 0.008
		stage.view_pitch = clampf(stage.view_pitch + event.relative.y * 0.008, -1.3, 1.3)
		fit_view()
		accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed: drag_distance = 0
			elif drag_distance < 6:
				var point: Vector2 = event.position * Vector2($SubViewport.size) / size
				var id: String = stage.pick_orbit(point)
				if not id.is_empty(): orbit_selected.emit(id)
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			stage.view_zoom = clampf(stage.view_zoom * (0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1), 0.65, 2.0)
			fit_view()
			accept_event()

# Shared spacecraft-preview interface used by Readiness.
var model: Node3D:
	get: return stage.craft.get_node("ModelSlot")
var satellite_ids: Dictionary:
	get: return model.selected_ids
func configure_satellite(draft: Dictionary) -> void:
	configure(draft)
