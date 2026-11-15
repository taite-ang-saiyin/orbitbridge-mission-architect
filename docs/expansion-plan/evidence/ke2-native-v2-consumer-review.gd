extends SceneTree
## Run in KE2's checkout after hpc-native-v2-review.gd records original traces.
const Evaluation = preload("res://scripts/evaluation/mission_expansion_candidate.gd")
const Evidence = preload("res://scripts/evaluation/mission_goal_evidence.gd")
var passed: int = 0
var failed: int = 0

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL " + message)

func _initialize() -> void:
	var packet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://exports/check-evidence/hpc-native-v2-review.json"))
	var original: Dictionary = packet.duplicate(true)
	var results: Dictionary = {}
	for name: String in packet.native_traces:
		var trace: Dictionary = packet.native_traces[name]
		var config: Dictionary = trace.config
		var state: Dictionary = trace.final_state
		var communication: bool = config.mission.objective == "communication"
		var measured: Dictionary = Evidence._communication(state, trace.events) if communication else Evidence._weather(config, state, trace.events)
		check(measured.ok, "native v2 evidence accepted " + name)
		if not measured.ok:
			continue
		var count: int = measured.measure.positive_transmit_steps if communication else measured.measure.selected_target_revolution_visits
		check(count == state.goal_progress.actual_count, "independent event count equals native v2 counter " + name)
		var direct: Dictionary = Evaluation.evaluate_mission(config, state, trace.events)
		check(not direct.ok and direct.error.field_path == "config.contract_revision", "direct HPC config mismatch is explicit " + name)
		# Review-only field mapping. Preserve the original trace separately and
		# record a new fixture identity. SE must agree actual execution binding.
		var fixture_config: Dictionary = config.duplicate(true)
		fixture_config.contract_revision = Evaluation.INPUT_REVISION
		fixture_config.preset_id = "communication" if communication else "weather_monitoring"
		fixture_config.preset_revision = 2 if communication else 1
		fixture_config.mission.goal = {"kind": "communication_contacts", "required_positive_contact_steps": 2} if communication else {"kind": "weather_revisit", "required_distinct_orbits": 2}
		var fixture_state: Dictionary = state.duplicate(true)
		fixture_state.config_snapshot = fixture_config.duplicate(true)
		var reply: Dictionary = Evaluation.evaluate_mission(fixture_config, fixture_state, trace.events)
		check(reply.ok, "candidate config fixture evaluates " + name)
		if not reply.ok:
			printerr(reply)
			continue
		var expected: int = 1 if name.ends_with("shortfall") else 2
		check(count == expected and reply.report.score == (75 if expected == 1 else 100), "proposed count and score " + name)
		check(reply.report.size() == 19 and reply.report.goal_progress is Array, "reviewed consumer envelope " + name)
		check(reply.report.returned_data_mb == state.returned_data_mb, "raw native MB retained " + name)
		results[name] = {"native_objective": config.mission.objective, "native_count": count,
			"returned_data_mb": state.returned_data_mb, "direct_config_result": direct,
			"review_fixture_config": fixture_config, "review_fixture_report": reply.report,
			"provenance": "native config-v2 mechanics with explicit review-only config/snapshot field mapping",
			"production_execution_binding": "pending_SE"}
	check(packet == original, "original native-v2 evidence preserved")
	var path: String = "res://exports/check-evidence/ke2-native-v2-consumer-review.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"hpc_commit": "61a2772", "passed": passed, "failed": failed,
		"scoring": "proposal", "direct_contract_compatibility": false, "cases": results}, "\t", true, true))
	file.close()
	print("KE2 NATIVE V2 CONSUMER REVIEW: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
