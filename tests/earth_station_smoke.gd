extends SceneTree
func _initialize() -> void: call_deferred("check")
func check() -> void:
	root.size = Vector2i(1280, 720)
	var view = load("res://scenes/ui/components/OperationsOrbitViewport.tscn").instantiate()
	view.size = Vector2(640, 480)
	root.add_child(view)
	for frame in 5: await process_frame
	var draft: Dictionary = preload("res://data/mock/DesignCatalog.gd").DEFAULTS.duplicate(true)
	for orbit in ["LEO – 400 km", "Polar – 600 km"]:
		draft.orbit = orbit
		view.configure(draft)
		var earth: Node3D = view.stage.get_node("Earth")
		var station: Node3D = earth.get_node("GroundStation")
		view.set_frame(0, "PREVIEW")
		var location: Vector3 = earth.to_local(station.global_position)
		var initial: Vector3 = station.global_position
		view.set_frame(0.25, "PREVIEW")
		assert(station.global_position.distance_to(initial) > 0.01, "Ground station must move when Earth rotates")
		assert(earth.to_local(station.global_position).is_equal_approx(location), "Ground station must remain fixed to the same point on Earth")
		var camera: Camera3D = view.stage.get_node("Camera3D")
		var projected: Vector2 = camera.unproject_position(station.global_position)
		var drag = InputEventMouseMotion.new()
		drag.button_mask = MOUSE_BUTTON_MASK_LEFT
		drag.relative = Vector2(80, 15)
		view.interact(drag)
		assert(camera.unproject_position(station.global_position).distance_to(projected) > 1.0, "Orange marker must move on screen when dragging Earth")
		assert(earth.to_local(station.global_position).is_equal_approx(location), "Camera rotation must not change the station location")
		print("PASS ground station follows Earth without sliding at ", orbit)
	view.queue_free()
	quit(0)
