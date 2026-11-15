extends SceneTree
## Local owner-integration preview. Expanded scoring remains under review.
func _initialize() -> void:
	call_deferred("open_preview")
func open_preview() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	app.enable_expansion_candidate()
	root.add_child(app)
	print("OrbitBridge local expansion preview; expanded scoring is under review.")
