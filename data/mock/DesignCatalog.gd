extends RefCounted
## Authored UI fixtures. Not engineering calculations, coverage algorithms or HPC schemas.
const DEFAULTS = {"name": "Estuary Watch", "description": "Observe coastal and tropical regions to support environmental monitoring.", "objective": "Capture Imagery", "targets": ["Tropical Forest", "Coastal Region"], "target_limit": 2, "target": "Tropical Forest, Coastal Region", "observations": 5, "duration": 6, "budget": 100, "orbit": "LEO – 400 km", "launcher": "LV-1 (Small)", "policy": "Observe First", "component": "BUS-S1 (Small)", "components": {"payload": "OPT-C1 Camera", "bus": "BUS-S1 (Small)", "battery": "BAT-60 (60 Wh)", "solar": "SOL-40 (40 W)", "storage": "STO-32 (32 GB)", "radio": "COM-A (10 kbps)"}}
const TARGETS = [
	["Tropical Forest", "Equatorial", "forest"], ["Equatorial Ocean", "Equatorial", "ocean"],
	["Coastal Region", "Mid-Latitude", "coast"], ["Temperate Land", "Mid-Latitude", "land"],
	["Arctic Ice", "Polar", "ice"], ["Antarctic Region", "Polar", "ice"]
]
const ORBITS = ["LEO – 400 km", "LEO – 500 km", "Polar – 600 km"]
# [400 km, 500 km, polar] fixed examples; duration intentionally does not compute windows.
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
	if state.objective not in ["Capture Imagery", "Survey Target Regions"]:
		state.objective = "Capture Imagery"
	if state.orbit not in ORBITS:
		state.orbit = ORBITS[0]
	state.observations = clampi(int(state.observations), 1, 8)
	state.duration = state.duration if state.duration in [3, 6, 9] else 6
	state.budget = clampi(roundi(float(state.budget) / 10.0) * 10, 60, 150)
	state.component = state.components.bus
static func reset(state: Dictionary) -> void:
	state.clear()
	state.merge(DEFAULTS.duplicate(true))
static func success(state: Dictionary) -> String:
	var rule = "Deliver at least %s complete observations" % state.observations
	if state.objective == "Survey Target Regions":
		rule += " in total, including at least one from each selected target"
	else:
		rule += " pooled across the selected targets"
	return rule + " within %s orbits." % state.duration
static func window_count(target: String, orbit: String) -> int:
	return COVERAGE.get(target, [0, 0, 0])[maxi(0, ORBITS.find(orbit))]
