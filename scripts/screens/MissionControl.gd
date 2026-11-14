extends "res://scripts/screens/Workbench.gd"
const Workflow = preload("res://scripts/integration/mission_workflow.gd")

func _ready() -> void:
	screen_id = "MissionControl"
	setup("01", "Mission Control", "Design a spacecraft, check it, and operate an imaging mission.", -1, 1, "Continue Mission")
	var box = section(content, "Your mission")
	UI.label(box, state.name, 24, "8ce5dc")
	UI.label(box, CATALOG.success(state), 16)
	UI.label(box, "Choose parts, review the launch checks, then capture observations and send data home. Component values and orbit windows are illustrative training assumptions.", 15, "a9cbdc")
	var new_button = UI.button(box, "Create new mission", func(): Workflow.reset(state); navigate.emit(1))
	new_button.disabled = Workflow.is_operating(state)
	if Workflow.is_operating(state):
		UI.button(box, "Resume current mission", func(): navigate.emit(4))
		next_button.disabled = true
