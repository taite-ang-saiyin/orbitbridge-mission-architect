extends "res://scripts/prototype/Screen.gd"
## Mission Control presentation only. Uses the existing controller navigation.
const Catalog = preload("res://data/mock/DesignCatalog.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const STYLE = preload("res://ui/theme/WorkbenchTheme.gd")
var scroll: ScrollContainer
var main_row: BoxContainer
var hero_row: BoxContainer
var earth: SubViewportContainer
var quick_start: Button
var presets: Dictionary = {}
var recent_text: Label
var start_button: Button
var hero_title: Label

func _ready() -> void:
	Catalog.ensure(state)
	screen_id = "MissionControl"
	add_theme_constant_override("separation", 8)
	var heading = HBoxContainer.new()
	heading.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	heading.custom_minimum_size.y = 30
	add_child(heading)
	var heading_text = UI.label(heading, "⌂  HOME", 15, "39efff")
	heading_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var local_status = UI.label(heading, "●  LOCAL SYSTEMS", 12, "37e8b1")
	local_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	local_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	main_row = flex(content)
	main_row.size_flags_stretch_ratio = 3.0
	var hero = column(main_row, 2.2)
	hero_row = flex(hero)
	var intro = column(hero_row, 0.95)
	hero_title = UI.label(intro, "OrbitBridge", 34, "f0fbff")
	UI.label(intro, "Mission Architect", 21, "45dff4")
	UI.label(intro, "Design, launch and operate a satellite mission in Earth orbit. Explore how engineering decisions affect mission success.", 13, "bfd3e1")
	intro.add_child(HSeparator.new())
	UI.label(intro, "Design   •   Plan   •   Execute", 15, "4ce9f6")
	build_flow(intro)
	var map_box = panel(intro, "▣  EARTH VIEW — SAMPLE TARGETS")
	var map = preload("res://ui/components/SampleTargetMap.gd").new()
	map.custom_minimum_size = Vector2(180, 90)
	map_box.add_child(map)
	build_learning(intro)
	var globe_card = PanelContainer.new()
	globe_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	globe_card.size_flags_stretch_ratio = 1.25
	globe_card.add_theme_stylebox_override("panel", STYLE.box(Color("041c2eea"), Color("37758e"), 9))
	hero_row.add_child(globe_card)
	var globe = column(globe_card)
	var orbit = Runtime.orbit_for(state)
	UI.label(globe, "%s  /  %s km  /  %.1f min" % ["EARTH ORBIT (LEO)" if orbit.get("id") == "low_eq" else "EARTH ORBIT (POLAR)", orbit.get("altitude_km", "—"), float(orbit.get("step_duration_hours", 0)) * float(orbit.get("steps_per_orbit", 0)) * 60.0], 12, "a8dce9")
	earth = ORBIT.instantiate()
	earth.custom_minimum_size = Vector2(230, 340)
	globe.add_child(earth)
	earth.configure(state)
	earth.set_preview_playing(true)
	var legend = HFlowContainer.new()
	legend.add_theme_constant_override("h_separation", 12)
	legend.add_theme_constant_override("v_separation", 4)
	globe.add_child(legend)
	UI.label(legend, "● Target", 11, "1fff8c")
	UI.label(legend, "● Ground station · receives data", 11, "ffb040")
	UI.label(legend, "— Selected orbit", 11, "39eeff")
	for label in legend.get_children():
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UI.label(globe, "Drag to rotate the Earth", 11, "749eb5")
	var right = column(main_row, 1.0)
	build_quick_start(right)
	build_presets(right)
	var actions = HBoxContainer.new()
	add_child(actions)
	actions.alignment = BoxContainer.ALIGNMENT_END
	start_button = UI.button(actions, "▷  Start Mission  →", new_mission)
	start_button.custom_minimum_size.x = 240
	accent(start_button)
	resized.connect(fit_dashboard)
	call_deferred("fit_dashboard")

func flex(parent: Node) -> BoxContainer:
	var box = BoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	parent.add_child(box)
	return box

func column(parent: Node, ratio: float = 1.0) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_stretch_ratio = ratio
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)
	return box

func panel(parent: Node, title: String) -> VBoxContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", STYLE.box(Color("041c2eea"), Color("37758e"), 9))
	parent.add_child(card)
	var body = column(card)
	UI.label(body, title, 13, "e2f7ff")
	body.add_child(HSeparator.new())
	return body

func accent(button: Button) -> void:
	button.custom_minimum_size.y = 54
	var style = STYLE.box(Color("043e55"), Color("32eaff"), 9)
	style.shadow_size = 7
	style.shadow_color = Color(0.05, 0.85, 1.0, 0.22)
	button.add_theme_stylebox_override("normal", style)

