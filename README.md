# OrbitBridge - Mission Architect

OrbitBridge is an educational satellite mission design and operations project being developed for the NASA Space Apps Challenge 2026. Players define a mission, assemble a spacecraft, review launch readiness, operate the satellite, and use the results to improve their next design.

The project uses Godot 4.7.2 and GDScript. It includes an interactive desktop UI, 3D spacecraft and Earth previews, KE1 readiness validation, and a deterministic HPC mission simulator. The application runs locally without a backend service.

## Current development status

The active application connects Creator, Builder and Readiness to real KE1 checks, HPC operations and KE2 evaluation. K15 combines stable KE1 work with current main's simulator fixes and current KE2 runtime support. All 12 active test programs pass: 1790 counted assertions plus the legacy, Home/settings, layout and 3D checks. The separately rebuilt Windows app passes 61 checks headlessly and with graphics. See [K15 integration](docs/k15-integration.md) and [Sunday open work](docs/sunday-blockers.md).

| Area | Available in this checkout |
| --- | --- |
| Application shell | Home, Settings, Mission Control, screen navigation, and responsive desktop layout |
| Mission Creator | Mission name, description, objectives, target selection, observation goal, duration, budget, and illustrative coverage preview |
| Spacecraft Builder | Six real catalog slots, calculated mass/cost/resources, profile/launcher/orbit choices and illustrative 3D preview |
| Flight Readiness UI | All eight real checks, current totals, blocking explanations and the source-backed sample mass credit |
| Operations UI | Real HPC actions/state/events, 3D orbit presentation, automatic stepping, live counters and operator abort |
| Debrief UI | Real KE2 score/status/feedback, one report per run, run history, retry and New Mission; optional A/B comparison remains pending |
| KE1 engineering module | Component and launcher catalogs, mission configuration validation, and readiness results |
| HPC engineering module | Validated run initialization, step actions, resource accounting, ordered events, operator abort, and next-step predictions |
| KE2 evaluation handoff | Current evaluator/feedback, native HPC-state adapter, terminal-reason support and owner regression tests |

The active UI explicitly maps selected goals and part IDs to the [agreed v1 contract](docs/contracts.md). Prototype mocks remain historical/presentation helpers and do not authorize launch or compute active reports.

## Run the project

1. Install Godot 4.7.2. The Standard or .NET editor can run the project's GDScript code.
2. Import the existing `project.godot` from this repository's root folder.
3. Open the project and press **F5** to launch the application.
4. To run an individual scene, open it and press **F6**.

The main scene is `scenes/Main.tscn`. It starts at the Home screen. For the standalone 3D preview, open `scenes/3d/PreviewDemo.tscn`.

The application starts in fullscreen mode. Press **F11** to switch between fullscreen and a resizable window. The design canvas is 1440 x 900, with responsive layouts for smaller windows. Use **Tab** to move keyboard focus between controls.

The rendering method is Compatibility (`gl_compatibility`). Windows x86_64 is the confirmed first demo. Its real exported flow is verified; browser export remains separate and untested.

## Explore the application

1. **Home and Settings:** Start a mission, adjust the theme or available language settings, or quit. The mission workflow is in English; Home and Settings also offer Simplified Chinese.
2. **Mission Control:** Create a mission or resume the current run.
3. **Mission Creator:** Define the mission and inspect the target/orbit coverage preview. Confirm that the summary updates when selections change.
4. **Spacecraft Builder:** Choose real bus, camera, solar, battery, radio and storage parts. Inspect the illustrative rotating/zoomable preview and calculated totals. Art does not define engineering capability.
5. **Flight Readiness:** Resolve failed checks; Launch revalidates current inputs and is enabled only when every required check passes.
6. **Mission Operations:** Use Observe, Send data, Save power, automatic stepping or Run to end. Available actions, counters, energy and events come from the real HPC engine.
7. **Debrief:** Read the actual report, retry the same mission, modify the design or start a new mission. Controlled comparison is not yet implemented.

