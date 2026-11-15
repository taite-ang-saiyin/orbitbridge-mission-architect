extends RefCounted
## Explicit opt-in integration candidate. Active v1 evaluation is unchanged.
## This module implements proposed rules for review, not a ratified team contract.
const Base = preload("res://scripts/evaluation/mission_evaluator.gd")
const Evidence = preload("res://scripts/evaluation/mission_goal_evidence.gd")
const Feedback = preload("res://scripts/evaluation/mission_goal_feedback.gd")
const INPUT_REVISION = "expansion-goals-v2-draft-2"
const AGREED_INPUT_REVISION = "expansion-goals-v2-agreed-1"
const REPORT_REVISION = "mission-report-goals-v2-draft-1"
const EVALUATOR_REVISION = "ke2-expansion-candidate-3"
const HPC_EVALUATOR_REVISION = "ke2-expansion-candidate-2"
const LEGACY_EVALUATOR_REVISION = "ke2-expansion-candidate-1"
const LEGACY_POLICY_REVISION = "ke2-evidence-policy-candidate-1"
const OBJECTIVES = ["imaging", "survey", "communication", "weather_monitoring"]
const PRESETS = {"estuary_watch": "imaging", "tropical_forest_watch": "imaging", "polar_ice_survey": "survey", "communication": "communication", "weather_monitoring": "weather_monitoring"}

static func default_policy() -> Dictionary:
	return {"revision": Evidence.HPC_REVISION, "survey_missing_targets": "zero_in_present_map", "weather_mapping": "step_floor"}

@warning_ignore("unused_parameter")
static func evaluate_mission(config: Dictionary, final_state: Dictionary, events: Array, comparison_baseline = null) -> Dictionary:
	# Comparison remains a separate call on complete execution records, per handoff.
	return evaluate_with_policy(config, final_state, events, default_policy())

