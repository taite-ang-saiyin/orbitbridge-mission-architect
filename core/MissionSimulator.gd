extends RefCounted
class_name MissionSimulator

## Pure fixed-slot simulation for a validated, immutable proposal RunInput.
const MODEL_VERSION: String = "slots-1"
const OrbitPlannerScript = preload("res://core/OrbitPlanner.gd")
const Adapter = preload("res://core/HPCContractAdapter.gd")
const StepEngine = preload("res://core/MissionStepEngine.gd")

static func simulate(run_input: Dictionary, catalog: Dictionary) -> Dictionary:
	if int(run_input.get("schema_version", 0)) == 2:
		return _simulate_v2(run_input, catalog)
	var plan: Dictionary = OrbitPlannerScript.build_plan(run_input, catalog)
	if not plan.get("ok", false):
		return {"ok": false, "error": str(plan.get("error", "planning failed"))}
	var setup: Dictionary = _resolve(run_input, catalog)
	if not setup.get("ok", false):
		return {"ok": false, "error": str(setup.get("error", "invalid input"))}
	var input_snapshot: Dictionary = run_input.duplicate(true)
	var s: Dictionary = {
		"battery_ws": int(setup.battery.capacity_ws),
		"minimum_battery_ws": int(setup.battery.capacity_ws),
		"captured": 0, "delivered": 0, "delivered_by_target": {},
		"returned_kb": 0, "buffer_kb": 0, "peak_buffer_kb": 0,
		"queue": [], "events": [], "telemetry": [], "seq": 0,
		"status": "completed", "completed_slots": 0, "current_slot": -1, "elapsed_t_s": 0
	}
	var target_ids: Array[String] = []
	for target_id in setup.brief.target_ids:
		target_ids.append(str(target_id))
	target_ids.sort()
	_emit(s, -1, 0, "LAUNCH", {"orbit_id": setup.design.orbit_id})
	_emit(s, -1, 0, "DEPLOY", {"status": "deployed"})
	for slot_data in plan.slots:
		var slot_index: int = int(slot_data.slot)
		var t_s: int = int(slot_data.t_s)
		var eligible_targets: Array[String] = []
		var instrument: Dictionary = setup.instrument
		if int(s.captured) < int(setup.brief.required_obs):
			var sun_ok: bool = not bool(instrument.get("requires_sunlight", false)) or bool(slot_data.sunlight)
			if sun_ok:
				for target_id in target_ids:
					if slot_data.target_windows.has(target_id):
						eligible_targets.append(str(target_id))
		eligible_targets.sort_custom(func(a: String, b: String) -> bool:
			var a_count: int = int(s.delivered_by_target.get(a, 0)) + _queued_count(s.queue, a)
			var b_count: int = int(s.delivered_by_target.get(b, 0)) + _queued_count(s.queue, b)
			return a_count < b_count if a_count != b_count else a < b
		)
		var remaining_captures: int = int(setup.brief.required_obs) - int(s.captured)
		var unseen_targets: Array[String] = []
		for target_id in target_ids:
			var count_for_target: int = int(s.delivered_by_target.get(target_id, 0)) + _queued_count(s.queue, target_id)
			if count_for_target < int(setup.per_target_min):
				unseen_targets.append(str(target_id))
		if not unseen_targets.is_empty() and remaining_captures <= unseen_targets.size():
			var reserved_targets: Array[String] = []
			for target_id in eligible_targets:
				if unseen_targets.has(target_id):
					reserved_targets.append(target_id)
			eligible_targets = reserved_targets
		var can_observe: bool = not eligible_targets.is_empty()
		var can_transmit: bool = bool(slot_data.contact) and int(s.buffer_kb) > 0
		var operations: Array = ["observe", "transmit"] if str(setup.design.policy) == "observe_first" else ["transmit", "observe"]
		var selected_action: String = "idle"
		var chosen_target: String = ""
		var skip_power: Array[String] = []
		for operation in operations:
			if operation == "observe":
				if not can_observe:
					continue
				var packet_kb: int = int(instrument.packet_kb)
				if int(s.buffer_kb) + packet_kb > int(setup.storage.capacity_kb):
					_emit(s, slot_index, t_s, "SKIP_STORAGE", {"target_id": eligible_targets[0], "packet_kb": packet_kb, "buffer_kb": s.buffer_kb, "capacity_kb": setup.storage.capacity_kb})
					continue
				var observe_w: int = int(instrument.observe_w)
				if _trial_battery(s, slot_data, setup.bus, setup.solar, observe_w) < 0:
					_emit(s, slot_index, t_s, "SKIP_POWER", {"action": "observe", "required_w": int(setup.bus.idle_w) + observe_w})
					skip_power.append("observe")
					continue
				selected_action = "observe"
				chosen_target = eligible_targets[0]
				break
			elif operation == "transmit":
				if not can_transmit:
					continue
				var transmit_w: int = int(setup.radio.transmit_w)
				if _trial_battery(s, slot_data, setup.bus, setup.solar, transmit_w) < 0:
					_emit(s, slot_index, t_s, "SKIP_POWER", {"action": "transmit", "required_w": int(setup.bus.idle_w) + transmit_w})
					skip_power.append("transmit")
					continue
				selected_action = "transmit"
				break
		var action_w: int = 0
		if selected_action == "observe":
			action_w = int(instrument.observe_w)
		elif selected_action == "transmit":
			action_w = int(setup.radio.transmit_w)
		var trial_energy_ws: int = _trial_battery(s, slot_data, setup.bus, setup.solar, action_w)
		if trial_energy_ws < 0:
			# Only idle remained and its load cannot be paid. Preserve buffer and stop.
			s.battery_ws = 0
			s.minimum_battery_ws = 0
			s.status = "depleted"
			_emit(s, slot_index, t_s, "POWER_DEPLETED", {"remaining_battery_ws": 0, "buffer_kb": s.buffer_kb})
			_emit(s, slot_index, t_s, "SLOT_STATE", _slot_params(slot_data, s, "depleted"))
			s.telemetry.append(_telemetry(slot_data, s))
			s.completed_slots += 1
			s.current_slot = slot_index
			s.elapsed_t_s = t_s
			break
		s.battery_ws = mini(int(setup.battery.capacity_ws), trial_energy_ws)
		if selected_action == "observe":
			s.captured += 1
			var observation_id: String = "obs_%03d" % int(s.captured)
			var packet: Dictionary = {"observation_id": observation_id, "target_id": chosen_target, "packet_kb": int(instrument.packet_kb), "remaining_kb": int(instrument.packet_kb)}
			s.queue.append(packet)
			s.buffer_kb += int(instrument.packet_kb)
			s.peak_buffer_kb = maxi(int(s.peak_buffer_kb), int(s.buffer_kb))
			_emit(s, slot_index, t_s, "OBSERVE", {"observation_id": observation_id, "target_id": chosen_target, "packet_kb": packet.packet_kb})
		elif selected_action == "transmit":
			_transmit(s, slot_data, setup.radio)
		s.minimum_battery_ws = mini(int(s.minimum_battery_ws), int(s.battery_ws))
		_emit(s, slot_index, t_s, "SLOT_STATE", _slot_params(slot_data, s, selected_action))
		s.telemetry.append(_telemetry(slot_data, s))
		s.completed_slots += 1
		s.current_slot = slot_index
		s.elapsed_t_s = t_s
	var metrics: Dictionary = {
		"deployed": true,
		"captured": int(s.captured),
		"delivered": int(s.delivered),
		"delivered_by_target": s.delivered_by_target,
		"returned_kb": int(s.returned_kb),
		"min_battery_ws": int(s.minimum_battery_ws),
		"peak_buffer_kb": int(s.peak_buffer_kb),
		"cost_cr": int(setup.cost_cr),
		"mass_kg": int(setup.mass_kg),
		"buffer_kb": int(s.buffer_kb),
		"final_battery_ws": int(s.battery_ws)
	}
	return {
		"ok": true,
		"model_version": MODEL_VERSION,
		"run_input": input_snapshot,
		"status": s.status,
		"slot_count": s.completed_slots,
		"orbit_period_s": plan.orbit_period_s,
		"slot_seconds": plan.slot_seconds,
		"metrics": metrics,
		"state": {"current_slot": s.current_slot, "elapsed_t_s": s.elapsed_t_s, "battery_ws": s.battery_ws, "minimum_battery_ws": s.minimum_battery_ws, "captured": s.captured, "delivered": s.delivered, "delivered_by_target": s.delivered_by_target, "returned_kb": s.returned_kb, "buffer_kb": s.buffer_kb, "peak_buffer_kb": s.peak_buffer_kb, "packet_queue": s.queue, "launch_status": "launched", "deployment_status": "deployed"},
		"events": s.events,
		"telemetry": s.telemetry
	}

