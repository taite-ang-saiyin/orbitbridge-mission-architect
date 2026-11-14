extends RefCounted
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")

static func publish(session: Dictionary, native_state: Dictionary, evaluate: Callable = Callable()) -> Dictionary:
	var id: String = str(native_state.get("run_id", ""))
	var store: Dictionary = session.get("evaluation_store", {"reports": {}, "errors": {}, "history": [], "baseline": null})
	session.evaluation_store = store
	if store.reports.has(id):
		return {"ok": true, "report": store.reports[id].duplicate(true), "existing": true}
	var reply: Dictionary = evaluate.call(native_state.duplicate(true)) if evaluate.is_valid() else Evaluator.evaluate_hpc_state(native_state.duplicate(true))
	if not reply.get("ok", false):
		store.errors[id] = reply.get("error", {"message": "Evaluation failed.", "suggested_fix": "Restore a valid terminal HPC state."}).duplicate(true)
		return reply
	if not reply.get("report") is Dictionary or reply.report.get("run_id") != id or reply.report.get("mission_id") != native_state.get("mission_id"):
		var error: Dictionary = {"code":"STALE_EVALUATION", "message":"Evaluator reply does not match the requested run/mission.", "suggested_fix":"Provide the report for this exact native run."}
		store.errors[id] = error.duplicate(true)
		return {"ok":false,"error":error}
	var record: Dictionary = {"report": reply.report.duplicate(true), "state": native_state.duplicate(true), "validation": {}}
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
