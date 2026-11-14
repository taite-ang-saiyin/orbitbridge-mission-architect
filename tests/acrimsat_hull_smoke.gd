extends SceneTree
func _initialize() -> void: call_deferred("check")
func check() -> void:
	var craft = load("res://scenes/3d/actors/ArchitectSpacecraft.tscn").instantiate()
	root.add_child(craft)
	var model: Node3D = craft.get_node("ModelSlot")
	var body: Node3D = model.get_node("body_id")
	var meshes: Array = body.find_children("*", "MeshInstance3D", true, false)
	assert(meshes.size() >= 2, "The textured centre panels must be present alongside the foil shell")
	var triangles: Array[Vector3] = []
	for part in meshes:
		var transform_to_model: Transform3D = model.global_transform.affine_inverse() * part.global_transform
		for surface in part.mesh.get_surface_count():
			var arrays: Array = part.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices = arrays[Mesh.ARRAY_INDEX]
			if indices == null or indices.is_empty():
				for vertex in vertices: triangles.append(transform_to_model * vertex)
			else:
				for index in indices: triangles.append(transform_to_model * vertices[index])
	for height in [0.10, 0.25]:
		for i in 8:
			var outward = Vector3(cos(i * TAU / 8), 0, sin(i * TAU / 8))
			var origin: Vector3 = outward * 2.0 + Vector3(0, height, 0)
			var outer_hit: float = 0.0
			for triangle in range(0, triangles.size(), 3):
				var hit = Geometry3D.ray_intersects_triangle(origin, -outward, triangles[triangle], triangles[triangle + 1], triangles[triangle + 2])
				if hit is Vector3: outer_hit = maxf(outer_hit, Vector2(hit.x, hit.z).length())
			assert(outer_hit > 0.38, "AcrimSAT centre wall is open at angle %s, height %s" % [i, height])
	print("PASS restored AcrimSAT centre walls are present and block rays from all eight sides at two heights")
	craft.queue_free()
	quit(0)
