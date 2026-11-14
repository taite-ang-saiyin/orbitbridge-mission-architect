extends SceneTree
const Verification = preload("res://scripts/verification/demo_verification.gd")

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): printerr("FAIL: K14 verification timed out"); quit(1))
	call_deferred("_run")

func _run() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	var result: Dictionary = await Verification.new().run(app)
	app.queue_free()
	for frame in 4: await process_frame
	quit(0 if result.failed == 0 else 1)
