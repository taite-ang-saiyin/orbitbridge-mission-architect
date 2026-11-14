extends "res://scripts/visualization/OperationsOrbitViewport.gd"
## Creator-only framing; shared Operations and Readiness cameras are unchanged.
func fit_view() -> void:
	if not is_instance_valid(stage) or not stage.is_inside_tree(): return
	var dimensions: Vector2i = $SubViewport.size
	stage.fit_view(dimensions)
	var camera: Camera3D = stage.get_node("Camera3D")
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	var aspect: float = float(dimensions.x) / maxf(1.0, dimensions.y)
	var vertical_half: float = deg_to_rad(camera.fov) * 0.5
	var horizontal_half: float = atan(tan(vertical_half) * aspect)
	# Enclose the Earth, the higher orbit and the miniature spacecraft with margin.
	var radius: float = 1.0 + 600.0 / 6371.0 + 0.13
	var distance: float = radius / sin(minf(vertical_half, horizontal_half)) * 1.05 * stage.view_zoom
	camera.position = camera.position.normalized() * distance
	camera.look_at(Vector3.ZERO, Vector3.UP)

func configure(draft: Dictionary) -> void:
	super.configure(draft)
	fit_view()
