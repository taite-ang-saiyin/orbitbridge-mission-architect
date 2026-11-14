# HPC integration handoff

HPC owns `core/HPCContractAdapter.gd`, `core/MissionStepEngine.gd`, `core/OrbitPlanner.gd`, and `data/orbits.json`. The step engine accepts the agreed MissionConfig and a scenario snapshot. KE1's `CatalogLoader.load_catalogs()` bundle needs the HPC orbit data combined with it before starting a run.

```gdscript
const Adapter = preload("res://core/HPCContractAdapter.gd")
const StepEngine = preload("res://core/MissionStepEngine.gd")
const CatalogLoader = preload("res://scripts/core/catalog_loader.gd")

var ke1_result: Dictionary = CatalogLoader.load_catalogs()
if not ke1_result.ok:
    # Show KE1 catalog errors.
    return
# This re-runs KE1 readiness against this exact config/catalog snapshot,
# combines KE1's orbit_catalog with the component catalogs, then starts HPC.
var started: Dictionary = StepEngine.init_validated_run(
    config, ke1_result.catalogs, run_id, mission_id)
if not started.ok:
    # Show started.error and, when present, started.validation_result.
    return
```

`init_validated_run` invokes KE1's actual `MissionValidator.validate` and refuses to start unless `ready_to_launch` is true. It reads HPC's unchanged orbit metadata from `ke1_result.catalogs.orbit_catalog`, maps KE1 component categories and field names into an immutable HPC snapshot, and carries the complete ValidationResult in the success response. `init_run` remains the lower-level v1 API for explicit scenario snapshots and isolated tests. KE1's catalog files and validator are dependencies; this checkout includes their current `origin/ke1` versions unchanged for a runnable integration.

The step engine uses `battery.initial_charge_fraction`, defaults to 1 only for legacy catalogs, and exposes state and events in Team Contract v1 units. Call `get_available_actions(state)` and `request_action(state, action)` for each step. For an operator abort, call `MissionStepEngine.abort_run(state, reason)`: it returns a finished state with `run_status: "aborted"`, preserves the current step and resource totals, records `terminal_reason`, and emits a `mission_aborted` event for downstream evaluation and UI display.

| Orbit ID | Target ID | Local observation steps per orbit | Local contact steps per orbit | Step hours |
| --- | --- | --- | --- | ---: |
| `low_eq` | `equator` | 2, 5 | 8 | 0.1538888889 |
| `high_inc` | `equator` | 1, 6 | 0, 7 | 0.1611111111 |

The windows are deterministic gameplay presets, not physical coverage predictions. KE1's readiness check uses these HPC `target_windows` to determine target/orbit suitability; current integration tests pass for `equator` with both orbit IDs and block a target whose window is removed. SE should pass the selected orbit ID and config unchanged. KE3 should render `available_actions`, state, and emitted events without recomputing windows.

## Legacy whole-run trace boundary

`MissionSimulator.simulate()` remains the legacy fixed-slot API and continues to report its native `RunTrace` values in watt-seconds (`battery_ws`) and kilobytes (`*_kb`). For consumers that need a normalized summary, call the explicit `LegacyTraceAdapter` after the legacy run:

```gdscript
const LegacySimulator = preload("res://core/MissionSimulator.gd")
const LegacyTraceAdapter = preload("res://core/LegacyTraceAdapter.gd")

var legacy_result: Dictionary = LegacySimulator.simulate(run_input, catalog)
var normalized: Dictionary = LegacyTraceAdapter.to_v1_units(legacy_result)
if normalized.ok:
    print(normalized.metrics.energy_wh)
    print(normalized.metrics.returned_data_mb)
```

The adapter converts energy with `Wh = Ws / 3600` and data with decimal `MB = KB / 1000`. Its summary and telemetry use Wh and decimal MB field names. Raw legacy events are retained under `legacy_events` with `legacy_event_schema: "seq_slot_t_s_code_params"`; their parameter payloads still contain legacy units, so they are not Team Contract v1 `Event` records and must not be sent to v1 event consumers as such. The result is explicitly tagged `compatibility_kind: "legacy_trace_summary"` and is not a v1 `MissionState`. Use `MissionStepEngine` for authoritative v1 state, action, and event behavior. The adapter is an output conversion; it does not reinterpret legacy `RunInput` fields or rates.

The HPC suite now tests the full current KE1 catalog loader and readiness validator against the agreed ready, overweight and target-window cases. KE1 source commit: `55d4f336e72a68ff31cf37e44f65a98c1cdcc193`. The actual ready-config trace is [hpc-ke3-ops-trace-v0.2.json](hpc-ke3-ops-trace-v0.2.json); v0.1 is retained as the earlier provisional sample. SE/KE3 controller and screen integration still needs a runtime walkthrough with the actual Launch and Operations UI path.
