extends SceneTree
## B01 read-only configuration/runtime probe; no gameplay or provider calls.


func _initialize() -> void:
	var method: Variant = "Unavailable"
	var driver: Variant = "Unavailable"
	if RenderingServer.has_method("get_current_rendering_method"):
		method = RenderingServer.call("get_current_rendering_method")
	if RenderingServer.has_method("get_current_rendering_driver_name"):
		driver = RenderingServer.call("get_current_rendering_driver_name")
	print("B01_RENDERER_PROBE ", JSON.stringify({
		"project_path": ProjectSettings.globalize_path("res://project.godot"),
		"declared_features": ProjectSettings.get_setting("application/config/features", []),
		"configured_renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method", "Unavailable"),
		"configured_windows_driver": ProjectSettings.get_setting("rendering/rendering_device/driver.windows", "Unavailable"),
		"actual_rendering_method": method, "actual_rendering_driver": driver,
		"display_driver": DisplayServer.get_name(),
	}))
	quit(0)
