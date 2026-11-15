extends RefCounted
## SE session storage/routing seam. KE2 owns final comparison/scoring output.
const Results = preload("res://scripts/integration/mission_results.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")

static func failure(code: String, message: String) -> Dictionary:
	return {"ok":false,"error":{"code":code,"message":message}}

static func eligible(session: Dictionary, execution_key: String) -> Dictionary:
	var stored: Dictionary = Results.get_execution(session, execution_key)
	if not stored.ok: return stored
	var packet: Dictionary = stored.execution
	var trace: Dictionary = packet.trace
	if trace.final_state.get("run_status") != "completed": return failure("RUN_NOT_COMPLETED", "Only completed runs can be saved or compared.")
	if not packet.evaluation.get("ok", false): return failure("EVALUATION_UNAVAILABLE", "This execution does not have a valid evaluated result.")
	for field in ["catalogs_snapshot", "draft_snapshot", "versions", "frames", "action_plan", "policy"]:
		if not trace.has(field): return failure("EXECUTION_INCOMPLETE", "Recorded execution is missing " + field + ".")
	if trace.frames.is_empty() or trace.action_plan.size() != int(trace.final_state.get("total_steps", -1)):
		return failure("EXECUTION_INCOMPLETE", "The initial resource state or full action plan is missing.")
	if trace.frames.back().state != trace.final_state or trace.config != trace.final_state.get("config_snapshot") or trace.events != trace.final_state.get("event_log"):
		return failure("EXECUTION_INCOMPLETE", "Terminal frame, configuration and full event history must match.")
	if trace.validation.get("ready_to_launch") != true or trace.validation.get("config") != trace.config:
		return failure("EXECUTION_INCOMPLETE", "Original launch validation does not match this execution.")
	for frame in trace.frames:
		if frame.state.get("run_id") != packet.run_id or frame.state.get("mission_id") != packet.mission_id or frame.state.get("config_snapshot") != trace.config:
			return failure("EXECUTION_INCOMPLETE", "A resource sample belongs to another execution.")
	if trace.frames[0].state.get("step_index") != 0 or not trace.frames[0].state.get("event_log", []).is_empty():
		return failure("EXECUTION_INCOMPLETE", "The original clean launch state is missing.")
	return stored

static func saved_a(session: Dictionary) -> Dictionary:
	var key: String = str(session.get("design_lab", {}).get("saved_a", ""))
	if key.is_empty(): return {"ok":true,"execution":null}
	return Results.get_execution(session, key)

static func save_a(session: Dictionary, execution_key: String) -> Dictionary:
	if session.has("design_lab_route"): return failure("DRAFT_ACTIVE", "Cancel the current design draft before saving A.")
	if session.get("active_run_state", {}).get("phase") == "operating": return failure("RUN_ACTIVE", "Finish or stop the current run first.")
	var existing: String = str(session.get("design_lab", {}).get("saved_a", ""))
	if not existing.is_empty() and existing != execution_key:
		return failure("A_ALREADY_SAVED", "Replace A explicitly to choose another baseline.")
	var packet: Dictionary = eligible(session, execution_key)
	if not packet.ok: return packet
	if not session.has("design_lab"): session.design_lab = {}
	session.design_lab.saved_a = execution_key
	return packet

static func replace_a(session: Dictionary, execution_key: String, expected_a: String) -> Dictionary:
	if session.get("active_run_state", {}).get("phase") == "operating": return failure("RUN_ACTIVE", "Finish or stop the current run first.")
	if session.has("design_lab_route"): return failure("DRAFT_ACTIVE", "Cancel the current design draft before replacing A.")
	if str(session.get("design_lab", {}).get("saved_a", "")) != expected_a or expected_a.is_empty():
		return failure("A_CHANGED", "The saved baseline changed. Review the currently saved A.")
	var packet: Dictionary = eligible(session, execution_key)
	if not packet.ok: return packet
	session.design_lab.saved_a = execution_key
	return packet

static func clear_a(session: Dictionary, expected_a: String) -> Dictionary:
	if session.get("active_run_state", {}).get("phase") == "operating": return failure("RUN_ACTIVE", "Finish or stop the current run first.")
	if session.has("design_lab_route"): return failure("DRAFT_ACTIVE", "Cancel the current design draft before clearing A.")
	if str(session.get("design_lab", {}).get("saved_a", "")) != expected_a:
		return failure("A_CHANGED", "The saved baseline changed. Review the currently saved A.")
	if session.has("design_lab"): session.design_lab.erase("saved_a")
	return {"ok":true}

