extends RefCounted
## Presentation projection of actual HPC states. No simulation equations here.
var TOTAL_SECONDS: float = 1.0
var PLAYBACK_RATE: float = 180.0
var EVENTS: Array = []
var TARGET_CAPTURE: Array = []
var TARGET_DELIVERY: Array = []
var frames: Array = []
func configure(trace: Dictionary) -> void:
	EVENTS.clear()
	TARGET_CAPTURE.clear()
	TARGET_DELIVERY.clear()
	frames = trace.frames
	var final: Dictionary = trace.final_state
	var step_hours: float = 0.0
	for orbit in final.scenario_snapshot.orbits:
		if orbit.id == final.scenario_id: step_hours = orbit.step_duration_hours
	TOTAL_SECONDS = final.total_steps * step_hours * 3600.0
	for frame in frames:
		var s: Dictionary = frame.state
		var event: Dictionary = frame.events[0] if not frame.events.is_empty() else {}
		var action: String = str(event.get("action", ""))
		var kind: String = {"observe": "OBSERVE", "transmit": "TX", "power_save": "POWER_SAVE"}.get(action, "START")
		if s.phase == "finished": kind = "MISSION_FINISHED"
		EVENTS.append([kind, s.step_index * step_hours * 3600.0, event.get("message", "Run initialized from validated configuration."), 100.0 * s.energy_wh / s.battery_capacity_wh, 100.0 * s.stored_data_mb / s.storage_capacity_mb, s.observations_completed, s.returned_data_mb, "%.3f MB" % s.returned_data_mb, "Sunlit" if s.is_sunlit else "Eclipse", "—", "Contact" if s.in_ground_contact else "No contact"])
		TARGET_CAPTURE.append(trace.config.mission.get("target_regions", [trace.config.mission.target_region]).map(func(id): return s.get("observations_by_target", {}).get(id, 0)))
		TARGET_DELIVERY.append(trace.config.mission.get("target_regions", [trace.config.mission.target_region]).map(func(id): return s.get("returned_data_by_target_mb", {}).get(id, 0.0)))
func time_label(seconds: float) -> String:
	var whole: int = maxi(0, int(seconds))
	return "%02d:%02d:%02d" % [floori(whole / 3600.0), floori(fmod(whole, 3600) / 60.0), whole % 60]
func index_at(seconds: float) -> int:
	var index: int = 0
	for i in EVENTS.size():
		if seconds >= EVENTS[i][1]: index = i
	return index
