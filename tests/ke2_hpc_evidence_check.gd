extends SceneTree
## Consume HPC's published native packet and check KE2's confirmed measurements.
const Evaluation = preload("res://scripts/evaluation/mission_expansion_candidate.gd")
const Records = preload("res://scripts/evaluation/mission_expansion_records.gd")
const Comparison = preload("res://scripts/evaluation/mission_expansion_comparison.gd")
const GoalEvidence = preload("res://scripts/evaluation/mission_goal_evidence.gd")
const StepEngine = preload("res://core/MissionStepEngine.gd")
var passed: int = 0
var failed: int = 0
var records: Dictionary = {}

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL " + label)

func read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(parsed is Dictionary, "JSON dictionary " + path)
	return parsed if parsed is Dictionary else {}

func goal(report: Dictionary, id: String) -> Dictionary:
	for row: Dictionary in report.goal_progress:
		if row.id == id:
			return row
	return {}

func _initialize() -> void:
	create_timer(45).timeout.connect(func(): printerr("FAIL HPC consumer timeout"); quit(1))
	var evidence_dir: String = "res://exports/hpc-goal-evidence-345e5bd/docs/handoffs/hpc-goal-evidence-v1"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--evidence-dir")
	if index >= 0 and index + 1 < args.size():
		evidence_dir = args[index + 1]
	var manifest: Dictionary = read_json(evidence_dir.path_join("manifest.json"))
	if manifest.is_empty():
		quit(1)
		return
	check(manifest.bundle_revision == GoalEvidence.HPC_REVISION and manifest.examples.size() == 12, "pinned release has twelve examples")
	for entry: Dictionary in manifest.examples:
		var path: String = evidence_dir.path_join(entry.file)
		check(FileAccess.get_sha256(path) == entry.sha256, "original packet bytes " + entry.example_id)
		consume(read_json(path))
	legacy_records()
	zero_survey(read_json(evidence_dir.path_join("survey_two_targets_complete.json")))
	for pair in [["survey_two_targets_partial_packet", "survey_two_targets_complete", "selected_targets_delivered"],
		["communication_count_shortfall_proxy", "communication_complete_proxy", "positive_transmit_steps"],
		["weather_one_orbit_shortfall_proxy", "weather_two_orbits_proxy", "selected_target_revolution_visits"]]:
		if not records.has(pair[0]) or not records.has(pair[1]):
			check(false, "record pair available")
			continue
		var reply: Dictionary = Comparison.compare_runs(records[pair[0]], records[pair[1]])
		check(reply.ok and reply.get("comparison", {}).get("eligible", false), "HPC expanded comparison " + pair[0])
		if not reply.ok or not reply.comparison.eligible:
			printerr(reply)
			continue
		var changes: Array = reply.comparison.goal_measures.filter(func(row): return row.id == pair[2])
		check(changes.size() == 1 and changes[0].delta_b_minus_a == 1, "HPC qualifying count delta " + pair[0])
		check(reply.comparison.classification == "Design + operations", "different native manual requests classified")
		check(reply.comparison.measures.filter(func(row): return row.id == "lowest_battery_wh")[0].available, "HPC sampling usable in comparison")
	var radio_pair: Dictionary = Comparison.compare_runs(records.tropical_forest_watch_stock, records.tropical_forest_watch_fast_radio)
	check(radio_pair.ok and radio_pair.comparison.eligible and radio_pair.comparison.classification == "Design", "HPC fixed requested plan preserves Design classification")
	if radio_pair.ok and radio_pair.comparison.eligible:
		var data_change: Dictionary = radio_pair.comparison.measures.filter(func(row): return row.id == "returned_data_mb")[0]
		check(is_equal_approx(data_change.delta_b_minus_a, 15.6799999968), "HPC native fixed-plan radio data improvement")
	var output: Dictionary = {"hpc_commit": "345e5bd", "evidence_revision": GoalEvidence.HPC_REVISION,
		"candidate_scoring": true, "records": records, "checks_passed": passed, "checks_failed": failed}
	DirAccess.make_dir_recursive_absolute("res://exports/check-evidence/ke2-hpc-evidence")
	var file: FileAccess = FileAccess.open("res://exports/check-evidence/ke2-hpc-evidence/records.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t", true, true))
	file.close()
	print("KE2 HPC EVIDENCE: %d passed; %d failed; %d native examples" % [passed, failed, records.size()])
	quit(0 if failed == 0 else 1)

