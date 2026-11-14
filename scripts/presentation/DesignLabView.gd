extends VBoxContainer
## KE3 read-only presentation and intents. Session storage and comparison are owner inputs.
signal save_a_requested(run_id: String, execution_key: String, replace: bool)
signal modify_a_requested(run_id: String, execution_key: String)
signal modify_current_requested
signal compare_requested
signal clear_a_requested
const UI = preload("res://ui/components/UI.gd")
const Words = preload("res://scripts/presentation/PlayerLanguage.gd")
const METRICS = [["outcome","Outcome"],["qualifying_count","Qualifying count / goal"],["returned_data_mb","Returned MB"],["lowest_battery_wh","Lowest battery (Wh)"],["peak_storage_mb","Peak storage (MB)"],["total_cost_credits","Total cost"],["total_mass_g","Total mass (g)"]]
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

func _ready() -> void:
	add_theme_constant_override("separation",12)
	UI.label(self,"A / B DESIGN LAB",17,"b9f4e7")
	notice = UI.label(self,"Session only · Refreshing clears the saved pair.",14,"f4d38b")
	fixture_notice = UI.label(self,"",14,"f4d38b")
	status_label = UI.label(self,"",22,"b9f4e7")
	explanation = UI.label(self,"",15)
	identities = UI.label(self,"",12,"8ea9bb")
	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.columns = 4
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	add_child(grid)
	for title in ["Measurement","A","B","B − A"]: _cell(title,"8ea9bb",160 if title == "Measurement" else 85)
	for definition in METRICS:
		_cell(definition[1],"e6edf8",160)
		var row: Array[Label] = []
		for i in 3: row.append(_cell("Unavailable","e6edf8",85))
		cells[definition[0]] = row
	changes = UI.label(self,"",14)
	var actions = HFlowContainer.new()
	actions.add_theme_constant_override("h_separation",10)
	actions.add_theme_constant_override("v_separation",8)
	add_child(actions)
	save_button = UI.button(actions,"Save as A",func(): _save(false))
	replace_button = UI.button(actions,"Replace A…",func(): _confirm("replace"))
	modify_button = UI.button(actions,"Modify design",_modify)
	compare_button = UI.button(actions,"Compare A and B",func():
		if not compare_button.disabled: compare_requested.emit())
	clear_button = UI.button(actions,"Clear A…",func(): _confirm("clear"))
	for button in actions.get_children(): button.custom_minimum_size.y = 44
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Saved reference"
	confirmation.confirmed.connect(_confirmed)
	confirmation.canceled.connect(func(): pending_intent = "")
	add_child(confirmation)
	refresh()

func _cell(value: String,color: String,width: float) -> Label:
	var label: Label = UI.label(grid,value,14,color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = width
	return label

static func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value)

static func signed(value: Variant) -> String:
	if not numeric(value): return "Unavailable"
	return ("+" if value > 0 else "") + Words.amount(value)

static func completed(record: Dictionary) -> bool:
	return record.get("run_id") is String and not record.run_id.is_empty() and record.get("mission_id") is String and not record.mission_id.is_empty() and record.get("execution_key") is String and not record.execution_key.is_empty() and record.get("phase") == "finished" and record.get("run_status") == "completed" and record.get("report",{}).get("run_status") == "completed" and record.get("report",{}).get("run_id") == record.get("run_id") and record.get("report",{}).get("mission_id") == record.get("mission_id")

func set_inputs(value: Dictionary) -> void:
	inputs = value.duplicate(true)
	if is_node_ready(): refresh()

func refresh() -> void:
	var a: Dictionary = inputs.get("a",{})
	var b: Dictionary = inputs.get("b",{})
	var candidate: Dictionary = inputs.get("candidate",{})
	var comparison: Dictionary = inputs.get("comparison",{}) if inputs.get("comparison") is Dictionary else {}
	var saved: bool = inputs.get("a_saved",false)
	var binding: bool = comparison.get("a_run_id") == a.get("run_id") and comparison.get("b_run_id") == b.get("run_id") and comparison.get("a_execution_key") == a.get("execution_key") and comparison.get("b_execution_key") == b.get("execution_key")
	var ready: bool = completed(a) and completed(b) and a.get("run_id") != b.get("run_id") and a.get("mission_id") == b.get("mission_id") and a.get("scenario_id") is String and not str(a.scenario_id).is_empty() and a.get("scenario_id") == b.get("scenario_id") and a.get("scenario_version") != null and a.get("scenario_version") == b.get("scenario_version")
	var eligible: bool = saved and ready and binding and comparison.get("eligible") == true
	var state: String = "pending"
	if not comparison.is_empty():
		state = "comparison" if eligible else "blocked"
	status_label.text = "Live comparison pending"
	if state == "comparison":
		status_label.text = "Comparison mode Unavailable"
		if comparison.get("operations_differ") == true or comparison.get("mode") == "design_operations": status_label.text = "Design + operations comparison"
		elif comparison.get("mode") == "design": status_label.text = "Controlled design comparison"
	elif state == "blocked": status_label.text = "Controlled comparison blocked"
	var supplied_explanation: Variant = comparison.get("explanation")
	explanation.text = str(supplied_explanation) if supplied_explanation is String and not supplied_explanation.is_empty() else "Save A and comparison services are unavailable on this build. The completed run measurements below remain readable."
	if not comparison.is_empty() and not ready: explanation.text += "\nBoth inputs must be distinct completed, non-aborted executions with matching mission/scenario identities and reports."
	if not comparison.is_empty() and not binding: explanation.text += "\nComparison identifiers do not match these executions."
	fixture_notice.text = str(inputs.get("fixture_label",""))
	fixture_notice.visible = not fixture_notice.text.is_empty()
	identities.text = "A%s: %s\nB: %s" % [" (saved)" if saved else " candidate (not saved)",str(a.get("run_id","Unavailable")),str(b.get("run_id","Unavailable"))]
	for definition in METRICS:
		var name: String = definition[0]
		var supplied: Dictionary = comparison.get("metrics",{}).get(name,{}) if eligible else {}
		var av: Variant = supplied.get("a",a.get("metrics",{}).get(name))
		var bv: Variant = supplied.get("b",b.get("metrics",{}).get(name))
		cells[name][0].text = _value(name,av,a)
		cells[name][1].text = _value(name,bv,b)
		# Deltas are supplied values only. Never compute a substitute comparison.
		cells[name][2].text = signed(supplied.get("delta")) if eligible else "Unavailable"
	var changed: Variant = comparison.get("changed_parts") if eligible else null
	if changed is Array: changes.text = "Changed parts\n" + "\n".join(changed)
	else: changes.text = "Recorded part selections\n" + _parts(a,b)
	var storage: bool = inputs.get("storage_available",false)
	save_button.disabled = not storage or saved or not completed(candidate)
	replace_button.disabled = not storage or not saved or not completed(candidate) or candidate.get("run_id") == a.get("run_id")
	clear_button.disabled = not storage or not saved
	modify_button.disabled = not inputs.get("modify_saved_available",false) and not inputs.get("modify_current_available",false)
	modify_button.text = "Modify saved A" if saved else "Modify current design"
	compare_button.disabled = not inputs.get("comparison_available",false) or not saved or not ready
	model = {"state":state,"eligible":eligible,"a_saved":saved,"comparison":comparison.duplicate(true),"a":a.duplicate(true),"b":b.duplicate(true),"heading":status_label.text}

