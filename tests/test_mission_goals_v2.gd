extends SceneTree
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const Results = preload("res://scripts/integration/mission_results.gd")
const Record = preload("res://scripts/integration/execution_record.gd")
const Presenter = preload("res://scripts/presentation/DebriefPresentation.gd")
const Step = preload("res://core/MissionStepEngine.gd")
var passed: int=0
var failed: int=0
func _initialize(): run.call_deferred()
func check(value: bool, label: String):
	if value: passed+=1
	else: failed+=1;printerr("FAIL: ",label)
func run():
	for id in ["communication","weather_monitoring"]:
		for variant in ["starter","count_shortfall","no_delivery","quota_only","half_up"]:
			if id=="weather_monitoring" and variant in ["quota_only","half_up"]: continue
			var draft: Dictionary=preload("res://data/mock/DesignCatalog.gd").DEFAULTS.duplicate(true)
			check(Runtime.select_preset(draft,id).ok,id+": select preset")
			if variant=="half_up": draft.goal.required_positive_contact_steps=4
			if variant=="quota_only": draft.engineering_parts.radio="radio_basic"
			var options: Dictionary={}
			if variant!="starter":
				var observe: Array=[1,6] if id=="communication" else [1,11]
				if variant in ["count_shortfall","half_up","quota_only"]: observe=[1] if id=="communication" else [1,6]
				var plan: Array=[]
				for i in 30: plan.append({"step_index":i,"action":"observe" if i in observe else ("transmit" if i in [7,10,17,20,27] and variant!="no_delivery" else "power_save")})
				options.action_plan=plan
			var launched: Dictionary=Runtime.launch(draft,{},options)
			check(launched.ok,id+" "+variant+": launch")
			if not launched.ok:printerr(launched);continue
			var trace: Dictionary=draft.run_trace.duplicate(true)
			var before: Dictionary=trace.duplicate(true)
			var reply: Dictionary=Evaluator.evaluate_mission(trace.config,trace.final_state,trace.events)
			check(reply.ok,id+" "+variant+": evaluated")
			if not reply.ok:printerr(reply);continue
			var report: Dictionary=reply.report
			var expected: int=100 if variant in ["starter","quota_only"] else (63 if variant=="half_up" else (75 if variant=="count_shortfall" else (0 if id=="communication" else 50)))
			check(report.schema_version==2 and report.objective==id,"Report v2 preserves objective")
			check(report.score==expected,id+" "+variant+": exact agreed score")
			check(report.status==("success" if expected==100 else ("failed" if expected==0 else "partial")),"Raw goal outcome")
			check(report.goal_progress.size()==2,"Count and returned data are separate goal rows")
			check(trace==before,"Evaluation preserves every input")
			if variant=="quota_only":check(report.observations_completed==1 and report.required_observations==2 and report.status=="success","Capture quota is not an extra Communication success condition")
			draft.active_run_state=trace.final_state.duplicate(true)
			check(Results.publish(draft,draft.active_run_state).ok,"Real terminal publication")
			var key: String=Results.input_key(trace)
			var portable: Dictionary=Results.export_execution_record(draft,key)
			check(portable.ok,"Expanded execution can be exported")
			if portable.ok:check(Record.verify(JSON.parse_string(JSON.stringify(portable.record,"",true,true))).ok,"Expanded portable record survives JSON reload")
			var store: Dictionary=draft.evaluation_store.duplicate(true)
			store.reports[report.run_id].goal_progress[0].actual+=1
			check(Presenter.build(trace,store).state=="stale_report","Forged goal progress cannot attach to this run")
			var forged: Dictionary=trace.final_state.duplicate(true)
			forged.returned_data_mb+=1
			check(not Evaluator.evaluate_mission(trace.config,forged,forged.event_log).ok,"Returned MB must match accepted events")
			forged=trace.final_state.duplicate(true);forged.goal_progress.actual_count+=1
			check(not Evaluator.evaluate_mission(trace.config,forged,forged.event_log).ok,"Forged goal counter rejected")
			check(not Evaluator.evaluate_mission(trace.config,trace.final_state,[]).ok,"Missing event evidence rejected")
			var initial: Dictionary=trace.frames[0].state
			check(not Evaluator.evaluate_mission(trace.config,initial,initial.event_log).ok,"Operating state is not evaluated early")
			if variant=="starter":
				var aborted: Dictionary=Step.abort_run(initial,"Scoring abort control")
				check(aborted.ok,"Abort remains a native terminal outcome")
				var stopped: Dictionary=Evaluator.evaluate_mission(trace.config,aborted.state,aborted.state.event_log)
				check(stopped.ok and stopped.report.run_status=="aborted" and stopped.report.status=="failed" and stopped.report.score==null,"Aborted flight has no numeric score")
	check(not Evaluator.evaluate_mission({"schema_version":2,"mission":[]},{},[]).ok,"Malformed v2 mission returns a structured error")
	print("New mission scoring: ",passed," checks passed; ",failed," failed")
	quit(0 if failed==0 else 1)
