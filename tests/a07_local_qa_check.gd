extends SceneTree
## A07 observation-only QA. Existing previews/providers own all supplied replies.
var checks: int = 0
var failures: Array[String] = []
var records: Array = []
var output_dir: String = "res://verification/a07-runs"
var capture_enabled: bool = false
var requested_size := Vector2i(1024, 768)

func _initialize() -> void:
	_run.call_deferred()
	create_timer(40).timeout.connect(func(): push_error("A07 watchdog timeout"); quit(1))

func expect(value: bool, label: String, actual: Variant = null) -> void:
	checks += 1
	records.append({"check":label,"pass":value,"actual":actual})
	if not value:
		failures.append(label)
		push_error(label + " actual=" + str(actual))

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func key(code: Key, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.shift_pressed = shift
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
	await settle()

func navigate(target: Control, label: String, reverse: bool = false) -> bool:
	for i in range(40):
		if root.gui_get_focus_owner() == target:
			expect(true,label)
			return true
		await key(KEY_TAB,reverse)
	expect(false,label,str(root.gui_get_focus_owner()))
	return false

func inside(control: Control, label: String) -> void:
	var rect := control.get_global_rect()
	var visible := Rect2(Vector2.ZERO,Vector2(root.size))
	# Screen containment alone is insufficient; check ancestor scroll clipping too.
	var node: Node = control.get_parent()
	while node != null:
		if node is ScrollContainer:
			visible = visible.intersection(node.get_global_rect())
		node = node.get_parent()
	expect(visible.encloses(rect),label,{"rect":str(rect),"visible_clip":str(visible),"window":str(root.size)})

func capture(name: String) -> void:
	if not capture_enabled:
		return
	await settle()
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(output_dir.path_join(name+".png")) == OK,"capture "+name)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	capture_enabled = "--capture" in args
	for i in range(args.size()):
		if args[i] == "--size" and i+1 < args.size():
			var values := args[i+1].split("x")
			requested_size = Vector2i(int(values[0]),int(values[1]))
		if args[i] == "--output-dir" and i+1 < args.size():
			output_dir = args[i+1]
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = requested_size
	await operations_checks()
	await debrief_checks()
	await recorded_checks()
	await retry_checks()
	var output := {"checks":checks,"failures":failures,"records":records,"requested_size":str(requested_size),"actual_size":str(root.size),"renderer":RenderingServer.get_current_rendering_method(),"scope":"A07 automated local engine key input; SYNTHETIC fixtures; not human/live/browser QA; B02 NOT TESTED"}
	var file := FileAccess.open(output_dir.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print("A07 RESULT: ",checks," checks; ",failures.size()," failures; viewport ",root.size)
	print("FIXTURE PASS" if failures.is_empty() else "FAIL — see recorded defects")
	quit(0 if failures.is_empty() else 1)

func operations_checks() -> void:
	var entry: Control = load("res://preview/a03_preview.tscn").instantiate()
	root.add_child(entry)
	await settle()
	entry.select_fixture("ready_step_2")
	await settle()
	expect(root.size == requested_size,"Operations actual requested viewport",str(root.size))
	var input: Dictionary = entry.operations.get_input_snapshot()
	var metrics: Dictionary = entry.operations.get_display_metrics()
	var original: Dictionary = entry.provider.catalog()
	for i in range(3):
		entry.select_fixture("ready_step_2")
		expect(input == entry.operations.get_input_snapshot() and metrics == entry.operations.get_display_metrics(),"Identical Operations input repeat "+str(i))
	expect(entry.action_intents == 0 and entry.provider.action_calls == 0,"Repeated rendering emits no action")
	entry._selector.grab_focus()
	var before_focus_metrics: Dictionary = entry.operations.get_display_metrics()
	if await navigate(entry.operations._action_buttons.observe,"Tab reaches Observe"):
		expect(entry.action_intents == 0 and entry.provider.action_calls == 0 and before_focus_metrics == entry.operations.get_display_metrics(),"Observe focus emits zero intents and preserves telemetry")
		inside(entry.operations._action_buttons.observe,"Keyboard-focused Observe visible without mouse scrolling")
		await capture("operations-observe-focus")
		await key(KEY_SPACE)
		expect(entry.action_intents == 1 and entry.provider.action_calls == 1 and entry.operations.get_display_metrics().step == "3","Keyboard Space dispatches exactly one Observe",entry.operations.get_display_metrics())
	if await navigate(entry.operations._action_buttons.power_save,"Tab reaches Power-save"):
		inside(entry.operations._action_buttons.power_save,"Keyboard-focused Power-save visible")
		expect(entry.action_intents == 1 and entry.provider.action_calls == 1,"Power-save focus alone dispatches zero")
		await key(KEY_ENTER)
		expect(entry.action_intents == 2 and entry.provider.action_calls == 2 and entry.operations.get_display_metrics().step == "4","Keyboard Enter dispatches exactly one Power-save")
	entry.select_fixture("contact_on")
	await settle()
	entry._selector.grab_focus()
	var contact_snapshot: Dictionary = entry.operations.get_input_snapshot()
	if await navigate(entry.operations._action_buttons.downlink,"Tab reaches Transmit"):
		inside(entry.operations._action_buttons.downlink,"Keyboard-focused Transmit visible")
		var focused: Button = entry.operations._action_buttons.downlink
		var clip: Control = focused.get_parent().get_parent().get_parent().get_parent()
		expect(clip.get_global_rect().encloses(focused.get_global_rect().grow(3)),"Transmit focus outline fits visible scroll clip")
		expect(entry.action_intents == 2 and entry.provider.action_calls == 2 and contact_snapshot == entry.operations.get_input_snapshot(),"Transmit focus alone dispatches zero and preserves full snapshot")
		await capture("operations-transmit-focus")
		await key(KEY_SPACE)
		expect(entry.action_intents == 3 and entry.provider.action_calls == 3 and entry.operations.get_display_metrics().returned == "2 MB","Keyboard Transmit uses supplied reply")
	entry.select_fixture("ready_step_2")
	await settle()
	# A disabled request remains provider-owned: neither keyboard activation nor the
	# guarded view request may dispatch when the supplied capability is disabled.
	var disabled: Button = entry.operations._action_buttons.downlink
	disabled.grab_focus()
	await key(KEY_SPACE)
	entry.operations.request_action(&"downlink")
	expect(disabled.disabled and entry.action_intents == 3 and entry.provider.action_calls == 3,"Disabled Transmit keyboard/guarded request dispatches zero")
	expect(input == entry.operations.get_input_snapshot() and metrics == entry.operations.get_display_metrics(),"Clean preview reset restores initial input/HUD")
	expect(original == entry.provider.catalog(),"Operations source fixtures unchanged")
	await capture("operations-reset")
	entry.queue_free()
	await settle()

func debrief_checks() -> void:
	var entry: Control = load("res://preview/a05_preview.tscn").instantiate()
	root.add_child(entry)
	await settle()
	entry.select_fixture("debrief_long")
	await settle()
	expect(root.size == requested_size,"Debrief actual requested viewport",str(root.size))
	var original: Dictionary = entry.results.get_input_snapshot()
	var model: Dictionary = entry.results.get_debrief_model()
	expect(model.summary.ends_with("End of synthetic explanation.") and model.credits.contains("End of synthetic source credit."),"Full long explanation and credits retained")
	var scroll: ScrollContainer = entry.results._scroll
	expect(scroll.get_v_scroll_bar().max_value > scroll.size.y,"Long Debrief content scrolls vertically")
	inside(entry.results._retry_button,"Long Debrief Retry footer inside viewport")
	inside(entry.results._credits_button,"Long Debrief Credits footer inside viewport")
	scroll.grab_focus()
	await key(KEY_TAB)
	expect(root.gui_get_focus_owner() == entry.results._credits_button,"Tab reaches Credits")
	await key(KEY_ENTER)
	expect(scroll.scroll_vertical > 0,"Keyboard Enter reveals credits",scroll.scroll_vertical)
	await capture("debrief-long-credits")
	await key(KEY_TAB)
	expect(root.gui_get_focus_owner() == entry.results._retry_button,"Tab reaches Retry")
	await key(KEY_TAB,true)
	expect(root.gui_get_focus_owner() == entry.results._credits_button,"Shift+Tab restores Credits focus")
	# Scroll through reason/summary with keyboard; no report mutation or new intents.
	scroll.scroll_vertical = 0
	await settle()
	scroll.grab_focus()
	await settle()
	var before_focus := str(root.gui_get_focus_owner())
	await key(KEY_PAGEDOWN)
	var after_page := {"scroll_y":scroll.scroll_vertical,"focus":str(root.gui_get_focus_owner())}
	expect(scroll.scroll_vertical > 0,"Focused PageDown scrolls down",scroll.scroll_vertical)
	var position_before := scroll.scroll_vertical
	await key(KEY_DOWN)
	expect(scroll.scroll_vertical > position_before,"Focused Down scrolls down",scroll.scroll_vertical)
	position_before = scroll.scroll_vertical
	await key(KEY_UP)
	expect(scroll.scroll_vertical < position_before,"Focused Up scrolls up",scroll.scroll_vertical)
	position_before = scroll.scroll_vertical
	await key(KEY_PAGEUP)
	expect(scroll.scroll_vertical < position_before,"Focused PageUp scrolls up",scroll.scroll_vertical)
	for i in range(8):
		await key(KEY_DOWN)
	expect(scroll.scroll_vertical > 0,"Long Debrief focused scroll responds to PageDown/Down",{"initial_focus":before_focus,"after_page_down":after_page,"scroll_y":scroll.scroll_vertical,"focus":str(root.gui_get_focus_owner()),"vscroll_focus_mode":scroll.get_v_scroll_bar().focus_mode})
	expect(root.gui_get_focus_owner() == scroll,"Scrolling retains report-region focus")
	expect(original == entry.results.get_input_snapshot() and model == entry.results.get_debrief_model(),"Scrolling leaves raw report/context/state and labels intact")
	# Keyboard handling is local to the scroll region, not global UI shortcuts.
	entry.results._retry_button.grab_focus()
	position_before = scroll.scroll_vertical
	await key(KEY_PAGEDOWN)
	expect(scroll.scroll_vertical == position_before and entry.retry_intents == 0,"PageDown outside report region does not scroll or Retry")
	for i in range(3):
		entry.select_fixture("debrief_long")
		expect(original == entry.results.get_input_snapshot() and model == entry.results.get_debrief_model(),"Identical long Debrief repeat "+str(i))
	expect(entry.action_intents == 0 and entry.retry_intents == 0,"Long content/focus/re-entry never changes run or retries")
	await capture("debrief-long-top")
	# A labeled, memory-only layout stress copy; it is not a KE2 scientific claim.
	var stress: Dictionary = original.duplicate(true)
	stress.report.root_causes[0].explanation = "SYNTHETIC A07 layout-only long reason; no new scientific cause is asserted. ".repeat(60) + "End of A07 synthetic long reason."
	entry.results.set_inputs(stress.context,stress.state,stress.report)
	await settle()
	expect(entry.results.get_debrief_model().causes.contains("End of A07 synthetic long reason."),"Long root-cause text retained without truncating model")
	expect(entry.results.get_input_snapshot().report == stress.report and original.report.root_causes[0].explanation != stress.report.root_causes[0].explanation,"Long-reason stress copy leaves original fixture independent")
	entry.results._scroll.ensure_control_visible(entry.results._fields.causes.get_parent().get_parent().get_parent())
	await capture("debrief-long-cause")
	entry.select_fixture("debrief_zero_score")
	expect(entry.results.get_debrief_model().score == "0","Zero score remains visible")
	entry.select_fixture("debrief_aborted")
	expect(entry.results.get_debrief_model().score == "Unavailable" and entry.results.get_debrief_model().run_status == "aborted","Null abort score remains distinct")
	entry.queue_free()
	await settle()

func recorded_checks() -> void:
	var entry: Control = load("res://preview/ke2_recorded_preview.tscn").instantiate()
	root.add_child(entry)
	await settle()
	var model: Dictionary = entry.results.get_debrief_model()
	var trace: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://preview/recorded_ke2/hpc-ke2-trace-ce478f9.json"))
	expect(trace.validation.launch_approved == false,"Recorded HPC sample explicitly has launch approval false")
	expect([model.status,model.score,model.observations,model.returned] == ["partial","25","1/4","7.7333333328/30 MB"],"Recorded KE2 exact supplied metrics at small viewport",entry.results.get_visible_labels())
	expect(model.causes.contains("Evidence: evt_008 | Step 8 | No ground station contact window is available during this step."),"Recorded same-run step8 evidence at small viewport")
	expect(root.size == requested_size,"Recorded KE2 actual requested viewport",str(root.size))
	inside(entry.results._retry_button,"Recorded KE2 Retry visible")
	inside(entry.results._credits_button,"Recorded KE2 Credits visible")
	await capture("recorded-ke2-top")
	entry.results._scroll.ensure_control_visible(entry.results._fields.causes.get_parent().get_parent().get_parent())
	await capture("recorded-ke2-cause")
	entry.results._scroll.grab_focus()
	await key(KEY_TAB)
	await key(KEY_ENTER)
	expect(entry.results.get_visible_labels().credits.contains("Profile credit: Unavailable"),"Recorded sample empty source IDs do not create NASA credit")
	await capture("recorded-ke2-credits")
	entry.queue_free()
	await settle()

func retry_checks() -> void:
	var entry: Control = load("res://preview/a06_preview.tscn").instantiate()
	root.add_child(entry)
	await settle()
	var initial: Dictionary = entry.results.get_input_snapshot()
	var baseline: Dictionary = entry.receiver.get_completed()
	# A06 establishes initial keyboard focus on Retry. Every activation below is a key event.
	expect(root.gui_get_focus_owner() == entry.results._retry_button,"A06 entry initializes Retry focus")
	inside(entry.results._retry_button,"Initial Retry footer inside viewport")
	await key(KEY_SPACE)
	await create_timer(0.7).timeout
	expect(entry.retry_intents == 1 and entry.receiver.accepted,"Keyboard Retry receives one accepted synthetic route")
	expect(root.gui_get_focus_owner() == entry.draft_screen.component_selector,"Retry draft focus initialized")
	if await navigate(entry.draft_screen.cancel_button,"Tab reaches Back/Cancel"):
		inside(entry.draft_screen.cancel_button,"Draft Back/Cancel visible")
		await key(KEY_ENTER)
		expect(entry.receiver.get_draft().is_empty() and entry.results.get_input_snapshot() == initial,"Keyboard Cancel returns untouched completed A")
	await key(KEY_ENTER)
	await create_timer(0.7).timeout
	if await navigate(entry.draft_screen.value_selector,"Tab reaches component value selector"):
		await key(KEY_SPACE)
		await key(KEY_ESCAPE)
		expect(root.gui_get_focus_owner() == entry.draft_screen.value_selector,"Escape dismisses option popup and restores selector focus")
		await key(KEY_SPACE)
		await key(KEY_DOWN)
		await key(KEY_ENTER)
	expect(entry.receiver.get_draft().get("design",{}).get("radio_id") == "SYNTHETIC-RADIO-002","Keyboard selects one different radio",entry.receiver.get_draft())
	await capture("retry-edited-draft")
	if await navigate(entry.draft_screen.start_button,"Tab reaches second-run Start"):
		inside(entry.draft_screen.start_button,"Draft Start visible")
		await key(KEY_SPACE)
	await settle()
	var b: Dictionary = entry.operations.get_input_snapshot()
	expect(b.context.get("run_id") == "SYNTHETIC-A06-RUN-B-001","Keyboard Start creates distinct synthetic B",b.context.get("run_id"))
	expect(entry.operations.get_display_metrics().step == "0" and b.report.is_empty() and b.state.events.size() == 1,"Second-run reset clears old counters/report/history")
	expect(baseline == entry.receiver.get_completed(),"Retry keeps independent original baseline")
	# New view entry does not guarantee focus: test ordinary Tab traversal from its current owner.
	if await navigate(entry.operations._action_buttons.observe,"Tab reaches B Observe"):
		inside(entry.operations._action_buttons.observe,"B Observe visible by keyboard")
		await key(KEY_ENTER)
		await create_timer(0.7).timeout
		expect(entry.provider.action_calls == 1 and entry.operations.get_display_metrics().step == "1","Keyboard B Observe exactly once")
	if await navigate(entry.finish_button,"Tab reaches terminal fixture control"):
		await key(KEY_SPACE)
	if await navigate(entry.operations._route_button,"Tab reaches Results route"):
		await key(KEY_ENTER)
	await settle()
	expect(entry.results.get_debrief_model().status == "success" and entry.results.get_debrief_model().score == "100","Keyboard-only path reaches supplied second Debrief")
	expect(entry.receiver.get_completed().order.size() == 2,"Exactly two completed synthetic runs")
	inside(entry.back_button,"Second Debrief Back visible")
	inside(entry.results._retry_button,"Second Debrief Retry visible")
	await capture("retry-second-debrief")
	expect(initial == entry.receiver.get_completed().runs.get("SYNTHETIC-A06-RUN-A-001"),"Original A snapshot unchanged by complete keyboard flow")
	records.append({"check":"Final keyboard-only intent counts","retry":entry.retry_intents,"route":entry.route_intents,"actions":entry.action_intents,"starts":entry.provider.start_calls})
	entry.queue_free()
	await settle()
	var fresh: Control = load("res://preview/a06_preview.tscn").instantiate()
	root.add_child(fresh)
	await settle()
	expect(fresh.results.get_input_snapshot() == initial and fresh.receiver.get_completed() == baseline,"Fresh preview reset repeats exact original state")
	expect(fresh.action_intents == 0 and fresh.retry_intents == 0 and fresh.provider.start_calls == 0,"Fresh entry has no retained intent/launch state")
	fresh.queue_free()
	await settle()
