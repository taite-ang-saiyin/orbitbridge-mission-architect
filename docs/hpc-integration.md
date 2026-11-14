# HPC integration handoff

The [native goal-evidence v1.0.0 handoff](handoffs/hpc-goal-evidence-v1/README.md) pins current producer `dce75db` and supplies 12 reproducible goal examples, canonical native/derived counter meanings, packet/resource samples, extrema, source hashes, and replay checks. Communication/Weather records explicitly demonstrate Imaging mechanics pending production config-v2 adoption. Earlier trace and integration records below retain their original revision context.

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

## Next-step energy and storage prediction (optional HPC API)

`MissionStepEngine.predict_next_step(state, action)` previews attempting `observe`, `transmit`, or `power_save` at the state's current `step_index`. It uses the immutable launch/scenario snapshots and the same resource calculation as `request_action`. It returns `{"ok": true, "prediction": {...}}` for valid states, including blocked actions, and the usual `ok: false` error wrapper for invalid states. The method leaves the input state, snapshots, cumulative event log, and event sequence unchanged. It emits no events. Existing v1 state/event payloads are unchanged; UI adoption of this optional API should be coordinated with SE/KE3.

```gdscript
var preview: Dictionary = StepEngine.predict_next_step(state, "observe")
if preview.ok:
    var prediction: Dictionary = preview.prediction
    if prediction.allowed:
        print("After observation: %.3f Wh, %.3f MB stored" % [
            prediction.energy_wh_after, prediction.stored_data_mb_after])
    else:
        print(prediction.blocked_code, ": ", prediction.reason)
```

The preview describes the result of the next requested action using the current step's sunlight, target access, contact window, and explicit hours per step. It does not predict a second action or advance past a blocked request. Recompute it whenever the authoritative state changes; only `request_action` commits a simulated step. Predictions are exact for the deterministic gameplay model, whose access windows are illustrative assumptions.

| Prediction fields | Meaning |
| --- | --- |
| `run_id`, `mission_id`, `scenario_id`, `step_index`, `action` | Identifies the source state and requested action |
| `allowed`, `blocked_code`, `reason` | Same eligibility decision as execution; blocked code/reason are null when allowed |
| `next_step_index`, `phase_after`, `run_status_after`, `will_finish` | Resulting lifecycle values; `will_finish` is true only for an accepted final step |
| `step_duration_hours`, `elapsed_step_hours` | Current step duration and predicted time advancement; blocked requests advance zero hours |
| `energy_wh_before`, `energy_wh_after`, `delta_energy_wh`, `battery_capacity_wh` | Energy in Wh, including the battery's lower/upper clamps |
| `energy_generated_wh`, `energy_consumed_wh`, `energy_clamped` | Step energy accounting before the clamp; zero/false for blocked actions |
| `stored_data_mb_before`, `stored_data_mb_after`, `delta_stored_data_mb` | Onboard data in decimal MB |
| `storage_capacity_mb`, `storage_remaining_mb_after` | Storage capacity and space remaining after the action |
| `returned_data_mb_after`, `delta_returned_data_mb`, `data_added_mb`, `data_transmitted_mb` | Received-data total and action data accounting in decimal MB |
| `observations_completed_after`, `delta_observations` | Successful capture count and its change |

Observation adds a complete packet only when access, sunlight requirements, energy, storage, and observation-limit checks pass. Transmission removes at most the currently stored data, bounded by `downlink_mb_per_hour * step_duration_hours`. Energy uses `current_wh + generation_w * hours - load_w * hours`, clamped to `[0, battery_capacity_wh]`. Accepted `power_save` can clamp at zero and continue. Blocked actions retain all counters and report zero deltas. Completed/aborted runs return blocked `MISSION_FINISHED` previews with unchanged terminal status and zero step duration/advancement.

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

## KE2 operator-abort handoff

The reproducible abort bundle is [hpc-ke2-abort-bundle-v0.1.json](hpc-ke2-abort-bundle-v0.1.json), generated by `tests/run_hpc_abort_bundle.gd`. It initializes the fixture through KE1 readiness, captures one observation, transmits during contact, records blocked no-contact transmit evidence as `evt_008`, then aborts at unchanged step 8 with the ordered terminal event `evt_009`. The bundle includes the launch config, terminal state, cumulative events, abort response, and source engine commit `3990d3c7aae3b69dcf367d9f0601fc40fd669262`.

Recreate it with Godot 4.7.2: `Godot --headless --path . --script tests/run_hpc_abort_bundle.gd` (exit 0). The generator validates preserved step/resource/capture values, nonempty `terminal_reason`, event order, and abort event before writing the bundle. The HPC regression suite command is `powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_hpc_checks.ps1` (exit 0; simulator, 36 HPC cases, and demo passed). The KE2 evaluator at `origin/memberKE2` commit `8c3ed816f5122a6645c0517aecd83880876a0cd7` also evaluated this bundle successfully (exit 0): `run_status: aborted`, `status: failed`, `score: null`, and the explanation includes the recorded abort reason.

The HPC suite now tests the full current KE1 catalog loader and readiness validator against the agreed ready, overweight and target-window cases. KE1 source commit: `55d4f336e72a68ff31cf37e44f65a98c1cdcc193`. The actual ready-config trace is [hpc-ke3-ops-trace-v0.2.json](hpc-ke3-ops-trace-v0.2.json); v0.1 is retained as the earlier provisional sample. SE/KE3 controller and screen integration still needs a runtime walkthrough with the actual Launch and Operations UI path.
