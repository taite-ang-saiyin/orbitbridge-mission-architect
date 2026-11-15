extends SceneTree
## Review acceptance tests for SE's components-only B UI contract.
## Run separately on SE's patch. Known guard/Creator failures are not suppressed.
var passed: int = 0
var failed: int = 0
var records: Dictionary = {"scope":"SE_PATCH_REVIEW_NOT_MAIN_ACCEPTANCE", "cases":{}, "launch_policy_under_test":"B launcher/profile fixed to match existing UI; final owner decision pending"}
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1; printerr("FAIL: " + label)
func settle() -> void:
	for frame in 8: await process_frame
func run() -> void:
	if not FileAccess.file_exists("res://scripts/integration/design_lab.gd"):
		printerr("BLOCKED_SE_PATCH_MISSING: run this separate test on the SE patch; it is not part of main's default runner.")
		quit(2); return
	var runtime: Variant = load("res://scripts/integration/mission_runtime.gd")
	var lab: Variant = load("res://scripts/integration/design_lab.gd")
	var results: Variant = load("res://scripts/integration/mission_results.gd")
	var catalog: Variant = load("res://data/mock/DesignCatalog.gd")
	var review: Variant = load("res://scripts/integration/mission_review.gd")
	var draft: Dictionary = catalog.DEFAULTS.duplicate(true)
	draft.schema_version=2; draft.contract_revision="expansion-goals-v2-draft-2"; draft.preset_id="communication"; draft.preset_revision=2
	draft.objective="communication"; draft.goal={"kind":"communication_contacts","required_positive_contact_steps":2}
	var mapped: Dictionary = runtime.config_for(draft)
	check(mapped.schema_version==2 and mapped.preset_id=="communication" and mapped.preset_revision==2 and mapped.mission.goal==draft.goal,"SE propagates full supplied v2 identity/goal")
	check(review.confirm(draft,review.snapshot(draft)),"Review confirms exact supplied draft")
	draft.goal.required_positive_contact_steps=3
	check(not review.is_confirmed(draft),"Goal edit invalidates review")
	draft.goal.required_positive_contact_steps=2
	check(review.confirm(draft,review.snapshot(draft)),"Review refreshed")
	draft.preset_revision=3
	check(not review.is_confirmed(draft),"Revision edit invalidates review")
	check(not runtime.review(draft).ready_to_launch and not runtime.launch(draft).ok,"Supplied v2 fields do not bypass production launch guards")
	for variant in ["launcher_only","profile_only","launcher_and_profile"]:
		var state: Dictionary = catalog.DEFAULTS.duplicate(true)
		state.budget=200; state.run_session_id="k28_"+variant
		if variant=="profile_only": state.launcher_id="medium"
		var initial: Dictionary = runtime.launch(state)
		check(initial.ok,variant+": baseline Imaging run launches")
		if not initial.ok: continue
		state.active_run_state=state.run_trace.final_state.duplicate(true)
		var publication: Dictionary = results.publish(state,state.active_run_state)
		check(publication.ok,variant+": baseline has actual report")
		if not publication.ok: continue
		var key: String = results.input_key(state.run_trace)
		check(lab.save_a(state,key).ok,variant+": explicit Save A succeeds")
		var original: Dictionary = lab.saved_a(state).execution
		var edit: Dictionary = lab.modify_execution(state,key)
		check(edit.ok,variant+": owned B draft created")
		if not edit.ok: continue
		var changed: Dictionary = edit.draft
		if variant!="profile_only": changed.launcher_id="medium"
		if variant!="launcher_only": changed.launch_profile_id="illustrative_alternative"
		var ready: Dictionary = runtime.review(changed)
		check(ready.ready_to_launch,variant+": modified launch setup is physically valid, isolating the contract guard")
		var launched: Dictionary = lab.launch_b(changed,key)
		check(not launched.ok,variant+": launch_b rejects changes locked by the B UI")
		# Independently create an eligible completed execution to test comparison's
		# own boundary even after launch_b is fixed. Do not alter SE source.
		var independent: Dictionary = lab.modify_execution(state,key).draft
		independent.erase("design_lab_route")
		if variant!="profile_only": independent.launcher_id="medium"
		if variant!="launcher_only": independent.launch_profile_id="illustrative_alternative"
		var source: Dictionary = original.trace
		var run_b: Dictionary = runtime.launch(independent,{}, {"catalogs_snapshot":source.catalogs_snapshot,"action_plan":source.get("requested_action_plan",source.action_plan)})
		check(run_b.ok,variant+": independent changed-design execution exists for comparison-boundary test")
		if not run_b.ok: continue
		independent.active_run_state=independent.run_trace.final_state.duplicate(true)
		check(results.publish(independent,independent.active_run_state).ok,variant+": independent changed execution evaluated")
		var b_key: String = results.input_key(independent.run_trace)
		var compared: Dictionary = lab.comparison_inputs(independent,b_key)
		check(not compared.ok,variant+": comparison_inputs rejects launch setup changes independently")
		check(lab.saved_a(independent).execution==original,variant+": A preserved through independently created B")
		records.cases[variant]={"physical_ready":ready.ready_to_launch,"launch_b_accepted":launched.ok,"comparison_inputs_accepted":compared.ok,"expected_under_components_only_policy":"both boundaries reject","a_preserved":lab.saved_a(independent).execution==original}
	# Exercise Creator's actual callback; a goal-type change must update lineage
	# and goal together, or explicitly refuse that transition.
	var app: Variant = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app); await settle()
	app.state.schema_version=2; app.state.contract_revision="expansion-goals-v2-draft-2"; app.state.preset_id="estuary_watch"; app.state.preset_revision=1; app.state.goal={"kind":"imaging"}; app.state.objective="Capture Imagery"
	review.confirm(app.state,review.snapshot(app.state))
	app.show_screen(1); await settle()
	app.current.objective_buttons["Survey Target Regions"].pressed.emit()
	await settle()
	var blocked: bool = app.state.objective=="Capture Imagery"
	var transitioned: bool = app.state.objective=="Survey Target Regions" and app.state.get("preset_id")=="polar_ice_survey" and app.state.get("goal",{}).get("kind")=="survey_delivery"
	check(blocked or transitioned,"Creator goal-type change updates matching lineage/goal or refuses the edit")
	check(blocked or not review.is_confirmed(app.state),"Accepted goal-type change invalidates old review")
	records.creator={"objective":app.state.objective,"preset_id":app.state.get("preset_id"),"goal":app.state.get("goal"),"transition_consistent_or_blocked":blocked or transitioned,"scope":"authored five-preset transition proposal; final custom identity still pending"}
	app.queue_free(); await settle()
	records.passed=passed; records.failed=failed
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if not args.is_empty():
		DirAccess.make_dir_recursive_absolute(args[0])
		var file=FileAccess.open(args[0].path_join("se-owner-contract-check.json"),FileAccess.WRITE)
		if file!=null: file.store_string(JSON.stringify(records,"  "));file.close()
	print("SE owner-contract preparation: %d checks passed; %d failed." % [passed,failed])
	quit(0 if failed==0 else 1)