static func _simulate_v2(config: Dictionary, catalog_input: Dictionary) -> Dictionary:
	var scenario: Dictionary
	if catalog_input.get("orbits") is Array and catalog_input.get("parts") is Array:
		scenario = catalog_input.duplicate(true)
	elif catalog_input.get("orbit_catalog") is Dictionary:
		var built: Dictionary = Adapter.build_scenario(catalog_input, catalog_input.orbit_catalog)
		if not built.get("ok", false):
			return {"ok": false, "error": built.get("error_message", "Could not build the v2 scenario snapshot.")}
		scenario = built.scenario
	else:
		return {"ok": false, "error": "schema_version 2 requires a native scenario or catalog bundle"}
	var run_id: String = str(config.get("run_id", "sim_v2_" + str(config.get("preset_id", "mission"))))
	var mission_id: String = str(config.get("mission_id", "mission_v2_" + str(config.get("preset_id", "mission"))))
	var started: Dictionary = StepEngine.init_run(config, scenario, run_id, mission_id)
	if not started.get("ok", false):
		return started
	var state: Dictionary = started.state
	var frames: Array = [{"state": state.duplicate(true), "events": []}]
	while state.phase == "operating":
		var action: String = _v2_action(state)
		var reply: Dictionary = StepEngine.request_action(state, action)
		if not reply.get("ok", false):
			return reply
		if not reply.get("allowed", false):
			reply = StepEngine.request_action(state, "power_save")
			if not reply.get("ok", false) or not reply.get("allowed", false):
				return {"ok": false, "error": "v2 simulator could not advance blocked step"}
		state = reply.state
		frames.append({"state": state.duplicate(true), "events": reply.events.duplicate(true)})
	return {
		"ok": true,
		"schema_version": 2,
		"model_version": "native-v2",
		"run_input": config.duplicate(true),
		"config_snapshot": state.config_snapshot.duplicate(true),
		"scenario_snapshot": state.scenario_snapshot.duplicate(true),
		"catalog_context": state.get("catalog_context", scenario).duplicate(true),
		"status": state.run_status,
		"slot_count": state.total_steps,
		"metrics": {
			"goal_type": state.goal_progress.kind,
			"actual_count": state.goal_progress.actual_count,
			"required_count": state.goal_progress.required_count,
			"returned_data_mb": state.returned_data_mb,
			"stored_data_mb": state.stored_data_mb,
			"evidence_event_ids": state.goal_progress.evidence_event_ids.duplicate(),
			"goal_evidence": state.goal_evidence.duplicate(true)
		},
		"state": state.duplicate(true),
		"final_state": state.duplicate(true),
		"events": state.event_log.duplicate(true),
		"frames": frames
	}

