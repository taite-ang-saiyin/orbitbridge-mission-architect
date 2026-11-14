extends RefCounted
## Development seam only. Replace catalog/validate with KE1; never derive capabilities from art.
const SATELLITES = {"acrimsat": ["AcrimSAT", "Solar-monitoring spacecraft", "res://assets/3d/real/AcrimSAT.glb"], "mirata": ["CubeSat – MiRaTa", "Compact weather-sensing spacecraft", "res://assets/3d/real/MiRaTa.glb"], "icecube": ["CubeSat – ICECube", "Cloud-ice sensing CubeSat", "res://assets/3d/real/ICECube.glb"]}
const STARTER = {"body_id": "dev_body_1", "wings_id": "dev_wings_1", "radio_id": "dev_radio_1"}
const GROUPS = {"body_id": ["Body", "The main structure that holds your satellite’s equipment. Choose a body that fits your mission’s capacity, mass and budget limits.", "body", "Mass (kg), capacity, cost: awaiting KE1"], "wings_id": ["Solar Panels", "Generate electricity while the satellite is in sunlight. Compare power generation, mass and cost to support your equipment.", "wings", "Generation (W), mass (kg), cost: awaiting KE1"], "radio_id": ["Radio", "Sends collected mission data to a ground station when contact is available. Compare transmission rate, power use and cost.", "radio", "Data rate (kbps), active power (W), mass (kg), cost: awaiting KE1"]}
static func catalog(key: String) -> Array:
	var options = []
	for number in range(1, 4):
		options.append({"id": "dev_%s_%s" % [GROUPS[key][2], number], "name": {"body_id": ["AcrimSAT-style Bus", "MiRaTa-style Bus", "ICECube-style Bus"], "wings_id": ["Twin Solar Wings", "Segmented Solar Wings", "Four-Panel Array"], "radio_id": ["Parabolic Dish", "Compact Dish", "Antenna Array"]}[key][number - 1], "description": "Reference-inspired modular part %s. Engineering specifications pending." % number, "specifications": GROUPS[key][3], "asset": "res://assets/3d/satellite/Satellite Kit %s %s.glb" % [GROUPS[key][2], number]})
	return options
static func ensure(draft: Dictionary) -> void:
	draft.satellite_id = "kit"
	for key in STARTER:
		if not draft.has(key): draft[key] = STARTER[key]
static func validate(draft: Dictionary) -> Dictionary:
	ensure(draft)
	var ids = {}
	var blockers = {}
	for key in STARTER:
		ids[key] = draft[key]
		if not catalog(key).any(func(option): return option.id == draft[key]):
			blockers[key] = "Choose an available " + GROUPS[key][0].to_lower() + "."
	if draft.satellite_id not in SATELLITES and draft.satellite_id != "kit": blockers["satellite_id"] = "Choose an available satellite."
	return {"satellite_id": draft.satellite_id, "source": "development_mock", "selected_ids": ids, "can_proceed": blockers.is_empty(), "blockers": blockers, "warnings": ["Development preview only. KE1 engineering validation and HPC capabilities are unavailable."], "totals_text": "Mass (kg) · Power (W) · Battery (Wh)\nStorage (GB) · Data rate (kbps)\nCost and budget remaining: awaiting KE1", "capabilities": {}}
static func refresh(draft: Dictionary) -> Dictionary:
	var result = validate(draft)
	draft["validated_design"] = result.duplicate(true)
	return result
