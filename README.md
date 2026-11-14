# OrbitBridge - Mission Architect

**Design a spacecraft. Plan its mission. Operate it in Earth orbit. Learn from the outcome.**

OrbitBridge is an educational satellite mission design and operations sandbox being developed for the NASA Space Apps Challenge 2026. It brings mission planning, spacecraft assembly, launch readiness, orbital operations, and mission review into one interactive experience.

Players set a mission objective, work within a budget, choose spacecraft components, and investigate how their decisions affect the mission. Success depends on capturing useful observations and returning data to Earth while managing limited energy, storage, and communication opportunities.

Built with **Godot 4.7.2** and **GDScript**, the project combines an interactive desktop interface, 3D spacecraft and Earth visualization, engineering validation, deterministic simulation, and mission evaluation. It runs locally without a backend service.

## The mission experience

```text
Home -> Mission Control -> Mission Creator -> Spacecraft Builder
     -> Flight Readiness -> Mission Operations -> Debrief and Redesign
```

| Stage | What the player does |
| --- | --- |
| Mission Control | Start a mission or resume the current run |
| Mission Creator | Define the mission name, objective, target, observation goals, duration, and budget |
| Spacecraft Builder | Choose spacecraft components, launcher, launch profile, and orbit; inspect the design in 3D |
| Flight Readiness | Review calculated totals and resolve blocking readiness checks before launching |
| Mission Operations | Capture observations, manage energy and storage, and transmit data during ground contact |
| Debrief and Redesign | Review the actual score and explanations, inspect run history, retry, or modify the design |

The learning loop is to change a design or an operating decision, run another experiment, and understand the outcome. Controlled side-by-side A/B comparison remains an optional feature in development.

## Features

### Mission planning

- Define mission details, observation and returned-data goals, duration, and a credit-based budget.
- Explore target and orbit choices with an illustrative coverage preview.
- Review a mission summary before moving into spacecraft design.

### Spacecraft design

- Select catalog parts for the bus, instrument, solar panels, battery, radio, and storage.
- Choose a launcher, launch profile, orbit, and operating policy.
- Inspect calculated mass, cost, power, and resource totals as the design changes.
- Rotate and zoom an illustrative 3D spacecraft preview. Visual models support exploration; engineering capability comes from the selected catalog parts.

### Launch readiness

- Check configuration validity, budget, mass, launcher capacity, launch-profile compatibility, target suitability, and essential power requirements.
- Inspect current totals, blocking explanations, and the source credit for the sample CubeSat mass rule.
- Revalidate current inputs when launching. A mission can launch only when all required checks pass.

### Orbital operations

- Follow the spacecraft in an illustrative 3D Earth and orbit view.
- Observe the target, send data to Earth, or save power through explicit action controls.
- Use automatic stepping or run to the end of the mission.
- Track battery energy, onboard storage, captured observations, received data, and ordered events from the simulation.
- End a run through an operator abort with a recorded reason.
- Preview an action's energy and storage outcome through the simulation API; a dedicated UI prediction panel remains to be connected.

### Mission results and iteration

- Receive a calculated mission status, score, and explanation based on the actual run.
- Review feedback and recorded evidence to understand unmet goals.
- Keep run history and retry the same mission, modify the design, or start a new mission.
- Preserve a single report per run across repeated terminal notifications.

### Presentation and usability

- Shared navy/cyan styling, sidebar navigation, and responsive desktop layouts.
- Fullscreen and resizable-window modes.
- Session-based theme and language settings. The mission workflow is in English; Home and Settings also support Simplified Chinese.
- Local assets and data support an offline experience.

## Current development status

The active application connects mission creation and spacecraft design to calculated readiness, live mission operations, and evaluated results. Earlier prototype fixtures remain as historical or presentation resources; they do not approve launch or calculate active mission reports.

The stable integration and Windows build have recorded verification evidence in [the integration report](docs/k15-integration.md). Windows x86_64 is the first demo target. Final player-journey review, testing on another Windows computer, and submission checks remain tracked in [the open-work record](docs/sunday-blockers.md). Browser export and controlled A/B comparison are not yet verified or complete.

