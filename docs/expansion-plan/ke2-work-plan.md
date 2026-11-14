# KE2 Expansion Work Plan

Markdown tracking version of the eight-page KE2 plan. Starting revision is `features/KE2` at `4c65496`. Follow the [team scope](team-scope-v2.md) and record results in the [progress record](progress.md).

KE2 owns evaluation, scores, event-supported feedback, comparison logic, and source-ledger coordination. Keep Godot 4.7.2, GDScript, local JSON, Compatibility rendering, deterministic steps, and existing signed behavior. Proposed expansion rules and estimates need coordination with their affected producers and consumers.

The first planned result is a Survey report with both aggregate goals met and one selected target lacking a complete delivery. Existing engine counters support preparing that example.

## 00 Contracts and handoffs

- [x] **00.1 Pin the starting revision and regression baseline.**
  - [x] Record branch `features/KE2` and commit `4c65496`.
  - [x] Inspect the signed agreement, current schema, evaluator, runtime, and active Debrief route.
  - [x] Record the existing local `.gitignore` edit and baseline of 38 passing check programs.
  - [x] Review the five declared evaluator pending cases and record relevant checks to rerun.

Completed by the baseline note and verification references in the [progress record](progress.md#baseline-and-verification). This is baseline preparation completed before expansion implementation.

- [ ] **00.2 Agree objective and goal fields with KE1 and SE.**
  - [x] Draft the [KE1/SE configuration handoff](ke1-se-config-handoff.md) with source-inspected current behavior, proposed IDs/fields, candidate valid and invalid examples, and open owner decisions.
  - [x] Record the user's agreement on the five mission IDs and objective-specific goal meanings on 15 November 2026.
  - [x] Review KE1's K20 draft and document the [four remaining interface differences](k20-ke2-interface-review.md) with recommendations and a concrete candidate Communication starter.
  - [x] Record KE1's confirmation of config v2, K20 nested goal names, root preset identity/revision, and the specified Communication starter, as reported by the user on 15 November 2026.
  - [x] Receive KE1's candidate registry, catalog API, tests, exact revision, and expected results, then inspect them against the confirmed interface. [Draft-2 receipt/review](ke1-k20-draft2-receipt-review.md): hashes verified; 629 supplied checks reproduced in isolation, plus 265 checks for a same-config surrogate control.
  - [x] Record SE's production-readiness review and confirmation that separate Save A/B storage and navigation can start. The [review response](ke1-se-config-handoff.md#se-review-and-work-that-can-proceed) records owner outputs and required integration evidence.
  - [ ] Keep existing `imaging` and `survey` inputs compatible.
  - [ ] Set exact new objective and preset IDs, target cardinality, duration, positive goal fields, and input-error behavior.
  - [x] Confirm that both existing Imaging presets and Polar Ice Survey retain their current settings. Draft-2 catalog checks preserve all three legacy configs; both Imaging configs also equal the measured actual card configs. Coordinated v2 migration remains open.
  - [x] Share one valid config and one invalid-input example with KE1 and SE. User reported sending the configuration handoff on 15 November 2026.
  - [ ] Coordinate corresponding agreement, contract, example, validator, adapter, and consumer changes.

Complete when the affected owners use the same examples and field meanings. Current validation rejects unknown config fields.

Draft prepared on 15 November 2026 at `4c65496` and shared with KE1/SE as reported by the user. IDs and goal meanings are user-confirmed. KE1's four K20 interface choices are confirmed, and the draft-2 registry/API/tests and measured evidence have now been received and independently checked at `8b76b5d`. Remaining bounds/custom-identity decisions, SE/HPC alignment, production updates and integrated compatibility checks stay open. See the [receipt/review](ke1-k20-draft2-receipt-review.md). Existing Imaging task 10.1 is complete.

- [ ] **00.3 Agree the evidence interface with HPC.**
  - [x] Draft the [HPC evidence handoff](hpc-evidence-handoff.md) by inspecting engine, adapter, planner, and runtime fields, with a hashed excerpt of existing local integration evidence and explicit missing-field requests.
  - [ ] Obtain terminal state, ordered events, stable event IDs, step indices, target IDs, returned MB, and observation revolution identity or mapping.
  - [ ] Define accepted-event semantics and test-payload generation.
  - [ ] Agree resource-extrema sampling boundaries, including initial and terminal samples as applicable.
  - [ ] Obtain a real trace excerpt and feasible run plan with field explanations.
  - [x] Distinguish the orbit preset ID from the revolution index used for Weather visits. Planner computes the index, while native events omit it. HPC confirmation of the accepted-event step mapping remains pending.

Complete when KE2 can explain which recorded fact supports each new count and measure.

Prompt 00.3's source trace and draft request were completed on 15 November 2026. Existing event/packet behavior is documented with a copied real-record excerpt. HPC agreement on new-objective evidence, resource sampling, and feasible success/shortfall traces remains open. The next independent planning prompt is 00.4.

- [ ] **00.4 Agree reports and comparison with KE3 and SE.**
  - [x] Supply a proposed report example for each of the four goal types. The [KE3 reports/A/B handoff](ke3-ke2-results-ab-handoff.md) contains actual Imaging reports and engine-backed proposed Survey, Communication, and Weather examples with production replies retained separately.
  - [ ] Identify existing report fields required by current callers and preserve their behavior during migration.
  - [ ] Agree comparison eligibility and requested action-policy identity with SE and HPC.
  - [x] Define the minimum independent record retained for saved A. The [handoff proposal](ke3-ke2-results-ab-handoff.md#proposed-record-and-eligibility-contract-for-se-hpc-and-ke3) lists identity, snapshots/versions, readiness, operations, resource samples, and objective evidence. SE/HPC agreement and storage implementation remain open.
  - [ ] Verify KE3 can render one report and SE can describe the snapshot/comparison inputs.

The 15 November response includes eight direct headless module executions, a source-hashed JSON packet, and a measured one-radio Imaging pair. Production Survey evaluation still errors, the new objective configs fail readiness, and comparison remains null. Proposal preparation is complete for the checked subtasks. Production evaluation/comparison, owner agreement, active UI integration, and saved-A lifecycle remain open.

## 10 Imaging and Survey

- [x] **10.1 Pin both Imaging regressions.**
  - [x] Exercise Estuary Watch with its actual config, target, thresholds, and schedule.
  - [x] Exercise Tropical Forest Watch with its own config, target, thresholds, and schedule.
  - [x] Verify raw actuals, status, existing score calculation, and goal labels for each.

Complete when both presets retain their configured meaning and expected outcomes.

Verified at `8b76b5d`: actual preset buttons through native runs, publication and headless Debrief pass 53 checks. Estuary returns 60 MB / success / 100; Tropical Forest returns 44.3200000032 MB / partial / 87. See the [baseline and report review](imaging-baseline-and-report-review.md) for commands, source-bound evidence and remaining owner dependencies.

- [ ] **10.2 Read complete deliveries for selected Survey targets.**
  - [x] Read selected targets from the launch configuration and deliveries from `observations_delivered_by_target` in a private, unwired preparation helper with snapshot binding.
  - [x] Count each selected target once when at least one complete observation is explicitly recorded, retaining its actual delivery count. Fixture checks cover extra/unrelated deliveries, repeatability and input preservation.
  - [ ] Confirm absent-target entries with HPC and distinguish them from an unavailable delivery map.
  - [x] Verify partial packets do not qualify, complete packets do qualify, and unrelated targets contribute zero. Native packet checks leave sparse entries unavailable; explicit fixture counters cover multi-target counting.

Step 8 preparation is verified: evaluator 254 passed / 0 failed / 5 existing pending, Imaging 53 passed, adapted Results 17 passed. See [implementation boundary, commands and remaining inputs](survey-delivery-measure-step8.md). The user reports HPC has not replied. Missing selected entries remain errors in the private helper; public Survey evaluation and scoring are unchanged. Parent 10.2 remains open for owner-confirmed semantics and integration.

- [ ] **10.3 Add the Survey verdict and score.**
  - [ ] Agree three equally weighted capped ratios for captures, returned MB, and selected targets with complete deliveries.
  - [ ] Define qualifying progress for partial and failed outcomes with the team.
  - [ ] Implement success only when every required goal is met.
  - [ ] Preserve raw aggregate and per-target actuals and round the score once with halves upward.
  - [ ] Verify both aggregate goals met plus one of two target deliveries produces `partial` and `83` under the agreed proposed weights.

The proposed score is `round_half_up(100 * (capture_ratio + data_ratio + delivered_target_ratio) / 3)`. Existing Imaging scoring retains its current two-goal rule.

- [ ] **10.4 Verify the one-target preset and multi-target input.**
  - [ ] Run the current Arctic Ice preset through real validation, engine, evaluator, and presentation.
  - [ ] Exercise a valid two-target Survey setup supplied by KE1.
  - [ ] Verify a real shortfall and a feasible completion with every selected target delivered.
  - [ ] Give KE3 a Survey report containing target IDs, actuals, requirements, verdict, score, and supporting event references.

When using fixtures first, label their provenance and record the corresponding real HPC run still needed.

## 20 Communication and Weather Monitoring

The proposed thresholds remain three orbits, a qualifying count of two, and 12 MB until KE1/HPC demonstrate feasible runs.

- [ ] **20.1 Count successful Communication steps.**
  - [ ] Count distinct step indices for accepted Transmit events with positive returned MB.
  - [ ] Count multiple positive steps in one continuous contact window individually.
  - [ ] Deduplicate positive evidence entries for the same step.
  - [ ] Exclude rejected and zero-MB attempts.
  - [ ] Agree equal weighting for qualifying count and returned MB, plus partial-result semantics.
  - [ ] Confirm Observe-generated test payloads and event fields with HPC.

- [ ] **20.2 Prove the Communication threshold.**
  - [x] Inspect KE1's exact fast-radio stock candidate and reproduce its native surrogate mechanics: 1120 g / 89 credits; 24 MB over steps 7/10, plus a same-config count-only shortfall of 12 MB at step 7. [Evidence and limitations](ke1-k20-draft2-receipt-review.md#independent-rerun-and-same-config-control). Typed v2 readiness and HPC acceptance remain open.
  - [ ] Obtain a valid stock design from KE1.
  - [ ] Obtain a real three-orbit trace returning at least 12 MB over at least two qualifying steps.
  - [ ] Obtain a real shortfall that isolates a missed requirement.
  - [ ] Reconcile qualifying steps and total returned MB with the evaluated report.
  - [ ] Record the frozen or revised thresholds with KE1/HPC.

- [ ] **20.3 Count repeat Weather observations.**
  - [ ] Count distinct revolutions for accepted successful captures of the selected region.
  - [ ] Use an HPC revolution index or an explicitly agreed mapping such as `floor(step_index / steps_per_orbit)` using the accepted observation event's step.
  - [ ] Deduplicate repeated captures in the same revolution and exclude other regions.
  - [ ] Surface missing revolution evidence according to the agreed contract.
  - [ ] Agree equal weighting for revolution visits and returned MB, plus partial-result semantics.

The existing `orbit_id`, such as `high_inc`, identifies the orbit preset throughout a run. Agree the distinct revolution representation in task 00.3.

- [ ] **20.4 Prove the Weather threshold.**
  - [ ] Obtain a valid stock design and a real three-orbit trace with two selected-region revolution visits and at least 12 MB returned.
  - [ ] Obtain a shortfall with sufficient returned MB but captures restricted to one revolution.
  - [ ] Verify engine, report, and Debrief agree on region, visits, MB, and outcome.
  - [ ] Record the frozen or revised thresholds with KE1/HPC.

Describe Communication through qualifying transmit steps and Weather through repeat observation. Keep packet delivery and returned MB distinct in the evidence.

## 30 Reports and feedback

- [ ] **30.1 Define objective-aware goal progress.**
  - [x] Review the existing additive report proposal against live consumers and verify four labeled examples, source hashes and legacy-field compatibility at `8b76b5d`. See the [review](imaging-baseline-and-report-review.md#report-proposal-review); owner agreement and production migration remain open.
  - [ ] Preserve the evaluation envelope, execution identity, terminal status, and authoritative score.
  - [ ] Agree a goal-progress list with stable goal ID, actual, required, unit, and met state.
  - [ ] Include selected-target Survey delivery progress.
  - [ ] Preserve required existing Imaging fields and update current consumers together.
  - [ ] Verify KE3 renders correct labels and thresholds for all four objectives.

- [ ] **30.2 Keep evaluator error and abort behavior.**
  - [ ] Preserve deterministic, scene-independent evaluation and input immutability.
  - [ ] Preserve structured errors for malformed and nonterminal inputs.
  - [ ] Preserve actuals with `status: failed` and `score: null` on abort, including abort after meeting all goals.
  - [ ] Verify invalid inputs, repeatability, no mutation, and abort-after-goals using fixtures and applicable real runs.

- [ ] **30.3 Write cause and advice rules.**
  - [ ] Cover missed communication opportunities, incomplete Survey deliveries, same-revolution Weather captures, and storage limits.
  - [ ] Explain the measured shortfall and cite relevant event IDs for specific causes.
  - [ ] Suggest one feasible next experiment.
  - [ ] Preserve neutral explanations and empty `root_causes` for insufficient, irrelevant, or unknown evidence.

The source example is "Arctic Ice has no complete delivery. Try using an available contact step to send the remaining packet." A specific missed-contact explanation requires supporting recorded evidence.

- [ ] **30.4 Verify the active presentation path.**
  - [ ] Pair with KE3 on `scripts/prototype/Screen.gd` and `scripts/presentation/` helpers.
  - [ ] Check Overview, Flight log, and Sources for all objective types.
  - [ ] Share actual source IDs and locators for material used in gameplay and advice.
  - [ ] Verify visible progress, explanation, evidence, and credit against the bound report for that execution.

## 40 A/B Design Lab

KE2 computes eligibility and differences. SE owns stored records and lifecycle. KE3 presents the result.

- [ ] **40.1 Specify the run record and compatibility check.**
  - [ ] Require completed runs and reject abort or incomplete pairs with actionable reasons.
  - [ ] Match preset, objective, targets, goals, orbit, duration, scenario/schedule, versions, and starting conditions except effects of intended design changes.
  - [ ] Match the requested action plan or policy for a controlled comparison.
  - [ ] Allow accepted-action differences caused by hardware limits under that same policy.
  - [ ] Label differing manual decisions Design + operations when other matching conditions hold.

- [ ] **40.2 Calculate measured changes.**
  - [ ] Return both outcomes, qualifying count and goal, returned MB, lowest battery, highest storage, total cost, total mass, and changed parts.
  - [ ] Compute signed B-minus-A differences for comparable numeric measures.
  - [ ] Agree resource sampling boundaries with HPC and label Wh and percent separately where applicable.
  - [ ] Display unavailable values explicitly and verify every delta against its source record.

- [ ] **40.3 Protect saved A beyond trace turnover.**
  - [ ] Have SE store report, config/catalog identity, needed evidence, action information, and measures independently of the latest-two-trace buffer.
  - [ ] Gate Save A on the actually reached completed active execution and its bound report.
  - [ ] Verify Save A, copied Builder draft, readiness validation, and fresh B run identity.
  - [ ] Verify A survives B, Cancel, Retry, reopened Results, and later trace turnover.
  - [ ] Verify deliberate replacement of A preserves historical reports and New Mission resets comparison.

SE confirmed on 15 November that the storage/navigation implementation can start while mission-expansion agreements continue. Use completed supported Imaging reports and the full saved-record proposal for initial lifecycle work. Implementation, owner commit, and actual lifecycle verification remain open.

- [ ] **40.4 Connect one loop, then broaden verification.**
  - [ ] Connect the first real Imaging Save A -> Modify design -> Run B -> Compare loop using one subsystem change and a fixed action policy.
  - [ ] Verify an actual A/B pair for Estuary Watch.
  - [ ] Verify an actual A/B pair for Tropical Forest Watch.
  - [ ] Verify an actual A/B pair for Polar Ice Survey.
  - [ ] Verify an actual A/B pair for Communication.
  - [ ] Verify an actual A/B pair for Weather Monitoring.
  - [ ] Verify session-only retention, the refresh notice, and controlled/combined comparison labels.

The PDF's illustrative radio example has A returning 8 MB and B returning 12 MB, with a +4 MB difference and actual cost/mass changes. Obtain measured values from the real paired runs.

## 50 Acceptance tests

- [ ] **50.1 Both Imaging presets.**
  - [ ] Verify success and shortfall for Estuary Watch.
  - [ ] Verify success and shortfall for Tropical Forest Watch.
  - [ ] Keep capture and returned-MB targets independent.
- [ ] **50.2 Survey target delivery.**
  - [ ] Verify aggregate goals met plus one of two deliveries gives partial / 83 under the proposed agreed weighting.
  - [ ] Complete the remaining packet and verify success.
  - [ ] Cover missing selected targets, unrelated targets, and partial packets.
- [ ] **50.3 Communication count.**
  - [ ] Rejected and zero-MB steps count zero.
  - [ ] Two positive steps in one contact window count two.
  - [ ] Duplicate evidence for one step counts once.
- [ ] **50.4 Weather visits.**
  - [ ] Two selected-target captures in one revolution and one in another count two visits.
  - [ ] Other targets contribute zero and boundary-step mapping is correct.
- [ ] **50.5 Score and validation.**
  - [ ] Test exact thresholds, over-target raw actuals, capped scores, and half-up rounding.
  - [ ] Test invalid goals, malformed evidence, and nonterminal inputs.
- [ ] **50.6 Abort and feedback.**
  - [ ] Abort after meeting goals retains failed / null score.
  - [ ] Unknown or irrelevant evidence produces neutral feedback and empty causes.
- [ ] **50.7 Comparison rules.**
  - [ ] Identical runs produce matching measures.
  - [ ] Changed scenario blocks comparison.
  - [ ] Different manual actions receive the combined label.
  - [ ] Aborted pairs are ineligible.
- [ ] **50.8 Record integrity.**
  - [ ] Duplicate terminal notifications and Results reentry preserve one report per run.
  - [ ] Retry creates a new run ID.
  - [ ] Cancel, A replacement, and trace turnover preserve saved/historical records appropriately.
- [ ] **50.9 Public browser build.**
  - [ ] From a fresh visit, verify success, shortfall, and an A/B pair for Estuary Watch.
  - [ ] From a fresh visit, verify success, shortfall, and an A/B pair for Tropical Forest Watch.
  - [ ] From a fresh visit, verify success, shortfall, and an A/B pair for Polar Ice Survey.
  - [ ] From a fresh visit, verify success, shortfall, and an A/B pair for Communication.
  - [ ] From a fresh visit, verify success, shortfall, and an A/B pair for Weather Monitoring.
  - [ ] Verify refresh clears the session pair and record the deployed revision and public URL.

Record revision, preset/scenario, verification level, run IDs, requirements, expected and actual report values, supporting event IDs, commands/browser steps, and result. Record an owner and missing dependency for any unavailable check.

## 60 Eight-hour schedule and release

| Elapsed target | KE2 work and checkpoint |
| --- | --- |
| H+00:00-00:30 | 00.1-00.4, baseline and shared config/evidence/report/comparison fields |
| H+00:30-02:00 | 10.1-10.3 and 30.1, Survey draft and worked reports for four objectives, Communication/Weather fixtures while HPC proves stock designs |
| H+02:00-04:00 | 10.4, 20.1-20.4, and 40.1-40.3, five actual reports and one integrated A/B loop |
| H+04:00-06:00 | 30.2-30.4, 40.4, and 50.1-50.8, feedback, five real preset pairs, lifecycle, and presentation |
| H+06:00-07:00 | Correctness fixes, affected-check reruns, Web candidate with SE, and one supported comparison rehearsal |
| H+07:00-08:00 | Final relevant checks, public-browser acceptance when available, tested revision, evidence, and open items |

- [ ] RELEASE.1 Record final affected checks and reconcile the five original pending declarations with actual evidence.
- [ ] RELEASE.2 Have SE confirm the Netlify URL, deployed revision, and matching Godot Web templates.
- [ ] RELEASE.3 Record Windows, local Web, and public Netlify results by environment.
- [ ] RELEASE.4 Rehearse a measured design-improvement story and record unfinished core work with owners.

The initial reported baseline has 38 passing programs, 48 acceptance checks, 23 merge checks, 207 evaluator passes, and five evaluator pending declarations. Record the Windows certificate-store diagnostic if it recurs. The inspected machine has a Web preset and an empty export-template directory.

If time slips, cut charts and extra advice rules first. Preserve five playable presets, completed Survey scoring, basic A/B measures, and one supported explanation.

## Ownership and source references

| Owner | Handoff paths |
| --- | --- |
| KE2 | `scripts/evaluation/mission_evaluator.gd`, `mission_feedback.gd`, optional `mission_comparison.gd`, evaluator checks, and `data/nasa_sources.json` |
| KE1 | Catalogs, configuration validation, and stock designs |
| HPC | `core/MissionStepEngine.gd`, `HPCContractAdapter.gd`, orbit/window evidence, and trace semantics |
| SE | `scripts/MissionController.gd`, `scripts/integration/mission_runtime.gd`, `mission_results.gd`, lifecycle/storage, and export |
| KE3 | `scripts/prototype/Screen.gd` and `scripts/presentation/` |

When a producer handoff is pending, continue independent work with labeled agreed-contract fixtures and record the real evidence still needed. The planning sources are the supplied KE2 PDF, the [team scope v2](team-scope-v2.md), and checkout/verification notes for `4c65496`.
