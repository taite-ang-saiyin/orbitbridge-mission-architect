extends SceneTree
const Loader = preload("res://scripts/core/mission_capability_draft_loader.gd")
const Draft = preload("res://scripts/core/mission_config_v2_draft_checker.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const V1 = preload("res://scripts/core/mission_validator.gd")
const Steps = preload("res://core/MissionStepEngine.gd")
var passed: int = 0
var failed: int = 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1; printerr("FAIL: " + label)
func read_json(path: String) -> Variant: return JSON.parse_string(FileAccess.get_file_as_string(path))
func run() -> void:
	var loaded: Dictionary = Runtime.load_game_catalogs()
	check(loaded.ok, "Current effective v1 catalogs load")
	if not loaded.ok: quit(1); return
	var catalogs: Dictionary = loaded.catalogs
	var document: Dictionary = read_json(Loader.PATH)
	var registry: Dictionary = read_json("res://data/mission_presets.json")
	var before: String = JSON.stringify([document,catalogs,registry])
	var good: Dictionary = Loader.load_review(catalogs)
	check(good.ok and good.draft_only and not good.ready_to_launch and not good.production_enabled, "Loading draft support cannot authorize launch")
	check(before == JSON.stringify([document,catalogs,registry]), "Loader preserves all supplied catalogs and metadata")
	check(good == Loader.inspect_review(document,catalogs), "File and pure inspection paths agree")
	var old: Dictionary = read_json("res://docs/ke1-expansion/examples/k20-review/parts.proposed.json")
	check(good.checker_context.proposed_instrument_objectives == old.proposed_instrument_objectives, "Draft declaration matches existing reviewed part proposal")
	for preset in registry.presets:
		var review: Dictionary = Draft.check(preset.candidate_config_v2,catalogs,registry,good.checker_context)
		check(review.review_valid and not review.ready_to_launch, "Explicit loader context works for candidate: " + preset.id)
		check(not V1.validate(preset.candidate_config_v2,catalogs).ready_to_launch, "Production v2 rejection remains: " + preset.id)
		check(not Steps.init_validated_run(preset.candidate_config_v2,catalogs,"cap_block_"+preset.id,"test").ok, "Native v2 launch remains blocked: " + preset.id)
	for objective in ["communication","weather_monitoring"]:
		check(not catalogs.objective_ids.has(objective), "No production objective registration: " + objective)
	var copy: Dictionary = Loader.load_review(catalogs)
	copy.document.instruments[0].objective_ids.clear(); copy.checker_context.proposed_instrument_objectives.instrument_basic.clear()
	check(Loader.load_review(catalogs) == good, "Output copies cannot change later loads")
	check(before == JSON.stringify([document,catalogs,registry]), "Repeated calls leave context unchanged")
	var withdrawn: Dictionary = document.duplicate(true)
	withdrawn.instruments[0].objective_ids.erase("communication")
	var support: Dictionary = Loader.inspect_review(withdrawn,catalogs)
	check(support.ok, "Explicit partial capability declaration is allowed")
	var comm: Dictionary = registry.presets[3].candidate_config_v2
	var unsupported: Dictionary = Draft.check(comm,catalogs,registry,support.checker_context)
	var found: bool = false
	for issue in unsupported.errors:
		if issue.code == "INSTRUMENT_OBJECTIVE_UNSUPPORTED": found = true
	check(not unsupported.review_valid and found and not unsupported.ready_to_launch, "Withdrawn capability blocks the draft candidate")
	for value in [null,true,[],"json",4]: check(not Loader.inspect_review(value,catalogs).ok, "Invalid document root fails safely")
	var variants: Array = []
	for key in Loader.FIELDS:
		var bad: Dictionary = document.duplicate(true); bad.erase(key); variants.append(bad)
	for value in [true,null,"1",1.5,NAN,INF]:
		var bad: Dictionary = document.duplicate(true); bad.schema_version = value; variants.append(bad)
	for value in [true,null,[],"approved"]:
		var bad: Dictionary = document.duplicate(true); bad.approval_status = value; variants.append(bad)
	for value in [true,null,0,"false"]:
		var bad: Dictionary = document.duplicate(true); bad.production_enabled = value; variants.append(bad)
	for value in [null,{},[],"instruments"]:
		var bad: Dictionary = document.duplicate(true); bad.instruments = value; variants.append(bad)
	for value in [null,true,[],{}]:
		var bad: Dictionary = document.duplicate(true); bad.instruments[0] = value; variants.append(bad)
	for value in [true,"unknown","bus_basic",[],null]:
		var bad: Dictionary = document.duplicate(true); bad.instruments[0].instrument_id = value; variants.append(bad)
	for value in [true,null,{},"imaging",[false],["unknown"],["imaging","imaging"]]:
		var bad: Dictionary = document.duplicate(true); bad.instruments[0].objective_ids = value; variants.append(bad)
	var bad: Dictionary = document.duplicate(true); bad.instruments.append(bad.instruments[0].duplicate(true)); variants.append(bad)
	bad = document.duplicate(true); bad.extra = true; variants.append(bad)
	bad = document.duplicate(true); bad.instruments[0].mass_g = 0; variants.append(bad)
	bad = document.duplicate(true); bad.instruments[0].assumption_id = "unlabelled"; variants.append(bad)
	for index in variants.size():
		var reply: Dictionary = Loader.inspect_review(variants[index],catalogs)
		check(not reply.ok and not reply.ready_to_launch and not reply.production_enabled and reply.document.is_empty() and reply.checker_context.is_empty() and not reply.errors.is_empty(), "Malformed/spoofed declaration fails closed: " + str(index))
	for value in [null,true,[],{},"catalogs"]: check(not Loader.inspect_review(document,value).ok, "Invalid catalog context rejected")
	check(not Loader.load_review(catalogs,"res://data/missing-capability-file.json").ok, "Missing explicit file rejected")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		DirAccess.make_dir_recursive_absolute(args[0])
		var invalid_path: String = args[0].path_join("malformed-capability.json")
		var file = FileAccess.open(invalid_path,FileAccess.WRITE)
		if file != null:
			file.store_string("{not-json"); file.close()
			check(not Loader.load_review(catalogs,invalid_path).ok, "Invalid JSON rejected without partial context")
		else: check(false,"Test fixture file writable")
		var evidence = FileAccess.open(args[0].path_join("capability-loader-check.json"),FileAccess.WRITE)
		if evidence != null: evidence.store_string(JSON.stringify({"passed":passed,"failed":failed,"draft_only":true,"production_enabled":false,"loaded_context":good.checker_context},"  ")); evidence.close()
		else: check(false,"Evidence output writable")
	print("Draft capability loader: %d checks passed; %d failed." % [passed,failed])
	quit(0 if failed==0 else 1)
