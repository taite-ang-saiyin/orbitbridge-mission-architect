class_name MissionEvaluator
extends RefCounted
## Scene-independent KE2 evaluation boundary for the agreed v1 dictionaries.
## Data uses decimal MB, counts use whole numeric values, and energy uses Wh.
## Goal validation, classification, and scoring are implemented in Prompt 3.

const SCHEMA_VERSION: int = 1
const INVALID_INPUT: String = "INVALID_EVALUATION_INPUT"
const NONTERMINAL_STATE: String = "NONTERMINAL_RUN_STATE"
## Temporary setup error. Replace this path with goal evaluation in Prompt 3.
const EVALUATION_PENDING: String = "EVALUATION_NOT_IMPLEMENTED"

const REPORT_FIELDS: Array[String] = [
	"schema_version",
	"run_id",
	"mission_id",
	"run_status",
	"status",
	"observations_completed",
	"required_observations",
	"returned_data_mb",
	"required_returned_data_mb",
	"observation_completion_ratio",
	"data_return_completion_ratio",
	"score",
	"explanation",
	"root_causes",
	"next_experiment",
	"source_ids",
	"comparison",
]


## Accepts a launch config snapshot, terminal HPC state, and ordered events.
## comparison_baseline is reserved for the agreed optional P1 comparison.
## Returns the v1 ok/report or ok/error wrapper and preserves all inputs.
## During module setup, terminal runs return EVALUATION_NOT_IMPLEMENTED.
@warning_ignore("unused_parameter")
static func evaluate_mission(
	config: Dictionary,
	final_state: Dictionary,
	events: Array,
	comparison_baseline = null
) -> Dictionary:
	var run_id: Variant = final_state.get("run_id")
	if not run_id is String or run_id.strip_edges().is_empty():
		run_id = null

	if config.is_empty() or final_state.is_empty():
		return _error(
			INVALID_INPUT, null,
			"Required evaluation input is missing or malformed.",
			"Provide a valid config, terminal state and event array.", run_id
		)

	for section: String in ["mission", "design"]:
		if not config.get(section) is Dictionary:
			return _error(
				INVALID_INPUT, "config." + section,
				"The config section must be a Dictionary.",
				"Provide the launch-time MissionConfig snapshot.", run_id
			)

	for input: Dictionary in [
		{"value": config, "path": "config"},
		{"value": final_state, "path": "final_state"},
	]:
		var version: Variant = input["value"].get("schema_version")
		if not (version is int or version is float) or version != SCHEMA_VERSION:
			return _error(
				INVALID_INPUT, input["path"] + ".schema_version",
				"The evaluation boundary requires schema version 1.",
				"Use the agreed v1 configuration and state dictionaries.", run_id
			)

	if run_id == null:
		return _error(
			INVALID_INPUT, "final_state.run_id",
			"The run identifier must be a nonempty String.",
			"Preserve the run_id assigned when HPC initialized the run."
		)

	var mission_id: Variant = final_state.get("mission_id")
	if not mission_id is String or mission_id.strip_edges().is_empty():
		return _error(
			INVALID_INPUT, "final_state.mission_id",
			"The mission identifier must be a nonempty String.",
			"Preserve the mission_id assigned when HPC initialized the run.", run_id
		)

	if final_state.get("phase") == "operating":
		return _error(
			NONTERMINAL_STATE, "final_state.phase",
			"The run is still operating and cannot be evaluated as a terminal mission.",
			"Finish or explicitly abort the run before requesting evaluation.", run_id
		)

	if final_state.get("phase") != "finished":
		return _error(
			INVALID_INPUT, "final_state.phase",
			"The mission phase must be operating or finished.",
			"Provide HPC's recorded terminal state.", run_id
		)

	if final_state.get("run_status") not in ["completed", "aborted"]:
		return _error(
			INVALID_INPUT, "final_state.run_status",
			"A finished run requires a completed or aborted status.",
			"Preserve HPC's terminal run_status.", run_id
		)

	for index: int in range(events.size()):
		if not events[index] is Dictionary:
			return _error(
				INVALID_INPUT, "events[%d]" % index,
				"Each recorded event must be a Dictionary.",
				"Provide the ordered HPC event array, or an empty array.", run_id
			)

	return _error(
		EVALUATION_PENDING, null,
		"The evaluation module is set up. Goal evaluation is pending Prompt 3.",
		"Implement the agreed goal rules before evaluating terminal runs. "
		+ "Use mock_report_result with a labeled report fixture for setup previews.",
		run_id
	)


## Explicit setup helper for caller-supplied MissionReport documentation fixtures.
## It checks required keys and returns an independent deep copy in the v1 wrapper.
## Callers own fixture loading and labeling. This helper does not evaluate a run
## or validate report values against the scoring rubric.
static func mock_report_result(report: Dictionary) -> Dictionary:
	for field: String in REPORT_FIELDS:
		if not report.has(field):
			return _error(
				INVALID_INPUT, "mock_report." + field,
				"The mock MissionReport is missing a required field.",
				"Supply a complete labeled v1 MissionReport fixture."
			)

	return {"ok": true, "report": report.duplicate(true)}


static func _error(
	code: String,
	field_path: Variant,
	message: String,
	suggested_fix: String,
	run_id: Variant = null
) -> Dictionary:
	return {
		"ok": false,
		"error": {
			"code": code,
			"field_path": field_path,
			"message": message,
			"suggested_fix": suggested_fix,
			"run_id": run_id,
		},
	}
