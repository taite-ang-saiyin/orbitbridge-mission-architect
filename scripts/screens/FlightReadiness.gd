extends "res://scripts/screens/Workbench.gd"
const Workflow = preload("res://scripts/integration/mission_workflow.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const CHECK_TITLES = {"input_schema": "Mission details", "catalog_references": "Selected parts", "profile_mass": "Spacecraft weight", "launcher_capacity": "Launcher weight limit", "budget": "Budget", "launch_orbit": "Launch choices", "target_orbit": "Target access", "essential_power": "Starting power"}
var readiness_label: Label
var total_values: Label
var source_label: Label
var warning_label: Label
var check_details: Dictionary = {}

func _ready() -> void:
	screen_id = "FlightReadiness"
	setup("04", "Flight Readiness", "Every required check must pass before the mission can launch.", 2, 4, "Launch Mission")
	var columns = row(content)
	var checks = column(columns, 1.2)
	var details = column(columns, 1.0)
	for id in Validator.CHECK_IDS:
		var box = section(checks, CHECK_TITLES[id])
		check_details[id] = UI.label(box, "", 12)
	var summary_box = section(details, "Launch decision")
	readiness_label = UI.label(summary_box, "", 22, "75e3d7")
	total_values = UI.label(summary_box, "", 14)
	warning_label = UI.label(summary_box, "", 13, "f6cb8f")
	source_label = UI.label(section(details, "Mass rule and source"), "", 12, "a4cddc")
	UI.label(details, "A passing launch check does not guarantee mission success. Battery, storage and contact windows are also enforced during operations.", 12, "8baabd")
	for connection in next_button.pressed.get_connections(): next_button.pressed.disconnect(connection.callable)
	next_button.pressed.connect(launch)
	resized.connect(fit_navigation)
	refresh()

func refresh() -> void:
	var result: Dictionary = Workflow.review(state)
	readiness_label.text = "READY TO LAUNCH" if result.ready_to_launch else "LAUNCH BLOCKED"
	total_values.text = Workflow.totals_text(result)
	warning_label.text = Workflow.issue_text(result)
	for id in check_details:
		var check: Dictionary = result.checks[id]
		var message: String = check.message
		if id == "target_orbit" and check.passed == true:
			message = "This orbit has planned observation windows for the target. Each action still needs access at the current step."
		check_details[id].text = check.status.to_upper().replace("_", " ") + " · " + message
	var mass: Dictionary = result.checks.profile_mass
	if mass.threshold_g == null:
		source_label.text = "The mass rule is unavailable until the input errors are corrected."
	elif mass.source_id == "cubesat_101_1u_sample":
		source_label.text = "Sample 1U rule: mass < 1330 g.\nAdapted from NASA CubeSat 101, Appendix C, item 6, printed p.79 / PDF p.87. This educational profile requires mass below 1.33 kg. Other values are illustrative."
	else:
		source_label.text = "Illustrative profile: mass %s %s g.\nThis training limit is not a NASA mass rule." % [mass.comparator, mass.threshold_g]
	next_button.disabled = not result.ready_to_launch

func launch() -> void:
	var started: Dictionary = Workflow.start_run(state)
	if started.ok:
		navigate.emit(4)
	else:
		refresh()
		warning_label.text = started.error.message + "\n" + warning_label.text
