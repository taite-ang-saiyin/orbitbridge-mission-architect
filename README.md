# OrbitBridge - Mission Architect

**Design a spacecraft. Plan its mission. Operate it in Earth orbit. Learn from the outcome.**

OrbitBridge is an educational satellite mission design and operations sandbox being developed for the NASA Space Apps Challenge 2026. It brings mission planning, spacecraft assembly, launch readiness, orbital operations, and mission review into one interactive experience.

The goal is to make spacecraft engineering easier to explore through experimentation. Players set a mission objective, work within a budget, choose spacecraft components, and investigate how their decisions affect the mission. A successful mission involves capturing useful observations and returning data to Earth while managing limited resources.

Built with **Godot 4.7.2** and **GDScript**, the project combines an interactive desktop interface, modular 3D spacecraft, Earth and orbit visualization, engineering checks, and a deterministic mission simulation. It runs locally without a backend service.

## The mission experience

The project follows a complete design-to-review workflow:

```text
Home -> Mission Control -> Mission Creator -> Spacecraft Builder
     -> Flight Readiness -> Mission Operations -> Debrief and Redesign
```

| Stage | What the player explores |
| --- | --- |
| Mission Control | Start a mission or choose a starting preset |
| Mission Creator | Define the mission name, objective, target, observation goals, duration, and budget |
| Spacecraft Builder | Assemble a spacecraft, choose components, and inspect the design in 3D |
| Flight Readiness | Review mass, cost, power, compatibility, and other launch constraints |
| Mission Operations | Follow the spacecraft in orbit, capture observations, manage energy and storage, and transmit data during ground contact |
| Debrief and Redesign | Review mission outcomes, compare experiments, and return to the design to try an improvement |

The intended learning loop is to change a design or an operating decision, run another experiment, and understand the difference in the results. The current development status of this workflow is described below.

## Features

### Mission planning

- Define mission details, observation goals, duration, and a credit-based budget.
- Explore target and orbit selections with an illustrative coverage preview.
- Review a mission summary before moving into spacecraft design.

### Modular spacecraft design

- Combine independent Body, Solar Panels, and Radio selections, with 27 visual combinations in the current builder.
- Rotate and zoom the 3D spacecraft preview and inspect its assembly.
- Carry the selected spacecraft appearance through Readiness and Operations.
- Explore the relationship between spacecraft capabilities, mission requirements, and resource limits.

### Readiness and engineering checks

- Calculate design metrics from component and launcher catalogs.
- Check mission configuration, budget, mass, launch-profile compatibility, target suitability, and essential power requirements.
- Present readiness information alongside resource gauges and a spacecraft/orbit preview.

### Orbital operations and resource management

- Explore a 3D Earth and spacecraft view, ground-track display, telemetry, and an event timeline.
- Model observation opportunities, sunlight/eclipse periods, and ground-contact windows.
- Simulate observation, transmission, and power-save actions with bounded battery energy and data storage.
- Preview the next action's energy and storage outcome through the simulation API.
- Preserve ordered action evidence and support an operator abort with a recorded reason.

### Mission review and experimentation

- Explore the debrief and Run A/Run B comparison interface.
- Return to the spacecraft builder to try a different design.
- Develop the connection between mission requirements, captured observations, data received on Earth, and the final outcome.

### Presentation and usability

- Shared navy/cyan styling, sidebar navigation, and responsive desktop layouts.
- Fullscreen and resizable-window modes.
- Session-based theme and language settings. The mission workflow is in English; Home and Settings also support Simplified Chinese.
- Local assets and data support an offline experience.

## Current development status

OrbitBridge is under active development. The main application provides the mission workflow screens and 3D presentation. Parts of Readiness, Operations playback, and Debrief still use clearly identified sample data. The engineering validator, catalogs, simulation, resource predictions, and evidence bundles are implemented separately in this repository; connecting the full application workflow to these components is ongoing. Final mission evaluation and comparison integration is also in progress.

The visible prototype should therefore be used to explore the interface and intended experience. Changing a selection does not yet cause every sample chart, timeline, or debrief result to be recalculated. Next-step prediction is available in the simulation API and has not yet been connected to a preview panel in the UI.

