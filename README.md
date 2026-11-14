# OrbitBridge: Mission Architect

An educational satellite mission simulator planned for Godot 4. Design spacecraft, operate missions in Earth orbit, and explore engineering trade-offs through experiments.

## Project status

Team agreement v1.0-agreed is approved by all five roles. K01-K14, including K13a, are complete locally. The user confirmed Windows for the first demo and reported team demo approval. The standalone app passes 61 checks in headless and graphical modes; source suites pass 1706 counted checks plus the legacy simulator suite. Creator → Builder → Readiness → real HPC Operations → KE2 Debrief is working. See [Windows demo and acceptance evidence](docs/k13a-k14-progress.md). K15 review/merge is next. Optional comparison/browser work remains separate; no commit or push was made.

## Planned gameplay

1. Create a mission by choosing an objective, targets, observation count, duration, and budget.
2. Build a satellite by selecting its instrument, bus, battery, solar panels, storage, and radio, plus a launcher, orbit, and operations policy.
3. Review readiness checks for cost, mass, power, compatibility, and coverage risks.
4. Run the mission and track energy, observations, storage, and data returned to Earth.
5. Review run history and retry. Controlled A/B comparison is a future optional feature.

## Technology

- Engine: Godot 4.7.2 (team version confirmed by the user)
- Language: GDScript
- Data: Versioned local JSON catalogs and fixtures
- Delivery: first demo is Windows x86_64, with embedded game data; user-confirmed and tested

## Learning focus

- Turn a science goal into measurable requirements.
- Understand how spacecraft subsystems constrain mission performance.
- Distinguish observations captured from observations fully delivered.
- Run controlled experiments and explain cost and resource trade-offs.

## Model scope

The proposed MVP uses fictional components, preset circular Earth orbits, and a simplified simulation for education. It is not intended for real flight planning.

## Getting started

Import the existing project.godot from this repository into Godot 4.7.2. Godot imports SE's assets and opens the integrated Home/Creator/Builder/Readiness/Operations/Debrief flow. The project uses the imported SE Compatibility-renderer settings.

Open this repository root in Codex or Antigravity. Both assistants use the shared root guidance; take turns when editing the same files.

## KE1 implementation status

Status: IMPLEMENTATION. [docs/team-agreement.md](docs/team-agreement.md) (`v1.0-agreed`) is agreed by all five roles and contract v1 is frozen; `K01`–`K14`, including `K13a`, are complete locally. Windows demo/export and acceptance checks passed; user reported team demo approval. `K15` review/merge is next.

- [Shared assistant instructions](AGENTS.md) and [Antigravity entry point](GEMINI.md).
- [KE1 tasks and acceptance criteria](tasks.md).
- [Team agreement for all five members](docs/team-agreement.md).
- [Detailed KE1 data contract](docs/contracts.md).
- [Validation and test plan](docs/validation-plan.md).
- [Kickoff, ownership, and handoffs](docs/kickoff.md).
- [Source ledger and offline NASA reference](docs/sources.md).
- [Godot setup and verification](docs/tool-setup.md).
- [Preparation review and remaining team decisions](docs/pre-kickoff-review.md).
- [Current K01-K04 progress](docs/kickoff-progress.md).
- [Agreed v1 interface examples and expectation cases](docs/contracts/v1-draft/README.md).
- [K05/K06 implementation, usage and test results](docs/k05-k06-progress.md).
- [Actual KE1 catalog files and assumptions](data/README.md).
- [K07/K08 totals, readiness, HPC data and test results](docs/k07-k08-progress.md).
- [K09/K10 verification and saved examples](docs/k09-k10-progress.md).
- [K11 handoff for SE, HPC and KE2](docs/ke1-handoff.md).
- [K12/K13 integrated flow, branch provenance, checks and limitations](docs/k12-k13-progress.md).
- [Runnable valid/overweight cases and expected results](tests/fixtures/README.md).
- [K13a/K14 Windows build and acceptance results](docs/k13a-k14-progress.md).
- [Team review record](docs/k14-team-review.md).

The first demo is Windows, confirmed by the user. The built OrbitBridge.exe and README are in the sibling OrbitBridge-Windows-Demo folder outside Git. Matching templates are installed and the app has been tested with graphics. Rebuild with scripts/build_windows.ps1; see docs/tool-setup.md. Browser export has not been built or tested.

## License

A project license has not yet been selected.
