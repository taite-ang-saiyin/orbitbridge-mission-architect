# K12/K13: Builder and real mission flow

Completed locally on 14 November 2026 against the signed `v1.0-agreed` contract. The active app now connects Creator → Builder → Readiness → HPC Operations → KE2 Debrief. This is working-tree integration on `ke1`; no commit, push, merge commit, or teammate message was made.

## Team code used

| Source | Exact revision | Integration |
| --- | --- | --- |
| KE1 starting point | `55d4f336e72a68ff31cf37e44f65a98c1cdcc193` | Existing validator, catalogs, fixtures and tests preserved |
| `origin/main` | `1a82ebd93a019b751947965aa760e8e759d8f45b` | SE screen shell, assets, 3D presentation, theme and project settings |
| `origin/feature/hpc-simulator` | `9dfd942e6fccf230d03dfdf8bf097bf65d8f143f` | Unchanged `core/` runtime, fixtures and owner tests |
| `origin/memberKE2` | `f313e6fbf5c0eed7f67885edb45ce5ba45b85bba` | Unchanged evaluator/feedback scripts and owner tests |

The integration adapts SE's screen/controller files rather than implementing another simulator or evaluator. HPC and KE2 runtime scripts remain byte-for-byte identical to the revisions above. The signed agreement, original KE1 core scripts, production KE1 catalogs and HPC orbit file are unchanged. The imported SE project settings set the main scene and Compatibility rendering; this replaces the previously empty local project shell. Main's art and mock presentation helpers remain where needed by the visuals; active launch checks, mission telemetry and reports do not use mock results.

## K12: Builder and launch gate

- Builder offers the actual six catalog slots and real part IDs. Mass, cost, power, battery, storage, observation data and hourly downlink values come from `MissionValidator`.
- Swapping Basic imaging camera for Advanced imaging camera changes the displayed total from **1060 g / 82 credits** to **1380 g / 96 credits**. The sample `< 1330 g` rule then blocks continuation/launch and displays a useful correction.
- Profile, launcher, orbit and policy selectors are live. The heavy design passes with the illustrative alternative, medium launcher and sufficient budget; it still fails with budget 100 because its total is 116 credits.
- Readiness shows all eight real checks and the source-backed sample mass credit. Alternative profiles display their own illustrative rule and do not claim the NASA limit.
- Every Launch request revalidates current selections using the same loaded catalog bundle used to build the scenario. Sidebar/progress navigation cannot bypass validation. Editing is blocked while a mission is operating.

## K13: validated config through simulation and evaluation

`scripts/integration/design_catalog.gd` supplies UI defaults and labels. `scripts/integration/mission_workflow.gd` connects the owners' existing calls:

1. Map the UI draft explicitly into MissionConfig and call KE1 `validate`. The six UI component selections map to the six design IDs; `components.payload` maps to `instrument_id`. Only the agreed `imaging`/`equator` combination is offered. Multiple/unsupported legacy targets are rejected, never reduced silently to the first target. Creator now asks separately for captured observations and returned MB.
2. Call HPC `HPCContractAdapter.build_scenario(catalogs, catalogs.orbit_catalog)`, then `MissionStepEngine.init_run` only after readiness passes. Save independent config, catalog and scenario snapshots with unique session run/mission identities.
3. Operations calls the real `request_action`, `get_available_actions` and `abort_run`. Manual Observe/Send/Save Power, automatic stepping, run-to-end and stopping all use HPC state/events. Wh and decimal MB remain unchanged; the hourly radio rate is converted to a step capacity only by HPC.
4. At a terminal state, call KE2 `evaluate_mission` with the launch config snapshot and actual HPC event log. Store one report per run ID. Debrief displays the real status, score, captures, returned data, explanation and feedback. A failed evaluation displays a correction rather than inventing a mission score.
5. Retry preserves the exact previous config, catalogs, scenario and policy while clearing live counters/events and assigning a new run ID. New Mission clears run history and gets a new mission ID. Reopening Results does not add another report. Aborts produce failed reports with null scores.

The starter mission completed **60 steps**, captured **4 observations**, returned **48 MB** against the **30 MB** goal, and received KE2 **success / 100**. Both agreed orbit presets passed through real evaluation. Snapshot tests changed the editable draft after launch and verified that the run and evaluator kept the original goals/parts.

## Verification

Godot `4.7.2.stable.official.ed1daf0bf`:

| Suite | Passed | Failed |
| --- | ---: | ---: |
| KE1 field/catalog | 294 | 0 |
| KE1 readiness | 671 | 0 |
| KE1 saved fixtures | 470 | 0 |
| HPC step-engine owner suite | 26 | 0 |
| KE2 owner suite | 143 | 0 |
| New real mission-flow integration | 32 | 0 |
| New screen-flow integration | 30 | 0 |
| Counted total | **1666** | **0** |

The HPC legacy simulator suite also exited 0; it does not print a check count. All eight test programs exited 0. New tests cover stale launch results, real part/dropdown controls and labels, navigation bypasses, independent budget blocking, launch snapshots, blocked actions, actual terminal evaluation, repeated-result handling, retry, abort and New Mission. See [tool-setup.md](tool-setup.md) for commands.

The unchanged KE2 suite still prints five pending entries: optional comparison/baseline features, its older exact-boundary Builder cases, and its older full-integration placeholder. This task did not rewrite the owner's test declarations. KE1 suites execute exact 1329/1330/1331 g boundaries; the new integration suites separately prove actual part swaps/profile changes and the real HPC → evaluator → Results/retry path. Optional controlled A/B comparison remains unimplemented by KE2 and is not represented as working in the UI.

The project imported successfully. Six real GPU-rendered screen states were inspected: Creator, valid Builder, overweight Builder, blocked Readiness, Operations and Debrief. The native desktop-control service was unavailable, so screen behavior was tested through actual Godot Button/OptionButton signals and scene instances, with rendered images used for visual review. Exported executables and browser builds were not tested.

## Handoff and next work

K12 changes the active `MissionController.gd`, `Workbench.gd`, `MissionCreator.gd`, `SpacecraftBuilder.gd` and `FlightReadiness.gd` from the imported SE revision. K13 connects `MissionOperations.gd`, adds live `MissionControl.gd`/`DebriefCompare.gd`, updates their two scenes, and adds two integration helpers/tests. Imported themes/assets/scenes retain their SE provenance.

There are no blockers to K12/K13 in this local project. K13a still needs the team's Windows/browser choice and an export check; K14 is team acceptance testing. Teammate review/receipt and sharing remain unconfirmed. The K11 `docs/handoff/manifest.json` is a historical snapshot of the pre-integration handoff at `55d4f33`, not a hash manifest for the current integrated project. Do not use it to overwrite newer integrated files.