Orbits, access windows, and many engineering values are simplified educational assumptions. The project models engineering trade-offs for learning; the animated orbit and coverage illustrations are not physical coverage forecasts. Desktop development is the current focus, and final export verification remains pending.

## Getting started

1. Install **Godot 4.7.2**. Either the Standard or .NET editor can run this GDScript project.
2. Clone or download this repository.
3. In Godot's Project Manager, import the existing `project.godot` from the repository root.
4. Open the project and press **F5** to run it.
5. From Home, select **Start Mission** and follow the workflow.

The application starts from `scenes/Main.tscn`. To explore the standalone 3D preview, open `scenes/3d/PreviewDemo.tscn` and press **F6**.

The project uses the Compatibility rendering method. Its desktop design canvas is 1440 x 900, with layouts that adapt to smaller windows.

## Controls

| Control | Action |
| --- | --- |
| F5 in the editor | Run the application |
| F6 in the editor | Run the open scene |
| F11 in the application | Toggle fullscreen and windowed mode |
| Tab | Move keyboard focus between controls |
| Sidebar and top navigation | Explore the mission workflow screens |
| Back / Continue | Move through the current workflow |
| Operations playback controls | Play, pause, step, change speed, or skip to the end of the sample timeline |
| Operations event list | Inspect an event and its corresponding telemetry |

## Project structure

```text
project.godot          Godot settings and application entry configuration
scenes/                Workflow screens, reusable UI scenes, and 3D stages
scripts/               Application control, screen behavior, validation, and visualization
core/                  Mission simulation, orbit planning, and data adapters
data/                  Component catalogs, orbit presets, and fixtures
data/mock/             Sample data used by the visual prototype
ui/                    Shared interface components and themes
assets/                Artwork, textures, and spacecraft resources
tests/                 UI, 3D, validation-integration, and simulation checks
docs/                  Design guides, contracts, sources, and integration notes
```

UI presentation, engineering calculations, simulation, and mission evaluation use explicit data boundaries. Shared interfaces are documented in [the implementation contracts](docs/contracts.md). Many controls are created at runtime, so running a scene shows more than its editor preview.

## Development checks

Run these examples from the repository root. Replace `godot` with the path to your Godot 4.7.2 executable if it is not on PATH.

```sh
godot --headless --path . --script tests/prototype_smoke.gd
godot --headless --path . --script tests/modular_reference_smoke.gd
godot --headless --path . --script tests/design_workflow_smoke.gd
godot --headless --path . --script tests/3d/preview_smoke.gd
godot --headless --path . --script tests/test_simulator.gd
godot --headless --path . --script tests/test_hpc.gd
```

The repository includes checks for navigation, spacecraft combinations, session selections, layout, 3D scene loading, readiness integration, resource accounting, event output, and prediction consistency. Additional screen-specific checks and example trace generators are in `tests/`. Visual appearance and exported builds also need manual verification.

## Documentation

- [Home and Settings](docs/HOME.md)
- [Mission Creator and spacecraft design](docs/DESIGN_WORKBENCH.md)
- [Modular spacecraft and visual assets](docs/SATELLITE_BUILDER.md)
- [Flight Readiness](docs/FLIGHT_READINESS.md)
- [Mission Operations](docs/MISSION_OPERATIONS.md)
- [3D structure and asset conventions](docs/PROJECT_STRUCTURE.md)
- [Shared implementation contracts](docs/contracts.md)
- [Validation and integration plan](docs/validation-plan.md)
- [Simulation APIs and integration evidence](docs/hpc-integration.md)
- [Contributor agreement](docs/team-agreement.md)
- [Sources and engineering references](docs/sources.md)

Some supporting documents describe earlier prototype stages. Refer to the current implementation and agreed contracts when integrating changes.

## Sources and assets

The project uses educational engineering references and adapted visual resources, including NASA spacecraft resources. Source records and assumptions are documented in [the source ledger](docs/sources.md) and [the spacecraft asset guide](docs/SATELLITE_BUILDER.md). Preserve the source and license information for imported assets when contributing.
