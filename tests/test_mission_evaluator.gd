extends SceneTree
## Headless KE2 setup, scoring, and input-validation checks using v1 fixtures.
## Expected outcomes come from contracts.md and literal contract examples.

const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const Feedback = preload("res://scripts/evaluation/mission_feedback.gd")
const SurveyProposal = preload("res://tests/fixtures/ke2_survey_scoring_proposal.gd")
const EXAMPLES: String = "res://docs/contracts/v1-draft/"
const REPORT_FIELDS: Array[String] = [
	"schema_version", "run_id", "mission_id", "run_status", "status",
	"observations_completed", "required_observations", "returned_data_mb",
	"required_returned_data_mb", "observation_completion_ratio",
	"data_return_completion_ratio", "score", "explanation", "root_causes",
	"next_experiment", "source_ids", "comparison",
]
const PENDING_CASES: Array[String] = [
	"T07 controlled retry deltas await comparison implementation",
	"T08 baseline eligibility awaits comparison implementation",
	"T11 actual 1329 g validation and Builder check await KE1/SE integration",
	"T12 actual 1330/1331 g and profile-switch checks await KE1/SE integration",
	"INTEGRATION real HPC trace, Results, duplicate publication, and retry/reset",
]

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	var config: Dictionary = _fixture("mission-config.example.json")
	var state: Dictionary = _fixture("mission-state.example.json")
	var completed: Dictionary = _fixture("mission-report-completed.example.json")
	var aborted: Dictionary = _fixture("mission-report-aborted.example.json")
	if _failed > 0:
		quit(1)
		return

	_check(
		"SETUP01 completed mock wrapper",
		Evaluator.mock_report_result(completed), _fixture("evaluation-completed.example.json")
	)
	_check(
		"SETUP02 aborted mock wrapper and null score",
		Evaluator.mock_report_result(aborted), _fixture("evaluation-aborted.example.json")
	)

	var copied: Dictionary = Evaluator.mock_report_result(completed)
	var copied_causes: Array = copied.get("report", {}).get("root_causes", [])
	if not copied_causes.is_empty():
		copied_causes[0].get("evidence_event_ids", []).append("changed-preview")
	_check(
		"SETUP03 nested mock values are independent",
		completed.get("root_causes"), _fixture("mission-report-completed.example.json").get("root_causes")
	)

	var incomplete: Dictionary = completed.duplicate(true)
	incomplete.erase("score")
	var invalid_mock: Dictionary = Evaluator.mock_report_result(incomplete)
	_check_error("SETUP04 incomplete mock returns a field error", invalid_mock, "mock_report.score", null)

	_check(
		"SETUP05 missing inputs use the agreed top-level error",
		Evaluator.evaluate_mission({}, {}, []), _fixture("evaluation-top-level-error.example.json")
	)
	_check(
		"SETUP06 operating state uses the agreed nonterminal error",
		Evaluator.evaluate_mission(config, state, []), _fixture("evaluation-nonterminal-error.example.json")
	)

	var terminal: Dictionary = state.duplicate(true)
	terminal["phase"] = "finished"
	terminal["run_status"] = "completed"
	terminal["step_index"] = terminal["total_steps"]
	var events: Array = _fixture("completed-report.evidence-events.example.json", TYPE_ARRAY)
	var config_before: Dictionary = config.duplicate(true)
	var state_before: Dictionary = terminal.duplicate(true)
	var events_before: Array = events.duplicate(true)
	var baseline_before: Dictionary = completed.duplicate(true)
	var evaluated: Dictionary = Evaluator.evaluate_mission(config, terminal, events, completed)
	var actual_fields: Array = evaluated.get("report", {}).keys()
	var expected_fields: Array = REPORT_FIELDS.duplicate()
	actual_fields.sort()
	expected_fields.sort()
	_check(
		"SETUP07 terminal evaluation returns all agreed report fields",
		{"ok": evaluated.get("ok"), "report_fields": actual_fields},
		{"ok": true, "report_fields": expected_fields}
	)
	_check(
		"SETUP08 evaluation preserves every input",
		{"config": config, "state": terminal, "events": events, "baseline": completed},
		{"config": config_before, "state": state_before, "events": events_before, "baseline": baseline_before}
	)

	terminal["run_status"] = "aborted"
	var evaluated_abort: Dictionary = Evaluator.evaluate_mission(config, terminal, [])
	var abort_report: Dictionary = evaluated_abort.get("report", {})
	_check(
		"SETUP09 abort evaluation returns a valid failed report with null score",
		{"ok": evaluated_abort.get("ok"), "status": abort_report.get("status"), "score": abort_report.get("score", "missing")},
		{"ok": true, "status": "failed", "score": null}
	)

	_test_scoring(config, state)
	_test_invalid_inputs(config, state)
	_test_feedback(config, state)
	_test_hpc_adapter(config, state)
	_test_survey_delivery_measure(config)
	_test_survey_scoring_proposal(config)
	var hpc_runtime_checked: bool = false
	if "--ke2-standalone" in OS.get_cmdline_user_args():
		print("HPC runtime checks deferred by --ke2-standalone.")
	else:
		hpc_runtime_checked = _test_hpc_runtime()
		if hpc_runtime_checked:
			_test_survey_native_packets()
	for pending: String in PENDING_CASES:
		print("PENDING " + (pending.replace("real HPC trace, ", "") if hpc_runtime_checked else pending))
	print("Evaluator checks: %d passed, %d failed, %d pending." % [_passed, _failed, PENDING_CASES.size()])
	quit(0 if _failed == 0 else 1)


