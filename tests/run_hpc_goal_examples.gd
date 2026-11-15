extends SceneTree
## Reproducible owner evidence, not a new objective implementation or evaluator.
const StepEngine = preload("res://core/MissionStepEngine.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const INPUT_PATH = "res://tests/fixtures/hpc_goal_examples_v1.json"
const SOURCE_PATH = "res://tests/fixtures/hpc_goal_source_v1.json"
const SAMPLING_ID = "initial_and_each_accepted_poststep_v1_proposal"
const SOURCE_COMMIT = "dce75db845f6c494b8c25c9028dd9c0648aabd91"
var _checks: int = 0
var _failed: int = 0
var _output_dir: String = "res://docs/handoffs/hpc-goal-evidence-v1"

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var output_arg: int = args.find("--output-dir")
	if output_arg >= 0:
		if not _check(output_arg + 1 < args.size(), "--output-dir requires a path"):
			quit(1)
			return
		_output_dir = args[output_arg + 1]
	var inputs: Dictionary = _read(INPUT_PATH)
	var source: Dictionary = _read(SOURCE_PATH)
	if inputs.is_empty() or source.is_empty():
		quit(1)
		return
	_check(inputs.source_commit_sha == SOURCE_COMMIT and source.source_commit_sha == SOURCE_COMMIT, "source revision is explicitly pinned")
	for path in source.sha256:
		_check(FileAccess.get_sha256("res://" + path) == source.sha256[path], "pinned source bytes: " + path)
	if _failed > 0:
		quit(1)
		return
	var catalog_result: Dictionary = Runtime.load_game_catalogs()
	if not _check(catalog_result.get("ok", false), "current application catalogs load"):
		quit(1)
		return
	var payloads: Array[Dictionary] = []
	for spec in inputs.cases:
		var payload: Dictionary
		if args.has("--verify-only"):
			payload = _read(_output_dir.path_join(str(spec.id) + ".json"))
		else:
			payload = _run(spec, inputs, source, catalog_result.catalogs)
		if payload.is_empty():
			quit(1)
			return
		_verify(payload, spec)
		_replay(payload)
		payloads.append(payload)
	if _failed > 0:
		quit(1)
		return
	var entries: Array[Dictionary] = []
	if not args.has("--verify-only"):
		if not _check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir)) == OK, "create evidence output folder"):
			quit(1)
			return
	for payload in payloads:
		var file_name: String = str(payload.example_id) + ".json"
		var path: String = _output_dir.path_join(file_name)
		if not args.has("--verify-only") and not _write(path, payload):
			quit(1)
			return
		entries.append({"file": file_name, "sha256": FileAccess.get_sha256(path), "example_id": payload.example_id,
			"goal_type": payload.goal_type, "mechanics_proxy": payload.mechanics_proxy,
			"run_id": payload.run_id, "scenario_id": payload.scenario_id,
			"goal_measurements": payload.goal_measurements, "resource_extrema": payload.resource_extrema})
	if args.has("--verify-only"):
		var manifest: Dictionary = _read(_output_dir.path_join("manifest.json"))
		_check(_same(manifest.get("examples", []), entries), "all bundle hashes and manifest summaries match")
	else:
		_write(_output_dir.path_join("manifest.json"), {
			"bundle_revision": inputs.bundle_revision, "source": payloads[0].source,
			"resource_sampling_id": SAMPLING_ID, "examples": entries,
			"verification": {"engine_version": Engine.get_version_info().string,
				"native_replays": payloads.size(), "checks_passed": _checks, "failed": _failed,
				"generation_command": "godot --headless --path . --script tests/run_hpc_goal_examples.gd",
				"verification_command": "godot --headless --path . --script tests/run_hpc_goal_examples.gd -- --verify-only"},
			"limits": ["Communication/Weather use explicitly labeled schema-1 Imaging mechanics proxies; config-v2 production acceptance remains pending.",
				"No expanded-objective report, score, execution-binding key or physical coverage claim is fabricated.",
				"Preset labels describe source setup; edited radio/action variants are explicit in inputs and snapshots."]})
	print("HPC goal evidence: %d examples, %d checks passed, %d failed; %s" % [payloads.size(), _checks - _failed, _failed, _output_dir])
	quit(0 if _failed == 0 else 1)