static func evaluate_with_policy(config: Dictionary, state: Dictionary, events: Array, policy: Dictionary) -> Dictionary:
	var checked: Dictionary = _validate(config, state, events, policy)
	if not checked.ok: return checked
	var mission: Dictionary = config.mission
	var objective: String = mission.objective
	var accepted: Array = checked.accepted
	var capture_ids: Array = []
	var return_ids: Array = []
	for event: Dictionary in accepted:
		if event.action == "observe" and event.delta_observations > 0: capture_ids.append(event.event_id)
		if event.action == "transmit" and event.delta_returned_data_mb > 0: return_ids.append(event.event_id)
	var goals: Array = []
	if objective in ["imaging", "survey"]:
		goals.append(_goal("captures", state.observations_completed, mission.required_observations, "count", capture_ids))
	goals.append(_goal("returned_data", state.returned_data_mb, mission.required_returned_data_mb, "MB", return_ids))
	var feedback_state: Dictionary = state.duplicate(true)
	if objective == "survey":
		var delivery: Dictionary = _survey(config, state, policy)
		if not delivery.ok and (state.run_status != "aborted" or not delivery.get("unavailable", false)): return {"ok": false, "error": delivery.error}
		var selected: Array = checked.targets
		var row: Dictionary = _goal("selected_targets_delivered", delivery.get("count"), selected.size(), "targets", return_ids)
		var details: Array = []
		for target: String in selected:
			var actual: Variant = delivery.get("counts", {}).get(target)
			var child: Dictionary = _goal(target, actual, 1, "complete_observations", [])
			child.erase("id")
			child.erase("evidence_event_ids")
			child.target_id = target
			var target_data: Variant = state.get("returned_data_by_target_mb")
			child.returned_data_mb = null
			if target_data is Dictionary:
				child.returned_data_mb = target_data.get(target, 0.0) if policy.revision == Evidence.HPC_REVISION else target_data.get(target)
			details.append(child)
		row.by_target = details
		goals.insert(1, row)
		if delivery.ok: feedback_state.observations_delivered_by_target = delivery.counts.duplicate(true)
	elif objective == "communication":
		var communication: Dictionary = Evidence._communication(state, events)
		if not communication.ok: return communication
		goals.push_front(_goal("positive_transmit_steps", communication.measure.positive_transmit_steps,
			mission.goal.required_positive_contact_steps, "steps", communication.measure.evidence_event_ids))
	elif objective == "weather_monitoring":
		var weather: Dictionary = _weather(config, state, events, policy)
		if not weather.ok and (state.run_status != "aborted" or not weather.get("unavailable", false)): return {"ok": false, "error": weather.error}
		goals.push_front(_goal("selected_target_revolution_visits", weather.get("count"), mission.goal.required_distinct_orbits, "revolutions", weather.get("ids", [])))
	var status: String = "success"
	var ratio_sum: float = 0
	var progress: bool = false
	for row: Dictionary in goals:
		if row.met != true: status = "partial"
		if row.actual != null and row.actual > 0: progress = true
		if row.completion_ratio != null: ratio_sum += row.completion_ratio
	if status != "success" and not progress: status = "failed"
	var score: Variant = int(floorf(100.0 * ratio_sum / float(goals.size()) + 0.5))
	if state.run_status == "aborted": status = "failed"; score = null
	var feedback: Dictionary = Feedback._build(feedback_state, events, goals, policy.revision == Evidence.HPC_REVISION)
	if objective == "weather_monitoring" and policy.weather_mapping == "recorded_orbit_index" and state.run_status != "aborted":
		feedback = {"explanation": "Recorded revolution evidence was assessed under the explicit candidate mapping policy.", "root_causes": [], "next_experiment": "Keep the design/downlink fixed and try a target-access step in another required revolution."}
	if status == "success":
		feedback = {"explanation": "All required candidate goals were met; raw measurements are retained in the goal rows.", "root_causes": [], "next_experiment": "Keep the scenario and plan fixed and change one design choice on the next attempt."}
	var report: Dictionary = {"schema_version": 2, "run_id": state.run_id, "mission_id": state.mission_id, "run_status": state.run_status,
		"status": status, "observations_completed": state.observations_completed, "required_observations": mission.required_observations,
		"returned_data_mb": state.returned_data_mb, "required_returned_data_mb": mission.required_returned_data_mb,
		"observation_completion_ratio": _ratio(state.observations_completed, mission.required_observations),
		"data_return_completion_ratio": _ratio(state.returned_data_mb, mission.required_returned_data_mb), "score": score,
		"explanation": feedback.explanation, "root_causes": feedback.root_causes.duplicate(true), "next_experiment": feedback.next_experiment,
		"source_ids": [], "comparison": null, "objective": objective, "goal_progress": goals}
	return {"ok": true, "report": report}