func _test_scoring(config: Dictionary, state: Dictionary) -> void:
	var cases: Array = [
		{"name": "T01 exact thresholds", "observations": 3, "returned": 30, "target": 3, "status": "success", "score": 100},
		{"name": "T02 partial data", "observations": 3, "returned": 10, "target": 3, "status": "partial", "score": 67},
		{"name": "T03 onboard data excluded", "observations": 3, "returned": 0, "target": 3, "status": "partial", "score": 50},
		{"name": "T04 no progress", "observations": 0, "returned": 0, "target": 3, "status": "failed", "score": 0},
		{"name": "T05 excess observations", "observations": 4, "returned": 30, "target": 3, "status": "success", "score": 100},
		{"name": "T06 changed observation target", "observations": 3, "returned": 30, "target": 4, "status": "partial", "score": 88},
		{"name": "SCORE excess captures cannot replace returned data", "observations": 100, "returned": 0, "target": 3, "status": "partial", "score": 50, "ratios": [1.0, 0.0]},
		{"name": "SCORE excess returned data cannot replace captures", "observations": 0, "returned": 300, "target": 3, "status": "partial", "score": 50, "ratios": [0.0, 1.0]},
		{"name": "SCORE extra returned MB preserved", "observations": 3, "returned": 45, "target": 3, "status": "success", "score": 100},
		{"name": "SCORE below half-point boundary", "observations": 2, "returned": 29.992, "target": 4, "data_target": 40, "status": "partial", "score": 62},
		{"name": "SCORE exact half-point boundary", "observations": 2, "returned": 30, "target": 4, "data_target": 40, "status": "partial", "score": 63},
		{"name": "SCORE above half-point boundary", "observations": 2, "returned": 30.008, "target": 4, "data_target": 40, "status": "partial", "score": 63},
		{"name": "SCORE positive progress may round to zero", "observations": 0, "returned": 0.001, "target": 3, "status": "partial", "score": 0},
		{"name": "SCORE whole-valued floats accepted", "observations": 3.0, "returned": 30.0, "target": 3.0, "status": "success", "score": 100},
		{"name": "SCORE fractional MB target accepted", "observations": 3, "returned": 30.5, "target": 3, "data_target": 30.5, "status": "success", "score": 100},
	]
	for case: Dictionary in cases:
		var run_config: Dictionary = config.duplicate(true)
		run_config["mission"]["required_observations"] = case["target"]
		run_config["mission"]["required_returned_data_mb"] = case.get("data_target", 30)
		var terminal: Dictionary = _terminal(state, case["observations"], case["returned"])
		terminal["stored_data_mb"] = 30.0
		_check_report(case["name"], run_config, terminal, case["status"], case["score"])
		if case.has("ratios"):
			var report: Dictionary = Evaluator.evaluate_mission(run_config, terminal, []).get("report", {})
			_check(
				case["name"] + " caps each ratio",
				[report.get("observation_completion_ratio"), report.get("data_return_completion_ratio")],
				case["ratios"]
			)

	var vectors: Dictionary = _fixture("scoring-cases.example.json")
	if not vectors.get("cases") is Array:
		_check("Fixture scoring cases have an array root", vectors.get("cases"), "Array of scoring cases")
		return
	for case: Dictionary in vectors["cases"]:
		var run_config: Dictionary = config.duplicate(true)
		run_config["mission"]["required_observations"] = case["required_observations"]
		run_config["mission"]["required_returned_data_mb"] = case["required_returned_data_mb"]
		var terminal: Dictionary = _terminal(state, case["observations_completed"], case["returned_data_mb"])
		terminal["run_status"] = case["run_status"]
		_check_report(case["name"], run_config, terminal, case["expected_status"], case["expected_score"])

	var run_config: Dictionary = config.duplicate(true)
	run_config["mission"]["required_returned_data_mb"] = 1.0e-300
	var terminal: Dictionary = _terminal(state, 4, 1.0e300)
	_check_report("SCORE finite extreme MB values cap safely", run_config, terminal, "success", 100)

	terminal = _terminal(state, 3, 10)
	var first: Dictionary = Evaluator.evaluate_mission(config, terminal, [])
	var second: Dictionary = Evaluator.evaluate_mission(config, terminal, [])
	_check("SCORE deterministic reports", first, second)
	first.get("report", {}).get("root_causes", []).append({"changed": true})
	_check("SCORE fresh nested report containers", second.get("report", {}).get("root_causes"), [])
	_check(
		"SCORE ratios retain fractional completion for percentage display",
		{
			"observation_ratio": second.get("report", {}).get("observation_completion_ratio"),
			"data_ratio": second.get("report", {}).get("data_return_completion_ratio"),
		},
		{"observation_ratio": 0.75, "data_ratio": 1.0 / 3.0}
	)

	terminal = _terminal(state, 4, 30)
	terminal["run_status"] = "aborted"
	terminal["step_index"] = 2
	_check_report("T14 early abort after targets were met", config, terminal, "failed", null)
	terminal = _terminal(state, 0, 0)
	terminal["run_status"] = "aborted"
	terminal["step_index"] = 0
	_check_report("T14 abort before progress", config, terminal, "failed", null)
	var abort_report: Dictionary = Evaluator.evaluate_mission(config, terminal, []).get("report", {})
	_check(
		"T14 abort explanation identifies termination",
		str(abort_report.get("explanation", "")).to_lower().contains("aborted"), true
	)


func _test_invalid_inputs(config: Dictionary, state: Dictionary) -> void:
	var cases: Array = [
		{"side": "mission", "field": "required_observations", "values": [0, -1, 1.5, 21, NAN, INF, "3", true, null]},
		{"side": "mission", "field": "required_returned_data_mb", "values": [0, -1, NAN, INF, "30", true, null]},
		{"side": "mission", "field": "duration_orbits", "values": [0, -1, 1.5, 13]},
		{"side": "state", "field": "observations_completed", "values": [-1, 1.5, NAN, INF, "3", true, null]},
		{"side": "state", "field": "returned_data_mb", "values": [-1, NAN, INF, "30", true, null]},
		{"side": "state", "field": "stored_data_mb", "values": [-1, NAN, INF, "30", true, null]},
		{"side": "state", "field": "step_index", "values": [-1, 1.5, 13, null]},
		{"side": "state", "field": "total_steps", "values": [0, -1, INF, null]},
	]
	for case: Dictionary in cases:
		for value: Variant in case["values"]:
			var run_config: Dictionary = config.duplicate(true)
			var terminal: Dictionary = _terminal(state, 3, 10)
			var path: String = "final_state." + case["field"]
			if case["side"] == "mission":
				run_config["mission"][case["field"]] = value
				path = "config.mission." + case["field"]
			else:
				terminal[case["field"]] = value
			var result: Dictionary = Evaluator.evaluate_mission(run_config, terminal, [])
			_check_error(
				"INVALID %s rejects %s %s" % [path, type_string(typeof(value)), var_to_str(value)],
				result, path, terminal["run_id"]
			)

	var missing: Dictionary = config.duplicate(true)
	missing["mission"].erase("required_observations")
	var result: Dictionary = Evaluator.evaluate_mission(missing, _terminal(state, 3, 10), [])
	_check_error("INVALID missing target", result, "config.mission.required_observations", state["run_id"])
	var terminal: Dictionary = _terminal(state, 3, 10)
	terminal.erase("returned_data_mb")
	result = Evaluator.evaluate_mission(config, terminal, [])
	_check_error("INVALID missing returned counter", result, "final_state.returned_data_mb", state["run_id"])
	terminal = _terminal(state, 3, 10)
	terminal["step_index"] = 2
	result = Evaluator.evaluate_mission(config, terminal, [])
	_check_error("INVALID incomplete step with completed status", result, "final_state.step_index", state["run_id"])
	terminal = _terminal(state, 3, 10)
	terminal["run_status"] = "unknown"
	result = Evaluator.evaluate_mission(config, terminal, [])
	_check_error("INVALID unknown terminal status", result, "final_state.run_status", state["run_id"])

	var zero_targets: Dictionary = config.duplicate(true)
	zero_targets["mission"]["required_observations"] = 0
	zero_targets["mission"]["required_returned_data_mb"] = 0
	result = Evaluator.evaluate_mission(zero_targets, _terminal(state, 3, 10), [])
	_check_error("T13 both zero targets rejected", result, "config.mission.required_observations", state["run_id"])
	terminal = _terminal(state, -1, 10)
	terminal["run_status"] = "aborted"
	result = Evaluator.evaluate_mission(config, terminal, [])
	_check_error("INVALID abort still validates counters", result, "final_state.observations_completed", state["run_id"])
	terminal = _terminal(state, 3, 10)
	terminal.erase("observations_completed")
	result = Evaluator.evaluate_mission(config, terminal, [])
	_check_error("INVALID missing capture counter", result, "final_state.observations_completed", state["run_id"])
	terminal = _terminal(state, 3, 10)
	terminal["schema_version"] = true
	result = Evaluator.evaluate_mission(config, terminal, [])
	_check_error("INVALID boolean schema version", result, "final_state.schema_version", state["run_id"])
	terminal = _terminal(state, 3, 10)
	result = Evaluator.evaluate_mission(config, terminal, ["malformed event"])
	_check_error("INVALID event item type", result, "events[0]", state["run_id"])


