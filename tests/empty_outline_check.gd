extends SceneTree
## Explicit SYNTHETIC fixture runner; never referenced by either outline scene.

var _failures: Array[String] = []


class OwnerProbe:
	extends Node
	var draft: Dictionary = {"selections": {"instrument": "SYNTHETIC_ONLY"}}
	var step: int = 7
	var advance_calls: int = 0


	func advance_step() -> void:
		advance_calls += 1
		step += 1


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
		push_error(description)


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.is_empty() or arguments[0] not in ["operations", "results"]:
		printerr("Usage: --script res://tests/empty_outline_check.gd -- operations|results [--capture]")
		quit(2)
		return
	var kind: String = arguments[0]
	var scene_path := "res://ke3/%s_control.tscn" % kind
	var packed := load(scene_path) as PackedScene
	if packed == null:
		quit(1)
		return
	var scene = packed.instantiate()
	var probe := OwnerProbe.new()
	root.add_child(probe)
	var original_draft := probe.draft.duplicate(true)
	var intents := {"action": 0, "result_route": 0, "retry": 0}
	scene.action_requested.connect(func(_run_id: String, _action: StringName): intents["action"] += 1)
	scene.result_route_requested.connect(func(_run_id: String): intents["result_route"] += 1)
	scene.retry_requested.connect(func(_run_id: String): intents["retry"] += 1)
	scene.set_inputs({}, {}, {})
	root.add_child(scene)
	await process_frame
	await process_frame
	_expect(scene.get_input_snapshot() == {"context": {}, "state": {}, "report": {}}, "Empty inputs retained")
	for button in scene.find_children("*", "Button", true, false):
		_expect(button.disabled, "Empty-input intent button must be disabled")
	_expect(intents == {"action": 0, "result_route": 0, "retry": 0}, "Mount/render emitted no intents")
	_expect(probe.draft == original_draft and probe.step == 7 and probe.advance_calls == 0, "Owner probe unchanged across empty mount and idle frames")
	# The caller passes nested owner data; verify copied inputs and repeated renders.
	var context := {"run_id": "SYNTHETIC-run", "config_selections": probe.draft}
	var state := {"run_id": "SYNTHETIC-run", "sentinel_step": probe.step, "events": []}
	var report := {"run_id": "SYNTHETIC-run", "credits": []}
	var before := {"context": context.duplicate(true), "state": state.duplicate(true), "report": report.duplicate(true)}
	scene.set_inputs(context, state, report)
	scene.set_inputs(context, state, report)
	await process_frame
	_expect(context == before.context and state == before.state and report == before.report, "Rendering did not mutate caller dictionaries")
	var returned_snapshot: Dictionary = scene.get_input_snapshot()
	returned_snapshot.context.config_selections.selections.instrument = "CHANGED_COPY"
	_expect(probe.draft == original_draft, "Returned snapshot cannot mutate owner draft")
	_expect(scene.get_input_snapshot() == before, "Returned snapshot cannot mutate retained inputs")
	context.config_selections = {"caller_changed": true}
	state.events.append("CALLER_CHANGED")
	report.credits.append("CALLER_CHANGED")
	_expect(scene.get_input_snapshot() == before, "Caller changes cannot mutate retained inputs")
	_expect(probe.step == 7 and probe.advance_calls == 0, "No simulation step advanced")
	_expect(intents == {"action": 0, "result_route": 0, "retry": 0}, "Rendering snapshots emitted no intents")
	# End on explicit empty data for the independent window/capture check.
	scene.set_inputs({}, {}, {})
	await process_frame
	await process_frame
	if "--capture" in arguments:
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://verification")
		var image := root.get_texture().get_image()
		_expect(image.save_png("res://verification/%s-empty.png" % kind) == OK, "Screenshot saved")
	print("SYNTHETIC | ", scene_path, " | empty inputs injected; draft unchanged; step=", probe.step, "; advance_calls=", probe.advance_calls, "; intents=", intents)
	print("FIXTURE PASS" if _failures.is_empty() else "FAIL: " + str(_failures))
	scene.free()
	probe.free()
	quit(0 if _failures.is_empty() else 1)
