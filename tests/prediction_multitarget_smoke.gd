extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Step = preload("res://core/MissionStepEngine.gd")
func _initialize() -> void:
	var loaded: Dictionary = Runtime.load_game_catalogs()
	for objective in ["Capture Imagery", "Survey Target Regions"]:
		for orbit in Runtime.ORBITS:
			var draft: Dictionary = preload("res://data/mock/DesignCatalog.gd").DEFAULTS.duplicate(true)
			draft.objective = objective
			draft.orbit = orbit
			draft.duration = 3
			draft.targets = ["Tropical Forest", "Equatorial Ocean"] if Runtime.ORBITS[orbit] == "low_eq" else ["Arctic Ice", "Antarctic Region"]
			draft.observations = 2
			var started: Dictionary = Step.init_validated_run(Runtime.config_for(draft), loaded.catalogs, "prediction_test", "prediction_mission")
			assert(started.ok)
			var state: Dictionary = started.state
			while state.phase == "operating":
				for action in Step.ACTIONS: verify(state, action)
				var action: String = "power_save"
				if state.available_actions.observe.allowed: action = "observe"
				elif state.available_actions.transmit.allowed: action = "transmit"
				state = Step.request_action(state, action).state
			for action in Step.ACTIONS: verify(state, action)
			assert(state.observations_by_target.size() == 2)
			var returned: float = 0.0
			for amount in state.returned_data_by_target_mb.values(): returned += amount
			assert(is_equal_approx(returned, state.returned_data_mb))
			var aborted: Dictionary = Step.abort_run(started.state, "Prediction abort test").state
			verify(aborted, "observe")
			print("PASS prediction/execution parity, unchanged inputs and multi-target tracking: ", objective, " / ", orbit)
	quit(0)
func verify(state: Dictionary, action: String) -> void:
	var before: Dictionary = state.duplicate(true)
	var projected: Dictionary = Step.predict_next_step(state, action)
	assert(projected.ok and Step.predict_next_step(state, action) == projected)
	assert(state == before, "Prediction mutated state, history or event sequence")
	var actual: Dictionary = Step.request_action(state, action)
	assert(actual.ok and actual.allowed == projected.prediction.allowed)
	assert(actual.state.step_index == projected.prediction.next_step_index)
	assert(actual.state.phase == projected.prediction.phase_after)
	assert(actual.state.run_status == projected.prediction.run_status_after)
	for field in ["energy_wh", "stored_data_mb", "returned_data_mb", "observations_completed"]:
		assert(actual.state[field] == projected.prediction[field + "_after"], "Prediction differs from execution for " + field)
	assert(state == before, "Execution mutated its caller's state")
