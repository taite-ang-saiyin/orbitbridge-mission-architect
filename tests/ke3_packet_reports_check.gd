extends SceneTree
const Results = preload("res://scripts/integration/mission_results.gd")
const Presenter = preload("res://scripts/presentation/DebriefPresentation.gd")
var out: String
var packets: String
var passed: int = 0
var failed: int = 0
var rows: Array = []
func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0]
	packets = OS.get_cmdline_user_args()[1]
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("run")
func read(path: String) -> Variant: return JSON.parse_string(FileAccess.get_file_as_string(path))
func check(value: bool,message: String) -> void:
	rows.append({"pass":value,"check":message})
	if value: passed += 1
	else:
		failed += 1
		print("FAIL ",message)
func settle() -> void:
	for i in 10: await process_frame
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run() -> void:
	var data: Array = []
	for name in ["low_eq_3orbits","return_goal_60mb"]:
		var folder: String = packets.path_join(name)
		var trace: Dictionary = {"config":read(folder.path_join("config.json")),"final_state":read(folder.path_join("final-state.json")),"events":read(folder.path_join("events.json")),"validation":read(folder.path_join("readiness.json"))}
		var reply: Dictionary = read(folder.path_join("evaluation-"+name+".json"))
		var metadata: Dictionary = read(folder.path_join("metadata.json"))
		var hashes: Dictionary = read(folder.path_join("verified-input-hashes.json"))
		var bound: Dictionary = Results.bind_packet(trace,reply,metadata,hashes,name)
		check(bound.ok,name+" report hashes/execution binding accepted")
		check(Results.input_key(trace)==metadata.execution_key,name+" exact producer execution key")
		var evaluated: Dictionary = Results.evaluate_trace(trace.duplicate(true))
		check(JSON.parse_string(JSON.stringify(evaluated))==reply,name+" current KE2 code reproduces unchanged archived reply (JSON numeric normalization)")
		var model: Dictionary = Presenter.build(trace,bound.get("store",{}))
		check(model.state=="report" and model.report==reply.report,name+" supplied report retained byte-value unchanged")
		check(model.report.score==(87 if name=="low_eq_3orbits" else 90),name+" correct supplied score")
		check(model.report.root_causes==[] and model.report.source_ids==[] and model.report.comparison==null,name+" empty causes/sources/null comparison")
		check(reply.report.explanation in model.text and reply.report.next_experiment in model.text,name+" neutral explanation and experiment preserved")
		check("Scope: readiness" in model.credits and "1060" in model.credits and "1330" in model.credits,name+" readiness-scope1060<1330 displayed")
		check(not "Scope: feedback_vocabulary" in model.credits,name+" no invented feedback credit")
		var page = load("res://scenes/screens/DebriefCompare.tscn").instantiate()
		page.theme=preload("res://ui/theme/WorkbenchTheme.gd").build()
		page.state={"evaluation_store":bound.store,"run_history":[trace.duplicate(true)]}
		root.add_child(page)
		root.mode=Window.MODE_WINDOWED
		root.min_size=Vector2i(640,480)
		root.size=Vector2i(1280,720)
		await settle()
		check(page.get_presentation_model().report==reply.report,name+" existing actual Results screen displays this report")
		await capture(name+"-report")
		page.credits_button.pressed.emit()
		await settle()
		await capture(name+"-credits")
		data.append({"name":name,"trace":trace,"reply":reply,"metadata":metadata,"hashes":hashes,"store":bound.store,"model":page.get_presentation_model()})
		page.queue_free()
		await settle()
	for i in 2:
		var own: Dictionary = data[i]
		var other: Dictionary = data[1-i]
		check(not Results.bind_packet(own.trace,other.reply,own.metadata,own.hashes,own.name).ok,own.name+" swapped report rejected despite same IDs")
		check(not Results.bind_packet(own.trace,own.reply,other.metadata,own.hashes,own.name).ok,own.name+" swapped metadata rejected despite same IDs")
		check(not Results.bind_packet(own.trace,other.reply,other.metadata,own.hashes,own.name).ok,own.name+" swapped full bundle rejected")
		var same_ids_store: Dictionary = other.store.duplicate(true)
		check(Presenter.build(own.trace,same_ids_store).state=="stale_report",own.name+" cross-execution store cannot bind same run IDs")
	# The historical leak: matching metadata + rejected report must hide feedback credits.
	var test: Dictionary = data[0]
	var store: Dictionary = test.store.duplicate(true)
	store.history[0].source_credit_metadata.applicable_source_credits.append({"credit_scope":"feedback_vocabulary","title":"TEST must not leak","attribution_text":"TEST feedback","url":"test://only","actual_use":"TEST report cause"})
	check("Scope: feedback_vocabulary" in Presenter.build(test.trace,store).credits,"Accepted test report can display matching supplied feedback scope")
	store.reports.run_001.mission_id="stale-mission"
	var rejected: Dictionary=Presenter.build(test.trace,store)
	check(rejected.state=="stale_report" and not "Scope: feedback_vocabulary" in rejected.credits,"Rejected report cannot leak matching-history feedback credit")
	check("Scope: readiness" in rejected.credits,"Executed readiness credit remains after rejected report")
	var f=FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":rows,"cases":data},"  "))
	print("KE3 ARCHIVED PACKETS: ",passed," passed; ",failed," failed")
	quit(1 if failed else 0)
