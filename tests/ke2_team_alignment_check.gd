extends SceneTree
## Run in the composed owner snapshot documented in the team-alignment handoff.
const Team = preload("res://scripts/evaluation/mission_team_integration.gd")
const Evaluation = preload("res://scripts/evaluation/mission_expansion_candidate.gd")
const Catalog = preload("res://data/mock/DesignCatalog.gd")
var Runtime: Script
var Results: Script
var Lab: Script
var Presenter: Script
var Goals: Script
var Review: Script
var passed: int = 0
var failed: int = 0
var evidence: Dictionary = {}

func check(condition: bool, label: String) -> bool:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL " + label)
	return condition

func settle() -> void:
	for frame in 5:
		await process_frame

func draft_for(config: Dictionary) -> Dictionary:
	var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
	draft.name = config.mission.title
	draft.objective = config.mission.objective
	draft.targets = config.mission.get("target_regions", [config.mission.target_region]).map(func(id): return Runtime.TARGETS.find_key(id))
	draft.target = draft.targets[0]
	draft.target_limit = draft.targets.size()
	draft.observations = config.mission.required_observations
	draft.required_returned_data_mb = config.mission.required_returned_data_mb
	draft.duration = config.mission.duration_orbits
	draft.budget = config.mission.budget_credits
	draft.orbit = Runtime.ORBITS.find_key(config.design.orbit_id)
	for field in ["schema_version", "contract_revision", "preset_id", "preset_revision"]:
		draft[field] = config[field]
	draft.goal = config.mission.goal.duplicate(true)
	draft.engineering_parts = {}
	for field in ["bus", "instrument", "solar", "battery", "radio", "storage"]:
		draft.engineering_parts[field] = config.design[field + "_id"]
	draft.launch_profile_id = config.design.launch_profile_id
	draft.launcher_id = config.design.launcher_id
	Review.confirm(draft, Review.snapshot(draft))
	return draft

func _initialize() -> void:
	create_timer(180).timeout.connect(func(): printerr("FAIL team alignment timeout"); quit(1))
	if not ResourceLoader.exists("res://scripts/core/mission_v2_context.gd") or not ResourceLoader.exists("res://scripts/integration/design_lab.gd"):
		printerr("Run this check inside the composed owner snapshot.")
		quit(1)
		return
	Runtime = load("res://scripts/integration/mission_runtime.gd")
	Results = load("res://scripts/integration/mission_results.gd")
	Lab = load("res://scripts/integration/design_lab.gd")
	Presenter = load("res://scripts/presentation/DebriefPresentation.gd")
	Goals = load("res://scripts/presentation/GoalProgress.gd")
	Review = load("res://scripts/integration/mission_review.gd")
	call_deferred("run")

