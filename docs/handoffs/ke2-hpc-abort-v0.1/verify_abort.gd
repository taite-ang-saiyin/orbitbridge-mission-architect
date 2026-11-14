extends SceneTree
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
const StepEngine = preload("res://core/MissionStepEngine.gd")
const Loader = preload("res://scripts/core/catalog_loader.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
    var bundle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://input-bundle.json"))
    var before: Dictionary = bundle.duplicate(true)
    var config: Dictionary = bundle["launch_config"]
    var terminal: Dictionary = bundle["terminal_state"]
    var events: Array = bundle["ordered_events"]
    check("literal run ID", bundle["run_id"] == "run_hpc_ke2_abort_3990d3c_01")
    check("source revision", bundle["source"]["source_commit_sha"] == "3990d3c7aae3b69dcf367d9f0601fc40fd669262")
    check("terminal identity", terminal["run_id"] == bundle["run_id"] and terminal["mission_id"] == bundle["mission_id"])
    check("launch snapshot", equivalent(terminal["config_snapshot"], config))
    check("full ordered history", equivalent(terminal["event_log"], events) and events.size() == 10)
    check("abort response state", equivalent(bundle["abort_response"]["state"], terminal))
    check("abort response event", equivalent(bundle["abort_response"]["events"], [bundle["abort_event"]]))
    check("operator reason", terminal["terminal_reason"] is String and not terminal["terminal_reason"].strip_edges().is_empty() and terminal["terminal_reason"] == bundle["abort_reason"])
    var last_step: int = -1
    for index: int in range(events.size()):
        var event: Dictionary = events[index]
        check("event %d identity/order" % index, event["event_id"] == "evt_%03d" % index and event["run_id"] == bundle["run_id"] and event["mission_id"] == bundle["mission_id"] and event["step_index"] >= last_step)
        last_step = int(event["step_index"])
    check("prior no-contact block", events[8]["code"] == "NO_LINK_WINDOW" and events[8]["type"] == "action_blocked" and events[8]["action"] == "transmit" and events[8]["step_index"] == 8)
    check("abort event", events[9]["code"] == "MISSION_ABORTED" and events[9]["type"] == "mission_aborted" and equivalent(events[9], bundle["abort_event"]))
    for field: String in ["delta_energy_wh", "delta_stored_data_mb", "delta_returned_data_mb", "delta_observations"]:
        check("zero block/abort " + field, events[8][field] == 0 and events[9][field] == 0)
    for field: String in ["step_index", "energy_wh", "stored_data_mb", "returned_data_mb", "observations_completed"]:
        check("abort preserves " + field, terminal[field] == bundle["pre_abort_state"][field])
    check("recorded step and captures", terminal["step_index"] == 8 and terminal["total_steps"] == 60 and terminal["observations_completed"] == 1)
    check("recorded returned/stored MB", absf(terminal["returned_data_mb"] - 7.7333333328) <= 1e-9 and absf(terminal["stored_data_mb"] - 4.2666666672) <= 1e-9)
    var result: Dictionary = Evaluator.evaluate_mission(config, terminal, events)
    check("evaluator accepts abort", result.get("ok") == true)
    check("native adapter matches", Evaluator.evaluate_hpc_state(terminal) == result)
    var report: Dictionary = result.get("report", {})
    var expected_fields: Array = ["schema_version", "run_id", "mission_id", "run_status", "status", "observations_completed", "required_observations", "returned_data_mb", "required_returned_data_mb", "observation_completion_ratio", "data_return_completion_ratio", "score", "explanation", "root_causes", "next_experiment", "source_ids", "comparison"]
    var actual_fields: Array = report.keys()
    actual_fields.sort()
    expected_fields.sort()
    check("complete report", actual_fields == expected_fields)
    check("failed aborted verdict", report.get("status") == "failed" and report.get("run_status") == "aborted")
    check("null unscored abort", report.get("score", "missing") == null)
    check("report identity", report.get("run_id") == bundle["run_id"] and report.get("mission_id") == bundle["mission_id"])
    check("actuals preserved", report.get("observations_completed") == terminal["observations_completed"] and report.get("returned_data_mb") == terminal["returned_data_mb"])
    check("launch targets preserved", report.get("required_observations") == 4 and report.get("required_returned_data_mb") == 30)
    check("ratios preserved", report.get("observation_completion_ratio") == 0.25 and absf(report.get("data_return_completion_ratio", -1.0) - 0.25777777776) <= 1e-12)
    check("recorded abort explained", str(report.get("explanation")).contains(terminal["terminal_reason"]))
    check("onboard data explained", str(report.get("explanation")).contains("4.2666666672 MB remain onboard"))
    check("abort has neutral cause list", report.get("root_causes") == [])
    check("source/comparison defaults", report.get("source_ids") == [] and report.get("comparison", "missing") == null)
    check("evaluation deterministic", Evaluator.evaluate_mission(config, terminal, events) == result)
    var loaded: Dictionary = Loader.load_catalogs()
    check("pinned KE1 catalogs load", loaded.get("ok") == true)
    if not loaded.get("ok", false):
        finish(result)
        return
    var started: Dictionary = StepEngine.init_validated_run(config, loaded["catalogs"], bundle["run_id"], bundle["mission_id"])
    check("pinned ready launch", started.get("ok") == true)
    if not started.get("ok", false):
        finish(result)
        return
    check("pinned readiness matches", equivalent(started["validation_result"], bundle["readiness"]["validation_result"]))
    var state: Dictionary = started["state"]
    for index: int in range(bundle["trace_actions"].size()):
        var action: Dictionary = bundle["trace_actions"][index]
        check("replay request step %d" % index, state["step_index"] == action["step_index"])
        var reply: Dictionary = StepEngine.request_action(state, action["action"])
        check("replay response %d" % index, equivalent(reply, action["response"]))
        if not reply.get("ok", false):
            finish(result)
            return
        state = reply["state"]
    check("replayed pre-abort state", equivalent(state, bundle["pre_abort_state"]))
    var replayed: Dictionary = StepEngine.abort_run(state, bundle["abort_reason"])
    check("pinned abort response matches", equivalent(replayed, bundle["abort_response"]))
    var replay_result: Dictionary = Evaluator.evaluate_hpc_state(replayed.get("state", {}))
    var replay_report: Dictionary = replay_result.get("report", {}).duplicate(true)
    var supplied_report: Dictionary = report.duplicate(true)
    var replay_explanation: String = str(replay_report.get("explanation"))
    replay_report.erase("explanation")
    supplied_report.erase("explanation")
    check("pinned replay numeric/status fields match", equivalent(replay_report, supplied_report))
    check("pinned replay explanation attributes the operator", replay_explanation.contains(bundle["abort_reason"]))
    check("all supplied inputs preserved", bundle == before)
    finish(result)

func equivalent(actual: Variant, expected: Variant) -> bool:
    if actual is Dictionary and expected is Dictionary:
        if actual.size() != expected.size(): return false
        for key in expected:
            if not actual.has(key) or not equivalent(actual[key], expected[key]): return false
        return true
    if actual is Array and expected is Array:
        if actual.size() != expected.size(): return false
        for index in range(expected.size()):
            if not equivalent(actual[index], expected[index]): return false
        return true
    if (actual is int or actual is float) and (expected is int or expected is float):
        return is_finite(float(actual)) and is_finite(float(expected)) and absf(float(actual) - float(expected)) <= 1e-9
    return typeof(actual) == typeof(expected) and actual == expected

func check(label: String, ok: bool) -> void:
    if ok:
        passed += 1
        print("PASS " + label)
    else:
        failed += 1
        printerr("FAIL " + label)

func finish(result: Dictionary) -> void:
    var checks: FileAccess = FileAccess.open("res://checks-v0.1.json", FileAccess.WRITE)
    checks.store_string(JSON.stringify({"passed": passed, "failed": failed, "scope": "Current KE2 evaluation and full pinned KE1/HPC recorded-action/abort replay", "replay_numeric_absolute_tolerance": 1e-9}, "  ") + "\n")
    if failed == 0:
        var output: FileAccess = FileAccess.open("res://evaluation-v0.1.json", FileAccess.WRITE)
        output.store_string(JSON.stringify(result, "\t", true, true) + "\n")
    print("Operator-abort verification: %d passed, %d failed." % [passed, failed])
    quit(0 if failed == 0 else 1)
