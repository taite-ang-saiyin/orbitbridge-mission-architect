extends SceneTree
## Review-only historical evidence/key checks; does not evaluate new objectives.
const Results = preload("res://scripts/integration/mission_results.gd")
const ROOT = "res://docs/expansion-plan/evidence/"
var passed: int = 0
var failed: int = 0

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		printerr("FAIL " + label)

func _initialize() -> void:
	var packet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "ke2-handoff-current.json"))
	var bindings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "execution-key-preimages-review.json"))
	var roundtrip_mismatches: int = 0
	for name: String in packet.cases:
		var item: Dictionary = packet.cases[name]
		var trace: Dictionary = item.trace
		var preimage: String = bindings.cases[name].preimage_utf8
		check(preimage.sha256_text() == item.execution_key, name + " historical execution key from recorded bytes")
		check(JSON.parse_string(preimage) == [trace.config, trace.final_state, trace.events, trace.validation], name + " preimage matches supplied execution values")
		if Results.input_key(trace) != item.execution_key:
			roundtrip_mismatches += 1
		check(trace.config == trace.final_state.config_snapshot and trace.events == trace.final_state.event_log, name + " retained execution snapshots")
		var seen: Array = []
		var valid: bool = true
		for event: Dictionary in trace.events:
			valid = valid and not seen.has(event.event_id) and event.run_id == trace.final_state.run_id and event.mission_id == trace.final_state.mission_id
			seen.append(event.event_id)
		check(valid, name + " unique same-run event identities")
	for version in [1, 2]:
		var filename: String = "report-examples-proposal.json" if version == 1 else "report-examples-v2-proposal.json"
		var examples: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + filename))
		check(FileAccess.get_sha256("res://" + examples.source_packet) == examples.source_packet_sha256, "v%d source packet hash" % version)
		for name: String in examples.examples:
			var item: Dictionary = examples.examples[name]
			var source: Dictionary = packet.cases[item.source_case_id]
			var report: Dictionary = item.report_example.report
			var final: Dictionary = source.trace.final_state
			check(report.schema_version == version and report.size() == 19, name + " candidate version and 17-plus-two field count")
			check(item.production_reply == source.evaluation, name + " actual production reply preserved")
			check(item.source_execution_key == source.execution_key and report.run_id == final.run_id and report.mission_id == final.mission_id, name + " source execution binding")
			check(report.observations_completed == final.observations_completed and report.returned_data_mb == final.returned_data_mb, name + " raw actuals retained")
			var ids: Array = []
			for event: Dictionary in source.trace.events:
				ids.append(event.event_id)
			for goal: Dictionary in report.goal_progress:
				var valid: bool = goal.required > 0 and goal.actual >= 0 and goal.met == (goal.actual >= goal.required)
				valid = valid and absf(float(goal.completion_ratio) - minf(1.0, float(goal.actual) / float(goal.required))) < 1e-9
				for id in goal.evidence_event_ids:
					valid = valid and ids.has(id)
				check(valid, name + " supplied goal ratios/verdicts and same-run evidence: " + goal.id)
	var integer_json: String = JSON.stringify([1], "", true, true)
	var parsed_json: String = JSON.stringify(JSON.parse_string(integer_json), "", true, true)
	check(integer_json != parsed_json, "numeric-type roundtrip reproduces serialization difference")
	print("Known unresolved transport issue: %d of 8 keys differ after Godot JSON load; minimal example %s -> %s" % [roundtrip_mismatches, integer_json, parsed_json])
	print("SE REPORT EVIDENCE: %d passed; %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
