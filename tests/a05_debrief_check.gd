extends SceneTree
var output_dir: String = "res://verification"
## Automated synthetic evidence only. No evaluation, human playtest or live wiring.

const EXPECTED := {
	"debrief_success": ["success", "completed", "3/3", "4/4 MB", "100%", "100%", "100", "report"],
	"debrief_partial": ["partial", "completed", "1/3", "2/4 MB", "33.33%", "50%", "42", "report"],
	"debrief_failed": ["failed", "completed", "0/3", "0/4 MB", "0%", "0%", "0", "report"],
	"debrief_zero_score": ["failed", "completed", "0/3", "0/4 MB", "0%", "0%", "0", "report"],
	"debrief_aborted": ["failed", "aborted", "3/3", "4/4 MB", "100%", "100%", "Unavailable", "report"],
	"debrief_missing_optional": ["partial", "completed", "1/3", "2/4 MB", "33.33%", "Unavailable", "42", "report"],
	"debrief_missing_score": ["partial", "completed", "1/3", "2/4 MB", "33.33%", "50%", "Unavailable", "report"],
	"debrief_awaiting": ["Awaiting evaluation", "completed", "1/3", "2/4 MB", "Unavailable", "Unavailable", "Unavailable", "awaiting_evaluation"],
	"debrief_stale": ["Unavailable", "Unavailable", "Unavailable/Unavailable", "Unavailable/Unavailable MB", "Unavailable", "Unavailable", "Unavailable", "unavailable"],
	"debrief_missing_event": ["partial", "completed", "1/3", "2/4 MB", "33.33%", "50%", "42", "report"],
	"debrief_long": ["partial", "completed", "1/3", "2/4 MB", "33.33%", "50%", "42", "report"],
	"debrief_evaluation_error": ["Evaluation error", "Unavailable", "Unavailable/Unavailable", "Unavailable/Unavailable MB", "Unavailable", "Unavailable", "Unavailable", "evaluation_error"],
	"debrief_prelaunch": ["Unavailable", "Unavailable", "Unavailable/Unavailable", "Unavailable/Unavailable MB", "Unavailable", "Unavailable", "Unavailable", "readiness_required"],
	"debrief_missing_credit": ["partial", "completed", "1/3", "2/4 MB", "33.33%", "50%", "42", "report"],
}
const METRICS := ["status", "run_status", "observations", "returned", "observation_percent", "return_percent", "score", "presentation_state"]
var entry: Control
var checks: int = 0
var failures: Array[String] = []
var records: Array = []


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	for index in range(arguments.size()):
		if arguments[index] == "--output-dir" and index + 1 < arguments.size():
			output_dir = arguments[index + 1]
	DirAccess.make_dir_recursive_absolute(output_dir)
	_run.call_deferred()


func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)


func same(label: String, expected: Variant, actual: Variant) -> void:
	expect(expected == actual, label)
	records.append({"check": label, "expected": expected, "actual": actual, "status": "FIXTURE PASS" if expected == actual else "FAIL"})


func counts() -> Dictionary:
	return {"action": entry.action_intents, "route": entry.route_intents, "retry": entry.retry_intents, "provider_action": entry.provider.action_calls}


func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(output_dir.path_join("a05-" + name + ".png")) == OK, "capture " + name)


func tab_key() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_TAB
	key.pressed = true
	root.push_input(key)
	key = key.duplicate()
	key.pressed = false
	root.push_input(key)
	await process_frame


