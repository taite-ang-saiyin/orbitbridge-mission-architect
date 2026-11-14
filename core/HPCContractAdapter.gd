extends RefCounted
class_name HPCContractAdapter

## Team Contract v1 adapter from the shared MissionConfig to HPC catalog rows.
const SCHEMA_VERSION: int = 1
const CONTRACT_VERSION: String = "team-v1"
const KB_PER_MB: float = 1000.0

static func validate_config(config: Dictionary, catalog: Dictionary) -> Dictionary:
	if not config.has("schema_version"):
		return _error("MISSING_FIELD", "schema_version is required")
	if not _is_integer(config.schema_version) or int(config.schema_version) != SCHEMA_VERSION:
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
	if objective.is_empty():
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
	var total_steps: int = int(mission.duration_orbits) * int(orbit.steps_per_orbit)
	return {
		"ok": true,
		"config_snapshot": config.duplicate(true),
		"scenario_id": str(design.orbit_id),
		"target_id": str(mission.target_region),
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
