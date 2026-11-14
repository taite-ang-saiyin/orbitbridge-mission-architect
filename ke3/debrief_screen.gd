extends "res://ke3/outline_control.gd"
## A05 read-only report presentation. No evaluation, scoring or Retry reset.

var _fields: Dictionary = {}
var _scroll: ScrollContainer
var _credits_button: Button
var _credits_panel: PanelContainer
var _retry_pending: bool = false


func set_inputs(context: Dictionary, state: Dictionary, report: Dictionary) -> void:
	if context.get("run_id") != _context.get("run_id"):
		_retry_pending = false
	super.set_inputs(context, state, report)


func set_retry_pending(value: bool) -> void:
	_retry_pending = value
	if is_node_ready():
		_render()


func _build_outline() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var banner := _label(column, "SYNTHETIC DEBRIEF PREVIEW | SUPPLIED REPORT VALUES | NO LIVE LEDGER")
	banner.add_theme_color_override("font_color", Color(1.0, 0.76, 0.3))
	var title := _label(column, "Mission Debrief")
	title.add_theme_font_size_override("font_size", 30)
	_boundary_label = _label(column, "")
	_boundary_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.4))
	_scroll = ScrollContainer.new()
	_scroll.name = "DebriefScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.focus_mode = Control.FOCUS_ALL
	_scroll.follow_focus = true
	_scroll.gui_input.connect(_on_report_scroll_input)
	column.add_child(_scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	_scroll.add_child(content)
	for definition in [["context", "SELECTED MISSION / PROFILE / GOAL"], ["outcome", "OUTCOME / RUN STATUS"], ["metrics", "SUPPLIED METRICS"], ["summary", "REPORT SUMMARY"], ["causes", "CAUSES / ACTIVE-RUN EVIDENCE"], ["experiment", "NEXT EXPERIMENT"], ["credits", "PROFILE / SOURCE CREDITS"]]:
		_fields[definition[0]] = _section(content, definition[1])
	_credits_panel = _fields.credits.get_parent().get_parent().get_parent()
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	column.add_child(footer)
	_credits_button = Button.new()
	_credits_button.name = "ShowCredits"
	_credits_button.text = "Show credits"
	_credits_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_credits_button.pressed.connect(func(): _scroll.ensure_control_visible(_credits_panel))
	footer.add_child(_credits_button)
	_retry_button = Button.new()
	_retry_button.name = "RetryIntent"
	_retry_button.text = "Retry"
	_retry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_retry_button.pressed.connect(_request_retry)
	footer.add_child(_retry_button)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = Color(1.0, 0.8, 0.25)
	focus.set_border_width_all(3)
	for control in [_scroll, _credits_button, _retry_button]:
		control.focus_mode = Control.FOCUS_ALL
		control.add_theme_stylebox_override("focus", focus)
	_scroll.focus_next = _scroll.get_path_to(_credits_button)
	_credits_button.focus_next = _credits_button.get_path_to(_retry_button)
	_retry_button.focus_next = _retry_button.get_path_to(_scroll)
	_scroll.focus_previous = _scroll.get_path_to(_retry_button)
	_credits_button.focus_previous = _credits_button.get_path_to(_scroll)
	_retry_button.focus_previous = _retry_button.get_path_to(_credits_button)


func _on_report_scroll_input(event: InputEvent) -> void:
	# Handle report navigation only while this scroll region owns keyboard focus.
	# Accepting the event prevents arrow keys from moving focus to footer buttons.
	if not _scroll.has_focus() or not event is InputEventKey or not event.pressed:
		return
	if event.alt_pressed or event.ctrl_pressed or event.meta_pressed:
		return
	var distance: int = 0
	var page_distance := maxi(32, int(_scroll.size.y) - 32)
	match event.keycode:
		KEY_DOWN: distance = 32
		KEY_UP: distance = -32
		KEY_PAGEDOWN: distance = page_distance
		KEY_PAGEUP: distance = -page_distance
		_: return
	var bar := _scroll.get_v_scroll_bar()
	var maximum := maxi(0, floori(bar.max_value - bar.page))
	if maximum == 0:
		return
	_scroll.scroll_vertical = clampi(_scroll.scroll_vertical + distance, 0, maximum)
	_scroll.accept_event()


func _text(value: Variant) -> String:
	if value == null:
		return "Unavailable"
	var rendered := str(value)
	# JSON whole numbers arrive as floats; format labels without changing payloads.
	return rendered.trim_suffix(".0") if value is float else rendered


func _number(data: Dictionary, field: String) -> String:
	return _text(data.get(field))


func _percent(field: String) -> String:
	var value: Variant = _report.get(field)
	if not (value is int or value is float):
		return "Unavailable"
	# Presentation formatting only: never calculate a ratio from the raw counters.
	var text := "%.2f" % (float(value) * 100.0)
	while text.ends_with("0"):
		text = text.trim_suffix("0")
	return text.trim_suffix(".") + "%"


func _selected_mission() -> Dictionary:
	var config: Variant = _context.get("config", {})
	if config is Dictionary and config.get("mission") is Dictionary:
		return config.mission
	var legacy: Variant = _context.get("config_selections", {})
	return legacy if legacy is Dictionary else {}


func _profile() -> Dictionary:
	var profile: Variant = _context.get("profile_metadata", {})
	return profile if profile is Dictionary else {}


func _report_value(canonical: String, legacy: String = "") -> Variant:
	if _report.has(canonical):
		return _report[canonical]
	return _report.get(legacy) if not legacy.is_empty() else null


func _event_index() -> Dictionary:
	var index: Dictionary = {}
	var run_id: Variant = _context.get("run_id")
	if _state.get("run_id") != run_id:
		return index
	var events: Variant = _state.get("events", [])
	if not events is Array:
		return index
	for event in events:
		if event is Dictionary and event.get("run_id") == run_id and event.get("event_id") is String:
			index[event.event_id] = event
	return index


func _evidence_text(references: Variant, index: Dictionary) -> String:
	if not references is Array or references.is_empty():
		return "Evidence Unavailable (no active-run link supplied)"
	var lines: Array[String] = []
	for event_id in references:
		if not index.has(event_id):
			lines.append("Evidence Unavailable: " + str(event_id) + " (not in active run)")
			continue
		var event: Dictionary = index[event_id]
		lines.append("Evidence: %s | Step %s | %s" % [event_id, _text(event.get("step_index", event.get("step"))), _text(event.get("message", event.get("label")))])
	return "\n".join(lines)


func _causes_text() -> String:
	var index := _event_index()
	var lines: Array[String] = []
	var causes: Variant = _report.get("root_causes", [])
	if causes is Array:
		for cause in causes:
			if cause is Dictionary:
				lines.append("Cause code: %s\nExplanation: %s\n%s" % [_text(cause.get("code")), _text(cause.get("explanation")), _evidence_text(cause.get("evidence_event_ids"), index)])
	if _report.has("evidence_event_ids"):
		# Legacy A02 report-level links are never assigned to an invented cause.
		lines.append("Report evidence (legacy):\n" + _evidence_text(_report.evidence_event_ids, index))
	return "\n\n".join(lines) if not lines.is_empty() else "No root causes supplied."


func _credits_text() -> String:
	var profile := _profile()
	var lines: Array[String] = [_text(_context.get("attribution_notice", "SYNTHETIC metadata / preview attribution; production ledger unverified.")), "Profile source: " + _text(profile.get("source_label")), "Profile credit: " + _text(profile.get("credit"))]
	var metadata: Variant = _context.get("source_metadata", {})
	var source_ids: Variant = _report.get("source_ids", []) if _report_matches_context() else []
	if not source_ids is Array:
		source_ids = []
	for source_id in source_ids:
		var source: Dictionary = {}
		if metadata is Dictionary and metadata.get(source_id) is Dictionary:
			source = metadata[source_id]
		lines.append("Source ID: %s\nTitle: %s\nCredit: %s\nURL: %s" % [source_id, _text(source.get("title")), _text(source.get("credit")), _text(source.get("url"))])
	# Credits scoped to executed readiness or feedback vocabulary arrive as
	# display metadata. Preserve the evaluator's independent source_ids verbatim.
	var has_context_run: bool = _context.get("run_id") is String and not String(_context.run_id).is_empty() and _state.get("run_id") == _context.run_id
	# A foreign-run report invalidates its entire scoped metadata binding.
	if not _report.is_empty() and _report.get("run_id") != _context.get("run_id"):
		has_context_run = false
	var scoped_credits: Variant = _context.get("applicable_source_credits", []) if has_context_run else []
	if scoped_credits is Array:
		for credit in scoped_credits:
			if credit is Dictionary:
				# Readiness is independently executed; feedback needs this run's report.
				if credit.get("credit_scope") != "readiness" and not _report_matches_context():
					continue
				lines.append("Applicable credit scope: %s (metadata; not report source_ids)\nMetadata source ID: %s\nTitle: %s\nCredit: %s\nURL: %s\nActual use: %s" % [_text(credit.get("credit_scope")), _text(credit.get("source_id")), _text(credit.get("title")), _text(credit.get("attribution_text")), _text(credit.get("url")), _text(credit.get("actual_use"))])
	var attributions: Variant = _context.get("visual_attributions", [])
	if not attributions is Array:
		attributions = []
	for attribution in attributions:
		if attribution is Dictionary:
			lines.append("Preview visual-cue attribution: %s\n%s\n%s" % [_text(attribution.get("title")), _text(attribution.get("url")), _text(attribution.get("credit"))])
	return "\n\n".join(lines)


func _report_matches_context() -> bool:
	if _matching_run_id().is_empty() or _report.is_empty():
		return false
	if _state.has("mission_id") and _report.get("mission_id") != _state.mission_id:
		return false
	if _context.has("mission_id") and _report.get("mission_id") != _context.mission_id:
		return false
	var mission: Dictionary = _selected_mission()
	for field in ["required_observations", "required_returned_data_mb"]:
		if _report.has(field) and mission.has(field) and _report[field] != mission[field]:
			return false
	for field in ["observations_completed", "returned_data_mb", "run_status"]:
		if _report.has(field) and _state.has(field) and _report[field] != _state[field]:
			return false
	return true


func get_debrief_model() -> Dictionary:
	var mission := _selected_mission()
	var profile := _profile()
	var legacy: Variant = _context.get("config_selections", {})
	var profile_label: Variant = profile.get("label")
	if profile_label == null and legacy is Dictionary:
		profile_label = legacy.get("profile_label")
	var goal_observations: Variant = mission.get("required_observations", mission.get("observations_requested"))
	var goal_mb: Variant = mission.get("required_returned_data_mb", mission.get("return_threshold_mb"))
	var model := {"mission": _text(mission.get("title", mission.get("label"))), "profile": _text(profile_label),
		"goal": "%s observations; %s MB returned" % [_text(goal_observations), _text(goal_mb)],
		"status": "Unavailable", "run_status": "Unavailable", "score": "Unavailable",
		"observations": "Unavailable/Unavailable", "returned": "Unavailable/Unavailable MB",
		"observation_percent": "Unavailable", "return_percent": "Unavailable",
		"summary": "Unavailable", "failed_constraint": "Unavailable", "causes": "No root causes supplied.",
		"next_experiment": "Unavailable", "credits": _credits_text(), "presentation_state": "unavailable"}
	if not _context.get("run_id") is String or String(_context.run_id).is_empty() or _state.get("run_id") != _context.run_id:
		return model
	if _context.get("presentation_route") == "readiness" or _state.get("phase") == "readiness":
		model.presentation_state = "readiness_required"
		model.summary = "Readiness required: " + _text(_context.get("readiness_message"))
		return model
	var error: Variant = _context.get("evaluation_error", {})
	if error is Dictionary and not error.is_empty() and error.get("run_id") == _context.run_id:
		model.presentation_state = "evaluation_error"
		model.status = "Evaluation error"
		model.summary = "%s | %s\nSuggested fix: %s" % [_text(error.get("code")), _text(error.get("message")), _text(error.get("suggested_fix"))]
		return model
	if _report.is_empty():
		if _state.get("phase") == "finished" or _state.get("lifecycle") == "terminal":
			model.presentation_state = "awaiting_evaluation"
			model.status = "Awaiting evaluation"
			model.run_status = _text(_state.get("run_status"))
			model.summary = "Awaiting evaluation"
			model.observations = "%s/%s" % [_text(_state.get("observations_completed")), _text(goal_observations)]
			model.returned = "%s/%s MB" % [_text(_state.get("returned_data_mb", _state.get("returned_mb"))), _text(goal_mb)]
		return model
	if _report.get("run_id") != _context.get("run_id"):
		return model
	if not _report_matches_context():
		model.presentation_state = "stale_report"
		model.summary = "Report identity, goals or counters do not match this execution."
		return model
	model.presentation_state = "report"
	model.status = _text(_report.get("status"))
	model.run_status = _text(_report.get("run_status"))
	model.score = _number(_report, "score")
	model.observations = "%s/%s" % [_text(_report_value("observations_completed")), _text(_report_value("required_observations", "observations_requested"))]
	model.returned = "%s/%s MB" % [_text(_report_value("returned_data_mb", "returned_mb")), _text(_report_value("required_returned_data_mb", "return_threshold_mb"))]
	model.observation_percent = _percent("observation_completion_ratio")
	model.return_percent = _percent("data_return_completion_ratio")
	model.summary = _text(_report.get("explanation"))
	model.failed_constraint = _text(_report.get("failed_constraint"))
	model.causes = _causes_text()
	model.next_experiment = _text(_report.get("next_experiment"))
	return model


func get_visible_labels() -> Dictionary:
	var result: Dictionary = {}
	for key in _fields:
		result[key] = _fields[key].text
	return result


func _render() -> void:
	var model := get_debrief_model()
	_boundary_label.visible = not _boundary_error.is_empty()
	_boundary_label.text = "Input unavailable: " + _boundary_error
	_fields.context.text = "Mission: %s\nProfile: %s\nGoal: %s" % [model.mission, model.profile, model.goal]
	_fields.outcome.text = "Outcome: %s | Run status: %s" % [model.status, model.run_status]
	_fields.metrics.text = "Observations: %s | Completion: %s\nReturned: %s | Completion: %s\nScore: %s" % [model.observations, model.observation_percent, model.returned, model.return_percent, model.score]
	_fields.summary.text = model.summary + "\nFailed constraint: " + model.failed_constraint
	_fields.causes.text = model.causes
	_fields.experiment.text = model.next_experiment
	_fields.credits.text = model.credits
	_retry_button.disabled = _retry_pending or model.presentation_state != "report" or _matching_run_id().is_empty()
	_retry_button.text = "Retry requested…" if _retry_pending else "Retry"
	_credits_button.disabled = _report.is_empty() or _matching_run_id().is_empty()


func _request_retry() -> void:
	if not _retry_button.disabled:
		# Latch before emission, including deferred route receivers.
		set_retry_pending(true)
		super._request_retry()
