extends RefCounted
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const LEDGER_PATH = "res://data/nasa_sources.json"

static func publish(session: Dictionary, native_state: Dictionary, evaluate: Callable = Callable()) -> Dictionary:
	var id: String = str(native_state.get("run_id", ""))
	var store: Dictionary = session.get("evaluation_store", {"reports": {}, "errors": {}, "history": [], "baseline": null})
	session.evaluation_store = store
	if store.reports.has(id):
		var previous_key: Variant = store.get("bindings",{}).get(id)
		if previous_key != null and previous_key != _native_key(session,native_state):
			return {"ok":false,"error":{"code":"EXECUTION_MISMATCH","message":"Run ID already belongs to another input snapshot.","suggested_fix":"Use a distinct run identity for this execution."}}
		return {"ok": true, "report": store.reports[id].duplicate(true), "existing": true}
	var bound_trace: Dictionary = {"config":native_state.get("config_snapshot",{}).duplicate(true), "final_state":native_state.duplicate(true), "events":native_state.get("event_log",[]).duplicate(true), "validation":{}}
	for trace in session.get("run_history", []):
		if trace.final_state.run_id == id and trace.config == bound_trace.config: bound_trace.validation = trace.validation.duplicate(true)
	var reply: Dictionary = evaluate.call(native_state.duplicate(true)) if evaluate.is_valid() else evaluate_trace(bound_trace)
	if not reply.get("ok", false):
		store.errors[id] = reply.get("error", {"message": "Evaluation failed.", "suggested_fix": "Restore a valid terminal HPC state."}).duplicate(true)
		return reply
	if not reply.get("report") is Dictionary or reply.report.get("run_id") != id or reply.report.get("mission_id") != native_state.get("mission_id"):
		var error: Dictionary = {"code":"STALE_EVALUATION", "message":"Evaluator reply does not match the requested run/mission.", "suggested_fix":"Provide the report for this exact native run."}
		store.errors[id] = error.duplicate(true)
		return {"ok":false,"error":error}
	var record: Dictionary = {"report": reply.report.duplicate(true), "state": native_state.duplicate(true), "validation": bound_trace.validation.duplicate(true), "execution_key":input_key(bound_trace)}
	if bound_trace.get("result_context") is Dictionary:
		record.result_context = bound_trace.result_context.duplicate(true)
		record.source_credit_metadata = {"applicable_source_credits":bound_trace.result_context.applicable_source_credits.duplicate(true)}
	if not store.has("bindings"): store.bindings = {}
	store.bindings[id] = record.execution_key
	# Optional supplied display metadata stays separate from the KE2 report.
	if reply.get("source_credit_metadata") is Dictionary: record.source_credit_metadata = reply.source_credit_metadata.duplicate(true)
	for trace in session.get("run_history", []):
		if trace.final_state.run_id == id: record.validation = trace.validation.duplicate(true)
	store.reports[id] = reply.report.duplicate(true)
	store.history.append(record)
	store.errors.erase(id)
	if store.baseline == null and native_state.run_status == "completed": store.baseline = record.duplicate(true)
	return {"ok": true, "report": reply.report.duplicate(true), "existing": false}

static func retry(session: Dictionary) -> void:
	for key in ["run_trace", "run_design", "active_run_state"]: session.erase(key)
	# Reports, errors, eligible baseline and launch history intentionally survive.

static func baseline_for(session: Dictionary, config: Dictionary) -> Variant:
	var baseline: Variant = session.get("evaluation_store", {}).get("baseline")
	if not baseline is Dictionary: return null
	var previous: Dictionary = baseline.state.config_snapshot
	if previous.design.orbit_id != config.design.orbit_id: return null
	for field in ["objective", "target_region", "target_regions", "required_observations", "required_returned_data_mb", "duration_orbits"]:
		if previous.mission.get(field) != config.mission.get(field): return null
	return baseline.duplicate(true)


# KE2 input-bound trace adapter ported unchanged from 14c0f973.
static func input_key(trace: Dictionary) -> String:
	return JSON.stringify([
		trace.get("config"), trace.get("final_state"), trace.get("events"),
		trace.get("validation"),
	], "", true, true).sha256_text()


static func evaluate_trace(trace: Dictionary) -> Dictionary:
	var key: String = input_key(trace)
	if trace.get("evaluation_key") == key and trace.get("evaluation") is Dictionary:
		return trace.evaluation.duplicate(true)
	var final_value: Variant = trace.get("final_state")
	var final: Dictionary = final_value if final_value is Dictionary else {}
	var config: Variant = trace.get("config")
	var events: Variant = trace.get("events")
	var result: Dictionary
	if not config is Dictionary or not events is Array:
		result = _input_error(final, "trace", "The run requires its config, terminal state and complete event history.")
	elif final.get("config_snapshot") != config or final.get("event_log") != events:
		result = _input_error(final, "trace.events", "The run snapshots do not match the terminal config and complete event log.")
	else:
		result = Evaluator.evaluate_mission(config, final, events)
		if result.get("ok", false):
			for event: Dictionary in events:
				if event.get("run_id") != final.get("run_id") or event.get("mission_id") != final.get("mission_id"):
					result = _input_error(final, "trace.events", "An event belongs to a different run or mission.")
					break
	trace.evaluation_key = key
	trace.evaluation = result.duplicate(true)
	trace.result_context = _context(trace, result)
	return result.duplicate(true)


