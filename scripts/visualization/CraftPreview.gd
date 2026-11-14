extends SubViewportContainer
## Presentation controls only; model changes do not calculate spacecraft performance.
signal auto_rotation_changed(enabled: bool)
var auto_rotate = false:
	set(value):
		auto_rotate = value
		auto_rotation_changed.emit(value)
var view_mode = "3D Model"
var yaw = -0.42
var pitch = 0.32
var zoom = 0.9
var highlighted = ""
var group_bounds: Dictionary = {}
var satellite_ids: Dictionary = {}
@onready var rig: Node3D = $SubViewport/Stage/Turntable
@onready var model: Node3D = $SubViewport/Stage/Turntable/Spacecraft/ModelSlot
@onready var camera: Camera3D = $SubViewport/Stage/Camera3D
@onready var animation: AnimationPlayer = $SubViewport/Stage/AnimationPlayer
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	gui_input.connect(handle_input)
	var earth = preload("res://scenes/3d/actors/OperationsEarth.tscn").instantiate()
	earth.name = "PreviewEarth"
	earth.position = Vector3(-3.8, -2.5, -6)
	earth.scale = Vector3.ONE * 4.8
	$SubViewport/Stage.add_child(earth)
	cache_bounds()
	resized.connect(update_camera)
	update_camera()
func _process(delta: float) -> void:
	if auto_rotate:
		yaw += delta * 0.24
	rig.rotation = Vector3(pitch, yaw, -0.12)
	update_camera()
func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		yaw += event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.008, -1.15, 1.15)
		auto_rotate = false
		accept_event()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 0.1, 0.7, 1.7)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 0.1, 0.7, 1.7)
		else:
			return
		update_camera()
		accept_event()
func cache_bounds() -> void:
	# Cache six assembly boxes; fitting transforms only 48 corners per frame.
	group_bounds.clear()
	for group in model.get_children():
		var bounds = AABB()
		var first = true
		for part in group.find_children("*", "MeshInstance3D", true, false):
			var box: AABB = group.global_transform.affine_inverse() * part.global_transform * part.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		if not first:
			group_bounds[group] = bounds

func framing_points() -> PackedVector3Array:
	var points = PackedVector3Array()
	var to_stage = $SubViewport/Stage.global_transform.affine_inverse()
	for group in group_bounds:
		var transform_to_stage: Transform3D = to_stage * group.global_transform
		for corner in 8:
			points.append(transform_to_stage * group_bounds[group].get_endpoint(corner))
	return points

func update_camera() -> void:
	if not is_instance_valid(camera) or group_bounds.is_empty():
		return
	rig.rotation = Vector3(pitch, yaw, -0.12)
	var points = framing_points()
	var bounds = AABB(points[0], Vector3.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var center = bounds.get_center()
	var viewport_size = $SubViewport.size
	var aspect = float(viewport_size.x) / maxf(1, viewport_size.y)
	var horizontal = tan(deg_to_rad(camera.fov * 0.5)) * 0.82
	var vertical = horizontal / maxf(0.1, aspect)
	var distance = 0.0
	for point in points:
		var offset = point - center
		distance = maxf(distance, offset.z + maxf(absf(offset.x) / horizontal, absf(offset.y) / vertical))
	camera.position = center + Vector3(0, 0, (distance + 0.1) * zoom)
func reset_view() -> void:
	yaw = -0.42
	pitch = 0.32
	zoom = 0.9
	auto_rotate = false
	update_camera()
func set_mode(mode: String) -> void:
	view_mode = mode
	zoom = 0.9
	update_camera()
	for slot in model.get_children():
		slot.position = Vector3(0, 0.8, 0) if mode == "Exploded View" and slot.name == "radio_id" else Vector3.ZERO
func highlight(group: String) -> void:
	highlighted = group.capitalize()
	refresh_highlight()
func refresh_highlight() -> void:
	pass
func configure(components: Dictionary) -> void:
	configure_satellite(components)
func configure_satellite(draft: Dictionary) -> void:
	if not is_node_ready():
		configure_satellite.call_deferred(draft)
		return
	model.configure(draft)
	satellite_ids = model.selected_ids.duplicate()
	cache_bounds()
	update_camera()