func _test_feedback(config: Dictionary, state: Dictionary) -> void:
	var recognized: Array[Dictionary] = [
		{
			"code": "NO_LINK_WINDOW", "action": "transmit", "segment": "ground",
			"observations": 4, "returned": 10, "score": 67,
			"cause": "no ground-contact window was available",
			"next": "Retry and transmit during an available ground-contact window.",
		},
		{
			"code": "LOW_BATTERY", "action": "observe", "segment": "space",
			"observations": 3, "returned": 30, "score": 88,
			"cause": "battery energy was insufficient",
			"next": "Try Power Save before that operation while keeping the other settings fixed.",
		},
		{
			"code": "LOW_BATTERY", "action": "transmit", "segment": "space",
			"observations": 4, "returned": 10, "score": 67,
			"cause": "battery energy was insufficient",
			"next": "Try Power Save before that operation while keeping the other settings fixed.",
		},
		{
			"code": "STORAGE_FULL", "action": "observe", "segment": "space",
			"observations": 3, "returned": 30, "score": 88,
			"cause": "would not fit in the remaining onboard storage",
			"next": "Transmit stored data during an available contact window before observing again.",
		},
		{
			"code": "TARGET_NOT_VISIBLE", "action": "observe", "segment": "space",
			"observations": 3, "returned": 30, "score": 88,
			"cause": "the selected target was outside the observation window",
			"next": "Retry and observe during a target-access window.",
		},
	]
	for case: Dictionary in recognized:
		var event: Dictionary = _blocked_event(case["code"], case["action"])
		var terminal: Dictionary = _terminal(state, case["observations"], case["returned"])
		var report: Dictionary = Evaluator.evaluate_mission(config, terminal, [event]).get("report", {})
		var causes: Array = report.get("root_causes", [])
		var cause: Dictionary = causes[0] if not causes.is_empty() else {}
		var event_feedback: Dictionary = Feedback.explain_event(event)
		_check(
			"T09 recognized %s/%s" % [case["code"], case["action"]],
			{
				"status": report.get("status"), "score": report.get("score"),
				"cause_count": causes.size(), "code": cause.get("code"),
				"segment": cause.get("segment"), "references": cause.get("evidence_event_ids"),
				"has_cause": str(cause.get("explanation", "")).contains(case["cause"]),
				"has_step": str(cause.get("explanation", "")).contains("step 2"),
				"has_correction": str(cause.get("explanation", "")).contains(case["next"]),
				"next": report.get("next_experiment"), "event_next": event_feedback.get("next_experiment"),
			},
			{
				"status": "partial", "score": case["score"], "cause_count": 1,
				"code": case["code"], "segment": case["segment"], "references": ["evt_feedback"],
				"has_cause": true, "has_step": true, "has_correction": true,
				"next": case["next"], "event_next": case["next"],
			}
		)

	var recorded: Array = _fixture("completed-report.evidence-events.example.json", TYPE_ARRAY)
	var report: Dictionary = Evaluator.evaluate_mission(config, _terminal(state, 3, 30), recorded).get("report", {})
	var recorded_references: Array = []
	for cause: Dictionary in report.get("root_causes", []):
		recorded_references.append_array(cause.get("evidence_event_ids", []))
	_check("FEEDBACK signed evt_007 reference resolves", recorded_references, ["evt_007"])

	_test_feedback_fallback(config, state)
	_test_feedback_ordering(config, state)
	_test_abort_feedback(config, state)

	var terminal: Dictionary = _terminal(state, 4, 30)
	report = Evaluator.evaluate_mission(config, terminal, [_blocked_event("LOW_BATTERY", "observe")]).get("report", {})
	_check(
		"FEEDBACK success acknowledges goals without blaming historical blocks",
		{
			"causes": report.get("root_causes"), "score": report.get("score"),
			"acknowledges_success": str(report.get("explanation", "")).contains("Both mission requirements were met"),
			"next": report.get("next_experiment"),
		},
		{
			"causes": [], "score": 100, "acknowledges_success": true,
			"next": "Keep the scenario and targets fixed and change one operation on the next attempt.",
		}
	)

	terminal = _terminal(state, 4, 0)
	terminal["stored_data_mb"] = 30
	report = Evaluator.evaluate_mission(config, terminal, []).get("report", {})
	_check(
		"FEEDBACK onboard data remains distinct from Earth reception",
		{
			"score": report.get("score"), "returned": report.get("returned_data_mb"),
			"mentions_onboard": str(report.get("explanation", "")).contains("30 MB remain onboard"),
			"mentions_received": str(report.get("explanation", "")).contains("0/30")
			and str(report.get("explanation", "")).contains("MB received on Earth"),
		},
		{"score": 50, "returned": 0, "mentions_onboard": true, "mentions_received": true}
	)


