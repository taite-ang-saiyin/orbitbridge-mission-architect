# Implementation resources

**Latest implementation update:** K20 is agreed and K21 definitions are delivered. [K21/K22 production API and current blockers](k21-k22-live-integration.md) and the [agreed v2 contract](../contracts/expansion-v2.md) supersede earlier pending-confirmation/candidate-only status. The public validator now supports explicit agreed v2 context; native launch integration remains blocked. Existing reviewed ZIPs are unchanged historical snapshots and do not contain these later files.


**Current update, 15 November:** Only HPC confirmation remains. [Consolidated non-HPC decisions](k20-consolidated-non-hpc-decisions.md), [candidate validator](k22-v2-candidate-validator.md), [aligned copy](k29-mission-wording-preparation.md) and [single current handoff](current-implementation-handoff.md) supersede earlier pending-owner labels below. Candidate tests: 2429 passed. Latest SE checks still expose two implementation issues; final integration remains pending.


Prepared against main dce75db. Required software is already available: Godot 4.7.2 Standard or .NET running GDScript, matching export templates, Git and a WebGL 2 browser. No multiplayer hosting, database, Python/Node runtime dependency in the game, or GMAT installation is needed for this scope.

## K24/K25 measured handoff

Read [the feasibility report](k24-k25-feasibility.md), [exact plans](examples/k24-k25-action-plans.json), [audit](tools/check_contact_revisit.gd) and [raw evidence summary](evidence/k24-k25/summary.json). These use supported v1 Imaging inputs to prove physical/event feasibility; production policies/scoring and K20 agreement remain pending. The report includes a repeat command.

## K26 Survey resources

Read [the handoff](k26-survey-preparation.md), [configs/plans](examples/k26-survey/README.md), [native audit](tools/check_survey_delivery_examples.gd) and [measured summary](evidence/k26-survey/summary.json). They preserve real v1 Survey inputs and distinguish partial/full per-target delivery from aggregate MB. Scoring and owner acceptance remain pending.

## K27 A/B resources for teammates

Read [the owner handoff and acceptance checklist](k27-ab-handoff.md), [matched configs and operation plan](examples/k27-ab/README.md), [audit](tools/check_ab_radio_examples.gd) and [real Imaging reports/metrics](evidence/k27-ab/summary.json). Proposal matching rules are separate from any implemented comparator. K20 and final KE2/SE decisions stay pending.

## K22 draft checker

Read [the API and scope](k22-draft-checker.md), [pure checker](../../scripts/core/mission_config_v2_draft_checker.gd), [tests](../../tests/validation/test_mission_config_v2_draft.gd) and [executed evidence](evidence/k22-draft/verification.json). All draft results have ready_to_launch=false; do not replace the production validator with this preparation API.

## K23 readiness report

Use [the human report](k23-five-mission-readiness.md) and [machine-readable evidence summary](evidence/k23-readiness/readiness-report.json). They combine existing results and exact input snapshots for five candidates. No new execution or launch approval is claimed; code/catalog changes need fresh integration evidence.

## Source files to use

| Need | Current path | Owner / caution |
| --- | --- | --- |
| Preset selection and active defaults | scripts/screens/MissionControl.gd; data/mock/DesignCatalog.gd | SE; preserve three existing names/settings |
| UI-to-engine config and extended catalogs | scripts/integration/mission_runtime.gd | SE + KE1/HPC; active path, unlike older mission_workflow.gd |
| Schema, metrics and eight readiness checks | scripts/core/mission_validator.gd; catalog_loader.gd; validation_support.gd | KE1 |
| Physical part, launcher and profile records | data/components.json; launchers.json; launch_profiles.json | KE1; illustrative values except individually sourced rules |
| Original orbit data and target extension | data/orbits.json; data/mission_scenarios.json | HPC; explicit training windows, not drawn-globe predictions |
| Scenario/config checks and engine packets/events | core/HPCContractAdapter.gd; MissionStepEngine.gd; OrbitPlanner.gd | HPC |
| Evaluation and report binding | scripts/evaluation/mission_evaluator.gd; scripts/integration/mission_results.gd | KE2; currently rejects Survey and does not implement full A/B |
| Review snapshot and main navigation guards | scripts/integration/mission_review.gd; scripts/MissionController.gd | SE; include new fields after agreement |
| Operations and Results | scripts/screens/MissionOperations.gd; scripts/prototype/Screen.gd; scripts/presentation/DebriefPresentation.gd | KE3 + SE; keep frozen run/report identity |
| Baseline regression and concrete examples | tests/run_all_checks.ps1; tests/validation/; tests/fixtures/valid_1u_feasible.json; tests/integration/test_ke3_merge.gd | Use actual assertions and preserve passing fixtures |
| Existing integration evidence | docs/integration-evidence/se-main-layout-merge.md | Historical inherited results; not newly executed expansion tests |
| Original agreements and source evidence | docs/team-agreement.md; contracts.md; sources.md; references/NASA_CubeSat_101.pdf | Keep signed originals; propose extensions separately |

The target pack currently has equator, tropical_forest, equatorial_ocean, coastal_region, temperate_land, arctic_ice and antarctic_region. The source orbits are low_eq and high_inc. Use registered IDs, not display names or newly invented atmospheric IDs.

## Primary references checked for this preparation

- [NASA Mission Design Lab](https://etd.gsfc.nasa.gov/capabilities/integrated-design-center/mission-design-lab/): alternative designs and subsystem resource estimates; supports the educational A/B idea, not a certification of our model.
- [NASA Build It Yourself](https://science.nasa.gov/mission/webb/game-build-it-yourself/): choosing engineering options from science requirements; informs mission briefs.
- [Godot Web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html): Compatibility/WebGL 2 and single-threaded browser export. Stay with the existing GDScript setup.
- [Godot command-line guide](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html): existing test/export commands; use the pinned 4.7.2 executable and installed templates.
- [NASA CubeSat 101 copy](https://www.nasa.gov/wp-content/uploads/2017/03/nasa_csli_CubeSat_101_508.pdf): previously verified Appendix C, item 6, printed p.79/PDF p.87. Use the existing local reference and strict sample-profile mass rule; no need to download it again.

The user-supplied v2 scope PDF is the product-planning source. Its thresholds and examples remain game assumptions until proven. Reading a NASA reference does not make invented payload specifications or orbit windows NASA data.

## Check the prepared examples

Use the [23-check audit and reproduction command](verification.md). It checks existing v1 inputs and timing diagnostics; it does not create a production evaluator.

## Commands after implementation

From this project root, using your installed Godot executable:

```powershell
$godotExe = '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe'
& $godotExe --headless --path . --script tests/validation/test_mission_validator.gd
& $godotExe --headless --path . --script tests/validation/test_mission_readiness.gd
& $godotExe --headless --path . --script tests/validation/test_mission_fixtures.gd
.\tests\run_all_checks.ps1 -GodotExe $godotExe
```

SE handles Web export into a folder outside tracked source and tests the public Netlify release. Preserve the deploy checkout's existing export path and unfinished generated files. Do not mark K18/K31 done from a source-only check.


## Ordered preparation update

See [handoff index](ordered-preparation-handoff.md), [draft capability API](k22-capability-loader.md), [SE regression handoff](k28-se-integration-preparation.md), and [five-mission copy](k29-mission-wording-preparation.md). Main focused checks: 2102 passed. SE saved-A: 73 passed. New SE contract probes: 31 passed / 7 open failures; these are not main/browser acceptance. All owner decisions and live launch approvals remain pending.
