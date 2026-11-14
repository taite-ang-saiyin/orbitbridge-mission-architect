extends SceneTree
## Reproducible handoff evidence against the current production modules.
## Proposed assessments are audit calculations and require owner agreement.
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const StepEngine = preload("res://core/MissionStepEngine.gd")
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
const Catalog = preload("res://data/mock/DesignCatalog.gd")
const OUTPUT = "res://docs/expansion-plan/evidence/ke2-handoff-current.json"
var failures: int = 0


func _initialize() -> void:
	call_deferred("probe")


func probe() -> void:
	var loaded: Dictionary = Runtime.load_game_catalogs()
	check(loaded.ok, "Effective production catalogs load")
	if not loaded.ok:
		quit(1)
		return
	var cases: Dictionary = {}
	var survey: Dictionary = draft_for("Survey Target Regions", ["Arctic Ice", "Antarctic Region"], "Polar – 600 km")
	cases.survey_shortfall = run_case(survey, "survey_shortfall", loaded.catalogs, [0, 7], [10, 17])
	cases.survey_complete = run_case(survey, "survey_complete", loaded.catalogs, [0, 7], [10, 17, 20, 27])
	var communication: Dictionary = draft_for("Capture Imagery", ["Equator"], "LEO – 400 km")
	communication.engineering_parts = {"radio": "radio_fast"}
	cases.communication_candidate_shortfall = run_case(communication, "communication_candidate_shortfall", loaded.catalogs, [2, 5], [8])
	cases.communication_candidate_complete = run_case(communication, "communication_candidate_complete", loaded.catalogs, [2, 5], [8, 18])
	var weather: Dictionary = draft_for("Capture Imagery", ["Equator"], "LEO – 400 km")
	cases.weather_candidate_shortfall = run_case(weather, "weather_candidate_shortfall", loaded.catalogs, [2, 5], [8, 18, 28])
	cases.weather_candidate_complete = run_case(weather, "weather_candidate_complete", loaded.catalogs, [2, 12], [8, 18, 28])
	var imaging: Dictionary = draft_for("Capture Imagery", ["Equator"], "LEO – 400 km")
	imaging.observations = 1
	imaging.duration = 1
	cases.imaging_a = run_case(imaging, "imaging_a", loaded.catalogs)
	imaging.engineering_parts = {"radio": "radio_fast"}
	cases.imaging_b = run_case(imaging, "imaging_b", loaded.catalogs)
	if failures > 0:
		quit(1)
		return
	for objective: String in ["survey", "communication", "weather"]:
		for suffix: String in ["shortfall", "complete"]:
			var case_id: String = objective + ("_" if objective == "survey" else "_candidate_") + suffix
			cases[case_id].proposed_report = proposed_report(cases[case_id], "weather_monitoring" if objective == "weather" else objective)
	var a: Dictionary = cases.imaging_a
	var b: Dictionary = cases.imaging_b
	var baseline: Dictionary = {
		"report": a.evaluation.report, "state": a.trace.final_state,
		"validation": a.trace.validation, "execution_key": a.execution_key,
	}
	var comparison_reply: Dictionary = Evaluator.evaluate_hpc_state(b.trace.final_state, baseline)
	check(comparison_reply.ok and comparison_reply.report.comparison == null, "Production baseline argument still yields comparison=null")
	check(not cases.survey_shortfall.evaluation.ok and not cases.survey_complete.evaluation.ok, "Production evaluator rejects both Survey cases")
	check(cases.survey_shortfall.measured.delivered_selected_targets == 1, "Real Survey shortfall has one complete target delivery")
	check(cases.survey_complete.measured.delivered_selected_targets == 2, "Real Survey completion has both target deliveries")
	check(cases.survey_shortfall.measured.returned_data_mb >= 12.0, "Survey shortfall meets the aggregate MB goal")
	check(cases.communication_candidate_shortfall.measured.positive_transmit_steps == 1, "Communication candidate shortfall has one positive step")
	check(cases.communication_candidate_complete.measured.positive_transmit_steps == 2, "Communication candidate completion has two positive steps")
	check(cases.communication_candidate_shortfall.measured.returned_data_mb >= 12.0, "Communication candidate shortfall meets MB")
	check(cases.weather_candidate_shortfall.measured.selected_target_revolution_visits == 1, "Weather candidate shortfall has one revolution")
	check(cases.weather_candidate_complete.measured.selected_target_revolution_visits == 2, "Weather candidate completion has two revolutions")
	check(cases.weather_candidate_shortfall.measured.returned_data_mb >= 12.0, "Weather candidate shortfall meets MB")
	var rejections: Dictionary = {}
	for objective: String in ["communication", "weather_monitoring"]:
		var candidate: Dictionary = Runtime.config_for(weather)
		candidate.mission.objective = objective
		candidate.mission.preset_id = objective
		candidate.mission["required_contact_steps" if objective == "communication" else "required_orbit_visits"] = 2
		var reply: Dictionary = StepEngine.init_validated_run(candidate, loaded.catalogs, "probe_rejected_" + objective, "ke2_handoff_20261115")
		check(not reply.ok, objective + " configuration rejected by actual readiness entry point")
		rejections[objective] = {"config": candidate, "initialization": reply, "execution_started": false}
	var proposed_pair: Dictionary = {
		"status": "proposal_for_owner_review",
		"implemented_comparison_api": null,
		"proposed_api": "MissionComparison.compare_runs(a_record, b_record) -> Dictionary",
		"a": identity(a), "b": identity(b),
		"proposed_eligibility": {"eligible": null, "candidate_label": "Design", "reasons": [{"code": "CONTRACT_PENDING", "message": "Production eligibility computation is unavailable. Stable preset identity, version matching and saved-record contract await owner agreement."}]},
		"operations_scope": {"requested_policy_id": "observe_first_v1", "definition": "At every step, request the first allowed action in observe, transmit, power_save order.", "a_requested_actions": a.requested_actions, "b_requested_actions": b.requested_actions},
		"changed_parts": [{"field": "radio_id", "a": "radio_basic", "b": "radio_fast", "delta_mass_g": 60, "delta_cost_credits": 7}],
		"outcomes": {"a": a.evaluation.report.status, "b": b.evaluation.report.status},
		"measures": paired_measures(a, b),
		"interpretation": "Under the same observe-first policy and one-orbit schedule, the fast-radio run returned more MB. The radio change also increased modeled mass and cost. The measured pair supports this scenario-specific trade-off.",
		"production_evaluation_with_baseline": comparison_reply,
	}
	var packet: Dictionary = {
		"date": "2026-11-15", "timezone": "Asia/Rangoon",
		"code_revision": "4c65496", "branch": "features/KE2", "engine_version": Engine.get_version_info().string,
		"execution_scope": "Direct headless module calls. Run IDs identify reproducible probe executions. No active UI execution or saved-A lifecycle was exercised.",
		"verification_level": "integrated_headless_modules_and_proposed_audit_assessments",
		"resource_sampling": "Initial state and every accepted post-step state, including terminal. Battery Wh and percent of capacity are separate measures.",
		"weather_mapping_status": "Source-derived candidate floor(accepted_event.step_index / 10), awaiting HPC agreement.",
		"candidate_goal_rules": {"survey": "Equal capped capture, returned-MB and delivered-selected-target ratios.", "communication": "Equal capped positive-transmit-step and returned-MB ratios, with contact goal 2.", "weather_monitoring": "Equal capped selected-target distinct-revolution and returned-MB ratios, with visit goal 2.", "rounding": "Round once, halves upward. Proposed expansion assessments are separate from production evaluator replies."},
		"source_sha256": source_hashes(), "cases": cases,
		"unsupported_objective_initialization": rejections,
		"ab_payload_proposal": proposed_pair,
	}
	var file = FileAccess.open(OUTPUT, FileAccess.WRITE)
	check(file != null, "Evidence output is writable")
	if file != null:
		file.store_string(JSON.stringify(packet, "\t", true, true) + "\n")
	print("Handoff probe failures: ", failures)
	quit(0 if failures == 0 else 1)