func _test_feedback_fallback(config: Dictionary, state: Dictionary) -> void:
	var missing_id: Dictionary = _blocked_event("LOW_BATTERY", "observe")
	missing_id.erase("event_id")
	var missing_step: Dictionary = _blocked_event("LOW_BATTERY", "observe")
	missing_step.erase("step_index")
	var cases: Array[Dictionary] = [
		{"name": "missing events", "events": []},
		{"name": "unknown code", "events": [_blocked_event("UNKNOWN_REASON", "observe")]},
		{"name": "legacy whole-run code", "events": [_blocked_event("SKIP_POWER", "observe")]},
		{"name": "other HPC code", "events": [_blocked_event("NO_DATA", "transmit")]},
		{"name": "missing event ID", "events": [missing_id]},
		{"name": "missing event step", "events": [missing_step]},
		{"name": "empty event", "events": [{}]},
		{"name": "wrong code/action pair", "events": [_blocked_event("NO_LINK_WINDOW", "observe")]},
		{"name": "data goal met", "events": [_blocked_event("NO_LINK_WINDOW", "transmit")], "returned": 30},
		{"name": "observation goal met", "events": [_blocked_event("LOW_BATTERY", "observe")], "observations": 4},
		{"name": "storage block alone cannot explain return shortfall", "events": [_blocked_event("STORAGE_FULL", "observe")], "observations": 4},
		{"name": "visibility alone cannot explain return shortfall", "events": [_blocked_event("TARGET_NOT_VISIBLE", "observe")], "observations": 4},
	]
	var base_event: Dictionary = _blocked_event("LOW_BATTERY", "observe")
	for change: Dictionary in [
		{"field": "type", "value": "warning"},
		{"field": "type", "value": "action_accepted"},
		{"field": "event_id", "value": "  "},
		{"field": "step_index", "value": -1},
		{"field": "step_index", "value": 1.5},
		{"field": "step_index", "value": NAN},
		{"field": "step_index", "value": true},
		{"field": "step_index", "value": 12},
		{"field": "delta_returned_data_mb", "value": 1},
		{"field": "delta_energy_wh", "value": NAN},
		{"field": "delta_observations", "value": true},
		{"field": "run_id", "value": "other-run"},
		{"field": "mission_id", "value": "other-mission"},
	]:
		var event: Dictionary = base_event.duplicate(true)
		event[change["field"]] = change["value"]
		cases.append({"name": "%s=%s" % [change["field"], var_to_str(change["value"])], "events": [event]})

	for case: Dictionary in cases:
		var terminal: Dictionary = _terminal(state, case.get("observations", 3), case.get("returned", 10))
		var report: Dictionary = Evaluator.evaluate_mission(config, terminal, case["events"]).get("report", {})
		_check(
			"T10 neutral fallback for " + case["name"],
			{
				"causes": report.get("root_causes"),
				"neutral": str(report.get("explanation", "")).contains("Available events do not establish the cause"),
				"has_next": not str(report.get("next_experiment", "")).is_empty(),
			},
			{"causes": [], "neutral": true, "has_next": true}
		)


func _test_feedback_ordering(config: Dictionary, state: Dictionary) -> void:
	var terminal: Dictionary = _terminal(state, 3, 10)
	var events: Array = [
		_blocked_event("NO_LINK_WINDOW", "transmit", 0, "evt_ground"),
		_blocked_event("LOW_BATTERY", "observe", 5, "evt_late"),
		_blocked_event("TARGET_NOT_VISIBLE", "observe", 1, "evt_first"),
		_blocked_event("STORAGE_FULL", "observe", 1, "evt_second"),
	]
	var config_before: Dictionary = config.duplicate(true)
	var state_before: Dictionary = terminal.duplicate(true)
	var events_before: Array = events.duplicate(true)
	var first: Dictionary = Evaluator.evaluate_mission(config, terminal, events)
	var second: Dictionary = Evaluator.evaluate_mission(config, terminal, events)
	var references: Array = []
	for cause: Dictionary in first.get("report", {}).get("root_causes", []):
		references.append(cause["evidence_event_ids"][0])
	_check(
		"FEEDBACK orders unmet observation goal, step, then original event order",
		references, ["evt_first", "evt_second", "evt_late", "evt_ground"]
	)
	_check("FEEDBACK repeated inputs give identical reports", first, second)
	var causes: Array = first.get("report", {}).get("root_causes", [])
	if not causes.is_empty():
		causes[0]["evidence_event_ids"].append("changed-output")
	_check(
		"FEEDBACK preserves config, state, and event ordering",
		{"config": config, "state": terminal, "events": events},
		{"config": config_before, "state": state_before, "events": events_before}
	)
	_check(
		"FEEDBACK output references are independent",
		second.get("report", {}).get("root_causes", [])[0].get("evidence_event_ids"), ["evt_first"]
	)

	var event: Dictionary = _blocked_event("LOW_BATTERY", "observe")
	var report: Dictionary = Evaluator.evaluate_mission(config, terminal, [event, event.duplicate(true)]).get("report", {})
	_check("FEEDBACK identical duplicate event is cited once", report.get("root_causes", []).size(), 1)
	var conflicting: Dictionary = event.duplicate(true)
	conflicting["code"] = "TARGET_NOT_VISIBLE"
	report = Evaluator.evaluate_mission(config, terminal, [event, conflicting]).get("report", {})
	_check("FEEDBACK conflicting event IDs give neutral causes", report.get("root_causes"), [])

	event = _blocked_event("LOW_BATTERY", "observe")
	event["run_id"] = terminal["run_id"]
	event["mission_id"] = terminal["mission_id"]
	event["message"] = "Unverified custom text claiming an unrelated hardware failure."
	report = Evaluator.evaluate_mission(config, terminal, [event]).get("report", {})
	_check(
		"FEEDBACK uses confirmed code semantics and matching identities",
		{
			"count": report.get("root_causes", []).size(),
			"copied_unverified_text": str(report.get("explanation", "")).contains("unrelated hardware failure"),
		},
		{"count": 1, "copied_unverified_text": false}
	)


func _test_abort_feedback(config: Dictionary, state: Dictionary) -> void:
	for reason: Variant in [null, "Player requested stop.", {"message": "Operator ended the run."}, 42, {"code": "UNKNOWN"}]:
		var terminal: Dictionary = _terminal(state, 3, 10)
		terminal["run_status"] = "aborted"
		terminal["step_index"] = 3
		if reason != null:
			terminal["abort_reason"] = reason
		var report: Dictionary = Evaluator.evaluate_mission(config, terminal, [_blocked_event("LOW_BATTERY", "observe")]).get("report", {})
		var expected_reason: String = ""
		if reason is String:
			expected_reason = reason
		elif reason is Dictionary:
			expected_reason = reason.get("message", "")
		_check(
			"FEEDBACK aborted reason handling " + var_to_str(reason),
			{
				"status": report.get("status"), "score": report.get("score", "missing"),
				"causes": report.get("root_causes"),
				"aborted_label": str(report.get("explanation", "")).contains("Mission aborted"),
				"has_recorded_reason": str(report.get("explanation", "")).contains("Recorded abort reason was"),
				"includes_reason": expected_reason.is_empty() or str(report.get("explanation", "")).contains(expected_reason),
				"inferred_power_cause": str(report.get("explanation", "")).contains("battery energy was insufficient"),
			},
			{
				"status": "failed", "score": null, "causes": [], "aborted_label": true,
				"has_recorded_reason": not expected_reason.is_empty(), "includes_reason": true,
				"inferred_power_cause": false,
			}
		)


## Synthetic v1 event using the code/action meanings verified in HPC's branch.
func _blocked_event(code: String, action: String, step: int = 2, event_id: String = "evt_feedback") -> Dictionary:
	return {
		"event_id": event_id, "step_index": step, "action": action,
		"type": "action_blocked", "code": code, "message": "Synthetic blocked action fixture.",
		"delta_energy_wh": 0.0, "delta_stored_data_mb": 0.0,
		"delta_returned_data_mb": 0.0, "delta_observations": 0,
	}


func _terminal(state: Dictionary, observations: Variant, returned_mb: Variant) -> Dictionary:
	var terminal: Dictionary = state.duplicate(true)
	terminal["phase"] = "finished"
	terminal["run_status"] = "completed"
	terminal["step_index"] = terminal["total_steps"]
	terminal["observations_completed"] = observations
	terminal["returned_data_mb"] = returned_mb
	return terminal


