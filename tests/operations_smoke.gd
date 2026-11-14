extends SceneTree
func _initialize() -> void:
	call_deferred("check")
func settle() -> void:
	for frame in 10:
		await process_frame
func require(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		quit(1)
		return false
	return true
func check() -> void:
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	app.state.name = "Operations Review"
	for resolution in [Vector2i(1440, 900), Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(1920, 1080), Vector2i(3360, 2100)]:
		root.size = resolution
		app.show_screen(4)
		await settle()
		var page = app.current
		if not require("Operations Review" in page.status.text, "Mission name not retained"): return
		if not require(page.content.size.x <= page.scroll.size.x + 1, "Operations horizontal overflow"): return
		if not require(Rect2(Vector2.ZERO, app.size).encloses(page.next_button.get_global_rect()), "Debrief button outside screen"): return
		if resolution in [Vector2i(1440, 900), Vector2i(1920, 1080), Vector2i(3360, 2100)]:
			print("Operations content ", page.content.size, " available ", page.scroll.size)
			if not require(page.content.size.y <= page.scroll.size.y + 1, "Desktop operations panels require scrolling"): return
		if not require(page.orbit_badge.get_parent().size.x >= 146, "Orbit badge collapsed to a narrow column"): return
		if not require(page.timeline.item_count == page.DATA.EVENTS.size(), "Missing event types"): return
		page.step_button.pressed.emit()
		if not require(page.event_index == 1, "Step did not select DEPLOY"): return
		page.play_button.pressed.emit()
		page._process(8.0)
		if not require(page.event_index > 1 and page.playing, "Playback did not advance to OBSERVE"): return
		page.pause_button.pressed.emit()
		var stopped_at = page.playhead
		page._process(1.0)
		if not require(page.playhead == stopped_at, "Pause did not stop playback"): return
		page.speed_buttons[4].pressed.emit()
		if not require(page.speed == 4, "Speed selector did not update"): return
		var transmit_index = -1
		for i in page.DATA.EVENTS.size():
			if page.DATA.EVENTS[i][0] == "TX": transmit_index = i; break
		if not require(transmit_index >= 0, "No actual downlink event"): return
		page.select_event(transmit_index)
		if not require("TX" in page.details.text, "Event selection not synchronized"): return
		if not require(page.live_track.progress == page.track_view.progress, "Ground tracks disagree"): return
		for tab in ["Ground Track", "Data View", "Earth & Orbit"]:
			page.tab_buttons[tab].pressed.emit()
			if not require(page.tab_buttons[tab].button_pressed, "Tab state incorrect"): return
		page.filter_select.select(3)
		page.filter_select.item_selected.emit(3)
		if not require(page.timeline.item_count == 0, "Nominal run invented a warning"): return
		page.filter_select.select(0)
		page.filter_select.item_selected.emit(0)
		page.skip_button.pressed.emit()
		if not require(page.event_index == page.DATA.EVENTS.size() - 1 and not page.playing and "MB" in page.telemetry.text, "Skip to End is inconsistent"): return
		page.play_button.pressed.emit()
		if not require(page.event_index == 0 and page.playhead == 0 and page.playing, "Replay did not reset"): return
		page.pause()
		page.expand_orbit()
		if not require(page.enlarged.visible, "Expanded orbit view did not open"): return
		page.enlarged.hide()
		page.next_button.pressed.emit()
		await settle()
		app.current.show_run("Run A")
		if not require(app.current.report_view.get_debrief_model().presentation_state == "report", "Operations and Debrief Run A disagree"): return
		app.show_screen(4)
		await settle()
		app.current.previous.pressed.emit()
		await settle()
		if not require(app.current.screen_id == "FlightReadiness", "Back navigation failed"): return
		print("PASS: operations playback, tabs, event filtering, telemetry, completion, comparison and layout at ", resolution)
	quit()
