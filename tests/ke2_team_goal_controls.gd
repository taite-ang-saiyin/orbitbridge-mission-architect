extends SceneTree
## Real native-v2 goal controls against the composed KE1/HPC implementation.
const Team = preload("res://scripts/evaluation/mission_team_integration.gd")
const Step = preload("res://core/MissionStepEngine.gd")
var catalogs: Dictionary
var configs: Dictionary = {}
var cases: Dictionary = {}
var passed: int = 0
var failed: int = 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL " + label)

func run_case(name: String, config: Dictionary, observes: Array, transmits: Array, abort_at: int = -1) -> Dictionary:
	var begun: Dictionary = Step.init_validated_run(config, catalogs, "team_" + name, "team_goal_controls")
	check(begun.ok, "validated typed-v2 initialization " + name)
	if not begun.ok:
		printerr(begun)
		return {}
	var initial: Dictionary = begun.state.duplicate(true)
	var state: Dictionary = begun.state
	for index in int(state.total_steps):
		if abort_at >= 0 and index == abort_at:
			state = Step.abort_run(state, "Owner integration abort control").state
			break
		var action: String = "observe" if index in observes else "transmit" if index in transmits else "power_save"
		var reply: Dictionary = Step.request_action(state, action)
		if not reply.ok:
			check(false, "native request " + name)
			return {}
		state = reply.state
		if not reply.allowed:
			state = Step.request_action(state, "power_save").state
	var before: Dictionary = state.duplicate(true)
	var reply: Dictionary = Team.evaluate_state(state)
	check(reply.ok, "terminal evaluation " + name)
	check(state == before and state.config_snapshot == config, "native config/evidence preserved " + name)
	if not reply.ok:
		printerr(reply)
		return {}
	var result: Dictionary = {"config": config, "initial_state": initial, "final_state": state, "readiness": begun.validation_result, "evaluation": reply}
	cases[name] = result
	return result

func _initialize() -> void:
	if not ResourceLoader.exists("res://scripts/core/mission_v2_context.gd"):
		printerr("Run this check in the composed owner snapshot.")
		quit(1)
		return
	var runtime: Script = load("res://scripts/integration/mission_runtime.gd")
	var loaded: Dictionary = runtime.load_game_catalogs(true)
	if not loaded.ok:
		printerr(loaded)
		quit(1)
		return
	catalogs = loaded.catalogs
	for entry: Dictionary in catalogs.mission_v2.registry.presets:
		configs[entry.id] = entry.config_v2.duplicate(true)
	var communication: Dictionary = run_case("communication_complete", configs.communication, [1, 6], [7, 10])
	var contact_shortfall: Dictionary = run_case("communication_shortfall", configs.communication, [1], [7, 10])
	check(communication.get("evaluation", {}).get("report", {}).get("score") == 100, "Communication complete candidate score")
	check(contact_shortfall.get("evaluation", {}).get("report", {}).get("score") == 75, "Communication shortfall candidate score")
	var weather: Dictionary = run_case("weather_complete", configs.weather_monitoring, [1, 11], [7, 10, 17, 20, 27])
	var weather_shortfall: Dictionary = run_case("weather_shortfall", configs.weather_monitoring, [1, 6], [7, 10, 17, 20, 27])
	check(weather.get("evaluation", {}).get("report", {}).get("score") == 100, "Weather feasible real-v2 success")
	check(weather_shortfall.get("evaluation", {}).get("report", {}).get("score") == 75, "Weather same-revolution shortfall")
	var survey: Dictionary = configs.polar_ice_survey.duplicate(true)
	survey.mission.target_regions = ["arctic_ice", "antarctic_region"]
	survey.mission.required_observations = 2
	survey.mission.required_returned_data_mb = 12.0
	survey.mission.duration_orbits = 3
	var partial: Dictionary = run_case("survey_partial_packet", survey, [0, 7], [10, 17])
	var complete: Dictionary = run_case("survey_complete", survey, [0, 7], [10, 17, 20, 27])
	check(partial.get("evaluation", {}).get("report", {}).get("score") == 83, "Survey aggregate goals met with one missing delivery")
	check(complete.get("evaluation", {}).get("report", {}).get("score") == 100, "Survey both targets completely delivered")
	var aborted: Dictionary = run_case("abort_after_goals", configs.communication, [1, 6], [7, 10], 11)
	var aborted_report: Dictionary = aborted.get("evaluation", {}).get("report", {})
	check(aborted_report.get("run_status") == "aborted" and aborted_report.get("status") == "failed" and aborted_report.get("score") == null and aborted_report.get("returned_data_mb") == 24.0, "real abort after met goals preserves actuals/null score")
	for id: String in configs:
		var zero: Dictionary = run_case("zero_" + id, configs[id], [], [])
		check(zero.get("evaluation", {}).get("report", {}).get("status") == "failed" and zero.get("evaluation", {}).get("report", {}).get("score") == 0, "zero-progress native failure " + id)
	if not contact_shortfall.is_empty():
		var altered: Dictionary = contact_shortfall.final_state.duplicate(true)
		altered.goal_progress.actual_count = 99
		var derived: Dictionary = Team.evaluate_state(altered)
		check(derived.ok and derived.report.goal_progress[0].actual == 1 and derived.report.score == 75, "verdict derives count from events despite altered auxiliary counter")
	if not partial.is_empty():
		var missing: Dictionary = partial.final_state.duplicate(true)
		missing.erase("observations_delivered_by_target")
		check(not Team.evaluate_state(missing).ok, "missing whole delivery map unavailable")
	check(cases.size() == 12, "all real-v2 controls completed")
	DirAccess.make_dir_recursive_absolute("res://exports/check-evidence/team-alignment")
	var file: FileAccess = FileAccess.open("res://exports/check-evidence/team-alignment/goal-controls.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "failed": failed, "scoring": "proposal", "cases": cases}, "\t", true, true))
	file.close()
	print("KE2 TEAM GOAL CONTROLS: %d passed, %d failed, %d native cases" % [passed, failed, cases.size()])
	quit(0 if failed == 0 else 1)
