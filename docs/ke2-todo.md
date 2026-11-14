# KE2 implementation checklist

Owner: KE2  
Planning basis: v1.0-agreed, updated 14 November 2026

Current stage: SE/KE3 candidate Results integration verified at 14c0f97; stability review ready; optional comparison, Survey scoring, independent mass-boundary/Builder checks, manual actions, and release acceptance pending

Update this checklist after each KE2 task. Use the team's recorded decisions to update pending tasks and expected results. The API names and policies below follow the agreed v1 contract. Independent preparation and labeled fixtures can proceed while runtime handoffs are being implemented. Mark a task complete when its stated evidence is available. Record blocked tasks with the dependency owner and missing input.

References are the [signed agreement](team-agreement.md), [technical contract](contracts.md), [validation plan](validation-plan.md), and [implementation prompts](prompts.md). Earlier prompts use older field names, uppercase outcome labels, and an earlier zero-target proposal. Apply v1.0's lowercase statuses and positive-only targets.

KE2's implementation guide, team handoff, test instructions, and source-credit document are indexed in [KE2 documentation](ke2/README.md).

## 1. Preparation and contract decisions

- [x] Inspect the current checkout, existing changes, scripts, scenes, and test entry points.
- [x] Review v0.5 against KE2's earlier requests.
- [x] Parse the four JSON examples and verify Example 3's score of 88 and Example 4's null abort score.
- [ ] Resolve KE2's remaining contract review items with the affected owners.
  - [x] Correct Example 3's explanation and supply the referenced `evt_007` in matching input evidence.
  - [x] Apply Prompt 5's requested launch/space/ground/user vocabulary: link-window feedback uses ground; power/storage/visibility feedback uses space.
  - [x] Confirm HPC's runtime abort-reason mapping at b9817c3. Feedback reads the producer's nonempty `terminal_reason` string, then supports the earlier `abort_reason` string/dictionary fallback. Actual operator abort verified.
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

- [x] Receive KE1's configuration and readiness handoff.
  - [x] Locate valid, overweight, boundary, and alternative-profile fixtures in KE1 commit `55d4f33`, together with its runner and recorded results.
  - [x] Confirm `required_observations` and `required_returned_data_mb` names and allowed ranges.
  - [x] Obtain the sample-1U source ID, strict comparator, threshold, and actual validator entry point `MissionValidator.validate(config, catalogs)` from `55d4f33`.
  - [x] Synchronize `docs/contracts.md`, `docs/validation-plan.md`, `docs/sources.md`, the NASA reference, and the canonical agreement when KE1 publishes them.
- [ ] Receive HPC's terminal-state and event handoff.
  - [x] Inspect the two orbit IDs, scenario metadata, and step duration in pinned HPC catalogs and the v0.2 trace; execute the high_inc scenario with the real modules.
  - [x] Confirm decimal data units and the owner of Ws-to-Wh and KB-to-MB conversion.
  - [ ] Confirm `brief.policy` handling and the `MissionConfig` adapter boundary.
  - [x] Inspect hourly downlink units, solar/load energy accounting and clamp order, finished-step indexing, and low-energy `power_save` behavior against unchanged source and HPC tests at b9817c3.
  - [x] Confirm cumulative event ordering, referenced blocked-action IDs, and terminal/abort fields from real execution and the committed trace.
  - [x] Obtain a recorded trace with a successful observation, valid downlink, and blocked action. The existing `ke2-hpc-report-v0.1` handoff identifies HPC commit `ce478f94a918047c0449fe30bfffe18f368315fd` and records its evaluator verification.
