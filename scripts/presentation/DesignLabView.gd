extends VBoxContainer
## KE3 presentation and intents only. Storage, eligibility and deltas are owner inputs.
## `inputs` is a view model, not a ratified MissionComparison API.
signal save_a_requested(run_id: String, execution_key: String, replace: bool)
signal modify_a_requested(run_id: String, execution_key: String)
signal modify_current_requested
signal compare_requested
signal clear_a_requested
signal view_execution_requested(execution_key: String)
const COPY = preload("res://scripts/settings/MyanmarText.gd")
const UI = preload("res://ui/components/UI.gd")
const Words = preload("res://scripts/presentation/PlayerLanguage.gd")
const Presenter = preload("res://scripts/presentation/DebriefPresentation.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
const METRICS = [
	["outcome", "Outcome", ""], ["score", "Score", "points"],
	["qualifying_count", "Qualifying count / goal", "count"],
	["returned_data_mb", "Returned data (MB)", "MB"],
	["lowest_battery_wh", "Lowest battery (Wh)", "Wh"],
	["lowest_battery_percent", "Lowest battery (%)", "percentage points"],
	["peak_storage_mb", "Peak storage (MB)", "MB"],
	["total_cost_credits", "Total cost (illustrative credits)", "illustrative credits"],
	["total_mass_g", "Total mass (g)", "g"]]
var inputs: Dictionary = {}
var model: Dictionary = {}
var notice: Label
var fixture_notice: Label
var status_label: Label
var explanation: Label
var identities: Label
var changes: Label
var grid: GridContainer
var cells: Dictionary = {}
var save_button: Button
var replace_button: Button
var modify_button: Button
var compare_button: Button
var clear_button: Button
var confirmation: ConfirmationDialog
var pending_intent: String = ""
var pending_expected_a_key: String = ""
var pending_candidate: Dictionary = {}
var confirmed_expected_a_key: String = ""
var view_a_button: Button
var view_b_button: Button
var _confirmation_focus: Control

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	UI.label(self, "A / B DESIGN LAB", 17, "b9f4e7")
	notice = UI.label(self, session_notice(OS.has_feature("web")), 14, "f4d38b")
	fixture_notice = UI.label(self, "", 14, "f4d38b")
	status_label = UI.label(self, "", 22, "b9f4e7")
	explanation = UI.label(self, "", 15)
	identities = UI.label(self, "", 12, "8ea9bb")
	grid = GridContainer.new()
	grid.name = "DesignComparison"
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)
	for title in ["Measurement", "A", "B", "B − A"]: _cell(title, "8ea9bb", 135 if title == "Measurement" else 75)
	for definition in METRICS:
		_cell(definition[1], "e6edf8", 135)
		var row: Array[Label] = []
		for i in 3: row.append(_cell("Unavailable", "e6edf8", 75))
		cells[definition[0]] = row
	changes = UI.label(self, "", 14)
	var actions = HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 10)
	actions.add_theme_constant_override("v_separation", 8)
	add_child(actions)
	save_button = UI.button(actions, "Save as A", func(): _save(false))
	replace_button = UI.button(actions, "Replace A…", func(): _confirm("replace"))
	modify_button = UI.button(actions, "Modify design", _modify)
	compare_button = UI.button(actions, "Compare A and B", func():
		if not compare_button.disabled: compare_requested.emit())
	clear_button = UI.button(actions, "Clear A…", func(): _confirm("clear"))
	view_a_button = UI.button(actions, "Open A's Debrief", func(): _view("a"))
	view_b_button = UI.button(actions, "Open B's Debrief", func(): _view("b"))
	for button in actions.get_children(): button.custom_minimum_size.y = 44
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Saved reference"
	confirmation.confirmed.connect(_confirmed)
	confirmation.canceled.connect(_dismiss_confirmation)
	confirmation.visibility_changed.connect(func():
		if not confirmation.visible: _restore_confirmation_focus.call_deferred())
	add_child(confirmation)
	refresh()