func draft_for(objective: String, targets: Array, orbit: String) -> Dictionary:
	var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
	Catalog.ensure(draft)
	draft.name = "KE2 handoff measurement"
	draft.objective = objective
	draft.targets = targets.duplicate()
	draft.orbit = orbit
	draft.observations = 2
	draft.required_returned_data_mb = 12.0
	draft.duration = 3
	return draft


func run_case(draft: Dictionary, case_id: String, catalogs: Dictionary, observe_steps: Array = [], transmit_steps: Array = []) -> Dictionary:
	var config: Dictionary = Runtime.config_for(draft)
	var started: Dictionary = StepEngine.init_validated_run(config, catalogs, "ke2_probe_20261115_" + case_id, "ke2_handoff_20261115")
	check(started.ok, case_id + " passes actual readiness and initialization")
	if not started.ok:
		return {}
	var state: Dictionary = started.state
	var samples: Array = [sample(state)]
	var requested: Array = []
	while state.phase == "operating":
		var action: String = "power_save"
		if observe_steps.is_empty():
			for candidate: String in ["observe", "transmit", "power_save"]:
				if state.available_actions[candidate].allowed:
					action = candidate
					break
		elif observe_steps.has(int(state.step_index)):
			action = "observe"
		elif transmit_steps.has(int(state.step_index)):
			action = "transmit"
		requested.append({"step_index": state.step_index, "action": action})
		var reply: Dictionary = StepEngine.request_action(state, action)
		check(reply.get("ok", false) and reply.get("allowed", false), case_id + " step " + str(state.step_index))
		if not reply.get("ok", false) or not reply.get("allowed", false):
			return {}
		state = reply.state
		samples.append(sample(state))
	var trace: Dictionary = {"config": config, "final_state": state, "events": state.event_log, "validation": started.validation_result}
	var evaluation: Dictionary = Results.evaluate_trace(trace)
	var measured: Dictionary = measures(trace, samples)
	return {"case_id": case_id, "execution_key": Results.input_key(trace), "trace": trace, "evaluation": evaluation, "measured": measured, "resource_samples": samples, "requested_actions": requested}


