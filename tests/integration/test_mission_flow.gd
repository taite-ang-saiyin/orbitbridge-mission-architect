extends SceneTree
const Workflow = preload("res://scripts/integration/mission_workflow.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	var draft: Dictionary = Workflow.new_draft()
	var reviewed: Dictionary = Workflow.review(draft)
	_check(reviewed.ready_to_launch and reviewed.metrics.total_mass_g == 1060 and reviewed.metrics.total_cost_credits == 82, "Default draft uses real KE1 totals")
	draft.components.payload = "instrument_advanced"
	_check(not Workflow.start_run(draft).ok and draft.active_run.is_empty(), "Launch rechecks a stale passing result after a heavy-part edit")
	_check(draft.validation.metrics.total_mass_g == 1380, "Heavy instrument changes the total to 1380 g")
	draft.launch_profile = "illustrative_alternative"
	draft.launcher = "medium"
	draft.budget = 120
	_check(Workflow.review(draft).ready_to_launch, "Same heavy design passes with compatible profile and budget")
	draft.targets = ["Equator", "Coastal Region"]
	_check(not Workflow.review(draft).ready_to_launch, "Multiple legacy targets are rejected rather than silently selecting one")
	Workflow.reset(draft)
	draft.budget = 81
	_check(not Workflow.start_run(draft).ok, "A passing mass never bypasses a failed budget")
	Workflow.reset(draft)
	var started: Dictionary = Workflow.start_run(draft)
	_check(started.ok, "Validated config starts the real HPC engine through its adapter")
	if not started.ok:
		printerr(str(started))
		_finish()
		return
	var run_id: String = draft.active_run.state.run_id
	var saved_config: String = JSON.stringify(draft.active_run.config)
	var saved_scenario: String = JSON.stringify(draft.active_run.scenario)
	_check(draft.active_run.state.total_steps == 60 and draft.active_run.state.energy_wh == 25, "HPC receives duration and selected battery in agreed units")
	_check(not Workflow.start_run(draft).ok and draft.active_run.state.run_id == run_id, "A second launch cannot replace an operating run")
	_check(Workflow.evaluation(draft).is_empty(), "A nonterminal run has no invented report")
	var before: Dictionary = draft.active_run.state.duplicate(true)
	var rejected: Dictionary = Workflow.request_action(draft, "observe")
	_check(not rejected.allowed and draft.active_run.state.step_index == before.step_index, "Rejected action produces an event without advancing a step")
	_check(draft.active_run.state.energy_wh == before.energy_wh and draft.active_run.state.observations_completed == 0, "Rejected action has no resource or capture change")
	draft.observations = 20
	draft.required_returned_data_mb = 999
	draft.components.battery = "battery_large"
	_complete(draft)
	var live: Dictionary = draft.active_run.state
	_check(live.phase == "finished" and live.run_status == "completed" and live.step_index == 60, "Real engine finishes exactly at the configured final step")
	_check(JSON.stringify(draft.active_run.config) == saved_config and JSON.stringify(draft.active_run.scenario) == saved_scenario, "Launch snapshots survive later draft edits and all operations")
	var evaluated: Dictionary = Workflow.evaluation(draft)
	_check(evaluated.ok, "Real KE2 evaluator accepts actual HPC terminal state and event log")
	if evaluated.ok:
		var report: Dictionary = evaluated.report
		_check(report.required_observations == 4 and report.required_returned_data_mb == 30, "Evaluator receives original launch goals, not later edits")
		_check(report.observations_completed == live.observations_completed and report.returned_data_mb == live.returned_data_mb, "Report uses actual simulator counts and returned MB")
		_check(report.status == "success" and report.score == 100, "Feasible default policy reaches both goals and scores 100")
		print("ACTUAL RUN: %s; captures=%d; returned=%.4f MB; score=%s; status=%s" % [report.run_id, report.observations_completed, report.returned_data_mb, str(report.score), report.status])
		for repeat in 3: Workflow.evaluation(draft)
		_check(draft.reports.size() == 1, "Repeated completion/result access records one report per run")
		evaluated.report.status = "tampered"
		_check(Workflow.evaluation(draft).report.status == "success", "Returned report copies cannot alter saved reports")
	var retried: Dictionary = Workflow.retry(draft)
	_check(retried.ok and draft.active_run.state.run_id != run_id, "Retry starts a new run identity")
	_check(draft.active_run.state.step_index == 0 and draft.active_run.state.returned_data_mb == 0 and draft.active_run.state.event_log.is_empty(), "Retry clears live counters and events")
	_check(JSON.stringify(draft.active_run.config) == saved_config and JSON.stringify(draft.active_run.scenario) == saved_scenario, "Retry preserves the exact config, scenario and units")
	_check(draft.observations == 4 and draft.required_returned_data_mb == 30 and draft.reports.size() == 1, "Retry restores mission goals and preserves history")
	_check(Workflow.abort(draft).ok, "Stop action uses the HPC abort API")
	var aborted: Dictionary = Workflow.evaluation(draft)
	_check(aborted.ok and aborted.report.status == "failed" and aborted.report.score == null and aborted.report.run_status == "aborted", "KE2 reports aborted runs with a null score")
	_check(draft.reports.size() == 2 and not Workflow.abort(draft).ok, "Repeated abort cannot add another report")
	var previous_mission: String = draft.mission_id
	Workflow.reset(draft)
	_check(draft.mission_id != previous_mission and draft.reports.is_empty() and draft.active_run.is_empty(), "New Mission clears run/history and assigns a new mission identity")
	draft.orbit = "low_eq"
	_check(Workflow.start_run(draft).ok, "The other agreed orbit launches through the real adapter")
	_complete(draft)
	_check(Workflow.evaluation(draft).ok and Workflow.evaluation(draft).report.status == "success", "Both authored orbit presets run through to real evaluation")
	_finish()

func _complete(draft: Dictionary) -> void:
	for index in 120:
		if not Workflow.is_operating(draft): break
		var result: Dictionary = Workflow.automatic_step(draft)
		if not result.get("ok", true):
			_check(false, "Automatic step failed: " + str(result))
			return
	_check(not Workflow.is_operating(draft), "Automatic policy finishes within its finite step bound")

func _check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func _finish() -> void:
	print("K12/K13 mission flow: %d checks passed; %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)
