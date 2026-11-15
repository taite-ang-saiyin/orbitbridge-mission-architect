extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Step = preload("res://core/MissionStepEngine.gd")
const Adapter = preload("res://core/HPCContractAdapter.gd")
func _initialize() -> void:
	for objective in ["communication", "weather_monitoring"]:
		var draft: Dictionary = preload("res://data/mock/DesignCatalog.gd").DEFAULTS.duplicate(true)
		assert(Runtime.select_preset(draft, objective).ok)
		var config: Dictionary = Runtime.config_for(draft)
		var catalogs: Dictionary = Runtime.catalogs_for(config).catalogs
		var original: Dictionary = catalogs.duplicate(true)
		var scenario: Dictionary = Adapter.build_scenario(catalogs, catalogs.orbit_catalog).scenario
		var start: Dictionary = Step.init_validated_run(config,catalogs,"native_"+objective,"mission")
		assert(start.ok and start.state.config_snapshot == config and catalogs == original)
		for same_orbit in [false, true]:
			var state: Dictionary = start.state
			while state.phase == "operating":
				var index: int = state.step_index
				var observations: Array = [1,6] if objective == "communication" or same_orbit else [1,11]
				var action: String = "observe" if index in observations else ("transmit" if index in [7,10,17,20,27] else "power_save")
				var before: Dictionary = state.duplicate(true)
				var prediction: Dictionary = Step.predict_next_step(state,action)
				var result: Dictionary = Step.request_action(state,action)
				if not result.ok:
					print(index, " ", result, " prediction ",prediction); quit(1); return
				assert(state == before and result.allowed == prediction.prediction.allowed)
				state = result.state
				if not result.allowed: state = Step.request_action(state,"power_save").state
			assert(state.goal_progress.actual_count == (1 if same_orbit and objective == "weather_monitoring" else 2))
			assert(state.config_snapshot == config and state.scenario_snapshot == scenario)
			var forged: Dictionary = state.duplicate(true)
			forged.goal_progress.actual_count += 1
			assert(not Step.predict_next_step(forged,"power_save").ok)
		var missing_log: Dictionary = start.state.duplicate(true)
		missing_log.erase("event_log")
		assert(not Step.predict_next_step(missing_log,"observe").ok)
		if objective == "communication":
			var shortfall: Dictionary = start.state
			while shortfall.phase == "operating":
				var action: String = "observe" if shortfall.step_index == 1 else ("transmit" if shortfall.step_index in [7,10] else "power_save")
				var reply: Dictionary = Step.request_action(shortfall,action)
				assert(reply.ok)
				shortfall = reply.state
				if not reply.allowed: shortfall = Step.request_action(shortfall,"power_save").state
			assert(shortfall.returned_data_mb >= 12 and shortfall.goal_progress.actual_count == 1)
		var malformed: Dictionary = config.duplicate(true)
		malformed.mission.goal = {"kind":objective,"required_count":2}
		assert(not Step.init_run(malformed,scenario,"invalid","mission").ok)
		malformed = config.duplicate(true); malformed.schema_version = 2.5
		assert(not Step.init_run(malformed,scenario,"invalid","mission").ok)
		var mismatched: Dictionary = scenario.duplicate(true)
		mismatched.orbits[0].sunlight_windows = []
		assert(not Step.init_run(config,mismatched,"invalid","mission").ok)
		var abort: Dictionary = Step.abort_run(start.state,"Operator stopped the flight")
		assert(abort.ok and abort.state.config_snapshot == config and abort.state.goal_progress.actual_count == 0)
		print("PASS native ", objective, ": canonical contract, counts, same-orbit control, prediction parity, abort, input immutability and forged evidence rejection")
	quit(0)
