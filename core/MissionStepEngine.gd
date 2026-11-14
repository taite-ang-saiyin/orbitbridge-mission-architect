extends RefCounted
class_name MissionStepEngine

## Scene-independent, deterministic per-step mission operations for Team Contract v1.
## `scenario` is an immutable catalog snapshot containing the selected orbit preset,
## component rows, targets, objectives, and unit_conventions.
const Adapter = preload("res://core/HPCContractAdapter.gd")
const Planner = preload("res://core/OrbitPlanner.gd")
const MissionValidator = preload("res://scripts/core/mission_validator.gd")
const ACTIONS: Array[String] = ["observe", "transmit", "power_save"]
const ENERGY_EPSILON_WH: float = 0.000000001

static func init_run(config: Dictionary, scenario: Dictionary, run_id: String, mission_id: String) -> Dictionary:
	if run_id.strip_edges().is_empty() or mission_id.strip_edges().is_empty():
		return _error("MISSING_RUN_IDENTITY", "run_id and mission_id must be non-empty strings")
	var catalog_result: Dictionary = _catalog_from_scenario(scenario)
	if not catalog_result.ok:
		return catalog_result
	var catalog: Dictionary = catalog_result.catalog
	var resolved: Dictionary = Adapter.validate_config(config, catalog)
	if not resolved.ok:
		return _adapter_error(resolved)
	var plan: Dictionary = Planner.build_step_plan(str(config.design.orbit_id), [str(config.mission.target_region)], int(resolved.total_steps), catalog)
	if not plan.ok:
		return _error(str(plan.get("error_code", "INVALID_SCENARIO")), str(plan.get("error_message", "Could not create the mission step plan.")))
	var parts: Dictionary = resolved.parts
	var battery_capacity_wh: float = float(parts.battery.capacity_wh)
	var storage_capacity_mb: float = float(parts.storage.capacity_mb)
	var state: Dictionary = {
		"schema_version": 1,
		"run_id": run_id,
		"mission_id": mission_id,
		"scenario_id": str(config.design.orbit_id),
		"step_index": 0,
		"total_steps": int(resolved.total_steps),
		"phase": "operating",
		"run_status": null,
		"terminal_reason": null,
		"is_sunlit": false,
		"in_target_access": false,
		"in_ground_contact": false,
		"energy_wh": battery_capacity_wh * float(parts.battery.initial_charge_fraction),
		"battery_capacity_wh": battery_capacity_wh,
		"stored_data_mb": 0.0,
		"storage_capacity_mb": storage_capacity_mb,
		"returned_data_mb": 0.0,
		"observations_completed": 0,
		"available_actions": {},
		"event_log": [],
		"next_event_sequence": 0,
		"config_snapshot": config.duplicate(true),
		"scenario_snapshot": scenario.duplicate(true)
	}
	_refresh_step_context(state, plan)
	state.available_actions = _available_actions(state)
	return {"ok": true, "state": state, "events": []}

## KE1 integration entry point: evaluate readiness against the current catalog bundle,
## combine its HPC orbit_catalog, and only initialize a passing configuration.
static func init_validated_run(config: Dictionary, ke1_catalogs: Dictionary, run_id: String, mission_id: String) -> Dictionary:
	var validation_result: Dictionary = MissionValidator.validate(config, ke1_catalogs)
	if not bool(validation_result.get("ready_to_launch", false)):
		return {
			"ok": false,
			"error": {"code": "MISSION_NOT_READY", "message": "KE1 readiness checks did not approve this configuration."},
			"validation_result": validation_result
		}
	var orbit_data: Variant = ke1_catalogs.get("orbit_catalog", null)
	if not orbit_data is Dictionary:
		return _error("INVALID_ORBIT_CATALOG", "KE1 catalogs must include HPC orbit_catalog metadata")
	var scenario_result: Dictionary = Adapter.build_scenario(ke1_catalogs, orbit_data)
	if not scenario_result.get("ok", false):
		return _adapter_error(scenario_result)
	var started: Dictionary = init_run(config, scenario_result.scenario, run_id, mission_id)
	if started.get("ok", false):
		started["validation_result"] = validation_result
	return started