func _check_report(
	label: String, config: Dictionary, terminal: Dictionary,
	expected_status: String, expected_score: Variant
) -> void:
	# JSON decodes whole expected scores as floats. The public score is an integer.
	if expected_score is float:
		if not is_finite(expected_score) or expected_score != floorf(expected_score):
			_check(label + " has a whole expected score", expected_score, "finite whole score")
			return
		expected_score = int(expected_score)
	var result: Dictionary = Evaluator.evaluate_mission(config, terminal, [])
	var report: Dictionary = result.get("report", {})
	var expected: Dictionary = {
		"ok": true,
		"schema_version": 1,
		"run_id": terminal["run_id"],
		"mission_id": terminal["mission_id"],
		"run_status": terminal["run_status"],
		"status": expected_status,
		"score": expected_score,
		"score_type": TYPE_NIL if expected_score == null else TYPE_INT,
		"observations_completed": terminal["observations_completed"],
		"returned_data_mb": terminal["returned_data_mb"],
		"required_observations": config["mission"]["required_observations"],
		"required_returned_data_mb": config["mission"]["required_returned_data_mb"],
	}
	var actual: Dictionary = {"ok": result.get("ok")}
	for field: String in expected:
		if field not in ["ok", "score_type"]:
			actual[field] = report.get(field, "<missing>")
	actual["score_type"] = typeof(report.get("score", "<missing>"))
	if result.has("error"):
		actual["evaluation_error"] = result["error"]
	_check(label, actual, expected)


func _check_error(label: String, result: Dictionary, field_path: Variant, run_id: Variant) -> void:
	var error: Dictionary = result.get("error", {})
	var actual: Dictionary = {
		"ok": result.get("ok"),
		"code": error.get("code"),
		"field_path": error.get("field_path", "<missing>"),
		"run_id": error.get("run_id", "<missing>"),
		"has_report": result.has("report"),
		"has_message": error.get("message") is String and not error["message"].is_empty(),
		"has_correction": error.get("suggested_fix") is String and not error["suggested_fix"].is_empty(),
	}
	_check(
		label, actual,
		{
			"ok": false, "code": "INVALID_EVALUATION_INPUT",
			"field_path": field_path, "run_id": run_id, "has_report": false,
			"has_message": true, "has_correction": true,
		}
	)


func _fixture(filename: String, expected_type: int = TYPE_DICTIONARY) -> Variant:
	var path: String = filename if filename.begins_with("res://") else EXAMPLES + filename
	var parser := JSON.new()
	var parse_error: Error = parser.parse(FileAccess.get_file_as_string(path))
	if parse_error != OK:
		_check("Fixture loads as JSON: " + filename, parser.get_error_message(), "valid JSON")
		return [] if expected_type == TYPE_ARRAY else {}
	if typeof(parser.data) != expected_type:
		_check("Fixture root type: " + filename, type_string(typeof(parser.data)), type_string(expected_type))
		return [] if expected_type == TYPE_ARRAY else {}
	return parser.data


## Synthetic native-state envelope checks, independent of the HPC checkout.
func _test_hpc_adapter(config: Dictionary, state: Dictionary) -> void:
	var native: Dictionary = _terminal(state, 3, 10.0)
	native["config_snapshot"] = config.duplicate(true)
	native["config_snapshot"]["mission"]["required_observations"] = 3
	native["event_log"] = [_blocked_event("NO_LINK_WINDOW", "transmit")]
	var before: Dictionary = native.duplicate(true)
	var result: Dictionary = Evaluator.evaluate_hpc_state(native)
	var report: Dictionary = result.get("report", {})
	_check("HPC adapter returns a complete evaluation", result.get("ok"), true)
	_check("HPC adapter uses launch observation target", report.get("required_observations"), 3)
	_check("HPC adapter uses launch return target", report.get("required_returned_data_mb"), 30)
	_check("HPC adapter preserves returned MB", report.get("returned_data_mb"), 10.0)
	_check("HPC adapter delegates capped scoring", report.get("score"), 67)
	var adapter_causes: Array = report.get("root_causes", [])
	_check("HPC adapter delegates event evidence", adapter_causes[0].get("code") if not adapter_causes.is_empty() else null, "NO_LINK_WINDOW")
	_check("HPC adapter preserves state and nested snapshots", native, before)
	_check("HPC adapter is deterministic", Evaluator.evaluate_hpc_state(native), result)
	_check(
		"HPC adapter agrees with the public three-input evaluator", result,
		Evaluator.evaluate_mission(native["config_snapshot"], native, native["event_log"])
	)
	for field: String in ["config_snapshot", "event_log"]:
		var malformed: Dictionary = native.duplicate(true)
		malformed.erase(field)
		_check_error("HPC adapter rejects missing " + field, Evaluator.evaluate_hpc_state(malformed), "final_state." + field, native["run_id"])
		malformed[field] = "invalid"
		_check_error("HPC adapter rejects invalid " + field, Evaluator.evaluate_hpc_state(malformed), "final_state." + field, native["run_id"])
	var malformed_events: Dictionary = native.duplicate(true)
	malformed_events["event_log"] = [null]
	_check_error("HPC adapter delegates event validation", Evaluator.evaluate_hpc_state(malformed_events), "events[0]", native["run_id"])
	var operating: Dictionary = native.duplicate(true)
	operating["phase"] = "operating"
	operating["run_status"] = null
	_check("HPC adapter rejects a live operating state", Evaluator.evaluate_hpc_state(operating).get("error", {}).get("code"), "NONTERMINAL_RUN_STATE")
	var aborted: Dictionary = native.duplicate(true)
	aborted["run_status"] = "aborted"
	aborted["terminal_reason"] = "  Operator ended this attempt.  "
	aborted["abort_reason"] = "Older alternate metadata."
	var abort_before: Dictionary = aborted.duplicate(true)
	var abort_report: Dictionary = Evaluator.evaluate_hpc_state(aborted).get("report", {})
	_check("HPC terminal_reason is attributed", str(abort_report.get("explanation")).contains("Recorded abort reason was Operator ended this attempt."), true)
	_check("HPC terminal_reason takes precedence", str(abort_report.get("explanation")).contains("Older alternate metadata."), false)
	_check("HPC abort score is null", abort_report.get("score", "missing"), null)
	_check("HPC abort retains actual progress", abort_report.get("observations_completed"), 3)
	_check("HPC abort mapping preserves inputs", aborted, abort_before)
	aborted["terminal_reason"] = " "
	_check("HPC empty terminal_reason preserves legacy fallback", str(Evaluator.evaluate_hpc_state(aborted).get("report", {}).get("explanation")).contains("Older alternate metadata."), true)
	_check_error("HPC empty state uses nullable identity", Evaluator.evaluate_hpc_state({}), "final_state.config_snapshot", null)
	var survey: Dictionary = native.duplicate(true)
	survey["config_snapshot"]["mission"]["objective"] = "survey"
	survey["observations_completed"] = 3
	survey["returned_data_mb"] = 30.0
	survey["observations_delivered_by_target"] = {}
	_check_error(
		"Survey aggregate thresholds require the delivery extension", Evaluator.evaluate_hpc_state(survey),
		"config.mission.objective", survey["run_id"]
	)
	_check_error(
		"Survey guard also applies to the public evaluator",
		Evaluator.evaluate_mission(survey["config_snapshot"], survey, survey["event_log"]),
		"config.mission.objective", survey["run_id"]
	)