func consume(source: Dictionary) -> void:
	if source.is_empty():
		return
	var original: Dictionary = source.duplicate(true)
	check(source.expanded_objective_score == null, "HPC supplies measurements without an official score")
	var contact: Dictionary = GoalEvidence._communication(source.final_state, source.ordered_events)
	check(contact.ok and contact.measure.positive_transmit_steps == source.goal_measurements.positive_transmit_steps, "canonical contact delta " + source.example_id)
	var config: Dictionary = source.launch_config.duplicate(true)
	var state: Dictionary = source.final_state.duplicate(true)
	var initial: Dictionary = source.initial_state.duplicate(true)
	if source.mechanics_proxy:
		# Only fixture copies receive proposed objective fields. Native source bytes
		# and events remain bound to the original Imaging execution in the packet.
		config.schema_version = 2
		config.contract_revision = Evaluation.INPUT_REVISION
		var communication: bool = source.goal_type == "communication_contacts"
		config.preset_id = "communication" if communication else "weather_monitoring"
		config.preset_revision = 2 if communication else 1
		config.mission.objective = "communication" if communication else "weather_monitoring"
		config.mission.goal = {"kind": "communication_contacts", "required_positive_contact_steps": 2} if communication else {"kind": "weather_revisit", "required_distinct_orbits": 2}
		state.config_snapshot = config.duplicate(true)
		initial.config_snapshot = config.duplicate(true)
	var before: Array = [config, state].duplicate(true)
	var evaluated: Dictionary = Evaluation.evaluate_mission(config, state, source.ordered_events)
	check(evaluated.ok, "HPC default candidate evaluation " + source.example_id)
	if not evaluated.ok:
		printerr(evaluated)
		return
	check(Evaluation.evaluate_mission(config, state, source.ordered_events) == evaluated and [config, state] == before, "HPC deterministic and preserving")
	var report: Dictionary = evaluated.report
	check(report.returned_data_mb == state.returned_data_mb and report.observations_completed == state.observations_completed, "raw native actuals")
	if source.goal_type == "survey_delivery":
		var delivered: Dictionary = goal(report, "selected_targets_delivered")
		check(delivered.actual == source.goal_measurements.selected_targets_delivered, "native sparse Survey count")
		for row: Dictionary in delivered.by_target:
			check(row.actual == source.goal_measurements.complete_deliveries_by_selected_target[row.target_id], "native target complete counter")
		var missing: Dictionary = state.duplicate(true)
		missing.erase("observations_delivered_by_target")
		check(not Evaluation.evaluate_mission(config, missing, source.ordered_events).ok, "missing whole native map unavailable")
	elif source.goal_type == "communication_contacts":
		check(goal(report, "positive_transmit_steps").actual == source.goal_measurements.positive_transmit_steps, "Communication candidate count")
	elif source.goal_type == "weather_revisit":
		check(goal(report, "selected_target_revolution_visits").actual == source.goal_measurements.selected_target_revolution_visits, "Weather native revolution count")
		check(not report.explanation.contains("awaits HPC"), "confirmed Weather feedback")
	var expected: Dictionary = {"survey_two_targets_partial_packet": 83, "survey_two_targets_complete": 100,
		"communication_count_shortfall_proxy": 75, "communication_complete_proxy": 100,
		"communication_low_eq_basic_radio_proxy": 100, "weather_one_orbit_shortfall_proxy": 75, "weather_two_orbits_proxy": 100,
		"estuary_watch_stock": 100, "tropical_forest_watch_stock": 87, "tropical_forest_watch_fast_radio": 100,
		"polar_ice_survey_stock": 97, "polar_ice_survey_fast_radio": 100}
	check(report.score == expected[source.example_id], "candidate score " + source.example_id + " " + str(report.score))
	var requests: Array = []
	for event: Dictionary in source.ordered_events:
		if event.type in ["action_accepted", "action_blocked"]:
			requests.append({"step_index": event.step_index, "action": event.action})
	var parameters: Dictionary = source.action_plan.duplicate(true)
	parameters.erase("id")
	parameters.erase("version")
	var context: Dictionary = {"initial_state": initial, "catalogs_snapshot": state.scenario_snapshot.duplicate(true),
		"source_versions": {"engine": source.source.native_source_sha256["core/MissionStepEngine.gd"], "adapter": source.source.native_source_sha256["core/HPCContractAdapter.gd"],
			"catalogs": JSON.stringify(state.scenario_snapshot, "", true, true).sha256_text(), "scenario": state.scenario_snapshot.scenario_version,
			"evaluator": Evaluation.EVALUATOR_REVISION, "report": Evaluation.REPORT_REVISION},
		"initialization_policy": "full_battery_empty_v1_proposal", "legacy_identity_policy": "exact_requirements_v1_proposal",
		"verification_scope": "typed_proxy_fixture" if source.mechanics_proxy else "native_modules",
		"source_credits": {}, "display_context": {"hpc_example": source.example_id, "hpc_commit": "345e5bd", "scoring": "proposal"},
		"operations": {"policy": {"id": source.action_plan.id, "version": source.action_plan.version, "parameters": parameters}, "manual_requests": [], "requested_actions": requests},
		"resource_samples": source.resource_samples.duplicate(true), "resource_sampling_id": source.resource_sampling_id}
	var built: Dictionary = Records.build_record(config, state, source.ordered_events, source.readiness, context)
	check(built.ok, "HPC record binding " + source.example_id)
	if built.ok:
		records[source.example_id] = built.record
		check(Records.validate_record(JSON.parse_string(JSON.stringify(built.record, "", true, true))).ok, "HPC record JSON transport")
		var compared: Dictionary = Comparison.compare_runs(built.record, built.record)
		check(compared.ok and compared.comparison.eligible, "HPC self comparison")
		if compared.ok and compared.comparison.eligible:
			for id: String in ["lowest_battery_wh", "lowest_battery_percent", "highest_storage_mb"]:
				var row: Dictionary = compared.comparison.measures.filter(func(measure): return measure.id == id)[0]
				check(row.available and is_equal_approx(row.a, source.resource_extrema[id]) and row.delta_b_minus_a == 0, "HPC post-clamp sampling " + id)
	else:
		printerr(built)
	check(source == original, "original HPC packet unchanged")

