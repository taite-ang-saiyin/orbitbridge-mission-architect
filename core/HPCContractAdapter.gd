extends RefCounted
class_name HPCContractAdapter

## Team Contract v1 adapter from the shared MissionConfig to HPC catalog rows.
const SCHEMA_VERSION: int = 1
const CONTRACT_VERSION: String = "team-v1"
const KB_PER_MB: float = 1000.0

## Combine KE1 CatalogLoader's v1 bundle with HPC's authored orbit presets.
## The returned scenario is a snapshot suitable for MissionStepEngine.init_run.
static func build_scenario(ke1_catalogs: Dictionary, orbit_data: Dictionary) -> Dictionary:
	if int(ke1_catalogs.get("schema_version", 0)) != SCHEMA_VERSION or str(ke1_catalogs.get("contract_revision", "")) != "v1.0-agreed":
		return _error("UNSUPPORTED_KE1_CONTRACT", "KE1 catalogs must use schema_version 1 and contract_revision v1.0-agreed")
	for key in ["components", "launch_profiles", "launchers", "objective_ids", "orbit_ids", "target_region_ids"]:
		if not ke1_catalogs.get(key, null) is Array:
			return _error("INVALID_KE1_CATALOG", "KE1 catalog field %s must be an array" % key)
	for key in ["orbits", "targets"]:
		if not orbit_data.get(key, null) is Array:
			return _error("INVALID_ORBIT_CATALOG", "HPC orbit field %s must be an array" % key)
	if not orbit_data.get("unit_conventions", null) is Dictionary:
		return _error("UNSUPPORTED_DATA_UNITS", "HPC orbit data must define unit_conventions")
	if int(orbit_data.get("schema_version", 0)) != SCHEMA_VERSION:
		return _error("UNSUPPORTED_ORBIT_SCHEMA", "HPC orbit data schema_version must be 1")
	var parts: Array = []
	for component in ke1_catalogs.components:
		if not component is Dictionary:
			return _error("INVALID_KE1_CATALOG", "KE1 components must contain objects")
		var part: Dictionary = component.duplicate(true)
		part.kind = str(part.get("category", ""))
		match part.kind:
			"bus": part.idle_w = part.get("baseline_power_w", null)
			"instrument":
				part.observe_w = part.get("observe_power_w", null)
				part.packet_mb = part.get("data_per_observation_mb", null)
			"solar": part.output_w = part.get("generation_power_w", null)
			"radio": part.transmit_w = part.get("transmit_power_w", null)
			"battery", "storage": pass
			_: return _error("INVALID_KE1_CATALOG", "Unknown KE1 component category '%s'" % part.kind)
		parts.append(part)
	var orbits: Array = []
	for orbit in orbit_data.orbits:
		if not orbit is Dictionary or not ke1_catalogs.orbit_ids.has(orbit.get("id", null)):
			return _error("CATALOG_ID_MISMATCH", "HPC orbit is absent from KE1 orbit_ids")
		orbits.append(orbit.duplicate(true))
	var targets: Array = []
	for target in orbit_data.targets:
		if not target is Dictionary or not ke1_catalogs.target_region_ids.has(target.get("id", null)):
			return _error("CATALOG_ID_MISMATCH", "HPC target is absent from KE1 target_region_ids")
		targets.append(target.duplicate(true))
	var objectives: Array = []
	for objective_id in ke1_catalogs.objective_ids:
		objectives.append({"id": objective_id})
	var scenario: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"scenario_version": str(orbit_data.get("scenario_version", "")),
		"contract_revision": str(ke1_catalogs.get("contract_revision", "")),
		"unit_conventions": orbit_data.unit_conventions.duplicate(true),
		"parts": parts,
		"orbits": orbits,
		"targets": targets,
		"objectives": objectives,
		"launch_profiles": ke1_catalogs.launch_profiles.duplicate(true),
		"launchers": ke1_catalogs.launchers.duplicate(true)
	}
	if ke1_catalogs.has("mission_v2"):
		scenario.mission_catalogs = ke1_catalogs.duplicate(true)
	return {"ok":true,"scenario":scenario}

static func validate_config(config: Dictionary, catalog: Dictionary) -> Dictionary:
	if _is_integer(config.get("schema_version")) and config.schema_version == 2:
		return _validate_config_v2(config, catalog)
	return _validate_physical_config(config, catalog)

