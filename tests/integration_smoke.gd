extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Catalog = preload("res://data/mock/DesignCatalog.gd")
func _initialize() -> void:
	call_deferred("check")
func settle() -> void:
	for frame in 5: await process_frame
func check() -> void:
	var draft: Dictionary = Catalog.DEFAULTS.duplicate(true)
	Catalog.ensure(draft)
	var valid: Dictionary = Runtime.review(draft)
	assert(valid.ready_to_launch and valid.metrics.total_mass_g == 1060 and valid.metrics.total_cost_credits == 82)
	assert(valid.config.mission.title == draft.name)
	draft.targets = ["Equator", "Unknown target"]
	assert(not Runtime.review(draft).ready_to_launch)
	draft.targets = ["Equator"]
	draft.budget = 81
	assert(not Runtime.launch(draft).ok and not draft.has("run_trace"))
	draft.budget = 100
	draft.wings_id = "dev_wings_2"
	assert(Runtime.review(draft).metrics.total_mass_g == 1180)
	draft.wings_id = "dev_wings_1"
	var launched: Dictionary = Runtime.launch(draft)
	assert(launched.ok)
	var frozen: Dictionary = draft.run_design.duplicate(true)
	draft.name = "Edited after launch"
	assert(draft.run_design == frozen)
	assert(draft.run_trace.final_state.run_status == "completed")
	assert(draft.run_trace.events == draft.run_trace.final_state.event_log)
	var heavy: Dictionary = Catalog.DEFAULTS.duplicate(true)
	Catalog.ensure(heavy)
	heavy.body_id = "dev_body_3"
	assert(not Runtime.review(heavy).ready_to_launch)
	heavy.launch_profile_id = "illustrative_alternative"
	heavy.launcher_id = "medium"
	heavy.budget = 120
	assert(Runtime.review(heavy).ready_to_launch)
	for orbit in Runtime.ORBITS:
		for policy in ["Observe First", "Downlink First"]:
			heavy.orbit = orbit
			heavy.policy = policy
			var actual: Dictionary = Runtime.launch(heavy)
			assert(actual.ok and actual.trace.final_state.run_status == "completed")
			assert(actual.trace.config.design.orbit_id == Runtime.ORBITS[orbit])
	assert(heavy.run_history.size() == 2)
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	for resolution in [Vector2i(1440, 900), Vector2i(1024, 768)]:
		root.size = resolution
		app.show_screen(1)
		await settle()
		assert(not app.current.objective_buttons["Survey Target Regions"].disabled)
		assert(not app.current.target_buttons["Arctic Ice"].disabled)
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.show_screen(2)
		await settle()
		assert("1060" in app.current.total_values.text)
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.show_screen(3)
		await settle()
		assert(not app.current.next_button.disabled)
		assert(app.current.check_buttons.size() == 8)
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.current.next_button.pressed.emit()
		await settle()
		assert(app.current.screen_id == "MissionOperations")
		assert(app.current.DATA.EVENTS.size() == app.state.run_trace.frames.size())
		app.current.step()
		assert(app.current.event_index == 1)
		app.current.skip_to_end()
		assert(not app.current.next_button.disabled)
		assert("MB" in app.current.telemetry.text)
		assert(preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state)))
		app.current.next_button.pressed.emit()
		await settle()
		assert("Score:" in app.current.results.text)
		assert(not "1.24 GB" in app.current.results.text)
		print("PASS integrated player flow at ", resolution)
	app.state.budget = 60
	app.show_screen(4)
	await settle()
	assert(app.current.screen_id == "FlightReadiness" and app.current.next_button.disabled)
	print("PASS real metrics, invalid targets, budget launch gate, snapshots, HPC playback and actual debrief")
	app.queue_free()
	quit(0)
