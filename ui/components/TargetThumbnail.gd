extends Control
## Generated illustrative landscape atlas; not geographic or mission data.
const LANDSCAPES = preload("res://assets/ui/backgrounds/target-landscapes-v1.png")
var terrain = "forest"
func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(Vector2(52, 36))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	var index = {"forest": 0, "coast": 1, "ocean": 2, "mountain": 3, "land": 4, "ice": 5}.get(terrain, 0)
	var cell = Vector2(LANDSCAPES.get_width() / 3.0, LANDSCAPES.get_height() / 2.0)
	var crop = cell
	var aspect = size.x / size.y
	if cell.x / cell.y > aspect:
		crop.x = cell.y * aspect
	else:
		crop.y = cell.x / aspect
	var start = Vector2(int(index) % 3, floori(float(index) / 3.0)) * cell + (cell - crop) * 0.5
	draw_texture_rect_region(LANDSCAPES, Rect2(Vector2.ZERO, size), Rect2(start, crop))
