# KE2 implementation checklist

Owner: KE2  
Planning basis: v1.0-agreed, updated 14 November 2026

Current stage: Prompts 2-5 complete; NASA source-ledger work next

Update this checklist after each KE2 task. Use the team's recorded decisions to update pending tasks and expected results. The API names and policies below follow the agreed v1 contract. Independent preparation and labeled fixtures can proceed while runtime handoffs are being implemented. Mark a task complete when its stated evidence is available. Record blocked tasks with the dependency owner and missing input.

References are the [signed agreement](team-agreement.md), [technical contract](contracts.md), [validation plan](validation-plan.md), and [implementation prompts](prompts.md). Earlier prompts use older field names, uppercase outcome labels, and an earlier zero-target proposal. Apply v1.0's lowercase statuses and positive-only targets.

## 1. Preparation and contract decisions

- [x] Inspect the current checkout, existing changes, scripts, scenes, and test entry points.
- [x] Review v0.5 against KE2's earlier requests.
- [x] Parse the four JSON examples and verify Example 3's score of 88 and Example 4's null abort score.
- [ ] Resolve KE2's remaining contract review items with the affected owners.
  - [x] Correct Example 3's explanation and supply the referenced `evt_007` in matching input evidence.
  - [x] Apply Prompt 5's requested launch/space/ground/user vocabulary: link-window feedback uses ground; power/storage/visibility feedback uses space.
  - [ ] Confirm HPC's runtime abort-reason mapping. Optional `final_state.abort_reason` text or a dictionary `message` is supported; missing or unusable metadata produces neutral abort feedback.
  - [x] Correct Example 4 to match recorded evidence or use neutral abort feedback.
  - [x] Define `EvaluationError.run_id` nullability and how suggested corrections reach the UI.
  - [x] Align Section 11's renderer statement with Section 2 and SE's actual branch/configuration.
- [x] Record the agreed evaluator signature, result envelope, field names, types, and nullability.
  - [x] Confirm `MissionEvaluator.evaluate_mission(config, final_state, events, comparison_baseline = null)` and how callers load/invoke it.
  - [x] Confirm lowercase report statuses `success`, `partial`, and `failed`.
  - [x] Confirm positive-only targets, capped average scoring, .5-up rounding, and abort `score: null`.
  - [x] Confirm KE2's file ownership and the mapping owner for each producer interface.
  - [x] Record KE2's review decision against the same revision as the other members.

Completion evidence: agreed KE2 fields/policies, corrected report examples, named mapping owners, and a recorded review decision.

## 2. Obtain producer and controller handoffs

- [ ] Receive KE1's configuration and readiness handoff.
  - [ ] Obtain valid and overweight fixtures with real component, launcher, orbit, and profile IDs.
  - [x] Confirm `required_observations` and `required_returned_data_mb` names and allowed ranges.
  - [ ] Obtain the sample-1U source ID, strict comparator, threshold, and actual validator entry point.
  - [x] Synchronize `docs/contracts.md`, `docs/validation-plan.md`, `docs/sources.md`, the NASA reference, and the canonical agreement when KE1 publishes them.
- [ ] Receive HPC's terminal-state and event handoff.
  - [ ] Confirm the two orbit IDs, scenario identity/version, and step duration.
  - [x] Confirm decimal data units and the owner of Ws-to-Wh and KB-to-MB conversion.
  - [ ] Confirm `brief.policy` handling and the `MissionConfig` adapter boundary.
  - [ ] Confirm downlink rate units, energy-update order, finished-step indexing, and low-energy `power_save` behavior.
  - [ ] Confirm event ordering, unique event references, blocked-action codes, and terminal/abort fields.
  - [ ] Obtain a trace with a successful observation, valid downlink, and blocked action.
- [ ] Confirm SE/KE3's controller and Results handoff.
  - [ ] Identify the actual initialize/action/evaluate/render call sites.
  - [ ] Confirm launch snapshots, one report per run, retry baseline retention, and New Mission reset.
  - [ ] Confirm prototype-field migration and final selected mission requirements reach evaluation.

Completion evidence: versioned sample inputs and named call sites. Track unavailable samples against their producer.

## 3. Implement the evaluator and report

