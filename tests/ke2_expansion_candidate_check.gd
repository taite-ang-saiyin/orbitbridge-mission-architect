extends SceneTree
## Candidate rules only. Communication/Weather typed records are proxy fixtures.
const Evaluation = preload("res://scripts/evaluation/mission_expansion_candidate.gd")
const Records = preload("res://scripts/evaluation/mission_expansion_records.gd")
const Compare = preload("res://scripts/evaluation/mission_expansion_comparison.gd")
const Active = preload("res://scripts/evaluation/mission_evaluator.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const EngineSteps = preload("res://core/MissionStepEngine.gd")
var passed: int = 0
var failed: int = 0
var natives: Dictionary = {}
var examples: Dictionary = {}

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1; printerr("FAIL " + label)

func evaluate(item: Dictionary, policy: Dictionary = {}) -> Dictionary:
	return Evaluation.evaluate_with_policy(item.config, item.state, item.state.event_log, Evaluation.default_policy() if policy.is_empty() else policy)

func goal(reply: Dictionary, id: String) -> Dictionary:
	for row: Dictionary in reply.get("report", {}).get("goal_progress", []):
		if row.id == id: return row
	return {}

func typed(item: Dictionary, objective: String, preset: String = "") -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	result.config.schema_version = 2
	result.config.contract_revision = Evaluation.INPUT_REVISION
	result.config.preset_id = preset if not preset.is_empty() else {"survey": "polar_ice_survey", "communication": "communication", "weather_monitoring": "weather_monitoring", "imaging": "estuary_watch"}[objective]
	result.config.preset_revision = 2 if objective == "communication" else 1
	result.config.mission.objective = objective
	result.config.mission.goal = {"imaging": {"kind": "imaging"}, "survey": {"kind": "survey_delivery", "minimum_complete_observations_per_target": 1},
		"communication": {"kind": "communication_contacts", "required_positive_contact_steps": 2}, "weather_monitoring": {"kind": "weather_revisit", "required_distinct_orbits": 2}}[objective]
	result.state.config_snapshot = result.config.duplicate(true)
	result.initial.config_snapshot = result.config.duplicate(true)
	result.scope = "typed_proxy_fixture"
	return result

func replay(name: String, source: Dictionary, catalogs: Dictionary, abort_at: int = -1) -> Dictionary:
	var config: Dictionary = source.trace.config.duplicate(true)
	var begun: Dictionary = EngineSteps.init_validated_run(config, catalogs, "candidate_" + name, "ke2_candidate")
	check(begun.ok, "native validator/adapter init " + name)
	if not begun.ok: printerr(begun); return {}
	var initial: Dictionary = begun.state.duplicate(true)
	var state: Dictionary = begun.state
	var samples: Array = [sample(state)]
	for request: Dictionary in source.requested_actions:
		if abort_at >= 0 and state.step_index >= abort_at: break
		check(state.step_index == request.step_index, "native replay request position " + name)
		var response: Dictionary = EngineSteps.request_action(state, request.action)
		if not response.ok: check(false, "native request " + name); return {}
		state = response.state
		if response.allowed: samples.append(sample(state))
	if abort_at >= 0: state = EngineSteps.abort_run(state, "Candidate abort after goal progress").state
	return {"config": config, "state": state, "initial": initial, "samples": samples, "validation": begun.validation_result, "scope": "native_modules"}

func sample(state: Dictionary) -> Dictionary:
	return {"step_index": state.step_index, "energy_wh": state.energy_wh, "stored_data_mb": state.stored_data_mb}

func context(item: Dictionary) -> Dictionary:
	var requests: Array = []
	for event: Dictionary in item.state.event_log:
		if event.type in ["action_accepted", "action_blocked"]: requests.append({"step_index": event.step_index, "action": event.action})
	return {"initial_state": item.initial.duplicate(true), "catalogs_snapshot": item.state.scenario_snapshot.duplicate(true),
		"source_versions": {"engine": FileAccess.get_sha256("res://core/MissionStepEngine.gd"), "adapter": FileAccess.get_sha256("res://core/HPCContractAdapter.gd"),
			"catalogs": JSON.stringify(item.state.scenario_snapshot, "", true, true).sha256_text(), "scenario": item.state.scenario_snapshot.scenario_version,
			"evaluator": Evaluation.EVALUATOR_REVISION, "report": Evaluation.REPORT_REVISION},
		"initialization_policy": "full_battery_empty_v1_proposal", "legacy_identity_policy": "exact_requirements_v1_proposal",
		"verification_scope": item.scope, "source_credits": {}, "display_context": {"notice": "Candidate scoring and evidence policies; not production acceptance"},
		"operations": {"policy": {"id": "recorded_manual_plan", "version": 1, "parameters": {}}, "manual_requests": requests.duplicate(true), "requested_actions": requests},
		"resource_samples": item.samples.duplicate(true), "resource_sampling_id": Records.SAMPLING}

func record(item: Dictionary, policy: Dictionary = {}) -> Dictionary:
	return Records.build_record(item.config, item.state, item.state.event_log, item.validation, context(item), policy)

func measure(reply: Dictionary, id: String) -> Dictionary:
	for row: Dictionary in reply.get("comparison", {}).get("measures", []):
		if row.id == id: return row
	return {}

func _initialize() -> void:
	create_timer(45).timeout.connect(func(): printerr("FAIL candidate timeout"); quit(1))
	var loaded: Dictionary = Runtime.load_game_catalogs()
	check(loaded.ok, "actual catalogs")
	if not loaded.ok: quit(1); return
	var packet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/expansion-plan/evidence/ke2-handoff-current.json"))
	for name: String in packet.cases:
		var item: Dictionary = replay(name, packet.cases[name], loaded.catalogs)
		if item.is_empty(): quit(1); return
		natives[name] = item
		check(is_equal_approx(item.state.returned_data_mb, packet.cases[name].measured.returned_data_mb), "fresh native MB reproduce " + name)
		check(Compare.Existing._same(item.state.observations_delivered_by_target, packet.cases[name].measured.observations_delivered_by_target), "fresh native delivery map " + name)
	var sparse: Dictionary = Evaluation.default_policy()
	sparse.survey_missing_targets = "zero_in_present_map"
	for name: String in natives:
		var item: Dictionary = natives[name]
		if name.begins_with("communication"): item = typed(item, "communication")
		if name.begins_with("weather"): item = typed(item, "weather_monitoring")
		var before: Dictionary = item.duplicate(true)
		var reply: Dictionary = evaluate(item, sparse)
		check(reply.ok, "all candidate reports " + name)
		if not reply.ok: printerr(reply); quit(1); return
		check(reply.report.size() == 19 and reply.report.schema_version == 2, "19-field report " + name)
		for field: String in Active.REPORT_FIELDS: check(reply.report.has(field), "preserved field " + field)
		check(evaluate(item, sparse) == reply and before == item, "deterministic/input preserving " + name)
		var expected: int = 83 if name == "survey_shortfall" else 75 if "shortfall" in name else 81 if name == "imaging_a" else 100
		check(reply.report.score == expected, "proposed score " + name + " actual=" + str(reply.report.score))
		for row: Dictionary in reply.report.goal_progress:
			for id: String in row.evidence_event_ids:
				check(item.state.event_log.any(func(e): return e.event_id == id), "same execution goal evidence")
		var built: Dictionary = record(item, sparse)
		check(built.ok, "frozen record " + name)
		if not built.ok: printerr(built); quit(1); return
		examples[name] = built.record
		check(Records.validate_record(JSON.parse_string(JSON.stringify(built.record, "", true, true))).ok, "JSON transport preserves typed keys " + name)
		check(Compare.compare_runs(built.record, built.record).comparison.eligible, "all-objective callable comparison " + name)
	survey(sparse)
	validation_checks()
	aborts(packet, loaded.catalogs)
	comparisons(sparse)
	additional_boundaries(packet, loaded.catalogs)
	communication_control(packet, loaded.catalogs)
	expanded_pairs()
	DirAccess.make_dir_recursive_absolute("res://exports/check-evidence/ke2-expansion-candidate")
	var file: FileAccess = FileAccess.open("res://exports/check-evidence/ke2-expansion-candidate/records.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"proposal": true, "native_config_v2_acceptance": false, "records": examples}, "\t", true, true)); file.close()
	print("KE2 EXPANSION CANDIDATE: %d passed; %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func survey(policy: Dictionary) -> void:
	var missing: Dictionary = evaluate(natives.survey_shortfall)
	check(not missing.ok and "observations_delivered_by_target" in missing.error.field_path, "default sparse evidence unavailable")
	var reply: Dictionary = evaluate(natives.survey_shortfall, policy)
	check(goal(reply, "selected_targets_delivered").actual == 1 and goal(reply, "selected_targets_delivered").by_target.size() == 2, "partial packet not complete, target detail retained")
	check(reply.report.goal_progress.map(func(row): return row.id) == ["captures", "selected_targets_delivered", "returned_data"], "Survey rows match reviewed example order")
	var item: Dictionary = natives.survey_shortfall.duplicate(true)
	item.state.erase("observations_delivered_by_target")
	check(not evaluate(item, policy).ok, "missing whole map never inferred zero")
	item = typed(natives.survey_complete, "survey")
	check(evaluate(item).report.score == 100, "v2 Survey complete")
	for objective in ["imaging", "survey", "communication", "weather_monitoring"]:
		var source: Dictionary = natives.survey_complete if objective == "survey" else natives.weather_candidate_complete if objective == "weather_monitoring" else natives.communication_candidate_complete
		item = typed(source, objective)
		check(evaluate(item, policy).ok, "typed objective " + objective)
	item = typed(natives.imaging_b, "imaging", "tropical_forest_watch")
	check(evaluate(item).ok, "second Imaging preset identity")
	item = typed(natives.weather_candidate_complete, "weather_monitoring")
	var recorded: Dictionary = Evaluation.default_policy(); recorded.weather_mapping = "recorded_orbit_index"
	check(not evaluate(item, recorded).ok, "recorded revolution policy requires event field")
	for event: Dictionary in item.state.event_log:
		if event.type == "action_accepted" and event.action == "observe": event.orbit_index = int(event.step_index) / 10
	check(evaluate(item, recorded).report.score == 100, "explicit recorded revolution policy")
	item = typed(natives.communication_candidate_complete, "communication")
	item.config.mission.required_observations = 20; item.state.config_snapshot = item.config.duplicate(true)
	check(evaluate(item).report.score == 100, "Communication capture quota diagnostic not score term")
	item = natives.imaging_b.duplicate(true)
	item.config.mission.required_observations = 8; item.config.mission.required_returned_data_mb = 1000.0; item.state.config_snapshot = item.config.duplicate(true)
	check(evaluate(item).report.score == 7, "half-up after average once (6.85)")
	item.config.mission.required_returned_data_mb = 24.0; item.state.config_snapshot = item.config.duplicate(true)
	check(evaluate(item).report.score == 31, "fractional capped terms preserve precision")
	check(Evaluation._ratio(12.0, 4.0) == 1.0, "over-target ratio capped")
	item.config.mission.required_observations = 2; item.config.mission.required_returned_data_mb = 16.0; item.state.config_snapshot = item.config.duplicate(true)
	check(evaluate(item).report.score == 63, "exact 62.5 rounds half up once")

func validation_checks() -> void:
	for value in [0, -1, NAN, INF, true, "12", null]:
		var item: Dictionary = natives.imaging_b.duplicate(true)
		item.config.mission.required_returned_data_mb = value; item.state.config_snapshot = item.config.duplicate(true)
		check(not evaluate(item).ok, "invalid MB goal " + str(value))
	for path in ["root", "goal", "state_version", "counter", "snapshot", "nonterminal", "events", "foreign", "unknown_action", "duplicate_conflict"]:
		var item: Dictionary = typed(natives.communication_candidate_complete, "communication")
		match path:
			"root": item.config.unconfirmed = 1
			"goal": item.config.mission.goal.required_positive_contact_steps = 0
			"state_version": item.state.schema_version = 2
			"counter": item.state.returned_data_mb += 1
			"snapshot": item.state.config_snapshot = {}
			"nonterminal": item.state.phase = "operating"
			"events": item.state.event_log.remove_at(0)
			"foreign": item.state.event_log[0].run_id = "other"
			"unknown_action": item.state.event_log[0].action = "invented"
			"duplicate_conflict":
				var event: Dictionary = item.state.event_log[-1].duplicate(true); event.action = "observe"; item.state.event_log.append(event)
		if not path in ["snapshot"]: item.state.config_snapshot = item.config.duplicate(true)
		var reply: Dictionary = evaluate(item)
		check(not reply.ok and reply.error.size() == 5, "structured invalid " + path)
	var item: Dictionary = natives.imaging_b.duplicate(true)
	item.state.event_log.append(item.state.event_log[-1].duplicate(true))
	check(evaluate(item).ok, "exact duplicate evidence idempotent")
	item = typed(natives.communication_candidate_complete, "communication")
	check(not Active.evaluate_mission(item.config, item.state, item.state.event_log).ok, "active evaluator remains v1 gated")

func aborts(packet: Dictionary, catalogs: Dictionary) -> void:
	var item: Dictionary = replay("abort_after_goals", packet.cases.communication_candidate_complete, catalogs, 20)
	item = typed(item, "communication")
	var reply: Dictionary = evaluate(item)
	check(reply.ok and reply.report.run_status == "aborted" and reply.report.status == "failed" and reply.report.score == null, "native abort retained with null score")
	check(goal(reply, "positive_transmit_steps").met and reply.report.returned_data_mb == 24.0, "abort after both goals preserves raw actuals")
	check("Candidate abort" in reply.report.explanation, "recorded abort reason")
	var built: Dictionary = record(item)
	check(built.ok and not Compare.compare_runs(built.record, built.record).comparison.eligible, "aborted record retained but ineligible A/B")
	item = replay("abort_early", packet.cases.survey_complete, catalogs, 0)
	item.state.erase("observations_delivered_by_target")
	reply = evaluate(item)
	check(reply.ok and goal(reply, "selected_targets_delivered").actual == null, "aborted missing delivery unavailable not fabricated zero")
	item.state.observations_delivered_by_target = {"arctic_ice": -1}
	check(not evaluate(item).ok, "abort malformed delivery still rejected")

func comparisons(policy: Dictionary) -> void:
	var a: Dictionary = examples.imaging_a
	var b: Dictionary = examples.imaging_b
	var before: Array = [a, b].duplicate(true)
	var reply: Dictionary = Compare.compare_runs(a, b)
	check(reply.ok and reply.comparison.eligible and reply.comparison.proposal, "native expanded report comparison")
	check(is_equal_approx(measure(reply, "returned_data_mb").delta_b_minus_a, 4.6133333328), "signed native MB delta")
	check(measure(reply, "score").delta_b_minus_a == 19 and measure(reply, "total_mass_g").delta_b_minus_a == 60 and measure(reply, "total_cost_credits").delta_b_minus_a == 7, "score/mass/cost deltas")
	check(measure(reply, "lowest_battery_wh").available and measure(reply, "lowest_battery_percent").delta_unit == "percentage_points", "explicit sampled extrema and delta units")
	check(reply.comparison.classification == "Design", "same requested manual plan Design")
	check(Compare.compare_runs(a, b) == reply and [a, b] == before, "comparison deterministic and records unchanged")
	check(is_equal_approx(measure(Compare.compare_runs(b, a), "returned_data_mb").delta_b_minus_a, -4.6133333328), "reverse comparison delta")
	var changed: Dictionary = b.duplicate(true); changed.report.score = 42
	check(not Records.validate_record(changed).ok, "digest catches mutation")
	check(not Records.validate_record(Records.seal(changed)).ok, "re-evaluation catches resealed false report")
	changed = b.duplicate(true); changed.execution_key = "invented"
	check(not Records.validate_record(Records.seal(changed)).ok, "original execution key required")
	changed = b.duplicate(true); changed.context.initial_state.energy_wh = 0
	check(not Records.validate_record(Records.seal(changed)).ok, "initial conditions bound")
	changed = b.duplicate(true); changed.context.source_versions.erase("engine")
	check(not Records.validate_record(Records.seal(changed)).ok, "unknown producer revision rejected")
	changed = b.duplicate(true); changed.context.resource_sampling_id = "unknown"
	reply = Compare.compare_runs(a, Records.seal(changed))
	check(reply.comparison.eligible and not measure(reply, "lowest_battery_wh").available, "unknown sampling unavailable")
	changed = b.duplicate(true); changed.context.resource_samples[0].energy_wh = 0
	check(not measure(Compare.compare_runs(a, Records.seal(changed)), "lowest_battery_wh").available, "bad initial sample unavailable")
	changed = b.duplicate(true); changed.context.operations = null
	check(Compare.compare_runs(a, Records.seal(changed)).comparison.classification == null, "missing operations unclassified")
	changed = b.duplicate(true); changed.context.operations.manual_requests = []
	check(Compare.compare_runs(a, Records.seal(changed)).comparison.classification == "Design + operations", "different manual context combined")
	var other: Dictionary = natives.imaging_b.duplicate(true)
	other.config.mission.required_returned_data_mb = 13.0; other.state.config_snapshot = other.config.duplicate(true); other.initial.config_snapshot = other.config.duplicate(true)
	var built: Dictionary = record(other, policy)
	check(built.ok and not Compare.compare_runs(a, built.record).comparison.eligible, "different requirements unavailable")
	changed = b.duplicate(true); changed.context.source_versions.engine = "another-engine"
	check(not Compare.compare_runs(a, Records.seal(changed)).comparison.eligible, "producer version mismatch unavailable")
	changed = b.duplicate(true); changed.context.operations.requested_actions[0].action = "observe"
	check(not Records.validate_record(Records.seal(changed)).ok, "operations must match recorded requests")
	var transported: Dictionary = JSON.parse_string(JSON.stringify(b, "", true, true))
	var restored: Dictionary = Records.validate_record(transported)
	check(restored.ok and restored.record.execution_key == b.execution_key and restored.record.key_preimage_utf8 == b.key_preimage_utf8, "transport restores original typed key bytes")
	changed = b.duplicate(true); changed.context.resource_samples[2].stored_data_mb = 25.0
	check(not measure(Compare.compare_runs(a, Records.seal(changed)), "highest_storage_mb").available, "intermediate sample must match accepted evidence")

func additional_boundaries(packet: Dictionary, catalogs: Dictionary) -> void:
	var empty_source: Dictionary = packet.cases.communication_candidate_complete.duplicate(true)
	for request: Dictionary in empty_source.requested_actions: request.action = "power_save"
	var zero: Dictionary = replay("zero", empty_source, catalogs)
	zero = typed(zero, "communication")
	var reply: Dictionary = evaluate(zero)
	check(reply.ok and reply.report.status == "failed" and reply.report.score == 0, "zero goals failed/zero score")
	var capture_source: Dictionary = packet.cases.communication_candidate_complete.duplicate(true)
	for request: Dictionary in capture_source.requested_actions:
		if request.action == "transmit": request.action = "power_save"
	var only_captures: Dictionary = typed(replay("captures_only", capture_source, catalogs), "communication")
	reply = evaluate(only_captures)
	check(reply.report.observations_completed == 2 and reply.report.status == "failed" and reply.report.score == 0, "captures alone not Communication goal progress")
	var same: Dictionary = natives.communication_candidate_complete.duplicate(true)
	var original: Dictionary = same.duplicate(true)
	var expected: Dictionary = evaluate(typed(same, "communication"))
	check(expected.report.status == "success" and expected.report.returned_data_mb == 24.0 and goal(expected, "returned_data").completion_ratio == 1.0, "over-target MB raw retained/capped score")
	check(same == original, "typed fixture producer preserves native inputs")
	for fault in ["capture_map", "return_map", "delivery_count", "targets", "duration", "preset", "goal_unknown", "config_revision", "partial_event_history"]:
		var item: Dictionary = typed(natives.survey_complete, "survey")
		match fault:
			"capture_map": item.state.observations_by_target.arctic_ice = 99
			"return_map": item.state.returned_data_by_target_mb.arctic_ice = 99.0
			"delivery_count": item.state.observations_delivered_by_target.arctic_ice = 2
			"targets": item.config.mission.target_regions.append("equator")
			"duration": item.config.mission.duration_orbits = 0
			"preset": item.config.preset_id = "unconfirmed_custom"
			"goal_unknown": item.config.mission.goal.proposal = 1
			"config_revision": item.config.contract_revision = "unconfirmed"
			"partial_event_history":
				check(not Evaluation.evaluate_mission(item.config, item.state, item.state.event_log.slice(1)).ok, "history argument must match frozen full log")
				continue
		item.state.config_snapshot = item.config.duplicate(true)
		check(not evaluate(item).ok, "invalid " + fault)
	var weather: Dictionary = typed(natives.weather_candidate_complete, "weather_monitoring")
	weather.config.mission.goal.required_distinct_orbits = 4; weather.state.config_snapshot = weather.config.duplicate(true)
	check(not evaluate(weather).ok, "Weather goal cannot exceed duration/capture quota")
	var neutral: Dictionary = evaluate(typed(natives.communication_candidate_shortfall, "communication"))
	check(neutral.report.root_causes.is_empty() and not neutral.report.next_experiment.is_empty(), "count shortfall neutral with one experiment")
	var legacy: Dictionary = evaluate(natives.imaging_b)
	check(legacy.report.score == Active.evaluate_mission(natives.imaging_b.config, natives.imaging_b.state, natives.imaging_b.state.event_log).report.score, "candidate Imaging score agrees with active evaluator")

func communication_control(packet: Dictionary, catalogs: Dictionary) -> void:
	# Same frozen quota and goal, two sends in one continuous native contact.
	# Only requested captures differ. Neither config-v2 fixture is sent to HPC.
	var pair: Array = []
	for capture_twice in [true, false]:
		var source: Dictionary = packet.cases.communication_candidate_complete.duplicate(true)
		source.trace.config.design.orbit_id = "high_inc"
		source.requested_actions = []
		for step in 30:
			var action: String = "observe" if step == 1 or (step == 6 and capture_twice) else "transmit" if step in [7, 10] else "power_save"
			source.requested_actions.append({"step_index": step, "action": action})
			if step == 10 and not capture_twice: source.requested_actions.append({"step_index": step, "action": "power_save"})
		var item: Dictionary = typed(replay("same_contact_" + str(capture_twice), source, catalogs), "communication")
		var reply: Dictionary = evaluate(item)
		check(reply.ok and reply.report.score == (100 if capture_twice else 75), "same quota/native contact score " + str(capture_twice))
		check(reply.report.returned_data_mb == (24.0 if capture_twice else 12.0), "same contact raw Earth MB " + str(capture_twice))
		check(goal(reply, "positive_transmit_steps").actual == (2 if capture_twice else 1), "same contact distinct accepted steps " + str(capture_twice))
		var built: Dictionary = record(item)
		check(built.ok, "same contact record " + str(capture_twice))
		if not built.ok: printerr(built); continue
		examples["communication_same_contact_" + ("complete" if capture_twice else "shortfall")] = built.record
		pair.append(built.record)
	if pair.size() == 2:
		check(pair[0].config_snapshot == pair[1].config_snapshot, "Communication shortfall control leaves goal and capture quota unchanged")
		var comparison: Dictionary = Compare.compare_runs(pair[1], pair[0])
		check(comparison.comparison.eligible and comparison.comparison.classification == "Design + operations", "same contact controlled pair callable with changed manual requests")

func expanded_pairs() -> void:
	for objective in ["survey", "communication_candidate", "weather_candidate"]:
		var a: Dictionary = examples[objective + "_shortfall"]
		var b: Dictionary = examples[objective + "_complete"]
		var reply: Dictionary = Compare.compare_runs(a, b)
		check(reply.ok and reply.comparison.eligible, "expanded pair " + objective)
		var id: String = {"survey": "selected_targets_delivered", "communication_candidate": "positive_transmit_steps", "weather_candidate": "selected_target_revolution_visits"}[objective]
		var row: Dictionary = reply.comparison.goal_measures.filter(func(g): return g.id == id)[0]
		check(row.delta_b_minus_a == 1, "expanded qualifying count delta " + objective)
		check(measure(reply, "score").delta_b_minus_a == (17 if objective == "survey" else 25), "expanded proposed score delta " + objective)
		check(reply.comparison.classification == "Design + operations", "different requested plan classified " + objective)
	var changed: Dictionary = examples.imaging_b.duplicate(true)
	changed.validation_snapshot.ready_to_launch = false
	check(not Records.validate_record(Records.seal(changed)).ok, "missing original ready snapshot rejected")
	changed = examples.imaging_b.duplicate(true)
	changed.context.catalogs_snapshot.orbits[0].steps_per_orbit += 1
	check(not Records.validate_record(Records.seal(changed)).ok, "retained catalog/scenario mismatch rejected")