func _cell(value: String, color: String, width: float) -> Label:
	var label: Label = UI.label(grid, value, 14, color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = width
	return label

static func dictionary(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

static func session_notice(web: bool) -> String:
	return "Refreshing the page clears this comparison" if web else "Session only · New Mission or closing the app clears this comparison."

static func supplied_metric(comparison: Dictionary, name: String) -> Dictionary:
	var normalized: Dictionary = dictionary(dictionary(comparison.get("metrics")).get(name))
	if not normalized.is_empty(): return normalized
	var measures: Array = comparison.measures if comparison.get("measures") is Array else []
	for measure in measures:
		if not measure is Dictionary: continue
		var id: String = {"observations_completed":"qualifying_count", "highest_storage_mb":"peak_storage_mb"}.get(measure.get("id"), str(measure.get("id", "")))
		if id != name: continue
		if measure.get("available") == false: return {"a":null, "b":null, "delta":null}
		return {"a":measure.get("a"), "b":measure.get("b"), "delta":measure.get("delta_b_minus_a"), "delta_unit":str(measure.get("delta_unit", measure.get("unit", ""))).replace("_", " ")}
	return {}

static func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value)

static func signed(value: Variant) -> String:
	if not numeric(value): return "Unavailable"
	return ("+" if value > 0 else "") + Words.amount(value)

static func completed(record: Dictionary) -> bool:
	var report: Dictionary = dictionary(record.get("report"))
	return record.get("run_id") is String and not record.run_id.is_empty() and record.get("mission_id") is String and not record.mission_id.is_empty() and record.get("execution_key") is String and not record.execution_key.is_empty() and record.get("phase") == "finished" and record.get("run_status") == "completed" and report.get("run_status") == "completed" and report.get("run_id") == record.run_id and report.get("mission_id") == record.mission_id

func set_inputs(value: Dictionary) -> void:
	inputs = value.duplicate(true)
	if is_node_ready(): refresh()

func refresh() -> void:
	var a: Dictionary = dictionary(inputs.get("a"))
	var b: Dictionary = dictionary(inputs.get("b"))
	var candidate: Dictionary = dictionary(inputs.get("candidate"))
	var comparison: Dictionary = dictionary(inputs.get("comparison"))
	var saved: bool = inputs.get("a_saved") == true
	var preview: bool = inputs.get("preview") == true and inputs.get("fixture_label") is String and not inputs.fixture_label.is_empty()
	# KE2's published packet is a proposal. Nested draft eligibility is preview-only.
	var eligibility: Dictionary = dictionary(comparison.get("proposed_eligibility")) if preview else {}
	var provider_eligible: Variant = comparison.get("eligible", eligibility.get("eligible"))
	var ca: Dictionary = dictionary(comparison.get("a"))
	var cb: Dictionary = dictionary(comparison.get("b"))
	var ready: bool = completed(a) and completed(b) and a.run_id != b.run_id
	var binding: bool = comparison.get("a_run_id", ca.get("run_id")) == a.get("run_id") and comparison.get("b_run_id", cb.get("run_id")) == b.get("run_id") and comparison.get("a_execution_key", ca.get("execution_key")) == a.get("execution_key") and comparison.get("b_execution_key", cb.get("execution_key")) == b.get("execution_key")
	for side in [["a", a, ca], ["b", b, cb]]:
		var mission: Variant = comparison.get(side[0] + "_mission_id", side[2].get("mission_id"))
		# Older labeled packet previews lack these fields. Live replies must supply both.
		if not (preview and mission == null) and mission != side[1].get("mission_id"): binding = false
	# KE2 owns policy/goal/scenario eligibility. Do not compare accepted action lists.
	var eligible: bool = saved and ready and binding and provider_eligible == true
	var example: bool = preview and ready and binding and provider_eligible == null
	var state: String = "pending"
	if not comparison.is_empty() and (not ready or not binding or provider_eligible == false): state = "blocked"
	elif eligible: state = "comparison"
	elif example: state = "example"
	status_label.text = "Live comparison pending"
	if state == "comparison":
		var classification: Variant = comparison.get("classification") if comparison.has("classification") else comparison.get("mode")
		status_label.text = {"Design":"Controlled design comparison", "Design + operations":"Design + operations comparison", "design":"Controlled design comparison", "controlled_design":"Controlled design comparison", "design_operations":"Design + operations comparison", "design_and_operations":"Design + operations comparison"}.get(classification, "Comparison scope Unavailable")
	elif state == "blocked": status_label.text = "Controlled comparison blocked"
	elif state == "example": status_label.text = "Measured example · eligibility pending"
	var interpretation: Variant = comparison.get("interpretation", comparison.get("explanation")) if binding else null
	var parts: Array = [{"raw":interpretation}] if interpretation is String and not interpretation.is_empty() else ["Save a completed flight as A, then continue with one design change. Both Debriefs remain available."]
	if state == "comparison" and not (interpretation is String and not interpretation.is_empty()): parts = ["Interpretation: Unavailable"]
	if state == "comparison" and comparison.get("limitations") is Array:
		parts.append("\nLimitations\n")
		for limitation in comparison.limitations:
			if limitation is String and not limitation.is_empty(): parts.append({"raw":limitation + "\n"})
	if inputs.get("storage_available") != true: parts = ["Saved-design services are unavailable on this build. Completed run measurements remain readable."]
	if saved and state == "pending": status_label.text = "Design A saved · ready for your next experiment"
	if inputs.get("feedback") is String and not inputs.feedback.is_empty(): parts = [inputs.feedback]
	var error: Dictionary = dictionary(inputs.get("error"))
	if not error.is_empty():
		status_label.text = "Review needed" if error.get("code") == "A_CHANGED" else "Comparison or action unavailable"
		var code: String = str(error.get("code", "UNAVAILABLE"))
		var message: String = str(error.get("message", "No additional detail was supplied."))
		var caption: String = COPY.code_label(code)
		parts = [{"raw":code}, ": ", {"copy":caption}]
		if message != caption: parts.append({"raw":"\n" + message})
		if error.get("code") == "A_CHANGED": parts.append("\nSaved A has been refreshed below. Review it before confirming again.")
	var reason_values: Variant = comparison.get("reasons", eligibility.get("reasons"))
	var reasons: Array = reason_values if reason_values is Array else []
	for reason in reasons:
		if reason is Dictionary: parts.append({"raw":"\n%s: %s" % [reason.get("code", "Unavailable"), reason.get("message", "Unavailable")]})
		elif reason is String: parts.append({"raw":"\n" + reason})
	if not comparison.is_empty() and not ready: parts.append("\nTwo distinct completed, non-aborted executions with matching reports are required.")
	if not comparison.is_empty() and not binding: parts.append("\nComparison identifiers do not match these executions.")
	COPY.pieces(explanation, "text", parts)
	COPY.raw(fixture_notice, "text", str(inputs.get("fixture_label", "")) if preview else "")
	fixture_notice.visible = preview
	COPY.bind(identities, "text", "A (saved): {0}\nB: {1}" if saved else "A candidate (not saved): {0}\nB: {1}", [a.get("run_id", {"copy":"Unavailable"}), b.get("run_id", {"copy":"Unavailable"})])
	COPY.bind(identities, "tooltip_text", "A mission: {0}\nA execution: {1}\nB mission: {2}\nB execution: {3}", [a.get("mission_id", {"copy":"Unavailable"}), a.get("execution_key", {"copy":"Unavailable"}), b.get("mission_id", {"copy":"Unavailable"}), b.get("execution_key", {"copy":"Unavailable"})])
	var show_supplied: bool = eligible or example
	for definition in METRICS:
		var name: String = definition[0]
		var supplied: Dictionary = supplied_metric(comparison, name) if show_supplied else {}
		var av: Variant = supplied.get("a", dictionary(a.get("metrics")).get(name) if completed(a) else null)
		var bv: Variant = supplied.get("b", dictionary(b.get("metrics")).get(name) if completed(b) else null)
		cells[name][0].text = _value(name, av, a)
		cells[name][1].text = _value(name, bv, b)
		# Deltas are supplied values only; never calculate a substitute comparison.
		cells[name][2].text = signed(supplied.get("delta")) if show_supplied else "Unavailable"
		cells[name][2].tooltip_text = str(supplied.get("delta_unit", definition[2]))
		if numeric(supplied.get("delta")) and show_supplied and not str(supplied.get("delta_unit", definition[2])).is_empty():
			cells[name][2].text += " " + str(supplied.get("delta_unit", definition[2]))
		for cell in cells[name]:
			if name != "outcome" and not "Unavailable" in cell.text: COPY.raw(cell, "text", cell.text)
			else: COPY.bind(cell, "text", "{0}", [{"copy":cell.text}])
			COPY.raw(cell, "tooltip_text", cell.tooltip_text)
	var changed: Variant = comparison.get("changed_parts") if show_supplied else null
	var part_lines: Array[String] = []
	if changed is Array:
		for part in changed:
			if part is String: part_lines.append(part)
			elif part is Dictionary: part_lines.append("%s: %s → %s" % [part.get("slot", part.get("field", "Part")), part.get("a", "Unavailable"), part.get("b", "Unavailable")])
	COPY.bind(changes, "text", "Changed parts\n{0}" if not part_lines.is_empty() else "Changed parts: {0}", ["\n".join(part_lines) if not part_lines.is_empty() else {"copy":"Unavailable"}])
	var storage: bool = inputs.get("storage_available") == true and not preview
	save_button.disabled = not storage or saved or not completed(candidate)
	replace_button.disabled = not storage or not saved or not completed(candidate) or candidate.get("run_id") == a.get("run_id")
	clear_button.disabled = not storage or not saved
	modify_button.disabled = preview or (inputs.get("modify_saved_available") != true and inputs.get("modify_current_available") != true)
	modify_button.text = "Continue Design B" if saved else "Modify current design"
	compare_button.disabled = preview or inputs.get("comparison_available") != true or not saved or not ready
	view_a_button.disabled = preview or not saved or not completed(a)
	view_b_button.disabled = preview or not completed(b)
	model = {"state":state, "eligible":eligible, "a_saved":saved, "preview":preview, "comparison":comparison.duplicate(true), "a":a.duplicate(true), "b":b.duplicate(true), "error":error.duplicate(true), "heading":status_label.text}

static func _value(name: String, value: Variant, record: Dictionary) -> String:
	if name == "outcome": return value if value is String else "Unavailable"
	if name == "qualifying_count": return Words.amount(value) + " / " + Words.amount(record.get("required_count"))
	if name == "score": return Words.amount(value) + " / 100" if numeric(value) else "Unavailable"
	return Words.amount(value)

func _save(replace: bool) -> void:
	if (replace and replace_button.disabled) or (not replace and save_button.disabled): return
	var candidate: Dictionary = inputs.candidate
	save_a_requested.emit(candidate.run_id, candidate.execution_key, replace)

func _confirm(intent: String) -> void:
	if (intent == "replace" and replace_button.disabled) or (intent == "clear" and clear_button.disabled): return
	pending_intent = intent
	pending_expected_a_key = str(dictionary(inputs.get("a")).get("execution_key", ""))
	pending_candidate = dictionary(inputs.get("candidate")).duplicate(true)
	_confirmation_focus = replace_button if intent == "replace" else clear_button
	confirmation.dialog_text = "Replace the saved A with this completed execution?" if intent == "replace" else "Clear the saved A reference?"
	confirmation.popup_centered(Vector2i(400, 160))

func _confirmed() -> void:
	var intent: String = pending_intent
	var candidate: Dictionary = pending_candidate.duplicate(true)
	confirmed_expected_a_key = pending_expected_a_key
	pending_intent = ""
	pending_expected_a_key = ""
	pending_candidate.clear()
	# Use the identities the player confirmed, even if refresh changed the view.
	# SE's compare-and-set guard decides whether that selection is still current.
	if intent == "replace" and not candidate.is_empty(): save_a_requested.emit(candidate.run_id, candidate.execution_key, true)
	elif intent == "clear": clear_a_requested.emit()

func _dismiss_confirmation() -> void:
	pending_intent = ""
	pending_expected_a_key = ""
	pending_candidate.clear()

func _restore_confirmation_focus() -> void:
	if is_instance_valid(_confirmation_focus) and not _confirmation_focus.disabled and _confirmation_focus.is_visible_in_tree(): _confirmation_focus.grab_focus()
	elif not modify_button.disabled and modify_button.is_visible_in_tree(): modify_button.grab_focus()

func _view(which: String) -> void:
	var button: Button = view_a_button if which == "a" else view_b_button
	if button.disabled: return
	var record: Dictionary = dictionary(inputs.get(which))
	view_execution_requested.emit(str(record.get("execution_key", "")))

func _modify() -> void:
	if modify_button.disabled: return
	if inputs.get("a_saved", false) and inputs.get("modify_saved_available", false):
		var a: Dictionary = inputs.a
		modify_a_requested.emit(a.run_id, a.execution_key)
	elif inputs.get("modify_current_available", false): modify_current_requested.emit()

func get_model() -> Dictionary:
	return model.duplicate(true)

static func record(trace: Dictionary, report: Dictionary) -> Dictionary:
	var final: Dictionary = dictionary(trace.get("final_state"))
	var validation: Dictionary = dictionary(dictionary(trace.get("validation")).get("metrics"))
	var config: Dictionary = dictionary(trace.get("config"))
	# The v1 capture counter is a qualifying count only for Imaging.
	var imaging: bool = dictionary(config.get("mission")).get("objective") == "imaging"
	return {
		"run_id":final.get("run_id"), "mission_id":final.get("mission_id"),
		"execution_key":Results.input_key(trace), "scenario_id":final.get("scenario_id"),
		"scenario_version":dictionary(final.get("scenario_snapshot")).get("scenario_version"),
		"phase":final.get("phase"), "run_status":final.get("run_status"),
		"config":config.duplicate(true), "report":report.duplicate(true),
		"required_count":report.get("required_observations") if imaging else null,
		"metrics":{
			"outcome":report.get("status"), "score":report.get("score"),
			"qualifying_count":report.get("observations_completed") if imaging else null,
			"returned_data_mb":report.get("returned_data_mb"),
			"total_cost_credits":validation.get("total_cost_credits"),
			"total_mass_g":validation.get("total_mass_g")}}

static func from_session(session: Dictionary, selected: Dictionary) -> Dictionary:
	var store: Dictionary = dictionary(session.get("evaluation_store"))
	var baseline: Dictionary = dictionary(store.get("baseline"))
	var a: Dictionary = {}
	var native: Dictionary = dictionary(baseline.get("state"))
	if not native.is_empty():
		var trace: Dictionary = {"config":native.get("config_snapshot", {}), "final_state":native, "events":native.get("event_log", []), "validation":dictionary(baseline.get("validation"))}
		var baseline_model: Dictionary = Presenter.build(trace, store)
		if baseline.get("execution_key") == Results.input_key(trace): a = record(trace, baseline_model.report)
	var selected_model: Dictionary = Presenter.build(selected, store)
	var current: Dictionary = record(selected, selected_model.report)
	var b: Dictionary = current if current.get("run_id") != a.get("run_id") else {}
	# Automatic baseline lookup is not an explicit Save A service. No independent store.
	return {"a":a, "b":b, "candidate":current, "a_saved":false, "comparison":dictionary(current.get("report")).get("comparison"), "storage_available":false, "comparison_available":false, "modify_current_available":session.get("run_trace", {}).get("final_state", {}).get("run_id") == current.get("run_id") and completed(current)}