static func modify_execution(session: Dictionary, execution_key: String) -> Dictionary:
	if session.get("active_run_state", {}).get("phase") == "operating": return failure("RUN_ACTIVE", "Finish or stop the current run first.")
	var packet: Dictionary = eligible(session, execution_key)
	if not packet.ok: return packet
	var source: Dictionary = packet.execution.trace
	var draft: Dictionary = session.duplicate(true)
	Results.retry(draft)
	for key in Runtime.CONTRACT_FIELDS:
		draft.erase(key)
	for key in source.draft_snapshot:
		var value: Variant = source.draft_snapshot[key]
		draft[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	draft.mission_id = packet.execution.mission_id
	draft.design_lab_route = {"origin_execution_key":execution_key, "saved_a":session.get("design_lab", {}).get("saved_a", "")}
	return {"ok":true,"draft":draft,"execution":packet.execution}

static func launch_b(session: Dictionary, origin_execution_key: String) -> Dictionary:
	if session.get("design_lab_route", {}).get("origin_execution_key") != origin_execution_key:
		return failure("EXECUTION_MISMATCH", "The B draft belongs to another execution.")
	if session.design_lab_route.get("saved_a") != session.get("design_lab", {}).get("saved_a", ""):
		return failure("A_CHANGED", "The saved A changed while editing this draft.")
	var packet: Dictionary = eligible(session, origin_execution_key)
	if not packet.ok: return packet
	var source: Dictionary = packet.execution.trace
	var current: Dictionary = Runtime.config_for(session)
	if not same_contract_identity(current, source.config) or current.mission != source.config.mission or not same_launch_setup(current.design, source.config.design) or session.get("mission_id") != packet.execution.mission_id or session.get("preset_id") != source.draft_snapshot.get("preset_id"):
		return failure("MISSION_CHANGED", "Changed mission requirements or orbit require a new comparison.")
	if session.get("policy", "Observe First") != source.policy:
		return failure("OPERATIONS_CHANGED", "Use the original action policy for a controlled B run.")
	var reply: Dictionary = Runtime.launch(session, {}, {"catalogs_snapshot":source.catalogs_snapshot,"action_plan":source.get("requested_action_plan",source.action_plan),"comparison_context":session.design_lab_route.duplicate(true)})
	if reply.ok:
		session.erase("design_lab_route")
	return reply

static func comparison_inputs(session: Dictionary, b_execution_key: String) -> Dictionary:
	var a: Dictionary = saved_a(session)
	if not a.ok: return a
	if a.execution == null: return failure("A_NOT_SAVED", "Save Design A before comparing runs.")
	var b: Dictionary = eligible(session, b_execution_key)
	if not b.ok: return b
	if a.execution.execution_key == b_execution_key: return failure("SAME_EXECUTION", "Choose a different completed execution for B.")
	var left: Dictionary = a.execution.trace
	var right: Dictionary = b.execution.trace
	if not same_contract_identity(left.config, right.config) or a.execution.mission_id != b.execution.mission_id or left.config.mission != right.config.mission or not same_launch_setup(left.config.design, right.config.design):
		return failure("INCOMPATIBLE_MISSION", "Mission identity, requirements and orbit must match.")
	if left.draft_snapshot.get("preset_id") != right.draft_snapshot.get("preset_id"):
		return failure("INCOMPATIBLE_PRESET", "The preset identity differs.")
	if left.catalogs_snapshot != right.catalogs_snapshot or left.final_state.scenario_snapshot != right.final_state.scenario_snapshot:
		return failure("INCOMPATIBLE_SCENARIO", "The recorded catalogs or scenario schedules differ.")
	for version in ["simulator_sha256","adapter_sha256","runner_sha256","validator_sha256","evaluator_sha256","catalog_sha256"]:
		if not left.versions.get(version) is String or left.versions[version].length() != 64:
			return failure("COMPARISON_METADATA_MISSING", "Verified module and catalog hashes are required for comparison.")
	if left.versions != right.versions or left.versions.values().has(null):
		return failure("INCOMPATIBLE_VERSIONS", "Verified simulator, runner and catalog versions must match.")
	var first: Dictionary = left.frames[0].state
	var second: Dictionary = right.frames[0].state
	if not is_equal_approx(float(first.energy_wh) / float(first.battery_capacity_wh), float(second.energy_wh) / float(second.battery_capacity_wh)) or first.stored_data_mb != second.stored_data_mb:
		return failure("INCOMPATIBLE_START", "Starting battery charge fraction and stored data must match.")
	var changed_operations: bool = left.policy != right.policy or left.get("requested_action_plan",left.action_plan) != right.get("requested_action_plan",right.action_plan) or left.get("manual_actions",[]) != right.get("manual_actions",[])
	return {"ok":true,"a":a.execution,"b":b.execution,"mode":"design_and_operations" if changed_operations else "controlled_design"}

static func compare(session: Dictionary, b_execution_key: String, provider: Callable = Callable()) -> Dictionary:
	var inputs: Dictionary = comparison_inputs(session, b_execution_key)
	if not inputs.ok: return inputs
	if not provider.is_valid(): return failure("COMPARISON_PROVIDER_UNAVAILABLE", "Comparison scoring has not been connected yet.")
	var reply: Variant = provider.call(inputs.duplicate(true))
	if not reply is Dictionary or not reply.get("ok",false): return reply if reply is Dictionary else failure("INVALID_COMPARISON", "The comparison provider returned an invalid wrapper.")
	var result: Variant = reply.get("comparison")
	if not result is Dictionary or result.get("a_execution_key") != inputs.a.execution_key or result.get("b_execution_key") != inputs.b.execution_key:
		return failure("EXECUTION_MISMATCH", "The comparison response belongs to another A/B pair.")
	var output: Dictionary = reply.duplicate(true)
	output.mode = inputs.mode
	return output

static func same_contract_identity(a: Dictionary, b: Dictionary) -> bool:
	for field in ["schema_version", "contract_revision", "preset_id", "preset_revision"]:
		if a.get(field) != b.get(field): return false
	return true

static func export_saved_a(session: Dictionary) -> Dictionary:
	var saved: Dictionary = saved_a(session)
	if not saved.ok: return saved
	if saved.execution == null: return failure("A_NOT_SAVED", "Save Design A before exporting it.")
	return Results.export_execution_record(session, saved.execution.execution_key)

static func same_launch_setup(a: Dictionary, b: Dictionary) -> bool:
	for field in ["orbit_id", "launcher_id", "launch_profile_id"]:
		if a.get(field) != b.get(field): return false
	return true