static func _validate(config: Dictionary, state: Dictionary, events: Array, policy: Dictionary) -> Dictionary:
	if not policy.get("revision") in [Evidence.HPC_REVISION, LEGACY_POLICY_REVISION] or not policy.get("survey_missing_targets") in ["unavailable", "zero_in_present_map"] or not policy.get("weather_mapping") in ["step_floor", "recorded_orbit_index"] or policy.size() != 3: return _bad("policy", state)
	if not Base._is_whole_number(config.get("schema_version")) or (config.schema_version != 1 and config.schema_version != 2): return _bad("config.schema_version", state)
	var version: int = int(config.schema_version)
	var root_fields: Array = ["schema_version", "mission", "design"]
	if version == 2: root_fields.append_array(["contract_revision", "preset_id", "preset_revision"])
	for field in root_fields:
		if not config.has(field): return _bad("config." + field, state)
	for field in config:
		if not field in root_fields: return _bad("config." + str(field), state)
	if not config.mission is Dictionary or not config.design is Dictionary: return _bad("config", state)
	var mission: Dictionary = config.mission
	var required: Array = ["title", "objective", "target_region", "required_observations", "required_returned_data_mb", "duration_orbits", "budget_credits"]
	if version == 2: required.append("goal")
	for field in required:
		if not mission.has(field): return _bad("config.mission." + field, state)
	for field in mission:
		if not field in required and field != "target_regions": return _bad("config.mission." + str(field), state)
	if not mission.title is String or mission.title.strip_edges().is_empty() or mission.title.length() > 80: return _bad("config.mission.title", state)
	if not mission.objective in OBJECTIVES or (version == 1 and not mission.objective in ["imaging", "survey"]): return _bad("config.mission.objective", state)
	for spec in [["required_observations", 20], ["duration_orbits", 12], ["budget_credits", 9223372036854775807]]:
		if not Base._is_whole_number(mission[spec[0]]) or mission[spec[0]] <= 0 or mission[spec[0]] > spec[1]: return _bad("config.mission." + spec[0], state)
	if not Base._is_finite_number(mission.required_returned_data_mb) or mission.required_returned_data_mb <= 0: return _bad("config.mission.required_returned_data_mb", state)
	var targets: Variant = mission.get("target_regions", [mission.target_region])
	if not targets is Array or targets.is_empty() or targets.size() > 2: return _bad("config.mission.target_regions", state)
	var seen: Array = []
	for target in targets:
		if not target is String or target.strip_edges().is_empty() or target in seen: return _bad("config.mission.target_regions", state)
		seen.append(target)
	if targets[0] != mission.target_region: return _bad("config.mission.target_region", state)
	if mission.objective in ["communication", "weather_monitoring"] and targets.size() != 1: return _bad("config.mission.target_regions", state)
	if mission.objective == "survey" and mission.required_observations < targets.size(): return _bad("config.mission.required_observations", state)
	var design_fields: Array = ["bus_id", "instrument_id", "solar_id", "battery_id", "radio_id", "storage_id", "launch_profile_id", "launcher_id", "orbit_id"]
	for field in design_fields:
		if not config.design.get(field) is String or config.design[field].is_empty(): return _bad("config.design." + field, state)
	for field in config.design:
		if not field in design_fields: return _bad("config.design." + str(field), state)
	if version == 2:
		if not config.contract_revision in [INPUT_REVISION, AGREED_INPUT_REVISION]: return _bad("config.contract_revision", state)
		if not config.preset_id is String or PRESETS.get(config.preset_id) != mission.objective: return _bad("config.preset_id", state)
		if not Base._is_whole_number(config.preset_revision) or config.preset_revision <= 0: return _bad("config.preset_revision", state)
		if config.contract_revision == AGREED_INPUT_REVISION:
			var authored_revision: int = 2 if config.preset_id == "communication" else 1
			if config.preset_revision != authored_revision: return _bad("config.preset_revision", state)
			if mission.budget_credits > 9007199254740991: return _bad("config.mission.budget_credits", state)
		var goal: Variant = mission.goal
		var kinds: Dictionary = {"imaging": "imaging", "survey": "survey_delivery", "communication": "communication_contacts", "weather_monitoring": "weather_revisit"}
		if not goal is Dictionary or goal.get("kind") != kinds[mission.objective]: return _bad("config.mission.goal", state)
		var count_key: String = {"survey": "minimum_complete_observations_per_target", "communication": "required_positive_contact_steps", "weather_monitoring": "required_distinct_orbits"}.get(mission.objective, "")
		if goal.size() != (1 if count_key.is_empty() else 2): return _bad("config.mission.goal", state)
		if not count_key.is_empty() and (not Base._is_whole_number(goal.get(count_key)) or goal[count_key] <= 0): return _bad("config.mission.goal." + count_key, state)
		if mission.objective == "survey" and goal[count_key] != 1: return _bad("config.mission.goal." + count_key, state)
		if mission.objective == "weather_monitoring" and (goal[count_key] > mission.duration_orbits or goal[count_key] > mission.required_observations): return _bad("config.mission.goal." + count_key, state)
	if not Base._is_whole_number(state.get("schema_version")) or state.schema_version != 1: return _bad("final_state.schema_version", state)
	for field in ["run_id", "mission_id"]:
		if not state.get(field) is String or state[field].strip_edges().is_empty(): return _bad("final_state." + field, state)
	if state.get("phase") == "operating": return Base._error(Base.NONTERMINAL_STATE, "final_state.phase", "Candidate evaluation requires a terminal run.", "Finish or abort the run.", state.get("run_id"))
	if state.get("phase") != "finished" or not state.get("run_status") in ["completed", "aborted"]: return _bad("final_state.run_status", state)
	for field in ["observations_completed", "step_index", "total_steps"]:
		if not Base._is_whole_number(state.get(field)) or state[field] < 0 or (field == "total_steps" and state[field] == 0): return _bad("final_state." + field, state)
	if state.step_index > state.total_steps or (state.run_status == "completed" and state.step_index != state.total_steps) or (state.run_status == "aborted" and state.step_index >= state.total_steps): return _bad("final_state.step_index", state)
	for field in ["returned_data_mb", "stored_data_mb", "energy_wh", "battery_capacity_wh", "storage_capacity_mb"]:
		if not Base._is_finite_number(state.get(field)) or state[field] < 0: return _bad("final_state." + field, state)
	if state.battery_capacity_wh <= 0 or state.energy_wh > state.battery_capacity_wh or state.stored_data_mb > state.storage_capacity_mb: return _bad("final_state.energy_wh", state)
	if state.get("config_snapshot") != config: return _bad("final_state.config_snapshot", state)
	if not state.get("event_log") is Array: return _bad("final_state.event_log", state)
	for field in ["observations_by_target", "returned_data_by_target_mb", "observations_delivered_by_target"]:
		if not state.has(field) or state[field] == null: continue
		if not state[field] is Dictionary: return _bad("final_state." + field, state)
		for target in state[field]:
			var value: Variant = state[field][target]
			if not target is String or target.is_empty() or not Base._is_finite_number(value) or value < 0 or (field != "returned_data_by_target_mb" and not Base._is_whole_number(value)): return _bad("final_state." + field, state)
	if state.get("observations_by_target") is Dictionary:
		var total: float = 0
		for value in state.observations_by_target.values(): total += value
		if total != state.observations_completed: return _bad("final_state.observations_by_target", state)
		if state.get("observations_delivered_by_target") is Dictionary:
			for target in state.observations_delivered_by_target:
				if state.observations_delivered_by_target[target] > state.observations_by_target.get(target, 0): return _bad("final_state.observations_delivered_by_target." + target, state)
	if state.get("returned_data_by_target_mb") is Dictionary:
		var total: float = 0
		for value in state.returned_data_by_target_mb.values(): total += value
		if not is_finite(total) or not _close(total, state.returned_data_mb): return _bad("final_state.returned_data_by_target_mb", state)
	var orbit: Dictionary = _orbit(config, state)
	if orbit.is_empty() or state.get("scenario_id") != config.design.orbit_id or state.total_steps != mission.duration_orbits * orbit.steps_per_orbit: return _bad("final_state.scenario_snapshot", state)
	if mission.objective == "communication" and mission.goal.required_positive_contact_steps > state.total_steps: return _bad("config.mission.goal.required_positive_contact_steps", state)
	var history: Dictionary = Evidence._events(state, events)
	if not history.ok: return history
	var accepted: Dictionary = {}
	var captures: int = 0
	var returned: float = 0
	for event: Dictionary in history.events:
		if event.get("type") != "action_accepted": continue
		if not event.get("action") in ["observe", "transmit", "power_save"] or not Base._is_whole_number(event.get("delta_observations")) or event.delta_observations < 0 or not Base._is_finite_number(event.get("delta_returned_data_mb")) or event.delta_returned_data_mb < 0: return _bad("events." + event.event_id, state)
		var step: int = int(event.step_index)
		if accepted.has(step):
			var first: Dictionary = accepted[step].duplicate(true)
			var repeated: Dictionary = event.duplicate(true)
			first.erase("event_id"); repeated.erase("event_id")
			if first != repeated: return _bad("events." + event.event_id, state)
			continue
		if event.action == "observe" and (event.delta_observations != 1 or not event.get("target_id") is String or event.target_id.is_empty()): return _bad("events." + event.event_id, state)
		if event.action != "observe" and event.delta_observations != 0: return _bad("events." + event.event_id, state)
		if event.action != "transmit" and event.delta_returned_data_mb != 0: return _bad("events." + event.event_id, state)
		accepted[step] = event
		captures += int(event.delta_observations)
		returned += event.delta_returned_data_mb
	if accepted.size() != int(state.step_index): return _bad("events", state)
	for step in int(state.step_index):
		if not accepted.has(step): return _bad("events", state)
	if captures != state.observations_completed or not is_finite(returned) or not _close(returned, state.returned_data_mb): return _bad("final_state.returned_data_mb", state)
	return {"ok": true, "accepted": accepted.values(), "targets": targets}

