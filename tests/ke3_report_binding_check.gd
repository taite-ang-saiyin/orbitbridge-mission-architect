extends SceneTree
## Real component snapshots; no simulator/evaluator logic duplicated here.
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
const Catalog = preload("res://data/mock/DesignCatalog.gd")
var checks: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed += 1
		print("FAIL ", message)

func run() -> void:
	var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
	Catalog.ensure(draft)
	draft.observations = 4
	draft.required_returned_data_mb = 30
	draft.orbit = "Polar – 600 km"
	var launched: Dictionary = Runtime.launch(draft)
	check(launched.ok, "Actual validated HPC component run starts")
	if not launched.ok:
		quit(1)
		return
	var payload: Dictionary = Results.presentation(launched.trace)
	var retained: Dictionary = payload.duplicate(true)
	var view = load("res://ke3/results_control.tscn").instantiate()
	root.add_child(view)
	await process_frame
	view.set_inputs(payload.context, payload.state, payload.report)
	check(view.get_debrief_model().presentation_state == "report", "Matching execution displays actual report")
	check(payload.report.source_ids == [] and payload.report.comparison == null, "Evaluator optional fields preserved")
	var context: Dictionary = payload.context.duplicate(true)
	# Explicit display metadata sentinel: this test does not claim a new attribution.
	context.applicable_source_credits.append({"credit_scope":"feedback_vocabulary", "source_id":"TEST_FEEDBACK_SENTINEL"})
	for definition in [["mission_id", "foreign-mission"], ["required_observations", 99], ["required_returned_data_mb", 999], ["observations_completed", 99], ["returned_data_mb", 999], ["run_status", "aborted"]]:
		var wrong: Dictionary = payload.report.duplicate(true)
		wrong[definition[0]] = definition[1]
		wrong.source_ids = ["TEST_REPORT_SOURCE_SENTINEL"]
		view.set_inputs(context, payload.state, wrong)
		var model: Dictionary = view.get_debrief_model()
		check(model.presentation_state == "stale_report", "Reject same-run mismatched " + definition[0])
		check(not "TEST_FEEDBACK_SENTINEL" in model.credits and not "TEST_REPORT_SOURCE_SENTINEL" in model.credits, "Rejected report credits hidden: " + definition[0])
		check("Metadata source ID: cubesat_101_1u_sample" in model.credits, "Independent readiness credit retained: " + definition[0])
		check(view._retry_button.disabled, "Rejected report cannot Retry: " + definition[0])
	view.set_inputs(payload.context, payload.state, {})
	check(view.get_debrief_model().presentation_state == "awaiting_evaluation", "Missing report stays awaiting evaluation")
	var foreign: Dictionary = payload.report.duplicate(true)
	foreign.run_id = "foreign-run"
	view.set_inputs(context, payload.state, foreign)
	check(not "Applicable credit scope:" in view.get_debrief_model().credits, "Foreign-run report hides all scoped metadata")
	check(view._retry_button.disabled, "Foreign-run report cannot Retry")
	view.set_inputs(payload.context, payload.state, payload.report)
	check(view.get_debrief_model().presentation_state == "report", "Valid report recovers after rejection")
	check(payload == retained, "View does not mutate supplied snapshots")
	view.queue_free()
	await process_frame
	print("KE3 REPORT BINDING: ", checks - failed, " passed; ", failed, " failed")
	quit(0 if failed == 0 else 1)
