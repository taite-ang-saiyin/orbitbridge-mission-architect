# OrbitBridge - Mission Architect

OrbitBridge is an educational satellite mission design and operations project being developed for the NASA Space Apps Challenge 2026. Players define a mission, assemble a spacecraft, review launch readiness, operate the satellite, and use the results to improve their next design.

The project uses Godot 4.7.2 and GDScript. It includes an interactive desktop UI, 3D spacecraft and Earth previews, KE1 readiness validation, and a deterministic HPC mission simulator. The application runs locally without a backend service.

## Current development status

The repository contains both the visual prototype and the engineering modules. The main application still uses mock fixtures for parts of its readiness, operations, and debrief workflow. The KE1 validator and HPC simulator can be exercised independently through their APIs and tests. A complete UI-to-simulator-to-evaluator walkthrough remains an integration task.

| Area | Available in this checkout |
| --- | --- |
| Application shell | Home, Settings, Mission Control, screen navigation, and responsive desktop layout |
| Mission Creator | Mission name, description, objectives, target selection, observation goal, duration, budget, and illustrative coverage preview |
| Spacecraft Builder | Component selection, interactive 3D preview, and modular Body/Solar Panels/Radio choices with 27 visual combinations |
| Flight Readiness UI | Expandable checks, spacecraft/orbit preview, resource gauges, and prototype readiness displays |
| Operations UI | 3D orbital view, telemetry panels, event filtering, playback controls, and ground-track display driven by mock fixtures |
| Debrief UI | Prototype Run A/Run B displays and navigation back to spacecraft design |
| KE1 engineering module | Component and launcher catalogs, mission configuration validation, and readiness results |
| HPC engineering module | Validated run initialization, step actions, resource accounting, ordered events, operator abort, and next-step predictions |
| KE2 evaluation handoff | Agreed report contracts and HPC evidence bundles; the KE2 evaluator is maintained on its own team branch and is not present in this checkout |

Prototype UI fields and fixture values can differ from the agreed v1 engineering contract. Use the [shared contracts](docs/contracts.md) when connecting modules.

## Run the project

1. Install Godot 4.7.2. The Standard or .NET editor can run the project's GDScript code.
2. Import the existing `project.godot` from this repository's root folder.
3. Open the project and press **F5** to launch the application.
4. To run an individual scene, open it and press **F6**.

The main scene is `scenes/Main.tscn`. It starts at the Home screen. For the standalone 3D preview, open `scenes/3d/PreviewDemo.tscn`.

The application starts in fullscreen mode. Press **F11** to switch between fullscreen and a resizable window. The design canvas is 1440 x 900, with responsive layouts for smaller windows. Use **Tab** to move keyboard focus between controls.

The configured rendering method is Compatibility (`gl_compatibility`). Final Windows/Web packaging and export verification are coordinated by SE.

## Explore the application

1. **Home and Settings:** Start a mission, adjust the theme or available language settings, or quit. The mission workflow is in English; Home and Settings also offer Simplified Chinese.
2. **Mission Control:** Create a mission or explore the available presets.
3. **Mission Creator:** Define the mission and inspect the target/orbit coverage preview. Confirm that the summary updates when selections change.
4. **Spacecraft Builder:** Choose components and inspect the spacecraft using rotation, zoom, exploded view, and subsystem highlighting. Body, Solar Panels, and Radio selections carry through to the Readiness and Operations models.
5. **Flight Readiness:** Explore the checks and resource displays. The prototype screen's launch behavior should not be treated as proof that the engineering validator approved a mission.
6. **Mission Operations:** Use Play, Pause, Step, playback speeds, and Skip to End. Select events to inspect the corresponding telemetry and visual state. Current UI playback uses mock mission data.
7. **Debrief:** Explore the prototype comparison, modify the design, or start a new mission.

The top navigation and Back/Continue controls let users explore the workflow. Check that controls remain accessible when resizing the window.

Public energy values use **Wh**, data values use **decimal MB**, and step durations use **hours**. Radio capacity per step is `downlink_mb_per_hour * step_duration_hours`.

Accepted actions advance one step. Blocked requests emit an event while preserving the step and resource counters. Battery energy and stored data stay within their bounds. Accepted `power_save` can clamp energy to zero and continue. A naturally completed run finishes at `step_index == total_steps`; an operator abort preserves the current step and counters.


Prediction and execution share the resource calculation. Preview calls preserve the input state, snapshots, event log, and event sequence. Recompute a preview when the authoritative state changes. UI adoption of this optional API requires coordination with SE and KE3.

### Orbit presets and observation windows

| Orbit ID | Target ID | Observation steps per orbit | Ground-contact steps per orbit |
| --- | --- | --- | --- |
| `low_eq` | `equator` | 2, 5 | 8 |
| `high_inc` | `equator` | 1, 6 | 0, 7 |

Step indices are zero-based. A target window is an opportunity to observe the target during the orbit. Successful capture also requires the instrument's sunlight conditions, sufficient energy, and free storage. Observation windows and ground-contact windows serve different operations.

These presets use authored, deterministic gameplay windows. The orbital illustrations and window counts are educational approximations rather than physical coverage predictions. Preset metadata is in `data/orbits.json`.

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


On Windows, the combined runner accepts an explicit Godot path. Replace the example path with your installation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_hpc_checks.ps1 -Godot 'C:\Tools\Godot\Godot.exe'
```

### UI and 3D checks

```sh
godot --headless --path . --script tests/prototype_smoke.gd
godot --headless --path . --script tests/modular_reference_smoke.gd
godot --headless --path . --script tests/satellite_selection_smoke.gd
godot --headless --path . --script tests/design_workflow_smoke.gd
godot --headless --path . --script tests/3d/preview_smoke.gd
```

Additional screen-specific checks are in `tests/`. Headless checks do not establish visual quality or exported-build behavior; inspect the application and the selected export target separately.

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
