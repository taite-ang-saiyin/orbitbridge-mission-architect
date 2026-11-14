extends Node3D
## Art-directed movement from a normalized UI playhead. No orbital propagation.
@onready var orbit_rig: Node3D = $OrbitPlane/OrbitRig
@onready var craft: Node3D = $OrbitPlane/OrbitRig/Spacecraft
@onready var beam: MeshInstance3D = $OrbitPlane/OrbitRig/ObservationBeam
var target_count: int = 1
var duration_orbits: int = 6
var orbit_parameters: Dictionary = {}
var orbit_paths: Dictionary = {}
var view_yaw: float = 0.0
var view_pitch: float = 0.32
var view_zoom: float = 1.0
var last_view_size: Vector2i = Vector2i(640, 360)
var unwrapped_angle: float = 0.0
func set_frame(progress: float, event_type: String) -> void:
	unwrapped_angle = clampf(progress, 0.0, 1.0) * TAU * duration_orbits
	orbit_rig.rotation.y = unwrapped_angle
	var elapsed_hours: float = progress * duration_orbits * float(orbit_parameters.get("steps_per_orbit", 10)) * float(orbit_parameters.get("step_duration_hours", 0.15))
	$Earth.rotation.y = -2.1 + elapsed_hours * TAU / 24.0
	beam.visible = event_type in ["OBSERVE", "TX"]
	$Earth/TargetA.visible = event_type != "LAUNCH"
	$Earth/TargetB.visible = event_type != "LAUNCH" and target_count > 1
func configure(components: Dictionary) -> void:
	craft.get_node("ModelSlot").configure(components)
	duration_orbits = int(components.get("duration", 6))
	var names: Array = components.get("targets", ["Equator"])
	target_count = names.size()
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/mission_scenarios.json"))
	for i in mini(2, names.size()):
		var marker: Node3D = get_node("Earth/TargetA" if i == 0 else "Earth/TargetB")
		for target in metadata.targets:
			if target.label != names[i]: continue
			var latitude: float = deg_to_rad(target.latitude_deg)
			var longitude: float = deg_to_rad(target.longitude_deg)
			marker.position = Vector3(cos(latitude) * cos(longitude), sin(latitude), cos(latitude) * sin(longitude)) * 1.015
	$Earth/TargetB.visible = target_count > 1
	var selected: Dictionary = preload("res://scripts/integration/mission_runtime.gd").orbit_for(components)
	if selected.is_empty(): return
	orbit_parameters = selected
	$OrbitPlane.rotation = Vector3(0, 0, deg_to_rad(float(selected.inclination_deg)))
	var radius: float = 1.0 + float(selected.altitude_km) / 6371.0
	craft.position = Vector3(radius, 0, 0)
	craft.scale = Vector3.ONE * 0.065
	beam.position.x = (radius + 1.0) * 0.5
	$OrbitPlane/OrbitPath.hide()
	for id in ["low_eq", "high_inc"]:
		var row: Dictionary = preload("res://scripts/integration/mission_runtime.gd").orbit_for({"orbit_id": id})
		if row.is_empty(): continue
		var path: MeshInstance3D
		if orbit_paths.has(id): path = orbit_paths[id]
		else:
			path = MeshInstance3D.new()
			path.name = "Path_" + id
			add_child(path)
			orbit_paths[id] = path
		var mesh = TorusMesh.new()
		var path_radius: float = 1.0 + float(row.altitude_km) / 6371.0
		mesh.inner_radius = path_radius - (0.008 if id == selected.id else 0.003)
		mesh.outer_radius = path_radius + (0.008 if id == selected.id else 0.003)
		mesh.rings = 128
		mesh.ring_segments = 8
		var material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("39eeff") if id == selected.id else Color("58758d")
		mesh.material = material
		path.mesh = mesh
		path.rotation.z = deg_to_rad(float(row.inclination_deg))
	fit_view(last_view_size)
func fit_view(view_size: Vector2i) -> void:
	if not is_inside_tree(): return
	last_view_size = view_size
	var aspect: float = float(view_size.x) / maxf(1, view_size.y)
	# The distance is fitted to height; retaining horizontal FOV crops Earth
	# in a wide, shallow panel. Keep the vertical field of view stable instead.
	$Camera3D.keep_aspect = Camera3D.KEEP_HEIGHT
	var distance: float = maxf(3.4, 3.2 / maxf(0.5, aspect)) * view_zoom
	$Camera3D.position = Vector3(sin(view_yaw) * cos(view_pitch), sin(view_pitch), cos(view_yaw) * cos(view_pitch)) * distance
	$Camera3D.look_at(Vector3.ZERO, Vector3.UP)
func pick_orbit(point: Vector2) -> String:
	var nearest: float = 16.0
	var selected: String = ""
	for id in orbit_paths:
		var row: Dictionary = preload("res://scripts/integration/mission_runtime.gd").orbit_for({"orbit_id": id})
		var radius: float = 1.0 + float(row.altitude_km) / 6371.0
		for i in 180:
			var position: Vector3 = orbit_paths[id].transform * Vector3(cos(TAU * i / 180.0) * radius, 0, sin(TAU * i / 180.0) * radius)
			if $Camera3D.is_position_behind(position): continue
			# Hide far-side points behind the solid Earth from picking.
			if position.dot($Camera3D.position - position) < -0.02: continue
			var distance: float = $Camera3D.unproject_position(position).distance_to(point)
			if distance < nearest:
				nearest = distance
				selected = id
	return selected

func _ready() -> void:
	$TargetA.reparent($Earth)
	$TargetB.reparent($Earth)
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
