extends RefCounted
## Read-only recorded sample. Only its explicit SYNTHETIC entry can load it.

const DATA := "res://preview/recorded_ke2/"
var _entry_ref: WeakRef
var _payload: Dictionary = {}
var _missing_link: bool = false
var open_calls: int = 0
var action_calls: int = 0


func _init(entry: Node = null) -> void:
	if is_instance_valid(entry):
		_entry_ref = weakref(entry)


func _active() -> bool:
	var entry: Node = _entry_ref.get_ref() if _entry_ref != null else null
	return is_instance_valid(entry) and entry.is_inside_tree() and entry.get_script().resource_path in ["res://preview/ke2_recorded_preview.gd", "res://preview/ke2_validated_preview.gd"]


func choose_missing_link(value: bool) -> void:
	if _active():
		_missing_link = value


func open_run(run_id: String) -> Dictionary:
	if not _active():
		return {"ok": false, "error": "preview_entry_required"}
	open_calls += 1
	var source: Dictionary = _entry_ref.get_ref().get_recorded_source()
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source.metadata_path))
	if FileAccess.get_sha256(source.report_path) != metadata.report_sha256:
		return {"ok": false, "error": "recorded_report_hash_mismatch"}
	var wrapper: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source.report_path))
	var trace: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source.trace_path))
	if wrapper.get("ok") != true or wrapper.report.run_id != metadata.run_id or wrapper.report.mission_id != metadata.mission_id or trace.run_id != run_id or trace.final_state.run_id != run_id or trace.mission_id != metadata.mission_id:
		return {"ok": false, "error": "recorded_identity_mismatch"}
	var state: Dictionary = trace.final_state.duplicate(true)
	state.events = trace.events.duplicate(true)
	if _missing_link:
		# Remove history only for the negative fixture; report remains untouched.
		state.events = state.events.filter(func(event: Dictionary): return event.event_id != "evt_008")
	var context := {"run_id": run_id, "synthetic_preview": true, "recorded_sample": source.sample_revision, "config": trace.config.duplicate(true), "profile_metadata": {"id": trace.config.design.launch_profile_id, "label": "Profile ID: " + str(trace.config.design.launch_profile_id)}, "source_metadata": {}}
	if source.get("scoped_credit_metadata", false):
		# Separate presentation metadata: do not append these IDs to MissionReport.
		context.applicable_source_credits = metadata.source_credit_metadata.applicable_source_credits.duplicate(true)
		context.attribution_notice = "KE2 versioned metadata / validated component-run preview; SE live and export credit checks pending."
	_payload = {"context": context, "state": state, "report": wrapper.report.duplicate(true)}
	return {"ok": true, "payload": _payload.duplicate(true)}


func request_action(_run_id: String, _action: StringName) -> Dictionary:
	action_calls += 1
	return {"ok": false, "error": "recorded_sample_has_no_simulation" if _active() else "preview_entry_required"}
