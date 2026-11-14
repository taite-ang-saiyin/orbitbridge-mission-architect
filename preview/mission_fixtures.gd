extends RefCounted
## Literal teaching data only. No equations, random IDs, clocks or live catalogs.

const OPS := "SYNTHETIC-KE3-RUN-OPS-001"
const SUCCESS := "SYNTHETIC-KE3-RUN-SUCCESS-001"
const PARTIAL := "SYNTHETIC-KE3-RUN-PARTIAL-001"
const FAILURE := "SYNTHETIC-KE3-RUN-FAILURE-001"
const MISSING := "SYNTHETIC-KE3-RUN-MISSING-001"
const STALE := "SYNTHETIC-KE3-RUN-STALE-001"
const DANGLING := "SYNTHETIC-KE3-RUN-DANGLING-001"

const MISSION := {
	"mission_id": "SYNTHETIC-KE3-MISSION-001",
	"label": "SYNTHETIC wetland mission - preview only",
	"target_id": "SYNTHETIC-TARGET-DELTA-001",
	"target_label": "SYNTHETIC Delta Wetland",
	"observations_requested": 3,
	"return_threshold_mb": 4,
	"duration_steps": 8,
	"budget_credits": 1200,
	"selected_part_ids": {
		"instrument": "SYNTHETIC-CAMERA-001", "bus": "SYNTHETIC-BUS-001",
		"battery": "SYNTHETIC-BATTERY-001", "solar": "SYNTHETIC-SOLAR-001",
		"storage": "SYNTHETIC-STORAGE-001", "radio": "SYNTHETIC-RADIO-001",
		"launcher": "SYNTHETIC-LAUNCHER-001",
	},
	"selected_orbit_id": "SYNTHETIC-ORBIT-LEO-001",
	"profile_id": "SYNTHETIC-PROFILE-001",
	"profile_label": "SYNTHETIC sample teaching profile; not an HPC profile",
	"source_labels": ["SYNTHETIC illustrative values; no external source confirmation"],
}


func _context(run_id: String) -> Dictionary:
	return {"run_id": run_id, "synthetic": true, "config_selections": MISSION.duplicate(true)}


func _event(run_id: String, suffix: String, step: int, label: String) -> Dictionary:
	return {"run_id": run_id, "event_id": run_id + "-EVENT-" + suffix, "step": step, "label": "SYNTHETIC " + label}


func _case(run_id: String, state: Dictionary, report: Dictionary, expected: Dictionary, action_id: String = "", reply_status: String = "snapshot") -> Dictionary:
	return {"ok": true, "synthetic": true, "action_id": action_id, "reply_status": reply_status,
		"payload": {"context": _context(run_id), "state": state, "report": report}, "expected": expected}


