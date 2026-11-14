extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
func _initialize() -> void: call_deferred("check")
func settle() -> void:
	for frame in 8: await process_frame
func bounds_in(root_node: Node3D, node: Node3D) -> AABB:
	var result = AABB()
	var first: bool = true
	for part in node.find_children("*", "MeshInstance3D", true, false):
		var bounds: AABB = root_node.global_transform.affine_inverse() * part.global_transform * part.get_aabb()
		result = bounds if first else result.merge(bounds)
		first = false
	return result
func check() -> void:
	root.size = Vector2i(1440, 900)
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	app.show_screen(2)
	await settle()
	var builder = app.current
	for body in builder.ADAPTER.catalog("body_id"):
		builder.select_component("body_id", body.id)
		builder.select_component("radio_id", "dev_radio_1")
		var previous: Dictionary = Runtime.review(app.state)
		builder.select_component("radio_id", "dev_radio_3")
		await settle()
		var current: Dictionary = Runtime.review(app.state)
		assert(current.metrics == previous.metrics, "Antenna art must preserve existing gameplay specifications")
		assert(current.config.design.radio_id == previous.config.design.radio_id)
		var model: Node3D = builder.preview.model
		var radio: Node3D = model.get_node("radio_id/CompactAntennaArray")
		var body_bounds: AABB = bounds_in(model, model.get_node("body_id"))
		var radio_bounds: AABB = bounds_in(model, model.get_node("radio_id"))
		var plate: MeshInstance3D = radio.get_node("MountingPlate")
		var plate_bounds: AABB = model.global_transform.affine_inverse() * plate.global_transform * plate.get_aabb()
		assert(plate_bounds.position.y < body_bounds.end.y and plate_bounds.end.y > body_bounds.end.y, "Mount must contact the bus without floating")
		assert(plate_bounds.size.x <= body_bounds.size.x and plate_bounds.size.z <= body_bounds.size.z, "Plate must fit the bus footprint")
		assert(radio_bounds.size.y <= body_bounds.size.y * 0.6, "Whips must remain compact relative to the body")
		for i in range(1, 5):
			var collar: MeshInstance3D = radio.get_node("Socket%s/Collar" % i)
			var rod: MeshInstance3D = radio.get_node("Socket%s/Whip/Rod" % i)
			var start: Vector3 = collar.to_local(rod.to_global(Vector3(0, -rod.mesh.height * 0.5, 0)))
			assert(collar.get_aabb().has_point(start), "Each whip must begin inside its mounting socket")
		builder.preview.zoom = 1.0
		for yaw in [-0.42, 1.2, 3.1]:
			builder.preview.yaw = yaw
			builder.preview.update_camera()
			var dimensions = Vector2(builder.preview.get_node("SubViewport").size)
			var safe = Rect2(Vector2.ONE * 2, dimensions - Vector2.ONE * 4)
			for point in builder.preview.framing_points():
				assert(safe.has_point(builder.preview.camera.unproject_position(point)), "Compact array must fit the camera")
		print("PASS compact mount, four connected whips, proportional fit, camera and unchanged specifications for ", body.name)
	app.queue_free()
	quit(0)
