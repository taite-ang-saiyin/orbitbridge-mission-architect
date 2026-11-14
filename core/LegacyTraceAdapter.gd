extends RefCounted
class_name LegacyTraceAdapter

## Exposes legacy fixed-slot RunTrace summaries in Team Contract v1 units.
## The legacy simulator and its event schema remain unchanged and are namespaced.
const WH_PER_WS: float = 3600.0
const KB_PER_MB: float = 1000.0

static func to_v1_units(legacy_result: Dictionary) -> Dictionary:
	if not legacy_result.get("ok", false):
		return _error("LEGACY_RUN_FAILED", str(legacy_result.get("error", "Legacy simulation did not complete.")))
	var metrics: Variant = legacy_result.get("metrics", null)
	var state: Variant = legacy_result.get("state", null)
	var telemetry: Variant = legacy_result.get("telemetry", null)
	var events: Variant = legacy_result.get("events", null)
	if not metrics is Dictionary or not state is Dictionary or not telemetry is Array or not events is Array:
		return _error("INVALID_LEGACY_TRACE", "Legacy result must contain metrics, state, telemetry, and events.")
	for key in ["min_battery_ws", "peak_buffer_kb", "returned_kb", "buffer_kb", "final_battery_ws"]:
		if not _is_number(metrics.get(key, null)):
			return _error("INVALID_LEGACY_TRACE", "Legacy metrics.%s must be a finite number." % key)
	for key in ["current_slot", "elapsed_t_s", "battery_ws", "minimum_battery_ws", "captured", "delivered", "returned_kb", "buffer_kb", "peak_buffer_kb"]:
		if not _is_number(state.get(key, null)):
			return _error("INVALID_LEGACY_TRACE", "Legacy state.%s must be a finite number." % key)
	var packet_queue: Variant = state.get("packet_queue", [])
	if not packet_queue is Array:
		return _error("INVALID_LEGACY_TRACE", "Legacy state.packet_queue must be an array.")
	for index in range(packet_queue.size()):
		var packet: Variant = packet_queue[index]
		if not packet is Dictionary or not _is_number(packet.get("packet_kb", null)) or not _is_number(packet.get("remaining_kb", null)):
			return _error("INVALID_LEGACY_TRACE", "Legacy state.packet_queue[%d] must include finite packet_kb and remaining_kb values." % index)
	var adapted_telemetry: Array[Dictionary] = []
	for index in range(telemetry.size()):
		var row: Variant = telemetry[index]
		if not row is Dictionary or not _is_number(row.get("battery_ws", null)) or not _is_number(row.get("buffer_kb", null)):
			return _error("INVALID_LEGACY_TRACE", "Legacy telemetry[%d] must include finite battery_ws and buffer_kb values." % index)
		adapted_telemetry.append({
			"slot_index": int(row.get("slot", index)),
			"elapsed_time_seconds": int(row.get("t_s", 0)),
			"energy_wh": float(row.battery_ws) / WH_PER_WS,
			"stored_data_mb": float(row.buffer_kb) / KB_PER_MB,
			"observations_completed": int(row.get("captured", 0)),
			"observations_delivered": int(row.get("delivered", 0))
		})
	var adapted_state: Dictionary = {
		"slot_index": int(state.current_slot),
		"completed_steps": int(legacy_result.get("slot_count", 0)),
		"elapsed_time_seconds": int(state.elapsed_t_s),
		"energy_wh": float(state.battery_ws) / WH_PER_WS,
		"minimum_energy_wh": float(state.minimum_battery_ws) / WH_PER_WS,
		"observations_completed": int(state.captured),
		"observations_delivered": int(state.delivered),
		"delivered_by_target": state.get("delivered_by_target", {}).duplicate(true),
		"returned_data_mb": float(state.returned_kb) / KB_PER_MB,
		"stored_data_mb": float(state.buffer_kb) / KB_PER_MB,
		"peak_stored_data_mb": float(state.peak_buffer_kb) / KB_PER_MB,
		"packet_queue": _adapt_packet_queue(state.get("packet_queue", [])),
		"launch_status": str(state.get("launch_status", "")),
		"deployment_status": str(state.get("deployment_status", ""))
	}
	var adapted_metrics: Dictionary = {
		"observations_completed": int(metrics.get("captured", 0)),
		"observations_delivered": int(metrics.get("delivered", 0)),
		"delivered_by_target": metrics.get("delivered_by_target", {}).duplicate(true),
		"minimum_energy_wh": float(metrics.min_battery_ws) / WH_PER_WS,
		"peak_stored_data_mb": float(metrics.peak_buffer_kb) / KB_PER_MB,
		"returned_data_mb": float(metrics.returned_kb) / KB_PER_MB,
		"stored_data_mb": float(metrics.buffer_kb) / KB_PER_MB,
		"energy_wh": float(metrics.final_battery_ws) / WH_PER_WS,
		"total_cost_credits": int(metrics.get("cost_cr", 0))
	}
	return {
		"ok": true,
		"compatibility_kind": "legacy_trace_summary",
		"units": {"energy": "Wh", "data": "decimal MB", "time": "seconds"},
		"source_model_version": str(legacy_result.get("model_version", "")),
		"status": str(legacy_result.get("status", "")),
		"metrics": adapted_metrics,
		"summary": adapted_state,
		"telemetry": adapted_telemetry,
		"legacy_events": events.duplicate(true),
		"legacy_event_schema": "seq_slot_t_s_code_params"
	}

static func _adapt_packet_queue(queue: Variant) -> Array[Dictionary]:
	var adapted: Array[Dictionary] = []
	for packet in queue:
		var row: Dictionary = packet.duplicate(true)
		row["packet_mb"] = float(row.packet_kb) / KB_PER_MB
		row.erase("packet_kb")
		row["remaining_mb"] = float(row.remaining_kb) / KB_PER_MB
		row.erase("remaining_kb")
		adapted.append(row)
	return adapted

static func _is_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "error": {"code": code, "message": message}}
