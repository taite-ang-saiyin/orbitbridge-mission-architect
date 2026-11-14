extends RefCounted
## UI draft vocabulary. Numeric capabilities always come from the KE1 catalogs.
const Loader = preload("res://scripts/core/catalog_loader.gd")
const DEFAULTS = {
	"name": "Equator imaging trial", "description": "Observe the equatorial teaching target.",
	"objective": "imaging", "targets": ["Equator"], "target_limit": 1, "target": "Equator",
	"observations": 4, "required_returned_data_mb": 30, "duration": 6, "budget": 100,
	"orbit": "high_inc", "launcher": "small", "launch_profile": "cubesat_1u_sample",
	"policy": "Observe First", "satellite_id": "kit", "body_id": "dev_body_1",
	"wings_id": "dev_wings_1", "radio_id": "dev_radio_1",
	"components": {"payload": "instrument_basic", "bus": "bus_basic", "solar": "solar_standard",
		"battery": "battery_standard", "radio": "radio_basic", "storage": "storage_standard"}
}
const TARGETS = [["Equator", "Equatorial", "ocean"]]
const ORBITS = ["low_eq", "high_inc"]

static func orbit_label(id: String) -> String:
	return {"low_eq": "Low equatorial orbit", "high_inc": "High inclination orbit"}.get(id, id)

static func ensure(state: Dictionary) -> void:
	for key in DEFAULTS:
		if not state.has(key):
			var value: Variant = DEFAULTS[key]
			state[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	# Art is only a visual reflection of catalog choices, never a capability input.
	state.body_id = "dev_body_2" if state.components.get("bus") == "bus_light" else "dev_body_1"
	state.wings_id = "dev_wings_2" if state.components.get("solar") == "solar_large" else "dev_wings_1"
	state.radio_id = "dev_radio_2" if state.components.get("radio") == "radio_fast" else "dev_radio_1"

static func reset(state: Dictionary) -> void:
	state.clear()
	state.merge(DEFAULTS.duplicate(true))

static func success(state: Dictionary) -> String:
	return "Capture at least %s observations and return at least %s MB within %s orbits." % [state.observations, state.required_returned_data_mb, state.duration]

static func window_count(target: String, orbit_id: String) -> int:
	if target != "Equator": return 0
	var loaded: Dictionary = Loader.load_catalogs()
	if not loaded.ok: return 0
	for orbit in loaded.catalogs.get("orbit_catalog", {}).get("orbits", []):
		if orbit.id == orbit_id:
			return orbit.get("target_windows", {}).get("equator", []).size()
	return 0