static func _value(name: String, value: Variant, record: Dictionary) -> String:
	if name == "outcome": return str(value) if value is String else "Unavailable"
	if name == "qualifying_count": return Words.amount(value) + " / " + Words.amount(record.get("required_count"))
	return Words.amount(value)

static func _parts(a: Dictionary,b: Dictionary) -> String:
	var left: Dictionary = a.get("config",{}).get("design",{})
	var right: Dictionary = b.get("config",{}).get("design",{})
	var lines: Array[String] = []
	for slot in ["bus_id","instrument_id","solar_id","battery_id","radio_id","storage_id"]:
		if left.has(slot) and right.has(slot) and left[slot] != right[slot]: lines.append("%s: %s → %s" % [slot,left[slot],right[slot]])
	return "\n".join(lines) if not lines.is_empty() else "Unavailable"

func _save(replace: bool) -> void:
	if (replace and replace_button.disabled) or (not replace and save_button.disabled): return
	var candidate: Dictionary = inputs.get("candidate",{})
	save_a_requested.emit(candidate.run_id,candidate.execution_key,replace)

func _confirm(intent: String) -> void:
	if (intent == "replace" and replace_button.disabled) or (intent == "clear" and clear_button.disabled): return
	pending_intent = intent
	confirmation.dialog_text = "Replace the saved A with this completed execution?" if intent == "replace" else "Clear the saved A reference?"
	confirmation.popup_centered(Vector2i(400,160))

func _confirmed() -> void:
	var intent: String = pending_intent
	pending_intent = ""
	if intent == "replace": _save(true)
	elif intent == "clear" and not clear_button.disabled: clear_a_requested.emit()

func _modify() -> void:
	if modify_button.disabled: return
	if inputs.get("a_saved",false) and inputs.get("modify_saved_available",false):
		var a: Dictionary = inputs.a
		modify_a_requested.emit(a.run_id,a.execution_key)
	elif inputs.get("modify_current_available",false): modify_current_requested.emit()

func get_model() -> Dictionary:
	return model.duplicate(true)

static func record(trace: Dictionary, report: Dictionary) -> Dictionary:
	var final: Dictionary = trace.get("final_state",{})
	var validation: Dictionary = trace.get("validation",{}).get("metrics",{})
	return {"run_id":final.get("run_id"),"mission_id":final.get("mission_id"),"execution_key":preload("res://scripts/integration/mission_results.gd").input_key(trace),"scenario_id":final.get("scenario_id"),"scenario_version":final.get("scenario_snapshot",{}).get("scenario_version"),"phase":final.get("phase"),"run_status":final.get("run_status"),"config":trace.get("config",{}).duplicate(true),"report":report.duplicate(true),"required_count":report.get("required_observations"),"metrics":{"outcome":report.get("status"),"qualifying_count":report.get("observations_completed"),"returned_data_mb":report.get("returned_data_mb"),"total_cost_credits":validation.get("total_cost_credits"),"total_mass_g":validation.get("total_mass_g")}}

static func from_session(session: Dictionary, selected: Dictionary) -> Dictionary:
	var store: Dictionary = session.get("evaluation_store",{})
	var baseline: Variant = store.get("baseline")
	var a: Dictionary = {}
	if baseline is Dictionary:
		var trace: Dictionary = {"config":baseline.state.config_snapshot,"final_state":baseline.state,"events":baseline.state.event_log,"validation":baseline.validation}
		a = record(trace,baseline.report)
	var current: Dictionary = record(selected,store.get("reports",{}).get(selected.get("final_state",{}).get("run_id"),{}))
	var b: Dictionary = current if current.get("run_id") != a.get("run_id") else {}
	# Current SE store is automatic baseline only. No explicit Save A hooks are present.
	return {"a":a,"b":b,"candidate":current,"a_saved":false,"comparison":current.get("report",{}).get("comparison"),"storage_available":false,"comparison_available":false,"modify_current_available":session.get("run_trace",{}).get("final_state",{}).get("run_id") == current.get("run_id") and completed(current)}