func _run() -> void:
	root.size = Vector2i(1280, 960)
	entry = load("res://preview/a05_preview.tscn").instantiate()
	root.add_child(entry)
	await process_frame
	var do_capture := "--capture" in OS.get_cmdline_user_args()
	var original: Dictionary = entry.provider.catalog()
	var baseline := counts()
	for case_id in EXPECTED:
		var result: Dictionary = entry.select_fixture(case_id)
		await process_frame
		await process_frame
		var model: Dictionary = entry.results.get_debrief_model()
		var actual: Array = []
		for metric in METRICS:
			actual.append(model[metric])
		same(case_id + " exact supplied metrics", EXPECTED[case_id], actual)
		same(case_id + " acceptance", case_id != "debrief_stale", result.accepted)
		var labels: Dictionary = entry.results.get_visible_labels()
		records.append({"case": case_id, "visible_labels": labels, "boundary": entry.results._boundary_label.text, "selected_tab": entry._tabs.current_tab})
		if case_id != "debrief_stale":
			same(case_id + " context mission", "SYNTHETIC wetland mission - preview only", model.mission)
			same(case_id + " context goal", "3 observations; 4 MB returned", model.goal)
			same(case_id + " supplied profile", original[case_id].payload.context.profile_metadata.label, model.profile)
		if model.presentation_state == "report":
			same(case_id + " supplied explanation", original[case_id].payload.report.explanation, model.summary)
			same(case_id + " supplied experiment", original[case_id].payload.report.next_experiment, model.next_experiment)
			expect(not entry.results._retry_button.disabled, case_id + " Retry enabled")
			expect(labels.metrics.contains("Score: " + model.score), case_id + " actual score label")
		match case_id:
			"debrief_partial":
				same("Partial exactly one cause", 1, original[case_id].payload.report.root_causes.size())
				expect(model.causes.count("Cause code:") == 1 and model.causes.contains("NO_LINK_WINDOW") and model.causes.contains("Step 4") and model.causes.contains("Transmit blocked: no ground contact at step 4"), "partial supplied cause, event and step")
				expect(model.failed_constraint == "SYNTHETIC returned-data goal", "supplied failed constraint")
			"debrief_aborted":
				same("Abort explanation", "Mission aborted before completion.", model.summary)
			"debrief_awaiting":
				same("Awaiting visible summary", "Awaiting evaluation", model.summary)
			"debrief_stale":
				var stale: Dictionary = original[case_id].payload
				same("Stale report event ID matches current history", stale.state.events[0].event_id, stale.report.root_causes[0].evidence_event_ids[0])
				expect(entry.results.get_input_snapshot().report.is_empty() and not str(labels).contains("MUST NOT BE DISPLAYED"), "stale report cleared despite matching event ID")
				expect(entry.results._boundary_label.text.contains("stale_run_id"), "stale boundary reason visible")
			"debrief_missing_event":
				expect(model.causes.contains("Evidence Unavailable: SYNTHETIC-A05-EVENT-NOT-IN-ACTIVE-RUN") and model.summary.contains("keep this current-run explanation visible"), "missing evidence retains current report and explanation")
				expect(not entry.results.get_input_snapshot().report.is_empty(), "missing evidence report retained by session")
			"debrief_evaluation_error":
				expect(model.summary.contains("INVALID_EVALUATION_INPUT") and model.summary.contains("could not read the final state") and model.summary.contains("Suggested fix:"), "error kept separate from mission outcome")
			"debrief_prelaunch":
				same("Prelaunch stays preview Readiness notice", 2, entry._tabs.current_tab)
				expect(entry._readiness_notice.text.contains("rejected before launch"), "Readiness rejection label")
			"debrief_missing_credit":
				expect(model.credits.contains("Profile source: Unavailable") and model.credits.contains("Profile credit: Unavailable") and model.credits.contains("SYNTHETIC-UNRESOLVED-SOURCE") and model.credits.contains("Title: Unavailable"), "missing source fields are explicit")
		if do_capture:
			entry.results._scroll.scroll_vertical = 0
			await capture(case_id)
	# Supplied ratios/scores are authoritative, even when unlike the raw counters.
	entry.select_fixture("debrief_partial")
	var run_id: String = original.debrief_partial.payload.context.run_id
	entry.session.open_run(run_id)
	var supplied: Dictionary = original.debrief_partial.payload.duplicate(true)
	supplied.report.observation_completion_ratio = 0.125
	supplied.report.score = 17
	same("Modified supplied report accepted", true, entry.session.accept_payload(supplied).accepted)
	same("Ratio formatting never recalculates from 1/3", "12.5%", entry.results.get_debrief_model().observation_percent)
	same("Score never recalculated", "17", entry.results.get_debrief_model().score)
	# Foreign-run history is rejected before any evidence is resolved.
	var foreign := supplied.duplicate(true)
	foreign.state.events[0].run_id = "SYNTHETIC-OTHER-RUN"
	same("Foreign-run event rejected", "stale_event_run_id", entry.session.accept_payload(foreign).error)
	expect(entry.results.get_input_snapshot().report.is_empty(), "foreign history cannot retain evidence")
	# Direct view isolation also refuses the stale report and its source IDs.
	var stale_direct: Dictionary = original.debrief_stale.payload.duplicate(true)
	stale_direct.report.source_ids = ["STALE-SOURCE-MUST-NOT-DISPLAY"]
	entry.results.set_inputs(stale_direct.context, stale_direct.state, stale_direct.report)
	expect(not str(entry.results.get_debrief_model()).contains("STALE-SOURCE-MUST-NOT-DISPLAY"), "direct stale source refs do not leak")
	# Re-entry replaces presentation, never appends causes or emits intents.
	entry.select_fixture("debrief_partial")
	var before: Dictionary = entry.results.get_visible_labels()
	entry.session.enter_screen()
	entry.session.leave_screen()
	entry.session.enter_screen()
	same("Re-entry has no duplicate causes or credits", before, entry.results.get_visible_labels())
	# Long content is scrollable; keyboard path and footer stay inside the window.
	entry.select_fixture("debrief_long")
	await process_frame
	await process_frame
	var scroll: ScrollContainer = entry.results._scroll
	expect(scroll.get_v_scroll_bar().max_value > scroll.size.y, "long explanations and credits overflow into scroll")
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await process_frame
	expect(scroll.scroll_vertical > 0, "scroll position can reach long content")
	entry.results._credits_button.pressed.emit()
	await process_frame
	expect(scroll.scroll_vertical > 0 and entry.results.get_visible_labels().credits.contains("End of synthetic source credit."), "long credits reachable with credits shortcut")
	scroll.grab_focus()
	await tab_key()
	same("Keyboard Tab reaches credits", entry.results._credits_button, root.gui_get_focus_owner())
	await tab_key()
	same("Keyboard Tab reaches Retry", entry.results._retry_button, root.gui_get_focus_owner())
	var retry: Button = entry.results._retry_button
	records.append({"check": "long content footer geometry", "window": str(root.size), "viewport": str(root.get_visible_rect()), "retry_rect": str(retry.get_global_rect()), "scroll": scroll.scroll_vertical, "scroll_max": scroll.get_v_scroll_bar().max_value})
	expect(retry.get_global_rect().position.y >= 0 and retry.get_global_rect().end.y <= root.size.y, "Retry footer visible below long content")
	var focus: StyleBoxFlat = retry.get_theme_stylebox("focus")
	expect(focus.border_width_left == 3 and focus.border_color.a == 1.0, "visible keyboard focus style")
	if do_capture:
		await capture("long-credits-keyboard-focus")
		root.size = Vector2i(900, 680)
		await process_frame
		await process_frame
		expect(retry.get_global_rect().end.y <= root.size.y and retry.get_global_rect().end.x <= root.size.x, "resized window keeps Retry visible")
		await capture("long-resized")
	same("Rendering, evidence, scrolling, focus, re-entry and resize emit zero intents/provider actions", baseline, counts())
	same("Fixture inputs unchanged", original, entry.provider.catalog())
	var unmounted = preload("res://preview/a05_provider.gd").new()
	same("A05 fixtures require mounted explicit preview entry", {}, unmounted.catalog())
	same("A05 unmounted provider cannot open a run", "preview_entry_required", unmounted.open_run(run_id).error)
	var file := FileAccess.open(output_dir.path_join("a05-results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "metrics_order": METRICS, "records": records, "intent_counts": counts(), "renderer": RenderingServer.get_current_rendering_method(), "evidence": "SYNTHETIC / automated fixture", "human_playtest": "NOT TESTED"}, "  "))
	file.close()
	print("SYNTHETIC A05: ", checks, " checks; ", failures.size(), " failures")
	print("FIXTURE PASS" if failures.is_empty() else "FAIL")
	entry.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
