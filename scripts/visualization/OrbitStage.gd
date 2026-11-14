extends Node3D
## Authored visual animation only. No physical units or simulation state.
@onready var animation: AnimationPlayer = $AnimationPlayer

func play_preview() -> void:
	if animation.current_animation.is_empty():
		animation.play("orbit_preview")
	else:
		animation.play()

func pause_preview() -> void:
	animation.pause()

func reset_preview() -> void:
	animation.play("orbit_preview")
	animation.seek(0.0, true)
	animation.pause()

func set_preview_speed(multiplier: float) -> void:
	animation.speed_scale = clampf(multiplier, 0.25, 8.0)
