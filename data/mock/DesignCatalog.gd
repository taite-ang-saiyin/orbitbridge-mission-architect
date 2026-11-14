extends RefCounted
## UI vocabulary and draft defaults; production capabilities are provided by KE1/HPC.
const DEFAULTS = {"name": "Estuary Watch", "description": "Observe coastal and tropical regions to support environmental monitoring.", "objective": "Capture Imagery", "targets": ["Equator"], "target_limit": 1, "target": "Equator", "observations": 5, "duration": 6, "budget": 100, "orbit": "LEO – 400 km", "launcher": "LV-1 (Small)", "policy": "Observe First", "component": "BUS-S1 (Small)", "components": {"payload": "OPT-C1 Camera", "bus": "BUS-S1 (Small)", "battery": "BAT-60 (60 Wh)", "solar": "SOL-40 (40 W)", "storage": "STO-32 (32 GB)", "radio": "COM-A (10 kbps)"}}
const TARGETS = [
	["Equator", "Equatorial", "ocean"],
	["Tropical Forest", "Equatorial", "forest"], ["Equatorial Ocean", "Equatorial", "ocean"],
	["Coastal Region", "Mid-Latitude", "coast"], ["Temperate Land", "Mid-Latitude", "land"],
	["Arctic Ice", "Polar", "ice"], ["Antarctic Region", "Polar", "ice"]
]
const ORBITS = ["LEO – 400 km", "Polar – 600 km"]
# Legacy display specifications below are retained for older callers; runtime readiness never reads them.
const COVERAGE = {"Tropical Forest": [3, 2, 1], "Equatorial Ocean": [4, 2, 1], "Coastal Region": [3, 2, 2], "Temperate Land": [2, 3, 2], "Arctic Ice": [0, 1, 4], "Antarctic Region": [0, 1, 4]}
const COMPONENTS = {
	"payload": ["Payload / Instrument", [["OPT-C1 Camera", "Multispectral imaging payload"], ["SUR-S1 Sensor", "Regional survey instrument"]]],
	"bus": ["Bus / Platform", [["BUS-S1 (Small)", "Compact, balanced spacecraft"], ["BUS-M2 (Medium)", "Larger demonstration platform"]]],
	"battery": ["Battery", [["BAT-60 (60 Wh)", "Standard energy module"], ["BAT-90 (90 Wh)", "Extended energy module"]]],
	"solar": ["Solar Array", [["SOL-40 (40 W)", "Dual deployable solar wings"], ["SOL-60 (60 W)", "Extended solar wings"]]],
	"storage": ["Storage", [["STO-32 (32 GB)", "Standard solid-state recorder"], ["STO-64 (64 GB)", "Extended recorder module"]]],
	"radio": ["Radio", [["COM-A (10 kbps)", "Standard downlink terminal"], ["COM-B (20 kbps)", "High-rate demonstration terminal"]]]
}
const BUS_PROFILES = {"BUS-S1 (Small)": ["118.5 kg", "50 W", "95 cr", "8", "64,000 kB"], "BUS-M2 (Medium)": ["136.0 kg", "58 W", "110 cr", "8", "80,000 kB"]}
static func ensure(state: Dictionary) -> void:
	preload("res://data/mock/SatelliteAdapter.gd").ensure(state)
	for key in DEFAULTS:
		if not state.has(key):
			state[key] = DEFAULTS[key].duplicate(true) if DEFAULTS[key] is Array or DEFAULTS[key] is Dictionary else DEFAULTS[key]
	state.observations = clampi(int(state.observations), 1, 8)
	state.duration = state.duration if state.duration in [3, 6, 9] else 6
	state.budget = clampi(roundi(float(state.budget) / 10.0) * 10, 60, 150)
	state.component = state.components.bus
static func reset(state: Dictionary) -> void:
	state.clear()
	state.merge(DEFAULTS.duplicate(true))
static func success(state: Dictionary) -> String:
	var rule: String = "Capture at least %s observations and return at least %s MB within %s orbits." % [state.observations, state.get("required_returned_data_mb", state.observations * 12), state.duration]
	if state.objective == "Survey Target Regions": rule += " Return at least one complete observation from each selected target."
	return rule
static func window_count(target: String, orbit: String) -> int:
	var target_id: String = preload("res://scripts/integration/mission_runtime.gd").TARGETS.get(target, "")
	var loaded: Dictionary = preload("res://scripts/integration/mission_runtime.gd").load_game_catalogs()
	if not loaded.ok or not loaded.catalogs.get("orbit_catalog") is Dictionary: return 0
	var id: String = preload("res://scripts/integration/mission_runtime.gd").ORBITS.get(orbit, "")
	for preset in loaded.catalogs.orbit_catalog.orbits:
		if preset.id == id: return preset.target_windows.get(target_id, []).size()
	return 0