- [ ] Confirm SE/KE3's controller and Results handoff.
  - [ ] Identify SE's actual initialize/action/evaluate call sites on the confirmed integration revision.
  - [x] Identify KE3's supplied Results binding, `ke3/results_control.tscn` -> `ke3/debrief_screen.gd`, using `set_inputs(context, state, report)` in its manifest-pinned recorded preview.
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
- [x] Prepare labeled synthetic fixtures for success, partial, failed, aborted, and invalid input.
  - [x] Construct synthetic terminal states and expected scoring/error cases in `tests/test_mission_evaluator.gd`, reusing the agreed example pack.
  - [x] Pair supported causes with the exact input events referenced by the report.
  - [x] Prepare KE3's report-field and display-meaning handoff in `docs/ke2/integration-handoff.md`, with links to complete recorded and synthetic payloads.

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
- [x] Add native HPC adapter cases, source/runtime field checks, completed simulation, recorded block, and actual operator abort cases.
- [ ] Add comparison cases when that optional feature is implemented.
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
| T11 | Sample 1U profile at 1329 g, other checks valid | Mass check passes through KE1's actual validator | KE1 + KE2 + SE | KE1 recorded fixture passed at 55d4f33; independent KE2 rerun/Builder pending |
| T12 | Sample 1U at 1330 g and 1331 g, plus another profile | Sample mass check fails at both boundaries, other profile uses its rules | KE1 + KE2 + SE | KE1 recorded fixtures passed at 55d4f33; independent KE2 rerun/Builder pending |
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
- [ ] Complete the five current pending groups printed by the runner: T07-T08 comparison, T11-T12 actual validator/Builder checks, and controller/Results/retry lifecycle. Standalone execution also defers the native HPC runtime portion until dependencies are present; Prompt 7 verifies it in the pinned combined project.
- [x] Record the observed Windows certificate-store startup error alongside the successful smoke-run results. Graphical UI, real simulation integration, and exports await their respective verification tasks.
- [x] Prompt 7 verified with Godot `4.7.2.stable.mono.official.ed1daf0bf`. Local runner passed 165 checks, combined pinned KE1/HPC/KE2 runner passed 205 checks, and unchanged HPC suite passed 31 checks. Every final command exited 0. Both evaluator/test parse checks exited 0. Five pending groups remain for T07/T08 comparison, T11/T12 mass boundaries/Builder, and Results/publication/retry lifecycle.
- [x] Preserve producer code at `b9817c35628a4280a899d7fa73ce551d9d4a93ba` in an ignored isolated verification project. Record byte equality and SHA256 hashes for the 19 producer/dependency files in its source manifest. Document reproduction in `docs/ke2/hpc-integration.md`.
- [x] Correct the Prompt 7 test's exact float expectation after observing 7.7333333328 versus 7.733333332800001. The reference check now uses absolute tolerance 1e-9 and a separate assertion verifies exact pass-through of the producer counter.

## 5. Add evidence-based feedback

- [x] Implement scene-independent feedback in `scripts/evaluation/mission_feedback.gd` and call it from the evaluator.
  - [x] Match source-confirmed HPC codes/actions to the unmet observation or returned-data goal.
  - [x] Handle `NO_LINK_WINDOW`, `LOW_BATTERY`, `STORAGE_FULL`, and `TARGET_NOT_VISIBLE` according to confirmed semantics.
  - [x] Retain event IDs and steps, using the requested space/ground segment mapping in supported cause records.
  - [x] Order relevant events by observation-goal priority, earliest step, then original input order. Exclude conflicting duplicate IDs and collapse identical duplicates.
  - [x] Provide neutral summaries and empty causes for missing, unknown, irrelevant, malformed, contradictory, future-step, or foreign-run evidence.
  - [x] Attribute recorded abort text explicitly and keep unrelated blocked actions out of abort-cause claims. Verify the real producer's `terminal_reason` through `abort_run` and retain the older optional metadata fallback.
  - [x] Provide a specific experiment for each recognized event through `explain_event`; include corrections in cause text and expose the primary correction as `next_experiment`.
  - [x] Acknowledge met goals on successful runs and suggest a trade-off to explore.
  - [x] Run T09/T10 plus irrelevant-event, tie-ordering, abort-evidence, stored-versus-returned, determinism, input-preservation, and output-copy cases.