Orbits, access windows, and many component values are simplified educational assumptions. The animated orbit and coverage illustrations are not physical coverage forecasts. Public simulation values use Wh for energy and decimal MB for data; observation and transmission depend on the selected scenario's time steps and access windows.

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
| Sidebar and top navigation | Navigate through the mission workflow |
| Back / Continue | Move through the current stage |
| Observe / Send data / Save power | Request a simulation action during operations |
| Automatic stepping / Run to end | Advance operations using the selected operating policy |
| Abort | End the current run and preserve its recorded progress |
| Retry / Modify Design / New Mission | Continue experimenting from the debrief |

## Project structure

```text
project.godot          Godot settings and application entry configuration
scenes/                Workflow screens, reusable UI scenes, and 3D stages
scripts/               Application control, validation, evaluation, and visualization
scripts/integration/   Mission workflow and shared application data mapping
core/                  Mission simulation, orbit planning, and data adapters
data/                  Component catalogs, orbit presets, and fixtures
data/mock/             Historical prototype and presentation data
ui/                    Shared interface components and themes
assets/                Artwork, textures, and spacecraft resources
tests/                 Validation, simulation, evaluation, UI, and integration checks
docs/                  Design guides, contracts, sources, and verification records
```

Shared interfaces are documented in [the implementation contracts](docs/contracts.md). Many controls are created at runtime, so running a scene shows more than its editor preview.

## Development checks and Windows build

Run the full active checks from the repository root using your installed Godot 4.7.2 executable. Replace the example executable path with your installation:

```powershell
.\tests\run_all_checks.ps1 -GodotExe 'C:\Tools\Godot\Godot.exe'
```

The runner covers configuration validation, readiness, saved fixtures, simulation, evaluation, the complete mission flow, screen integration, acceptance scenarios, Home/settings, layout, and isolated 3D previews.

To run an individual check, replace `godot` below with your executable path if it is not on PATH:

```sh
godot --headless --path . --script tests/integration/test_mission_flow.gd
godot --headless --path . --script tests/integration/test_screen_flow.gd
godot --headless --path . --script tests/acceptance/test_k14_acceptance.gd
```

Build and verify the Windows demo with matching Godot export templates installed:

```powershell
.\scripts\build_windows.ps1 -GodotExe 'C:\Tools\Godot\Godot.exe' -Verify
```

Generated builds and verification logs are written under ignored `exports/`. Visual appearance and behavior on the final demonstration computer also need manual verification. Historical checks for the old mock workflow are documented separately in [the prototype archive](tests/archive/mock_prototype/README.md).

## Documentation

- [Stable integration and verification evidence](docs/k15-integration.md)
- [Open work and final demonstration checks](docs/sunday-blockers.md)
- [Home and Settings](docs/HOME.md)
- [Mission Creator and spacecraft design](docs/DESIGN_WORKBENCH.md)
- [Spacecraft models and visual assets](docs/SATELLITE_BUILDER.md)
- [Flight Readiness](docs/FLIGHT_READINESS.md)
- [Mission Operations](docs/MISSION_OPERATIONS.md)
- [3D structure and asset conventions](docs/PROJECT_STRUCTURE.md)
- [Shared implementation contracts](docs/contracts.md)
- [Validation and integration plan](docs/validation-plan.md)
- [Simulation APIs and integration evidence](docs/hpc-integration.md)
- [Contributor agreement](docs/team-agreement.md)
- [Sources and engineering references](docs/sources.md)

Some supporting design documents describe earlier prototype stages. Refer to the current implementation, integration report, and agreed contracts when resolving differences.

## Sources and assets

The project uses educational engineering references and adapted visual resources, including NASA spacecraft resources. Source records and assumptions are documented in [the source ledger](docs/sources.md) and [the spacecraft asset guide](docs/SATELLITE_BUILDER.md). Preserve the source and license information for imported assets when contributing.