func sample(state: Dictionary) -> Dictionary:
	return {"step_index": state.step_index, "energy_wh": state.energy_wh, "stored_data_mb": state.stored_data_mb}


func measures(trace: Dictionary, samples: Array) -> Dictionary:
	var final: Dictionary = trace.final_state
	var positive_steps: Array = []
	var revolution_ids: Array = []
	var evidence: Array = []
	var selected: Array = trace.config.mission.target_regions
	for event: Dictionary in trace.events:
		if event.type != "action_accepted":
			continue
		if event.action == "transmit" and event.delta_returned_data_mb > 0 and not positive_steps.has(event.step_index):
			positive_steps.append(event.step_index)
			evidence.append(event.duplicate(true))
		if event.action == "observe" and event.delta_observations > 0 and selected.has(event.get("target_id")):
			var revolution: int = floori(float(event.step_index) / 10.0)
			if not revolution_ids.has(revolution):
				revolution_ids.append(revolution)
			evidence.append(event.duplicate(true))
	var delivered: int = 0
	for target: String in selected:
		if final.observations_delivered_by_target.get(target, 0) > 0:
			delivered += 1
	var lowest: float = float(samples[0].energy_wh)
	var peak: float = 0.0
	for point: Dictionary in samples:
		lowest = minf(lowest, point.energy_wh)
		peak = maxf(peak, point.stored_data_mb)
	return {
		"observations_completed": final.observations_completed,
		"required_observations": trace.config.mission.required_observations,
		"returned_data_mb": final.returned_data_mb,
		"required_returned_data_mb": trace.config.mission.required_returned_data_mb,
		"delivered_selected_targets": delivered, "required_selected_targets": selected.size(),
		"observations_delivered_by_target": final.observations_delivered_by_target,
		"returned_data_by_target_mb": final.returned_data_by_target_mb,
		"positive_transmit_steps": positive_steps.size(), "positive_transmit_step_indices": positive_steps,
		"selected_target_revolution_visits": revolution_ids.size(), "revolution_indices": revolution_ids,
		"lowest_battery_wh": lowest, "lowest_battery_percent": 100.0 * lowest / final.battery_capacity_wh,
		"highest_storage_mb": peak,
		"total_cost_credits": trace.validation.metrics.total_cost_credits,
		"total_mass_g": trace.validation.metrics.total_mass_g,
		"supporting_events": evidence,
	}