Completion evidence: each asserted cause resolves to supplied evidence, and insufficient evidence yields the documented fallback.

Feedback handoff details: `build_feedback(report, final_state, events)` returns the existing `explanation`, `root_causes`, and `next_experiment` fields. `explain_event(event)` returns one supported cause, segment, event reference, and corrective experiment. The signed example's older `operations` segment is superseded in this implementation by Prompt 5's requested `space` vocabulary. Producer execution is verified in the pinned Prompt 7 project; Results integration remains pending.

## 6. Prepare NASA source records and attribution

- [x] Prepare the KE2-owned `data/nasa_sources.json` ledger.
  - [x] Verify CubeSat 101's checklist locator and original mass criterion against the source.
  - [x] Record title, NASA organization, official URL, printed/PDF page, source ID, original units, conversion, strict comparator, and applicable profile.
  - [x] Record intended implementation locations, missing paths, required Builder display, and separate source/code/gameplay/report/credit/export statuses.
  - [x] Record KE1's verified-by-inspection validator entry point and pinned source/catalog revision in the ledger.
  - [x] Record KE3's reviewed credit-rendering path and supplied source-manifest identity.
  - [ ] Obtain SE's actual Builder display path and integrated credit-routing evidence.
  - [x] Align `cubesat_101_1u_sample` with KE1's supplied validator outputs and boundary expectations.
  - [x] Verify KE3's recorded-preview scoped credit display against the supplied ledger-derived attribution metadata. Integrated/export credit checks remain pending.
  - [x] Record NASA's mission-segment reference used by feedback code; retain MDL as planning-only and exclude unverified CML/GMAT implementation claims.
  - [x] Prepare consistent attribution text and official URLs for SE/KE3 and the submission owner; external publication is pending.
  - [x] Review Prompt 6 for missing metadata, invalid JSON, conversion/boundary errors, ID mismatches, broken references, credit drift, and unsupported integration claims. Correct the original prompt's locator to Appendix C, item 6, printed p.79 / PDF p.87.
- [ ] Verify the sample-1U mass rule with KE1 and SE.
  - [x] Review KE1's pinned validator, 15-case manifest, runner, and recorded log. Its 470-check fixture suite records the strict boundary and alternative-profile cases passing.
  - [ ] Independently rerun T11/T12 through the pinned actual validator with other readiness checks passing.
  - [ ] Confirm profile switching, visible credit, and Launch behavior.
  - [ ] Record build/commit, expected/observed values, and screenshot or log evidence.

Ledger preparation evidence, 14 November 2026: both official CubeSat 101 URLs opened successfully. Verified Appendix C, item 6, printed p.79 / PDF p.87 of 96, checklist revision 02/20/2014, using official PDF text and a complete local-page visual check. Recorded the offline PDF SHA256. Exact conversion preserves `< 1.33 kg` as `< 1330 g`; documented boundary expectations are 1329 g pass and 1330/1331 g fail for `cubesat_1u_sample` only.

Verification command: inline Python via `@' ... '@ | python -B -`, using strict JSON parsing, `decimal.Decimal`, `hashlib`, `pathlib`, and PyMuPDF. Eight check groups passed, zero failed, exit 0: required metadata/unique IDs/official URLs; exact conversion; documented strict boundaries; PDF hash/locator/text; contract IDs and absent implementation paths; feedback segment/evidence paths and planning-only MDL status; the existing report's empty source IDs/unapproved launch; and attribution/status consistency. PDF heading checks normalize extracted whitespace. Godot tests were not rerun because this task changes documentation/data only and no runtime script loads this ledger.

The ledger's additional bibliographic IDs are local until coordinated for shared `source_ids`. Existing HPC handoff files were inspected and preserved: they record a real evaluated trace but no approved readiness check or source-credit linkage. The ledger records prior test evidence without presenting it as a new test run. No KE1/SE/KE3 files or report payloads were modified.