static func _v2_action(state: Dictionary) -> String:
	var available: Dictionary = state.get("available_actions", {})
	var objective: String = str(state.get("goal_kind", ""))
	var transmit: Dictionary = available.get("transmit", {})
	var observe: Dictionary = available.get("observe", {})
	if objective == "communication" and bool(transmit.get("allowed", false)):
		return "transmit"
	var progress: Dictionary = state.get("goal_progress", {})
	if objective == "weather_monitoring" and int(progress.get("actual_count", 0)) < int(progress.get("required_count", 0)) and bool(observe.get("allowed", false)):
		return "observe"
	if bool(observe.get("allowed", false)):
		return "observe"
	if bool(transmit.get("allowed", false)):
		return "transmit"
	return "power_save"

static func _resolve(input: Dictionary, catalog: Dictionary) -> Dictionary:
	var brief: Dictionary = input.get("brief", {})
	var design: Dictionary = input.get("design", {})
	for key in ["objective_id", "required_obs", "duration_orbits", "target_ids"]:
		if not brief.has(key):
			return {"ok": false, "error": "RunInput brief missing %s" % key}
	for key in ["instrument_id", "bus_id", "battery_id", "solar_id", "storage_id", "radio_id", "launcher_id", "orbit_id", "policy"]:
		if not design.has(key):
			return {"ok": false, "error": "RunInput design missing %s" % key}
	if not (brief.target_ids is Array) or brief.target_ids.is_empty():
		return {"ok": false, "error": "brief.target_ids must be a non-empty array"}
	if int(brief.required_obs) <= 0 or str(design.policy) not in ["observe_first", "downlink_first"]:
		return {"ok": false, "error": "brief count or policy is invalid"}
	var part_rows: Array = catalog.get("parts", [])
	var objective: Dictionary = _find(catalog.get("objectives", []), str(brief.objective_id), "")
	var bus: Dictionary = _find(part_rows, str(design.bus_id), "bus")
	var instrument: Dictionary = _find(part_rows, str(design.instrument_id), "instrument")
	var battery: Dictionary = _find(part_rows, str(design.battery_id), "battery")
	var solar: Dictionary = _find(part_rows, str(design.solar_id), "solar")
	var storage: Dictionary = _find(part_rows, str(design.storage_id), "storage")
	var radio: Dictionary = _find(part_rows, str(design.radio_id), "radio")
	var launcher: Dictionary = _find(catalog.get("launchers", []), str(design.launcher_id), "")
	var missing: Array[String] = []
	for part in [bus, instrument, battery, solar, storage, radio, launcher]:
		if part.is_empty():
			missing.append("missing or mismatched part ID")
	if not missing.is_empty():
		return {"ok": false, "error": missing[0]}
	for target_id in brief.target_ids:
		if _find(catalog.get("targets", []), str(target_id), "").is_empty():
			return {"ok": false, "error": "unknown target ID: %s" % target_id}
	for required_key in [[battery, "capacity_ws"], [storage, "capacity_kb"], [instrument, "packet_kb"], [instrument, "observe_w"], [radio, "rate_kb_s"], [radio, "transmit_w"], [solar, "output_w"], [bus, "idle_w"]]:
		if not required_key[0].has(required_key[1]):
			return {"ok": false, "error": "catalog part missing %s" % required_key[1]}
	if int(battery.capacity_ws) <= 0 or int(storage.capacity_kb) <= 0 or int(instrument.packet_kb) <= 0 or int(radio.rate_kb_s) <= 0:
		return {"ok": false, "error": "part capacity, packet size, and rate must be positive"}
	var cost_cr: int = int(launcher.get("cost_cr", 0))
	var mass_kg: int = 0
	for part in [bus, instrument, battery, solar, storage, radio]:
		cost_cr += int(part.get("cost_cr", 0))
		mass_kg += int(part.get("mass_kg", 0))
	return {"ok": true, "brief": brief, "design": design, "bus": bus, "instrument": instrument, "battery": battery, "solar": solar, "storage": storage, "radio": radio, "launcher": launcher, "per_target_min": int(objective.get("per_target_min", 0)), "cost_cr": cost_cr, "mass_kg": mass_kg}

