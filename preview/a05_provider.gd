extends "res://preview/a04_provider.gd"
## Literal SYNTHETIC v1 report examples. Never evaluates or scores a run.

var _debrief_cases: Dictionary = {}


func _init(entry: Node = null) -> void:
	super(entry)
	if not _preview_active():
		return
	var original := super.catalog()
	for specification in [
		{"id": "debrief_success", "base": "report_success", "status": "success", "run_status": "completed", "observations": 3, "returned": 4, "observation_ratio": 1.0, "return_ratio": 1.0, "score": 100, "explanation": "SYNTHETIC: supplied observation and returned-data goals were met.", "cause": "", "next": "SYNTHETIC: compare another orbit while holding the mission requirements fixed."},
		{"id": "debrief_partial", "base": "report_partial", "status": "partial", "run_status": "completed", "observations": 1, "returned": 2, "observation_ratio": 0.3333333333, "return_ratio": 0.5, "score": 42, "explanation": "SYNTHETIC: 1 of 3 observations and 2 of 4 MB were returned; the supplied report identifies one contact limitation.", "cause": "NO_LINK_WINDOW", "next": "SYNTHETIC: choose a higher-contact orbit profile."},
		{"id": "debrief_failed", "base": "report_failure", "status": "failed", "run_status": "completed", "observations": 0, "returned": 0, "observation_ratio": 0.0, "return_ratio": 0.0, "score": 0, "explanation": "SYNTHETIC: no observations or returned data were recorded; the supplied cause is low battery.", "cause": "LOW_BATTERY", "next": "SYNTHETIC: select a larger battery."},
		{"id": "debrief_zero_score", "base": "report_failure", "status": "failed", "run_status": "completed", "observations": 0, "returned": 0, "observation_ratio": 0.0, "return_ratio": 0.0, "score": 0, "explanation": "SYNTHETIC: a completed failed run with a valid supplied score of zero.", "cause": "", "next": "SYNTHETIC: review the selected design."},
		{"id": "debrief_aborted", "base": "report_partial", "status": "failed", "run_status": "aborted", "observations": 3, "returned": 4, "observation_ratio": 1.0, "return_ratio": 1.0, "score": null, "explanation": "Mission aborted before completion.", "cause": "", "next": "SYNTHETIC: review the run configuration and retry."},
		{"id": "debrief_missing_optional", "base": "report_partial", "status": "partial", "run_status": "completed", "observations": 1, "returned": 2, "observation_ratio": 0.3333333333, "return_ratio": 0.5, "score": 42, "explanation": "SYNTHETIC: the optional data-return completion ratio was not supplied.", "cause": "", "next": "SYNTHETIC: compare the supplied raw counters."},
		{"id": "debrief_missing_score", "base": "report_partial", "status": "partial", "run_status": "completed", "observations": 1, "returned": 2, "observation_ratio": 0.3333333333, "return_ratio": 0.5, "score": 42, "explanation": "SYNTHETIC: no score was supplied with this report.", "cause": "", "next": "SYNTHETIC: inspect the report metadata."},
		{"id": "debrief_awaiting", "base": "report_missing", "status": "partial", "run_status": "completed", "observations": 1, "returned": 2, "observation_ratio": 0.3333333333, "return_ratio": 0.5, "score": 42, "explanation": "", "cause": "", "next": ""},
		{"id": "debrief_stale", "base": "report_partial", "status": "partial", "run_status": "completed", "observations": 1, "returned": 2, "observation_ratio": 0.3333333333, "return_ratio": 0.5, "score": 42, "explanation": "SYNTHETIC STALE REPORT - MUST NOT BE DISPLAYED", "cause": "NO_LINK_WINDOW", "next": "SYNTHETIC STALE EXPERIMENT"},
		{"id": "debrief_missing_event", "base": "report_partial", "status": "partial", "run_status": "completed", "observations": 1, "returned": 2, "observation_ratio": 0.3333333333, "return_ratio": 0.5, "score": 42, "explanation": "SYNTHETIC: keep this current-run explanation visible even though its linked event is unavailable.", "cause": "NO_LINK_WINDOW", "next": "SYNTHETIC: choose a higher-contact orbit profile."},
		{"id": "debrief_long", "base": "report_partial", "status": "partial", "run_status": "completed", "observations": 1, "returned": 2, "observation_ratio": 0.3333333333, "return_ratio": 0.5, "score": 42, "explanation": "SYNTHETIC long explanation. ", "cause": "NO_LINK_WINDOW", "next": "SYNTHETIC: keep one design change identifiable."},
		{"id": "debrief_evaluation_error", "base": "report_partial", "status": "partial", "run_status": "completed", "observations": 1, "returned": 2, "observation_ratio": 0.3333333333, "return_ratio": 0.5, "score": 42, "explanation": "", "cause": "", "next": ""},
		{"id": "debrief_prelaunch", "base": "report_failure", "status": "failed", "run_status": "completed", "observations": 0, "returned": 0, "observation_ratio": 0.0, "return_ratio": 0.0, "score": 0, "explanation": "", "cause": "", "next": ""},
		{"id": "debrief_missing_credit", "base": "report_partial", "status": "partial", "run_status": "completed", "observations": 1, "returned": 2, "observation_ratio": 0.3333333333, "return_ratio": 0.5, "score": 42, "explanation": "SYNTHETIC: source labels and credits were not supplied.", "cause": "", "next": "SYNTHETIC: request the source metadata from KE2."},
	]:
		_debrief_cases[specification.id] = _make_report_case(original[specification.base], specification)