static func presentation(trace: Dictionary) -> Dictionary:
	var result: Dictionary = evaluate_trace(trace)
	var final_value: Variant = trace.get("final_state")
	var state: Dictionary = final_value.duplicate(true) if final_value is Dictionary else {}
	var events: Variant = trace.get("events")
	state.events = events.duplicate(true) if events is Array else []
	return {
		"context": trace.result_context.duplicate(true),
		"state": state,
		"report": result.get("report", {}).duplicate(true),
	}


static func _context(trace: Dictionary, result: Dictionary) -> Dictionary:
	var final_value: Variant = trace.get("final_state")
	var final: Dictionary = final_value if final_value is Dictionary else {}
	var config: Variant = trace.get("config")
	var context: Dictionary = {
		"run_id": final.get("run_id"), "mission_id": final.get("mission_id"),
		"execution_key": trace.evaluation_key,
		"config": config.duplicate(true) if config is Dictionary else {},
		"applicable_source_credits": [], "source_metadata": {},
		"profile_metadata": {},
		"attribution_notice": "Credits apply to the recorded readiness check and emitted feedback vocabulary. Orbital windows and gameplay rates are authored educational values.",
	}
	if not result.get("ok", false):
		context.evaluation_error = result.get("error", {}).duplicate(true)
		return context
	var ledger: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LEDGER_PATH))
	var validation: Dictionary = trace.get("validation", {})
	var mass: Dictionary = validation.get("checks", {}).get("profile_mass", {})
	var profile_id: String = str(trace.config.get("design", {}).get("launch_profile_id", ""))
	for source: Dictionary in ledger.get("sources", []):
		context.source_metadata[source.source_id] = source.duplicate(true)
		if source.source_id == "cubesat_101_1u_sample" and validation.get("ready_to_launch") == true:
			if mass.get("passed") == true and mass.get("source_id") == source.source_id and mass.get("profile_id") == profile_id:
				var credit: Dictionary = source.duplicate(true)
				credit.credit_scope = "readiness"
				credit.actual_use = "Recorded KE1 mass check: %s g %s %s g, profile %s." % [mass.get("total_mass_g"), mass.get("comparator"), mass.get("threshold_g"), profile_id]
				context.applicable_source_credits.append(credit)
				context.profile_metadata = {"label": source.applicable_profile.label, "source_label": source.title, "credit": source.attribution_text}
		if source.source_id == "nasa_design_develop_science_missions_2025" and not result.report.root_causes.is_empty():
			var credit: Dictionary = source.duplicate(true)
			credit.credit_scope = "feedback_vocabulary"
			credit.actual_use = "Mission-segment terminology in this report's recorded-event causes."
			context.applicable_source_credits.append(credit)
	return context


static func _input_error(final: Dictionary, field: String, message: String) -> Dictionary:
	return {"ok": false, "error": {
		"code": "INVALID_EVALUATION_INPUT", "field_path": field,
		"message": message, "suggested_fix": "Use the original config, terminal state and ordered events from this execution.",
		"run_id": final.get("run_id"),
	}}

static func _native_key(session: Dictionary, native: Dictionary) -> String:
	var trace: Dictionary = {"config":native.get("config_snapshot",{}), "final_state":native, "events":native.get("event_log",[]), "validation":{}}
	for item in session.get("run_history",[]):
		if item.final_state.run_id == native.get("run_id") and item.config == trace.config: trace.validation = item.validation
	return input_key(trace)

## Optional externally returned packet binding. Caller supplies verified file hashes;
## report data remains unchanged and packet loading stays outside runtime.
static func bind_packet(trace: Dictionary, reply: Dictionary, metadata: Dictionary, input_hashes: Dictionary, case_id: String) -> Dictionary:
	var key: String = input_key(trace)
	if metadata.get("case_id") != case_id or metadata.get("execution_key") != key:
		return {"ok":false,"error":{"code":"EXECUTION_MISMATCH","message":"Case/execution key differs from the original packet."}}
	for name in ["config.json","final-state.json","events.json","readiness.json"]:
		if input_hashes.get(name) == null or metadata.get("input_sha256",{}).get(name) != input_hashes[name]:
			return {"ok":false,"error":{"code":"INPUT_HASH_MISMATCH","message":"Packet input hashes do not match."}}
	var final: Dictionary = trace.get("final_state",{})
	if not reply.get("ok",false) or not reply.get("report") is Dictionary:
		return {"ok":false,"error":{"code":"INVALID_REPORT","message":"A successful report wrapper is required."}}
	var report: Dictionary = reply.report
	if report.get("run_id") != final.get("run_id") or report.get("mission_id") != final.get("mission_id"):
		return {"ok":false,"error":{"code":"STALE_REPORT","message":"Report belongs to another run/mission."}}
	for field in ["required_observations","required_returned_data_mb"]:
		if report.get(field) != trace.get("config",{}).get("mission",{}).get(field): return {"ok":false,"error":{"code":"STALE_REPORT","message":"Report goals differ from this execution."}}
	for field in ["observations_completed","returned_data_mb","run_status"]:
		if report.get(field) != final.get(field): return {"ok":false,"error":{"code":"STALE_REPORT","message":"Report counters/status differ from this execution."}}
	var record: Dictionary = {"state":final.duplicate(true),"validation":trace.validation.duplicate(true),"report":report.duplicate(true),"execution_key":key,"source_credit_metadata":metadata.get("source_credit_metadata",{}).duplicate(true)}
	return {"ok":true,"store":{"reports":{final.run_id:report.duplicate(true)},"errors":{},"bindings":{final.run_id:key},"history":[record],"baseline":null}}
