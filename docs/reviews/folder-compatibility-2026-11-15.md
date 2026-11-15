# Six-folder compatibility and science review

15 November 2026, Asia/Rangoon. Active integration commit: `6731bb3`. Scope: source comparison, official-reference review and isolated compatibility probes. No owner implementation files were merged or replaced. No deployment was performed. Exact compared-file hashes and probe outcomes are in [the evidence JSON](folder-compatibility-2026-11-15.json).

## Conclusion

The physical catalogs agree, but the six folders are **not interchangeable implementations**. The active integration has the agreed readiness context and aligned native expanded flights; its new mission results remain deliberately unscored. New evaluation and presentation files are useful inputs for targeted integration, not a replacement project tree.

| Supplied folder | Alignment with active integration | Treatment |
| --- | --- | --- |
| `ke1/` | Original physical catalogs match; original single-target/version-1 validation predates expanded support | Preserve as baseline/reference; do not replace current validator |
| `hpc/` | Physical catalogs, original orbit planner and legacy simulator match; step engine/adapter predate expanded targets/goals | Preserve physics baseline; do not replace current native goal implementation |
| `ke1-expand/` | Production v1/v2 validator implementations, agreed preset registry and capabilities match byte-for-byte | Already aligned; retain production modules and exclude historical candidate/draft paths from runtime |
| `hpc-ke3-goal-evidence-v1/` | Same physics/catalogs; updated adapter and candidate evaluator use a different v2 input/report contract | Reuse measurement semantics; keep the active canonical adapter and evidence guards |
| `features:KE2/` | Approved Imaging evaluator plus opt-in expansion candidates and a callable v1 comparison | v1 comparison passes isolated integration checks; expanded candidate still requires contract/dependency integration |
| `ke3:v2-consumer-fixes/` | Adds goal and design-comparison views, but includes older producer/storage/guard files | Selectively adapt presentation; preserve active native/config/storage fixes |

All six copies have byte-identical `orbits.json`, `components.json`, `launch_profiles.json` and `launchers.json` compared with the active integration. Where present, the original OrbitPlanner and legacy MissionSimulator also match. This establishes shared authored numbers, not physical validation.

## Findings requiring correction before integration

### 1. Expanded report acceptance does not bind the new requirements/counters — P1

`ke3:v2-consumer-fixes/scripts/presentation/DebriefPresentation.gd:23–41` verifies identity, an optional trace binding and legacy aggregate values, then accepts any nonempty goal-progress array for Communication/Weather. It does not check those new goal requirements, actuals, IDs or evidence against the frozen config and native measurements.

Reproduction: a real active Communication or Weather trace, its correct execution binding, and an injected report with goal actual/required `99/99`, met true, score 100 is accepted as `model.state == report`. The real requirements are 2 and native actuals in the probe are 2 and 1 respectively. This demonstrates an acceptance gap; no such report was published into the active session. Add explicit report-contract/goal binding checks before showing authoritative outcome/score. Missing required goal data must remain unavailable/error rather than an accepted report.

### 2. Supplied native adapter rejects the agreed readiness contract — P1 integration blocker

`hpc-ke3-goal-evidence-v1/core/HPCContractAdapter.gd:246–265` expects goal kind equal to objective and accepts generic/legacy aliases for its count. The agreed configs use `communication_contacts` / `required_positive_contact_steps` and `weather_revisit` / `required_distinct_orbits`, with `expansion-goals-v2-agreed-1` and frozen preset context. Both authored active configs are rejected by the supplied adapter with “mission.goal.kind must match mission.objective.” It also constructs a schema-1 copy internally. Keep the active validated canonical path; do not strip goals or downgrade the public config to make this copy accept it.

### 3. Expanded evaluation is still draft-only and has extra dependencies — P2 integration blocker

`features:KE2/scripts/evaluation/mission_expansion_candidate.gd:7,126` pins `expansion-goals-v2-draft-2`, so both real agreed configs fail at `config.contract_revision`. Its production `mission_evaluator.gd` continues to expose approved v1 Imaging behavior, not live expanded scoring. Importing the candidate alone also fails compilation against the active evaluator because `_measure_survey_deliveries()` is missing (`mission_expansion_candidate.gd:205`). The isolated probe included the supplied evaluator/helper dependency to test the intended candidate rather than pretending a standalone import works.

Move the candidate to the agreed config/context and report revision, integrate its complete dependencies, preserve legacy fields, validate required native evidence, then test success/partial/failure/abort and publication. Do not change archived config snapshots merely to pass the old revision check. Survey's default sparse-map policy is also still `unavailable`; agreed native absent-key-is-zero semantics require explicit verified provenance, while a missing whole map must stay unavailable.

### 4. The display folder carries a Design B guard regression — P2

`ke3:v2-consumer-fixes/scripts/integration/design_lab.gd:91,109` checks orbit but omits the active launcher's/profile's identity checks. Wholesale replacement would reopen the already corrected components-only comparison boundary and remove active `export_saved_a()`. Retain the active guards at both `launch_b()` and `comparison_inputs()` and preserve immutable A/record transport behavior.

