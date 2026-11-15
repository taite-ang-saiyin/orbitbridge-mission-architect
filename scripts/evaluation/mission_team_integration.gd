extends RefCounted
## Opt-in KE2 provider for SE's execution packets and KE3's supplied metric view.
## Expanded scoring remains a proposal. Callers choose this provider explicitly.
const Evaluation = preload("res://scripts/evaluation/mission_expansion_candidate.gd")
const Records = preload("res://scripts/evaluation/mission_expansion_records.gd")
const Comparison = preload("res://scripts/evaluation/mission_expansion_comparison.gd")
const Legacy = preload("res://scripts/evaluation/mission_evaluator.gd")

static func evaluate_state(state: Dictionary) -> Dictionary:
	var config: Variant = state.get("config_snapshot")
	var events: Variant = state.get("event_log")
	if not config is Dictionary or not events is Array:
		return Evaluation._bad("final_state.config_snapshot", state)
	if config.get("schema_version") == 1 and config.get("mission", {}).get("objective") == "imaging":
		return Legacy.evaluate_mission(config, state, events)
	return Evaluation.evaluate_mission(config, state, events)

static func compare_executions(inputs: Dictionary) -> Dictionary:
	if inputs.get("ok") != true:
		return Evaluation._bad("comparison_inputs", {})
	var a: Dictionary = _record(inputs.get("a"))
	if not a.ok:
		return a
	var b: Dictionary = _record(inputs.get("b"))
	if not b.ok:
		return b
	var reply: Dictionary = Comparison.compare_runs(a.record, b.record)
	if not reply.ok:
		return reply
	var result: Dictionary = reply.comparison
	# KE3 always binds the pair, including a valid-but-incompatible response.
	result.a_execution_key = a.record.execution_key
	result.b_execution_key = b.record.execution_key
	result.a_run_id = a.record.run_id
	result.b_run_id = b.record.run_id
	result.a_mission_id = a.record.mission_id
	result.b_mission_id = b.record.mission_id
	if result.get("eligible"):
		var primary: String = {"survey": "selected_targets_delivered", "communication": "positive_transmit_steps", "weather_monitoring": "selected_target_revolution_visits"}.get(result.objective, "captures")
		for row: Dictionary in result.goal_measures:
			if row.id == primary:
				result.metrics = {"qualifying_count": {"a": row.a, "b": row.b, "delta": row.delta_b_minus_a, "delta_unit": row.delta_unit}}
	return reply

static func _record(value: Variant) -> Dictionary:
	if not value is Dictionary or not value.get("trace") is Dictionary or not value.get("evaluation") is Dictionary:
		return Evaluation._bad("execution_packet", {})
	var packet: Dictionary = value
	var digest: String = JSON.stringify([packet.get("execution_key"), packet.get("run_id"), packet.get("mission_id"),
		packet.trace, packet.evaluation, packet.get("result_context")], "", true, true).sha256_text()
	if packet.get("content_digest") != digest:
		return Evaluation._bad("execution_packet.content_digest", {})
	var trace: Dictionary = packet.trace
	for field in ["config", "final_state", "validation", "versions", "catalogs_snapshot"]:
		if not trace.get(field) is Dictionary:
			return Evaluation._bad("execution_packet.trace." + field, {})
	if not trace.get("events") is Array or not trace.get("frames") is Array or trace.frames.is_empty():
		return Evaluation._bad("execution_packet.trace.frames", trace.final_state)
	var preimage: String = JSON.stringify([trace.config, trace.final_state, trace.events, trace.validation], "", true, true)
	if packet.get("execution_key") != preimage.sha256_text() or packet.get("run_id") != trace.final_state.get("run_id") or packet.get("mission_id") != trace.final_state.get("mission_id"):
		return Evaluation._bad("execution_packet.execution_key", trace.final_state)
	var reproduced: Dictionary = evaluate_state(trace.final_state)
	if not reproduced.ok:
		return reproduced
	if not packet.evaluation.get("ok") or not Records._equivalent(reproduced.report, packet.evaluation.get("report")):
		return Evaluation._bad("execution_packet.evaluation", trace.final_state)
	var requests: Array = []
	for event: Dictionary in trace.events:
		if event.get("type") in ["action_accepted", "action_blocked"]:
			requests.append({"step_index": event.step_index, "action": event.action})
	var manual: Array = []
	for request in trace.get("manual_actions", []):
		if not request is Dictionary:
			return Evaluation._bad("execution_packet.trace.manual_actions", trace.final_state)
		manual.append({"step_index": request.get("step_index"), "action": request.get("action")})
	var samples: Array = []
	for index in trace.frames.size():
		var frame: Variant = trace.frames[index]
		if not frame is Dictionary or not frame.get("state") is Dictionary or not frame.get("events") is Array:
			return Evaluation._bad("execution_packet.trace.frames", trace.final_state)
		if frame.state.get("run_id") != packet.run_id or frame.state.get("mission_id") != packet.mission_id or frame.state.get("config_snapshot") != trace.config:
			return Evaluation._bad("execution_packet.trace.frames", trace.final_state)
		var accepted: bool = index == 0
		for event in frame.events:
			if event is Dictionary and event.get("type") == "action_accepted":
				accepted = true
		if accepted:
			samples.append({"step_index": frame.state.get("step_index"), "energy_wh": frame.state.get("energy_wh"), "stored_data_mb": frame.state.get("stored_data_mb")})
	for field in ["simulator_sha256", "adapter_sha256", "validator_sha256", "evaluator_sha256", "runner_sha256", "catalog_sha256"]:
		if not trace.versions.get(field) is String or trace.versions[field].length() != 64:
			return Evaluation._bad("execution_packet.trace.versions." + field, trace.final_state)
	var context: Dictionary = {"initial_state": trace.frames[0].state.duplicate(true),
		"catalogs_snapshot": trace.final_state.get("scenario_snapshot", {}).duplicate(true),
		"source_versions": {"engine": trace.versions.simulator_sha256, "adapter": trace.versions.adapter_sha256,
			"catalogs": trace.versions.catalog_sha256, "scenario": trace.final_state.get("scenario_snapshot", {}).get("scenario_version"),
			"evaluator": Evaluation.EVALUATOR_REVISION, "report": Evaluation.REPORT_REVISION,
			"producer_dependencies": trace.versions.duplicate(true)},
		"initialization_policy": "full_battery_empty_v1_proposal", "legacy_identity_policy": "exact_requirements_v1_proposal",
		"verification_scope": "native_modules", "source_credits": packet.get("result_context", {}).duplicate(true),
		"display_context": {"source_report": packet.evaluation.report.duplicate(true), "scoring": "proposal"},
		"operations": {"policy": {"id": str(trace.get("policy", "")), "version": 1,
			"parameters": {"requested_action_plan": trace.get("requested_action_plan", trace.get("action_plan"))}},
			"manual_requests": manual, "requested_actions": requests},
		"resource_samples": samples, "resource_sampling_id": Records.SAMPLING}
	var built: Dictionary = Records.build_record(trace.config, trace.final_state, trace.events, trace.validation, context)
	if built.ok and built.record.execution_key != packet.execution_key:
		return Evaluation._bad("execution_packet.execution_key", trace.final_state)
	return built