static func _survey(config: Dictionary, state: Dictionary, policy: Dictionary) -> Dictionary:
	if not state.get("observations_delivered_by_target") is Dictionary: return _missing("final_state.observations_delivered_by_target", state)
	var normalized: Dictionary = state.duplicate(true)
	var selected: Array = config.mission.get("target_regions", [config.mission.target_region])
	for target: String in selected:
		if not normalized.observations_delivered_by_target.has(target):
			if policy.survey_missing_targets == "unavailable": return _missing("final_state.observations_delivered_by_target." + target, state)
			normalized.observations_delivered_by_target[target] = 0
	var measured: Dictionary = Base._measure_survey_deliveries(config, normalized)
	if not measured.ok: return measured
	return {"ok": true, "count": measured.measure.delivered_selected_target_count, "counts": normalized.observations_delivered_by_target}

static func _weather(config: Dictionary, state: Dictionary, events: Array, policy: Dictionary) -> Dictionary:
	if policy.weather_mapping == "step_floor":
		var measured: Dictionary = Evidence._weather(config, state, events)
		if not measured.ok: return measured
		return {"ok": true, "count": measured.measure.selected_target_revolution_visits, "ids": measured.measure.evidence_event_ids}
	var indices: Array = []
	var ids: Array = []
	for event: Dictionary in events:
		if event.get("type") != "action_accepted" or event.get("action") != "observe" or event.get("target_id") != config.mission.target_region: continue
		if not event.has("orbit_index"): return _missing("events." + event.event_id + ".orbit_index", state)
		if not Base._is_whole_number(event.orbit_index) or event.orbit_index < 0 or event.orbit_index >= config.mission.duration_orbits: return _bad("events." + event.event_id + ".orbit_index", state)
		var index: int = int(event.orbit_index)
		if not index in indices: indices.append(index); ids.append(event.event_id)
	return {"ok": true, "count": indices.size(), "ids": ids}