static func _validate_physical_config(config: Dictionary, catalog: Dictionary, v2: bool = false) -> Dictionary:
	if not config.has("schema_version"):
		return _error("MISSING_FIELD", "schema_version is required")
	if not _is_integer(config.schema_version) or int(config.schema_version) != (2 if v2 else SCHEMA_VERSION):
		return _error("UNSUPPORTED_SCHEMA_VERSION", "schema_version must be integer 1")
	if config.has("contract_version") and str(config.contract_version) != CONTRACT_VERSION:
		return _error("UNSUPPORTED_CONTRACT_VERSION", "contract_version must be %s when supplied" % CONTRACT_VERSION)
	if not config.get("mission", null) is Dictionary:
		return _error("INVALID_TYPE", "mission must be an object")
	if not config.get("design", null) is Dictionary:
		return _error("INVALID_TYPE", "design must be an object")
	var mission: Dictionary = config.mission
	var design: Dictionary = config.design
	if mission.is_empty():
		return _error("MISSING_FIELD", "mission is required")
	if design.is_empty():
		return _error("MISSING_FIELD", "design is required")
	for key in ["title", "objective", "target_region"]:
		if not mission.has(key):
			return _error("MISSING_FIELD", "mission.%s is required" % key)
		if not mission[key] is String or str(mission[key]).strip_edges().is_empty():
			return _error("INVALID_TYPE", "mission.%s must be a non-empty string" % key)
	if str(mission.title).length() > 80:
		return _error("INVALID_RANGE", "mission.title must be 80 characters or fewer")
	for key in ["required_observations", "duration_orbits", "budget_credits"]:
		if not mission.has(key):
			return _error("MISSING_FIELD", "mission.%s is required" % key)
		if not _is_integer(mission[key]):
			return _error("INVALID_TYPE", "mission.%s must be an integer" % key)
	if not mission.has("required_returned_data_mb"):
		return _error("MISSING_FIELD", "mission.required_returned_data_mb is required")
	if not _is_number(mission.required_returned_data_mb):
		return _error("INVALID_TYPE", "mission.required_returned_data_mb must be a finite number")
	if int(mission.required_observations) < 1 or int(mission.required_observations) > 20:
		return _error("INVALID_RANGE", "mission.required_observations must be from 1 through 20")
	if int(mission.duration_orbits) < 1 or int(mission.duration_orbits) > 12:
		return _error("INVALID_RANGE", "mission.duration_orbits must be from 1 through 12")
	if int(mission.budget_credits) <= 0 or float(mission.required_returned_data_mb) <= 0.0:
		return _error("INVALID_RANGE", "budget_credits and required_returned_data_mb must be positive")
	for key in ["bus_id", "instrument_id", "solar_id", "battery_id", "radio_id", "storage_id", "launch_profile_id", "launcher_id", "orbit_id"]:
		if not design.has(key):
			return _error("MISSING_FIELD", "design.%s is required" % key)
		if not design[key] is String or str(design[key]).strip_edges().is_empty():
			return _error("INVALID_TYPE", "design.%s must be a non-empty string" % key)
	if not catalog.get("unit_conventions", null) is Dictionary:
		return _error("UNSUPPORTED_DATA_UNITS", "catalog.unit_conventions must define the data unit conversion")
	var unit_conventions: Dictionary = catalog.unit_conventions
	if not _is_number(unit_conventions.get("kilobytes_per_megabyte", null)) or not is_equal_approx(float(unit_conventions.kilobytes_per_megabyte), KB_PER_MB):
		return _error("UNSUPPORTED_DATA_UNITS", "catalog must explicitly set unit_conventions.kilobytes_per_megabyte to 1000")
	var target: Dictionary = _find(catalog.get("targets", []), str(mission.target_region))
	if target.is_empty():
		return _error("UNKNOWN_TARGET_ID", "mission.target_region '%s' is not in catalog.targets" % mission.target_region)
	var objective: Dictionary = _find(catalog.get("objectives", []), str(mission.objective))
	if objective.is_empty() and not v2:
		return _error("UNKNOWN_OBJECTIVE_ID", "mission.objective '%s' is not in catalog.objectives" % mission.objective)
	var orbit: Dictionary = _find(catalog.get("orbits", []), str(design.orbit_id))
	if orbit.is_empty():
		return _error("UNKNOWN_ORBIT_ID", "design.orbit_id '%s' is not in catalog.orbits" % design.orbit_id)
	var parts: Dictionary = {}
	for pair in [["bus", "bus_id"], ["instrument", "instrument_id"], ["solar", "solar_id"], ["battery", "battery_id"], ["radio", "radio_id"], ["storage", "storage_id"]]:
		var row: Dictionary = _find(catalog.get("parts", []), str(design[pair[1]]), str(pair[0]))
		if row.is_empty():
			return _error("UNKNOWN_COMPONENT_ID", "design.%s '%s' is missing or has the wrong kind" % [pair[1], design[pair[1]]])
		parts[pair[0]] = row
	var launcher: Dictionary = _find(catalog.get("launchers", []), str(design.launcher_id))
	if launcher.is_empty():
		return _error("UNKNOWN_LAUNCHER_ID", "design.launcher_id '%s' is not in catalog.launchers" % design.launcher_id)
	var profiles: Variant = catalog.get("launch_profiles", null)
	if not profiles is Array:
		return _error("INVALID_CATALOG", "catalog.launch_profiles must be an array")
	if _find(profiles, str(design.launch_profile_id)).is_empty():
		return _error("UNKNOWN_LAUNCH_PROFILE_ID", "design.launch_profile_id '%s' is not in catalog.launch_profiles" % design.launch_profile_id)
	var required_power: Array = [[parts.bus, "idle_w"], [parts.instrument, "observe_w"], [parts.solar, "output_w"], [parts.radio, "transmit_w"]]
	for pair in required_power:
		if not pair[0].has(pair[1]) or not _is_number(pair[0].get(pair[1], null)) or float(pair[0][pair[1]]) < 0.0:
			return _error("INVALID_CATALOG_VALUE", "catalog field %s must be a finite nonnegative number" % pair[1])
	var normalized_parts: Dictionary = {}
	for kind in parts:
		normalized_parts[kind] = parts[kind].duplicate(true)
	var battery: Dictionary = normalized_parts.battery
	var initial_charge_fraction: Variant = battery.get("initial_charge_fraction", 1.0)
	if not _is_number(initial_charge_fraction) or float(initial_charge_fraction) <= 0.0 or float(initial_charge_fraction) > 1.0:
		return _error("INVALID_CATALOG_VALUE", "battery.initial_charge_fraction must be finite and within (0, 1]")
	battery.initial_charge_fraction = float(initial_charge_fraction)
	if battery.has("capacity_wh"):
		if not _is_number(battery.capacity_wh):
			return _error("INVALID_CATALOG_VALUE", "battery.capacity_wh must be finite")
		battery.capacity_wh = float(battery.capacity_wh)
	elif battery.has("capacity_ws") and _is_number(battery.capacity_ws):
		battery.capacity_wh = float(battery.capacity_ws) / 3600.0
	else:
		return _error("INVALID_CATALOG_VALUE", "battery must define capacity_wh")
	var storage: Dictionary = normalized_parts.storage
	if storage.has("capacity_mb"):
		if not _is_number(storage.capacity_mb):
			return _error("INVALID_CATALOG_VALUE", "storage.capacity_mb must be finite")
		storage.capacity_mb = float(storage.capacity_mb)
	elif storage.has("capacity_kb") and _is_number(storage.capacity_kb):
		storage.capacity_mb = float(storage.capacity_kb) / KB_PER_MB
	else:
		return _error("INVALID_CATALOG_VALUE", "storage must define capacity_mb")
	var instrument: Dictionary = normalized_parts.instrument
	if instrument.has("packet_mb"):
		if not _is_number(instrument.packet_mb):
			return _error("INVALID_CATALOG_VALUE", "instrument.packet_mb must be finite")
		instrument.packet_mb = float(instrument.packet_mb)
	elif instrument.has("packet_kb") and _is_number(instrument.packet_kb):
		instrument.packet_mb = float(instrument.packet_kb) / KB_PER_MB
	else:
		return _error("INVALID_CATALOG_VALUE", "instrument must define packet_mb")
	var radio: Dictionary = normalized_parts.radio
	if radio.has("downlink_mb_per_hour"):
		if not _is_number(radio.downlink_mb_per_hour):
			return _error("INVALID_CATALOG_VALUE", "radio.downlink_mb_per_hour must be finite")
		radio.downlink_mb_per_hour = float(radio.downlink_mb_per_hour)
	elif radio.has("rate_kb_s") and _is_number(radio.rate_kb_s):
		radio.downlink_mb_per_hour = float(radio.rate_kb_s) * 3600.0 / KB_PER_MB
	else:
		return _error("INVALID_CATALOG_VALUE", "radio must define downlink_mb_per_hour")
	for pair in [[battery, "capacity_wh"], [storage, "capacity_mb"], [instrument, "packet_mb"], [radio, "downlink_mb_per_hour"]]:
		if float(pair[0][pair[1]]) <= 0.0:
			return _error("INVALID_CATALOG_VALUE", "catalog field %s must be positive" % pair[1])
	if not _is_number(orbit.get("step_duration_hours", null)) or float(orbit.step_duration_hours) <= 0.0:
		return _error("INVALID_ORBIT_METADATA", "orbit.step_duration_hours must be positive and finite")
	if not _is_integer(orbit.get("steps_per_orbit", null)) or int(orbit.steps_per_orbit) <= 0:
		return _error("INVALID_ORBIT_METADATA", "orbit.steps_per_orbit must be a positive integer")
	for window_key in ["sunlight_windows", "ground_contact_windows"]:
		if not orbit.get(window_key, null) is Array or not _valid_windows(orbit[window_key], int(orbit.steps_per_orbit)):
			return _error("INVALID_ORBIT_METADATA", "orbit.%s must contain valid local step indices" % window_key)
	if not orbit.get("target_windows", null) is Dictionary:
		return _error("INVALID_ORBIT_METADATA", "orbit.target_windows must be an object")
	var target_windows: Dictionary = orbit.target_windows
	if not target_windows.has(str(mission.target_region)) or not target_windows[str(mission.target_region)] is Array or not _valid_windows(target_windows[str(mission.target_region)], int(orbit.steps_per_orbit)):
		return _error("TARGET_UNSUITABLE_FOR_ORBIT", "target '%s' has no valid observation window for orbit '%s'" % [mission.target_region, design.orbit_id])
	var target_ids: Variant = mission.get("target_regions", [mission.target_region])
	if not target_ids is Array or target_ids.is_empty() or target_ids.size() > 2 or target_ids[0] != mission.target_region:
		return _error("INVALID_TARGETS", "Choose one or two consistent target IDs.")
	var unique_targets: Array = []
	for target_id in target_ids:
		if not target_id is String or unique_targets.has(target_id) or _find(catalog.get("targets", []), target_id).is_empty():
			return _error("UNKNOWN_TARGET_ID", "Targets must be unique registered IDs.")
		if not target_windows.get(target_id) is Array or not _valid_windows(target_windows[target_id], int(orbit.steps_per_orbit)):
			return _error("TARGET_UNSUITABLE_FOR_ORBIT", "No authored access windows for " + target_id)
		unique_targets.append(target_id)
	if mission.objective == "survey" and int(mission.required_observations) < target_ids.size():
		return _error("INVALID_SURVEY_GOAL", "Survey needs at least one observation per target.")
	var total_steps: int = int(mission.duration_orbits) * int(orbit.steps_per_orbit)
	return {
		"ok": true,
		"config_snapshot": config.duplicate(true),
		"scenario_id": str(design.orbit_id),
		"target_id": str(mission.target_region),
		"target_ids": unique_targets,
		"observations_required": int(mission.required_observations),
		"required_returned_data_mb": float(mission.required_returned_data_mb),
		"total_steps": total_steps,
		"orbit": orbit,
		"parts": normalized_parts,
		"launcher": launcher
	}