func _run(spec: Dictionary, inputs: Dictionary, source: Dictionary, catalogs: Dictionary) -> Dictionary:
	var config: Dictionary = inputs.native_config_template.duplicate(true)
	config.mission.title = spec.id
	config.mission.objective = spec.native_objective
	config.mission.target_region = spec.targets[0]
	config.mission.target_regions = spec.targets.duplicate(true)
	config.mission.required_observations = spec.capture_quota
	config.mission.required_returned_data_mb = spec.required_returned_data_mb
	config.mission.duration_orbits = spec.duration_orbits
	config.design.orbit_id = spec.orbit_id
	config.design.radio_id = spec.radio_id
	var run_id: String = "run_hpc_goals_v1_" + str(spec.id)
	var mission_id: String = "mission_hpc_goals_v1_" + str(spec.preset_id if spec.preset_id != null else "survey_two_targets")
	var started: Dictionary = StepEngine.init_validated_run(config, catalogs, run_id, mission_id)
	if not _check(started.get("ok", false), "%s readiness: %s" % [spec.id, started.get("error", {})]):
		return {}
	var state: Dictionary = started.state
	var initial_state: Dictionary = state.duplicate(true)
	var resource_samples: Array = [_sample(state, -1, [], "initial")]
	var request_frames: Array = []
	var requests: Array = []
	# JSON numbers load as floats. Array.has uses typed equality, so normalize
	# authored whole-step inputs explicitly before comparing to native int steps.
	var observe_steps: Array = spec.observe_steps.map(func(value): return int(value))
	var transmit_steps: Array = spec.transmit_steps.map(func(value): return int(value))
	for step in int(state.total_steps):
		_check(int(state.step_index) == step, "requested pre-action step")
		_check(not (observe_steps.has(step) and transmit_steps.has(step)), "action inputs have no overlapping requests")
		var action: String = "observe" if observe_steps.has(step) else ("transmit" if transmit_steps.has(step) else "power_save")
		var result: Dictionary = StepEngine.request_action(state, action)
		if not _check(result.get("ok", false), "native request succeeds: " + str(spec.id)):
			return {}
		_record_request(result, action, step, requests, request_frames, resource_samples)
		state = result.state
		if not result.allowed:
			_check(result.events[0].code in ["NO_DATA", "NO_LINK_WINDOW"], "only explicitly permitted no-data/no-contact blocks")
			var fallback: Dictionary = StepEngine.request_action(state, "power_save")
			if not _check(fallback.get("ok", false) and fallback.get("allowed", false), "power-save fallback advances blocked step"):
				return {}
			_record_request(fallback, "power_save", step, requests, request_frames, resource_samples)
			state = fallback.state
	var proxy: bool = spec.goal_type in ["communication_contacts", "weather_revisit"]
	return {
		"schema_version": 1, "bundle_revision": inputs.bundle_revision, "example_id": spec.id,
		"goal_type": spec.goal_type, "preset_id": spec.preset_id, "mechanics_proxy": proxy,
		"scope": "Native Imaging mechanics only; not a Communication/Weather launch or scoring approval." if proxy else "Native objective evidence; scoring remains KE2-owned.",
		"source": {"repository": "taite-ang-saiyin/orbitbridge-mission-architect", "source_commit_sha": SOURCE_COMMIT,
			"native_source_sha256": source.sha256.duplicate(true),
			"generator_revision": inputs.bundle_revision, "generator_path": "tests/run_hpc_goal_examples.gd",
			"generator_sha256": FileAccess.get_sha256("res://tests/run_hpc_goal_examples.gd"),
			"inputs_sha256": FileAccess.get_sha256(INPUT_PATH), "source_manifest_sha256": FileAccess.get_sha256(SOURCE_PATH)},
		"run_id": run_id, "mission_id": mission_id, "scenario_id": state.scenario_id,
		"scenario_version": str(state.scenario_snapshot.scenario_version),
		"units": {"energy": "Wh", "data": "decimal MB", "time": "hours", "orbit_index": "zero_based"},
		"example_inputs": spec.duplicate(true), "launch_config": config,
		"catalogs_snapshot": catalogs.duplicate(true), "scenario_snapshot": state.scenario_snapshot.duplicate(true),
		"readiness": started.validation_result, "initial_state": initial_state, "final_state": state,
		"ordered_events": state.event_log.duplicate(true), "requested_actions": requests,
		"action_plan": {"id": "hpc_goal_explicit_steps_v1", "version": 1, "observe_steps": spec.observe_steps,
			"transmit_steps": spec.transmit_steps, "default_action": "power_save", "blocked_fallback": "power_save"},
		"request_frames": request_frames, "resource_samples": resource_samples, "resource_sampling_id": SAMPLING_ID,
		"goal_measurements": _measure(state), "resource_extrema": _extrema(resource_samples, state.battery_capacity_wh),
		"expanded_objective_score": null
	}

