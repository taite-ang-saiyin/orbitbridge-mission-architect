extends SceneTree
func _initialize() -> void:
	call_deferred("check")
func check() -> void:
	var demo = load("res://scenes/3d/PreviewDemo.tscn").instantiate()
	root.add_child(demo)
	await process_frame
	var stage = demo.stage
	assert(stage.get_node("Camera3D").current)
	assert(stage.get_parent().own_world_3d)
	demo.get_node("Layout/Controls/Play").pressed.emit()
	assert(stage.animation.is_playing())
	stage.animation.advance(4.0)
	assert(stage.get_node("OrbitPivot").rotation.y > 1.0)
	demo.get_node("Layout/Controls/Pause").pressed.emit()
	assert(not stage.animation.is_playing())
	stage.set_preview_speed(2.0)
	assert(stage.animation.speed_scale == 2.0)
	demo.get_node("Layout/Controls/Play").pressed.emit()
	assert(stage.animation.is_playing())
	demo.get_node("Layout/Controls/Reset").pressed.emit()
	assert(not stage.animation.is_playing())
	assert(is_zero_approx(stage.get_node("OrbitPivot").rotation.y))
	print("PASS: isolated 3D viewport, camera, animation, play/pause/resume/reset/speed")
	quit()
