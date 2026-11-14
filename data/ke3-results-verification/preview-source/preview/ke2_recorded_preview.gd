extends Control
## Explicit recorded-report entry. No production controller, routing or evaluator.

const RUN_ID := "run_ke2_handoff_v01"
var session = preload("res://ke3/presentation_session.gd").new()
var provider: RefCounted
var results: Control
var status_label: Label
var intent_counts := {"action": 0, "route": 0, "retry": 0}


func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(column)
	var banner := Label.new()
	banner.text = get_recorded_source().banner
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.add_theme_color_override("font_color", Color(1, 0.76, 0.3))
	column.add_child(banner)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)
	var controls := HBoxContainer.new()
	column.add_child(controls)
	for definition in [["Recorded report / full history", false], ["Missing linked event (negative fixture)", true]]:
		var button := Button.new()
		button.text = definition[0]
		button.pressed.connect(show_case.bind(definition[1]))
		controls.add_child(button)
	results = preload("res://ke3/results_control.tscn").instantiate()
	results.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(results)
	results.action_requested.connect(func(_run: String, _action: StringName): intent_counts.action += 1)
	results.result_route_requested.connect(func(_run: String): intent_counts.route += 1)
	results.retry_requested.connect(func(_run: String):
		intent_counts.retry += 1
		status_label.text = "Retry intent recorded; SE production lifecycle remains pending.")
	provider = preload("res://preview/ke2_recorded_provider.gd").new(self)
	session.bind_views(null, results)
	session.bind_provider(provider)
	show_case(false)


func get_recorded_source() -> Dictionary:
	return {"run_id": RUN_ID, "sample_revision": "ke2-hpc-report-v0.1", "report_path": "res://preview/recorded_ke2/ke2-hpc-report-v0.1.json", "metadata_path": "res://preview/recorded_ke2/ke2-hpc-report-v0.1.metadata.json", "trace_path": "res://preview/recorded_ke2/hpc-ke2-trace-ce478f9.json", "banner": "SYNTHETIC PREVIEW | KE2 RECORDED SAMPLE v0.1 | HPC ce478f9 | LAUNCH NOT APPROVED"}


func show_case(missing_link: bool) -> Dictionary:
	provider.choose_missing_link(missing_link)
	var run_id: String = get_recorded_source().run_id
	var reply: Dictionary = session.open_run(run_id)
	status_label.text = "KE2 recorded sample | " + run_id + (" | missing evt_008 fixture" if missing_link else " | 62 ordered same-run events") + " | " + str(reply)
	return reply
