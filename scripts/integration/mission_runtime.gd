extends RefCounted
## Explicit UI-to-contract boundary. Visual meshes never supply physical specifications.
static var next_run_sequence: int = 0
const Loader = preload("res://scripts/core/catalog_loader.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
const Adapter = preload("res://core/HPCContractAdapter.gd")
const StepEngine = preload("res://core/MissionStepEngine.gd")
const ORBITS = {"LEO – 400 km": "low_eq", "Polar – 600 km": "high_inc"}
const TARGETS = {"Equator": "equator", "Tropical Forest": "tropical_forest", "Equatorial Ocean": "equatorial_ocean", "Coastal Region": "coastal_region", "Temperate Land": "temperate_land", "Arctic Ice": "arctic_ice", "Antarctic Region": "antarctic_region"}
# Authored gameplay presets assigned to the existing three appearance buttons.
const BODIES = {
	"dev_body_1": ["bus_basic", "instrument_basic", "battery_standard", "storage_standard"],
	"dev_body_2": ["bus_light", "instrument_basic", "battery_standard", "storage_large"],
	"dev_body_3": ["bus_basic", "instrument_advanced", "battery_standard", "storage_standard"]}
const SOLAR = {"dev_wings_1": "solar_standard", "dev_wings_2": "solar_large", "dev_wings_3": "solar_standard"}
const RADIOS = {"dev_radio_1": "radio_basic", "dev_radio_2": "radio_fast", "dev_radio_3": "radio_basic"}

static func load_game_catalogs() -> Dictionary:
	var loaded: Dictionary = Loader.load_catalogs()
	if not loaded.ok: return loaded
	var extension: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/mission_scenarios.json"))
	if not extension is Dictionary or not extension.get("targets") is Array:
		return {"ok": false, "catalogs": {}, "errors": [{"code": "INVALID_SCHEMA", "field_path": "scenario_extension", "message": "Target scenario pack is missing or malformed.", "suggested_fix": "Restore data/mission_scenarios.json."}]}
	var catalogs: Dictionary = loaded.catalogs
	catalogs.objective_ids.append("survey")
	for part in catalogs.components:
		if part.category == "instrument": part.supported_objectives.append("survey")
	if not catalogs.get("orbit_catalog") is Dictionary: return loaded
	var seen: Array = []
	for target in extension.targets:
		if not target is Dictionary or not target.get("id") is String or not target.get("label") is String or not target.get("windows") is Dictionary:
			return _scenario_error("Every target needs an ID, label and explicit orbit windows.")
		if seen.has(target.id) or TARGETS.get(target.label, "") != target.id:
			return _scenario_error("Target IDs must be unique and match the UI vocabulary.")
		seen.append(target.id)
		for orbit in catalogs.orbit_catalog.orbits:
			if not orbit is Dictionary or not orbit.get("target_windows") is Dictionary or not target.windows.get(orbit.get("id")) is Array:
				return _scenario_error("Each target must declare windows for both source orbits.")
			for step in target.windows[orbit.id]:
				if not preload("res://scripts/core/validation_support.gd").is_whole(step) or step < 0 or step >= orbit.get("steps_per_orbit", 0):
					return _scenario_error("Target windows must contain valid whole step indices.")
		if not catalogs.target_region_ids.has(target.id):
			catalogs.target_region_ids.append(target.id)
			catalogs.orbit_catalog.targets.append({"id": target.id, "label": target.label})
		for orbit in catalogs.orbit_catalog.orbits:
			if not orbit.target_windows.has(target.id): orbit.target_windows[target.id] = target.windows[orbit.id].duplicate()
	if seen.size() != TARGETS.size(): return _scenario_error("The target pack must include every displayed region.")
	return loaded

static func _scenario_error(message: String) -> Dictionary:
	return {"ok": false, "catalogs": {}, "errors": [{"code": "INVALID_SCHEMA", "field_path": "scenario_extension", "message": message, "suggested_fix": "Restore data/mission_scenarios.json."}]}

static func orbit_for(draft: Dictionary) -> Dictionary:
	var loaded: Dictionary = Loader.load_catalogs()
	if not loaded.ok or not loaded.catalogs.get("orbit_catalog") is Dictionary: return {}
	for orbit in loaded.catalogs.orbit_catalog.orbits:
		if orbit.id == ORBITS.get(draft.get("orbit"), draft.get("orbit_id", "")): return orbit.duplicate(true)
	return {}

static func config_for(draft: Dictionary) -> Dictionary:
	var body: Array = BODIES.get(draft.get("body_id", "dev_body_1"), ["", "", "", ""])
	var targets: Array = draft.get("targets", [])
	return {"schema_version": 1, "mission": {
		"title": draft.get("name", ""), "objective": {"Capture Imagery": "imaging", "Survey Target Regions": "survey"}.get(draft.get("objective"), "unsupported"),
		"target_region": TARGETS.get(targets[0], "unsupported") if not targets.is_empty() else "unsupported",
		"target_regions": targets.map(func(t): return TARGETS.get(t, "unsupported")),
		"required_observations": draft.get("observations", 5),
		"required_returned_data_mb": draft.get("required_returned_data_mb", float(draft.get("observations", 5)) * 12.0),
		"duration_orbits": draft.get("duration", 6), "budget_credits": draft.get("budget", 100)},
		"design": _engineering_design(draft, {"bus_id": body[0], "instrument_id": body[1], "battery_id": body[2], "storage_id": body[3],
		"solar_id": SOLAR.get(draft.get("wings_id", "dev_wings_1"), ""),
		"radio_id": RADIOS.get(draft.get("radio_id", "dev_radio_1"), ""),
		"launch_profile_id": draft.get("launch_profile_id", "cubesat_1u_sample"),
		"launcher_id": draft.get("launcher_id", "small"), "orbit_id": ORBITS.get(draft.get("orbit"), "unsupported")})}

static func _engineering_design(draft: Dictionary, design: Dictionary) -> Dictionary:
	var selected: Dictionary = draft.get("engineering_parts", {})
	for category in ["bus", "instrument", "solar", "battery", "radio", "storage"]:
		if selected.has(category): design[category + "_id"] = selected[category]
	return design

static func review(draft: Dictionary) -> Dictionary:
	var loaded: Dictionary = load_game_catalogs()
	var config: Dictionary = config_for(draft)
	if not loaded.ok:
		return {"config": config, "ready_to_launch": false, "metrics": null, "checks": {}, "errors": loaded.errors, "warnings": []}
	var result: Dictionary = Validator.validate(config, loaded.catalogs)
	result.config = config
	return result

static var next_mission_sequence: int = 0

static func launch(draft: Dictionary, previous: Dictionary = {}) -> Dictionary:
	var loaded: Dictionary
	var config: Dictionary
	if previous.has("catalogs_snapshot") and previous.has("draft_snapshot"):
		for key in previous.draft_snapshot:
			var value: Variant = previous.draft_snapshot[key]
			draft[key] = value.duplicate(true) if value is Dictionary or value is Array else value
		loaded = {"ok": true, "catalogs": previous.catalogs_snapshot.duplicate(true)}
		config = previous.config.duplicate(true)
	else:
		loaded = load_game_catalogs()
		config = config_for(draft)
	if not loaded.ok: return {"ok": false, "error": {"message": "Catalog loading failed."}, "errors": loaded.errors}
	var sequence: int = maxi(next_run_sequence, int(draft.get("run_sequence", 0))) + 1
	# Run namespaces prevent collisions between sessions; identity does not enter physics.
	var session: String = str(draft.get("run_session_id", ""))
	if session.is_empty(): session = Crypto.new().generate_random_bytes(12).hex_encode()
	var mission_id: String = str(draft.get("mission_id", "mission_" + session))
	var started: Dictionary = StepEngine.init_validated_run(config, loaded.catalogs, "run_%s_%03d" % [session, sequence], mission_id)
	if not started.ok: return started
	next_run_sequence = sequence
	draft.run_session_id = session
	draft.mission_id = mission_id
	var reviewed: Dictionary = started.validation_result.duplicate(true)
	reviewed.config = config.duplicate(true)
	var snapshots: Dictionary = {}
	for key in ["name", "description", "objective", "targets", "target_limit", "target", "observations", "required_returned_data_mb", "duration", "budget", "orbit", "launcher", "policy", "component", "components", "satellite_id", "body_id", "wings_id", "radio_id", "engineering_parts", "launch_profile_id", "launcher_id", "schema_version", "contract_revision", "preset_id", "preset_revision", "goal", "required_contact_steps", "required_orbit_visits"]:
		if draft.has(key):
			var value: Variant = draft[key]
			snapshots[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	var trace: Dictionary = {"config": config.duplicate(true), "validation": reviewed,
		"policy": draft.get("policy", "Observe First"), "catalogs_snapshot": loaded.catalogs.duplicate(true), "draft_snapshot": snapshots}
	var completed: Dictionary = _finish_trace(trace, started.state, [{"state": started.state.duplicate(true), "events": []}])
	if not completed.ok: return completed
	draft.run_sequence = sequence
	_remember(draft, completed.trace)
	draft.active_run_state = started.state.duplicate(true)
	return completed

static func _finish_trace(trace: Dictionary, current: Dictionary, frames: Array) -> Dictionary:
	for index in range(int(current.total_steps) + 1):
		if current.phase != "operating": break
		var action: String = "power_save"
		var order: Array = ["transmit", "observe"] if trace.policy == "Downlink First" else ["observe", "transmit"]
		for candidate in order:
			if current.available_actions[candidate].allowed:
				action = candidate
				break
		var reply: Dictionary = StepEngine.request_action(current, action)
		if not reply.get("ok", false): return reply
		current = reply.state
		frames.append({"state": current.duplicate(true), "events": reply.events.duplicate(true)})
	if current.phase != "finished": return {"ok": false, "error": {"message": "Mission policy did not finish within its step bound."}}
	trace.frames = frames
	trace.final_state = current.duplicate(true)
	trace.events = current.event_log.duplicate(true)
	return {"ok": true, "trace": trace}

static func _remember(draft: Dictionary, trace: Dictionary) -> void:
	draft.run_design = trace.config.duplicate(true)
	draft.run_trace = trace
	var history: Array = draft.get("run_history", [])
	var replaced: bool = false
	for index in history.size():
		if history[index].final_state.run_id == trace.final_state.run_id:
			history[index] = trace.duplicate(true)
			replaced = true
	if not replaced: history.append(trace.duplicate(true))
	if history.size() > 2: history.pop_front()
	draft.run_history = history

static func take_action(draft: Dictionary, action: String) -> Dictionary:
	var current: Dictionary = draft.get("active_run_state", {})
	if current.get("phase") != "operating": return {"ok": false, "error": {"message": "Launch an operating mission before choosing an action."}}
	var store: Dictionary = draft.get("evaluation_store", {})
	if store.get("reports", {}).has(current.run_id) or store.get("errors", {}).has(current.run_id):
		return {"ok": false, "error": {"message": "This run is already recorded. Retry it to choose new actions."}}
	var reply: Dictionary = StepEngine.request_action(current, action)
	if not reply.get("ok", false): return reply
	var trace: Dictionary = draft.run_trace.duplicate(true)
	var frames: Array = []
	for frame in trace.frames:
		if frame.state.step_index <= current.step_index: frames.append(frame.duplicate(true))
	frames.append({"state": reply.state.duplicate(true), "events": reply.events.duplicate(true)})
	var completed: Dictionary = _finish_trace(trace, reply.state, frames)
	if not completed.ok: return completed
	_remember(draft, completed.trace)
	draft.active_run_state = reply.state.duplicate(true)
	return {"ok": true, "allowed": reply.allowed, "state": reply.state.duplicate(true)}