The top navigation and Back/Continue controls let users explore the workflow. Check that controls remain accessible when resizing the window.

## HPC mission operations

The scene-independent simulator is implemented in `core/MissionStepEngine.gd`. It consumes the agreed MissionConfig and an immutable scenario snapshot.

| API | Purpose |
| --- | --- |
| `init_validated_run(config, catalogs, run_id, mission_id)` | Run KE1 readiness validation and initialize only an approved configuration |
| `init_run(config, scenario, run_id, mission_id)` | Initialize a run from an explicit scenario snapshot |
| `get_available_actions(state)` | Return action eligibility and blocked reasons |
| `predict_next_step(state, action)` | Preview energy, storage, data return, and lifecycle changes without modifying the run |
| `request_action(state, action)` | Attempt one observation, transmission, or power-save step |
| `abort_run(state, reason)` | Finish an operating run with a recorded operator-abort reason |

Public energy values use **Wh**, data values use **decimal MB**, and step durations use **hours**. Radio capacity per step is `downlink_mb_per_hour * step_duration_hours`.

Accepted actions advance one step. Blocked requests emit an event while preserving the step and resource counters. Battery energy and stored data stay within their bounds. Accepted `power_save` can clamp energy to zero and continue. A naturally completed run finishes at `step_index == total_steps`; an operator abort preserves the current step and counters.

### Next-step prediction

```gdscript
const StepEngine = preload("res://core/MissionStepEngine.gd")

# state is an initialized MissionState returned by the engine.
var preview: Dictionary = StepEngine.predict_next_step(state, "observe")
if preview.ok:
    var prediction: Dictionary = preview.prediction
    if prediction.allowed:
        print("Energy after action: %.3f Wh" % prediction.energy_wh_after)
        print("Stored data after action: %.3f MB" % prediction.stored_data_mb_after)
        print("Free storage after action: %.3f MB" % prediction.storage_remaining_mb_after)
    else:
        print(prediction.blocked_code, ": ", prediction.reason)
```

Prediction and execution share the resource calculation. Preview calls preserve the input state, snapshots, event log, and event sequence. Recompute a preview when the authoritative state changes. UI adoption of this optional API requires coordination with SE and KE3.

### Orbit presets and observation windows

| Orbit ID | Target ID | Observation steps per orbit | Ground-contact steps per orbit |
| --- | --- | --- | --- |
| `low_eq` | `equator` | 2, 5 | 8 |
| `high_inc` | `equator` | 1, 6 | 0, 7 |

Step indices are zero-based. A target window is an opportunity to observe the target during the orbit. Successful capture also requires the instrument's sunlight conditions, sufficient energy, and free storage. Observation windows and ground-contact windows serve different operations.

These presets use authored, deterministic gameplay windows. The orbital illustrations and window counts are educational approximations rather than physical coverage predictions. Preset metadata is in `data/orbits.json`.

### Legacy simulator compatibility

`core/MissionSimulator.gd` preserves the original whole-run `RunInput -> RunTrace` API in watt-seconds and kilobytes. `core/LegacyTraceAdapter.gd` provides an explicit output conversion for summaries and telemetry:

- `Wh = Ws / 3600`
- `decimal MB = KB / 1000`

Raw legacy events remain under `legacy_events` and retain their original schema and units. Use `MissionStepEngine` for v1 MissionState and Event payloads. See the [HPC integration handoff](docs/hpc-integration.md) for API details and trace bundles.

## Repository layout

```text
project.godot                 Godot project settings and main-scene configuration
scenes/Main.tscn               Application entry point
scenes/screens/               Workflow scenes
scenes/3d/                    Spacecraft, Earth, stages, and preview scenes
scenes/ui/                    Embedded viewports and UI scenes
scripts/MissionController.gd   Application shell, navigation, and session selections
scripts/screens/              Screen behavior
scripts/core/                 KE1 catalog loading and readiness validation
scripts/visualization/        3D presentation and animation
scripts/settings/             UI preferences
core/                         HPC engine, planner, and adapters
data/                         Engineering catalogs, orbit presets, and test fixtures
data/mock/                    Prototype UI fixtures and adapters
ui/                           Shared components and themes
assets/                       UI artwork, textures, and 3D resources
tests/                        Engineering checks, UI smoke checks, and trace generators
docs/                         Contracts, integration notes, sources, and screen guides
```

