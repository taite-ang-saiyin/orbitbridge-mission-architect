extends RefCounted
## Fixed presentation report. Never evaluates feasibility, resources or flight safety.
const CHECKS = [
	["mission", "Mission Configuration", "PASS", "Objective, targets, duration and budget set.", "Review the mission selections below. This PASS is part of the fixed prototype report; no mission requirements have been evaluated."],
	["payload", "Payload & Instruments", "PASS", "Selected instrument configured.", "The selected payload is shown for review. Instrument compatibility is not evaluated by this prototype."],
	["resources", "Resource Balance", "PASS", "Mass, power and storage within example limits.", "The gauges show authored specifications and illustrative limits. No resource balance has been calculated."],
	["coverage", "Orbit & Coverage", "WARNING", "Limited coverage in the reference window sample.", "This report always includes one example coverage warning. The coverage strip is a fixed six-orbit sample and is not recalculated for the mission duration."],
	["launcher", "Launcher Compatibility", "PASS", "Launcher and orbit preset selected.", "The selected launcher and orbit are displayed for review. Payload capacity and orbital delivery are not evaluated."],
	["policy", "Operations Policy", "PASS", "Operating policy configured.", "The selected policy is carried forward into the prototype mission state. Scheduling and simulation remain mocked."]
]
const GAUGES = {"mass": [0.79, "≤ 150 kg"], "power": [0.83, "≤ 60 W"], "storage": [0.50, "≤ 64 GB"]}
const BUS_GAUGES = {"BUS-S1 (Small)": {"mass": 0.79, "power": 0.83}, "BUS-M2 (Medium)": {"mass": 0.91, "power": 0.97}}
const STORAGE_GAUGES = {"STO-32 (32 GB)": 0.50, "STO-64 (64 GB)": 1.0}
const ORBIT_NOTES = {
	"LEO – 400 km": "Period: 92.4 min\nInclination: 98.7°",
	"LEO – 500 km": "Period: 94.6 min\nInclination: 97.4°",
	"Polar – 600 km": "Period: 96.7 min\nInclination: 90.0°"
}
# Authored six-orbit reference slots, not derived orbital windows.
const SLOT_SAMPLES = [[0, 2, 4], [0, 3, 5]]
