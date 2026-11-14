extends SceneTree

const Simulator = preload("res://core/MissionSimulator.gd")

func _initialize() -> void:
	var catalog_file := FileAccess.open("res://data/fixtures/hpc_catalog.json", FileAccess.READ)
	var fixture_file := FileAccess.open("res://data/fixtures/hpc_golden_radio_ab.json", FileAccess.READ)
	var catalog: Dictionary = JSON.parse_string(catalog_file.get_as_text())
	var fixture: Dictionary = JSON.parse_string(fixture_file.get_as_text())
	var input: Dictionary = fixture.duplicate(true)
	input.erase("expected")
	input.design.radio_id = "radio_upgraded"
	var result: Dictionary = Simulator.simulate(input, catalog)
	if not result.get("ok", false):
		push_error(str(result.get("error", "unknown simulation error")))
		quit(1)
		return
	print(JSON.stringify({"status": result.status, "metrics": result.metrics, "event_count": result.events.size()}, "\t"))
	quit(0)