static func get_available_actions(state: Dictionary) -> Dictionary:
	var context_result: Dictionary = _context(state)
	if not context_result.ok:
		return context_result
	return {"ok": true, "available_actions": _available_actions(state)}

## Explicitly end an operating run while preserving its current step and resources.
static func abort_run(state: Dictionary, reason: String) -> Dictionary:
	var context_result: Dictionary = _context(state)
	if not context_result.ok:
		return context_result
	if str(state.phase) == "finished":
		return _error("MISSION_FINISHED", "A finished mission cannot be aborted again.")
	if reason.strip_edges().is_empty():
		return _error("MISSING_ABORT_REASON", "An abort reason must be a non-empty string.")
	var next_state: Dictionary = state.duplicate(true)
	var log: Array = next_state.get("event_log", []).duplicate(true)
	var sequence: int = int(next_state.get("next_event_sequence", log.size()))
	next_state.phase = "finished"
	next_state.run_status = "aborted"
	next_state.terminal_reason = reason.strip_edges()
	var event: Dictionary = _make_event(next_state, sequence, int(state.step_index), "", "mission_aborted", "MISSION_ABORTED", next_state.terminal_reason, {"terminal_reason": next_state.terminal_reason})
	log.append(event)
	next_state.event_log = log
	next_state.next_event_sequence = sequence + 1
	next_state.available_actions = _available_actions(next_state)
	return {"ok": true, "state": next_state, "events": [event]}

static func request_action(state: Dictionary, action: String) -> Dictionary:
	var context_result: Dictionary = _context(state)
	if not context_result.ok:
		return context_result
	var current_index: int = int(state.step_index)
	var decision: Dictionary = _evaluate(action, state, context_result.resolved, context_result.plan)
	var next_state: Dictionary = state.duplicate(true)
	var log: Array = next_state.get("event_log", []).duplicate(true)
	var event_sequence: int = int(next_state.get("next_event_sequence", log.size()))
	if not bool(decision.allowed):
		var blocked: Dictionary = _make_event(next_state, event_sequence, current_index, action, "action_blocked", str(decision.code), str(decision.message), {})
		log.append(blocked)
		next_state.event_log = log
		next_state.next_event_sequence = event_sequence + 1
		return {"ok": true, "allowed": false, "state": next_state, "events": [blocked]}

	var step: Dictionary = context_result.plan.steps[current_index]
	var parts: Dictionary = context_result.resolved.parts
	var step_hours: float = float(step.step_duration_hours)
	var solar_w: float = float(parts.solar.output_w) if bool(step.sunlight) else 0.0
	var load_w: float = float(parts.bus.idle_w)
	var before_energy: float = float(state.energy_wh)
	var before_stored: float = float(state.stored_data_mb)
	var before_returned: float = float(state.returned_data_mb)
	var before_observations: int = int(state.observations_completed)
	var data_added_mb: float = 0.0
	var data_transmitted_mb: float = 0.0
	if action == "observe":
		load_w += float(parts.instrument.observe_w)
		data_added_mb = float(parts.instrument.packet_mb)
	elif action == "transmit":
		load_w += float(parts.radio.transmit_w)
		var downlink_mb_per_hour: float = _downlink_rate_mb_per_hour(parts.radio)
		data_transmitted_mb = minf(before_stored, downlink_mb_per_hour * step_hours)
	# Accepted power_save uses baseline bus load. Its energy may clamp to zero by contract.
	var generated_wh: float = solar_w * step_hours
	var consumed_wh: float = load_w * step_hours
	var raw_energy: float = before_energy + generated_wh - consumed_wh
	var after_energy: float = clampf(raw_energy, 0.0, float(state.battery_capacity_wh))
	next_state.energy_wh = after_energy
	if action == "observe":
		next_state.stored_data_mb = before_stored + data_added_mb
		next_state.observations_completed = before_observations + 1
	elif action == "transmit":
		next_state.stored_data_mb = maxf(0.0, before_stored - data_transmitted_mb)
		next_state.returned_data_mb = before_returned + data_transmitted_mb
	next_state.step_index = current_index + 1
	if int(next_state.step_index) >= int(next_state.total_steps):
		next_state.step_index = int(next_state.total_steps)
		next_state.phase = "finished"
		next_state.run_status = "completed"
	_refresh_step_context(next_state, context_result.plan)
	var details: Dictionary = {
		"delta_energy_wh": after_energy - before_energy,
		"energy_change_wh": after_energy - before_energy,
		"delta_stored_data_mb": float(next_state.stored_data_mb) - before_stored,
		"delta_returned_data_mb": float(next_state.returned_data_mb) - before_returned,
		"delta_observations": int(next_state.observations_completed) - before_observations,
		"energy_generated_wh": generated_wh,
		"energy_consumed_wh": consumed_wh,
		"energy_clamped": raw_energy < 0.0 or raw_energy > float(state.battery_capacity_wh),
		"data_added_mb": data_added_mb,
		"data_transmitted_mb": data_transmitted_mb,
		"stored_data_mb": float(next_state.stored_data_mb),
		"returned_data_mb": float(next_state.returned_data_mb),
		"observations_completed": int(next_state.observations_completed)
	}
	if action == "observe":
		details.target_id = str(context_result.resolved.target_id)
	var message: String = _success_message(action, data_added_mb, data_transmitted_mb)
	var accepted: Dictionary = _make_event(next_state, event_sequence, current_index, action, "action_accepted", "ACTION_ACCEPTED", message, details)
	log.append(accepted)
	var events: Array = [accepted]
	event_sequence += 1
	if str(next_state.phase) == "finished":
		var finished: Dictionary = _make_event(next_state, event_sequence, int(next_state.step_index), "", "mission_finished", "MISSION_FINISHED", "The final mission step is complete.", {})
		log.append(finished)
		events.append(finished)
		event_sequence += 1
	next_state.event_log = log
	next_state.next_event_sequence = event_sequence
	next_state.available_actions = _available_actions(next_state)
	return {"ok": true, "allowed": true, "state": next_state, "events": events}

