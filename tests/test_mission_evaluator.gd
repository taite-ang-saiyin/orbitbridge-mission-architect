extends SceneTree
## Module-setup smoke checks. Scoring acceptance cases are added in Prompt 3/4.

const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const EXAMPLES: String = "res://docs/contracts/v1-draft/"

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
		Evaluator.mock_report_result(completed) == _fixture("evaluation-completed.example.json")
	)
	_check(
		"SETUP02 aborted mock wrapper and null score",
		Evaluator.mock_report_result(aborted) == _fixture("evaluation-aborted.example.json")
	)

	var copied: Dictionary = Evaluator.mock_report_result(completed)
	copied["report"]["root_causes"][0]["evidence_event_ids"].append("changed-preview")
	_check(
		"SETUP03 nested mock values are independent",
		completed["root_causes"][0]["evidence_event_ids"] == ["evt_007"]
	)

	var incomplete: Dictionary = completed.duplicate(true)
	incomplete.erase("score")
	var invalid_mock: Dictionary = Evaluator.mock_report_result(incomplete)
	_check(
		"SETUP04 incomplete mock returns a field error",
		invalid_mock["ok"] == false
		and invalid_mock["error"]["field_path"] == "mock_report.score"
	)

	_check(
		"SETUP05 missing inputs use the agreed top-level error",
		Evaluator.evaluate_mission({}, {}, []) == _fixture("evaluation-top-level-error.example.json")
	)
	_check(
		"SETUP06 operating state uses the agreed nonterminal error",
		Evaluator.evaluate_mission(config, state, []) == _fixture("evaluation-nonterminal-error.example.json")
	)

	var terminal: Dictionary = state.duplicate(true)
	terminal["phase"] = "finished"
	terminal["run_status"] = "completed"
	terminal["step_index"] = terminal["total_steps"]
	var events: Array = _fixture("completed-report.evidence-events.example.json")
	var config_before: Dictionary = config.duplicate(true)
	var state_before: Dictionary = terminal.duplicate(true)
	var events_before: Array = events.duplicate(true)
	var baseline_before: Dictionary = completed.duplicate(true)
	var pending: Dictionary = Evaluator.evaluate_mission(config, terminal, events, completed)
	_check(
		"SETUP07 terminal evaluation explicitly awaits Prompt 3",
		pending["ok"] == false
		and pending["error"]["code"] == "EVALUATION_NOT_IMPLEMENTED"
		and not pending.has("report")
	)
	_check(
		"SETUP08 evaluation preserves every input",
		config == config_before and terminal == state_before
		and events == events_before and completed == baseline_before
	)

	terminal["run_status"] = "aborted"
	var pending_abort: Dictionary = Evaluator.evaluate_mission(config, terminal, [])
	_check(
		"SETUP09 abort evaluation explicitly awaits Prompt 3",
		pending_abort["ok"] == false
		and pending_abort["error"]["code"] == "EVALUATION_NOT_IMPLEMENTED"
	)

	print("Module setup checks: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _fixture(filename: String) -> Variant:
	var path: String = EXAMPLES + filename
	var parser := JSON.new()
	var parse_error: Error = parser.parse(FileAccess.get_file_as_string(path))
	if parse_error != OK:
		_check("Fixture loads as JSON: " + filename, false)
		return {}
	return parser.data


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS " + label)
	else:
		_failed += 1
		printerr("FAIL " + label)
