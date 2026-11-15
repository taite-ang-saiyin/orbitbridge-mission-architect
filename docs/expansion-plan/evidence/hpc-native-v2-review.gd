extends SceneTree
## Run inside the isolated HPC 61a2772 snapshot. This records branch behavior.
const Adapter = preload("res://core/HPCContractAdapter.gd")
const Step = preload("res://core/MissionStepEngine.gd")
const Simulator = preload("res://core/MissionSimulator.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const LEGACY_FIELDS = ["schema_version", "run_id", "mission_id", "run_status", "status",
	"observations_completed", "required_observations", "returned_data_mb", "required_returned_data_mb",
	"observation_completion_ratio", "data_return_completion_ratio", "score", "explanation", "root_causes",
	"next_experiment", "source_ids", "comparison"]

func config_for(objective: String) -> Dictionary:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/valid_1u_feasible.json"))
	config.schema_version = 2
	# Reproduce upstream test inputs. These names carry upstream's asserted label.
	config.contract_revision = "v2.0-agreed"
	config.preset_id = "hpc_" + objective
	config.preset_revision = 1
	config.mission.objective = objective
	config.mission.goal = {"kind": objective, "required_count": 2}
	config.mission.required_observations = 2
	config.mission.required_returned_data_mb = 12.0
	config.mission.duration_orbits = 3
	config.design.radio_id = "radio_fast"
	return config

func run_plan(config: Dictionary, scenario: Dictionary, name: String, observe_steps: Array) -> Dictionary:
	var begun: Dictionary = Step.init_run(config, scenario, name, "ke2_hpc_branch_review")
	if not begun.ok:
		return begun
	var initial: Dictionary = begun.state.duplicate(true)
	var state: Dictionary = begun.state
	while state.phase == "operating":
		var action: String = "power_save"
		if int(state.step_index) in observe_steps:
			action = "observe"
		elif int(state.step_index) in [7, 10, 17, 20, 27]:
			action = "transmit"
		var response: Dictionary = Step.request_action(state, action)
		if not response.ok:
			return response
		state = response.state
		if not response.allowed:
			response = Step.request_action(state, "power_save")
			if not response.ok or not response.allowed:
				return {"ok": false, "error": "fallback failed"}
			state = response.state
	return {"ok": true, "config": config, "initial_state": initial, "final_state": state, "events": state.event_log}

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): printerr("FAIL branch review timeout"); quit(1))
	var loaded: Dictionary = Runtime.load_game_catalogs()
	var built: Dictionary = Adapter.build_scenario(loaded.catalogs, loaded.catalogs.orbit_catalog)
	if not loaded.ok or not built.ok:
		printerr("FAIL branch catalogs")
		quit(1)
		return
	var communication: Dictionary = config_for("communication")
	var success: Dictionary = run_plan(communication, built.scenario, "native_v2_complete", [1, 6])
	var shortfall: Dictionary = run_plan(communication, built.scenario, "native_v2_shortfall", [1])
	var weather: Dictionary = config_for("weather_monitoring")
	var weather_success: Dictionary = run_plan(weather, built.scenario, "native_weather_complete", [1, 11])
	var weather_shortfall: Dictionary = run_plan(weather, built.scenario, "native_weather_shortfall", [1, 6])
	if not success.ok or not shortfall.ok or not weather_success.ok or not weather_shortfall.ok:
		printerr("FAIL native v2 trace generation")
		quit(1)
		return
	var supplied_report: Dictionary = Evaluator.evaluate_hpc_state(success.final_state)
	var missing_fields: Array = []
	for field: String in LEGACY_FIELDS:
		if not supplied_report.get("report", {}).has(field):
			missing_fields.append(field)
	var altered: Dictionary = shortfall.final_state.duplicate(true)
	altered.goal_progress.actual_count = 2
	var altered_result: Dictionary = Evaluator.evaluate_hpc_state(altered)
	var canonical: Dictionary = communication.duplicate(true)
	canonical.contract_revision = "expansion-goals-v2-draft-2"
	canonical.preset_id = "communication"
	canonical.preset_revision = 2
	canonical.mission.goal = {"kind": "communication_contacts", "required_positive_contact_steps": 2}
	var canonical_start: Dictionary = Step.init_run(canonical, built.scenario, "canonical_probe", "canonical_probe")
	var invalid: Dictionary = communication.duplicate(true)
	invalid.mission.goal.required_count = 0
	var invalid_readiness: Dictionary = Validator.validate(invalid, loaded.catalogs)
	var direct_validated: Dictionary = Step.init_validated_run(communication, loaded.catalogs, "validated_v2", "validated_v2")
	var simulator_config: Dictionary = communication.duplicate(true)
	simulator_config.mission.required_observations = 4
	var simulated: Dictionary = Simulator.simulate(simulator_config, built.scenario)
	var output: Dictionary = {"hpc_revision": "61a2772", "review_status": "integration_changes_required",
		"native_traces": {"communication_complete": success, "communication_shortfall": shortfall,
			"weather_complete": weather_success, "weather_shortfall": weather_shortfall},
		"hpc_report": supplied_report, "missing_legacy_report_fields": missing_fields,
		"canonical_config": canonical, "canonical_config_start": canonical_start,
		"invalid_goal_readiness": invalid_readiness, "validated_native_start_ok": direct_validated.get("ok", false),
		"altered_counter_report": altered_result, "real_shortfall_actual_count": shortfall.final_state.goal_progress.actual_count,
		"simulator_metrics": simulated.get("metrics"), "simulator_ok": simulated.get("ok", false)}
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else "res://exports/native-v2-review.json"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t", true, true))
	file.close()
	print("NATIVE V2 REVIEW: four original config-v2 traces retained")
	print("Native counts: ", success.final_state.goal_progress.actual_count, "/", shortfall.final_state.goal_progress.actual_count,
		" Communication; ", weather_success.final_state.goal_progress.actual_count, "/", weather_shortfall.final_state.goal_progress.actual_count, " Weather")
	print("Missing legacy report fields: ", missing_fields)
	print("Canonical draft config accepted: ", canonical_start.get("ok", false))
	print("Zero count goal readiness: ", invalid_readiness.get("ready_to_launch"))
	print("Altered shortfall reported as: ", altered_result.get("report", {}).get("status"))
	print("Simulator actual count: ", simulated.get("metrics", {}).get("actual_count"))
	quit(0)