static func _orbit(config: Dictionary, state: Dictionary) -> Dictionary:
	var scenario: Variant = state.get("scenario_snapshot")
	if not scenario is Dictionary or not scenario.get("scenario_version") is String or scenario.scenario_version.is_empty() or not scenario.get("orbits") is Array: return {}
	var found: Array = []
	for orbit in scenario.orbits:
		if orbit is Dictionary and orbit.get("id") == config.design.orbit_id: found.append(orbit)
	if found.size() != 1: return {}
	var selected: Dictionary = found[0]
	if not Base._is_whole_number(selected.get("steps_per_orbit")) or selected.steps_per_orbit <= 0 or not Base._is_finite_number(selected.get("step_duration_hours")) or selected.step_duration_hours <= 0: return {}
	return selected

static func _goal(id: String, actual: Variant, required: Variant, unit: String, ids: Array) -> Dictionary:
	return {"id": id, "actual": actual, "required": required, "unit": unit,
		"met": actual >= required if actual != null else null, "completion_ratio": _ratio(actual, required) if actual != null else null, "evidence_event_ids": ids.duplicate()}

static func _ratio(actual: Variant, required: Variant) -> float:
	return 1.0 if actual >= required else float(actual) / float(required)

static func _close(a: float, b: float) -> bool:
	return absf(a - b) <= 1e-8 * maxf(1.0, maxf(absf(a), absf(b)))

static func _bad(path: String, state: Dictionary) -> Dictionary:
	var id: Variant = state.get("run_id")
	if not id is String or id.strip_edges().is_empty(): id = null
	return Base._error(Base.INVALID_INPUT, path, "Invalid candidate configuration, terminal state or evidence.", "Use the pinned candidate contract and full immutable same-run evidence.", id)

static func _missing(path: String, state: Dictionary) -> Dictionary:
	var result: Dictionary = _bad(path, state)
	result.error.message = "Required evidence is unavailable under the selected candidate policy."
	result.unavailable = true
	return result
