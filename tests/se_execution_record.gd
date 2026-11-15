extends SceneTree
const Record = preload("res://scripts/integration/execution_record.gd")
const Contract = preload("res://scripts/integration/report_contract.gd")
var checks = 0
var failed = 0
func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		push_error("FAIL: " + label)
		failed += 1

func _initialize() -> void:
	var config = {"schema_version":1,"mission":{"objective":"imaging"}}
	var final = {"run_id":"transport_fixture","mission_id":"fixture","config_snapshot":config,"event_log":[],"counts":[1]}
	var trace = {"config":config,"final_state":final,"events":[],"validation":{"config":config}}
	var key_bytes: String = JSON.stringify(Record.input_values(trace), "", true, true)
	var packet = {"execution_key":key_bytes.sha256_text(),"run_id":final.run_id,"mission_id":final.mission_id,"trace":trace,"evaluation":{"ok":false,"error":{"code":"TEST_FIXTURE"}},"result_context":{}}
	var encoded: Dictionary = Record.encode(packet)
	if not encoded.ok: printerr(encoded)
	expect(encoded.ok, "Encode typed original")
	if not encoded.ok: quit(1); return
	var reloaded: Dictionary = JSON.parse_string(JSON.stringify(encoded.record, "", true, true))
	expect(Record.verify(reloaded).ok, "Portable digest survives JSON reload")
	expect(JSON.stringify([1], "", true, true) != JSON.stringify(JSON.parse_string("[1]"), "", true, true), "Reproduce int/float representation change")
	expect(reloaded.execution_key == packet.execution_key, "Original identity retained")
	var view: Dictionary = JSON.parse_string(JSON.stringify(packet, "", true, true))
	expect(not Record.encode(view).ok, "Missing historical bytes never silently rekey")
	expect(Record.encode(view, key_bytes).ok, "Existing record plus verified bytes is compatible")
	var mutated = reloaded.duplicate(true)
	mutated.trace.final_state.counts = [2]
	expect(not Record.verify(mutated).ok, "Decoded evidence tampering rejected")
	mutated = reloaded.duplicate(true)
	mutated.content_digest = "changed"
	expect(not Record.verify(mutated).ok, "Digest tampering rejected")
	mutated = reloaded.duplicate(true)
	mutated.extra_metadata = "not covered by retained bytes"
	expect(not Record.verify(mutated).ok, "Additional metadata cannot escape digest scope")
	expect(not Record.content_fields(encoded.record).has("content_digest") and not Record.content_fields(encoded.record).has("content_preimage_utf8"), "Self digest and its preimage excluded")
	mutated = packet.duplicate(true)
	mutated.trace.final_state.invalid = NAN
	expect(not Record.encode(mutated).ok, "Nonfinite inputs rejected")
	mutated = packet.duplicate(true)
	mutated.trace.final_state.invalid = 9007199254740992
	expect(not Record.encode(mutated).ok, "Unsafe integer transport rejected")
	expect(Contract.output_format(config).schema_version == 1, "Legacy Imaging report stays v1")
	config.schema_version = 2
	expect(Contract.output_format(config).schema_version == 1, "Config version alone never selects report v2")
	config.mission.goal = {"kind":"imaging"}
	expect(Contract.output_format(config).schema_version == 2, "Goal-bearing Imaging requires expanded report")
	for objective in ["survey", "communication", "weather_monitoring"]:
		var format: Dictionary = Contract.output_format({"schema_version":1,"mission":{"objective":objective}})
		expect(format.schema_version == 2 and format.contract_revision == Contract.GOALS_REVISION, "Expanded semantics choose v2 independently: " + objective)
	expect(not Contract.output_format({"mission":{"objective":"unknown"}}).ok, "Unknown objective is never legacy fallback")
	var args = OS.get_cmdline_user_args()
	if "--historical-evidence" in args:
		var folder: String = args[args.find("--historical-evidence") + 1]
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("ke2-handoff-current.json")))
		var bindings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("execution-key-preimages-review.json")))
		expect(source.cases.size() == 8, "All eight historical cases supplied")
		for name in source.cases:
			var item: Dictionary = source.cases[name]
			var historical: Dictionary = {"execution_key":item.execution_key,"trace":item.trace,"run_id":item.trace.final_state.run_id,"mission_id":item.trace.final_state.mission_id,"evaluation":item.evaluation,"result_context":{}}
			var portable: Dictionary = Record.encode(historical, bindings.cases[name].preimage_utf8)
			if not portable.ok: printerr(portable)
			expect(portable.ok, "Historical key preimage preserved: " + name)
			if not portable.ok: continue
			expect(Record.verify(JSON.parse_string(JSON.stringify(portable.record, "", true, true))).ok, "Historical JSON record reload: " + name)
	print("SE execution records: ",checks - failed," checks passed; ",failed," failed")
	quit(0 if failed == 0 else 1)