func run() -> void:
	var loaded: Dictionary = Runtime.load_game_catalogs(true)
	if not check(loaded.ok, "KE1 explicit catalog context loads through SE"):
		printerr(loaded)
		quit(1)
		return
	var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/mission_presets_v2.json"))
	for preset: Dictionary in registry.presets:
		await native_and_ui(preset.config_v2)
	check(evidence.size() == registry.presets.size(), "all authored preset journeys completed")
	DirAccess.make_dir_recursive_absolute("res://exports/check-evidence/team-alignment")
	var file: FileAccess = FileAccess.open("res://exports/check-evidence/team-alignment/results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "failed": failed, "scoring": "proposal", "presets": evidence}, "\t", true, true))
	file.close()
	print("KE2 TEAM ALIGNMENT: %d passed, %d failed, %d presets" % [passed, failed, evidence.size()])
	quit(0 if failed == 0 else 1)

func native_and_ui(config: Dictionary) -> void:
	var id: String = config.preset_id
	var draft: Dictionary = draft_for(config)
	check(Runtime.config_for(draft) == config, "exact authored config propagated " + id)
	var ready: Dictionary = Runtime.review(draft)
	if not check(ready.ready_to_launch, "actual KE1 readiness " + id):
		printerr(ready.errors)
		return
	var launched: Dictionary = Runtime.launch(draft)
	if not check(launched.ok, "actual native v2 initialization " + id):
		printerr(launched)
		return
	check(launched.trace.config == config and launched.trace.final_state.config_snapshot == config, "full goal-bearing native snapshots " + id)
	check(draft.active_run_state.phase == "operating", "precomputed trace does not imply active completion " + id)
	var published: Dictionary = Results.publish(draft, launched.trace.final_state, Callable(Team, "evaluate_state"))
	if not check(published.ok, "SE publishes KE2 report " + id):
		printerr(published)
		return
	check(published.report.schema_version == 2 and published.report.size() == 19, "reviewed report shape " + id)
	var model: Dictionary = Presenter.build(launched.trace, draft.evaluation_store)
	var view: Dictionary = Goals.build(model, launched.trace)
	check(model.state == "report" and view.primary.known and view.data.known, "KE3 consumes actual goal rows " + id)
	check(view.primary.actual == published.report.goal_progress[0].actual, "KE3 supplied actual matches report " + id)
	var key: String = Results.input_key(launched.trace)
	check(not Lab.save_a(draft, key).ok, "Save A rejects active precomputed execution " + id)
	var repeated: Dictionary = Results.publish(draft, launched.trace.final_state, Callable(Team, "evaluate_state"))
	check(repeated.ok and repeated.existing and draft.evaluation_store.history.size() == 1, "duplicate publication is idempotent " + id)
	var invalid: Dictionary = config.duplicate(true)
	if config.mission.objective in ["communication", "weather_monitoring"]:
		invalid.mission.goal["required_positive_contact_steps" if config.mission.objective == "communication" else "required_distinct_orbits"] = 0
		var rejected: Dictionary = load("res://scripts/core/mission_validator.gd").validate(invalid, launched.trace.catalogs_snapshot)
		check(not rejected.ready_to_launch, "zero goal rejected by real readiness " + id)
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.enable_expansion_candidate()
	app.show_screen(0)
	await settle()
	check(app.current.presets.has(config.mission.title) and not app.current.presets[config.mission.title].disabled, "authored mission card available in preview " + id)
	app.current.presets[config.mission.title].pressed.emit()
	await settle()
	check(app.current.screen_id == "MissionCreator" and Runtime.config_for(app.state) == config, "mission card supplies exact KE1 config " + id)
	app.current.next_button.pressed.emit()
	await settle()
	app.current.review_dialog.acknowledgement.button_pressed = true
	app.current.review_dialog.continue_button.pressed.emit()
	await settle()
	check(app.current.screen_id == "SpacecraftBuilder" and Review.is_confirmed(app.state), "mission review and Builder use authored goals " + id)
	app.current.next_button.pressed.emit()
	await settle()
	check(app.current.screen_id == "FlightReadiness" and app.current.validation.ready_to_launch, "readiness widget accepts exact authored config " + id)
	app.current.next_button.pressed.emit()
	await settle()
	if not check(app.state.has("run_trace") and app.current.has_method("skip_to_end"), "controller reached Operations " + id):
		app.queue_free()
		await settle()
		return
	app.current.skip_to_end()
	await settle()
	app.show_screen(5)
	await settle()
	check(app.state.active_run_state.phase == "finished", "actual playback completion " + id)
	var goals: Dictionary = app.current.get_goal_progress()
	check(goals.primary.known and goals.data.known, "visible Debrief has supplied goals " + id)
	var a_key: String = Results.input_key(app.state.run_trace)
	app.current.select_report_tab(3)
	await settle()
	check(app.current.design_lab.is_visible_in_tree(), "Design Lab tab is visible " + id)
	app.current.design_lab.save_button.pressed.emit()
	await settle()
	var saved: Dictionary = app.get_saved_design_a()
	if not check(saved.ok and saved.execution != null and saved.execution.execution_key == a_key, "KE3 Save A uses selected execution " + id):
		printerr(saved)
		app.queue_free()
		await settle()
		return
	if app.flow_error != null and app.flow_error.visible:
		app.flow_error.hide()
	var frozen: Dictionary = saved.execution.duplicate(true)
	check(frozen.result_context.get("execution_key") == a_key and not frozen.result_context.get("applicable_source_credits", []).is_empty(), "scoped readiness credits stay execution-bound " + id)
	var portable: Dictionary = Lab.export_saved_a(app.state)
	check(portable.ok and portable.record.execution_key == a_key and portable.record.report_contract_revision == Evaluation.REPORT_REVISION, "portable saved A retains separate report revision " + id)
	if portable.ok:
		var codec: Script = load("res://scripts/integration/execution_record.gd")
		check(codec.verify(JSON.parse_string(JSON.stringify(portable.record, "", true, true))).ok, "portable saved A survives JSON transport " + id)
	var begun: Dictionary = app.continue_saved_design_a()
	check(begun.ok and app.state.has("design_lab_route"), "SE continues saved A into Builder " + id)
	await settle()
	app.state.engineering_parts.radio = "radio_fast"
	var b_run: Dictionary = app.run_design_b(a_key)
	if not check(b_run.ok, "SE launches fresh B " + id):
		printerr(b_run)
		app.queue_free()
		await settle()
		return
	await settle()
	check(app.state.run_trace.final_state.run_id != frozen.run_id, "fresh B identity " + id)
	app.current.skip_to_end()
	await settle()
	app.show_screen(5)
	await settle()
	var b_key: String = Results.input_key(app.state.run_trace)
	app.current.select_report_tab(3)
	await settle()
	app.current.design_lab.compare_button.pressed.emit()
	await settle()
	var comparison: Dictionary = app.current.design_lab.model.get("comparison", {})
	check(comparison.get("eligible", false) and comparison.get("a_execution_key") == a_key and comparison.get("b_execution_key") == b_key, "KE3 compares exact saved pair " + id)
	check(app.get_saved_design_a().execution == frozen, "B preserves immutable A " + id)
	if not comparison.get("eligible", false):
		printerr("COMPARISON ", app.current.design_lab.model)
	else:
		check(app.current.design_lab.cells.qualifying_count[2].text != "Unavailable", "displayed qualifying delta supplied " + id)
		check(comparison.classification == "Design", "fixed requested plan classified Design " + id)
		for label in app.current.design_lab.grid.get_children():
			if label is Label:
				check(label.size.y >= label.get_line_height() and label.size.x >= label.custom_minimum_size.x, "visible comparison cell fits its text " + id)
	var pair: Dictionary = app.comparison_inputs(b_key)
	if pair.ok:
		var before_pair: Dictionary = pair.duplicate(true)
		check(Team.compare_executions(pair).ok and pair == before_pair, "SE provider preserves source packets " + id)
		pair.a.evaluation.report.score = -1
		check(not Team.compare_executions(pair).ok, "SE provider rejects changed report packet " + id)
	var b_report: Dictionary = app.state.evaluation_store.reports[app.state.active_run_state.run_id]
	evidence[id] = {"a_execution_key": a_key, "b_execution_key": b_key, "a_report": frozen.evaluation.report,
		"b_report": b_report, "comparison": comparison, "scope": "native_v2_modules_and_headless_controller_widgets"}
	print("ALIGNED ", id, " A=", frozen.evaluation.report.status, "/", frozen.evaluation.report.score,
		" B=", b_report.status, "/", b_report.score)
	app.queue_free()
	await settle()
