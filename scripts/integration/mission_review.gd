extends RefCounted
## Player acknowledgement of mission intent; engineering validation still occurs separately.
const CATALOG = preload("res://data/mock/DesignCatalog.gd")
const FIELDS = ["name", "description", "objective", "targets", "observations", "duration", "budget", "orbit"]
static func snapshot(draft: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in FIELDS:
		var value = draft.get(key, CATALOG.DEFAULTS[key])
		result[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	result.required_returned_data_mb = float(draft.get("required_returned_data_mb", float(result.observations) * 12.0))
	for key in preload("res://scripts/integration/mission_runtime.gd").CONTRACT_FIELDS:
		if draft.has(key):
			var value: Variant = draft[key]
			result[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	return result
static func can_confirm(draft: Dictionary) -> bool:
	var mission: Dictionary = snapshot(draft)
	return not str(mission.name).strip_edges().is_empty() and not mission.targets.is_empty() and (mission.objective != "Survey Target Regions" or int(mission.observations) >= mission.targets.size())
static func is_confirmed(draft: Dictionary) -> bool:
	return can_confirm(draft) and draft.get("mission_review_snapshot", {}) == snapshot(draft)
static func confirm(draft: Dictionary, reviewed: Dictionary) -> bool:
	if not can_confirm(draft) or reviewed != snapshot(draft): return false
	draft.mission_review_snapshot = reviewed.duplicate(true)
	return true
static func details(draft: Dictionary) -> Dictionary:
	var mission: Dictionary = snapshot(draft)
	var result: Dictionary = {"Mission name": mission.name, "Description": mission.description if not str(mission.description).strip_edges().is_empty() else "No description added", "Objective": mission.objective, "Targets": ", ".join(mission.targets), "Orbit": mission.orbit, "Observations": str(mission.observations), "Data to return": "%s MB" % mission.required_returned_data_mb, "Duration": "%s orbits" % mission.duration, "Budget": "%s credits" % mission.budget}
	if mission.get("goal") is Dictionary:
		var goal: Dictionary = mission.goal
		for field in {"minimum_complete_observations_per_target":"Complete images delivered per target", "required_positive_contact_steps":"Successful transmission steps", "required_distinct_orbits":"Distinct orbits with a qualifying visit"}:
			if goal.has(field): result[{"minimum_complete_observations_per_target":"Complete images delivered per target", "required_positive_contact_steps":"Successful transmission steps", "required_distinct_orbits":"Distinct orbits with a qualifying visit"}[field]] = str(goal[field])
	return result
