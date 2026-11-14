# KE1 handoff to SE, HPC and KE2

Prepared 14 November 2026 (Asia/Rangoon), against the signed `v1.0-agreed` contract. KE1's validator, catalogs and examples are ready for integration. This package is saved locally; teammate receipt and screen/simulator/export integration have not been confirmed. No commit, push or team message is implied.

## Start here

| Recipient | What to use | Next action |
| --- | --- | --- |
| SE | Public calls below, returned checks/metrics, saved configs/results | K12: replace mock readiness, update Builder totals, block Launch when required |
| HPC | The same validated config, catalog IDs, units and native orbit data | K13: connect the agreed run API and preserve current selections/goals |
| KE2 | Source record and credit below, original mission requirements | Add the source to the shared ledger/credits and evaluate actual run outcomes |

The [signed agreement](team-agreement.md) and [detailed contract](contracts.md) remain the authority. This handoff introduces no field, rule, or API changes.

## Files needed in a teammate checkout

| Files | Purpose |
| --- | --- |
| `scripts/core/mission_validator.gd`, `catalog_loader.gd`, `validation_support.gd` | Public validator and both required dependencies |
| `data/components.json`, `launch_profiles.json`, `launchers.json`, `ke1_reference_ids.json` | KE1 catalogs, IDs and rule assumptions |
| `data/orbits.json` | HPC's native authored windows, used for target readiness |
| `tests/fixtures/` | Real valid/invalid configs and the saved-case manifest; see [fixture guide](../tests/fixtures/README.md) |
| `tests/validation/test_mission_validator.gd`, `test_mission_readiness.gd`, `test_mission_fixtures.gd` | Reproducible checks |
| This guide, `docs/contracts.md`, `docs/sources.md`, `data/README.md`, `docs/references/NASA_CubeSat_101.pdf` | Interface, units, source and assumptions |
| `docs/handoff/` | Actual result snapshots, test logs and file hashes |

Sharing only this guide does not install the validator. The runtime scripts, catalogs and test inputs must also be present in the teammate's checkout. Personal assistant instructions and `tasks.md` are not runtime dependencies. This package does not include the editor, cache or exports.

## Public interface and runnable example

Load data once for the current catalog revision with `OrbitBridgeCatalogLoader.load_catalogs(base_path = "res://data") -> Dictionary`. It returns `{ok, catalogs, errors}`. If `ok` is false, show loading errors and keep Launch disabled; do not treat this wrapper as a ValidationResult. The resulting `catalogs` is the loaded bundle, not the individual JSON file documents.

Call `MissionValidator.validate(config: Variant, catalogs: Variant) -> Dictionary` on the current MissionConfig. This call does no file loading, writes, networking or random work, and preserves both inputs. It returns the ValidationResult directly, without an `ok` wrapper.

This complete, scene-free example prints the real valid result and exits successfully. Save it as a temporary Godot script and run it with `--headless --path <project-root> --script <script-path>`:

```gdscript
extends SceneTree

const Loader = preload("res://scripts/core/catalog_loader.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")

func _initialize() -> void:
    var loaded: Dictionary = Loader.load_catalogs()
    if not loaded["ok"]:
        printerr(JSON.stringify(loaded["errors"]))
        quit(1)
        return
    var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(
        "res://tests/fixtures/valid_1u_feasible.json"))
    var result: Dictionary = Validator.validate(config, loaded["catalogs"])
    print(JSON.stringify(result, "  "))
    quit(0 if result["ready_to_launch"] else 1)
```

ValidationResult contains `schema_version: 1`, `ready_to_launch`, `metrics`, `checks`, `errors`, and `warnings`. `metrics` is null when invalid selections or unsafe values prevent totals. On ordinary feasibility failures, valid totals remain available. Errors have `code`, `field_path`, `message`, `suggested_fix`, and sometimes `source_id`. Warnings are nonblocking; the current implementation returns an empty warnings array.

