extends SubViewportContainer
@onready var stage: Node3D = $SubViewport/OperationsStage
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$SubViewport.size_changed.connect(fit_view)
	resized.connect(fit_view)
	call_deferred("fit_view")
func fit_view() -> void:
	if is_instance_valid(stage) and stage.is_inside_tree():
		stage.fit_view($SubViewport.size)
func set_frame(progress: float, event_type: String) -> void:
	stage.set_frame(progress, event_type)
func configure(components: Dictionary) -> void:
	stage.configure(components)
