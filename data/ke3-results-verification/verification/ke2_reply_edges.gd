extends "res://tests/ke2_recorded_debrief_check.gd"
## Extra local display/error-contract cases only; not new KE2 evaluated outcomes.
class ContractErrorProvider:
	extends RefCounted
	var wrapper: Dictionary
	func _init(value: Dictionary) -> void: wrapper = value.duplicate(true)
	func open_run(_run: String) -> Dictionary: return wrapper.duplicate(true)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	output_dir = args[0]
	capture_enabled = "--capture" in args
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1280,960)
	entry = load("res://preview/ke2_validated_preview.tscn").instantiate()
	root.add_child(entry)
	await process_frame
	await process_frame
	var original: Dictionary = entry.results.get_input_snapshot()
	var report_before: Dictionary = original.report.duplicate(true)
	var model: Dictionary = entry.results.get_debrief_model()
	expect(model.summary.contains("4.2666666672 MB remain onboard"),"Onboard amount displayed verbatim in supplied summary")
	same("Returned exact experiment","Retry and transmit during an available ground-contact window.",model.next_experiment)
	# Explicit local fixtures exercise display fallbacks; original source stays untouched.
	var empty: Dictionary = original.duplicate(true)
	empty.report.root_causes = []
	entry.results.set_inputs(empty.context,empty.state,empty.report)
	same("Empty causes are neutral","No root causes supplied.",entry.results.get_debrief_model().causes)
	same("Empty causes retain summary",original.report.explanation,entry.results.get_debrief_model().summary)
	same("Empty causes keep comparison null",null,entry.results.get_input_snapshot().report.comparison)
	records.append({"case":"SYNTHETIC empty-causes display fixture","labels":entry.results.get_visible_labels()})
	await capture("reply-empty-causes")
	var aborted: Dictionary = original.duplicate(true)
	aborted.state.run_status = "aborted"
	aborted.report.run_status = "aborted"
	aborted.report.status = "failed"
	aborted.report.score = null
	aborted.report.root_causes = []
	aborted.report.explanation = "SYNTHETIC DISPLAY CHECK: Mission aborted before completion."
	entry.results.set_inputs(aborted.context,aborted.state,aborted.report)
	same("Abort preserves failed/aborted/null-score display",["failed","aborted","Unavailable"],[entry.results.get_debrief_model().status,entry.results.get_debrief_model().run_status,entry.results.get_debrief_model().score])
	same("Abort raw null never becomes zero",null,entry.results.get_input_snapshot().report.score)
	same("Abort raw actuals preserved",[1.0,7.7333333328],[entry.results.get_input_snapshot().report.observations_completed,entry.results.get_input_snapshot().report.returned_data_mb])
	records.append({"case":"SYNTHETIC aborted display fixture, not an evaluated abort","labels":entry.results.get_visible_labels()})
	await capture("reply-aborted-null")
	for file_name in ["evaluation-nonterminal-error.example.json","evaluation-top-level-error.example.json"]:
		var wrapper: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1].path_join(file_name)))
		var error_before := wrapper.duplicate(true)
		entry.session.bind_provider(ContractErrorProvider.new(wrapper))
		var rejected: Dictionary = entry.session.open_run(original.context.run_id)
		expect(not rejected.accepted,"Exact contract wrapper rejected safely "+file_name)
		expect(entry.results.get_input_snapshot().report.is_empty(),"ok=false never produces a report "+file_name)
		expect(entry.results._boundary_label.text.contains(wrapper.error.code) and entry.results._boundary_label.text.contains(wrapper.error.suggested_fix),"Raw provider error visibly retains code/fix "+file_name)
		same("Error is not a failed mission","Unavailable",entry.results.get_debrief_model().status)
		same("Error cannot Retry report",true,entry.results._retry_button.disabled)
		same("Null or supplied error identity unchanged",error_before,wrapper)
		records.append({"case":"Exact contract error through preview provider","source_file":file_name,"wrapper":wrapper,"boundary":entry.results._boundary_label.text,"labels":entry.results.get_visible_labels()})
		await capture("reply-"+file_name.trim_suffix(".json"))
		# Structured EvaluationError view binding is only supported for a known run.
		# Do not stamp the null-ID error with an unrelated active run ID.
		if wrapper.error.run_id != null:
			var context := {"run_id":wrapper.error.run_id,"config":original.context.config.duplicate(true),"evaluation_error":wrapper.error.duplicate(true)}
			var state := {"run_id":wrapper.error.run_id,"events":[]}
			entry.results.set_inputs(context,state,{})
			same("Known-run error has structured Evaluation error display","evaluation_error",entry.results.get_debrief_model().presentation_state)
			expect(entry.results.get_debrief_model().summary.contains(wrapper.error.suggested_fix),"Known-run suggested correction displayed")
			await capture("reply-structured-known-run-error")
	same("Rendering edge cases emits no action/route/retry",{"action":0,"route":0,"retry":0},entry.intent_counts)
	same("Original validated report object untouched",report_before,original.report)
	var f := FileAccess.open(output_dir.path_join("reply-edges.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"records":records,"scope":"Additional preview display/contract cases only; SE integration/New Mission NOT TESTED"},"  "))
	f.close()
	print("KE2 REPLY EDGES: ",checks," checks; ",failures.size()," failures")
	print("FIXTURE PASS" if failures.is_empty() else "FAIL")
	entry.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