The eight checks are `input_schema`, `catalog_references`, `profile_mass`, `launcher_capacity`, `budget`, `launch_orbit`, `target_orbit`, and `essential_power`. Each has a message plus `status` / `passed`: `pass` / true, `fail` / false, or `not_evaluated` / null. Missing/unusable orbit metadata blocks readiness. Never display unavailable metrics as zero or an unevaluated check as passed.

## Units and IDs for SE and HPC

| Field or quantity | Unit / rule |
| --- | --- |
| `total_mass_g`, component `mass_g`, payload thresholds | Whole grams; add the six spacecraft parts once, exclude launcher mass |
| `total_cost_credits`, `budget_credits` | Whole illustrative credits; include parts and launch service |
| `baseline_power_w`, `solar_generation_power_w`, action power | Watts |
| `battery_capacity_wh`, `initial_energy_wh`, runtime energy | Watt-hours; legacy Ws / 3600 |
| `storage_capacity_mb`, `data_per_observation_mb`, returned/stored data | Decimal MB; legacy KB / 1000 |
| `downlink_mb_per_hour` | Decimal MB per hour; step capacity is rate × `step_duration_hours` |
| Mission goals and duration | Positive values under contract ranges; counts/duration are whole numbers |
| Objective / target | `imaging` / `equator` |
| Orbits | `low_eq`, `high_inc` |
| Launch profiles / launchers | `cubesat_1u_sample`, `illustrative_alternative` / `small`, `medium` |

All selected part IDs are in the saved configs and catalogs. `instrument_advanced` is real; `instrument_boundary_heavy` in the older contract mocks is not a selectable catalog part. The exact-boundary manifest uses private test catalog overrides; do not place those values in production catalogs.

HPC's unchanged orbit file came from `feature/hpc-simulator`, commit `ab7865cf45e65de84637b4319899759928ee7082`. SHA256: `0ed028a477998057ede2e6f79bd29d7d7569b32e6a9869d00c9826a0f8aa36d4`. The loader attaches its native document as `catalogs.orbit_catalog`. Its window/unit fields belong to HPC. These are authored gameplay windows, not real coverage calculations.

## Passing and failing examples

Paths below are relative to `tests/fixtures/`. The linked result snapshots were generated by the real validator with the unchanged catalogs; they are reference outputs, not replacement runtime calculations.

| Config | Mass / cost | Ready | Result / reason |
| --- | --- | --- | --- |
| `valid_1u_feasible.json` | 1060 g / 82 credits | true | [Full valid result](handoff/valid_1u_result.json) |
| `overweight_1u_1380g.json` | 1380 g / 96 credits | false | [Full overweight result](handoff/overweight_1u_result.json); PROFILE_MASS_EXCEEDED |
| `alternate_profile_1380g.json` | 1380 g / 116 credits | true | [Full alternative result](handoff/alternate_profile_result.json); compatible medium launcher, budget 120 |
| `budget_fail.json` | 1060 g / 82 credits | false | Budget 81; BUDGET_EXCEEDED even though mass passes |
| `incompatible_launch_profile.json` | 1060 g / 82 credits | false | LAUNCH_ORBIT_INCOMPATIBLE even though mass passes |

For the source-backed profile, `checks.profile_mass` includes actual mass, threshold 1330, comparator `<`, profile/source IDs, verdict and message. Exactly 1330 g fails. For the alternative it uses threshold 5000, comparator `<=`, source_id null and its own assumption_id. Invalid inputs leave dependent mass fields null and status not_evaluated.

## SE: Builder and launch flow

1. Build MissionConfig with the agreed `schema_version`, `mission` and `design` fields. Replace prototype names/target lists/payload fields using the contract's explicit mapping; do not silently choose one of several targets.
2. Revalidate after a part, orbit, profile, launcher or goal changes. Show the returned metrics, check messages, fixes and appropriate source credit.
3. Enable Launch only for `ready_to_launch == true`. Revalidate the current config again on the Launch request; a previous passing result becomes stale after an edit.
4. Take an independent config snapshot for the run. K12 should verify a component swap updates displayed totals and launch permission. K13 connects the snapshot to HPC, then KE2/KE3 results.