## Executes unchanged HPC/KE1 modules when the integrated checkout provides them.
## The isolated pinned-project recipe is recorded in docs/ke2/hpc-integration.md.
func _test_hpc_runtime() -> bool:
	if not FileAccess.file_exists("res://core/MissionStepEngine.gd"):
		print("HPC runtime checks deferred to the pending integration group because producer modules are absent.")
		return false
	var step_engine: GDScript = load("res://core/MissionStepEngine.gd")
	var catalog_loader: GDScript = load("res://scripts/core/catalog_loader.gd")
	if step_engine == null or catalog_loader == null:
		_check("HPC runtime dependencies load", false, true)
		return false
	var catalogs: Dictionary = catalog_loader.load_catalogs()
	_check("HPC real KE1 catalogs load", catalogs.get("ok"), true)
	if not catalogs.get("ok", false):
		return false
	var config: Dictionary = _fixture("res://tests/fixtures/valid_1u_feasible.json")
	var started: Dictionary = step_engine.init_validated_run(config, catalogs["catalogs"], "run_ke2_prompt7", "mission_ke2_prompt7")
	_check("HPC actual KE1 readiness permits initialization", started.get("ok"), true)
	if not started.get("ok", false):
		printerr(var_to_str(started))
		return false
	_check("HPC actual readiness is approved", started.get("validation_result", {}).get("ready_to_launch"), true)
	var current: Dictionary = started["state"]
	# Caller edits after Launch must leave the run's retained goals intact.
	config["mission"]["required_observations"] = 20
	config["mission"]["required_returned_data_mb"] = 999.0
	var blocked_once: bool = false
	var captured_state: Dictionary = {}
	var requests: int = 0
	var maximum_requests: int = int(current["total_steps"]) + 2
	while current["phase"] == "operating" and requests < maximum_requests:
		var step: int = int(current["step_index"])
		var action: String = "power_save"
		if step == 1:
			action = "observe"
		elif step == 7 or (step == 8 and not blocked_once):
			action = "transmit"
		var previous: Dictionary = current.duplicate(true)
		var reply: Dictionary = step_engine.request_action(current, action)
		if not reply.get("ok", false):
			_check("HPC action request completes", reply, {"ok": true})
			return false
		current = reply["state"]
		requests += 1
		if step == 8 and action == "transmit":
			blocked_once = true
			_check("HPC recorded transmission is blocked", reply.get("allowed"), false)
			_check("HPC recorded block code", reply["events"][0].get("code"), "NO_LINK_WINDOW")
			for field: String in ["step_index", "energy_wh", "stored_data_mb", "returned_data_mb", "observations_completed"]:
				_check("HPC blocked action preserves " + field, current[field], previous[field])
		elif not reply.get("allowed", false):
			_check("HPC planned action is accepted at step %d" % step, reply["events"], "accepted action")
			return false
		if step == 1:
			captured_state = current.duplicate(true)
	_check("HPC real mission finishes naturally", current.get("run_status"), "completed")
	_check("HPC real mission reaches step 60", current.get("step_index"), 60)
	_check("HPC real mission retains all 62 events", current.get("event_log", []).size(), 62)
	var before: Dictionary = current.duplicate(true)
	var result: Dictionary = Evaluator.evaluate_hpc_state(current)
	_check("HPC completed simulation evaluates", result.get("ok"), true)
	var report: Dictionary = result.get("report", {})
	var fields: Array = report.keys()
	var required: Array = REPORT_FIELDS.duplicate()
	fields.sort()
	required.sort()
	_check("HPC report contains every agreed field", fields, required)
	_check("HPC completed verdict", report.get("status"), "partial")
	_check("HPC completed score", report.get("score"), 25)
	_check("HPC successful captures pass through", report.get("observations_completed"), 1)
	_check("HPC actual Earth reception passes through exactly", report.get("returned_data_mb"), current["returned_data_mb"])
	_check_close("HPC Earth reception matches the recorded reference", report.get("returned_data_mb"), 7.7333333328)
	_check("HPC stored data stays in the explanation", str(report.get("explanation")).contains(str(current["stored_data_mb"]) + " MB remain onboard."), true)
	_check("HPC launch capture target survives caller edits", report.get("required_observations"), 4)
	_check("HPC launch return target survives caller edits", report.get("required_returned_data_mb"), 30)
	var causes: Array = report.get("root_causes", [])
	_check("HPC earlier block survives terminal notification", causes.size(), 1)
	if not causes.is_empty():
		_check("HPC earlier event ID is retained", causes[0].get("evidence_event_ids"), ["evt_008"])
		_check("HPC earlier reason is retained", causes[0].get("code"), "NO_LINK_WINDOW")
	_check("HPC terminal state remains immutable", current, before)
	_check("HPC repeated terminal evaluation is deterministic", Evaluator.evaluate_hpc_state(current), result)
	var trace: Dictionary = _fixture("res://docs/hpc-ke3-ops-trace-v0.2.json")
	if trace.is_empty():
		return false
	var recorded: Dictionary = Evaluator.evaluate_mission(trace["config"], trace["final_state"], trace["events"])
	_check("HPC committed trace has launch approval", trace.get("validation", {}).get("launch_approved"), true)
	_check("HPC committed trace evaluates", recorded.get("ok"), true)
	_check("HPC committed trace score", recorded.get("report", {}).get("score"), 25)
	var recorded_causes: Array = recorded.get("report", {}).get("root_causes", [])
	_check("HPC committed trace retains evt_008", recorded_causes[0].get("evidence_event_ids") if not recorded_causes.is_empty() else null, ["evt_008"])
	if captured_state.is_empty():
		_check("HPC abort setup captured an observation", false, true)
		return false
	var aborted: Dictionary = step_engine.abort_run(captured_state, "Operator requested stop after capture.")
	_check("HPC real abort succeeds", aborted.get("ok"), true)
	if not aborted.get("ok", false):
		return false
	var abort_state: Dictionary = aborted["state"]
	var abort_before: Dictionary = abort_state.duplicate(true)
	var abort_report: Dictionary = Evaluator.evaluate_hpc_state(abort_state).get("report", {})
	_check("HPC real abort status", abort_report.get("run_status"), "aborted")
	_check("HPC real abort verdict", abort_report.get("status"), "failed")
	_check("HPC real abort score", abort_report.get("score", "missing"), null)
	_check("HPC real abort preserves captures", abort_report.get("observations_completed"), 1)
	_check("HPC real abort preserves received MB", abort_report.get("returned_data_mb"), 0.0)
	_check("HPC real abort attributes producer reason", str(abort_report.get("explanation")).contains("Recorded abort reason was Operator requested stop after capture."), true)
	_check("HPC real abort retains state and logs", abort_state, abort_before)
	return true