func _record_request(result: Dictionary, action: String, step: int, requests: Array, frames: Array, samples: Array) -> void:
	var ids: Array = []
	for event in result.events: ids.append(event.event_id)
	var index: int = requests.size()
	requests.append({"request_index": index, "step_index": step, "action": action, "allowed": bool(result.allowed), "event_ids": ids})
	var sample: Dictionary = _sample(result.state, index, ids, "accepted_poststep" if result.allowed else "blocked_postrequest")
	frames.append(sample)
	if result.allowed: samples.append(sample.duplicate(true))

func _sample(state: Dictionary, request_index: int, event_ids: Array, kind: String) -> Dictionary:
	return {"kind": kind, "request_index": request_index, "event_ids": event_ids.duplicate(),
		"run_id": state.run_id, "mission_id": state.mission_id, "step_index": state.step_index,
		"phase": state.phase, "run_status": state.run_status,
		"energy_wh": state.energy_wh, "battery_capacity_wh": state.battery_capacity_wh,
		"stored_data_mb": state.stored_data_mb, "storage_capacity_mb": state.storage_capacity_mb,
		"returned_data_mb": state.returned_data_mb, "observations_completed": state.observations_completed,
		"observations_by_target": state.observations_by_target.duplicate(true),
		"returned_data_by_target_mb": state.returned_data_by_target_mb.duplicate(true),
		"observations_delivered_by_target": state.observations_delivered_by_target.duplicate(true),
		"data_packets": state.data_packets.duplicate(true)}

func _measure(state: Dictionary) -> Dictionary:
	var selected: Array = state.config_snapshot.mission.target_regions
	var steps_per_orbit: int = 0
	for orbit in state.scenario_snapshot.orbits:
		if orbit.id == state.scenario_id: steps_per_orbit = int(orbit.steps_per_orbit)
	var positive_steps: Array = []
	var positive_ids: Array = []
	var observed: Dictionary = {}
	var observed_ids: Dictionary = {}
	var deliveries: Dictionary = {}
	var delivered_targets: int = 0
	for target in selected:
		observed[target] = []
		observed_ids[target] = []
		deliveries[target] = int(state.observations_delivered_by_target.get(target, 0))
		if deliveries[target] >= 1: delivered_targets += 1
	for event in state.event_log:
		if event.type != "action_accepted": continue
		if event.action == "transmit" and float(event.delta_returned_data_mb) > 0.0:
			if not positive_steps.has(int(event.step_index)):
				positive_steps.append(int(event.step_index))
				positive_ids.append(event.event_id)
		if event.action == "observe" and int(event.delta_observations) > 0 and observed.has(event.target_id):
			var orbit_index: int = floori(float(event.step_index) / float(steps_per_orbit))
			if not observed[event.target_id].has(orbit_index):
				observed[event.target_id].append(orbit_index)
				observed_ids[event.target_id].append(event.event_id)
	return {"observations_completed": state.observations_completed, "returned_data_mb": state.returned_data_mb,
		"complete_deliveries_by_selected_target": deliveries, "selected_targets_delivered": delivered_targets,
		"positive_transmit_steps": positive_steps.size(), "positive_transmit_step_indices": positive_steps,
		"positive_transmit_evidence_event_ids": positive_ids,
		"observed_orbit_indices_by_target": observed, "observed_orbit_evidence_event_ids_by_target": observed_ids,
		"selected_target_revolution_visits": observed[selected[0]].size(), "steps_per_orbit": steps_per_orbit}

