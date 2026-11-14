# OrbitBridge: Mission Architect

An educational satellite mission simulator planned for Godot 4. Design spacecraft, operate missions in Earth orbit, and explore engineering trade-offs through experiments.

## Project status

Team agreement v1.0-agreed is approved by all five roles. K01-K06 are complete: mission field/selection checks, catalog loading and actual labeled training catalogs are implemented. Godot 4.7.2 passed 296 checks. K07-K09 still need to add totals/full launch readiness; the game cannot launch from this foundation alone.

## Planned gameplay

1. Create a mission by choosing an objective, targets, observation count, duration, and budget.
2. Build a satellite by selecting its instrument, bus, battery, solar panels, storage, and radio, plus a launcher, orbit, and operations policy.
3. Review readiness checks for cost, mass, power, compatibility, and coverage risks.
4. Run the mission and track energy, observations, storage, and data returned to Earth.
5. Compare two runs to understand how a design change affects mission results.

## Technology

- Engine: Godot 4.7.2 (team version confirmed by the user)
- Language: GDScript
- Data: Versioned local JSON catalogs and fixtures
- Delivery: final demo format pending; existing project setup targets Windows

## Learning focus

- Turn a science goal into measurable requirements.
- Understand how spacecraft subsystems constrain mission performance.
- Distinguish observations captured from observations fully delivered.
- Run controlled experiments and explain cost and resource trade-offs.

## Model scope

The proposed MVP uses fictional components, preset circular Earth orbits, and a simplified simulation for education. It is not intended for real flight planning.

## Getting started

Import the existing project.godot from this repository into Godot 4.7.2. The existing project shell and KE1 field/catalog checks are present; the full gameplay loop and scenes are not integrated yet.

Open this repository root in Codex or Antigravity. Both assistants use the shared root guidance; take turns when editing the same files.

## KE1 implementation status

Status: IMPLEMENTATION. [docs/team-agreement.md](docs/team-agreement.md) (`v1.0-agreed`) is agreed by all five roles and contract v1 is frozen; `K01`–`K06` are complete and `K07` is next.

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

The final demo may be Windows, browser, or both and can be selected after the first playable slice. Compatibility rendering is agreed; the signed agreement reports it on master while local main still has Forward Plus. SE owns the branch/settings sync and early Web export check. This contract/example synchronization preserves project.godot.

## License

A project license has not yet been selected.