func _test_survey_delivery_measure(base_config: Dictionary) -> void:
	# Labeled preparation fixture: explicit zeros, never inferred from sparse maps.
	var config: Dictionary = base_config.duplicate(true)
	config.mission.objective = "survey"
	config.mission.target_region = "arctic_ice"
	config.mission.target_regions = ["arctic_ice", "antarctic_region"]
	var state: Dictionary = {"run_id": "fixture_survey_measure", "config_snapshot": config.duplicate(true),
		"observations_delivered_by_target": {"arctic_ice": 3, "antarctic_region": 0, "equator": 99},
		"returned_data_mb": 999.0, "observations_completed": 99}
	var before: Dictionary = state.duplicate(true)
	var config_before: Dictionary = config.duplicate(true)
	var result: Dictionary = Evaluator._measure_survey_deliveries(config, state)
	_check("SURVEY fixture extra and unrelated deliveries cannot fill missing target", result, {"ok": true, "measure": {
		"selected_target_count": 2, "delivered_selected_target_count": 1,
		"by_target": [{"target_id": "arctic_ice", "complete_observations_delivered": 3, "has_complete_delivery": true},
			{"target_id": "antarctic_region", "complete_observations_delivered": 0, "has_complete_delivery": false}]}})
	_check("SURVEY fixture inputs unchanged", [config, state], [config_before, before])
	_check("SURVEY fixture repeatability", Evaluator._measure_survey_deliveries(config, state), result)
	state.observations_delivered_by_target.antarctic_region = 2.0
	_check("SURVEY fixture each delivered selected target counts once", Evaluator._measure_survey_deliveries(config, state).measure.delivered_selected_target_count, 2)
	state.observations_delivered_by_target.arctic_ice = 0
	state.observations_delivered_by_target.antarctic_region = 0
	_check("SURVEY fixture pooled MB and captures are not deliveries", Evaluator._measure_survey_deliveries(config, state).measure.delivered_selected_target_count, 0)
	for malformed in [null, [], false, "counts"]:
		state.observations_delivered_by_target = malformed
		_check_error("SURVEY fixture unavailable or malformed map " + str(malformed), Evaluator._measure_survey_deliveries(config, state), "final_state.observations_delivered_by_target", state.run_id)
	for malformed in [-1, 0.5, true, "1", null, NAN, INF]:
		state.observations_delivered_by_target = {"arctic_ice": malformed, "antarctic_region": 0}
		_check_error("SURVEY fixture malformed counter " + str(malformed), Evaluator._measure_survey_deliveries(config, state), "final_state.observations_delivered_by_target", state.run_id)
	state.observations_delivered_by_target = {"arctic_ice": 1}
	_check_error("SURVEY fixture omitted target stays unavailable pending HPC", Evaluator._measure_survey_deliveries(config, state), "final_state.observations_delivered_by_target.antarctic_region", state.run_id)
	state.observations_delivered_by_target = {}
	_check_error("SURVEY fixture empty map does not imply zeros", Evaluator._measure_survey_deliveries(config, state), "final_state.observations_delivered_by_target.arctic_ice", state.run_id)
	state.observations_delivered_by_target = {"arctic_ice": 1}
	var legacy: Dictionary = config.duplicate(true)
	legacy.mission.erase("target_regions")
	state.config_snapshot = legacy.duplicate(true)
	_check("SURVEY fixture legacy primary-target selection", Evaluator._measure_survey_deliveries(legacy, state).measure.selected_target_count, 1)
	for selected in [[], ["arctic_ice", "arctic_ice"], ["arctic_ice", "antarctic_region", "equator"], [null], "arctic_ice"]:
		var invalid: Dictionary = config.duplicate(true)
		invalid.mission.target_regions = selected
		state.config_snapshot = invalid.duplicate(true)
		_check_error("SURVEY fixture malformed selection " + str(selected), Evaluator._measure_survey_deliveries(invalid, state), "config.mission.target_regions", state.run_id)
	state.config_snapshot = config.duplicate(true)
	var edited: Dictionary = config.duplicate(true)
	edited.mission.target_regions = ["antarctic_region", "arctic_ice"]
	_check_error("SURVEY fixture edited draft cannot replace launch targets", Evaluator._measure_survey_deliveries(edited, state), "final_state.config_snapshot", state.run_id)
	var typed: Dictionary = legacy.duplicate(true)
	typed.schema_version = 2
	typed.contract_revision = "expansion-goals-v2-draft-2"
	typed.preset_id = "polar_ice_survey"
	typed.preset_revision = 1
	typed.mission.goal = {"kind": "survey_delivery", "minimum_complete_observations_per_target": 1}
	state.config_snapshot = typed.duplicate(true)
	_check("SURVEY fixture reviewed minimum one", Evaluator._measure_survey_deliveries(typed, state).measure.delivered_selected_target_count, 1)
	typed.mission.goal.minimum_complete_observations_per_target = 2
	state.config_snapshot = typed.duplicate(true)
	_check_error("SURVEY fixture unagreed higher minimum not silently ignored", Evaluator._measure_survey_deliveries(typed, state), "config.mission.goal", state.run_id)


