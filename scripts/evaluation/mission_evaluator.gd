class_name MissionEvaluator
extends RefCounted
## Scene-independent KE2 evaluation boundary for the agreed v1 dictionaries.
## Data uses decimal MB, counts use whole numeric values, and energy uses Wh.
## Both goals must be positive. Zero targets return INVALID_EVALUATION_INPUT.
## Completion ratios range from 0 to 1; multiply by 100 for display percentages.

const SCHEMA_VERSION: int = 1
const INVALID_INPUT: String = "INVALID_EVALUATION_INPUT"
const NONTERMINAL_STATE: String = "NONTERMINAL_RUN_STATE"
const Feedback = preload("res://scripts/evaluation/mission_feedback.gd")

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
## Scores use equally weighted capped ratios, rounded once with .5 rounded up.
## Aborts preserve actuals and ratios, with failed status and a null score.
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

	var mission: Dictionary = config["mission"]
	if mission.get("objective") == "survey":
		return _error(
			INVALID_INPUT, "config.mission.objective",
			"Survey requires per-target delivery evaluation beyond the agreed v1 aggregate goals.",
			"Use the supported imaging evaluation or coordinate the Survey scoring extension.", run_id
		)
	for requirement: Dictionary in [
		{"field": "required_observations", "maximum": 20},
		{"field": "duration_orbits", "maximum": 12},
	]:
		var field: String = requirement["field"]
		var value: Variant = mission.get(field)
		if not _is_whole_number(value) or value < 1 or value > requirement["maximum"]:
			return _error(
				INVALID_INPUT, "config.mission." + field,
				"The requirement must be a whole numeric value from 1 to %d."
				% requirement["maximum"],
				"Provide a positive requirement within the agreed v1 range.", run_id
			)

	var required_observations: Variant = mission["required_observations"]
	var required_data_mb: Variant = mission.get("required_returned_data_mb")
	if not _is_finite_number(required_data_mb) or required_data_mb <= 0:
		return _error(
			INVALID_INPUT, "config.mission.required_returned_data_mb",
			"The returned-data target must be a finite numeric value greater than zero.",
			"Set a positive returned-data target in decimal MB.", run_id
		)

	var observations: Variant = final_state.get("observations_completed")
	if not _is_whole_number(observations) or observations < 0:
		return _error(
			INVALID_INPUT, "final_state.observations_completed",
			"Completed observations must be a finite nonnegative whole numeric value.",
			"Provide HPC's successful-capture counter.", run_id
		)

	for field: String in ["returned_data_mb", "stored_data_mb"]:
		var value: Variant = final_state.get(field)
		if not _is_finite_number(value) or value < 0:
			return _error(
				INVALID_INPUT, "final_state." + field,
				"The data counter must be a finite nonnegative numeric value.",
				"Provide the recorded HPC counter in decimal MB.", run_id
			)

	var step_index: Variant = final_state.get("step_index")
	var total_steps: Variant = final_state.get("total_steps")
	if not _is_whole_number(total_steps) or total_steps <= 0:
		return _error(
			INVALID_INPUT, "final_state.total_steps",
			"The run length must be a finite positive whole numeric value.",
			"Preserve HPC's scenario-derived run length.", run_id
		)
	if not _is_whole_number(step_index) or step_index < 0 or step_index > total_steps:
		return _error(
			INVALID_INPUT, "final_state.step_index",
			"The step index must be a whole numeric value within the run length.",
			"Provide HPC's recorded terminal step index.", run_id
		)
	if final_state["run_status"] == "completed" and step_index != total_steps:
		return _error(
			INVALID_INPUT, "final_state.step_index",
			"A naturally completed run must reach total_steps.",
			"Finish the run or preserve an explicit aborted status.", run_id
		)

	for index: int in range(events.size()):
		if not events[index] is Dictionary:
			return _error(
				INVALID_INPUT, "events[%d]" % index,
				"Each recorded event must be a Dictionary.",
				"Provide the ordered HPC event array, or an empty array.", run_id
			)

	var returned_data_mb: Variant = final_state["returned_data_mb"]
	# Cap before dividing to avoid overflow for finite, widely separated MB values.
	var observation_ratio: float = (
		1.0 if observations >= required_observations
		else float(observations) / float(required_observations)
	)
	var data_ratio: float = (
		1.0 if returned_data_mb >= required_data_mb
		else float(returned_data_mb) / float(required_data_mb)
	)
	var score: Variant = int(floorf(50.0 * (observation_ratio + data_ratio) + 0.5))
	var status: String = "failed"
	if observations >= required_observations and returned_data_mb >= required_data_mb:
		status = "success"
	elif observations > 0 or returned_data_mb > 0:
		status = "partial"

	if final_state["run_status"] == "aborted":
		status = "failed"
		score = null

	var report: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"run_id": run_id,
		"mission_id": mission_id,
		"run_status": final_state["run_status"],
		"status": status,
		"observations_completed": observations,
		"required_observations": required_observations,
		"returned_data_mb": returned_data_mb,
		"required_returned_data_mb": required_data_mb,
		"observation_completion_ratio": observation_ratio,
		"data_return_completion_ratio": data_ratio,
		"score": score,
		"explanation": "",
		"root_causes": [],
		"next_experiment": "",
		"source_ids": [],
		"comparison": null,
	}
	var feedback: Dictionary = Feedback.build_feedback(report, final_state, events)
	report.merge(feedback, true)
	return {"ok": true, "report": report}


## Adapts the native HPC state using its immutable launch snapshot and full log.
## Counters, units, and event records pass directly to the agreed evaluator.
static func evaluate_hpc_state(final_state: Dictionary, comparison_baseline = null) -> Dictionary:
	var run_id: Variant = final_state.get("run_id")
	if not run_id is String or run_id.strip_edges().is_empty():
		run_id = null
	if not final_state.get("config_snapshot") is Dictionary:
		return _error(
			INVALID_INPUT, "final_state.config_snapshot",
			"The HPC state must contain its launch-time config snapshot.",
			"Pass the native MissionStepEngine state with config_snapshot intact.", run_id
		)
	if not final_state.get("event_log") is Array:
		return _error(
			INVALID_INPUT, "final_state.event_log",
			"The HPC state must contain its cumulative event log.",
			"Pass the state's event_log, including earlier blocked actions.", run_id
		)
	return evaluate_mission(
		final_state["config_snapshot"], final_state, final_state["event_log"], comparison_baseline
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


static func _is_finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _is_whole_number(value: Variant) -> bool:
	return _is_finite_number(value) and floorf(float(value)) == value


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
