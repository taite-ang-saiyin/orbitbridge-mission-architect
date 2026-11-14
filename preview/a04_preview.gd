extends "res://preview/a03_preview.gd"
## Explicit A04 opt-in; default startup remains untouched.


func _ready() -> void:
	# Native-size text and responsive layout in this preview only, no project edit.
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	super._ready()


func _make_provider() -> RefCounted:
	return preload("res://preview/a04_provider.gd").new(self)


func _entry_banner() -> String:
	return "SYNTHETIC A04 PREVIEW | ILLUSTRATIVE ORBIT AND PROVIDER EVENT TIMELINE"


func _case_prefix() -> String:
	return "SYNTHETIC A04 / "