func _make_report_case(base: Dictionary, spec: Dictionary) -> Dictionary:
	var reply := base.duplicate(true)
	var run_id: String = "SYNTHETIC-A05-RUN-" + String(spec.id).to_upper()
	var selection: Dictionary = reply.payload.context.config_selections
	var context := {"run_id": run_id, "synthetic": true,
		"config_selections": selection.duplicate(true),
		"config": {"mission": {"title": selection.label, "target_region": selection.target_id, "required_observations": 3, "required_returned_data_mb": 4}, "design": {"launch_profile_id": selection.profile_id}},
		"profile_metadata": {"id": selection.profile_id, "label": selection.profile_label, "source_label": "SYNTHETIC sample profile source", "credit": "SYNTHETIC teaching values; not a verified NASA rule or production ledger."},
		"source_metadata": {"SYNTHETIC-PROFILE-SOURCE-001": {"title": "SYNTHETIC teaching profile", "credit": "SYNTHETIC authored fixture values; KE2 ledger approval pending.", "url": "synthetic://orbitbridge/a05/profile"}},
		"visual_attributions": [
			{"title": "Mission Visualization", "url": "https://nasa.github.io/mission-viz/", "credit": "Preview attribution from A04 source notes: position/progression visual cues; production credit unverified."},
			{"title": "Trajectory from GMAT", "url": "https://nasa.github.io/mission-viz/X3Dom/20160129_Earth_MoonMission_X3D.html", "credit": "Central body, trajectory and spacecraft-marker cue only; no GMAT data/code/assets reused."},
			{"title": "Elliptical Orbit Simulator", "url": "https://nasa.github.io/mission-viz/RMarkdown/Elliptical_Orbit_Design.html", "credit": "Flat ellipse and blue central-body cue only; no orbital propagator reused."},
		]}
	var terminal := {"run_id": run_id, "event_id": run_id + "-EVENT-TERMINAL-008", "step_index": 8, "step": 8, "type": "run_finished", "code": "RUN_FINISHED", "message": "SYNTHETIC run finished", "label": "SYNTHETIC run finished"}
	var events: Array = []
	var causes: Array = []
	if not String(spec.cause).is_empty():
		var cause_event := {"run_id": run_id, "event_id": run_id + "-EVENT-CAUSE-004", "step_index": 4, "step": 4, "type": "action_blocked", "code": spec.cause,
			"message": "SYNTHETIC Transmit blocked: no ground contact at step 4" if spec.cause == "NO_LINK_WINDOW" else "SYNTHETIC Observe blocked: low battery at step 4"}
		cause_event.label = cause_event.message
		events.append(cause_event)
		causes.append({"code": spec.cause, "segment": "operations", "explanation": "SYNTHETIC: only one usable contact window." if spec.cause == "NO_LINK_WINDOW" else "SYNTHETIC: energy was unavailable for the observation.", "evidence_event_ids": [cause_event.event_id]})
	events.append(terminal)
	var report := {"schema_version": 1, "run_id": run_id, "mission_id": selection.mission_id, "status": spec.status, "run_status": spec.run_status,
		"observations_completed": spec.observations, "required_observations": 3, "returned_data_mb": spec.returned, "required_returned_data_mb": 4,
		"observation_completion_ratio": spec.observation_ratio, "data_return_completion_ratio": spec.return_ratio,
		"score": spec.score, "explanation": spec.explanation, "root_causes": causes, "next_experiment": spec.next,
		"source_ids": ["SYNTHETIC-PROFILE-SOURCE-001"], "comparison": null}
	if not String(spec.cause).is_empty():
		report.failed_constraint = "SYNTHETIC returned-data goal" if spec.cause == "NO_LINK_WINDOW" else "SYNTHETIC energy constraint"
	var state: Dictionary = reply.payload.state
	state.run_id = run_id
	state.phase = "finished"
	state.lifecycle = "terminal"
	state.run_status = spec.run_status
	state.observations_completed = spec.observations
	state.returned_data_mb = spec.returned
	state.returned_mb = spec.returned
	state.events = events
	match spec.id:
		"debrief_missing_optional":
			report.erase("data_return_completion_ratio")
		"debrief_missing_score":
			report.erase("score")
		"debrief_awaiting":
			report = {}
		"debrief_stale":
			# Its event IDs still match current history: the different report run wins.
			report.run_id = "SYNTHETIC-A05-OTHER-RUN"
		"debrief_missing_event":
			report.root_causes[0].evidence_event_ids = ["SYNTHETIC-A05-EVENT-NOT-IN-ACTIVE-RUN"]
		"debrief_long":
			report.explanation = "SYNTHETIC explanation: these are illustrative report values, and no extra cause is inferred. ".repeat(45) + "End of synthetic explanation."
			context.profile_metadata.credit = "SYNTHETIC extended profile credit. This is sample metadata, not an approved real source ledger. ".repeat(40) + "End of synthetic profile credit."
			context.source_metadata["SYNTHETIC-PROFILE-SOURCE-001"].credit = "SYNTHETIC source credit: no source confirmation or production attribution is claimed. ".repeat(40) + "End of synthetic source credit."
		"debrief_evaluation_error":
			report = {}
			context.evaluation_error = {"code": "INVALID_EVALUATION_INPUT", "field_path": "final_state", "message": "SYNTHETIC evaluator could not read the final state.", "suggested_fix": "SYNTHETIC: request a valid final-state payload.", "run_id": run_id}
		"debrief_prelaunch":
			report = {}
			state.phase = "readiness"
			context.presentation_route = "readiness"
			context.readiness_message = "SYNTHETIC design rejected before launch; no mission report or score."
		"debrief_missing_credit":
			context.profile_metadata.erase("source_label")
			context.profile_metadata.erase("credit")
			context.source_metadata = {}
			report.source_ids = ["SYNTHETIC-UNRESOLVED-SOURCE"]
	reply.payload = {"context": context, "state": state, "report": report}
	reply.expected = {"accepted": spec.id != "debrief_stale"}
	return reply


func catalog() -> Dictionary:
	var cases := super.catalog()
	if _preview_active():
		cases.merge(_debrief_cases.duplicate(true))
	return cases


func choose_case(case_id: String) -> bool:
	if _preview_active() and _debrief_cases.has(case_id):
		_selected = case_id
		return true
	return super.choose_case(case_id)


func open_run(run_id: String) -> Dictionary:
	if not _debrief_cases.has(_selected):
		return super.open_run(run_id)
	open_calls += 1
	if not _preview_active():
		return {"ok": false, "error": "preview_entry_required"}
	if run_id != _debrief_cases[_selected].payload.context.run_id:
		return {"ok": false, "error": "stale_run_id"}
	return _debrief_cases[_selected].duplicate(true)


func request_action(run_id: String, action_id: StringName) -> Dictionary:
	if not _debrief_cases.has(_selected):
		return super.request_action(run_id, action_id)
	action_calls += 1
	return {"ok": false, "error": "scripted_action_unavailable" if _preview_active() else "preview_entry_required"}