Many UI controls are built at runtime, so running a scene can show more than its editor preview. Visual animation is a presentation layer; simulator state and events define the engineering behavior.

## Run checks

Run commands from the repository root. In these examples, `godot` means your Godot 4.7.2 executable; replace it with the installed executable path if it is not on PATH.

### HPC checks

```sh
godot --headless --path . --script tests/test_simulator.gd
godot --headless --path . --script tests/test_hpc.gd
godot --headless --path . --script tests/run_demo.gd
```

The HPC suite covers action accounting, resource bounds, blocked actions, run/event identity, terminal states, KE1 readiness integration, legacy conversion, and prediction parity with execution across both orbit presets.

On Windows, the combined runner accepts an explicit Godot path. Replace the example path with your installation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_hpc_checks.ps1 -Godot 'C:\Tools\Godot\Godot.exe'
```

### Full active checks and Windows build

```powershell
.\tests\run_all_checks.ps1 -GodotExe 'C:\Tools\Godot\Godot.exe'
.\scripts\build_windows.ps1 -GodotExe 'C:\Tools\Godot\Godot.exe' -Verify
```

Use your installed Godot 4.7.2 executable path. The first command runs all 12 active programs, including real-flow acceptance, Home/settings, responsive layout and isolated 3D preview. Seven obsolete scripts that assert fixed mock data are explicitly preserved under tests/archive/mock_prototype/; they are not the current contract. Generated logs/builds go under ignored exports/.

The Windows build embeds runtime data and excludes source docs/tests. It supports an explicit `-- --verify-demo` check; normal startup opens Home. Inspect the chosen export target separately after changes. Personal AGENTS.md, GEMINI.md and tasks.md stay outside shared main; use the shared docs for team handoff.

## Team ownership and collaboration

| Role | Primary responsibility |
| --- | --- |
| KE1 | Mission/config schema, component and launcher catalogs, design metrics, and readiness validation |
| HPC | Orbit presets, observation/contact windows, simulation steps, energy/storage accounting, actions, events, and predictions |
| KE2 | Mission evaluation, scoring, evidence-based explanations, and learning feedback |
| SE | Application shell, Creator/Builder/Readiness screens, controller, routing, and export coordination |
| KE3 | Operations HUD, orbital presentation, debrief, and retry interaction |

Follow the [team agreement](docs/team-agreement.md) and [implementation contracts](docs/contracts.md). Coordinate edits to another member's primary files. Changes to shared fields, units, methods, or rules must be agreed with the affected producers and consumers and reflected in documentation and checks. Preserve existing assets, fixtures, and legacy simulator behavior when integrating work.

## Further documentation

- [K15 integration and test evidence](docs/k15-integration.md)
- [Sunday required checks and optional work](docs/sunday-blockers.md)
- [HPC integration and evidence bundles](docs/hpc-integration.md)
- [Team agreement](docs/team-agreement.md)
- [Shared implementation contracts](docs/contracts.md)
- [Validation and integration plan](docs/validation-plan.md)
- [Sources and engineering references](docs/sources.md)
- [Home and Settings](docs/HOME.md)
- [Mission Creator and spacecraft design](docs/DESIGN_WORKBENCH.md)
- [Modular satellite integration](docs/SATELLITE_BUILDER.md)
- [Flight Readiness screen](docs/FLIGHT_READINESS.md)
- [Mission Operations screen](docs/MISSION_OPERATIONS.md)
- [3D structure and asset conventions](docs/PROJECT_STRUCTURE.md)

Some linked design and setup documents describe earlier prototype stages. Use the agreed contracts and current implementation when resolving differences. Keep source and license information with imported assets.