func _extrema(samples: Array, capacity: float) -> Dictionary:
	var minimum: float = INF
	var maximum: float = -INF
	var peak: float = -INF
	var low_storage: float = INF
	for sample in samples:
		minimum = minf(minimum, float(sample.energy_wh))
		maximum = maxf(maximum, float(sample.energy_wh))
		peak = maxf(peak, float(sample.stored_data_mb))
		low_storage = minf(low_storage, float(sample.stored_data_mb))
	return {"lowest_battery_wh": minimum, "highest_battery_wh": maximum,
		"lowest_battery_percent": 100.0 * minimum / capacity,
		"highest_storage_mb": peak, "lowest_storage_mb": low_storage, "sample_count": samples.size()}

func _verify(payload: Dictionary, spec: Dictionary) -> void:
	var state: Dictionary = payload.final_state
	_check(payload.source.source_commit_sha == SOURCE_COMMIT, "bundle pins native producer revision")
	_check(payload.source.generator_sha256 == FileAccess.get_sha256("res://tests/run_hpc_goal_examples.gd") and payload.source.inputs_sha256 == FileAccess.get_sha256(INPUT_PATH), "evidence generator and authored inputs match recorded hashes")
	_check(payload.readiness.ready_to_launch and state.phase == "finished" and state.run_status == "completed" and int(state.step_index) == int(state.total_steps), "validated completed native run")
	_check(state.config_snapshot == payload.launch_config and state.scenario_snapshot == payload.scenario_snapshot, "immutable input snapshots retained")
	_check(state.event_log == payload.ordered_events, "full native event log retained without enrichment")
	_check(payload.resource_samples.size() == int(state.total_steps) + 1, "initial plus every accepted poststep including terminal")
	_check(payload.request_frames.size() == payload.requested_actions.size(), "every request has a packet/resource frame")
	var captured: int = 0
	var returned_mb: float = 0.0
	var previous_step: int = -1
	for i in payload.ordered_events.size():
		var event: Dictionary = payload.ordered_events[i]
		_check(event.event_id == "evt_%03d" % i and event.run_id == state.run_id and event.mission_id == state.mission_id and int(event.step_index) >= previous_step, "native ordered same-run event identity")
		previous_step = int(event.step_index)
		if event.type == "action_accepted":
			captured += int(event.delta_observations)
			returned_mb += float(event.delta_returned_data_mb)
			if event.action == "transmit": _check(_close(event.data_transmitted_mb, event.delta_returned_data_mb), "canonical returned-MB delta agrees with transmitted MB within floating-point tolerance")
	_check(captured == int(state.observations_completed) and _close(returned_mb, state.returned_data_mb), "native accepted events reconcile capture and return totals")
	var packet_mb: float = float(payload.readiness.metrics.data_per_observation_mb)
	for frame in [payload.initial_state] + payload.request_frames:
		_check(float(frame.energy_wh) >= 0.0 and float(frame.energy_wh) <= float(frame.battery_capacity_wh) and float(frame.stored_data_mb) >= 0.0 and float(frame.stored_data_mb) <= float(frame.storage_capacity_mb), "post-clamp resources within bounds")
		var queued_mb: float = 0.0
		var remaining_by_target: Dictionary = {}
		for packet in frame.data_packets:
			queued_mb += float(packet.remaining_mb)
			remaining_by_target[packet.target_id] = float(remaining_by_target.get(packet.target_id, 0.0)) + float(packet.remaining_mb)
		_check(_close(queued_mb, frame.stored_data_mb) and _close(float(frame.observations_completed) * packet_mb, float(frame.returned_data_mb) + float(frame.stored_data_mb)), "packet and aggregate data conservation")
		var total_by_target: float = 0.0
		for target in spec.targets:
			var received: float = float(frame.returned_data_by_target_mb.get(target, 0.0))
			total_by_target += received
			_check(_close(float(frame.observations_by_target.get(target, 0)) * packet_mb, received + float(remaining_by_target.get(target, 0.0))), "per-target returned and pending MB reconcile")
			_check(int(frame.observations_delivered_by_target.get(target, 0)) <= int(frame.observations_by_target.get(target, 0)), "complete deliveries never exceed captures")
		_check(_close(total_by_target, frame.returned_data_mb), "per-target returns sum to native total")
	var measures: Dictionary = payload.goal_measurements
	_check(measures.observations_completed == spec.expected.observations_completed and _close(measures.returned_data_mb, spec.expected.returned_data_mb), "independent expected capture and MB result: " + str(spec.id))
	_check(measures.positive_transmit_steps == spec.expected.positive_transmit_steps and _same(measures.complete_deliveries_by_selected_target, spec.expected.complete_deliveries), "expected positive steps and complete deliveries: " + str(spec.id))
	if spec.expected.has("observed_orbit_indices"):
		_check(_same(measures.observed_orbit_indices_by_target[spec.targets[0]], spec.expected.observed_orbit_indices), "expected distinct selected-region revolutions: " + str(spec.id))
	for step in spec.expected.get("blocked_steps", {}):
		var matched: bool = false
		for event in payload.ordered_events:
			if event.type == "action_blocked" and int(event.step_index) == int(step) and event.code == spec.expected.blocked_steps[step]: matched = true
		_check(matched, "requested blocked-action evidence exists")
	_check(_same(_measure(state), measures) and _same(_extrema(payload.resource_samples, float(state.battery_capacity_wh)), payload.resource_extrema), "recomputed measures and sample extrema match")