static func _find(rows: Variant, id: String, kind: String = "") -> Dictionary:
	if rows is Array:
		for row in rows:
			if row is Dictionary and str(row.get("id", "")) == id and (kind.is_empty() or str(row.get("kind", "")) == kind):
				return row
	return {}

static func _valid_windows(values: Array, steps_per_orbit: int) -> bool:
	for value in values:
		if not _is_integer(value) or int(value) < 0 or int(value) >= steps_per_orbit:
			return false
	return true

static func _is_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

static func _is_integer(value: Variant) -> bool:
	return _is_number(value) and is_equal_approx(float(value), float(int(value)))

static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "error_code": code, "error_message": message}

# The agreed validator owns goal shape, identity, capabilities and physical readiness.
# Reuse accounting resolution without converting the mission to a legacy objective.
static func _validate_config_v2(config: Dictionary, catalog: Dictionary) -> Dictionary:
	var source: Variant = catalog.get("mission_catalogs")
	if not source is Dictionary:
		return _error("V2_CONTEXT_MISSING", "The frozen mission catalog context is missing.")
	var checked: Dictionary = preload("res://scripts/core/mission_validator.gd").validate(config, source)
	if not checked.ready_to_launch:
		return _error("MISSION_NOT_READY", "Resolve the mission readiness checks before launch.")
	var rebuilt: Dictionary = build_scenario(source, source.get("orbit_catalog", {}))
	if not rebuilt.ok or rebuilt.scenario != catalog:
		return _error("INVALID_SCENARIO", "The scenario does not match its frozen mission catalogs.")
	var objective: String = config.mission.objective
	if objective not in ["communication", "weather_monitoring"]:
		return _error("UNSUPPORTED_OBJECTIVE", "This version supports native expanded communication and weather missions only.")
	var resolved: Dictionary = _validate_physical_config(config, catalog, true)
	if not resolved.ok: return resolved
	resolved.goal_kind = objective
	resolved.goal_required_count = config.mission.goal["required_positive_contact_steps" if objective == "communication" else "required_distinct_orbits"]
	resolved.goal_definition = config.mission.goal.duplicate(true)
	resolved.catalog_context = catalog.duplicate(true)
	return resolved
