extends Control
## Decorative world map and authored visual path; not a geographic projection engine.
const WORLD_TEXTURE = preload("res://assets/3d/textures/earth-albedo-v1.png")
var inclination: float = 0.0
var duration_orbits: int = 6
var progress = 0.0:
	set(value):
		progress = clampf(value, 0, 1)
		queue_redraw()
func _ready() -> void:
	custom_minimum_size = Vector2(220, 92)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("05192b"))
	draw_texture_rect(WORLD_TEXTURE, Rect2(Vector2.ZERO, size), false, Color(0.26, 0.52, 0.72, 0.72))
	for x in 17:
		draw_line(Vector2(size.x * x / 16, 0), Vector2(size.x * x / 16, size.y), Color("113049"), 1)
	for y in 7:
		draw_line(Vector2(0, size.y * y / 6), Vector2(size.x, size.y * y / 6), Color("113049"), 1)
	var curve = PackedVector2Array()
	for i in 97:
		var x = float(i) / 96
		curve.append(Vector2(x * size.x, (0.5 + sin(x * TAU) * minf(inclination, 180.0 - inclination) / 90.0 * 0.45) * size.y))
	draw_polyline(curve, Color("27e878"), 2, true)
	var local_progress: float = fposmod(progress * duration_orbits, 1.0)
	var current = Vector2(local_progress * size.x, (0.5 + sin(local_progress * TAU) * minf(inclination, 180.0 - inclination) / 90.0 * 0.45) * size.y)
	for point in [[Vector2(0.30,0.52), Color("29d8ff")], [Vector2(0.70,0.46), Color("bb89f7")], [Vector2(0.19,0.37), Color("ffbd6d")]]:
		draw_circle(point[0] * size, 4, point[1])
	draw_circle(current, 7, Color(0.1, 1, 0.5, 0.2))
	draw_circle(current, 4, Color("75ffb4"))

func configure(draft: Dictionary) -> void:
	var orbit: Dictionary = preload("res://scripts/integration/mission_runtime.gd").orbit_for(draft)
	inclination = float(orbit.get("inclination_deg", 0))
	duration_orbits = int(draft.get("duration", 6))
	queue_redraw()
