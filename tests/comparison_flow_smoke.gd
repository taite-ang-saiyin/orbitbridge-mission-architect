extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Review = preload("res://scripts/integration/mission_review.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
func _initialize() -> void:
	create_timer(90).timeout.connect(func(): push_error("Comparison flow timeout"); quit(1))
	call_deferred("run")
func settle() -> void:
	for frame in 10: await process_frame
func run() -> void:
	for preset in [["Estuary Watch","imaging"],["Tropical Forest Watch","imaging"],["Polar Ice Survey","survey"],["Communication","communication"],["Weather Monitoring","weather_monitoring"]]:
		var objective: String = preset[1]
		root.size = Vector2i(1280,720)
		var app = load("res://scenes/Main.tscn").instantiate()
		root.add_child(app)
		await settle()
		app.show_screen(0)
		await settle()
		app.current.presets[preset[0]].pressed.emit()
		await settle()
		assert(Review.confirm(app.state,Review.snapshot(app.state)))
		assert(Runtime.launch(app.state).ok)
		app.show_screen(4)
		await settle()
		app.current.skip_to_end()
		await settle()
		app.show_screen(5)
		await settle()
		var a_key: String = Results.input_key(app.state.run_trace)
		var saved: Dictionary = app.save_design_a(a_key)
		if not saved.ok: print(saved); quit(1); return
		var original: Dictionary = app.get_saved_design_a().execution.duplicate(true)
		assert(app.continue_saved_design_a().ok)
		await settle()
		var radio: String = "radio_basic" if original.trace.config.design.radio_id == "radio_fast" else "radio_fast"
		app.state.engineering_parts = {"radio":radio}
		assert(Review.confirm(app.state,Review.snapshot(app.state)))
		app.show_screen(3)
		await settle()
		app.current.next_button.pressed.emit()
		await settle()
		assert(app.current.screen_id == "MissionOperations")
		app.current.skip_to_end()
		await settle()
		app.show_screen(5)
		await settle()
		if app.current.report_tabs.current_tab != 3:
			print("AUTO ",objective," context=",app.state.run_trace.get("comparison_context")," saved=",app.state.get("design_lab")," selected=",app.current.get_presentation_model().execution_key," latest=",Results.input_key(app.state.run_trace)," lab=",app.current.design_lab.get_model()); quit(1); return
		assert(not app.current.result_hero.visible)
		var model: Dictionary = app.current.design_lab.get_model()
		if model.state != "comparison": print(model); quit(1); return
		assert(app.get_saved_design_a().execution == original)
		var packet: Dictionary = model.comparison
		assert(packet.a_execution_key == a_key and packet.b_execution_key != a_key)
		assert(packet.metrics.total_mass_g.delta == (60 if radio == "radio_fast" else -60))
		assert(packet.metrics.returned_data_mb.delta == packet.metrics.returned_data_mb.b - packet.metrics.returned_data_mb.a)
		assert(packet.scored == (objective == "imaging"))
		if not packet.scored: assert(packet.metrics.score.a == null and packet.metrics.score.b == null)
		var b_key: String = packet.b_execution_key
		assert(app.show_execution_result(a_key).ok)
		await settle()
		assert(app.current.get_presentation_model().execution_key == a_key)
		assert(app.show_execution_result(b_key).ok)
		await settle()
		assert(app.current.report_tabs.current_tab == 0)
		app.current.open_design_lab()
		await settle()
		assert(app.current.report_tabs.current_tab == 3)
		for resolution in [Vector2i(1440,900),Vector2i(1024,768),Vector2i(900,680)]:
			root.size = resolution
			await settle()
			var lab = app.current.design_lab
			assert(lab.explanation.get_theme_font_size("font_size") >= 18)
			assert(app.current.report_scroll.size.y > resolution.y * 0.45)
			assert(lab.modify_button.size.y < 100)
			assert(lab.stacked.visible == (lab.size.x < 640))
			assert(app.current.report_surface.size.x <= app.current.report_scroll.size.x + 2)
			assert(lab.size.x <= app.current.report_scroll.size.x + 2)
			if DisplayServer.get_name() != "headless" and objective == "imaging":
				await RenderingServer.frame_post_draw
				var args = OS.get_cmdline_user_args()
				if not args.is_empty():
					DirAccess.make_dir_recursive_absolute(args[0])
					root.get_texture().get_image().save_png(args[0].path_join("comparison-%sx%s.png" % [resolution.x,resolution.y]))
		app.queue_free()
		await settle()
		print("PASS ",preset[0],": saved A immutable, B auto-opens bound comparison, real deltas, score availability, history selection and responsive layout")
	quit(0)
