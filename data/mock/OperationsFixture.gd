extends RefCounted
## Local authored playback snapshots, NOT a production RunTrace schema or simulator.
const TOTAL_SECONDS = 5400.0
const PLAYBACK_RATE = 180.0
# type, reference seconds, explanation, battery %, storage %, captured, delivered,
# returned data label, mode, temperature label, downlink label.
const EVENTS = [
	["LAUNCH", 0.0, "Launch sequence started. The selected spacecraft enters this illustrative mission view.", 98, 0, 0, 0, "0 kB", "Launching", "14.8 °C", "0 kbps"],
	["DEPLOY", 720.0, "Solar wings deployed. Prototype subsystems are online.", 94, 2, 0, 0, "0 kB", "Deploying", "15.2 °C", "0 kbps"],
	["OBSERVE", 1902.0, "Imaging window over the selected target regions. Four example observations captured.", 86, 64, 4, 0, "0 kB", "Observing", "15.2 °C", "0 kbps"],
	["TX", 2730.0, "Ground station contact. Three complete observation packets delivered in this sample.", 63, 40, 5, 3, "0.76 GB", "Downlinking", "16.1 °C", "10.0 kbps"],
	["SKIP_POWER", 3960.0, "Example low battery interval: an additional observation opportunity is skipped.", 28, 40, 5, 3, "0.76 GB", "Power conserve", "12.4 °C", "0 kbps"],
	["SLOT_STATE", 5400.0, "Final reference slot reached. Five complete observations delivered; review Run A in Debrief.", 72, 12, 5, 5, "1.24 GB", "Complete", "14.6 °C", "0 kbps"]
]
const TARGET_CAPTURE = [[0, 0], [0, 0], [3, 1], [3, 2], [3, 2], [3, 2]]
const TARGET_DELIVERY = [[0, 0], [0, 0], [0, 0], [2, 1], [2, 1], [3, 2]]
static func time_label(seconds: float) -> String:
	var whole = maxi(0, int(seconds))
	return "%02d:%02d:%02d" % [floori(whole / 3600.0), floori(fmod(whole, 3600) / 60.0), whole % 60]
static func index_at(seconds: float) -> int:
	var index = 0
	for i in EVENTS.size():
		if seconds >= EVENTS[i][1]:
			index = i
	return index
