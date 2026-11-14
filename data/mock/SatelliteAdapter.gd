extends RefCounted
## Visual catalog with explicit gameplay presets and real KE1 validation.
const SATELLITES = {"acrimsat": ["AcrimSAT", "Solar-monitoring spacecraft", "res://assets/3d/real/AcrimSAT.glb"], "mirata": ["CubeSat – MiRaTa", "Compact weather-sensing spacecraft", "res://assets/3d/real/MiRaTa.glb"], "icecube": ["CubeSat – ICECube", "Cloud-ice sensing CubeSat", "res://assets/3d/real/ICECube.glb"]}
const STARTER = {"body_id": "dev_body_1", "wings_id": "dev_wings_1", "radio_id": "dev_radio_1"}
const GROUPS = {"body_id": ["Body", "The main structure that holds your satellite’s equipment. Choose a body that fits your mission’s capacity, mass and budget limits.", "body", "Mass (g), energy (Wh), storage (MB), illustrative credits"], "wings_id": ["Solar Panels", "Generate electricity while the satellite is in sunlight. Compare power generation, mass and cost to support your equipment.", "wings", "Generation (W), mass (g), illustrative credits"], "radio_id": ["Radio", "Sends collected mission data to a ground station when contact is available. Compare transmission rate, power use and cost.", "radio", "Data rate (MB/hour), active power (W), mass (g), illustrative credits"]}
static func catalog(key: String) -> Array:
	var options = []
	for number in range(1, 4):
		options.append({"id": "dev_%s_%s" % [GROUPS[key][2], number], "name": {"body_id": ["AcrimSAT-style Bus", "MiRaTa-style Bus", "ICECube-style Bus"], "wings_id": ["Twin Solar Wings", "Segmented Solar Wings", "Four-Panel Array"], "radio_id": ["Parabolic Dish", "Compact Dish", "Antenna Array"]}[key][number - 1], "description": "Reference-inspired modular part %s. Assigned gameplay preset; not specifications of the illustrated spacecraft." % number, "specifications": preset_text(key, number), "asset": "res://assets/3d/satellite/Satellite Kit %s %s.glb" % [GROUPS[key][2], number]})
	if key == "radio_id":
		options[2].asset = "res://scenes/3d/parts/CompactAntennaArray.tscn"
	return options
static func ensure(draft: Dictionary) -> void:
	draft.satellite_id = "kit"
	for key in STARTER:
		if not draft.has(key): draft[key] = STARTER[key]
static func validate(draft: Dictionary) -> Dictionary:
	ensure(draft)
	var result: Dictionary = preload("res://scripts/integration/mission_runtime.gd").review(draft)
	var blockers: Dictionary = {}
	for issue in result.errors:
		blockers[issue.field_path] = issue.message + " " + issue.suggested_fix
	for key in STARTER:
		if not catalog(key).any(func(option): return option.id == draft[key]):
			blockers[key] = "Choose an available " + GROUPS[key][0].to_lower() + "."
	var totals = "Metrics unavailable: resolve invalid selections."
	if result.metrics is Dictionary:
		var m: Dictionary = result.metrics
		totals = "Mass %s g · Cost %s credits\nBaseline %s W · Solar %s W\nBattery %s Wh · Storage %s MB\nCapture %s MB · Radio %s MB/hour" % [m.total_mass_g, m.total_cost_credits, m.baseline_power_w, m.solar_generation_power_w, m.battery_capacity_wh, m.storage_capacity_mb, m.data_per_observation_mb, m.downlink_mb_per_hour]
	return {"source": "ke1_v1", "selected_ids": {"body_id": draft.body_id, "wings_id": draft.wings_id, "radio_id": draft.radio_id}, "engineering_ids": result.config.design, "can_proceed": result.ready_to_launch, "blockers": blockers, "warnings": ["Illustrative gameplay specifications; appearance is not NASA hardware capability."], "totals_text": totals, "capabilities": result.get("metrics"), "validation": result}
static func refresh(draft: Dictionary) -> Dictionary:
	var result = validate(draft)
	draft["validated_design"] = result.duplicate(true)
	return result

static func preset_text(key: String, number: int) -> String:
	var runtime = preload("res://scripts/integration/mission_runtime.gd")
	match key:
		"body_id": return "Gameplay bundle: " + ", ".join(runtime.BODIES["dev_body_%s" % number])
		"wings_id": return "Gameplay panel: " + runtime.SOLAR["dev_wings_%s" % number]
		"radio_id": return "Gameplay radio: " + runtime.RADIOS["dev_radio_%s" % number]
	return ""