Prompt 6 completion review, 14 November 2026. Reopened the official NASA PDF and confirmed the checklist text. Eight source-ledger/documentation check groups passed, zero failed, exit 0, using inline Python. The review covered strict JSON and unique IDs, required metadata and exact conversion/boundaries, locator/PDF hash, agreed source/profile IDs and implementation-path status, feedback/MDL evidence, report/integration status, exact credits, and document links. Found and corrected one outdated locator in KE2's `docs/prompts.md`. The ledger required no changes. Source-ledger preparation and attribution are complete. Actual gameplay verification remains assigned to the integration subtasks below.

Remaining integration completion evidence: source metadata traces to an executed validator rule, a verified Builder display, and visible attribution in the selected export. T11/T12 remain pending; documentary arithmetic checks do not satisfy them.

KE1 reply reviewed, 14 November 2026. The supplied `message_to_ke2.md` identifies branch `ke1`, commit `55d4f336e72a68ff31cf37e44f65a98c1cdcc193`. KE2 confirmed the referenced artifacts exist at that cached revision and inspected actual validator comparison code, the 15-case manifest, runner, saved result paths, and recorded log. The owner log reports 470 checks passed, zero failed, including 1329 g passing and 1330/1331 g failing, plus alternative-profile boundaries. Recorded this as owner test evidence in `data/nasa_sources.json` and replaced the KE1 request with an acknowledgement in `docs/ke2/team-requests.md`. An independent KE2 Godot rerun, interactive Builder/profile switching, visible credits, and export checks remain pending.

## 7. Integrate real simulation output and Results

- [x] Implement and verify KE2's adapter against actual HPC terminal output in the pinned integration project.
  - [x] Compare real fields and units against the frozen contract. Native counters and decimal MB already match.
  - [x] Add `MissionEvaluator.evaluate_hpc_state` to use `config_snapshot` and complete `event_log`; map the producer's `terminal_reason` in feedback.
  - [x] Verify returned MB originates from a real accepted contact-window transmission and stored MB remains explanatory.
  - [x] Execute a real readiness-approved completed run, recorded `NO_LINK_WINDOW` block, committed v0.2 trace, and actual `abort_run` result.
  - [x] Receive and verify HPC's supplied operator-abort bundle for run `run_hpc_ke2_abort_3990d3c_01`. Match its SHA256, evaluate both APIs, and replay actual KE1 readiness, nine requests, and abort at pinned source `3990d3c`, with 71 checks passing.
  - [x] Package the actual abort input/report, verification metadata, verifier, and log for SE/KE3 in `docs/handoffs/ke2-hpc-abort-v0.1.zip`. Verify ZIP CRC and payload hashes, report identity, current executed module bytes, and 85 documentation links/anchors. ZIP SHA256 is `4d7c47ed0d9b449926f2a34482004083798b0945ca4a8db97c30585634be21c7`.
  - [x] Verify repeated terminal evaluation is deterministic and preserves inputs and the launch snapshot.
