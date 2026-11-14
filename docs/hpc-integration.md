# HPC integration handoff

HPC owns `core/HPCContractAdapter.gd`, `core/MissionStepEngine.gd`, `core/OrbitPlanner.gd`, and `data/orbits.json`. The step engine accepts the agreed MissionConfig and a scenario snapshot. KE1's `CatalogLoader.load_catalogs()` bundle needs the HPC orbit data combined with it before starting a run.

```gdscript
const Adapter = preload("res://core/HPCContractAdapter.gd")
const StepEngine = preload("res://core/MissionStepEngine.gd")

var ke1_result: Dictionary = CatalogLoader.load_catalogs()
if not ke1_result.ok:
    # Show KE1 catalog errors.
    return
var orbit_file := FileAccess.open("res://data/orbits.json", FileAccess.READ)
var orbit_data: Dictionary = JSON.parse_string(orbit_file.get_as_text())
var built: Dictionary = Adapter.build_scenario(ke1_result.catalogs, orbit_data)
if not built.ok:
    # Show built.error_code and built.error_message.
    return
# Start only after KE1 validates this config with ready_to_launch == true.
var started: Dictionary = StepEngine.init_run(config, built.scenario, run_id, mission_id)
```

`build_scenario` maps KE1's component `category` and power/data names to HPC's internal snapshot, and checks that HPC orbit and target IDs appear in KE1's reference ID lists. It does not alter KE1 files. The snapshot retains KE1's launch profiles and launchers and HPC's authored windows. `init_run` uses `battery.initial_charge_fraction`, defaulting to 1 for legacy fixtures. Its returned state and events follow Team Contract v1. Call `get_available_actions(state)` and `request_action(state, action)` for each step. For an operator abort, call `MissionStepEngine.abort_run(state, reason)`: it returns a finished state with `run_status: "aborted"`, preserves the current step and resource totals, records `terminal_reason`, and emits a `mission_aborted` event for downstream evaluation and UI display.

| Orbit ID | Target ID | Local observation steps per orbit | Local contact steps per orbit | Step hours |
| --- | --- | --- | --- | ---: |
| `low_eq` | `equator` | 2, 5 | 8 | 0.1538888889 |
| `high_inc` | `equator` | 1, 6 | 0, 7 | 0.1611111111 |

The windows are deterministic gameplay presets, not physical coverage predictions. KE1 should mark the `equator` target suitable for both orbit IDs if its readiness validator checks orbit-to-target suitability. SE should pass the selected orbit ID and config unchanged. KE3 should render `available_actions`, state, and emitted events without recomputing windows.

Current HPC tests use selected KE1 catalog rows and IDs from KE1 commit `15385a4` because KE1's catalog files are not yet in this local branch. They do not prove compatibility with the full current KE1 files or KE1's final readiness result. Run an end-to-end check with those files after they are integrated. At K05-K06, KE1's validator still reports `ready_to_launch=false` with metrics unavailable; KE1 must complete launch readiness before SE can launch through the gate.
