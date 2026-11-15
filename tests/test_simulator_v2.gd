extends SceneTree

const Adapter = preload("res://core/HPCContractAdapter.gd")
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const Simulator = preload("res://core/MissionSimulator.gd")

func _initialize() -> void:
	var loaded: Dictionary = Runtime.load_game_catalogs()
	assert(loaded.ok)
	var built: Dictionary = Adapter.build_scenario(loaded.catalogs, loaded.catalogs.orbit_catalog)
	assert(built.ok)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/valid_1u_feasible.json"))
	config.schema_version = 2
	config.contract_revision = "v2.0-agreed"
	config.preset_id = "simulator-v2"
	config.preset_revision = 1
	config.mission.objective = "communication"
	config.mission.goal = {"kind": "communication", "required_count": 2}
	config.mission.required_returned_data_mb = 12
	config.mission.duration_orbits = 3
	config.design.radio_id = "radio_fast"
	var first: Dictionary = Simulator.simulate(config, built.scenario)
	var second: Dictionary = Simulator.simulate(config, built.scenario)
	assert(first.ok and second.ok)
	assert(first.schema_version == 2 and first.model_version == "native-v2")
	assert(first.config_snapshot == config and first.scenario_snapshot == built.scenario)
	assert(first.catalog_context == built.scenario)
	assert(first.metrics.goal_type == "communication")
	assert(first.metrics.actual_count == 2)
	assert(first.metrics.evidence_event_ids.size() == 2)
	assert(first == second)
	print("PASS MissionSimulator native v2 replay and evidence")
	quit(0)
