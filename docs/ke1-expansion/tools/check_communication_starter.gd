extends SceneTree
## Review-only current-engine audit; never an exposed v2-to-v1 runtime adapter.
const Presets = preload("res://scripts/core/mission_preset_catalog.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Steps = preload("res://core/MissionStepEngine.gd")
var failed: int = 0
var passed: int = 0
var output: Dictionary = {"base_main": "dce75db845f6c494b8c25c9028dd9c0648aabd91", "status": "KE1_LOCAL_FEASIBILITY_ONLY_HPC_REVIEW_PENDING", "cases": {}}
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1; printerr("FAIL: " + label)
func run() -> void:
	var loaded: Dictionary = Runtime.load_game_catalogs()
	check(loaded.ok, "Runtime catalogs load")
	if not loaded.ok: quit(1); return
	var registry: Dictionary = Presets.load_registry()
	check(registry.ok, "Current candidate registry loads")
	if not registry.ok: quit(1); return
	var candidate: Dictionary = Presets.get_preset(registry.registry, "communication").preset.candidate_config_v2
	check(candidate.contract_revision == "expansion-goals-v2-draft-2" and candidate.preset_revision == 2, "Exact reviewed Communication revision")
	check(candidate.design.radio_id == "radio_fast" and candidate.mission.required_observations == 2, "Proposed fast-radio starter loaded from registry")
	output.registry_revision = registry.registry.registry_revision
	output.candidate_config_v2 = candidate.duplicate(true)
	for captures in [2, 1]:
		# Test-only physical surrogate; current production boundary must still reject v2.
		check(not Validator.validate(candidate, loaded.catalogs).ready_to_launch, "Current boundary rejects unimplemented v2 mission")
		var config: Dictionary = candidate.duplicate(true)
		for field in ["contract_revision", "preset_id", "preset_revision"]: config.erase(field)
		config.schema_version = 1
		config.mission.objective = "imaging"
		config.mission.erase("goal")
		config.mission.required_observations = captures
		var validation: Dictionary = Validator.validate(config, loaded.catalogs)
		check(validation.ready_to_launch and validation.checks.size() == 8, "All eight readiness checks pass")
		check(validation.metrics.total_mass_g == 1120 and validation.metrics.total_cost_credits == 89, "KE2 mass and cost match")
		var started: Dictionary = Steps.init_validated_run(config, loaded.catalogs, "ke2_fast_" + str(captures), "mission_ke2_followup")
		check(started.ok, "Validated run initializes")
		if not started.ok: continue
		var state: Dictionary = started.state
		for index in range(30):
			var action: String = "power_save"
			if index == 1 or (captures == 2 and index == 6): action = "observe"
			elif index == 7 or index == 10: action = "transmit"
			var before: String = JSON.stringify(state)
			var result: Dictionary = Steps.request_action(state, action)
			check(before == JSON.stringify(state), "Engine input state unchanged")
			check(result.ok, "Action returns engine result")
			if not result.ok: break
			state = result.state
			if not result.allowed:
				check(captures == 1 and index == 10 and result.events[0].code == "NO_DATA", "Only empty-buffer control is rejected")
				check(result.events[0].delta_returned_data_mb == 0, "Rejected empty-buffer transfer returns zero MB")
				result = Steps.request_action(state, "power_save")
				check(result.ok and result.allowed, "Power save advances after rejected request")
				state = result.state
			check(state.step_index == index + 1, "Accepted actions advance exactly once")
			check(state.energy_wh >= 0 and state.stored_data_mb >= 0 and state.stored_data_mb <= state.storage_capacity_mb, "Resources remain bounded")
		var positive: Array = []; var amounts: Array = []
		for event in state.event_log:
			if event.type == "action_accepted" and event.action == "transmit" and event.delta_returned_data_mb > 0:
				positive.append(event.step_index); amounts.append(event.delta_returned_data_mb)
		check(state.phase == "finished" and state.run_status == "completed", "Full run completes")
		check(positive == ([7, 10] if captures == 2 else [7]), "Exact positive contact steps match prediction")
		check(absf(state.returned_data_mb - float(captures * 12)) < 0.000001, "Expected payload returned")
		check(state.returned_data_mb >= 12, "Data threshold met in both cases")
		check((positive.size() >= 2) == (captures == 2), "One-packet control misses only the contact goal")
		output.cases[str(captures) + "_captures"] = {"config": config, "validation": validation, "positive_steps": positive, "transfer_mb": amounts, "returned_mb": state.returned_data_mb, "contact_goal_met": positive.size() >= 2, "data_goal_met": state.returned_data_mb >= 12, "final_state": state, "official_new_goal_score": null}
	output.passed = passed; output.failed = failed
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty(): printerr("Pass an output directory after --"); quit(1); return
	DirAccess.make_dir_recursive_absolute(args[0])
	var file = FileAccess.open(args[0].path_join("communication-fast-radio-check.json"), FileAccess.WRITE)
	if file == null: printerr("FAIL: Cannot save follow-up evidence"); quit(1); return
	file.store_string(JSON.stringify(output, "  ")); file.close()
	print("KE2 fast-radio follow-up: %d passed; %d failed." % [passed, failed])
	for key in output.cases:
		var result: Dictionary = output.cases[key]
		print(key, ": ", result.positive_steps, " / MB ", result.transfer_mb, " / total ", result.returned_mb)
	quit(0 if failed == 0 else 1)
