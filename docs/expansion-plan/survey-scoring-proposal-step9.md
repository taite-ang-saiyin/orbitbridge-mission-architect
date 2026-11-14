# Step 9 Survey scoring proposal and Step 10 checkpoint

Prepared on 15 November 2026 at `features/KE2`, HEAD `f04ab662e19c3ada6fdbd2240e355f27541a9e46` plus local changes. The user requested starting the next scoring task. Prompt 10.3 explicitly permits a labeled scoring fixture while the weighting decision is unresolved. This records completed prototype/checkpoint work, not production rule ratification.

## Implemented prototype

[The fixture-only assessment](../../tests/fixtures/ke2_survey_scoring_proposal.gd) calls Step 8's private delivery measure and applies the proposed three equally weighted capped ratios. It returns `ok/proposal`, always labeled `not_for_publication`, and never a MissionReport. Only the evaluator test suite imports it; runtime, evaluator production code, consumers and shared contracts are unchanged.

For completed fixtures, success requires all three ratios to reach 1. Partial requires progress in at least one scored measure with a goal unmet; failed means no progress. The score is `floor(100 * (capture_ratio + returned_mb_ratio + delivered_target_ratio) / 3 + 0.5)`, calculated once after capping each ratio. Raw aggregate and per-target actuals remain unchanged. Aborted fixtures retain actuals, return failed and have a null score, including after meeting all goals.

| Labeled counter fixture | Actuals and goals | Expected / actual proposal |
| --- | --- | --- |
| Missing selected target | Captures 2/2, returned MB 12/12, complete deliveries for 1/2 selected targets | partial / 83 |
| All goals met | 2/2, 12/12, 2/2 | success / 100 |
| No progress | 0/2, 0/12, 0/2 | failed / 0 |
| Capture-only progress | 1/2, 0/12, 0/2 | partial / 17 |
| Excess captures | 7/2, 0/12, 0/2 | partial / 33 |
| Excess captures/MB and extra delivery to one target | 7/2, 120.5/12, selected-target counters 3 and 0 | partial / 83; raw counts/MB retained |
| Both selected targets delivered, aggregate goals unmet | 2/4, 24/60, 2/2 | partial / 63 |

These are explicit numerical fixtures, not native traces or readiness-approved missions. Other boundary cases deliberately exercise arithmetic: two complete terms plus returned MB `100.999/200`, `101/200`, `101.001/200` give 83, 84 and 84; `199/200` may round to 100 while remaining partial. A completed-looking state at the wrong step, nonterminal state, malformed/zero goals and malformed actuals return structured errors. Numeric validation precedes snapshot comparison so NaN is reported at its invalid numeric field.

The helper requires explicit selected-target delivery counters. An omitted key still returns unavailable evidence; the prototype never converts a native sparse omission to zero. It reuses Step 8's reviewed minimum-one scope, launch-snapshot binding, selected-target ordering and invalid-counter handling. Behavior for an aborted record lacking required delivery evidence is not ratified by the all-evidence-present abort fixture.

## Commands and results

Confirmed Godot `4.7.2.stable.mono.official.ed1daf0bf` before checks. From the project root:

```powershell
$godot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $godot --version
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/test_mission_evaluator.log' --script res://tests/test_mission_evaluator.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_imaging_presets_check.log' --script res://tests/ke2_imaging_presets_check.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_results_integration.log' --script res://tests/ke2_results_integration.gd
git diff --check
```

Expected and actual final results: evaluator **294 passed / 0 failed / 5 existing pending**, including 40 new scoring-proposal assertions; Imaging presets **53 passed / 0 failed**; adapted Results **17 passed / 0 failed**. All three test programs exited 0. Source/log hashes and counts are in the [verification record](evidence/survey-scoring-step9-checks.json). `git diff --check` passed. The certificate-store diagnostic persists. The five original pending declarations were not removed or treated as resolved by this prototype.

The new scoring assertions are fixture-only. The evaluator suite also reruns existing native packet/engine checks, and the Imaging suite reruns actual buttons/native modules/headless Debrief: Estuary remains success/100, Tropical Forest partial/87. No new native Survey scoring, production v2 report, full suite, exported build or browser acceptance was performed. Existing unrelated local handoff/version/evidence work was preserved.

## Step 10 / 60.2 review checkpoint

Reused the [four worked examples](evidence/report-examples-proposal.json), [v2 format candidates](evidence/report-examples-v2-proposal.json), [Imaging baseline](imaging-baseline-and-report-review.md), [Step 8 measure](survey-delivery-measure-step8.md) and [KE1 draft-2 evidence](ke1-k20-draft2-receipt-review.md). No duplicate report format or claim of actual expanded-objective publication was introduced.

| Worked report | What came from native execution | Proposed/remaining behavior |
| --- | --- | --- |
| Imaging | Custom one-orbit actual report partial/81; actual cards remain success/100 and partial/87 | Additive goals/report-v2 migration is a proposal |
| Survey | Native captures 2, returned MB 15.466666665600002, partial/full packet evidence | Example partial/83 is proposed; missing-target zero interpretation and production Survey evaluation remain open. The new explicit-counter fixture verifies the arithmetic |
| Communication | Original low_eq Imaging proxy returns 18.466666668 MB in one positive step. New KE1 high_inc surrogate/control independently return 24/12 MB in two/one steps | Example partial/75 is proposed count/data scoring. Typed Communication integration/HPC confirmation remain open |
| Weather | Imaging proxy returns 22.1600000016 MB; accepted captures lie in one candidate revolution | Example partial/75 is proposed. HPC must confirm mapping and provide real Weather success/shortfall traces |

Highest-priority producer handoff is HPC's missing/sparse Survey-map rule, followed by exact contact/revolution evidence and Weather success/shortfall traces. KE1 has supplied the registry and feasible Communication mechanics; another request for those same files is unnecessary. SE's pending report-version/serialization/storage details and KE3's dynamic-consumer implementation remain distinct dependencies. The [SE review](se-report-review-and-version-proposal.md) records the actual JSON-key issue and prepared evidence bundle.

The next route entry is Step 11 / 10.4, actual Survey integration, when matching modules/decisions are ready. Independent KE2 work can also advance Step 12 / 20.1's Communication counting fixtures using recorded accepted-event fields while retaining HPC confirmation status. Do not report those fixtures as production Communication acceptance.

## Remaining completion boundary

- KE2 with affected owners: settle the proposed scoring/progress rule before production 10.3 publication. The request to start authorized this local prototype; it did not settle all shared rules.
- HPC: confirm sparse/absent-map and packet semantics, so native shortfalls can be interpreted without invented zeros.
- KE1/SE/HPC: coordinate real config-v2 acceptance and frozen snapshots; KE2/KE3/SE coordinate report version/revision and consumers.

10.3's fixture implementation and checks, and 60.2's review output, are complete. Parent 10.3 and actual Survey acceptance remain open. No additional files were needed to perform this prototype work and no remote action was taken.
