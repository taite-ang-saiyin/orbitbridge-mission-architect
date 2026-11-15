extends SceneTree
## KE2 algorithms under pending integration contracts; fixtures are explicitly labeled.
const Goals = preload("res://scripts/evaluation/mission_goal_evidence.gd")
const Comparison = preload("res://scripts/evaluation/mission_comparison.gd")
const GoalFeedback = preload("res://scripts/evaluation/mission_goal_feedback.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	communication()
	weather()
	eligibility()
	deltas()
	boundaries()
	feedback()
	ledger()
	print("KE2 INDEPENDENT WORK: %d passed; %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL " + label)

func context() -> Dictionary:
	return {"run_id": "fixture_run", "mission_id": "fixture_mission", "step_index": 30, "total_steps": 30}

func event(id: String, step: int, action: String, amount: float = 0.0) -> Dictionary:
	return {"event_id": id, "step_index": step, "type": "action_accepted", "action": action,
		"run_id": "fixture_run", "mission_id": "fixture_mission", "delta_returned_data_mb": amount}

func communication() -> void:
	var state: Dictionary = context()
	var blocked: Dictionary = event("blocked", 7, "transmit", 100)
	blocked.type = "action_blocked"
	var events: Array = [event("zero", 6, "transmit"), event("positive_a", 7, "transmit", 4), blocked,
		event("same_step", 7, "transmit", 4), event("positive_b", 8, "transmit", 8)]
	events.append(events[1].duplicate(true))
	var before: Array = events.duplicate(true)
	var measured: Dictionary = Goals._communication(state, events)
	check(measured.ok and measured.measure.positive_transmit_steps == 2 and measured.measure.step_indices == [7, 8], "communication distinct steps in one continuous contact, duplicates/zero/rejected excluded")
	check(measured.measure.evidence_event_ids == ["positive_a", "positive_b"], "communication stable supporting IDs")
	check(Goals._communication(state, events) == measured and events == before and state == context(), "communication deterministic and input preserving")
	check(Goals._communication(state, []).measure.positive_transmit_steps == 0, "communication explicit empty event list")
	var float_step: Dictionary = event("float_step", 7, "transmit", 4)
	float_step.step_index = 7.0
	check(Goals._communication(state, [event("int_step", 7, "transmit", 4), float_step]).measure.positive_transmit_steps == 1, "communication whole int/float steps identify one step")
	for value in [-1, NAN, INF, true, "1", null]:
		var invalid: Array = [event("bad", 7, "transmit", 1)]
		invalid[0].delta_returned_data_mb = value
		check(not Goals._communication(state, invalid).ok, "communication rejects invalid MB " + str(value))
	for field in ["event_id", "step_index", "delta_returned_data_mb"]:
		var invalid: Dictionary = event("bad", 7, "transmit", 1)
		invalid.erase(field)
		check(not Goals._communication(state, [invalid]).ok, "communication missing " + field)
	var foreign: Dictionary = event("foreign", 7, "transmit", 1)
	foreign.run_id = "other"
	check(not Goals._communication(state, [foreign]).ok, "communication foreign-run evidence")
	var conflict: Dictionary = events[1].duplicate(true)
	conflict.delta_returned_data_mb = 9
	check(not Goals._communication(state, [events[1], conflict]).ok, "communication conflicting ID rejected")
	check(not Goals._communication(state, [event("late", 8, "transmit", 1), event("early", 7, "transmit", 1)]).ok, "communication unordered events rejected")
	var packet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/expansion-plan/evidence/ke2-handoff-current.json"))
	for name: String in packet.cases:
		var item: Dictionary = packet.cases[name]
		var actual: Dictionary = Goals._communication(item.trace.final_state, item.trace.events)
		check(actual.ok and actual.measure.positive_transmit_steps == item.measured.positive_transmit_steps, "historical native contact count " + name)

func capture(id: String, step: int, target: String) -> Dictionary:
	var value: Dictionary = event(id, step, "observe")
	value.target_id = target
	value.delta_observations = 1
	return value

func weather() -> void:
	var config: Dictionary = {"mission": {"target_region": "equator", "target_regions": ["equator"]}, "design": {"orbit_id": "high_inc"}}
	var state: Dictionary = context()
	state.config_snapshot = config.duplicate(true)
	state.scenario_snapshot = {"orbits": [{"id": "high_inc", "steps_per_orbit": 10}]}
	var events: Array = [capture("a", 2, "equator"), capture("b", 5, "equator"), capture("other", 12, "arctic_ice"), capture("c", 19, "equator")]
	var before: Array = events.duplicate(true)
	var measured: Dictionary = Goals._weather(config, state, events)
	check(measured.ok and measured.measure.revolution_indices == [0, 1] and measured.measure.selected_target_revolution_visits == 2, "weather deduplicates same revolution and excludes other region")
	check(measured.measure.mapping_status == "pre_action_floor_hpc_confirmed_345e5bd", "weather mapping records HPC confirmation")
	check(Goals._weather(config, state, events) == measured and events == before, "weather repeatability/input preservation")
	check(Goals._weather(config, state, [capture("before", 9, "equator"), capture("boundary", 10, "equator")]).measure.revolution_indices == [0, 1], "weather pre-action revolution boundary")
	state.scenario_snapshot.orbits[0].steps_per_orbit = 3
	check(Goals._weather(config, state, [capture("before", 2, "equator"), capture("boundary", 3, "equator")]).measure.revolution_indices == [0, 1], "weather frozen timing rather than hard-coded ten")
	state.scenario_snapshot.orbits[0].steps_per_orbit = 10
	check(Goals._weather(config, state, []).measure.selected_target_revolution_visits == 0, "weather empty evidence explicit zero")
	for field in ["target_id", "delta_observations"]:
		var invalid: Dictionary = capture("missing", 2, "equator")
		invalid.erase(field)
		check(not Goals._weather(config, state, [invalid]).ok, "weather missing " + field)
	var wrong_index: Dictionary = capture("index", 10, "equator")
	wrong_index.orbit_index = 0
	check(not Goals._weather(config, state, [wrong_index]).ok, "weather conflicting explicit revolution")
	for value in [0, -1, 0.5, true, null]:
		var invalid: Dictionary = state.duplicate(true)
		invalid.scenario_snapshot.orbits[0].steps_per_orbit = value
		check(not Goals._weather(config, invalid, events).ok, "weather invalid timing " + str(value))
	var unavailable: Dictionary = state.duplicate(true)
	unavailable.erase("scenario_snapshot")
	check(not Goals._weather(config, unavailable, events).ok, "weather missing mapping cannot establish zero visits")
	var packet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/expansion-plan/evidence/ke2-handoff-current.json"))
	for name in ["weather_candidate_complete", "weather_candidate_shortfall"]:
		var item: Dictionary = packet.cases[name]
		var actual: Dictionary = Goals._weather(item.trace.config, item.trace.final_state, item.trace.events)
		check(actual.ok and actual.measure.selected_target_revolution_visits == item.measured.selected_target_revolution_visits, "historical native weather proxy " + name)

func record_for(name: String) -> Dictionary:
	# Explicit proposed normalization of historical native evidence, not SE Save A.
	var packet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/expansion-plan/evidence/ke2-handoff-current.json"))
	var bindings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/expansion-plan/evidence/execution-key-preimages-review.json"))
	var item: Dictionary = packet.cases[name]
	return {"config": item.trace.config.duplicate(true), "final_state": item.trace.final_state.duplicate(true),
		"events": item.trace.events.duplicate(true), "validation": item.trace.validation.duplicate(true), "report": item.evaluation.report.duplicate(true),
		"report_digest": JSON.stringify(item.evaluation.report, "", true, true).sha256_text(),
		"execution_key": item.execution_key, "key_preimage_utf8": bindings.cases[name].preimage_utf8,
		"initial_state": {"energy_wh": item.resource_samples[0].energy_wh, "stored_data_mb": 0, "returned_data_mb": 0, "observations_completed": 0},
		"context": {"catalogs_fingerprint": JSON.stringify(item.trace.final_state.scenario_snapshot, "", true, true).sha256_text(),
			"report_contract_revision": "v1.0-agreed", "legacy_identity_policy": "legacy_exact_requirements_v1_proposal", "initialization_policy": "full_battery_empty_v1_proposal",
			"versions": {"engine": packet.source_sha256["core/MissionStepEngine.gd"], "adapter": packet.source_sha256["core/HPCContractAdapter.gd"],
				"catalogs": packet.source_sha256["data/components.json"], "scenario": packet.source_sha256["data/orbits.json"], "evaluator": packet.source_sha256["scripts/evaluation/mission_evaluator.gd"], "report": "1"}},
		"operations": {"policy": {"id": "observe_first_v1", "version": 1, "parameters": {}}, "manual_requests": [], "requested_actions": item.requested_actions.duplicate(true)},
		"resource_sampling_id": "initial_and_each_accepted_poststep_v1_proposal", "resource_samples": item.resource_samples.duplicate(true)}

func rebind(record: Dictionary) -> void:
	record.final_state.config_snapshot = record.config.duplicate(true)
	record.final_state.event_log = record.events.duplicate(true)
	record.key_preimage_utf8 = JSON.stringify([record.config, record.final_state, record.events, record.validation], "", true, true)
	record.execution_key = record.key_preimage_utf8.sha256_text()
	record.report_digest = JSON.stringify(record.report, "", true, true).sha256_text()

func eligibility() -> void:
	var a: Dictionary = record_for("imaging_a")
	var b: Dictionary = record_for("imaging_b")
	var before: Array = [a.duplicate(true), b.duplicate(true)]
	var result: Dictionary = Comparison._eligibility(a, b)
	check(result.eligible and result.classification == "Design" and result.proposal, "comparison historical normalized radio pair proposed eligible")
	check(Comparison._eligibility(a, b) == result and [a, b] == before, "eligibility deterministic/input preserving")
	var manual: Dictionary = b.duplicate(true)
	manual.operations.manual_requests = [{"step_index": 2, "action": "power_save"}]
	check(Comparison._eligibility(a, manual).classification == "Design + operations", "manual override changes classification")
	manual = b.duplicate(true)
	manual.operations.requested_actions = [{"step_index": 2, "action": "power_save"}]
	check(Comparison._eligibility(a, manual).classification == "Design", "hardware-dependent policy requests do not imply manual changes")
	for field in ["duration_orbits", "required_observations", "required_returned_data_mb", "budget_credits"]:
		var changed: Dictionary = b.duplicate(true)
		changed.config.mission[field] += 1
		if changed.report.has(field): changed.report[field] = changed.config.mission[field]
		rebind(changed)
		check(not Comparison._eligibility(a, changed).eligible, "comparison mismatched requirement " + field)
	for field in ["engine", "adapter", "catalogs", "scenario", "evaluator", "report"]:
		var changed: Dictionary = b.duplicate(true)
		changed.context.versions[field] = "changed"
		check(not Comparison._eligibility(a, changed).eligible, "comparison mismatched version " + field)
	var unknown: Dictionary = b.duplicate(true)
	unknown.context.versions.erase("engine")
	check(not Comparison._eligibility(a, unknown).eligible, "unknown versions never assumed matching")
	var changed: Dictionary = b.duplicate(true)
	changed.final_state.run_status = "aborted"
	check(not Comparison._eligibility(a, changed).eligible, "aborted attempts excluded")
	changed = b.duplicate(true)
	changed.final_state.phase = "operating"
	check(not Comparison._eligibility(a, changed).eligible, "unfinished attempts excluded")
	changed = b.duplicate(true)
	changed.execution_key = "wrong"
	check(not Comparison._eligibility(a, changed).eligible, "tampered execution key excluded")
	changed = b.duplicate(true)
	changed.report.returned_data_mb += 1
	check(not Comparison._eligibility(a, changed).eligible, "tampered report actual excluded")
	changed = b.duplicate(true)
	changed.initial_state.energy_wh -= 1
	check(not Comparison._eligibility(a, changed).eligible, "changed starting condition excluded")
	changed = b.duplicate(true)
	changed.final_state.scenario_snapshot.orbits[0].ground_contact_windows = []
	rebind(changed)
	check(not Comparison._eligibility(a, changed).eligible, "actual changed schedule excluded even with stale metadata")
	changed = b.duplicate(true)
	changed.operations.manual_requests = [{"step_index": -1, "action": "observe"}]
	check(not Comparison._eligibility(a, changed).eligible, "negative manual step excluded")
	changed = b.duplicate(true)
	changed.validation.ready_to_launch = false
	rebind(changed)
	check(not Comparison._eligibility(a, changed).eligible, "unapproved readiness cannot become eligible")

func row(result: Dictionary, id: String) -> Dictionary:
	for item: Dictionary in result.measures:
		if item.id == id: return item
	return {}

func deltas() -> void:
	var a: Dictionary = record_for("imaging_a")
	var b: Dictionary = record_for("imaging_b")
	var before: Array = [a.duplicate(true), b.duplicate(true)]
	var result: Dictionary = Comparison._deltas(a, b)
	check(result.eligible and result.outcomes == {"a": "partial", "b": "success"}, "comparison preserves supplied outcomes")
	if not result.get("eligible", false): return
	for item in [["returned_data_mb", 4.6133333328], ["total_mass_g", 60], ["total_cost_credits", 7], ["score", 19], ["lowest_battery_wh", -0.4616666667000011]]:
		check(absf(float(row(result, item[0]).delta_b_minus_a) - float(item[1])) < 1e-8, "measured historical B-minus-A " + item[0])
	check(result.changed_parts == [{"field": "radio_id", "a": "radio_basic", "b": "radio_fast"}], "comparison changed part identity")
	check(row(result, "lowest_battery_percent").delta_unit == "percentage_points", "battery percentage points differ from Wh")
	check(Comparison._deltas(a, b) == result and [a, b] == before, "deltas repeatable and input preserving")
	check(row(Comparison._deltas(a, a), "returned_data_mb").delta_b_minus_a == 0, "identical record zero delta")
	check(absf(float(row(Comparison._deltas(b, a), "returned_data_mb").delta_b_minus_a) + 4.6133333328) < 1e-8, "reversed pair negative delta")
	var missing: Dictionary = b.duplicate(true)
	missing.erase("resource_samples")
	var optional: Dictionary = Comparison._deltas(a, missing)
	check(optional.eligible and row(optional, "lowest_battery_wh").delta_b_minus_a == null and not row(optional, "lowest_battery_wh").available, "missing optional samples do not invent zero")
	missing = b.duplicate(true)
	missing.resource_sampling_id = "unknown"
	check(row(Comparison._deltas(a, missing), "highest_storage_mb").b == null, "unagreed sample boundary cannot yield extrema")
	missing = b.duplicate(true)
	missing.resource_samples.pop_front()
	check(row(Comparison._deltas(a, missing), "lowest_battery_wh").b == null, "initial sample required")
	missing = b.duplicate(true)
	missing.resource_samples.pop_back()
	check(row(Comparison._deltas(a, missing), "highest_storage_mb").b == null, "terminal sample required")
	missing = b.duplicate(true)
	missing.validation.metrics.erase("total_cost_credits")
	rebind(missing)
	check(row(Comparison._deltas(a, missing), "total_cost_credits").delta_b_minus_a == null, "missing cost remains unavailable")

func boundaries() -> void:
	var state: Dictionary = context()
	for step in [-1, 0.5, true, null, 30]:
		var invalid: Dictionary = event("boundary", 7, "transmit", 1)
		invalid.step_index = step
		check(not Goals._communication(state, [invalid]).ok, "invalid/future accepted step " + str(step))
	check(not Goals._communication(state, null).ok, "missing events unavailable")
	var invalid_state: Dictionary = state.duplicate(true)
	invalid_state.step_index = 0.5
	check(not Goals._communication(invalid_state, []).ok, "fractional current step invalid")
	check(Goals._communication(state, [event("tiny", 1, "transmit", 1e-12)]).measure.positive_transmit_steps == 1, "positive returned MB has no invented epsilon threshold")
	var a: Dictionary = record_for("imaging_a")
	var b: Dictionary = record_for("imaging_b")
	var partial: Array = a.events.duplicate(true)
	partial.pop_front()
	check(not Goals._communication(a.final_state, partial).ok, "partial cumulative history cannot silently undercount")
	var duplicated: Array = a.events.duplicate(true)
	duplicated.append(duplicated[2].duplicate(true))
	check(Goals._communication(a.final_state, duplicated).ok, "identical repeated entries match retained unique history")
	var changed: Dictionary = b.duplicate(true)
	changed.report.score = 99
	check(not Comparison._eligibility(a, changed).eligible, "report digest detects score-only mutation")
	changed = b.duplicate(true)
	changed.report.erase("source_ids")
	rebind(changed)
	check(not Comparison._eligibility(a, changed).eligible, "missing required report field invalid even after digest refresh")
	changed = b.duplicate(true)
	changed.config.mission.required_observations = 1.5
	changed.report.required_observations = 1.5
	rebind(changed)
	check(not Comparison._eligibility(a, changed).eligible, "fractional required capture count invalid")
	for version in [true, 0, 3, "1"]:
		changed = b.duplicate(true)
		changed.report.schema_version = version
		rebind(changed)
		check(not Comparison._eligibility(a, changed).eligible, "unsupported report version " + str(version))
	changed = b.duplicate(true)
	changed.report.root_causes = [{"evidence_event_ids": ["not_recorded"]}]
	rebind(changed)
	check(not Comparison._eligibility(a, changed).eligible, "invented cause reference blocks comparison")
	for value in [NAN, -1, "12"]:
		changed = b.duplicate(true)
		changed.resource_samples[1].energy_wh = value
		check(row(Comparison._deltas(a, changed), "lowest_battery_wh").b == null, "malformed resource value unavailable " + str(value))

func goal(id: String, actual: float, required: float) -> Dictionary:
	return {"id": id, "actual": actual, "required": required, "met": actual >= required}

func feedback() -> void:
	var state: Dictionary = context()
	state.observations_completed = 0
	state.returned_data_mb = 0.0
	state.config_snapshot = {"mission": {"target_region": "equator"}, "design": {"orbit_id": "high_inc"}}
	var blocked: Dictionary = event("blocked_contact", 7, "transmit")
	blocked.type = "action_blocked"
	blocked.code = "NO_LINK_WINDOW"
	var goals: Array = [goal("positive_transmit_steps", 0, 2)]
	var before: Array = [state.duplicate(true), blocked.duplicate(true), goals.duplicate(true)]
	var result: Dictionary = GoalFeedback._build(state, [blocked], goals)
	check(result.root_causes.size() == 1 and result.root_causes[0].evidence_event_ids == ["blocked_contact"], "feedback uses recorded missed-contact ID")
	check(not result.next_experiment.is_empty() and result.proposal, "feedback one corrective experiment, proposed output")
	check(GoalFeedback._build(state, [blocked], goals) == result and [state, blocked, goals] == before, "feedback deterministic/input preserving")
	var storage: Dictionary = event("blocked_storage", 3, "observe")
	storage.type = "action_blocked"
	storage.code = "STORAGE_FULL"
	check(GoalFeedback._build(state, [storage], [goal("captures", 0, 2)]).root_causes[0].code == "STORAGE_FULL", "feedback recorded storage limit")
	check(GoalFeedback._build(state, [blocked], [goal("captures", 0, 2)]).root_causes.is_empty(), "feedback irrelevant transmit cannot explain capture shortfall")
	check(GoalFeedback._build(state, [], goals).root_causes.is_empty(), "feedback absent evidence neutral")
	var unknown: Dictionary = blocked.duplicate(true)
	unknown.code = "UNKNOWN_CODE"
	check(GoalFeedback._build(state, [unknown], goals).root_causes.is_empty(), "feedback unknown rule neutral")
	unknown = blocked.duplicate(true)
	unknown.run_id = "foreign"
	check(GoalFeedback._build(state, [unknown], goals).root_causes.is_empty(), "feedback wrong execution neutral")
	unknown = blocked.duplicate(true)
	unknown.code = "LOW_BATTERY"
	check(GoalFeedback._build(state, [blocked, unknown], goals).root_causes.is_empty(), "feedback conflicting IDs neutral")
	check(GoalFeedback._build(state, [blocked], [goal("returned_data", 0, 0)]).root_causes.is_empty(), "feedback invalid goal neutral")
	check(GoalFeedback._build(state, [storage], [goal("captures", 1, 2)]).root_causes.is_empty(), "feedback contradictory supplied actual neutral")
	state.run_status = "aborted"
	state.terminal_reason = "Operator stopped the fixture"
	var aborted: Dictionary = GoalFeedback._build(state, [], goals)
	check(aborted.root_causes.is_empty() and aborted.explanation.contains(state.terminal_reason), "feedback preserves recorded abort reason")
	var packet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/expansion-plan/evidence/ke2-handoff-current.json"))
	var survey: Dictionary = packet.cases.survey_shortfall.trace
	var native: Dictionary = survey.final_state.duplicate(true)
	check(GoalFeedback._build(native, survey.events, [goal("selected_targets_delivered", 1, 2)]).explanation.contains("unavailable"), "feedback missing Survey target entry does not become zero")
	native.observations_delivered_by_target["antarctic_region"] = 0 # Explicit labeled fixture, not a native default.
	var delivered: Dictionary = GoalFeedback._build(native, survey.events, [goal("selected_targets_delivered", 1, 2)])
	check(delivered.root_causes.is_empty() and delivered.next_experiment.contains("transmitting"), "feedback explicit delivery shortfall has experiment without invented cause")
	var weather_trace: Dictionary = packet.cases.weather_candidate_shortfall.trace
	var repeated: Dictionary = GoalFeedback._build(weather_trace.final_state, weather_trace.events, [goal("selected_target_revolution_visits", 1, 2)])
	check(repeated.root_causes.is_empty() and repeated.explanation.contains("proposed") and repeated.next_experiment.contains("different revolution"), "feedback same-revolution suggestion stays conditional")

func ledger() -> void:
	# Integrity/presence audit only; does not newly verify NASA prose or exported use.
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/nasa_sources.json"))
	var ids: Array = []
	var unique: bool = true
	for entry: Dictionary in source.sources:
		unique = unique and entry.source_id is String and not entry.source_id in ids
		ids.append(entry.source_id)
	check(unique and not ids.is_empty(), "ledger unique documented source IDs")
	var sample: Dictionary = source.sources[0]
	check(FileAccess.file_exists(sample.local_reference) and FileAccess.get_sha256(sample.local_reference) == sample.local_reference_sha256, "ledger local PDF matches prior verified source hash")
	check(sample.locator.appendix.begins_with("C") and sample.locator.item == 6 and sample.locator.printed_page == 79, "ledger recorded Appendix C item 6 locator")
	check(sample.locator.pdf_page == 87 and sample.locator.pdf_page_index == 86, "ledger PDF page/index consistency")
	check(sample.criterion.converted.comparator == "<" and sample.criterion.converted.value == 1330 and sample.criterion.converted.unit == "g", "ledger strict converted mass boundary retained")
	check(sample.criterion.boundary_expectations.map(func(v): return v.mass_check_passed) == [true, false, false], "ledger recorded 1329/1330/1331 expectations retained")
	var present: bool = true
	for key in ["validator", "profile_catalog"]:
		var implementation: Dictionary = sample.implementation[key]
		present = present and implementation.path_present_in_checkout and FileAccess.file_exists(implementation.intended_path)
	check(present, "ledger stale scaffold path-presence metadata corrected")
	var packet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/expansion-plan/evidence/ke2-handoff-current.json"))
	var known: bool = true
	for item: Dictionary in packet.cases.values():
		for id in item.evaluation.get("report", {}).get("source_ids", []): known = known and id in ids
		known = known and item.trace.validation.checks.profile_mass.get("source_id") in ids
	check(known, "ledger historical report/readiness references resolve")