## Backwards-compatible candidate aliases; new callers should use the v1 methods above.
static func initialize(config: Dictionary, catalog: Dictionary) -> Dictionary:
	return init_run(config, catalog, "run_local", "mission_local")

static func execute_step(state: Dictionary, action: String, _catalog: Dictionary = {}) -> Dictionary:
	var result: Dictionary = request_action(state, action)
	if not result.get("ok", false):
		return result
	var event: Dictionary = result.events[0] if not result.events.is_empty() else {}
	return {"ok": true, "allowed": bool(result.get("allowed", false)), "reason_code": str(event.get("code", "OK")), "message": str(event.get("message", "")), "state": result.state, "event": event, "events": result.events}

static func _catalog_from_scenario(scenario: Dictionary) -> Dictionary:
	var catalog: Variant = scenario.get("catalog", scenario)
	if not catalog is Dictionary or not catalog.has("orbits") or not catalog.has("parts"):
		return _error("INVALID_SCENARIO", "scenario must be a catalog snapshot containing orbits and parts")
	return {"ok": true, "catalog": catalog}

static func _context(state: Dictionary) -> Dictionary:
	for key in ["schema_version", "run_id", "mission_id", "scenario_id", "step_index", "total_steps", "phase", "run_status", "energy_wh", "battery_capacity_wh", "stored_data_mb", "storage_capacity_mb", "returned_data_mb", "observations_completed", "config_snapshot", "scenario_snapshot"]:
		if not state.has(key):
			return _error("INVALID_MISSION_STATE", "MissionState is missing %s" % key)
	if int(state.schema_version) != 1:
		return _error("UNSUPPORTED_STATE_VERSION", "MissionState schema_version must be 1")
	if not state.run_id is String or str(state.run_id).strip_edges().is_empty() or not state.mission_id is String or str(state.mission_id).strip_edges().is_empty():
		return _error("INVALID_MISSION_STATE", "run_id and mission_id must be non-empty strings")
	for key in ["step_index", "total_steps", "observations_completed"]:
		if not Adapter._is_integer(state[key]):
			return _error("INVALID_MISSION_STATE", "MissionState.%s must be a nonnegative integer" % key)
	for key in ["energy_wh", "battery_capacity_wh", "stored_data_mb", "storage_capacity_mb", "returned_data_mb"]:
		if not Adapter._is_number(state[key]):
			return _error("INVALID_MISSION_STATE", "MissionState.%s must be finite" % key)
	if float(state.energy_wh) < 0.0 or float(state.energy_wh) > float(state.battery_capacity_wh) or float(state.stored_data_mb) < 0.0 or float(state.stored_data_mb) > float(state.storage_capacity_mb) or float(state.returned_data_mb) < 0.0:
		return _error("INVALID_MISSION_STATE", "MissionState resource values are outside valid bounds")
	if not state.scenario_snapshot is Dictionary:
		return _error("INVALID_MISSION_STATE", "scenario_snapshot must be an object")
	var catalog_result: Dictionary = _catalog_from_scenario(state.scenario_snapshot)
	if not catalog_result.ok:
		return catalog_result
	var catalog: Dictionary = catalog_result.catalog
	if not state.config_snapshot is Dictionary:
		return _error("INVALID_MISSION_STATE", "config_snapshot must be an object")
	var config: Dictionary = state.config_snapshot
	var resolved: Dictionary = Adapter.validate_config(config, catalog)
	if not resolved.ok:
		return _adapter_error(resolved)
	var index: int = int(state.step_index)
	if index < 0 or index > int(state.total_steps) or int(state.total_steps) != int(resolved.total_steps) or str(state.scenario_id) != str(config.design.orbit_id):
		return _error("INVALID_MISSION_STATE", "step_index, total_steps, or scenario_id is inconsistent with the run snapshot")
	var status: String = str(state.run_status) if state.run_status != null else ""
	var expected_phase: String = "operating" if state.run_status == null else "finished"
	if str(state.phase) != expected_phase:
		return _error("INVALID_MISSION_STATE", "phase or run_status is inconsistent with step_index")
	if expected_phase == "operating" and index >= int(state.total_steps):
		return _error("INVALID_MISSION_STATE", "An operating run must have a step_index below total_steps")
	if status == "completed" and index != int(state.total_steps):
		return _error("INVALID_MISSION_STATE", "A completed run must be at total_steps")
	if status == "aborted" and index >= int(state.total_steps):
		return _error("INVALID_MISSION_STATE", "An aborted run must preserve a step below total_steps")
	if status == "aborted" and (not state.get("terminal_reason", null) is String or str(state.terminal_reason).strip_edges().is_empty()):
		return _error("INVALID_MISSION_STATE", "An aborted run must include terminal_reason")
	if expected_phase == "finished" and not ["completed", "aborted"].has(status):
		return _error("INVALID_MISSION_STATE", "Finished run_status must be completed or aborted")
	if expected_phase == "operating" and state.run_status != null:
		return _error("INVALID_MISSION_STATE", "Operating run_status must be null")
	var plan: Dictionary = Planner.build_step_plan(str(config.design.orbit_id), [str(config.mission.target_region)], int(state.total_steps), catalog)
	if not plan.ok:
		return _error(str(plan.get("error_code", "INVALID_SCENARIO")), str(plan.get("error_message", "Could not rebuild the step plan.")))
	return {"ok": true, "catalog": catalog, "resolved": resolved, "plan": plan}

