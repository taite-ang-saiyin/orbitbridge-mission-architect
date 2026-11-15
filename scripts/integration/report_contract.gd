extends RefCounted
## Report selection. The original revision identifier is retained for saved-record compatibility.
const GOALS_REVISION = "mission-report-goals-v2-draft-1"

static func output_format(config: Dictionary) -> Dictionary:
	var mission: Dictionary = config.get("mission", {})
	var objective: Variant = mission.get("objective")
	if objective not in ["imaging", "survey", "communication", "weather_monitoring"]:
		return {"ok":false,"error":{"code":"UNSUPPORTED_REPORT_OBJECTIVE","message":"No agreed report format for this objective."}}
	# Select by evaluated semantics, independently of config/state schema numbers.
	if objective == "imaging" and not mission.has("goal"):
		return {"ok":true,"schema_version":1,"contract_revision":null}
	return {"ok":true,"schema_version":2,"contract_revision":GOALS_REVISION}