- [ ] Verify KE3's Results screen with SE/KE3.
  - [x] Review the supplied validated run `ke3_validated_1u_55d4f33_9dfd942_20261114_01` and prepare remaining owner requests for controller/Results wiring, KE1 mass boundaries, source-credit display, and a release-version abort bundle. Requests are prepared for the user to send.
  - [x] Draft separate copy-ready replies/requests for SE, KE3, KE1, and HPC in `docs/ke2/team-requests.md`, including the matching package, API/field requirements, owner tasks, and verification evidence. Link them from the KE2 documentation index.
  - [x] Review KE3's source snapshot, all 64 source/evidence hashes, all 16 named input hashes, 14 recorded zero-exit command results, copied payloads, and four supplied screenshots. Record owner preview checks as 63/67 focused and 24/29 additional headless/windowed, with zero failures.
  - [x] Verify the candidate terminal evaluation/publication path and duplicate publication in the SE/KE3 integration checkout at 14c0f97, with implementation b23de72.
  - [x] Review SE's supplied controller handoff and cached base d60d224. Record its older KE2 f313e6f dependency, local uncommitted status, reported test coverage, different Results surface, and missing source/log packet.
  - [x] Prepare the current KE2 offline source/trace handoff for SE and add a canonical input error for unsupported Survey scoring through both public entry points.
  - [x] Review actual/target values, completion ratios, status, score, source labels, and same-run event references in KE3's recorded Results preview against the matching report.
  - [x] Review owner preview evidence for exact contract-error fixtures, synthetic null abort scores, empty causes, missing-event fallback, and absent comparison.
  - [x] Verify the candidate presentation receives the complete ordered history, scoped readiness credit, and structured Survey error through the integrated Results route.
  - [x] Verify candidate Retry starts a new run, resets the event sequence, and retains its completed baseline; verify New Mission resets baseline/history through the catalog reset entry point.
  - [x] Verify reopening candidate Results preserves run history through the actual scene route.
  - [ ] Complete manual acceptance of navigation, lifecycle controls, original partial/abort packets, and credits on the selected release revision.

Completion evidence: real config, run ID, terminal trace, report, and displayed values agree. Route changes in another owner's files to that owner with the requested call/binding and verification steps.

Prompt 7 runtime evidence. Pinned HPC `b9817c3` uses KE1 readiness dependencies attributed by its handoff to `55d4f33`. Executed high_inc completion at step 60/60 with 62 events, 1/4 observations, approximately 7.7333333328/30 MB received, approximately 4.2666666672 MB onboard, `partial`, score 25, and `NO_LINK_WINDOW` cause referencing `evt_008`. An actual abort after capture preserves counters and returns a null score with its producer reason. Commands and logs are recorded in [HPC integration](ke2/hpc-integration.md). Native HPC/KE1 modules remain outside the current KE2 checkout and were executed unchanged in the isolated project. Runtime controller/Results/retry/export checks remain pending.

Coordination review, 14 November 2026. The latest supplied bundle records KE1 `55d4f33` and HPC `9dfd942`, passing readiness at 1060 g, a completed run, and the recorded blocked transmission. The matching KE2 handoff contains the partial/25 report and applicable readiness/feedback credits in metadata. Prioritize SE's terminal publication/lifecycle wiring and KE3's Results/credits binding. Request KE1's actual 1329/1330/1331 g and alternate-profile evidence, and an abort bundle from the selected integration revision when available. This task reviewed current files and prepared requests. The handoff's prior 32 run checks and 165 evaluator checks retain their recorded execution history. [Matching report handoff](handoffs/ke3_validated_1u_55d4f33_9dfd942_20261114_01/README.md).

KE3 reply reviewed, 14 November 2026. `data/ke3-results-verification/SOURCE_SHA256.json` has SHA256 `e1f86bc937c5b0dc87f0a33a07e60e1395156c593cc0a00940ab59fe421b1256`, and all 64 named file hashes match. All 16 named original-input hashes and the returned archive/report/metadata identities match. Reviewed owner logs reporting 63 headless/67 windowed focused checks, 24 headless/29 windowed additional checks, zero failures, and 14 zero-exit command records. Four supplied screenshots show the report, scoped credits, missing evidence, and synthetic aborted/null-score display. KE3's local reopening and synthetic Retry regressions are recorded in the packet. Its source changes remain uncommitted and are identified by the manifest. KE2 reviewed these artifacts without a new UI test execution. Updated the source ledger, consumer handoff, KE3 acknowledgement, and SE request. The remaining SE request includes a confirmed integration revision and the full-history projection from HPC `event_log` to presentation `state.events`. Controller-driven lifecycle/error routing, B02, official B10, source-link opening, and exports remain pending. [Consumer review](ke2/integration-handoff.md#reviewed-ke3-results-preview).

