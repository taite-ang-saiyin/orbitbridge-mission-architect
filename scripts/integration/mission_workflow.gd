extends RefCounted
## Connects agreed producers. Engineering, simulation and scoring stay with their owners.
const Catalog = preload("res://scripts/integration/design_catalog.gd")
const Loader = preload("res://scripts/core/catalog_loader.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Adapter = preload("res://core/HPCContractAdapter.gd")
const StepEngine = preload("res://core/MissionStepEngine.gd")
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
static var run_sequence: int = 0
static var mission_sequence: int = 0

static func new_draft() -> Dictionary:
	mission_sequence += 1
	var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
	draft["mission_id"] = "mission_%04d" % mission_sequence
	draft["active_run"] = {}
	draft["reports"] = {}
	return draft

static func reset(draft: Dictionary) -> void:
	draft.clear()
	draft.merge(new_draft())

static func to_config(draft: Dictionary) -> Dictionary:
	# Multiple or unknown targets are rejected, never silently replaced with the first.
	var targets: Variant = draft.get("targets", [])
	var target_id: String = "equator" if targets is Array and targets == ["Equator"] else ""
	var parts: Dictionary = draft.get("components", {})
	var design: Dictionary = {}
	for category in ["bus", "instrument", "solar", "battery", "radio", "storage"]:
		design[category + "_id"] = parts.get("payload" if category == "instrument" else category)
	design.merge({"orbit_id": draft.get("orbit"), "launcher_id": draft.get("launcher"), "launch_profile_id": draft.get("launch_profile")})
	return {"schema_version": 1, "mission": {
		"title": draft.get("name"), "objective": draft.get("objective"), "target_region": target_id,
		"required_observations": draft.get("observations"), "required_returned_data_mb": draft.get("required_returned_data_mb"),
		"duration_orbits": draft.get("duration"), "budget_credits": draft.get("budget")}, "design": design}

static func review(draft: Dictionary) -> Dictionary:
	var loaded: Dictionary = Loader.load_catalogs()
	return _review_loaded(draft, loaded)

static func _review_loaded(draft: Dictionary, loaded: Dictionary) -> Dictionary:
	var config: Dictionary = to_config(draft)
	var result: Dictionary = Validator.validate(config, loaded.catalogs)
	if config.mission.target_region == "":
		for issue in result.errors:
			if issue.field_path == "mission.target_region":
				issue.message = "Choose Equator as the single target. Other targets are not supported in this demo."
				issue.suggested_fix = "Open Mission Creator and select Equator."
	if not loaded.ok:
		result.errors.append_array(loaded.errors)
	draft["mission_config"] = config.duplicate(true)
	draft["validation"] = result.duplicate(true)
	return result

static func start_run(draft: Dictionary) -> Dictionary:
	if is_operating(draft): return _error("RUN_IN_PROGRESS", "Finish or stop the current mission before starting another.")
	var loaded: Dictionary = Loader.load_catalogs()
	var result: Dictionary = _review_loaded(draft, loaded)
	if not result.ready_to_launch:
		return {"ok": false, "error": {"code": "DESIGN_BLOCKED", "message": "Resolve the readiness checks before launch."}, "validation": result}
	var config: Dictionary = to_config(draft).duplicate(true)
	if not loaded.ok: return _error("CATALOG_UNAVAILABLE", "Mission data could not be loaded. Launch is blocked.")
	var built: Dictionary = Adapter.build_scenario(loaded.catalogs, loaded.catalogs.get("orbit_catalog", {}))
	if not built.ok: return _error(str(built.get("error_code")), str(built.get("error_message")))
	return _initialize_run(draft, config, loaded.catalogs, built.scenario, draft.get("policy", "Observe First"))

static func _initialize_run(draft: Dictionary, config: Dictionary, catalogs: Dictionary, scenario: Dictionary, policy: String) -> Dictionary:
	run_sequence += 1
	if not draft.has("mission_id"):
		mission_sequence += 1
		draft["mission_id"] = "mission_%04d" % mission_sequence
	var started: Dictionary = StepEngine.init_run(config, scenario, "run_%04d" % run_sequence, draft.mission_id)
	if not started.ok: return started
	draft["active_run"] = {"config": config.duplicate(true), "catalogs": catalogs.duplicate(true), "scenario": scenario.duplicate(true),
		"state": started.state, "policy": policy, "evaluation": {}}
	return {"ok": true, "state": started.state.duplicate(true)}

static func retry(draft: Dictionary) -> Dictionary:
	if is_operating(draft): return _error("RUN_IN_PROGRESS", "Finish or stop this mission before retrying.")
	var previous: Dictionary = draft.get("active_run", {})
	if previous.is_empty(): return _error("NO_PREVIOUS_RUN", "Run a mission before retrying it.")
	var checked: Dictionary = Validator.validate(previous.config, previous.catalogs)
	if not checked.ready_to_launch: return _error("DESIGN_BLOCKED", "The previous design cannot pass its saved launch checks.")
	var config: Dictionary = previous.config
	draft.name = config.mission.title
	draft.objective = config.mission.objective
	draft.targets = ["Equator"]
	draft.observations = config.mission.required_observations
	draft.required_returned_data_mb = config.mission.required_returned_data_mb
	draft.duration = config.mission.duration_orbits
	draft.budget = config.mission.budget_credits
	draft.orbit = config.design.orbit_id
	draft.launcher = config.design.launcher_id
	draft.launch_profile = config.design.launch_profile_id
	draft.policy = previous.policy
	for category in ["bus", "instrument", "solar", "battery", "radio", "storage"]:
		draft.components["payload" if category == "instrument" else category] = config.design[category + "_id"]
	return _initialize_run(draft, config, previous.catalogs, previous.scenario, previous.policy)

static func is_operating(draft: Dictionary) -> bool:
	return draft.get("active_run", {}).get("state", {}).get("phase") == "operating"

static func request_action(draft: Dictionary, action: String) -> Dictionary:
	if not is_operating(draft): return _error("NO_OPERATING_RUN", "Launch a mission before choosing an action.")
	var result: Dictionary = StepEngine.request_action(draft.active_run.state, action)
	if result.get("ok", true) and result.has("state"):
		draft.active_run.state = result.state
		_evaluate_terminal(draft)
	return result

static func automatic_step(draft: Dictionary) -> Dictionary:
	if not is_operating(draft): return _error("NO_OPERATING_RUN", "There is no mission to advance.")
	var run: Dictionary = draft.active_run
	var available: Dictionary = StepEngine.get_available_actions(run.state)
	if not available.ok: return available
	var choices: Array = ["observe", "transmit"] if run.policy == "Observe First" else ["transmit", "observe"]
	var need_observation: bool = run.state.observations_completed < run.config.mission.required_observations or run.state.returned_data_mb + run.state.stored_data_mb < run.config.mission.required_returned_data_mb
	for action in choices:
		if action == "observe" and not need_observation: continue
		if available.available_actions[action].allowed:
			return request_action(draft, action)
	return request_action(draft, "power_save")

static func abort(draft: Dictionary) -> Dictionary:
	if not is_operating(draft): return _error("NO_OPERATING_RUN", "There is no running mission to stop.")
	var result: Dictionary = StepEngine.abort_run(draft.active_run.state, "Stopped by the player.")
	if result.ok:
		draft.active_run.state = result.state
		_evaluate_terminal(draft)
	return result

static func evaluation(draft: Dictionary) -> Dictionary:
	_evaluate_terminal(draft)
	return draft.get("active_run", {}).get("evaluation", {}).duplicate(true)

static func _evaluate_terminal(draft: Dictionary) -> void:
	var run: Dictionary = draft.get("active_run", {})
	if run.is_empty() or run.state.phase != "finished" or not run.evaluation.is_empty(): return
	var result: Dictionary = Evaluator.evaluate_mission(run.config, run.state, run.state.event_log)
	run.evaluation = result.duplicate(true)
	if result.ok:
		if not draft.has("reports"): draft["reports"] = {}
		draft.reports[run.state.run_id] = result.report.duplicate(true)

static func totals_text(result: Dictionary) -> String:
	if result.metrics == null: return "Totals unavailable. Correct the listed selections first."
	var m: Dictionary = result.metrics
	return "Mass: %d g  ·  Cost: %d credits\nSolar: %.1f W  ·  Baseline: %.1f W\nBattery: %.1f / %.1f Wh  ·  Storage: %.1f MB\nObservation: %.1f MB  ·  Downlink: %.1f MB/hour" % [m.total_mass_g, m.total_cost_credits, m.solar_generation_power_w, m.baseline_power_w, m.initial_energy_wh, m.battery_capacity_wh, m.storage_capacity_mb, m.data_per_observation_mb, m.downlink_mb_per_hour]

static func issue_text(result: Dictionary) -> String:
	var messages: PackedStringArray = []
	for issue in result.errors:
		messages.append(issue.message + " " + issue.suggested_fix)
	return "All required launch checks pass." if messages.is_empty() else "\n".join(messages)

static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "error": {"code": code, "message": message}}
