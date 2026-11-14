# KE2 implementation checklist

Owner: KE2  
Planning basis: v0.5-draft, reviewed 14 November 2026  
Current stage: contract review and implementation planning

Use the team's recorded decisions to update pending tasks and expected results. The API names and policies below follow the current draft. Independent preparation and labeled provisional fixtures can proceed while producer mappings are being agreed. Mark a task complete when its stated evidence is available. Record blocked tasks with the dependency owner and missing input.

References are the [v0.5 agreement](<team-agreement (5).md>) and [implementation prompts](prompts.md). Earlier prompts use older field names, uppercase outcome labels, and an earlier zero-target proposal. Reconcile these with the agreed contract when implementation begins.

## 1. Preparation and contract decisions

- [x] Inspect the current checkout, existing changes, scripts, scenes, and test entry points.
- [x] Review v0.5 against KE2's earlier requests.
- [x] Parse the four JSON examples and verify Example 3's score of 88 and Example 4's null abort score.
- [ ] Resolve KE2's remaining contract review items with the affected owners.
  - [ ] Correct Example 3's explanation and supply the referenced `evt_007` in matching input evidence.
  - [ ] Agree the feedback segment vocabulary, including the segment for power/storage failures.
  - [ ] Specify where the evaluator reads a recorded abort reason and how it handles an absent reason.
  - [ ] Correct Example 4 to match recorded evidence or use neutral abort feedback.
  - [ ] Define `EvaluationError.run_id` nullability and how suggested corrections reach the UI.
  - [ ] Align Section 11's renderer statement with Section 2 and SE's actual branch/configuration.
- [ ] Record the agreed evaluator signature, result envelope, field names, types, and nullability.
  - [ ] Confirm `MissionEvaluator.evaluate_mission(config, final_state, events, comparison_baseline = null)` and how callers load/invoke it.
  - [ ] Confirm lowercase report statuses `success`, `partial`, and `failed`.
  - [ ] Confirm positive-only targets, capped average scoring, .5-up rounding, and abort `score: null`.
  - [ ] Confirm KE2's file ownership and the mapping owner for each producer interface.
  - [ ] Record KE2's review decision against the same revision as the other members.

Completion evidence: agreed KE2 fields/policies, corrected report examples, named mapping owners, and a recorded review decision.

## 2. Obtain producer and controller handoffs

- [ ] Receive KE1's configuration and readiness handoff.
  - [ ] Obtain valid and overweight fixtures with real component, launcher, orbit, and profile IDs.
  - [ ] Confirm `required_observations` and `required_returned_data_mb` names and allowed ranges.
  - [ ] Obtain the sample-1U source ID, strict comparator, threshold, and actual validator entry point.
  - [ ] Synchronize `docs/contracts.md`, `docs/validation-plan.md`, `docs/sources.md`, the NASA reference, and the canonical agreement when KE1 publishes them.
- [ ] Receive HPC's terminal-state and event handoff.
  - [ ] Confirm the two orbit IDs, scenario identity/version, and step duration.
  - [ ] Confirm decimal data units and the owner of Ws-to-Wh and KB-to-MB conversion.
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

- [ ] Implement `scripts/evaluation/mission_evaluator.gd` against the confirmed KE2 contract.
  - [ ] Use a scene-independent, deterministic entry point and fresh output dictionaries.
  - [ ] Validate required fields, supported schema/status values, finite nonnegative actuals, positive targets, and integer counts.
  - [ ] Return the agreed error envelope for malformed and nonterminal inputs.
  - [ ] Read targets from the launch snapshot and actuals from HPC's authoritative terminal counters.
  - [ ] Calculate capped completion ratios and the equal-weight score with one .5-up rounding operation.
  - [ ] Derive status from raw actuals and preserve actual values above targets.
  - [ ] Preserve aborted-run counters, return a null score, and supply the agreed abort wording.
  - [ ] Populate `explanation`, `root_causes`, `next_experiment`, `source_ids`, and nullable `comparison`.
  - [ ] Verify inputs and the comparison baseline retain their original values after evaluation.
- [ ] Prepare labeled synthetic fixtures for success, partial, failed, aborted, and invalid input.
  - [ ] Pair supported causes with the exact input events referenced by the report.
  - [ ] Supply KE3 with expected report fields and their display meanings.

Completion evidence: the same evaluator entry point produces expected reports from isolated fixtures.

## 4. Implement and run automated checks

