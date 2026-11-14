extends SceneTree
## KE2 adapter tests adapted to SE's terminal-only publication lifecycle.
const Runtime=preload("res://scripts/integration/mission_runtime.gd")
const Results=preload("res://scripts/integration/mission_results.gd")
var passed: int=0
var failed: int=0
func expect(value: bool,message: String) -> void:
 if value: passed+=1
 else:
  failed+=1
  print("FAIL ",message)
func _initialize() -> void:
 var draft: Dictionary=preload("res://data/mock/DesignCatalog.gd").DEFAULTS.duplicate(true)
 draft.observations=4
 draft.required_returned_data_mb=30
 draft.orbit="Polar – 600 km"
 var launched: Dictionary=Runtime.launch(draft)
 expect(launched.ok,"Real validated launch")
 var trace: Dictionary=launched.trace
 var original: Dictionary=trace.duplicate(true)
 expect(not draft.has("evaluation_store"),"No premature report publication during policy generation")
 var reply: Dictionary=Results.evaluate_trace(trace)
 expect(reply.ok and reply.report.score==100,"Actual terminal evaluator success")
 expect(trace.config==original.config and trace.events==original.events and trace.final_state==original.final_state,"Source snapshots preserved")
 expect(Results.evaluate_trace(trace)==reply,"Repeated evaluation deterministic")
 var payload: Dictionary=Results.presentation(trace)
 expect(payload.state.events==trace.events,"All ordered events passed to presentation")
 expect(payload.context.applicable_source_credits.size()==1 and payload.context.applicable_source_credits[0].credit_scope=="readiness","Success has readiness-only actual metadata")
 var collision: Dictionary=original.duplicate(true)
 collision.config.mission.required_returned_data_mb=60
 collision.final_state.config_snapshot=collision.config.duplicate(true)
 expect(Results.evaluate_trace(collision).report.score==90,"Same IDs different goal evaluated independently")
 expect(collision.evaluation_key!=trace.evaluation_key,"Same-ID execution key isolation")
 var mismatched: Dictionary=original.duplicate(true)
 mismatched.events.pop_back()
 expect(not Results.evaluate_trace(mismatched).ok,"Partial cumulative history rejected")
 expect(not Results.evaluate_trace({"config":null,"events":null,"final_state":null}).ok,"Malformed trace structured error")
 var published: Dictionary=Results.publish(draft,original.final_state)
 expect(published.ok and not published.existing,"Terminal published through existing SE hook")
 var retained: Dictionary=draft.evaluation_store.duplicate(true)
 expect(Results.publish(draft,original.final_state).existing and draft.evaluation_store==retained,"Duplicate publication idempotent")
 expect(not Results.publish(draft,collision.final_state).ok,"Reused run ID cannot replace another input execution")
 var baseline: Variant=draft.evaluation_store.baseline.duplicate(true)
 Results.retry(draft)
 expect(not draft.has("run_trace") and draft.evaluation_store.baseline==baseline,"Retry retains completed baseline/reports")
 var second: Dictionary=Runtime.launch(draft)
 expect(second.ok and second.trace.final_state.run_id!=original.final_state.run_id,"New run after Retry has distinct ID")
 expect(second.trace.frames[0].state.event_log.is_empty(),"Retry initial history fresh")
 print("KE2 ADAPTED RESULTS: ",passed," passed; ",failed," failed")
 quit(1 if failed else 0)