func legacy_records() -> void:
	var previous: Dictionary = read_json("res://docs/expansion-plan/evidence/ke2-integration-candidate-records.json")
	for name: String in previous.records:
		var old_record: Dictionary = previous.records[name]
		check(old_record.evaluator_revision == Evaluation.LEGACY_EVALUATOR_REVISION, "historical evaluator identified")
		var checked: Dictionary = Records.validate_record(old_record)
		check(checked.ok, "old candidate record still verifies " + name)
		if not checked.ok:
			printerr(checked)
	var mislabeled: Dictionary = previous.records.values()[0].duplicate(true)
	mislabeled.evaluation_policy = Evaluation.default_policy()
	check(not Records.validate_record(Records.seal(mislabeled)).ok, "historical evaluator cannot claim a later evidence policy")

func zero_survey(source: Dictionary) -> void:
	var started: Dictionary = StepEngine.init_run(source.launch_config, source.scenario_snapshot, "ke2_hpc_zero_survey", "ke2_hpc_zero_survey")
	check(started.ok, "native zero-progress Survey initialization")
	if not started.ok:
		return
	var state: Dictionary = started.state
	while state.phase == "operating":
		var advanced: Dictionary = StepEngine.request_action(state, "power_save")
		if not advanced.ok or not advanced.allowed:
			check(false, "native zero-progress step")
			return
		state = advanced.state
	var reply: Dictionary = Evaluation.evaluate_mission(source.launch_config, state, state.event_log)
	check(reply.ok and reply.report.status == "failed" and reply.report.score == 0, "genuine empty delivery map measures zero")
	if reply.ok:
		for row: Dictionary in goal(reply.report, "selected_targets_delivered").by_target:
			check(row.actual == 0 and row.returned_data_mb == 0.0 and row.met == false, "native absent delivery and MB keys measure zero")
	state.erase("returned_data_by_target_mb")
	reply = Evaluation.evaluate_mission(source.launch_config, state, state.event_log)
	check(reply.ok and goal(reply.report, "selected_targets_delivered").by_target[0].returned_data_mb == null, "missing whole target MB map stays unavailable")
