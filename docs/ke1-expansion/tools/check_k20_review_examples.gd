extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Steps = preload("res://core/MissionStepEngine.gd")
var passed: int = 0
var failed: int = 0
var result: Dictionary = {"scope": "CURRENT_V1_PHYSICAL_SURROGATES_ONLY_NOT_V2_ACCEPTANCE", "examples": {}, "weather_decision_traces": {}}
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1; printerr("FAIL: " + label)
func physical(candidate: Dictionary) -> Dictionary:
	var config: Dictionary = candidate.duplicate(true)
	for key in ["contract_revision", "preset_id", "preset_revision"]: config.erase(key)
	config.schema_version = 1
	config.mission.erase("goal")
	if config.mission.objective in ["communication", "weather_monitoring"]: config.mission.objective = "imaging"
	return config
func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var base: String = args[0]
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("manifest.json")))
	var loaded: Dictionary = Runtime.load_game_catalogs()
	check(loaded.ok, "Active runtime catalogs load")
	if not loaded.ok: quit(1); return
	for example in manifest.cases:
		var is_positive: bool = example.proposed_issues.is_empty()
		if not is_positive and not example.id in ["heavy_part_combination", "budget_shortfall"]: continue
		var candidate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join(example.file)))
		check(not Validator.validate(candidate, loaded.catalogs).ready_to_launch, example.id + ": production still rejects v2")
		var config: Dictionary = physical(candidate)
		var before: String = JSON.stringify(loaded.catalogs)
		var ready: Dictionary = Validator.validate(config, loaded.catalogs)
		check(ready.ready_to_launch == is_positive, example.id + ": actual physical readiness matches expected")
		check(ready.checks.size() == 8, example.id + ": eight existing readiness gates preserved")
		check(before == JSON.stringify(loaded.catalogs), example.id + ": shared catalogs unchanged")
		if not is_positive:
			var issues: Array = []
			for issue in ready.errors: issues.append(issue.code)
			check(example.proposed_issues[0].code in issues, example.id + ": actual existing error code verified")
		if example.id == "advanced_imaging": check(ready.metrics.total_mass_g == 1300 and ready.metrics.total_cost_credits == 104, "Advanced alternate setup measures 1300 g / 104 credits")
		if example.id == "communication": check(ready.metrics.total_mass_g == 1120 and ready.metrics.total_cost_credits == 89, "Communication starter preserved")
		result.examples[example.id] = {"physical_test_config_v1": config, "production_v2_accepted": false, "physical_readiness": ready}
	var weather: Dictionary = physical(JSON.parse_string(FileAccess.get_file_as_string(base.path_join("candidate-valid/weather_monitoring.json"))))
	for full_return in [false, true]:
		var name: String = "complete_return" if full_return else "second_visit_unreturned"
		var init: Dictionary = Steps.init_validated_run(weather, loaded.catalogs, "weather_review_" + name, "k20_open_delivery_decision")
		check(init.ok, name + ": native run initializes")
		if not init.ok: continue
		var state: Dictionary = init.state
		for step in range(30):
			var action: String = "power_save"
			if step in [1, 11]: action = "observe"
			elif step in ([7, 10, 17, 20] if full_return else [7, 10]): action = "transmit"
			var reply: Dictionary = Steps.request_action(state, action)
			check(reply.get("ok", false) and reply.get("allowed", false), name + ": planned action accepted at " + str(step))
			if not reply.get("ok", false): break
			state = reply.state
		check(state.phase == "finished" and state.observations_completed == 2, name + ": two captures and completed run")
		check(absf(float(state.returned_data_mb) - (24.0 if full_return else 12.0)) < 0.000001, name + ": exact returned MB")
		check(state.observations_delivered_by_target.equator == (2 if full_return else 1), name + ": exact complete-delivery count")
		if not full_return: check(state.data_packets.size() == 1 and state.data_packets[0].remaining_mb == 12, "Second visit's entire image remains onboard in ambiguity example")
		result.weather_decision_traces[name] = {"config_v1_physical_surrogate": weather, "final_state": state, "draft2_capture_plus_mb_thresholds": "met", "stronger_complete_delivery_per_visit_alternative": "met" if full_return else "missed", "owner_selection": "PENDING", "official_score": null}
	result.passed = passed; result.failed = failed
	var file = FileAccess.open(args[1], FileAccess.WRITE)
	if file == null: printerr("FAIL: evidence output unavailable"); quit(1); return
	file.store_string(JSON.stringify(result, "  ")); file.close()
	print("K20 review physical QA: %d checks passed; %d failed; %d physical examples; two Weather decision traces." % [passed, failed, result.examples.size()])
	quit(0 if failed == 0 else 1)