- [x] Implement `scripts/evaluation/mission_evaluator.gd` against the confirmed KE2 scoring contract.
  - [x] Use a scene-independent, deterministic entry point and fresh output dictionaries.
  - [x] Validate consumed fields, supported schema/status values, finite nonnegative actuals, positive targets, duration, integer counts, and terminal-step consistency.
  - [x] Return the agreed error envelope for malformed and nonterminal inputs.
  - [x] Read targets from the launch snapshot and actuals from the agreed HPC terminal-counter fields, verified with synthetic inputs.
  - [x] Calculate capped completion ratios and the equal-weight score with one .5-up rounding operation.
  - [x] Derive status from raw actuals and preserve actual values above targets.
  - [x] Preserve aborted-run counters, return a null score, and supply the agreed abort wording.
  - [x] Populate `explanation`, `root_causes`, `next_experiment`, `source_ids`, and nullable `comparison` with neutral feedback and empty/null defaults for later features.
  - [x] Verify inputs and the comparison baseline retain their original values after evaluation.
- [ ] Prepare labeled synthetic fixtures for success, partial, failed, aborted, and invalid input.
  - [x] Construct synthetic terminal states and expected scoring/error cases in `tests/test_mission_evaluator.gd`, reusing the agreed example pack.
  - [x] Pair supported causes with the exact input events referenced by the report.
  - [ ] Supply KE3 with expected report fields and their display meanings.

Completion evidence: the same evaluator entry point produces expected reports from isolated fixtures.

## 4. Implement and run automated checks

- [x] Complete core headless runner verification.
  - [x] Add the agreed headless runner at `tests/test_mission_evaluator.gd`.
  - [x] Print case IDs and expected/actual values on failures.
  - [x] Exit zero when every executed case passes and nonzero on failure.
  - [x] Verify a deliberate failed expectation produces a failure exit code, restore it, and rerun.
  - [x] Exercise missing fields, negative values, nonfinite values, fractional counts, wrong types, and nonterminal states.
  - [x] Verify repeated identical inputs produce identical results and preserve inputs.
  - [x] Review literal expectations against the agreed contract and verify report fields independently of the evaluator's mock helper.
  - [x] Check each goal's ratio cap, half-up rounding boundaries, positive progress rounding to zero, whole-valued JSON numbers, and fractional MB requirements.
- [x] Add evidence-selection and neutral-fallback cases for the feedback module.
- [ ] Add adapter and comparison cases as those features become available.
- [ ] Run and record the acceptance cases below using the final agreed rules.

The table follows v1.0-agreed. Unless specified otherwise, targets are 3 captured observations and 30 MB received on Earth. Scores are whole points. Passed results below come from the headless evaluator runner using synthetic inputs.

| Case | Input or action | Expected result | Execution owner | Verification status |
| --- | --- | --- | --- | --- |
| T01 | Completed, 3 observations, 30 MB returned | `success`, 100 | KE2 | Passed |
| T02 | Completed, 3 observations, 10 MB returned | `partial`, 67 | KE2 | Passed |
| T03 | Completed, 3 observations, 30 MB stored, 0 MB returned | `partial`, 50, returned actual remains 0 | KE2 | Passed |
| T04 | Completed, 0 observations, 0 MB returned | `failed`, 0 | KE2 | Passed |
| T05 | Completed, 4 observations, 30 MB returned | `success`, 100, actual count remains 4 | KE2 | Passed |
| T06 | Observation target 4, actual 3, returned 30 MB | `partial`, 88 | KE2 | Passed |
| T07 | Eligible retry, returned data 10 to 30 MB | +20 MB, +33 points, 0 observation delta | KE2, optional P1 | Pending comparison |
| T08 | No eligible baseline | `comparison: null` | KE2 | Pending dedicated comparison check |
| T09 | Returned-data shortfall and relevant blocked-transmit event | Feedback references the matching code/event and action | KE2 | Passed with the four recognized codes/actions and signed evt_007 fixture |
| T10 | Missing, unknown, or irrelevant cause evidence | Neutral explanation, empty causes, concrete next experiment | KE2 | Passed, including malformed, conflicting, and foreign-run evidence |
| T11 | Sample 1U profile at 1329 g, other checks valid | Mass check passes through KE1's actual validator | KE1 + KE2 + SE | Pending actual validator/UI |
| T12 | Sample 1U at 1330 g and 1331 g, plus another profile | Sample mass check fails at both boundaries, other profile uses its rules | KE1 + KE2 + SE | Pending actual validator/UI |
| T13 | Either target zero | Agreed input error under v1.0 positive-only policy | KE2, align with KE1 | Passed evaluator checks; KE1 integration pending |
| T14 | Aborted, including after both targets were reached | `run_status: aborted`, `status: failed`, null score, actuals preserved | KE2 | Passed |

