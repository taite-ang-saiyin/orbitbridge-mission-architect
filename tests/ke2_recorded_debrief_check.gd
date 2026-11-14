extends SceneTree
## FIXTURE evidence with KE2's recorded sample, not production integration.

const DATA := "res://preview/recorded_ke2/"
var entry: Control
var checks: int = 0
var failures: Array[String] = []
var records: Array = []
var output_dir: String = "res://verification"
var capture_enabled: bool = false


class FailedProvider:
	extends RefCounted
	func open_run(_run_id: String) -> Dictionary:
		return {"ok": false, "error": "RECORDED_CHECK_PROVIDER_ERROR"}


func _initialize() -> void:
	_run.call_deferred()
	create_timer(30).timeout.connect(func(): quit(1))


func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		push_error(label)


func same(label: String, expected: Variant, actual: Variant) -> void:
	expect(expected == actual, label)
	records.append({"check": label, "expected": expected, "actual": actual, "status": "FIXTURE PASS" if expected == actual else "FAIL"})


func capture(name: String) -> void:
	if not capture_enabled:
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(output_dir.path_join(name + ".png")) == OK, "capture " + name)


func assert_metrics(label: String) -> void:
	var model: Dictionary = entry.results.get_debrief_model()
	same(label + " supplied status/run status", ["partial", "completed"], [model.status, model.run_status])
	same(label + " observations", "1/4", model.observations)
	same(label + " returned decimal MB", "7.7333333328/30 MB", model.returned)
	same(label + " supplied ratios formatted", ["25%", "25.78%"], [model.observation_percent, model.return_percent])
	same(label + " supplied score", "25", model.score)
	same(label + " supplied experiment", "Retry and transmit during an available ground-contact window.", model.next_experiment)
	records.append({"case": label, "actual_visible_labels": entry.results.get_visible_labels()})


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--output-dir" and i + 1 < args.size():
			output_dir = args[i + 1]
	capture_enabled = "--capture" in args
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1280, 960)
	var wrapper: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA + "ke2-hpc-report-v0.1.json"))
	var sidecar: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA + "ke2-hpc-report-v0.1.metadata.json"))
	var trace: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA + "hpc-ke2-trace-ce478f9.json"))
	var original_report: Dictionary = wrapper.report.duplicate(true)
	same("Report bytes hash matches supplied sidecar", sidecar.report_sha256, FileAccess.get_sha256(DATA + "ke2-hpc-report-v0.1.json"))
	same("Wrapper accepted", true, wrapper.ok)
	same("Report and sidecar identity", [sidecar.run_id, sidecar.mission_id], [original_report.run_id, original_report.mission_id])
	same("Full pinned trace terminal snapshot", [60.0, 60.0, "finished", "completed"], [trace.final_state.step_index, trace.final_state.total_steps, trace.final_state.phase, trace.final_state.run_status])
	same("Full pinned ordered history", 62, trace.events.size())
	entry = load("res://preview/ke2_recorded_preview.tscn").instantiate()
	root.add_child(entry)
	await process_frame
	await process_frame
	same("Existing A05 Results scene path", "res://ke3/results_control.tscn", entry.results.scene_file_path)
	same("Report unwrapped and accepted without altered fields", original_report, entry.results.get_input_snapshot().report)
	same("Original config unchanged", trace.config, entry.results.get_input_snapshot().context.config)
	same("Accepted full history order/content unchanged", trace.events, entry.results.get_input_snapshot().state.events)
	var accepted_state: Dictionary = entry.results.get_input_snapshot().state
	accepted_state.erase("events")
	same("Original terminal state unchanged apart from presentation history envelope", trace.final_state, accepted_state)
	assert_metrics("Recorded full-history report")
	same("Explanation unchanged", original_report.explanation, entry.results.get_debrief_model().summary)
	var index: Dictionary = entry.results._event_index()
	var blocked: Dictionary = index.evt_008
	var transmitted: Dictionary = index.evt_007
	same("evt_008 is the step8 no-contact block", [8.0, "transmit", "action_blocked", "NO_LINK_WINDOW"], [blocked.step_index, blocked.action, blocked.type, blocked.code])
	same("evt_007 stays successful transmission", [7.0, "transmit", "action_accepted", "ACTION_ACCEPTED"], [transmitted.step_index, transmitted.action, transmitted.type, transmitted.code])
	same("evt_007 transmitted amount", 7.7333333328, transmitted.data_transmitted_mb)
	var causes: String = entry.results.get_debrief_model().causes
	expect(causes.contains("Evidence: evt_008 | Step 8 | No ground station contact window is available during this step."), "Actual cause label resolves same-run evt_008 message/step")
	expect(not causes.contains("LOW_BATTERY") and not causes.contains("Evidence: evt_007"), "No documentation-example cause substituted or invented")
	same("Exactly one supplied cause", 1, causes.count("Cause code:"))
	records.append({"event_007_same_run_lookup": transmitted, "event_007_evidence_formatter": entry.results._evidence_text(["evt_007"], index), "event_008_same_run_lookup": blocked})
	same("Empty source_ids preserved", [], entry.results.get_input_snapshot().report.source_ids)
	same("Null comparison preserved", null, entry.results.get_input_snapshot().report.comparison)
	var labels: Dictionary = entry.results.get_visible_labels()
	expect(not labels.credits.contains("Source ID:") and not labels.credits.contains("NASA") and not labels.credits.contains("http"), "No report credit created for empty source_ids")
	expect(not labels.has("comparison") and entry.results._fields.size() == 7, "No comparison display added for null comparison")
	expect(labels.credits.contains("Profile source: Unavailable") and labels.credits.contains("Profile credit: Unavailable"), "Selected profile ID does not invent a source credit")
	await capture("ke2-recorded-debrief")
	entry.results._credits_button.pressed.emit()
	await capture("ke2-recorded-evidence-credits")
	same("Missing-linked-event history accepted", true, entry.show_case(true).accepted)
	assert_metrics("Missing linked event report")
	same("Missing evidence keeps whole supplied report", original_report, entry.results.get_input_snapshot().report)
	same("Missing evidence keeps explanation", original_report.explanation, entry.results.get_debrief_model().summary)
	expect(entry.results.get_debrief_model().causes.contains("Evidence Unavailable: evt_008 (not in active run)"), "Missing event visibly unavailable")
	same("Only requested linked event removed in negative fixture", 61, entry.results.get_input_snapshot().state.events.size())
	same("evt_007 still accepted in missing-link fixture", "action_accepted", entry.results._event_index().evt_007.type)
	entry.results._credits_button.pressed.emit()
	await capture("ke2-recorded-missing-evidence")
	entry.show_case(false)
	var before_labels: Dictionary = entry.results.get_visible_labels()
	entry.session.leave_screen()
	entry.session.enter_screen()
	same("Re-entry no duplicate causes/credits", before_labels, entry.results.get_visible_labels())
	same("Re-entry retains exactly62 events", 62, entry.results.get_input_snapshot().state.events.size())
	same("Preview emitted no intents", {"action": 0, "route": 0, "retry": 0}, entry.intent_counts)
	same("Rendering/evidence lookup made no action calls", 0, entry.provider.action_calls)
	var unmounted = preload("res://preview/ke2_recorded_provider.gd").new()
	same("Recorded sample requires explicit mounted entry", "preview_entry_required", unmounted.open_run(sidecar.run_id).error)
	var old_opens: int = entry.provider.open_calls
	entry.session.bind_provider(FailedProvider.new())
	same("Failed injected provider remains failed", "RECORDED_CHECK_PROVIDER_ERROR", entry.session.open_run(sidecar.run_id).error)
	same("Provider failure cannot activate recorded sample fallback", old_opens, entry.provider.open_calls)
	expect(entry.results.get_input_snapshot().report.is_empty(), "Provider failure clears display")
	same("Report resource bytes still match sidecar", sidecar.report_sha256, FileAccess.get_sha256(DATA + "ke2-hpc-report-v0.1.json"))
	var file := FileAccess.open(output_dir.path_join("ke2-recorded-results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "records": records, "scope": "FIXTURE with KE2 recorded sample; no B02", "hpc_sha": "ce478f94a918047c0449fe30bfffe18f368315fd", "evaluator_sha_recorded_by_ke2": sidecar.evaluator.commit_sha, "run_id": sidecar.run_id, "mission_id": sidecar.mission_id, "report_sha256": sidecar.report_sha256, "renderer": RenderingServer.get_current_rendering_method()}, "  "))
	file.close()
	print("KE2 RECORDED SAMPLE DEBRIEF: ", checks, " checks; ", failures.size(), " failures")
	print("FIXTURE PASS with KE2 recorded sample" if failures.is_empty() else "FAIL")
	entry.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
