extends "res://scripts/screens/Workbench.gd"
const Workflow = preload("res://scripts/integration/mission_workflow.gd")
const ORBIT_VIEW = preload("res://scenes/ui/components/OperationsOrbitViewport.tscn")
var run_configuration: Dictionary = {}
var orbit_view: SubViewportContainer
var status: Label
var telemetry: Label
var next_events: Label
var timeline: ItemList
var action_buttons: Dictionary = {}
var play_button: Button
var step_button: Button
var skip_button: Button
var stop_button: Button
var playing: bool = false
var elapsed: float = 0.0

func _ready() -> void:
	screen_id = "MissionOperations"
	setup("05", "Mission Operations", "Observe, send data, or save power as the mission moves through its orbit windows.", 3, 5, "View Debrief")
	var layout = row(content)
	var left = column(layout, 1.0)
	var right = column(layout, 1.5)
	status = UI.label(section(left, "Mission status"), "", 18, "75e3d7")
	telemetry = UI.label(section(left, "Live resources and goals"), "", 14)
	var actions = section(left, "Choose an action")
	for entry in [["observe", "Observe"], ["transmit", "Send data"], ["power_save", "Save power"]]:
		var button = UI.button(actions, entry[1], take_action.bind(entry[0]))
		button.custom_minimum_size.y = 42
		action_buttons[entry[0]] = button
	next_events = UI.label(actions, "", 12, "e8c38c")
	var preview_box = section(right, "Orbit view")
	orbit_view = ORBIT_VIEW.instantiate()
	orbit_view.custom_minimum_size = Vector2(330, 270)
	preview_box.add_child(orbit_view)
	orbit_view.configure(state)
	UI.label(preview_box, "Illustrative orbit view. Action availability follows the selected orbit's authored windows.", 11, "8baabd")
	var controls = row(right)
	play_button = UI.button(controls, "Run automatically", toggle_play)
	step_button = UI.button(controls, "Next step", step_once)
	skip_button = UI.button(controls, "Run to end", finish_run)
	stop_button = UI.button(controls, "Stop mission", stop_run)
	timeline = ItemList.new()
	timeline.custom_minimum_size.y = 150
	timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(timeline)
	if not state.get("active_run", {}).is_empty():
		run_configuration = state.active_run.config.duplicate(true)
	resized.connect(fit_navigation)
	refresh()

func take_action(action: String) -> void:
	playing = false
	var result: Dictionary = Workflow.request_action(state, action)
	refresh()
	if not result.get("ok", true): next_events.text = result.error.message

func step_once() -> void:
	var result: Dictionary = Workflow.automatic_step(state)
	if not result.get("ok", true): playing = false
	refresh()
	if not result.get("ok", true): next_events.text = result.error.message

func toggle_play() -> void:
	playing = not playing
	refresh()

func _process(delta: float) -> void:
	if not playing: return
	elapsed += delta
	if elapsed >= 0.35:
		elapsed = 0.0
		step_once()

func finish_run() -> void:
	playing = false
	# Each accepted step advances once; this bound also prevents an endless UI loop.
	for index in 120:
		if not Workflow.is_operating(state): break
		var result: Dictionary = Workflow.automatic_step(state)
		if not result.get("ok", true): break
	refresh()

func stop_run() -> void:
	playing = false
	Workflow.abort(state)
	refresh()

func refresh() -> void:
	if state.get("active_run", {}).is_empty():
		status.text = "Launch a valid design first."
		next_button.disabled = true
		return
	var run: Dictionary = state.active_run
	var live: Dictionary = run.state
	var operating: bool = live.phase == "operating"
	if not operating: playing = false
	status.text = "%s\nStep %d / %d · %s" % [run.config.mission.title, live.step_index, live.total_steps, "OPERATING" if operating else str(live.run_status).to_upper()]
	telemetry.text = "Battery: %.2f / %.2f Wh\nStored: %.2f / %.2f MB\nReturned: %.2f / %.2f MB\nCaptured: %d / %d\nSunlit: %s · Target access: %s\nGround contact: %s" % [live.energy_wh, live.battery_capacity_wh, live.stored_data_mb, live.storage_capacity_mb, live.returned_data_mb, run.config.mission.required_returned_data_mb, live.observations_completed, run.config.mission.required_observations, str(live.is_sunlit), str(live.in_target_access), str(live.in_ground_contact)]
	var reasons: PackedStringArray = []
	for action in action_buttons:
		var availability: Dictionary = live.available_actions.get(action, {})
		action_buttons[action].disabled = not operating or not availability.get("allowed", false)
		action_buttons[action].tooltip_text = str(availability.get("reason", "")) if availability.get("reason") != null else ""
		if operating and not availability.get("allowed", false) and availability.get("reason") != null:
			reasons.append(str(availability.reason))
	next_events.text = "\n".join(reasons) if operating else "Mission finished. Open Debrief to see the actual result."
	play_button.text = "Pause" if playing else "Run automatically"
	for button in [play_button, step_button, skip_button, stop_button]: button.disabled = not operating
	previous.disabled = operating
	next_button.disabled = operating
	timeline.clear()
	for event in live.event_log:
		timeline.add_item("Step %d · %s" % [event.step_index, event.message])
	if timeline.item_count > 0: timeline.ensure_current_is_visible()
	var kind: String = ""
	if not live.event_log.is_empty():
		var last: Dictionary = live.event_log[-1]
		if last.type == "action_accepted": kind = "OBSERVE" if last.action == "observe" else ("TX" if last.action == "transmit" else "")
	orbit_view.set_frame(float(live.step_index) / maxf(1, live.total_steps), kind)
