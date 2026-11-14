extends SceneTree
const REVIEW = preload("res://scripts/integration/mission_review.gd")
func _initialize() -> void: call_deferred("check")
func settle() -> void:
	for frame in 8: await process_frame
func approve(page: Control) -> void:
	page.review_dialog.acknowledgement.button_pressed = true
	assert(not page.review_dialog.continue_button.disabled)
	page.review_dialog.continue_button.pressed.emit()
func check() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	for resolution in [Vector2i(1024, 768), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		app.start_new_mission()
		await settle()
		var page = app.current
		page.name_input.text = "Reviewed mission"
		page.name_input.text_changed.emit("Reviewed mission")
		page.next_button.pressed.emit()
		await settle()
		assert(app.current == page and page.review_dialog.visible)
		assert(page.review_dialog.continue_button.disabled and not REVIEW.is_confirmed(app.state))
		page.review_dialog.continue_button.pressed.emit()
		assert(app.current == page and not REVIEW.is_confirmed(app.state))
		assert(page.review_dialog.checks_box.get_child_count() == 9)
		assert(Rect2(Vector2.ZERO, app.size).encloses(page.review_dialog.card.get_global_rect()))
		page.review_dialog.close_button.pressed.emit()
		assert(not page.review_dialog.visible and not REVIEW.is_confirmed(app.state))
		app.sidebar.get_child(2).pressed.emit()
		await settle()
		assert(app.current == page and page.review_dialog.visible, "Builder sidebar must require review")
		approve(page)
		await settle()
		assert(app.current.screen_id == "SpacecraftBuilder" and REVIEW.is_confirmed(app.state))
		app.sidebar.get_child(1).pressed.emit()
		await settle()
		page = app.current
		assert(page.summary_column == null)
		assert(page.next_button.text == "Next: Spacecraft Builder  →")
		page.next_button.pressed.emit()
		assert(page.review_dialog.visible and page.review_dialog.continue_button.disabled, "Next must always open the summary popup")
		page.review_dialog.close_button.pressed.emit()
		page.budget_input.value = 110
		assert(not REVIEW.is_confirmed(app.state), "Mission changes must invalidate acknowledgement")
		app.sidebar.get_child(3).pressed.emit()
		await settle()
		assert(app.current == page and page.review_dialog.visible, "Readiness must not bypass review")
		assert(not app.state.has("run_trace"))
		# A changed mission cannot be approved using a stale open summary.
		page.name_input.text_changed.emit("Updated mission")
		approve(page)
		await settle()
		assert(app.current == page and page.review_dialog.visible)
		assert(page.review_dialog.continue_button.disabled and not REVIEW.is_confirmed(app.state))
		approve(page)
		await settle()
		assert(app.current.screen_id == "SpacecraftBuilder" and REVIEW.is_confirmed(app.state))
		app.start_new_mission()
		await settle()
		assert(not app.state.has("mission_review_snapshot"))
		page = app.current
		page.name_input.text_changed.emit("")
		app.sidebar.get_child(2).pressed.emit()
		await settle()
		page.review_dialog.acknowledgement.button_pressed = true
		assert(page.review_dialog.continue_button.disabled)
		page.review_dialog.continue_button.pressed.emit()
		assert(app.current == page and not REVIEW.is_confirmed(app.state))
		print("PASS mandatory mission review, cancel, acknowledgement, stale summary, sidebar gates, new mission and overlay bounds at ", resolution)
	app.queue_free()
	quit(0)