static func _evaluate(action: String, state: Dictionary, resolved: Dictionary, plan: Dictionary) -> Dictionary:
	if not ACTIONS.has(action):
		return _blocked("INVALID_ACTION", "Choose observe, transmit, or power_save.")
	if str(state.phase) == "finished":
		return _blocked("MISSION_FINISHED", "No action is available because the mission has finished.")
	var step: Dictionary = plan.steps[int(state.step_index)]
	var parts: Dictionary = resolved.parts
	if action == "observe":
		if not step.target_windows.has(str(resolved.target_id)):
			return _blocked("TARGET_NOT_VISIBLE", "The selected target is not visible during this step.")
		if int(state.observations_completed) >= int(resolved.observations_required):
			return _blocked("OBSERVATION_LIMIT_REACHED", "The required observation count has already been reached.")
		if bool(parts.instrument.get("requires_sunlight", false)) and not bool(step.sunlight):
			return _blocked("NO_SUNLIGHT", "The selected instrument requires sunlight during this step.")
		var packet_mb: float = float(parts.instrument.packet_mb)
		if float(state.stored_data_mb) + packet_mb > float(state.storage_capacity_mb):
			return _blocked("STORAGE_FULL", "The observation packet will not fit in remaining storage.")
	elif action == "transmit":
		if not bool(step.contact):
			return _blocked("NO_LINK_WINDOW", "No ground station contact window is available during this step.")
		if float(state.stored_data_mb) <= 0.0:
			return _blocked("NO_DATA", "There is no stored data to transmit.")
	var action_load_w: float = 0.0
	if action == "observe":
		action_load_w = float(parts.instrument.observe_w)
	elif action == "transmit":
		action_load_w = float(parts.radio.transmit_w)
	var load_w: float = float(parts.bus.idle_w) + action_load_w
	var solar_w: float = float(parts.solar.output_w) if bool(step.sunlight) else 0.0
	var after_energy: float = float(state.energy_wh) + (solar_w - load_w) * float(step.step_duration_hours)
	if action != "power_save" and after_energy < -ENERGY_EPSILON_WH:
		return _blocked("LOW_BATTERY", "Battery energy is insufficient to complete this action and step.")
	# power_save is always available while operating; accepted action clamps at 0 Wh.
	return {"allowed": true, "code": "OK", "message": "Action is available."}

