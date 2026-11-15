extends SceneTree
const Results = preload("res://scripts/integration/mission_results.gd")
const Lab = preload("res://scripts/integration/design_lab.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
var checks: int = 0
func _initialize() -> void: call_deferred("check")
func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error("FAIL: " + message)
		quit(1)
		assert(value, message)
func settle() -> void:
	for frame in 8: await process_frame
func finish(app: Control) -> String:
	app.current.skip_to_end()
	return Results.input_key(app.state.run_trace)
func check() -> void:
	check_contract_propagation()
	root.size = Vector2i(1280, 720)
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	expect(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)), "Acknowledged test fixture")
	app.show_screen(3)
	app.current.next_button.pressed.emit()
	await settle()
	var a_key: String = finish(app)
	expect(app.get_saved_design_a().execution == null, "Completed run never silently becomes saved A")
	expect(app.offer_design_b(a_key).ok, "Save A opens continuation offer")
	var offer = app.get_node("DesignASavedDialog")
	expect(offer.cancel_button_text == "Not now", "Continuation has Not now")
	offer.canceled.emit()
	await settle()
	expect(app.get_saved_design_a().execution.execution_key == a_key, "Not now preserves saved A")
	var original: Dictionary = app.get_execution(a_key).execution
	var exported: Dictionary = app.export_saved_design_a()
	expect(exported.ok, "Export saved A with original hash bytes")
	var portable = preload("res://scripts/integration/execution_record.gd")
	expect(portable.verify(JSON.parse_string(JSON.stringify(exported.record, "", true, true))).ok, "Saved A survives portable JSON roundtrip")
	expect(exported.record.execution_key == a_key, "Export keeps original runtime execution key")
	var args = OS.get_cmdline_user_args()
	if not args.is_empty() and args[0].ends_with(".json"):
		var file = FileAccess.open(args[0], FileAccess.WRITE)
		file.store_string(JSON.stringify(exported.record, "\t", true, true))
		file.close()
	expect(original.trace.frames.size() > 1 and original.trace.has("catalogs_snapshot"), "Full frames/catalogs retained")
	expect(original.trace.has("draft_snapshot") and original.trace.has("versions") and original.trace.has("action_plan"), "Draft/versions/plan retained")
	var copy: Dictionary = app.get_saved_design_a().execution
	copy.trace.config.mission.title = "Mutated return value"
	copy.trace.frames[0].state.energy_wh = 0
	copy.evaluation.report.score = -1
	expect(app.get_saved_design_a().execution == original, "Public getters return isolated copies")
	var recorded: Dictionary = app.state.evaluation_store.duplicate(true)
	expect(app.on_terminal_state(app.state.active_run_state).ok, "Duplicate terminal notification idempotent")
	expect(app.state.evaluation_store == recorded, "Duplicate keeps every execution byte unchanged")
	expect(app.continue_saved_design_a().ok, "Continue B uses saved A")
	await settle()
	app.current.review_saved_a()
	var reference = app.current.get_child(app.current.get_child_count() - 1)
	expect(reference is AcceptDialog and reference.title == "Design A · read-only", "Builder has read-only A reference")
	reference.confirmed.emit()
	expect(not app.cancel_design_b("wrong-key").ok, "Cancel rejects wrong origin")
	expect(app.cancel_design_b(a_key).ok, "Cancel selected B draft")
	await settle()
	expect(app.current.get_presentation_model().execution_key == a_key, "Cancel displays selected A, not latest run")
	expect(app.get_saved_design_a().execution == original, "Cancel leaves A unchanged")
	expect(app.continue_saved_design_a().ok, "Begin B again from saved A")
	await settle()
	app.current.select_component("radio_id", "dev_radio_2")
	expect(not app.clear_design_a(a_key).ok, "No clearing baseline under an active draft")
	app.show_screen(3)
	await settle()
	expect(app.current.next_button.text == "Launch Design B", "Readiness identifies B launch")
	app.current.next_button.pressed.emit()
	expect(app.state.active_run_state.phase == "operating", "B launches through Readiness button")
	await settle()
	expect(app.state.active_run_state.run_id != original.run_id, "B has a fresh run ID")
	expect(app.state.active_run_state.step_index == 0 and app.state.active_run_state.event_log.is_empty(), "B starts with clean counters/events")
	expect(not app.replace_design_a(a_key,a_key).ok, "Live-run baseline edits rejected")
	var b_key: String = finish(app)
	expect(app.get_saved_design_a().execution == original, "B publication never overwrites A")
	expect(app.continue_saved_design_a().ok, "Continue from B Results still selects A")
	await settle()
	expect(app.state.design_lab_route.origin_execution_key == a_key, "Selected B cannot become B origin implicitly")
	app.show_screen(1)
	expect(app.current.screen_id == "SpacecraftBuilder", "B cannot navigate into editable mission Creator")
	expect(app.cancel_design_b(a_key).ok, "Cancel after B results preserves origin")
	await settle()
	var inputs: Dictionary = app.comparison_inputs(b_key)
	expect(inputs.ok and inputs.mode == "controlled_design", "Matching recorded scenario and requested action plan")
	expect(inputs.b.trace.requested_action_plan == original.trace.action_plan, "B reruns A's requests, not its resource outcomes")
	expect(app.compare_executions(b_key).ok, "Recorded comparison provider is connected")
	app.comparison_provider = Callable()
	expect(not app.compare_executions(b_key).ok, "Missing provider remains explicit")
	app.comparison_provider = func(pair): return {"ok":true,"comparison":{"a_execution_key":pair.a.execution_key,"b_execution_key":pair.b.execution_key,"test_provider":true}}
	expect(app.compare_executions(b_key).ok, "Execution-bound Compare callback")
	app.comparison_provider = func(_pair): return {"ok":true,"comparison":{"a_execution_key":"foreign","b_execution_key":b_key}}
	expect(not app.compare_executions(b_key).ok, "Reject comparison for another execution")
	expect(not app.save_design_a(b_key).ok, "Save never implicitly replaces A")
	# An unchanged design replay produces the same actual counters/outcome.
	var identical: Dictionary = Lab.modify_execution(app.state,a_key).draft
	expect(Lab.launch_b(identical,a_key).ok, "Identical design replay launches")
	identical.active_run_state = identical.run_trace.final_state.duplicate(true)
	var same_report: Dictionary = Results.publish(identical,identical.active_run_state)
	expect(same_report.ok, "Identical replay evaluated")
	for field in ["status","score","observations_completed","returned_data_mb"]:
		expect(same_report.report[field] == original.evaluation.report[field], "Identical input preserves " + field)
	# A real manual action is retained and labelled separately from hardware changes.
	var manual: Dictionary = Lab.modify_execution(app.state,a_key).draft
	expect(Lab.launch_b(manual,a_key).ok, "Manual test B launched")
	expect(Runtime.take_action(manual,"power_save").ok, "Real manual action executed")
	manual.active_run_state = manual.run_trace.final_state.duplicate(true)
	expect(Results.publish(manual,manual.active_run_state).ok, "Manual execution published")
	var manual_pair: Dictionary = Lab.comparison_inputs(manual,Results.input_key(manual.run_trace))
	expect(manual_pair.ok and manual_pair.mode == "design_and_operations", "Manual difference is not attributed to hardware alone")
	# Different mission requirements may run independently, but cannot be compared.
	var unrelated: Dictionary = app.state.duplicate(true)
	Results.retry(unrelated)
	unrelated.duration = 3
	expect(Runtime.launch(unrelated).ok, "Independent changed mission can run")
	unrelated.active_run_state = unrelated.run_trace.final_state.duplicate(true)
	expect(Results.publish(unrelated,unrelated.active_run_state).ok, "Independent changed mission evaluated")
	expect(not Lab.comparison_inputs(unrelated,Results.input_key(unrelated.run_trace)).ok, "Changed mission pair rejected")
	# Aborted executions remain stored as history and are never eligible A/B inputs.
	app.retry_mission()
	await settle()
	app.abort_current_run("Design Lab hook test")
	await settle()
	var aborted_key: String = Results.input_key(app.state.run_trace)
	expect(app.get_execution(aborted_key).ok, "Aborted execution evidence retained")
	expect(not Lab.eligible(app.state,aborted_key).ok, "Aborted execution is ineligible for A/B")

	# Tampering is detected even for frames omitted from the legacy KE2 input key.
	var bad_session: Dictionary = app.state.duplicate(true)
	bad_session.evaluation_store.executions[a_key].trace.frames[0].state.energy_wh = 0
	expect(not Results.get_execution(bad_session,a_key).ok, "Archive detects frame tampering")
	var history_backup: Array = app.state.run_history.duplicate(true)
	var victim: Dictionary = app.state.run_history.back()
	var victim_final: Dictionary = victim.final_state.duplicate(true)
	victim.frames[0].state.energy_wh = 0
	var mismatch: Dictionary = app.on_terminal_state(victim_final)
	expect(not mismatch.ok and mismatch.error.code == "IMMUTABLE_EXECUTION_MISMATCH", "Same native state cannot replace its recorded launch evidence")
	app.state.run_history = history_backup
	# A remains retrievable after the runtime's two-trace cache evicts it.
	for i in 3:
		app.retry_mission()
		await settle()
		finish(app)
	expect(not app.state.run_history.any(func(trace): return trace.final_state.run_id == original.run_id), "Old run evicted from short playback cache")
	expect(app.get_execution(a_key).execution == original, "Complete saved execution survives cache eviction")
	expect(app.modify_execution(a_key).ok, "Modify an older selected execution")
	await settle()
	app.state.duration = 3
	expect(not app.run_design_b(a_key).ok, "Changed mission blocks controlled B launch")
	expect(app.cancel_design_b(a_key).ok, "Cancel older draft restores selected A")
	await settle()
	expect(app.current.get_presentation_model().execution_key == a_key, "Older A is still displayed after Cancel")
	expect(not app.replace_design_a(b_key, "stale").ok, "Replace compare-and-set rejects stale A")
	expect(app.replace_design_a(b_key,a_key).ok, "Explicit baseline replacement")
	expect(not app.clear_design_a(a_key).ok, "Clear rejects stale A")
	expect(app.clear_design_a(b_key).ok and app.get_saved_design_a().execution == null, "Explicit clear")
	expect(app.get_execution(a_key).ok and app.get_execution(b_key).ok, "Clear retains historical evidence")
	app.start_new_mission()
	await settle()
	expect(not app.state.has("design_lab") and not app.state.has("evaluation_store"), "New Mission clears session comparison")
	print("PASS SE Design Lab hooks: ",checks," checks passed")
	app.queue_free()
	quit(0)

