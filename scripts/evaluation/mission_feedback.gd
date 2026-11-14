class_name MissionFeedback
extends RefCounted
## Deterministic feedback for validated v1 reports and recorded step-engine events.
## Codes/actions checked against origin/feature/hpc-simulator at ab7865c.
## Runtime integration still requires the producer's real trace and adapter handoff.
## Segment names follow the requested launch/space/ground/user vocabulary.

const RULES: Dictionary = {
	"NO_LINK_WINDOW": {
		"actions": ["transmit"],
		"segment": "ground",
		"cause": "no ground-contact window was available",
		"next_experiment": "Retry and transmit during an available ground-contact window.",
	},
	"LOW_BATTERY": {
		"actions": ["observe", "transmit"],
		"segment": "space",
		"cause": "battery energy was insufficient to complete the action and step",
		"next_experiment": "Try Power Save before that operation while keeping the other settings fixed.",
	},
	"STORAGE_FULL": {
		"actions": ["observe"],
		"segment": "space",
		"cause": "the observation packet would not fit in the remaining onboard storage",
		"next_experiment": "Transmit stored data during an available contact window before observing again.",
	},
	"TARGET_NOT_VISIBLE": {
		"actions": ["observe"],
		"segment": "space",
		"cause": "the selected target was outside the observation window",
		"next_experiment": "Retry and observe during a target-access window.",
	},
}


## Returns the three existing report feedback fields, preserving every input.
## Only events relevant to unmet goals become causes. Ties use observation goal,
## earliest step, then original array order. Duplicate IDs with conflicting
## records are excluded because the evidence reference would be ambiguous.
static func build_feedback(report: Dictionary, final_state: Dictionary, events: Array) -> Dictionary:
	var summary: String = "%s/%s observations captured and %s/%s MB received on Earth. " % [
		report["observations_completed"], report["required_observations"],
		report["returned_data_mb"], report["required_returned_data_mb"],
	]
	summary += "%s MB remain onboard." % final_state["stored_data_mb"]

	if report["run_status"] == "aborted":
		var reason: String = _abort_reason(final_state)
		var explanation: String = "Mission aborted before completion. " + summary
		var next_experiment: String = "Retry with the same settings and record the termination reason."
		if not reason.is_empty():
			explanation += " Recorded abort reason was " + reason
			next_experiment = "Review the recorded termination reason and choose one setting to change before retrying."
		return {"explanation": explanation, "root_causes": [], "next_experiment": next_experiment}

	if report["status"] == "success":
		return {
			"explanation": "Both mission requirements were met. " + summary,
			"root_causes": [],
			"next_experiment": "Keep the scenario and targets fixed and change one operation on the next attempt.",
		}

	var observation_shortfall: bool = report["observations_completed"] < report["required_observations"]
	var data_shortfall: bool = report["returned_data_mb"] < report["required_returned_data_mb"]
	var first_events: Dictionary = {}
	var conflicting_ids: Dictionary = {}
	for event: Variant in events:
		if not event is Dictionary or not event.get("event_id") is String:
			continue
		var event_id: String = event["event_id"]
		if first_events.has(event_id) and first_events[event_id] != event:
			conflicting_ids[event_id] = true
		else:
			first_events[event_id] = event

	var candidates: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	for index: int in range(events.size()):
		var event: Variant = events[index]
		if not event is Dictionary:
			continue
		var feedback: Dictionary = explain_event(event)
		if feedback.is_empty():
			continue
		var event_id: String = event["event_id"]
		if conflicting_ids.has(event_id) or seen_ids.has(event_id):
			continue
		seen_ids[event_id] = true
		if event.has("run_id") and event["run_id"] != report["run_id"]:
			continue
		if event.has("mission_id") and event["mission_id"] != report["mission_id"]:
			continue
		if event["step_index"] > final_state["step_index"] or event["step_index"] >= final_state["total_steps"]:
			continue
		var is_observation: bool = event["action"] == "observe"
		if (is_observation and not observation_shortfall) or (not is_observation and not data_shortfall):
			continue
		candidates.append({
			"goal_priority": 0 if is_observation else 1,
			"step_index": event["step_index"],
			"input_order": index,
			"feedback": feedback,
		})

	if candidates.is_empty():
		return {
			"explanation": summary + " Available events do not establish the cause of the shortfall.",
			"root_causes": [],
			"next_experiment": (
				"Retry with one change to observation timing and review the event timeline."
				if observation_shortfall else
				"Retry with one change to transmission timing and review the event timeline."
			),
		}

	candidates.sort_custom(_comes_before)
	var causes: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		var feedback: Dictionary = candidate["feedback"]
		causes.append({
			"code": feedback["code"],
			"segment": feedback["segment"],
			"evidence_event_ids": feedback["evidence_event_ids"].duplicate(),
			"explanation": feedback["explanation"] + " " + feedback["next_experiment"],
		})
	var primary: Dictionary = candidates[0]["feedback"]
	return {
		"explanation": summary + " " + primary["explanation"],
		"root_causes": causes,
		"next_experiment": primary["next_experiment"],
	}


## Explains one recorded blocked event with its own corrective experiment.
## Unknown codes, incompatible actions, missing references, and contradictory
## blocked-action deltas return an empty Dictionary for neutral handling.
static func explain_event(event: Dictionary) -> Dictionary:
	var event_id: Variant = event.get("event_id")
	var code: Variant = event.get("code")
	var step: Variant = event.get("step_index")
	if not event_id is String or event_id.strip_edges().is_empty():
		return {}
	if event.get("type") != "action_blocked" or not code is String or not RULES.has(code):
		return {}
	if not (step is int or step is float) or not is_finite(float(step)):
		return {}
	if step < 0 or floorf(float(step)) != step:
		return {}
	var rule: Dictionary = RULES[code]
	if event.get("action") not in rule["actions"]:
		return {}
	for field: String in ["delta_energy_wh", "delta_stored_data_mb", "delta_returned_data_mb", "delta_observations"]:
		if event.has(field):
			var delta: Variant = event[field]
			if not (delta is int or delta is float) or not is_finite(float(delta)) or delta != 0:
				return {}
	var action: String = "an observation" if event["action"] == "observe" else "a transmission"
	return {
		"code": code,
		"segment": rule["segment"],
		"evidence_event_ids": [event_id],
		"explanation": "At step %s, %s was blocked because %s." % [step, action, rule["cause"]],
		"next_experiment": rule["next_experiment"],
	}


static func _comes_before(left: Dictionary, right: Dictionary) -> bool:
	for key: String in ["goal_priority", "step_index", "input_order"]:
		if left[key] != right[key]:
			return left[key] < right[key]
	return false


## Optional caller-supplied abort metadata. Its runtime producer mapping remains
## an HPC handoff detail. Operation-blocked events alone do not explain an abort.
static func _abort_reason(final_state: Dictionary) -> String:
	var reason: Variant = final_state.get("abort_reason")
	if reason is Dictionary:
		reason = reason.get("message")
	if reason is String:
		return reason.strip_edges()
	return ""
