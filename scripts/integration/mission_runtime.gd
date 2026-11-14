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
		"design": {"bus_id": body[0], "instrument_id": body[1], "battery_id": body[2], "storage_id": body[3],
		"solar_id": SOLAR.get(draft.get("wings_id", "dev_wings_1"), ""),
		"radio_id": RADIOS.get(draft.get("radio_id", "dev_radio_1"), ""),
		"launch_profile_id": draft.get("launch_profile_id", "cubesat_1u_sample"),
		"launcher_id": draft.get("launcher_id", "small"), "orbit_id": ORBITS.get(draft.get("orbit"), "unsupported")}}

static func review(draft: Dictionary) -> Dictionary:
	var loaded: Dictionary = load_game_catalogs()
	var config: Dictionary = config_for(draft)
	if not loaded.ok:
		return {"config": config, "ready_to_launch": false, "metrics": null, "checks": {}, "errors": loaded.errors, "warnings": []}
	var result: Dictionary = Validator.validate(config, loaded.catalogs)
	result.config = config
	return result

static func launch(draft: Dictionary) -> Dictionary:
	var reviewed: Dictionary = review(draft)
	if not reviewed.ready_to_launch:
		return {"ok": false, "error": {"message": "Resolve readiness errors before launch."}, "validation": reviewed}
	var loaded: Dictionary = load_game_catalogs()
	if not loaded.ok: return {"ok": false, "error": {"message": "Catalog loading failed."}}
	var built: Dictionary = Adapter.build_scenario(loaded.catalogs, loaded.catalogs.orbit_catalog)
	if not built.ok: return {"ok": false, "error": {"message": built.error_message}}
	next_run_sequence = maxi(next_run_sequence, int(draft.get("run_sequence", 0))) + 1
	var sequence: int = next_run_sequence
	var started: Dictionary = StepEngine.init_run(reviewed.config, built.scenario, "run_%03d" % sequence, "mission_local")
	if not started.ok: return started
	var current: Dictionary = started.state
	var frames: Array = [{"state": current.duplicate(true), "events": []}]
	var events: Array = []
	while current.phase == "operating":
		var action: String = "power_save"
		var order: Array = ["transmit", "observe"] if draft.get("policy") == "Downlink First" else ["observe", "transmit"]
		for candidate in order:
			if current.available_actions[candidate].allowed:
				action = candidate
				break
		var reply: Dictionary = StepEngine.request_action(current, action)
		if not reply.get("ok", false): return reply
		current = reply.state
		events.append_array(reply.events)
		frames.append({"state": current.duplicate(true), "events": reply.events.duplicate(true)})
	var trace: Dictionary = {"config": reviewed.config.duplicate(true), "validation": reviewed.duplicate(true), "frames": frames, "events": events, "final_state": current.duplicate(true), "policy": draft.get("policy", "Observe First")}
	draft.run_sequence = sequence
	draft.run_design = reviewed.config.duplicate(true)
	draft.run_trace = trace
	var history: Array = draft.get("run_history", [])
	history.append(trace.duplicate(true))
	if history.size() > 2: history.pop_front()
	draft.run_history = history
	return {"ok": true, "trace": trace}
