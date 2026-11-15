extends Control
## Illustrative spacecraft/operations atlas reserved for mission presets. Targets keep their landscape atlas.
const MISSIONS = preload("res://assets/ui/backgrounds/mission-presets-v1.png")
var mission = "Estuary Watch"
func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(Vector2(52, 36))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	var index = {"Estuary Watch": 0, "Tropical Forest Watch": 1, "Polar Ice Survey": 2, "Communication": 3, "Weather Monitoring": 4}.get(mission, 0)
	var cell = Vector2(MISSIONS.get_width() / 3.0, MISSIONS.get_height() / 2.0)
	var crop = cell
	var aspect = size.x / size.y
	if cell.x / cell.y > aspect:
		crop.x = cell.y * aspect
	else:
		crop.y = cell.x / aspect
	var start = Vector2(int(index) % 3, floori(float(index) / 3.0)) * cell + (cell - crop) * 0.5
	draw_texture_rect_region(MISSIONS, Rect2(Vector2.ZERO, size), Rect2(start, crop))