### 5. Native progress requires an explicit consumer adapter — P2

`ke3:v2-consumer-fixes/scripts/presentation/GoalProgress.gd:155–156` reads Communication/Weather actual/required values from its separate `details` input, not from native state. With either real active trace and no adapter, the primary goal is unknown even though `final_state.goal_progress` is present. Native `goal_progress` is a dictionary, whereas candidate report `goal_progress` is an array. Keep those representations distinct and map the bound native measurements explicitly. Do not infer scores from them.

The supplied presentation output also contains `HPC battery` at `DebriefPresentation.gd:79`. Preserve active player-text sanitization and plain labels to meet the user's no-team-labels UI requirement.

## Active behavior to make explicit

The stock Weather run under Observe First captures at steps 1 and 6, both revolution 0, exhausting its two-capture quota. The probe records one qualifying revolution against a requirement of two. This is a correct count of that action plan, not a physics failure. Manual/different timing can achieve the distinct-revolution goal; the native contract test verifies that case. If the intended starter experience should succeed automatically, its policy needs an explicit revisit-aware change and fresh acceptance tests. Do not count the two same-revolution captures as two visits to hide the shortfall.

The supplied v1 callable comparison is promising: `mission_comparison.gd::compare_runs()` passed its own 34 checks against the active runtime in an isolated project with supplied evaluation dependencies and historical preimages. It remains an Imaging-only comparison interface. This result does not establish expanded scoring/comparison or UI wiring.

## NASA-reference assessment

- **Historical sample mass rule: directly supported.** [NASA CubeSat 101](https://www.nasa.gov/wp-content/uploads/2017/03/nasa_csli_CubeSat_101_508.pdf), Appendix C section 6, printed p.79 / PDF p.87, specifies mass strictly below 1.33 kg for its sample 1U checklist. The selected sample profile uses `<1330 g`; 1329 passes and 1330/1331 fail. This is not a universal current launcher certification rule. Alternative profile limits and invented hardware are not NASA specifications.
- **Power: consistent simplified concepts.** [NASA Small Spacecraft Technology, Power](https://www.nasa.gov/smallsat-institute/sst-soa/power-subsystems/) describes solar generation, eclipse and battery storage. The engine uses W × hours = Wh, no solar generation in authored eclipse and bounded battery storage. Constant output, no conversion/aging losses and power-save clamping at zero are game simplifications. In particular, continuing an always-on load at zero stored energy does not model real spacecraft survival/brownout. Static power readiness is not a lifetime energy guarantee.
- **Downlink: consistent simplified accounting.** [NASA Small Spacecraft Technology, Communications](https://www.nasa.gov/smallsat-institute/sst-soa/soa-communications/) describes rate/power/mass trade-offs and ground-station link budgets. The engine transmits at most stored MB or rate × step hours during authored contact. It lacks real propagation, antenna pointing, coding, attenuation and link-margin calculation. A positive transmission-step quota is a game success rule, not a NASA communications requirement.
- **Orbit/revisit: correct basic distinction, authored access.** [NASA Basics of Space Flight, chapter 5](https://science.nasa.gov/learn/basics-of-space-flight/chapter5-1/) defines inclination; exactly polar is 90 degrees. The shared high-inclination preset is 97.8 degrees, a near-polar retrograde orbit. Fixed ten-step windows and selected-target revolution counts do not calculate real geometric coverage. Weather is a revisit exercise; it is not a weather forecast, radiative-transfer or atmospheric-sensor model.
- **Scores, quotas, budgets and prices are illustrative.** Agreement between owner code and the integration does not imply NASA validation or endorsement. Captured images, partially returned MB and complete delivered observations must keep their distinct meanings across simulation, evaluation and UI.

## Verification and limits

Executed with Godot 4.7.2:

- Active `tests/validation/test_mission_presets_v2.gd`: 97 passed, zero failed.
- Active `tests/validation/test_mission_fixtures.gd`: 470 passed, zero failed, including exact sample mass boundaries.
- Active `tests/native_expansion_contract.gd`: Communication and Weather cases passed, including canonical fields, counts, same-orbit control, positive-data shortfall, predictions, abort, input immutability and forged/missing evidence rejection.
- Isolated cross-folder probe: reproduced adapter rejection, candidate revision rejection, unavailable consumer count mapping and acceptance of inconsistent supplied expanded-goal data for both missions.
- Isolated supplied `tests/ke2_comparison_api_check.gd`: 34 passed, zero failed.

The isolated project combined copied active native/runtime files with selected supplied evaluation/presentation dependencies. It did not replace active game modules. Initial candidate-only loading exposed the missing helper dependency; the completed probe then used the supplied evaluator. Tests were headless. Full owner test runners, rendered layouts, browser/export and physical mission validation were not executed. No all-folder merge compatibility is claimed.

Recommended integration order: keep the active agreed readiness/native path; update the evaluation candidate and dependencies; strengthen goal/report binding; adapt the new views with explicit native/report mapping; wire the verified comparison interface while preserving guards and historical bytes; then rerun full five-mission routes and UI-label checks.