func check_contract_propagation() -> void:
	var draft: Dictionary = preload("res://data/mock/DesignCatalog.gd").DEFAULTS.duplicate(true)
	var legacy: Dictionary = Runtime.config_for(draft)
	expect(legacy.schema_version == 1 and not legacy.mission.has("goal"), "Legacy mapping unchanged")
	# Synthetic identity/goal fixture only: introduces no authored mission values.
	draft.schema_version = 2
	draft.contract_revision = "review-fixture"
	draft.preset_id = "test-only"
	draft.preset_revision = 1
	draft.goal = {"kind":"imaging"}
	var config: Dictionary = Runtime.config_for(draft)
	expect(config.schema_version == 2 and config.contract_revision == draft.contract_revision, "Supplied schema/revision preserved")
	expect(config.preset_id == draft.preset_id and config.preset_revision == draft.preset_revision, "Supplied preset identity preserved")
	expect(config.mission.goal == draft.goal, "Nested goal propagated")
	config.mission.goal.kind = "changed"
	expect(draft.goal.kind == "imaging", "Goal config is an isolated copy")
	var review = preload("res://scripts/integration/mission_review.gd")
	expect(review.confirm(draft, review.snapshot(draft)), "Review snapshots supplied contract")
	draft.goal.kind = "changed"
	expect(not review.is_confirmed(draft), "Goal edit invalidates review")
	draft.goal.kind = "imaging"
	draft.preset_revision = 2
	expect(not review.is_confirmed(draft), "Preset revision edit invalidates review")
	expect(not Runtime.review(draft).ready_to_launch, "Unimplemented v2 validation remains blocked")
	expect(not Runtime.launch(draft).ok, "V2 never launches through v1 fallback")
