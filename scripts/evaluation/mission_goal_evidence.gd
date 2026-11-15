extends RefCounted
## KE2 internal measurements. Not wired into production reports or new objectives.
## HPC confirmed these native measurements at 345e5bd. Goal/report adoption is
## tracked separately from the producer evidence revision.
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const HPC_REVISION = "hpc-goal-evidence-v1.0.0"

static func _communication(state: Dictionary, events: Variant) -> Dictionary:
	var checked: Dictionary = _events(state, events)
	if not checked.ok: return checked
	var steps: Array = []
	var ids: Array = []
	for event: Dictionary in checked.events:
		if event.get("type") != "action_accepted" or event.get("action") != "transmit": continue
		var amount: Variant = event.get("delta_returned_data_mb")
		if not Evaluator._is_finite_number(amount) or amount < 0:
			return _bad("events." + event.event_id + ".delta_returned_data_mb", state)
		var step: int = int(event.step_index)
		if amount > 0 and not step in steps:
			steps.append(step)
			ids.append(event.event_id)
	return {"ok": true, "measure": {"positive_transmit_steps": steps.size(), "step_indices": steps, "evidence_event_ids": ids}}

static func _weather(config: Dictionary, state: Dictionary, events: Variant) -> Dictionary:
	var checked: Dictionary = _events(state, events)
	if not checked.ok: return checked
	if state.get("config_snapshot") != config: return _bad("final_state.config_snapshot", state)
	var mission: Variant = config.get("mission")
	var design: Variant = config.get("design")
	if not mission is Dictionary or not design is Dictionary: return _bad("config", state)
	var selected: Variant = mission.get("target_regions", [mission.get("target_region")])
	if not selected is Array or selected.size() != 1 or not selected[0] is String or selected[0].strip_edges().is_empty() or selected[0] != mission.get("target_region"):
		return _bad("config.mission.target_regions", state)
	var scenario: Variant = state.get("scenario_snapshot")
	if not scenario is Dictionary or not scenario.get("orbits") is Array: return _bad("final_state.scenario_snapshot.orbits", state)
	var matching: Array = []
	for orbit in scenario.orbits:
		if orbit is Dictionary and orbit.get("id") == design.get("orbit_id"): matching.append(orbit)
	if matching.size() != 1: return _bad("final_state.scenario_snapshot.orbits", state)
	var steps: Variant = matching[0].get("steps_per_orbit")
	if not Evaluator._is_whole_number(steps) or steps <= 0: return _bad("scenario.steps_per_orbit", state)
	var indices: Array = []
	var ids: Array = []
	for event: Dictionary in checked.events:
		if event.get("type") != "action_accepted" or event.get("action") != "observe": continue
		var captures: Variant = event.get("delta_observations")
		if not Evaluator._is_whole_number(captures) or captures < 0: return _bad("events." + event.event_id + ".delta_observations", state)
		if captures == 0: continue
		if not event.get("target_id") is String or event.target_id.strip_edges().is_empty(): return _bad("events." + event.event_id + ".target_id", state)
		if event.target_id != selected[0]: continue
		var index: int = floori(float(event.step_index) / float(steps))
		if event.has("orbit_index") and (not Evaluator._is_whole_number(event.orbit_index) or event.orbit_index != index): return _bad("events." + event.event_id + ".orbit_index", state)
		if not index in indices:
			indices.append(index)
			ids.append(event.event_id)
	return {"ok": true, "measure": {"selected_target_revolution_visits": indices.size(), "revolution_indices": indices,
		"target_id": selected[0], "steps_per_orbit": steps, "evidence_event_ids": ids,
		"mapping_status": "pre_action_floor_hpc_confirmed_345e5bd"}}

static func _events(state: Dictionary, events: Variant) -> Dictionary:
	if not events is Array: return _bad("events", state)
	for field in ["run_id", "mission_id"]:
		if not state.get(field) is String or state[field].strip_edges().is_empty(): return _bad("final_state." + field, state)
	if not Evaluator._is_whole_number(state.get("total_steps")) or state.total_steps <= 0:
		return _bad("final_state.total_steps", state)
	if not Evaluator._is_whole_number(state.get("step_index")) or state.step_index < 0 or state.step_index > state.total_steps:
		return _bad("final_state.step_index", state)
	var unique: Dictionary = {}
	var ordered: Array = []
	var previous: int = -1
	for index in events.size():
		var event: Variant = events[index]
		var path: String = "events[%d]" % index
		if not event is Dictionary: return _bad(path, state)
		if not event.get("event_id") is String or event.event_id.strip_edges().is_empty(): return _bad(path + ".event_id", state)
		if event.get("run_id") != state.run_id or event.get("mission_id") != state.mission_id: return _bad(path + ".run_id", state)
		if unique.has(event.event_id):
			if unique[event.event_id] != event: return _bad(path + ".event_id", state)
			continue
		var step: Variant = event.get("step_index")
		if not Evaluator._is_whole_number(step) or step < previous or step > state.step_index or step < 0:
			return _bad(path + ".step_index", state)
		if event.get("type") == "action_accepted" and step >= state.step_index: return _bad(path + ".step_index", state)
		previous = int(step)
		unique[event.event_id] = event
		ordered.append(event.duplicate(true))
	if state.has("event_log"):
		var context: Dictionary = state.duplicate(true)
		context.erase("event_log")
		var retained: Dictionary = _events(context, state.event_log)
		if not retained.ok: return retained
		if JSON.parse_string(JSON.stringify(ordered)) != JSON.parse_string(JSON.stringify(retained.events)): return _bad("events", state)
	return {"ok": true, "events": ordered}

static func _bad(path: String, state: Dictionary) -> Dictionary:
	var id: Variant = state.get("run_id")
	if not id is String or id.strip_edges().is_empty(): id = null
	return Evaluator._error(Evaluator.INVALID_INPUT, path,
		"Required measurement evidence is missing, malformed, conflicting or belongs to another execution.",
		"Use the complete ordered same-run native evidence; do not invent missing counters or identities.", id)
