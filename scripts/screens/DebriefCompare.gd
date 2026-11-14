extends "res://scripts/screens/Workbench.gd"
const Workflow = preload("res://scripts/integration/mission_workflow.gd")
var results: Label
var explanation: Label
var history: Label

func _ready() -> void:
	screen_id = "DebriefCompare"
	setup("06", "Mission Debrief", "Review the observations and data your mission actually returned.", 4, 0, "Return to Mission Control")
	var columns = row(content)
	var outcome = section(column(columns), "Mission outcome")
	results = UI.label(outcome, "", 20, "8ce5dc")
	explanation = UI.label(outcome, "", 14)
	var notes = section(column(columns), "What to try next")
	history = UI.label(notes, "", 13, "a9cbdc")
	var buttons = row(notes)
	UI.button(buttons, "Retry same mission", retry)
	UI.button(buttons, "Modify design", func(): navigate.emit(2))
	UI.button(buttons, "New mission", func(): Workflow.reset(state); navigate.emit(1))
	resized.connect(fit_navigation)
	refresh()

func refresh() -> void:
	var evaluated: Dictionary = Workflow.evaluation(state)
	if evaluated.is_empty():
		results.text = "Finish the mission before viewing a result."
		return
	if not evaluated.ok:
		results.text = "The result could not be checked."
		explanation.text = evaluated.error.message + " " + evaluated.error.suggested_fix
		return
	var report: Dictionary = evaluated.report
	results.text = "%s · %s\nScore: %s\nCaptured: %d / %d\nReturned: %.2f / %.2f MB" % [report.run_id, str(report.status).to_upper(), "—" if report.score == null else str(report.score), report.observations_completed, report.required_observations, report.returned_data_mb, report.required_returned_data_mb]
	explanation.text = report.explanation
	var feedback: PackedStringArray = []
	for cause in report.root_causes: feedback.append(cause.explanation)
	if report.next_experiment != null:
		feedback.append(str(report.next_experiment))
	feedback.append("\nPrevious runs in this mission:")
	for saved in state.get("reports", {}).values():
		feedback.append("%s · %s · %.2f MB returned" % [saved.run_id, saved.status, saved.returned_data_mb])
	history.text = "\n".join(feedback)

func retry() -> void:
	var started: Dictionary = Workflow.retry(state)
	if started.ok:
		navigate.emit(4)
	else:
		explanation.text = started.error.message
