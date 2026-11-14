extends Control
## Standalone integration example. Run PreviewDemo.tscn with F6.
@onready var stage = $Layout/OrbitViewport/SubViewport/OrbitStage
func _ready() -> void:
	theme = preload("res://ui/theme/PrototypeTheme.gd").build()
	$Layout/Controls/Play.pressed.connect(stage.play_preview)
	$Layout/Controls/Pause.pressed.connect(stage.pause_preview)
	$Layout/Controls/Reset.pressed.connect(stage.reset_preview)