Use the confirmed Godot executable with the current runner command below. On another machine, substitute its Godot 4.7.2 executable path.

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $godotExe --headless --version
& $godotExe --headless --path . --script res://scripts/evaluation/mission_evaluator.gd --check-only
& $godotExe --headless --path . --script res://tests/test_mission_evaluator.gd --check-only
& $godotExe --headless --path . --script res://tests/test_mission_evaluator.gd
```

Completion evidence: exact command, engine version, case results, and exit code. Record integration cases as pending until their real producer/UI path is available.

Completed-task evidence, 14 November 2026:

- [x] Prompt 2 module setup verified with Godot `4.7.2.stable.mono.official.ed1daf0bf`: evaluator parse exit 0 and nine setup checks passed, zero failed, runner exit 0. User also confirmed the checks run successfully.
- [x] Prompt 3 scoring verified with the same executable: evaluator parse exit 0 and 80 checks passed, zero failed, runner exit 0. Coverage includes the nine agreed scoring vectors, T01-T06, zero-target rejection, aborts, invalid numeric inputs, capped ratios, determinism, and input preservation.
- [x] Prompt 4 independent test review and diagnostics completed with the same executable. Restored suite: 98 passed, zero failed, seven pending groups, exit 0. Expected JSON scores are normalized from finite whole floats to the contract's integer representation; fractional expectations are rejected.
- [x] Prompt 4 deliberate failure verified: temporarily changed T01's expected score from 100 to 99. The runner displayed expected 99 and actual 100, reported 97 passed and one failed, and exited 1. Restored the original expectation before the final passing run.
- [x] Record each executed result in `tmp/ke2-prompt4-tests.log` and the deliberate failure in `tmp/ke2-prompt4-intentional-failure.log`. Both logs are local generated artifacts.
- [x] Prompt 5 feedback implemented in `scripts/evaluation/mission_feedback.gd` and connected to the evaluator. Godot 4.7.2 parsed both modules through the evaluator/test runner; the complete suite passed 143 checks with zero failures, five pending groups, and exit 0. Per-case output is in `tmp/ke2-prompt5-tests.log`.
- [x] Confirm the four reason codes and their action semantics from cached `origin/feature/hpc-simulator` commit `ab7865c`, specifically `core/MissionStepEngine.gd`'s `_evaluate` and `_make_event`. That source emits `action_blocked`, event/run/mission IDs, and zero deltas for rejections. Additional unsupported codes such as `NO_DATA` use neutral fallback.
- [ ] Complete the five current pending groups printed by the runner: T07-T08 comparison, T11-T12 actual validator/Builder checks, and real HPC/controller/Results/retry integration.
- [x] Record the observed Windows certificate-store startup error alongside the successful smoke-run results. Graphical UI, real simulation integration, and exports await their respective verification tasks.

## 5. Add evidence-based feedback

- [x] Implement scene-independent feedback in `scripts/evaluation/mission_feedback.gd` and call it from the evaluator.
  - [x] Match source-confirmed HPC codes/actions to the unmet observation or returned-data goal.
  - [x] Handle `NO_LINK_WINDOW`, `LOW_BATTERY`, `STORAGE_FULL`, and `TARGET_NOT_VISIBLE` according to confirmed semantics.
  - [x] Retain event IDs and steps, using the requested space/ground segment mapping in supported cause records.
  - [x] Order relevant events by observation-goal priority, earliest step, then original input order. Exclude conflicting duplicate IDs and collapse identical duplicates.
  - [x] Provide neutral summaries and empty causes for missing, unknown, irrelevant, malformed, contradictory, future-step, or foreign-run evidence.
  - [x] Attribute optional recorded abort text explicitly and keep unrelated blocked actions out of abort-cause claims. Confirm the real producer field during integration.
  - [x] Provide a specific experiment for each recognized event through `explain_event`; include corrections in cause text and expose the primary correction as `next_experiment`.
  - [x] Acknowledge met goals on successful runs and suggest a trade-off to explore.
  - [x] Run T09/T10 plus irrelevant-event, tie-ordering, abort-evidence, stored-versus-returned, determinism, input-preservation, and output-copy cases.

Completion evidence: each asserted cause resolves to supplied evidence, and insufficient evidence yields the documented fallback.

Feedback handoff details: `build_feedback(report, final_state, events)` returns the existing `explanation`, `root_causes`, and `next_experiment` fields. `explain_event(event)` returns one supported cause, segment, event reference, and corrective experiment. The signed example's older `operations` segment is superseded in this implementation by Prompt 5's requested `space` vocabulary. Real producer/Results execution remains an integration task.

## 6. Prepare NASA source records and attribution

- [ ] Prepare the KE2-owned `data/nasa_sources.json` ledger.
  - [ ] Verify CubeSat 101's checklist locator and original mass criterion against the source.
  - [ ] Record title, NASA organization, official URL, printed/PDF page, source ID, original units, conversion, strict comparator, and applicable profile.
  - [ ] Record the actual validator/rule path, Builder label, credits path, and verification status as they become available.
  - [ ] Align `cubesat_101_1u_sample` with KE1's validator output and KE3's credit lookup.
  - [ ] Record CML/MDL or other resources when their concepts or material are used in the game.
  - [ ] Give SE/KE3 and the submission owner consistent attribution text.
- [ ] Verify the sample-1U mass rule with KE1 and SE.
  - [ ] Run T11/T12 through the actual validator with other readiness checks passing.
  - [ ] Confirm profile switching, visible credit, and Launch behavior.
  - [ ] Record build/commit, expected/observed values, and screenshot or log evidence.

Completion evidence: source metadata traces to an implemented rule and visible attribution. Track source verification and gameplay verification separately in the ledger.

## 7. Integrate real simulation output and Results

- [ ] Connect KE2's evaluator to the actual HPC terminal output with the affected owners.
  - [ ] Compare real fields and units against the frozen contract.
  - [ ] Add a KE2-owned adapter only where an agreed mapping is necessary.
  - [ ] Verify returned MB originates from valid ground reception and stored data stays separate.
  - [ ] Test one completed run, one blocked action, and an aborted run when supported.
  - [ ] Confirm repeated terminal notifications preserve the same report and baseline.
- [ ] Verify KE3's Results screen with SE/KE3.
  - [ ] Check actual/target values, completion ratios, status, score, and source labels against the report.
  - [ ] Check error handling, null abort scores, empty causes, neutral explanation, and absent comparison.
  - [ ] Verify a retry starts a new run and New Mission clears the old baseline.
  - [ ] Verify reopening Results or navigating back preserves the intended run history.

Completion evidence: real config, run ID, terminal trace, report, and displayed values agree. Route changes in another owner's files to that owner with the requested call/binding and verification steps.

## 8. Optional P1 retry comparison

- [ ] Implement `scripts/evaluation/mission_comparison.gd` or keep comparison within the evaluator once the core loop is stable.
  - [ ] Compare immutable previous/current reports and their scenario, target, duration, design, and action metadata.
  - [ ] Apply the agreed eligibility rules and exclude aborts from controlled comparisons.
  - [ ] Calculate current-minus-previous observation, returned-MB, and score deltas.
  - [ ] Handle null scores and missing baselines according to the contract.
  - [ ] Identify one known changed choice when supported and describe multiple/unknown changes accurately.
  - [ ] Test improvements, regressions, identical attempts, changed targets/scenarios, missing baselines, and input preservation.
  - [ ] Run T07/T08 and verify KE3's displayed deltas.
- [ ] If comparison is deferred, record the scope decision and verify Retry plus `next_experiment` still works.

Completion evidence: comparison eligibility, signed deltas, and reflection match the recorded attempts, or the optional comparison is explicitly deferred.

## 9. Final acceptance and submission handoff

- [ ] Verify the complete Creator -> Builder -> Validation -> Operations -> Results -> Retry journey.
  - [ ] Demonstrate success, partial success, failure, dynamic targets, blocked transmission, abort handling, and clean reset.
  - [ ] Confirm explanations match the actual event trace and credits match sources used.
  - [ ] Verify the selected export with SE/KE3, including the sample-1U boundary and source visibility.
  - [ ] Reproduce and route defects by owner, fix KE2 defects, and rerun affected checks.
- [ ] Prepare KE2's release evidence and submission note.
  - [ ] Record the build/commit, test command/results, real-run evidence, source verification, and remaining limitations.
  - [ ] Explain scoring, evidence-based feedback, the retry experiment, and which NASA sources were used.
  - [ ] Record optional features deferred and unresolved issues with their owners.

Completion evidence: KE2's implementation, real Results path, automated checks, and source attribution have recorded verification for the release candidate.

## Dependency tracking

Update this table as owners provide decisions or samples. A pending producer mapping can coexist with fixture-based KE2 work.

| Dependency | Owner to coordinate with | Current status / required evidence |
| --- | --- | --- |
| Final KE2 error/feedback fields and examples | KE1 + KE2 + HPC + KE3 | Implemented and fixture-tested; requested space/ground segments used; real abort-reason producer mapping pending |
| Shared contract and reference synchronization | KE1 | Complete in this checkout |
| Scenario IDs, units, step/energy/abort rules, and real trace | HPC + KE1 | Public policies agreed; cached step-engine source inspected at ab7865c and feedback code/action semantics confirmed; runtime trace and integration pending |
| Controller migration and report/retry calls | SE + HPC + KE3 + KE2 | Responsibilities and API agreed; actual call sites and runtime integration pending |
| Results/credits display and export verification | KE3 + SE + KE2 | Pending runtime integration |