static func _find(rows: Variant, id: String, kind: String) -> Dictionary:
	if rows is Array:
		for row in rows:
			if row is Dictionary and str(row.get("id", "")) == id and (kind == "" or str(row.get("kind", "")) == kind):
				return row
	elif rows is Dictionary:
		var value: Variant = rows.get(id, {})
		if value is Dictionary and (kind == "" or str(value.get("kind", kind)) == kind):
			return value
	return {}

static func _trial_battery(state: Dictionary, slot_data: Dictionary, bus: Dictionary, solar: Dictionary, action_w: int) -> int:
	var generation_w: int = 0
	if bool(slot_data.sunlight):
		generation_w = int(solar.output_w)
	return int(state.battery_ws) + (generation_w - int(bus.idle_w) - action_w) * int(slot_data.slot_seconds)

static func _transmit(state: Dictionary, slot_data: Dictionary, radio: Dictionary) -> void:
	var remaining_kb: int = mini(int(state.buffer_kb), int(radio.rate_kb_s) * int(slot_data.slot_seconds))
	var sent_kb: int = remaining_kb
	var delivered_now: int = 0
	var delivered_targets: Array[String] = []
	while remaining_kb > 0 and not state.queue.is_empty():
		var packet: Dictionary = state.queue[0]
		var packet_send: int = mini(remaining_kb, int(packet.remaining_kb))
		packet.remaining_kb -= packet_send
		remaining_kb -= packet_send
		state.buffer_kb -= packet_send
		state.returned_kb += packet_send
		if int(packet.remaining_kb) == 0:
			state.delivered += 1
			delivered_now += 1
			var target_id: String = str(packet.target_id)
			state.delivered_by_target[target_id] = int(state.delivered_by_target.get(target_id, 0)) + 1
			delivered_targets.append(target_id)
			state.queue.pop_front()
	_emit(state, int(slot_data.slot), int(slot_data.t_s), "TX", {"sent_kb": sent_kb, "buffer_kb": state.buffer_kb, "delivered_now": delivered_now, "delivered_targets": delivered_targets})

static func _queued_count(queue: Array, target_id: String) -> int:
	var count: int = 0
	for packet in queue:
		if str(packet.target_id) == target_id:
			count += 1
	return count

static func _slot_params(slot_data: Dictionary, state: Dictionary, action: String) -> Dictionary:
	return {"battery_ws": state.battery_ws, "buffer_kb": state.buffer_kb, "captured": state.captured, "delivered": state.delivered, "sunlight": slot_data.sunlight, "contact": slot_data.contact, "target_windows": slot_data.target_windows, "action": action}

static func _telemetry(slot_data: Dictionary, state: Dictionary) -> Dictionary:
	return {"slot": slot_data.slot, "t_s": slot_data.t_s, "battery_ws": state.battery_ws, "buffer_kb": state.buffer_kb, "captured": state.captured, "delivered": state.delivered}

static func _emit(state: Dictionary, slot_index: int, t_s: int, code: String, params: Dictionary) -> void:
	state.events.append({"seq": state.seq, "slot": slot_index, "t_s": t_s, "code": code, "params": params.duplicate(true)})
	state.seq += 1
