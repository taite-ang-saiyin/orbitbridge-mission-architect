extends SceneTree

const Adapter = preload("res://core/HPCContractAdapter.gd")
const Evaluator = preload("res://scripts/evaluation/mission_team_integration.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Step = preload("res://core/MissionStepEngine.gd")

var failures: int = 0

func _initialize() -> void:
	var catalogs_result: Dictionary = Runtime.load_game_catalogs(true)
	_check(catalogs_result.ok, "v2 catalogs load")
	if not catalogs_result.ok:
		quit(1)
		return
	var scenario_result: Dictionary = Adapter.build_scenario(catalogs_result.catalogs, catalogs_result.catalogs.orbit_catalog)
	_check(scenario_result.ok, "v2 scenario builds")
	if not scenario_result.ok:
		quit(1)
		return
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/valid_1u_feasible.json"))
	var communication: Dictionary = _v2_config(base, "communication", 2)
	_check(_communication_success(communication, scenario_result.scenario), "communication counts distinct positive transmit steps")
	_check(_communication_shortfall(communication, scenario_result.scenario), "communication count shortfall is not hidden by returned MB")
	_check(_blocked_transmit_preserved(communication, scenario_result.scenario), "blocked or empty transmission is retained without counting")
	var weather: Dictionary = _v2_config(base, "weather_monitoring", 2)
	weather.mission.required_observations = 3
	weather.mission.target_regions = ["equator"]
	_check(_weather_counting(weather, scenario_result.scenario), "weather counts selected target on distinct revolutions")
	_check(_abort_preserves_v2(weather, scenario_result.scenario), "abort preserves v2 config, catalog context and evidence")
	_check(_replay_is_deterministic(communication, scenario_result.scenario), "v2 execution deterministically replays")
	print("HPC config-v2: %d checks passed, %d failed" % [6 - failures, failures])
	quit(1 if failures > 0 else 0)

func _v2_config(_base: Dictionary, objective: String, required_count: int) -> Dictionary:
	var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/mission_presets_v2.json"))
	for entry: Dictionary in registry.presets:
		if entry.config_v2.mission.objective == objective:
			var config: Dictionary = entry.config_v2.duplicate(true)
			var field: String = "required_positive_contact_steps" if objective == "communication" else "required_distinct_orbits"
			config.mission.goal[field] = required_count
			return config
	return {}

func _start(config: Dictionary, scenario: Dictionary, suffix: String) -> Dictionary:
	return Step.init_run(config, scenario, "v2_" + suffix, "mission_v2_" + suffix)

func _communication_success(config: Dictionary, scenario: Dictionary) -> bool:
	var started: Dictionary = _start(config, scenario, "communication_success")
	if not _check(started.ok, "communication success initializes"): return false
	var state: Dictionary = started.state
	for step in range(state.total_steps):
		var action: String = "observe" if step in [1, 6] else ("transmit" if step in [7, 10] else "power_save")
		var result: Dictionary = Step.request_action(state, action)
		if not _check(result.ok, "communication success action is processed"): return false
		state = result.state
	var progress: Dictionary = state.goal_progress
	var report: Dictionary = Evaluator.evaluate_state(state).report
	return _check(state.config_snapshot == config and state.scenario_snapshot == scenario, "success snapshots remain complete") \
		and _check(progress.actual_count == 2 and progress.evidence_event_ids.size() == 2, "success keeps one evidence ID per count") \
		and _check(report.status == "success" and report.goal_progress[0].actual == 2, "success report uses native v2 count")

func _communication_shortfall(config: Dictionary, scenario: Dictionary) -> bool:
	var started: Dictionary = _start(config, scenario, "communication_shortfall")
	if not _check(started.ok, "communication shortfall initializes"): return false
	var state: Dictionary = started.state
	for step in range(state.total_steps):
		var action: String = "observe" if step == 1 else ("transmit" if step == 7 else "power_save")
		state = Step.request_action(state, action).state
	var report: Dictionary = Evaluator.evaluate_state(state).report
	return _check(state.returned_data_mb >= 12.0 and state.goal_progress.actual_count == 1, "returned MB does not satisfy the second communication count") \
		and _check(report.status == "partial" and report.goal_progress[0].actual == 1, "shortfall report retains count failure")

func _blocked_transmit_preserved(config: Dictionary, scenario: Dictionary) -> bool:
	var started: Dictionary = _start(config, scenario, "blocked_transmit")
	if not _check(started.ok, "blocked transmission initializes"): return false
	var state: Dictionary = started.state
	var blocked: Dictionary = Step.request_action(state, "transmit")
	state = blocked.state
	var event: Dictionary = blocked.events[0]
	return _check(blocked.ok and not blocked.allowed and event.code == "NO_DATA", "empty transmission is explicitly blocked") \
		and _check(state.goal_progress.actual_count == 0 and state.step_index == 0, "blocked transmission does not advance or count")

func _weather_counting(config: Dictionary, scenario: Dictionary) -> bool:
	var started: Dictionary = _start(config, scenario, "weather_counting")
	if not _check(started.ok, "weather initializes"): return false
	var state: Dictionary = started.state
	for step in range(state.total_steps):
		var action: String = "observe" if step in [1, 6, 11] else "power_save"
		state = Step.request_action(state, action).state
	var progress: Dictionary = state.goal_progress
	return _check(progress.actual_count == 2, "weather counts two selected-target revolutions") \
		and _check(progress.qualifying_revolution_indices == [0, 1], "weather freezes pre-action revolution indices") \
		and _check(progress.evidence_event_ids.size() == 2, "weather preserves evidence for counted revolutions") \
		and _check(state.observations_by_target.get("equator", 0) == 3, "repeated selected-target captures remain visible while revolutions deduplicate")

func _abort_preserves_v2(config: Dictionary, scenario: Dictionary) -> bool:
	var started: Dictionary = _start(config, scenario, "abort")
	if not _check(started.ok, "abort initializes"): return false
	var state: Dictionary = Step.request_action(started.state, "observe").state
	var aborted: Dictionary = Step.abort_run(state, "test abort")
	var terminal: Dictionary = aborted.state
	var evaluation: Dictionary = Evaluator.evaluate_state(terminal)
	return _check(aborted.ok and terminal.run_status == "aborted", "abort reaches terminal state") \
		and _check(terminal.config_snapshot == config and terminal.scenario_snapshot == scenario, "abort preserves v2 snapshots") \
		and _check(evaluation.ok and evaluation.report.status == "failed" and evaluation.report.score == null, "abort report is failed without a score")

func _replay_is_deterministic(config: Dictionary, scenario: Dictionary) -> bool:
	var first: Dictionary = _run_actions(config, scenario, "replay")
	var second: Dictionary = _run_actions(config, scenario, "replay")
	return _check(first == second, "same v2 inputs and actions produce identical terminal evidence")

func _run_actions(config: Dictionary, scenario: Dictionary, suffix: String) -> Dictionary:
	var state: Dictionary = _start(config, scenario, suffix).state
	while state.phase != "finished":
		var action: String = "observe" if state.step_index == 1 else ("transmit" if state.step_index == 7 else "power_save")
		state = Step.request_action(state, action).state
	return state

func _check(condition: bool, label: String) -> bool:
	if not condition:
		failures += 1
		push_error("TEST FAILURE: " + label)
	return condition
