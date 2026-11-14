extends Control
## Static illustrative sample-target map, separate from the Operations ground track.
func _ready() -> void:
	custom_minimum_size = Vector2(180, 100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background = TextureRect.new()
	background.texture = preload("res://assets/3d/textures/earth-albedo-v1.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.show_behind_parent = true
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader = ShaderMaterial.new()
	shader.shader = preload("res://assets/ui/sample_target_map.gdshader")
	background.material = shader
	add_child(background)
	resized.connect(queue_redraw)
func _draw() -> void:
	for x in range(1, 17):
		draw_line(Vector2(size.x * x / 17.0, 0), Vector2(size.x * x / 17.0, size.y), Color(0.10, 0.30, 0.43, 0.32), 1)
	for y in range(1, 7):
		draw_line(Vector2(0, size.y * y / 7.0), Vector2(size.x, size.y * y / 7.0), Color(0.10, 0.30, 0.43, 0.32), 1)
	for location in [Vector2(0.19, 0.46), Vector2(0.61, 0.33), Vector2(0.51, 0.66), Vector2(0.80, 0.78)]:
		var point: Vector2 = location * size
		for radius in [13, 10, 7]: draw_circle(point, radius, Color(0.0, 0.9, 1.0, 0.06))
		draw_arc(point, 5, 0, TAU, 24, Color("32f4ff"), 1.5, true)
		draw_circle(point, 2.2, Color("90ffff"))
		var pin = PackedVector2Array([point + Vector2(-3, 4), point + Vector2(0, 9), point + Vector2(3, 4)])
		draw_polyline(pin, Color("32f4ff"), 1, true)
	for corner in [Vector2(2, 2), Vector2(size.x - 2, 2), Vector2(2, size.y - 2), size - Vector2(2, 2)]:
		var inward = Vector2(1 if corner.x < size.x * 0.5 else -1, 1 if corner.y < size.y * 0.5 else -1)
		draw_line(corner, corner + Vector2(inward.x * 12, 0), Color("25def3"), 1.5)
		draw_line(corner, corner + Vector2(0, inward.y * 12), Color("25def3"), 1.5)
