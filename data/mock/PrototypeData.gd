extends RefCounted
# Illustrative fixtures only. Not production RunTrace or evaluator schemas.
const RUNS = {
	"Run A": {"captured": 5, "delivered": 5, "data": "1.24 GB", "outcome": "MET", "battery": "28% min", "storage": "64% peak"},
	"Run B": {"captured": 4, "delivered": 4, "data": "0.96 GB", "outcome": "PARTIAL", "battery": "46% min", "storage": "58% peak"}
}
const COMPONENTS = {"Balanced bus": ["42 kg", "68 cr", "80 W", "64 MB"], "Imaging bus": ["56 kg", "92 cr", "110 W", "128 MB"], "Relay bus": ["38 kg", "74 cr", "95 W", "96 MB"]}
