extends Node3D
## Art-directed movement from a normalized UI playhead. No orbital propagation.
@onready var orbit_rig: Node3D = $OrbitPlane/OrbitRig
@onready var craft: Node3D = $OrbitPlane/OrbitRig/Spacecraft
@onready var beam: MeshInstance3D = $OrbitPlane/OrbitRig/ObservationBeam
func set_frame(progress: float, event_type: String) -> void:
	orbit_rig.rotation.y = progress * TAU * 2.0
	$Earth.rotation.y = -2.1 + progress * 0.3
	beam.visible = event_type in ["OBSERVE", "TX"]
	$TargetA.visible = event_type != "LAUNCH"
	$TargetB.visible = event_type != "LAUNCH"
func configure(components: Dictionary) -> void:
	craft.get_node("ModelSlot").configure(components)
func fit_view(view_size: Vector2i) -> void:
	if not is_inside_tree(): return
	var aspect = float(view_size.x) / maxf(1, view_size.y)
	var distance = maxf(4.8, 2.6 * aspect / (2.0 * tan(deg_to_rad(26))))
	$Camera3D.position = Vector3(0, distance * 0.32, distance)
	$Camera3D.look_at(Vector3.ZERO, Vector3.UP)

func _ready() -> void:
	var star_mesh = SphereMesh.new()
	star_mesh.radius = 0.009
	star_mesh.height = 0.018
	star_mesh.radial_segments = 8
	star_mesh.rings = 4
	var star_material = StandardMaterial3D.new()
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.albedo_color = Color(0.45, 0.68, 0.85)
	star_mesh.material = star_material
	var stars = MultiMesh.new()
	stars.transform_format = MultiMesh.TRANSFORM_3D
	stars.mesh = star_mesh
	stars.instance_count = 140
	for i in 140:
		var star_position = Vector3(fmod(i * 1.618, 14.0) - 7, fmod(i * 1.345, 10.0) - 5, -4)
		stars.set_instance_transform(i, Transform3D(Basis.IDENTITY, star_position))
	var field = MultiMeshInstance3D.new()
	field.multimesh = stars
	add_child(field)
