extends SceneTree
## KE1-only feasibility audit. Not a runtime policy, report, or new-goal evaluator.
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Steps = preload("res://core/MissionStepEngine.gd")
const Catalog = preload("res://data/mock/DesignCatalog.gd")
const EXAMPLES = "res://docs/ke1-expansion/examples"
var passed: int = 0
var failed: int = 0
var output: String
var evidence: Dictionary = {
	"base_main": "dce75db845f6c494b8c25c9028dd9c0648aabd91",
	"date": "2026-11-15", "status": "FEASIBILITY_MEASURED_OWNER_CONFIRMATION_PENDING",
	"official_new_goal_score": null, "new_objectives_enabled": false,
	"notice": "Supported v1 Imaging surrogates only. Diagnostics are not KE2 evaluation or HPC policy approval.",
	"cases": {}, "checks": []}
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	evidence.checks.append({"label": label, "passed": value})
	if value: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)
func read_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))
func normalized(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value))
func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("Pass an output directory after --. This audit writes trace evidence there.")
		quit(1); return
	output = args[0]
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		printerr("Cannot create evidence directory."); quit(1); return
	evidence.godot_version = Engine.get_version_info().string
	var loaded: Dictionary = Runtime.load_game_catalogs()
	check(loaded.ok, "Current active runtime catalogs load")
	if not loaded.ok: finish(); return
	var plans: Dictionary = read_json(EXAMPLES.path_join("k24-k25-action-plans.json"))
	for plan in plans.cases:
		# Godot parses JSON numbers as floats; normalize step lists before membership checks.
		for key in ["observe_steps", "transmit_steps"]:
			if plan.has(key): plan[key] = plan[key].map(func(value): return int(value))
		var config: Dictionary = read_json(EXAMPLES.path_join(plan.config_file))
		for key in ["required_observations", "required_returned_data_mb", "target_regions"]:
			if plan.has(key): config.mission[key] = plan[key]
		for key in ["orbit_id", "radio_id"]:
			if plan.has(key): config.design[key] = plan[key]
		var before_config: String = JSON.stringify(config)
		var before_catalogs: String = JSON.stringify(loaded.catalogs)
		var validation: Dictionary = Validator.validate(config, loaded.catalogs)
		check(validation.ready_to_launch and validation.checks.size() == 8, plan.id + ": all eight existing readiness checks pass")
		check(config.schema_version == 1 and config.mission.objective == "imaging", plan.id + ": explicitly a legacy Imaging diagnostic")
		if not validation.ready_to_launch: continue
		var trace: Dictionary = simulate(config, loaded.catalogs, plan)
		check(trace.get("ok", false), plan.id + ": engine trace completed")
		if not trace.get("ok", false): continue
		check(before_config == JSON.stringify(config) and before_catalogs == JSON.stringify(loaded.catalogs), plan.id + ": input config and shared catalogs unchanged")
		check(trace.final_state.run_status == "completed" and trace.final_state.step_index == trace.final_state.total_steps, plan.id + ": completed exactly at configured step bound")
		var orbit: Dictionary = {}
		for row in trace.final_state.scenario_snapshot.orbits:
			if row.id == config.design.orbit_id: orbit = row
		check(not orbit.is_empty(), plan.id + ": timing read from frozen scenario")
		if orbit.is_empty(): continue
		var measured: Dictionary = measure(trace.events, trace.final_state.run_id, config.mission.target_region, int(orbit.steps_per_orbit), int(trace.final_state.total_steps))
		check(normalized(measured.positive_transmit_steps) == plan.expected.positive_steps, plan.id + ": exact positive contact steps")
		check(normalized(measured.observed_orbit_indices) == plan.expected.visit_orbits, plan.id + ": exact selected-target orbit visits")
		check(absf(measured.returned_mb - float(plan.expected.returned_mb)) < 0.000001, plan.id + ": expected returned MB")
		check(absf(measured.returned_mb - float(trace.final_state.returned_data_mb)) < 0.000001, plan.id + ": event MB agrees with final state")
		check(measured.accepted_observations == trace.final_state.observations_completed, plan.id + ": event capture total agrees with final state")
		if plan.id == "weather_revisit_complete_delivery":
			check(trace.final_state.observations_delivered_by_target.get("equator", 0) == 2 and trace.final_state.data_packets.is_empty(), "Weather complete-return variant delivers both selected-target packets")
		var count_met: bool = measured.positive_transmit_steps.size() >= 2 if plan.goal_family == "communication" else measured.observed_orbit_indices.size() >= 2
		var data_met: bool = measured.returned_mb + 0.00000001 >= float(config.mission.required_returned_data_mb)
		check(count_met == plan.expected.count_met and data_met == plan.expected.data_met, plan.id + ": count and MB requirements checked separately")
		check(normalized(trace.final_state.config_snapshot) == normalized(config), plan.id + ": frozen config remains exact")
		var minimum_energy: float = float(trace.final_state.battery_capacity_wh)
		for frame in trace.telemetry:
			minimum_energy = minf(minimum_energy, float(frame.energy_wh))
			check(frame.energy_wh >= 0 and frame.energy_wh <= trace.final_state.battery_capacity_wh and frame.stored_data_mb >= 0 and frame.stored_data_mb <= trace.final_state.storage_capacity_mb, plan.id + ": resources bounded at step " + str(frame.step_index))
		var repeated: Dictionary = simulate(config, loaded.catalogs, plan)
		if plan.has("runtime_policy"):
			# Runtime owns fresh run IDs. Compare physics and ordered events after identity removal.
			check(physics_signature(trace) == physics_signature(repeated), plan.id + ": repeated runtime policy has identical physics")
		else:
			check(trace == repeated, plan.id + ": exact deterministic replay including events")
		var repeated_events: Array = trace.events.duplicate(true)
		repeated_events.append_array(trace.events.duplicate(true))
		var duplicate_result: Dictionary = measure(repeated_events, trace.final_state.run_id, config.mission.target_region, int(orbit.steps_per_orbit), int(trace.final_state.total_steps))
		check(measured == duplicate_result, plan.id + ": duplicate evidence cannot increase counts or MB")
		var foreign_events: Array = trace.events.duplicate(true)
		for event in trace.events:
			var other: Dictionary = event.duplicate(true); other.run_id = "another_run"
			foreign_events.append(other)
		check(measured == measure(foreign_events, trace.final_state.run_id, config.mission.target_region, int(orbit.steps_per_orbit), int(trace.final_state.total_steps)), plan.id + ": events from another run do not count")
		trace.erase("ok")
		trace.diagnostic_only = true
		trace.intended_goal_family = plan.goal_family
		trace.diagnostic_requirements = {"selected_target": config.mission.target_region, "required_distinct_count": 2, "required_returned_data_mb": config.mission.required_returned_data_mb}
		trace.measurements = measured
		trace.official_new_goal_score = null
		write_json(output.path_join(plan.id + ".json"), trace)
		evidence.cases[plan.id] = {"trace_file": plan.id + ".json", "config": config, "readiness": validation, "measurements": measured,
			"count_met": count_met, "data_met": data_met, "diagnostic_both_met": count_met and data_met,
			"minimum_energy_wh": minimum_energy, "steps_per_orbit": orbit.steps_per_orbit, "step_duration_hours": orbit.step_duration_hours,
			"contact_windows": orbit.ground_contact_windows, "target_windows": orbit.target_windows[config.mission.target_region],
			"blocked_attempts": trace.blocked_attempts, "official_new_goal_score": null}
	check(evidence.cases.size() == 11, "All eleven feasibility/control traces recorded")
	finish()
