extends SceneTree
const COPY = preload("res://scripts/settings/MyanmarText.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
var failures = 0
var checks = 0
func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + message)
func settle() -> void:
	for i in 5: await process_frame
func labels(node: Node) -> String:
	var result = ""
	if node is Label or node is Button: result += node.text + "\n"
	for child in node.get_children(): result += labels(child)
	return result
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var app = load("res://scenes/Main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.current.open_settings()
	await settle()
	var panel = app.current.settings_panel
	expect(panel.language.get_item_text(1) == "မြန်မာ", "Myanmar replaces Chinese option")
	panel.language.select(1)
	panel.language.item_selected.emit(1)
	await settle()
	expect(app.preferences.language == "my", "Settings uses Myanmar language code")
	expect(app.current.start.text == "မစ်ရှင် စတင်မည်", "Home changes immediately")
	expect(panel.get_node("Margin/Content/LanguageLabel").text == "ဘာသာစကား", "Settings copy translated")
	app.current.close_settings()
	var config: Dictionary = Runtime.config_for(app.state)
	for entry in [[0,"မစ်ရှင် အဆင့်များ"], [1,"မစ်ရှင် ဖန်တီးရေး"], [2,"ဂြိုဟ်တု တည်ဆောက်ရေး"], [3,"လွှတ်တင်ရန် အဆင်သင့် စစ်ဆေးရေး"]]:
		app.show_screen(entry[0])
		await settle()
		expect(entry[1] in labels(app.current), "SE page translated: " + app.current.screen_id)
		expect(Runtime.config_for(app.state) == config, "Language leaves canonical mission/config unchanged")
		if entry[0] == 1:
			expect(app.current.name_input.text == app.state.name, "Editable mission title is not translated")
			app.current.open_mission_review()
			await settle()
			expect("မစ်ရှင် အကျဉ်း" in labels(app.current), "Mission review dialog translated")
			app.current.review_dialog.close()
			for button in app.current.objective_buttons.values():
				for child in button.get_children():
					if child is MarginContainer: expect(button.size.y >= child.get_combined_minimum_size().y, "Myanmar choice card fits wrapped copy")
		if entry[0] == 2:
			app.current.select_component("radio_id", "dev_radio_1")
			await settle()
			expect(app.state.radio_id == "dev_radio_1", "Translated components keep stable IDs")
	# Dynamic refreshes must remain translated, and changing back must restore English.
	app.current.next_button.text = "Launch Mission"
	await settle()
	expect(app.current.next_button.text == "မစ်ရှင် လွှတ်တင်မည်", "Dynamic readiness refresh translated")
	preload("res://scripts/integration/mission_review.gd").confirm(app.state, preload("res://scripts/integration/mission_review.gd").snapshot(app.state))
	app.show_screen(4)
	await settle()
	expect(not app.current.has_meta("se_font_language"), "Operations subtree is untouched")
	expect("မစ်ရှင်" not in labels(app.current), "Operations remains English")
	app.current.skip_to_end()
	await settle()
	app.show_screen(5)
	await settle()
	expect(not app.current.has_meta("se_font_language"), "Debrief subtree is untouched")
	expect("မစ်ရှင်" not in labels(app.current), "Debrief remains English")
	app.show_screen(2)
	await settle()
	expect("ဂြိုဟ်တု တည်ဆောက်ရေး" in labels(app.current), "Returning from excluded page restores Myanmar")
	app.preferences.language = "en"
	await settle()
	expect("Satellite Builder" in labels(app.current), "Switching back restores English without recreating page")
	expect(not app.current.has_theme_font_override("font"), "Original font override restored")
	var font: Font = COPY.myanmar_font()
	expect(font.has_char("က".unicode_at(0)) and font.has_char("ြ".unicode_at(0)), "Bundled font supports Myanmar letters and combining marks")
	expect(COPY.text("radio_basic · 12 MB · 25 Wh", "my") == "radio_basic · 12 MB · 25 Wh", "IDs and numeric units preserved")
	expect("1380" in COPY.text("Spacecraft mass is 1380 g; this profile requires mass < 1330 g.", "my") and "Spacecraft" not in COPY.text("Spacecraft mass is 1380 g; this profile requires mass < 1330 g.", "my"), "Dynamic blocking messages translated with numbers preserved")
	print("Myanmar localization: ",checks - failures," checks passed; ",failures," failed")
	app.queue_free()
	quit(0 if failures == 0 else 1)