SE reply reviewed, 14 November 2026. The supplied `SE_KE2_CONTROLLER_HANDOFF.md` reports uncommitted changes based on cached SE `d60d224` using KE2 `f313e6f`. It identifies `on_terminal_state`, `mission_results.publish/baseline_for`, retry/abort/New Mission, and prototype Results methods, with local headless test claims. Its current source, raw logs, and `controller-reference-reproduction.json` were absent from this message. The cached base was inspected, including the Survey target/delivery extension and its earlier `init_run` API. Latest controller behavior remains owner-reported pending a source/evidence snapshot and KE3 integration.

- [x] Add explicit Survey input-error regression coverage through both evaluator APIs. Current v1 evaluation returns `INVALID_EVALUATION_INPUT` at `config.mission.objective` for Survey until its per-target scoring extension is agreed.
- [x] Verify Godot 4.7.2, 167 standalone checks, 207 pinned combined checks, and exact original validated-report reproduction through both APIs with input preservation. Every final command exited 0, with the known certificate-store diagnostic recorded.
- [x] Supply `--ke2-standalone` for testing current KE2 modules with producer revisions that lack the pinned runtime test's `init_validated_run` extension.
- [x] Prepare and check the offline `docs/handoffs/ke2-se-controller-v0.1.zip`, with 56 hashed payload files, current source, full original input bundle/report, standalone verification project, and KE3 reference ZIP. ZIP SHA256 is `d179c318d2058519b6df47258a364b98ec6a387c3b80c92e7f820e2643949aa7`. The packaged project passes its 167-check runner and original-trace verifier. Package Git-base metadata is aligned to current checkout `79e249b`; the retained report preserves its earlier `8c3ed81` generator provenance.
- [x] Update the SE reply with the current package, source-revision distinction, canonical Survey error, original-trace check, Results binding/history mapping, and required source/log/Survey examples. [Offline handoff](handoffs/ke2-se-controller-v0.1/README.md).

HPC abort reply reviewed and executed, 14 November 2026. Input SHA256 matches `4283f1dc663736b46462cbbb452f5fd1c5ab91cf0caa892c3e7c21f55c60697b`. Cached source `3990d3c7aae3b69dcf367d9f0601fc40fd669262` is a descendant of `9dfd942`. Preserved the original local/uncommitted payload and generated a matching report for `run_hpc_ke2_abort_3990d3c_01`, mission `mission_hpc_ke2_abort_01`. It returns failed/aborted with null score, step 8/60, one capture, 7.7333333328 MB returned, 4.2666666672 MB stored, and its recorded operator reason. Event history includes the prior no-contact block `evt_008` and abort `evt_009`.

Godot `4.7.2.stable.mono.official.ed1daf0bf` passed 71 checks, zero failed, exit 0. Verification loaded 13 byte-identical pinned producer/dependency files, recomputed actual readiness, replayed all nine recorded requests and the abort, compared response states/events with tolerance 1e-9, and checked the complete report, both APIs, deterministic output, and input preservation. A too-strict replay explanation-string comparison was corrected for JSON/native number formatting before the passing run. The replay explanation separately confirms the operator reason. The known certificate-store diagnostic was recorded. Full HPC regression counts remain attributed to the owner. SE/KE3 integrated display/lifecycle, B02, official B10, Survey, and exports remain pending. [Abort handoff and verification](handoffs/ke2-hpc-abort-v0.1/README.md).

Status and prompt-readiness review, 14 November 2026. The newer isolated checkout `tmp/se-ke2-integration` is at `14c0f97`, with integration implementation `b23de72` on SE candidate `d60d224`. Its evaluator, feedback, and KE2 runner are byte-identical to the current KE2 working files. Independently reran Godot `4.7.2.stable.mono.official.ed1daf0bf`, the candidate Results suite (57 passed, zero failed), and the standalone evaluator (167 passed, zero failed, five pending labels). Both test commands exited 0. Logs are `tmp/ke2-status-results-integration.log` and `tmp/ke2-status-evaluator.log`. The Windows certificate-store diagnostic remains present. The packet evaluates `run_001` / `mission_local` as success/100, 4/4 observations and 48/30 MB returned. These candidate checks supersede the earlier missing-controller-evidence status for the covered paths. The root `memberKE2` checkout remains at `79e249b` with local changes, and the candidate has its own revision. Optional comparison, manual Observe/Transmit/Power Save wiring, Survey scoring, exact Builder boundaries, official B10 and exports remain pending.

