extends RefCounted
class_name OrbitPlanner

## Deterministic planner for catalog-authored abstract coverage windows.
const EARTH_RADIUS_KM: float = 6371.0
const EARTH_MU_KM3_S2: float = 398600.0
const SLOTS_PER_ORBIT: int = 10

static func orbit_period_s(altitude_km: float) -> float:
	if altitude_km < 0.0:
		return 0.0
	var radius_km: float = EARTH_RADIUS_KM + altitude_km
	return TAU * sqrt(pow(radius_km, 3.0) / EARTH_MU_KM3_S2)

static func build_plan(input: Dictionary, catalog: Dictionary) -> Dictionary:
	var brief: Dictionary = input.get("brief", {})
	var design: Dictionary = input.get("design", {})
	var orbit_id: String = str(design.get("orbit_id", ""))
	var orbit: Dictionary = _lookup(catalog.get("orbits", []), orbit_id)
	if orbit.is_empty():
		return {"ok": false, "error": "unknown orbit_id: %s" % orbit_id}
	var altitude_km: float = float(orbit.get("altitude_km", -1.0))
	var duration_orbits: int = int(brief.get("duration_orbits", 0))
	if duration_orbits not in [3, 6, 9]:
		return {"ok": false, "error": "duration_orbits must be 3, 6, or 9"}
	var period_s: float = orbit_period_s(altitude_km)
	if period_s <= 0.0:
		return {"ok": false, "error": "orbit has invalid altitude_km"}
	var slot_seconds: int = int(orbit.get("slot_seconds", round(period_s / SLOTS_PER_ORBIT)))
	if slot_seconds <= 0:
		return {"ok": false, "error": "orbit slot_seconds must be positive"}
	var slots: Array[Dictionary] = []
	for slot_index in range(duration_orbits * SLOTS_PER_ORBIT):
		var local_slot: int = slot_index % SLOTS_PER_ORBIT
		slots.append({
			"slot": slot_index,
			"orbit": slot_index / SLOTS_PER_ORBIT,
			"slot_in_orbit": local_slot,
			"t_s": (slot_index + 1) * slot_seconds,
			"slot_seconds": slot_seconds,
			"sunlight": _has_slot(orbit.get("sunlight_slots", []), local_slot),
			"contact": _has_slot(orbit.get("contact_slots", []), local_slot),
			"target_windows": _visible_targets(orbit.get("target_windows", {}), local_slot)
		})
	return {"ok": true, "orbit_period_s": period_s, "slot_seconds": slot_seconds, "slots": slots}

## Candidate action-step plan. Windows are authored game rules, not orbit predictions.
static func build_step_plan(orbit_id: String, target_ids: Array, total_steps: int, catalog: Dictionary) -> Dictionary:
	var orbit: Dictionary = _lookup(catalog.get("orbits", []), orbit_id)
	if orbit.is_empty():
		return {"ok": false, "error_code": "UNKNOWN_ORBIT_ID", "error_message": "unknown orbit_id: %s" % orbit_id}
	var steps_per_orbit: int = int(orbit.get("steps_per_orbit", 0))
	var step_duration_hours: float = float(orbit.get("step_duration_hours", 0.0))
	if steps_per_orbit <= 0 or step_duration_hours <= 0.0 or total_steps <= 0:
		return {"ok": false, "error_code": "INVALID_ORBIT_METADATA", "error_message": "orbit step metadata must be positive"}
	var target_windows: Variant = orbit.get("target_windows", {})
	var sunlight_windows: Variant = orbit.get("sunlight_windows", [])
	var contact_windows: Variant = orbit.get("ground_contact_windows", [])
	if not target_windows is Dictionary or not sunlight_windows is Array or not contact_windows is Array:
		return {"ok": false, "error_code": "INVALID_ORBIT_METADATA", "error_message": "orbit windows have invalid types"}
	var steps: Array[Dictionary] = []
	for step_index in range(total_steps):
		var local_step: int = step_index % steps_per_orbit
		var visible_targets: Array[String] = []
		for target_id in target_ids:
			if _has_slot(target_windows.get(str(target_id), []), local_step):
				visible_targets.append(str(target_id))
		visible_targets.sort()
		steps.append({
			"step_index": step_index,
			"orbit_index": int(step_index / steps_per_orbit),
			"step_in_orbit": local_step,
			"elapsed_hours": float(step_index + 1) * step_duration_hours,
			"step_duration_hours": step_duration_hours,
			"sunlight": _has_slot(sunlight_windows, local_step),
			"contact": _has_slot(contact_windows, local_step),
			"target_windows": visible_targets
		})
	return {"ok": true, "orbit_id": orbit_id, "steps_per_orbit": steps_per_orbit, "step_duration_hours": step_duration_hours, "steps": steps}

static func _lookup(rows: Variant, id: String) -> Dictionary:
	if rows is Array:
		for row in rows:
			if row is Dictionary and str(row.get("id", "")) == id:
				return row
	elif rows is Dictionary:
		var value: Variant = rows.get(id, {})
		if value is Dictionary:
			return value
	return {}

static func _has_slot(values: Variant, slot_index: int) -> bool:
	if not values is Array:
		return false
	for value in values:
		if int(value) == slot_index:
			return true
	return false

static func _visible_targets(windows: Variant, slot_index: int) -> Array[String]:
	var result: Array[String] = []
	if windows is Dictionary:
		for target_id in windows.keys():
			if _has_slot(windows[target_id], slot_index):
				result.append(str(target_id))
	result.sort()
	return result