func build_flow(parent: Node) -> void:
	var box = panel(parent, "◎  MISSION FLOW")
	var flow = preload("res://ui/components/MissionFlow.gd").new()
	flow.navigate.connect(func(index): navigate.emit(index))
	box.add_child(flow)

func build_quick_start(parent: Node) -> void:
	var box = panel(parent, "♧  QUICK START")
	quick_start = UI.button(box, "＋  Create New Mission  →\nDesign a custom satellite mission", new_mission)
	quick_start.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quick_start.alignment = HORIZONTAL_ALIGNMENT_LEFT
	accent(quick_start)
	var choose = UI.button(box, "▦  Choose a Mission Preset  →\nStart from a prepared scenario", func():
		presets.values()[0].grab_focus()
		scroll.ensure_control_visible(presets.values()[0]))
	choose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choose.alignment = HORIZONTAL_ALIGNMENT_LEFT
	choose.custom_minimum_size.y = 60

func build_presets(parent: Node) -> void:
	var box = panel(parent, "◇  MISSION PRESETS")
	for entry in [["Estuary Watch", "Coastal · Imaging", "Coastal Region", "Capture Imagery", "Polar – 600 km", "coast"], ["Tropical Forest Watch", "Equatorial · Imaging", "Tropical Forest", "Capture Imagery", "LEO – 400 km", "forest"], ["Polar Ice Survey", "Polar · Survey", "Arctic Ice", "Survey Target Regions", "Polar – 600 km", "ice"]]:
		var line = HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		box.add_child(line)
		var thumbnail = preload("res://ui/components/TargetThumbnail.gd").new()
		thumbnail.terrain = entry[5]
		thumbnail.custom_minimum_size = Vector2(64, 58)
		line.add_child(thumbnail)
		var button = UI.button(line, entry[0] + "  →\n" + entry[1], apply_preset.bind(entry))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 58
		button.add_theme_font_size_override("font_size", 12)
		presets[entry[0]] = button

func apply_preset(entry: Array) -> void:
	if state.get("active_run_state", {}).get("phase") == "operating": return
	Catalog.reset(state)
	state.name = entry[0]
	state.targets = [entry[2]]
	state.target = entry[2]
	state.target_limit = 1
	state.objective = entry[3]
	state.orbit = entry[4]
	navigate.emit(1)

func build_system_status(parent: Node) -> void:
	var box = panel(parent, "READY TO EXPLORE")
	var loaded: Dictionary = Runtime.load_game_catalogs()
	for entry in [["Flight simulation", ResourceLoader.exists("res://core/MissionStepEngine.gd")], ["Spacecraft parts", loaded.get("ok", false)], ["Mission library", loaded.get("ok", false)]]:
		var line = HBoxContainer.new()
		box.add_child(line)
		UI.label(line, entry[0], 11, "bed7e5").size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var status = UI.label(line, "● READY" if entry[1] else "● UNAVAILABLE", 10, "38edb0" if entry[1] else "ffb56c")
		status.autowrap_mode = TextServer.AUTOWRAP_OFF
		status.custom_minimum_size.x = 82
	UI.label(box, "Explore the catalog and plan your next flight.", 13, "a7c4d5")

func build_recent(parent: Node) -> void:
	var box = panel(parent, "◷  RECENT MISSIONS")
	var records: Array = state.get("evaluation_store", {}).get("history", [])
	if records.is_empty():
		recent_text = UI.label(box, "No completed missions yet.\nLaunch your first mission to build a flight history.", 12, "86aebf")
	else:
		var rows: Array = []
		for i in range(maxi(0, records.size() - 3), records.size()):
			var record: Dictionary = records[i]
			rows.append("%s\n%s orbits · %s" % [record.state.config_snapshot.mission.title, record.state.config_snapshot.mission.duration_orbits, record.report.status.to_upper()])
		recent_text = UI.label(box, "\n\n".join(rows), 12, "b7d9e7")
		UI.button(box, "View Results  →", func(): navigate.emit(5))

func build_learning(parent: Node) -> void:
	var box = panel(parent, "▥  LEARNING GOALS")
	for title in ["Translate science intent into requirements.", "Understand subsystem trade-offs.", "Run and compare engineering experiments."]:
		var check = CheckBox.new()
		check.text = title
		check.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		check.add_theme_font_size_override("font_size", 11)
		box.add_child(check)

func fit_dashboard() -> void:
	if not is_instance_valid(earth): return
	main_row.vertical = size.x < 1000
	hero_row.vertical = size.x < 720
	earth.custom_minimum_size.y = clampf(size.y * 0.55, 300, 490)
	hero_title.add_theme_font_size_override("font_size", 31 if size.x >= 1000 else 27)