- [x] Reconcile prompt readiness against the latest candidate source and rerun its Results/evaluator suites. Prompt 8 now has candidate integration evidence. Prompt 10 can proceed as a focused stability review. Prompt 9 remains optional P1 work and uses `comparison: null` for absent/ineligible baselines under v1.0.

## 8. Optional P1 retry comparison

The separate SE Survey extension also needs coordination. Its aggregate goals and per-target fully delivered observations require agreed verdict/score/report examples. The current evaluator returns `INVALID_EVALUATION_INPUT` for explicit Survey requests. Imaging integration can use the supplied offline package.

- [ ] Agree and implement the Survey scoring extension with KE1/HPC/SE/KE3.
  - [x] Inspect SE d60d224's documented target_regions and per-target delivered/data/capture fields.
  - [ ] Obtain versioned Survey config/state/events and expected verdict/score examples.
  - [ ] Align scoring weights, delivery semantics, report fields, and consumer displays.
  - [ ] Implement and verify the agreed Survey extension in KE2-owned code.

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

## 10. KE2 documentation

- [x] Create a KE2 documentation index with owned files and current implementation status.
- [x] Document evaluator/feedback APIs, consumed inputs, deterministic scoring, aborts, evidence selection, and corrective actions.
- [x] Document KE1/HPC/SE/KE3 handoffs, all report/error fields, null handling, invocation, recorded payloads, and pending lifecycle checks.
- [x] Document headless commands, historical verification results, acceptance coverage, and pending comparison/readiness/UI cases.
- [x] Create a readable NASA source record with profile scope, strict boundaries, verification status, official URLs, and exact ledger attribution text.
- [x] Verify local documentation links and anchors, report/root-cause/error field coverage, copied credits, and recorded sample metrics against the current files.

Documentation task evidence, 14 November 2026. Five Markdown files are available under `docs/ke2/`. Five documentation check groups passed using inline Python, with zero failures and exit 0. Coverage includes 51 local links/anchors, balanced code fences, all 17 report fields, four cause fields, five error fields, three exact ledger credits, recorded metrics, test-script paths, and T01-T14 coverage. `git diff --check` passed. Prior Godot and recorded-trace results are labeled with their execution history. Gameplay verification remains tracked in Sections 4, 6, 7, and 8.

## Dependency tracking

Update this table as owners provide decisions or samples. A pending producer mapping can coexist with fixture-based KE2 work.

| Dependency | Owner to coordinate with | Current status / required evidence |
| --- | --- | --- |
| Final KE2 error/feedback fields and examples | KE1 + KE2 + HPC + KE3 | Implemented and tested with real pinned modules; native terminal_reason mapping verified; space/ground segments used |
| Shared contract and reference synchronization | KE1 | Complete in this checkout |
| Scenario IDs, units, step/energy/abort rules, and real trace | HPC + KE1 | Pinned completed/block/abort checks passed; current combined runner 207 passed and HPC 3990d3c abort replay 71 passed; selected-release manual-action integration pending |
| Controller migration and report/retry calls | SE + HPC + KE3 + KE2 | Candidate 14c0f97/b23de72 independently passes 57 Results/lifecycle checks and 167 evaluator checks; selected-release merge and manual acceptance pending |
| Results/credits display and export verification | KE3 + SE + KE2 | KE3 preview evidence reviewed and candidate actual scene binding/history/credit/error routing verified headlessly; original partial/abort packet release-path checks, manual controls and exports pending |