func _replay(payload: Dictionary) -> void:
	var started: Dictionary = StepEngine.init_run(payload.launch_config, payload.scenario_snapshot, payload.run_id, payload.mission_id)
	if not _check(started.get("ok", false), "replay initializes from retained scenario/config"):
		return
	var state: Dictionary = started.state
	_check(_same(state, payload.initial_state), "replay matches native initial state")
	for index in payload.requested_actions.size():
		var request: Dictionary = payload.requested_actions[index]
		_check(state.step_index == request.step_index, "replay uses exact pre-action step")
		var before: Dictionary = state.duplicate(true)
		var preview: Dictionary = StepEngine.predict_next_step(state, request.action)
		var result: Dictionary = StepEngine.request_action(state, request.action)
		if not _check(result.get("ok", false) and result.get("allowed") == request.allowed, "replay native decision"):
			return
		_check(state == before and preview.get("ok", false), "preview/execution preserve their input state")
		var actual_ids: Array = []
		for event in result.events: actual_ids.append(event.event_id)
		_check(_same(actual_ids, request.event_ids), "request-to-event evidence association matches replay")
		for field in ["energy_wh", "stored_data_mb", "returned_data_mb", "observations_completed"]:
			_check(preview.prediction[field + "_after"] == result.state[field], "native prediction parity in replay")
			if not result.allowed: _check(before[field] == result.state[field], "blocked request preserves native resource/capture counter")
		state = result.state
		_check(_same(_sample(state, index, request.event_ids, "accepted_poststep" if request.allowed else "blocked_postrequest"), payload.request_frames[index]), "replay matches retained resource and packet sample")
	_check(_same(state, payload.final_state), "exact replay matches native terminal state and event log")

func _close(a: float, b: float) -> bool:
	return absf(a - b) <= 0.0000001

func _same(a: Variant, b: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(a, "", true, true)) == JSON.parse_string(JSON.stringify(b, "", true, true))

func _check(condition: bool, label: String) -> bool:
	_checks += 1
	if not condition:
		_failed += 1
		push_error("TEST FAILURE: " + label)
	return condition

func _read(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not _check(file != null, "read " + path): return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	if not _check(value is Dictionary, "JSON object in " + path): return {}
	return value

func _write(path: String, value: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not _check(file != null, "write " + path): return false
	file.store_string(JSON.stringify(value, "\t", true, true) + "\n")
	var ok: bool = file.get_error() == OK
	file.close()
	return _check(ok, "complete output write " + path)