func identity(record: Dictionary) -> Dictionary:
	return {"run_id": record.trace.final_state.run_id, "mission_id": record.trace.final_state.mission_id, "execution_key": record.execution_key, "scenario_id": record.trace.final_state.scenario_id}


func paired_measures(a: Dictionary, b: Dictionary) -> Array:
	var output: Array = []
	for entry: Array in [["observations_completed", "count"], ["returned_data_mb", "MB"], ["lowest_battery_wh", "Wh"], ["lowest_battery_percent", "percent"], ["highest_storage_mb", "MB"], ["total_cost_credits", "credits"], ["total_mass_g", "g"]]:
		var field: String = entry[0]
		output.append({"id": field, "unit": entry[1], "delta_unit": "percentage_points" if entry[1] == "percent" else entry[1], "a": a.measured[field], "b": b.measured[field], "delta_b_minus_a": b.measured[field] - a.measured[field], "available": true})
	output.append({"id": "score", "unit": "points", "a": a.evaluation.report.score, "b": b.evaluation.report.score, "delta_b_minus_a": b.evaluation.report.score - a.evaluation.report.score, "available": true})
	return output


func proposed_report(record: Dictionary, objective: String) -> Dictionary:
	var measured: Dictionary = record.measured
	var goals: Array = []
	var experiment: String
	if objective == "survey":
		goals.append({"id": "captures", "actual": measured.observations_completed, "required": measured.required_observations, "unit": "count"})
		goals.append({"id": "selected_targets_delivered", "actual": measured.delivered_selected_targets, "required": measured.required_selected_targets, "unit": "targets"})
		experiment = "Keep the design and captures fixed and transmit at additional available steps 20 and 27 to finish the remaining packet."
	elif objective == "communication":
		goals.append({"id": "positive_transmit_steps", "actual": measured.positive_transmit_steps, "required": 2, "unit": "steps"})
		experiment = "Keep the design and capture plan fixed and transmit at available step 18 as well as step 8."
	else:
		goals.append({"id": "selected_target_revolution_visits", "actual": measured.selected_target_revolution_visits, "required": 2, "unit": "revolutions"})
		experiment = "Keep the design and downlink plan fixed and move the second capture from step 5 to step 12."
	goals.append({"id": "returned_data", "actual": measured.returned_data_mb, "required": measured.required_returned_data_mb, "unit": "MB"})
	var ratio_sum: float = 0.0
	var met: bool = true
	for goal: Dictionary in goals:
		goal.met = goal.actual >= goal.required
		met = met and goal.met
		ratio_sum += minf(1.0, float(goal.actual) / float(goal.required))
	return {
		"provenance": "Proposed audit assessment calculated from real engine counters. Production evaluator response is stored separately in evaluation.",
		"schema_version": 1,
		"run_id": record.trace.final_state.run_id, "mission_id": record.trace.final_state.mission_id,
		"execution_key": record.execution_key, "objective": objective,
		"run_status": "completed", "status": "success" if met else "partial",
		"observations_completed": measured.observations_completed, "required_observations": measured.required_observations,
		"returned_data_mb": measured.returned_data_mb, "required_returned_data_mb": measured.required_returned_data_mb,
		"observation_completion_ratio": minf(1.0, float(measured.observations_completed) / measured.required_observations),
		"data_return_completion_ratio": minf(1.0, measured.returned_data_mb / measured.required_returned_data_mb),
		"score": int(floorf(100.0 * ratio_sum / goals.size() + 0.5)), "goal_progress": goals,
		"per_target_deliveries": measured.observations_delivered_by_target if objective == "survey" else null,
		"explanation": "All proposed goals are met in this probe." if met else "The recorded qualifying count is below its proposed requirement. The returned-MB requirement is met.",
		"root_causes": [], "next_experiment": "Repeat this completed plan to verify the same measured outcome." if met else experiment,
		"source_ids": [], "comparison": null,
	}


func source_hashes() -> Dictionary:
	var hashes: Dictionary = {}
	for path: String in ["scripts/evaluation/mission_evaluator.gd", "scripts/integration/mission_results.gd", "scripts/integration/mission_runtime.gd", "core/MissionStepEngine.gd", "core/HPCContractAdapter.gd", "data/components.json", "data/orbits.json", "data/mission_scenarios.json"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	return hashes


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL " + message)