Do not calculate a second readiness verdict in the UI. A passed pre-launch check is not a guarantee of mission success or enough energy for all actions/eclipses.

## HPC: validated configuration boundary

Use the current validated config and matching scenario version. Preserve `mission.required_observations`, `required_returned_data_mb`, `duration_orbits`, target and all selected IDs. The native agreed step API is `init_run(config, scenario, run_id, mission_id)`, `get_available_actions(state)`, and `request_action(state, action)`. Its detailed wrappers and state fields are in [contracts section 6](contracts.md#6-missionstepengine-and-missionstate).

Legacy `RunInput`/`brief`/`brief.policy`, Ws and KB remain behind an explicit HPC adapter. This handoff does not implement or claim to verify that adapter. Do not pass the loader wrapper, ValidationResult, or documentation mock config as the runtime MissionConfig. HPC retains runtime energy/storage accounting and actual action/window enforcement.

## KE2: source and credit handoff

| Item | Verified record |
| --- | --- |
| Title | CubeSat 101: Basic Concepts and Processes for First-Time CubeSat Developers |
| Verified NASA-hosted PDF | [NASA CubeSat 101](https://www.nasa.gov/wp-content/uploads/2017/03/nasa_csli_CubeSat_101_508.pdf) |
| Offline copy | [NASA_CubeSat_101.pdf](references/NASA_CubeSat_101.pdf) |
| Locator | Appendix C, Templates, item 6, 1U CubeSat Acceptance Checklist; printed p.79 / PDF p.87 of 96; checklist dated 02/20/2014 |
| Source value / conversion | Mass < 1.33 kg; model rule mass < 1330 g |
| Profile / source ID | `cubesat_1u_sample` / `cubesat_101_1u_sample` |
| Implementation | `data/launch_profiles.json`; catalog integrity in `catalog_loader.gd`; totals/verdict/source fields in `mission_validator.gd` |
| Evidence | Strict 1329/1330/1331 g tests, result snapshots, and [source ledger](sources.md) |

Suggested visible credit, matching the existing source ledger:

> Sample 1U mass check adapted from NASA CubeSat 101, Appendix C, item 6, p.79. This educational profile requires total modeled spacecraft mass below 1.33 kg. Other values are illustrative.

Only this sample mass rule is sourced here. Alternative thresholds, parts, launch costs/capacities, power gate and authored windows are training assumptions. This is not flight certification. KE2 still owns the shared source-ledger entry, final visible credit/export check, and independent confirmation of the challenge resource-list requirement. Preserve the original mission goals for evaluation; readiness is not a mission score.

## Test evidence and acceptance

Godot `4.7.2.stable.official.ed1daf0bf`; K09/K10 project runs on 14 November 2026: 294 field/catalog + 671 readiness + 470 saved-fixture checks = **1435 passed, 0 failed**, all exits 0. The actual logs are saved in [validation-test-log.txt](handoff/validation-test-log.txt). No runtime or test inputs changed in K11. K11 also executed this guide's example and generated the three result snapshots through the public calls; see [handoff-check-log.txt](handoff/handoff-check-log.txt). The [SHA256 manifest](handoff/manifest.json) records the exact delivered runtime, inputs, tests and evidence.

Reproduce from the project root with your Godot 4.7.2 executable:

```powershell
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/validation/test_mission_validator.gd
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/validation/test_mission_readiness.gd
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/validation/test_mission_fixtures.gd
```

SE/HPC can first reproduce the valid and overweight results, then verify K12/K13 in the real player flow. Teammate receipt, Builder display/launch blocking, simulator/evaluator adapters, renderer synchronization and exports remain unverified. There are no blockers to preparing this handoff; the next KE1 task is K12 with SE.