func _test_survey_scoring_proposal(base_config: Dictionary) -> void:
	# Counter-only scoring fixtures. They are not native traces or official reports.
	var config: Dictionary = base_config.duplicate(true)
	config.mission.objective = "survey"
	config.mission.target_region = "arctic_ice"
	config.mission.target_regions = ["arctic_ice", "antarctic_region"]
	config.mission.required_observations = 2
	config.mission.required_returned_data_mb = 12.0
	var state: Dictionary = {"run_id": "fixture_survey_scoring", "config_snapshot": config.duplicate(true),
		"phase": "finished", "run_status": "completed", "step_index": 30, "total_steps": 30,
		"observations_completed": 2, "returned_data_mb": 12.0,
		"observations_delivered_by_target": {"arctic_ice": 1, "antarctic_region": 0}}
	for row in [
		["missing selected target", 2, 12.0, 1, 0, "partial", 83],
		["all goals met", 2, 12.0, 1, 1, "success", 100],
		["no progress", 0, 0.0, 0, 0, "failed", 0],
		["capture progress only", 1, 0.0, 0, 0, "partial", 17],
		["over-target captures cannot replace data", 7, 0.0, 0, 0, "partial", 33],
		["over-target MB cannot replace missing target", 7, 120.5, 3, 0, "partial", 83],
		["both target deliveries still need aggregate goals", 2, 24.0, 1, 1, "partial", 63, 4, 60.0],
	]:
		config.mission.required_observations = row[7] if row.size() > 7 else 2
		config.mission.required_returned_data_mb = row[8] if row.size() > 8 else 12.0
		state.config_snapshot = config.duplicate(true)
		state.observations_completed = row[1]
		state.returned_data_mb = row[2]
		state.observations_delivered_by_target = {"arctic_ice": row[3], "antarctic_region": row[4]}
		var before: Dictionary = state.duplicate(true)
		var original: Dictionary = config.duplicate(true)
		var result: Dictionary = SurveyProposal.assess(config, state)
		_check("SURVEY SCORE proposal " + row[0], [result.get("ok"), result.get("proposal", {}).get("status"), result.get("proposal", {}).get("score")], [true, row[5], row[6]])
		_check("SURVEY SCORE raw actuals and proposal label " + row[0], [result.get("proposal", {}).get("actuals"), result.get("proposal", {}).get("not_for_publication"), result.has("report")], [{"observations_completed": row[1], "returned_data_mb": row[2], "observations_delivered_by_target": state.observations_delivered_by_target}, true, false])
		_check("SURVEY SCORE repeatability/input preservation " + row[0], [SurveyProposal.assess(config, state), state, config], [result, before, original])
	state.observations_completed = 2
	state.observations_delivered_by_target = {"arctic_ice": 1, "antarctic_region": 1}
	config.mission.required_observations = 2
	config.mission.required_returned_data_mb = 200.0
	state.config_snapshot = config.duplicate(true)
	for row in [[100.999, 83], [101.0, 84], [101.001, 84]]:
		state.returned_data_mb = row[0]
		_check("SURVEY SCORE half-up boundary " + str(row[0]), SurveyProposal.assess(config, state).proposal.score, row[1])
	state.returned_data_mb = 199.0
	_check("SURVEY SCORE rounded 100 does not mean success", [SurveyProposal.assess(config, state).proposal.status, SurveyProposal.assess(config, state).proposal.score], ["partial", 100])
	state.returned_data_mb = 200.0
	state.run_status = "aborted"
	state.step_index = 29
	_check("SURVEY SCORE abort after all goals", [SurveyProposal.assess(config, state).proposal.run_status, SurveyProposal.assess(config, state).proposal.status, SurveyProposal.assess(config, state).proposal.score, SurveyProposal.assess(config, state).proposal.actuals.returned_data_mb], ["aborted", "failed", null, 200.0])
	state.run_status = "completed"
	state.step_index = 30
	for row in [["required_observations", 0], ["required_observations", true], ["required_returned_data_mb", 0], ["required_returned_data_mb", NAN], ["required_returned_data_mb", INF]]:
		var invalid: Dictionary = config.duplicate(true)
		invalid.mission[row[0]] = row[1]
		state.config_snapshot = invalid.duplicate(true)
		_check_error("SURVEY SCORE invalid goal " + str(row), SurveyProposal.assess(invalid, state), "config.mission." + row[0], state.run_id)
	state.config_snapshot = config.duplicate(true)
	for row in [["observations_completed", -1], ["observations_completed", 0.5], ["observations_completed", true], ["returned_data_mb", -1], ["returned_data_mb", "12"], ["returned_data_mb", INF]]:
		var invalid: Dictionary = state.duplicate(true)
		invalid[row[0]] = row[1]
		_check_error("SURVEY SCORE invalid actual " + str(row), SurveyProposal.assess(config, invalid), "final_state." + row[0], state.run_id)
	state.observations_delivered_by_target.erase("antarctic_region")
	_check_error("SURVEY SCORE sparse map cannot invent a score", SurveyProposal.assess(config, state), "final_state.observations_delivered_by_target.antarctic_region", state.run_id)
	state.observations_delivered_by_target.antarctic_region = 1
	state.step_index = 29
	_check_error("SURVEY SCORE invalid completed terminal step", SurveyProposal.assess(config, state), "final_state.step_index", state.run_id)
	state.phase = "operating"
	state.run_status = null
	_check("SURVEY SCORE rejects nonterminal fixture", SurveyProposal.assess(config, state).get("error", {}).get("code"), "NONTERMINAL_RUN_STATE")


func _test_survey_native_packets() -> void:
	# Actual producer mechanics; this does not ratify sparse-map defaults or emit a report.
	var runtime: GDScript = load("res://scripts/integration/mission_runtime.gd")
	var engine: GDScript = load("res://core/MissionStepEngine.gd")
	var catalog: GDScript = load("res://data/mock/DesignCatalog.gd")
	var draft: Dictionary = catalog.DEFAULTS.duplicate(true)
	draft.objective = "Survey Target Regions"
	draft.targets = ["Arctic Ice"]
	draft.orbit = "Polar – 600 km"
	draft.observations = 1
	draft.required_returned_data_mb = 12
	draft.duration = 3
	var loaded: Dictionary = runtime.load_game_catalogs()
	_check("SURVEY native catalogs load", loaded.get("ok"), true)
	if not loaded.get("ok", false): return
	var config: Dictionary = runtime.config_for(draft)
	var started: Dictionary = engine.init_validated_run(config, loaded.catalogs, "run_ke2_survey_packet", "mission_ke2_survey_packet")
	_check("SURVEY native validated setup", started.get("ok"), true)
	if not started.get("ok", false): return
	var state: Dictionary = started.state
	for step in range(11):
		var action: String = "observe" if step == 0 else ("transmit" if step == 7 or step == 10 else "power_save")
		var reply: Dictionary = engine.request_action(state, action)
		_check("SURVEY native accepted packet action at step " + str(step), reply.get("ok", false) and reply.get("allowed", false), true)
		if not reply.get("ok", false) or not reply.get("allowed", false): return
		state = reply.state
		if step == 7:
			_check("SURVEY native partial packet has positive return and onboard remainder", state.returned_data_mb > 0 and state.stored_data_mb > 0, true)
			_check("SURVEY native partial packet has no complete-delivery counter", state.observations_delivered_by_target, {})
			_check_error("SURVEY native sparse entry stays unavailable pending owner rule", Evaluator._measure_survey_deliveries(config, state), "final_state.observations_delivered_by_target.arctic_ice", state.run_id)
	var measured: Dictionary = Evaluator._measure_survey_deliveries(config, state)
	_check("SURVEY native full packet qualifies", measured.get("ok"), true)
	_check("SURVEY native one recorded complete delivery", measured.get("measure", {}).get("delivered_selected_target_count"), 1)
	_check_close("SURVEY native completed packet returns 12 MB", state.returned_data_mb, 12.0)
	_check("SURVEY native completed packet leaves no stored remainder", state.stored_data_mb, 0.0)


func _check_close(label: String, actual: Variant, expected: float, tolerance: float = 1e-9) -> void:
	if (actual is int or actual is float) and is_finite(float(actual)) and absf(float(actual) - expected) <= tolerance:
		_check(label, expected, expected)
	else:
		_check(label, actual, expected)


func _check(label: String, actual: Variant, expected: Variant) -> void:
	if actual == expected:
		_passed += 1
		print("PASS " + label)
	else:
		_failed += 1
		printerr("FAIL " + label)
		printerr("  expected = " + var_to_str(expected))
		printerr("  actual   = " + var_to_str(actual))