func simulate(config: Dictionary, catalogs: Dictionary, plan: Dictionary) -> Dictionary:
	if plan.has("runtime_policy"): return runtime_trace(config, plan)
	var started: Dictionary = Steps.init_validated_run(config, catalogs, "run_" + plan.id, "mission_k24_k25_audit")
	if not started.get("ok", false): return started
	var state: Dictionary = started.state
	var telemetry: Array = [sample_state(state)]
	var blocked: Array = []
	for guard in range(int(state.total_steps) + 1):
		if state.phase == "finished": break
		var step: int = int(state.step_index)
		var probes: Dictionary = plan.get("blocked_probes", {})
		if probes.has(str(step)):
			for attempt in 2:
				var probe: Dictionary = request_checked(state, probes[str(step)], plan.id)
				if not probe.get("ok", false): return probe
				check(not probe.allowed, plan.id + ": no-data/off-window probe is rejected")
				blocked.append(probe.events[0]); state = probe.state
		var action: String = "power_save"
		if step in plan.get("observe_steps", []): action = "observe"
		elif step in plan.get("transmit_steps", []): action = "transmit"
		var reply: Dictionary = request_checked(state, action, plan.id)
		if not reply.get("ok", false): return reply
		state = reply.state
		if not reply.allowed:
			blocked.append(reply.events[0])
			reply = request_checked(state, "power_save", plan.id)
			if not reply.get("ok", false): return reply
			state = reply.state
		check(state.step_index == step + 1, plan.id + ": exactly one accepted step advances time")
		telemetry.append(sample_state(state))
	return {"ok": state.phase == "finished", "config": config.duplicate(true), "final_state": state, "events": state.event_log.duplicate(true), "telemetry": telemetry, "blocked_attempts": blocked, "plan": plan.duplicate(true)}