static func _available_actions(state: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var context_result: Dictionary = _context(state)
	if not context_result.ok:
		for action in ACTIONS:
			result[action] = {"allowed": false, "blocked_code": "INVALID_MISSION_STATE", "reason": "Mission state is invalid."}
		return result
	for action in ACTIONS:
		var decision: Dictionary = _evaluate(action, state, context_result.resolved, context_result.plan)
		result[action] = {"allowed": bool(decision.allowed), "blocked_code": null if decision.allowed else str(decision.code), "reason": null if decision.allowed else str(decision.message)}
	return result

static func _refresh_step_context(state: Dictionary, plan: Dictionary) -> void:
	var index: int = int(state.step_index)
	if index >= int(state.total_steps):
		state.is_sunlit = false
		state.in_target_access = false
		state.in_ground_contact = false
		return
	var step: Dictionary = plan.steps[index]
	var target_id: String = str(state.config_snapshot.mission.target_region)
	state.is_sunlit = bool(step.sunlight)
	state.in_target_access = step.target_windows.has(target_id)
	state.in_ground_contact = bool(step.contact)

static func _downlink_rate_mb_per_hour(radio: Dictionary) -> float:
	return float(radio.downlink_mb_per_hour)

static func _make_event(state: Dictionary, sequence: int, step_index: int, action: String, event_type: String, code: String, message: String, details: Dictionary) -> Dictionary:
	var event: Dictionary = {
		"event_id": "evt_%03d" % sequence,
		"run_id": str(state.run_id),
		"mission_id": str(state.mission_id),
		"step_index": step_index,
		"action": action,
		"type": event_type,
		"code": code,
		"message": message,
		"delta_energy_wh": 0.0,
		"delta_stored_data_mb": 0.0,
		"delta_returned_data_mb": 0.0,
		"delta_observations": 0
	}
	for key in details:
		event[key] = details[key]
	return event

static func _success_message(action: String, data_added_mb: float, data_transmitted_mb: float) -> String:
	if action == "observe":
		return "Observation captured; %.3f MB stored." % data_added_mb
	if action == "transmit":
		return "Ground station received %.3f MB." % data_transmitted_mb
	return "Power-save step completed using baseline bus load."

static func _blocked(code: String, message: String) -> Dictionary:
	return {"allowed": false, "code": code, "message": message}

static func _adapter_error(result: Dictionary) -> Dictionary:
	return _error(str(result.get("error_code", "INVALID_CONFIG")), str(result.get("error_message", "Mission configuration is invalid.")))

static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "error": {"code": code, "message": message}}