func all_cases() -> Dictionary:
	var ready := _event(OPS, "READY-002", 2, "ready, contact off")
	var observe := _event(OPS, "OBSERVE-003", 3, "Observe allowed")
	var blocked := _event(OPS, "BLOCKED-003", 3, "Downlink blocked: no contact; no step advance")
	var contact := _event(OPS, "CONTACT-004", 4, "contact on")
	var downlink := _event(OPS, "DOWNLINK-005", 5, "Downlink allowed")
	var power_save := _event(OPS, "POWER-SAVE-004", 4, "Power-save allowed")
	var terminal := _event(OPS, "TERMINAL-008", 8, "duration ended")
	var cases := {
		"ready_step_2": _case(OPS,
			{"run_id": OPS, "lifecycle": "ready", "step": 2, "energy_wh": 8, "stored_mb": 2, "returned_mb": 0, "observations_completed": 0, "observations_requested": 3, "contact_on": false, "events": [ready]}, {},
			{"accepted": true, "step": 2, "energy_wh": 8, "stored_mb": 2, "returned_mb": 0, "observations_completed": 0, "observations_requested": 3, "contact_on": false, "lifecycle": "ready"}),
		"observe_allowed": _case(OPS,
			{"run_id": OPS, "lifecycle": "ready", "step": 3, "energy_wh": 7, "stored_mb": 3, "returned_mb": 0, "observations_completed": 1, "observations_requested": 3, "contact_on": false, "events": [ready, observe]}, {},
			{"accepted": true, "step": 3, "energy_wh": 7, "stored_mb": 3, "returned_mb": 0, "observations_completed": 1, "observations_requested": 3, "contact_on": false, "lifecycle": "ready"}, "observe", "allowed"),
		"contact_on": _case(OPS,
			{"run_id": OPS, "lifecycle": "ready", "step": 4, "energy_wh": 7, "stored_mb": 3, "returned_mb": 0, "observations_completed": 1, "observations_requested": 3, "contact_on": true, "events": [ready, observe, contact]}, {},
			{"accepted": true, "step": 4, "energy_wh": 7, "stored_mb": 3, "returned_mb": 0, "observations_completed": 1, "observations_requested": 3, "contact_on": true, "lifecycle": "ready"}),
		"downlink_contact_on": _case(OPS,
			{"run_id": OPS, "lifecycle": "ready", "step": 5, "energy_wh": 6, "stored_mb": 1, "returned_mb": 2, "observations_completed": 1, "observations_requested": 3, "contact_on": true, "events": [ready, observe, contact, downlink]}, {},
			{"accepted": true, "step": 5, "energy_wh": 6, "stored_mb": 1, "returned_mb": 2, "observations_completed": 1, "observations_requested": 3, "contact_on": true, "lifecycle": "ready"}, "downlink", "allowed"),
		"downlink_no_contact": _case(OPS,
			{"run_id": OPS, "lifecycle": "ready", "step": 3, "energy_wh": 7, "stored_mb": 3, "returned_mb": 0, "observations_completed": 1, "observations_requested": 3, "contact_on": false, "events": [ready, observe, blocked]}, {},
			{"accepted": true, "step": 3, "energy_wh": 7, "stored_mb": 3, "returned_mb": 0, "observations_completed": 1, "observations_requested": 3, "contact_on": false, "lifecycle": "ready"}, "downlink", "blocked_no_contact"),
		"power_save": _case(OPS,
			{"run_id": OPS, "lifecycle": "ready", "step": 4, "energy_wh": 8, "stored_mb": 3, "returned_mb": 0, "observations_completed": 1, "observations_requested": 3, "contact_on": false, "events": [ready, observe, blocked, power_save]}, {},
			{"accepted": true, "step": 4, "energy_wh": 8, "stored_mb": 3, "returned_mb": 0, "observations_completed": 1, "observations_requested": 3, "contact_on": false, "lifecycle": "ready"}, "power_save", "allowed"),
		"terminal": _case(OPS,
			{"run_id": OPS, "lifecycle": "terminal", "step": 8, "energy_wh": 5, "stored_mb": 1, "returned_mb": 2, "observations_completed": 1, "observations_requested": 3, "contact_on": false, "events": [ready, observe, contact, downlink, terminal]}, {},
			{"accepted": true, "step": 8, "energy_wh": 5, "stored_mb": 1, "returned_mb": 2, "observations_completed": 1, "observations_requested": 3, "contact_on": false, "lifecycle": "terminal"}),
	}
	# Reports and their state values are authored directly, never evaluated here.
	for specification in [
		{"id": "report_success", "run": SUCCESS, "status": "success", "observations": 3, "returned": 4, "energy": 4, "causes": [], "changes": []},
		{"id": "report_partial", "run": PARTIAL, "status": "partial", "observations": 1, "returned": 2, "energy": 5, "causes": ["SYNTHETIC: only one usable contact window"], "changes": ["SYNTHETIC: choose a higher-contact orbit profile"]},
		{"id": "report_failure", "run": FAILURE, "status": "failed", "observations": 0, "returned": 0, "energy": 0, "causes": ["SYNTHETIC: energy depleted before observations"], "changes": ["SYNTHETIC: select a larger battery"]},
		{"id": "report_missing", "run": MISSING, "status": "missing", "observations": 1, "returned": 2, "energy": 5, "causes": [], "changes": []},
		{"id": "report_stale_run", "run": STALE, "status": "partial", "observations": 1, "returned": 2, "energy": 5, "causes": [], "changes": []},
		{"id": "report_dangling_event", "run": DANGLING, "status": "partial", "observations": 1, "returned": 2, "energy": 5, "causes": [], "changes": []},
	]:
		var run_id: String = specification.run
		var event := _event(run_id, "TERMINAL-008", 8, "report fixture terminal")
		var report := {"run_id": run_id, "status": specification.status,
			"observations_completed": specification.observations, "observations_requested": 3,
			"returned_mb": specification.returned, "return_threshold_mb": 4,
			"causes": specification.causes.duplicate(), "suggested_changes": specification.changes.duplicate(),
			"evidence_event_ids": [event.event_id],
			"credits": [{"source_id": "SYNTHETIC-SOURCE-001", "label": "SYNTHETIC sample source; unconfirmed", "profile_id": "SYNTHETIC-PROFILE-001"}]}
		var expected := {"accepted": true, "status": specification.status,
			"observations_completed": specification.observations, "observations_requested": 3,
			"returned_mb": specification.returned, "return_threshold_mb": 4}
		if specification.id == "report_missing":
			report = {}
			expected = {"accepted": true, "report_present": false}
		if specification.id == "report_stale_run":
			report.run_id = "SYNTHETIC-KE3-RUN-STALE-OTHER-001"
			expected = {"accepted": false, "error": "stale_run_id"}
		if specification.id == "report_dangling_event":
			report.evidence_event_ids = ["SYNTHETIC-EVENT-NOT-IN-RUN-001"]
		cases[specification.id] = _case(run_id,
			{"run_id": run_id, "lifecycle": "terminal", "step": 8, "energy_wh": specification.energy,
			"stored_mb": 0, "returned_mb": specification.returned, "observations_completed": specification.observations,
			"observations_requested": 3, "contact_on": false, "events": [event]}, report, expected)
	return cases