func request_checked(state: Dictionary, action: String, label: String) -> Dictionary:
	var before: String = JSON.stringify(state)
	var reply: Dictionary = Steps.request_action(state, action)
	check(before == JSON.stringify(state), label + ": request leaves input state unchanged")
	if not reply.get("ok", false): return reply
	if not reply.allowed:
		for field in ["step_index", "energy_wh", "stored_data_mb", "returned_data_mb", "observations_completed", "data_packets"]:
			check(reply.state[field] == state[field], label + ": blocked action preserves " + field)
		check(reply.events[0].type == "action_blocked" and reply.events[0].delta_returned_data_mb == 0, label + ": rejected attempt has no positive data")
	return reply
func runtime_trace(config: Dictionary, plan: Dictionary) -> Dictionary:
	var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
	draft.name = config.mission.title; draft.targets = ["Equator"]; draft.target = "Equator"; draft.target_limit = 1
	draft.objective = "Capture Imagery"; draft.observations = config.mission.required_observations
	draft.required_returned_data_mb = config.mission.required_returned_data_mb
	draft.duration = config.mission.duration_orbits; draft.budget = config.mission.budget_credits
	draft.orbit = "Polar – 600 km"; draft.policy = plan.runtime_policy
	var launched: Dictionary = Runtime.launch(draft)
	if not launched.get("ok", false): return launched
	check(normalized(launched.trace.config) == normalized(config), plan.id + ": real runtime produces the exact training config")
	var trace: Dictionary = launched.trace
	var telemetry: Array = []
	for frame in trace.frames: telemetry.append(sample_state(frame.state))
	return {"ok": true, "config": trace.config, "final_state": trace.final_state, "events": trace.events, "telemetry": telemetry, "blocked_attempts": [], "plan": plan.duplicate(true)}
func sample_state(state: Dictionary) -> Dictionary:
	return {"step_index": state.step_index, "energy_wh": state.energy_wh, "stored_data_mb": state.stored_data_mb, "returned_data_mb": state.returned_data_mb, "observations_completed": state.observations_completed}
func physics_signature(trace: Dictionary) -> Dictionary:
	var events: Array = trace.events.duplicate(true)
	for event in events:
		event.erase("run_id"); event.erase("mission_id")
	return {"events": events, "telemetry": trace.telemetry, "config": trace.config}
func measure(events: Array, run_id: String, selected_target: String, steps_per_orbit: int, total_steps: int) -> Dictionary:
	# Offline count extraction only. KE2 still owns production evidence validation/scoring.
	var contacts: Array = []; var captures: Array = []; var orbits: Array = []
	var seen_steps: Array = []; var returned: float = 0.0; var accepted_observations: int = 0
	for event in events:
		if event.get("run_id") != run_id or event.get("type") != "action_accepted": continue
		var step: int = int(event.step_index)
		if step < 0 or step >= total_steps or step in seen_steps: continue
		seen_steps.append(step)
		if event.action == "transmit" and float(event.delta_returned_data_mb) > 0:
			contacts.append(step); returned += float(event.delta_returned_data_mb)
		if event.action == "observe" and int(event.delta_observations) > 0:
			accepted_observations += int(event.delta_observations)
			if event.get("target_id", "") != selected_target: continue
			captures.append(step)
			var orbit_index: int = floori(float(step) / float(steps_per_orbit))
			if not orbit_index in orbits: orbits.append(orbit_index)
	return {"positive_transmit_steps": contacts, "selected_target_capture_steps": captures, "observed_orbit_indices": orbits, "returned_mb": returned, "accepted_observations": accepted_observations}
func write_json(path: String, value: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		check(false, "Cannot write trace evidence: " + path); return
	file.store_string(JSON.stringify(value, "  ")); file.close()
func finish() -> void:
	evidence.passed = passed; evidence.failed = failed
	write_json(output.path_join("summary.json"), evidence)
	print("K24/K25 feasibility: %d checks passed; %d failed; %d engine traces." % [passed, failed, evidence.cases.size()])
	quit(0 if failed == 0 else 1)