- [ ] Add the agreed headless runner at `tests/test_mission_evaluator.gd`.
  - [ ] Print case IDs and expected/actual values on failures.
  - [ ] Exit zero when every executed case passes and nonzero on failure.
  - [ ] Verify a deliberate failed expectation produces a failure exit code, restore it, and rerun.
  - [ ] Exercise missing fields, negative values, nonfinite values, fractional counts, wrong types, and nonterminal states.
  - [ ] Verify repeated identical inputs produce identical results and preserve inputs.
  - [ ] Add evidence, adapter, and comparison cases as those features become available.
- [ ] Run and record the acceptance cases below using the final agreed rules.

The table follows v0.5's proposed policy. Unless specified otherwise, targets are 3 captured observations and 30 MB received on Earth. Scores are whole points.

| Case | Input or action | Expected result | Execution owner |
| --- | --- | --- | --- |
| T01 | Completed, 3 observations, 30 MB returned | `success`, 100 | KE2 |
| T02 | Completed, 3 observations, 10 MB returned | `partial`, 67 | KE2 |
| T03 | Completed, 3 observations, 30 MB stored, 0 MB returned | `partial`, 50, returned actual remains 0 | KE2 |
| T04 | Completed, 0 observations, 0 MB returned | `failed`, 0 | KE2 |
| T05 | Completed, 4 observations, 30 MB returned | `success`, 100, actual count remains 4 | KE2 |
| T06 | Observation target 4, actual 3, returned 30 MB | `partial`, 88 | KE2 |
| T07 | Eligible retry, returned data 10 to 30 MB | +20 MB, +33 points, 0 observation delta | KE2, optional P1 |
| T08 | No eligible baseline | `comparison: null` | KE2 |
| T09 | Returned-data shortfall and relevant blocked-transmit event | Feedback references the matching code/event and action | KE2 |
| T10 | Missing, unknown, or irrelevant cause evidence | Neutral explanation, empty causes, concrete next experiment | KE2 |
| T11 | Sample 1U profile at 1329 g, other checks valid | Mass check passes through KE1's actual validator | KE1 + KE2 + SE |
| T12 | Sample 1U at 1330 g and 1331 g, plus another profile | Sample mass check fails at both boundaries, other profile uses its rules | KE1 + KE2 + SE |
| T13 | Either target zero | Agreed input error under v0.5 positive-only policy | KE2, align with KE1 |
| T14 | Aborted, including after both targets were reached | `run_status: aborted`, `status: failed`, null score, actuals preserved | KE2 |

Use the confirmed Godot executable with the proposed command below, adjusted if the repository gains a shared runner.

```powershell
godot --headless --path . --script res://tests/test_mission_evaluator.gd
```

Completion evidence: exact command, engine version, case results, and exit code. Record integration cases as pending until their real producer/UI path is available.

## 5. Add evidence-based feedback

- [ ] Implement feedback in the evaluator or optional `scripts/evaluation/mission_feedback.gd`.
  - [ ] Match HPC-confirmed codes and actions to the unmet observation or returned-data goal.
  - [ ] Handle `NO_LINK_WINDOW`, `LOW_BATTERY`, `STORAGE_FULL`, and `TARGET_NOT_VISIBLE` according to confirmed semantics.
  - [ ] Retain event IDs, steps, and the agreed mission segment in supported cause records.
  - [ ] Choose relevant events in a stable, documented order.
  - [ ] Generate neutral text when events are missing, unknown, irrelevant, or insufficient.
  - [ ] Use only the recorded abort reason for an asserted termination cause.
  - [ ] Provide one concrete next experiment that follows from the evidence or evidence gap.
  - [ ] Acknowledge met goals on successful runs and suggest a trade-off to explore.
  - [ ] Run T09/T10 plus irrelevant-event, tie-ordering, and abort-evidence cases.

Completion evidence: each asserted cause resolves to supplied evidence, and insufficient evidence yields the documented fallback.

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
| Corrected examples and final KE2 error/feedback fields | KE1 + KE2 + HPC + KE3 | Pending final review corrections |
| Shared contract and reference synchronization | KE1 | Pending files in this checkout |
| Scenario IDs, units, step/energy/abort rules, and real trace | HPC + KE1 | Pending confirmed mapping and sample |
| Controller migration and report/retry calls | SE + HPC + KE3 + KE2 | Pending agreed call sites |
| Results/credits display and export verification | KE3 + SE + KE2 | Pending runtime integration |
