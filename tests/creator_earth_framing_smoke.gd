extends SceneTree
func _initialize() -> void: call_deferred("check")
func check() -> void:
	var view = load("res://scenes/ui/components/OperationsOrbitViewport.tscn").instantiate()
	view.set_script(load("res://scripts/visualization/CreatorOrbitViewport.gd"))
	root.add_child(view)
	var draft: Dictionary = preload("res://data/mock/DesignCatalog.gd").DEFAULTS.duplicate(true)
	for dimensions in [Vector2i(740, 220), Vector2i(450, 205), Vector2i(280, 255), Vector2i(450, 380), Vector2i(740, 480)]:
		view.size = Vector2(dimensions)
		for orbit in ["LEO – 400 km", "Polar – 600 km"]:
			draft.orbit = orbit
			view.configure(draft)
			for frame in 5: await process_frame
			for yaw in [0.0, 1.2]:
				view.stage.view_yaw = yaw
				view.fit_view()
				var camera: Camera3D = view.stage.get_node("Camera3D")
				var bounds = Rect2(Vector2.ONE * 5, Vector2(view.get_node("SubViewport").size) - Vector2.ONE * 10)
				for latitude in range(-90, 91, 15):
					for longitude in range(0, 360, 15):
						var lat: float = deg_to_rad(latitude)
						var lon: float = deg_to_rad(longitude)
						var point: Vector3 = Vector3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon)) * 1.1
						assert(bounds.has_point(camera.unproject_position(point)), "Earth/orbit clipped at " + str(dimensions))
		print("PASS Creator Earth/orbit fits panel at ", dimensions)
	view.queue_free()
	quit(0)
