# Expansion Progress Record

Last updated on 15 November 2026 in Asia/Rangoon.

Use the [team scope](team-scope-v2.md) and [KE2 task checklists](ke2-work-plan.md) for checkbox status. This record holds evidence, current dependencies, and completion history.

## Current status

| Work package | Status | Owner and next action |
| --- | --- | --- |
| Markdown plans and task tracking | Complete | Both supplied PDFs converted, task IDs retained, and tracking instructions added |
| Independent KE2 implementation candidate | Complete locally | [Callable evaluator, frozen records, expanded comparator, tests and review archive](ke2-integration-candidate.md); final 702/0 candidate checks and 43/43 repository programs |
| 00 Contracts and handoffs | In progress | KE1 draft-2 artifacts received, hashes verified and 629 checks reproduced in isolation. 00.3 evidence request and 00.4 examples are prepared. Remaining bounds/custom identity, owner alignment and production integration stay open |
| 10 Imaging and Survey | Candidate complete; integration open | Imaging regression 53 passes; callable Survey candidate reproduces 83/100, with strict missing-key default. HPC sparse semantics and coordinated production activation remain open |
| 20 Communication and Weather | Candidate complete; integration open | Callable count/MB evaluation, proposed scores and controlled native-proxy cases pass. Actual config-v2 producers, HPC semantics and live acceptance remain open |
| 30 Reports and feedback | Candidate complete; integration open | Callable 19-field report2, errors, aborts, feedback and immutable bindings verified. KE3 schema review retained; final revision/policy adoption and SE/KE3 live acceptance remain open |
| 40 A/B Design Lab | KE2 candidate complete; lifecycle open | All-objective record builder/validator and comparator verified. SE storage/runtime wiring, HPC sampling/identity ratification and KE3 presentation remain open |
| 50 Expansion acceptance | Independent checks complete; real acceptance open | Seven KE2 programs pass; 43 repository programs pass. Collect actual expanded-producer, Save A/B lifecycle and public-browser evidence |
| 60 Release | KE2 local package complete; team release open | Source/evidence archive and merge order ready. SE confirms templates, public URL and deployed revision; team verifies final journeys |

## Baseline and verification

The table below preserves the **original** `4c65496` baseline. Latest verified base is `6554823` plus the candidate files: 43 repository programs pass, evaluator 294/0/5 pending and candidate 702/0. See [current commands and evidence](ke2-integration-candidate.md).

| Item | Observed baseline |
| --- | --- |
| Branch and revision | `features/KE2`, `4c65496` |
| Local Git references | Local `main` points to `4c65496`. At the 15 November audit, recorded `origin/main` is `dce75db`, three commits ahead with SE producer/controller/UI changes |
| Local edit | `.gitignore` adds `PDF files` |
| Agreement | `docs/team-agreement.md`, `v1.0-agreed` |
| Engine | Confirmed `4.7.2.stable.mono.official.ed1daf0bf` |
| Last full run | All 38 active programs passed on `4c65496` during the preceding repository status review |
| Selected results | 48 acceptance, 23 merged retry-intent, 207 evaluator, 174 player UI, and 57 Debrief summary checks passed |
| Pending declarations | Five listed in `tests/test_mission_evaluator.gd`, retained below |
| Diagnostic | Windows certificate-store error appeared in logs while checks passed |
| Verification scope | Fixture checks, integrated Godot modules, and headless scenes |
| Export state | Web preset present, installed export-template directory empty at inspection |

Baseline verification command, run from the repository root during the preceding status review.

```powershell
$orbitGodot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $orbitGodot --version
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_all_checks.ps1 -GodotExe $orbitGodot
```

Per-program logs are under [exports/check-logs](../../exports/check-logs/). These are generated local evidence. The current documentation conversion was verified through Markdown, link, checklist, and Git diff checks. Gameplay checks reference the earlier full run on the same code revision.

The five evaluator pending declarations are retained as reported by that runner. Each expansion task must be closed using the relevant actual evidence.

| Declaration | Recorded meaning | Follow-up |
| --- | --- | --- |
| T07 | Controlled retry deltas await comparison implementation | KE2 40.2 and 50.7 |
| T08 | Baseline eligibility awaits comparison implementation | KE2 40.1 and 50.7 |
| T11 | Actual 1329 g validation and Builder verification await integration | Reconcile existing KE1 evidence with actual Builder and final-build checks |
| T12 | Actual 1330/1331 g and profile-switch checks await integration | Reconcile existing KE1 evidence with actual Builder and final-build checks |
| INTEGRATION | Results, duplicate publication, and retry/reset remain declared pending | Reconcile existing integration coverage, then verify expanded lifecycle through 50.8 |

## Active routes and checks to rerun

The actual startup is `scenes/Main.tscn` with `scripts/MissionController.gd`. Active screens use `scripts/integration/mission_runtime.gd`, `mission_playback.gd`, and `mission_results.gd`. `scenes/screens/DebriefCompare.tscn` binds to `scripts/prototype/Screen.gd`. Its display helpers include `DebriefPresentation.gd`, `DebriefSummary.gd`, and `PlayerLanguage.gd`.

The older pure `mission_workflow.gd` API retains test coverage. Use the active scene binding when integrating the expansion UI.

| Change | Relevant existing checks |
| --- | --- |
| Evaluation and feedback | `tests/test_mission_evaluator.gd`, `tests/ke2_results_integration.gd` |
| Configuration and catalogs | `tests/validation/test_mission_validator.gd`, `test_mission_readiness.gd`, and `test_mission_fixtures.gd` |
| Simulation and evidence | `tests/test_hpc.gd`, `tests/prediction_multitarget_smoke.gd`, `tests/expanded_missions_smoke.gd` |
| Publication and lifecycle | `tests/controller_evaluation_smoke.gd`, `tests/integration/test_ke3_merge.gd`, `tests/ke3_report_binding_check.gd` |
| Active goal presentation | `tests/player_ui_check.gd`, `tests/debrief_summary_check.gd`, and affected KE3 integration checks |
| Whole current project | `tests/run_all_checks.ps1` |
| New objectives and A/B | Add or extend meaningful checks for the agreed 50.1-50.9 expansion cases |

## Decisions and handoffs to resolve

These are current planning dependencies with identified owners.

| ID | Decision or missing handoff | Owner | Status and next action |
| --- | --- | --- | --- |
| D01 | Exact objective IDs, preset IDs, required-goal fields, and validation behavior | KE1 + KE2 + SE | Confirmed choices and draft-2 KE1 artifacts received/verified. Remaining bounds/custom identity, production validation and SE/HPC alignment are pending |
| D02 | Expansion score weights and qualifying progress | KE2 + affected team owners | User explicitly chose Keep scoring as a proposal on 15 November. Survey thirds and Communication/Weather halves are not approved for production; KE3's implementation request does not ratify them |
| D03 | Accepted-event fields, absent Survey target entries, and revolution identity/mapping | HPC + KE2 | Source map and existing-run excerpt in [HPC handoff](hpc-evidence-handoff.md), confirm mapping, sparse-map/legacy handling, and packet semantics with HPC |
| D04 | Communication/Weather thresholds and stock-design feasibility | KE1 + HPC + KE2 | KE1 confirmed the specified high_inc two-capture/basic-instrument/fast-radio Communication starter. Existing [headless evidence](ke3-ke2-results-ab-handoff.md) exercises Imaging mechanics proxies. Actual typed v2 runs, Weather revisit policy, and HPC confirmation remain pending |
| D05 | Extended report schema and existing-field compatibility | KE2 + KE3 + SE | KE3 schema agreement and [SE conditional review](se-report-review-and-version-proposal.md) received. Separate report-v2 candidates ready. Settle revision placement/output selection, dual-version consumers and coordinated implementation |
| D06 | Comparison matching, action-policy identity, and independent saved-A record | KE1 + HPC + SE + KE2 | SE saved-A fields received as a proposal. Agree eligibility/versions/sampling, serialization/digest and comparator wiring. Historical keys reproduce from typed inputs, but all eight change on direct JSON reload; normalization/retained bytes remain open |
| D07 | Save A eligibility from the reached active execution | SE + KE2 | SE confirms storage/navigation can start now. Gate Save A on reached completion and its bound report, then supply actual lifecycle evidence and the implementation commit |
| D08 | Web templates, Netlify URL, deployed revision, and browser evidence | SE + team | Open, confirm release dependencies and test public journeys |
| D09 | Newer recorded main producer/controller baseline | SE | Open, recorded `origin/main` is `dce75db`. SE requests exact owner commits, combined integration revision, commands, exit codes and example run records before production integration |
| D10 | KE1 registry, catalog API, and validation tests | KE1 | Draft-2 review artifacts received/verified/archived; they remain outside live production paths. Remaining dependency is coordinated v2 production validation/integration, not another artifact request |

## Completion history

Append a row after each completed subtask or task and update its checkbox in the relevant plan. Record subsequent reopened work with its failure and owner.

| Date | Item | Result and evidence | Verification level |
| --- | --- | --- | --- |
| 2026-11-14 | Documentation setup | Converted both supplied PDFs into linked Markdown plans, retained source task IDs, and added task/subtask status instructions | Document and source inspection |
| 2026-11-14 | KE2 00.1 | Recorded `features/KE2` at `4c65496`, signed contract, active routes, existing local edit, preceding 38-program verification, five pending declarations, and checks to rerun | Source inspection with referenced prior integrated/fixture/headless results |
| 2026-11-15 | KE2 00.2 draft subtask | Wrote [KE1/SE configuration handoff](ke1-se-config-handoff.md) with current catalog hydration, exact preset defaults, proposed optional preset IDs and positive goal fields, valid/invalid candidate examples, actual unknown-field errors, capture-quota constraints, consumer paths, and owner decisions. Parent 00.2 remains open for agreement | Source inspection and documentation-fixture checks |
| 2026-11-15 | KE2 00.2 handoff delivery | User reported sending the configuration handoff and examples to KE1 and SE. Ticked the sharing subtask. Owner decisions remain pending | User-reported handoff delivery |
| 2026-11-15 | KE2 00.2 K20 comparison | Recorded user-confirmed mission IDs and goal meanings. Wrote [KE2 K20 review](k20-ke2-interface-review.md) recommending explicit config v2, exact nested goal keys, root preset identity/revision, and a specified high_inc/basic-instrument/fast-radio starter. Candidate arithmetic is 1120 g / 89 credits, with 24 MB split over two contact steps. K20 registry/API/tests are absent locally. Four interface decisions and actual v2 acceptance remain pending | User-confirmed semantic agreement, source inspection, existing mechanics evidence, and proposed JSON/catalog arithmetic |
| 2026-11-15 | KE1 confirmation of K20 reply | User reports KE1 confirmed the four interface choices and will provide the required files later. Ticked the KE1-confirmation subtask and added the explicit artifact-receipt dependency. SE/HPC implementation alignment, scoring/report decisions, and actual v2 verification remain open | User-reported owner confirmation and local file-existence checks |
| 2026-11-15 | Prompt usage guide | Reviewed the prompt sequence, added when-to-use guidance, identified 00.3 as the next independent step, and clarified Weather revolution counting and proposed weighting in 20.3/50.4 | Document inspection and Markdown checks |
| 2026-11-15 | KE2 00.3 draft and source inspection | Wrote [HPC evidence handoff](hpc-evidence-handoff.md) and [existing-record excerpt](evidence/hpc-existing-trace-excerpt.json). Inspected stable events, step conventions, decimal MB, sparse packet-delivery maps, planner revolution index, frame extrema, and Observe-generated payloads. Recorded HPC requests and kept agreement/real new-objective checks open | Source inspection, prior local provider-integration record, and Python integrity/accounting checks, with no new engine execution |
| 2026-11-15 | KE2 00.4 proposed examples and saved-record definition | Prepared [KE3 reports/A/B response](ke3-ke2-results-ab-handoff.md), [probe source](evidence/ke2-handoff-probe.gd), and [full packet](evidence/ke2-handoff-current.json) at `4c65496`. Eight completed executions use prefix `ke2_probe_20261115_`. Survey goal evidence gives proposed 83/100, Communication and Weather give proposed 75/100 using supported Imaging mechanics. Production Survey replies remain errors and candidate new-objective initialization fails. Actual Imaging A/B reports are partial/81 and success/100, with +4.6133333328 MB, +7 credits, +60 g, and -0.4616666667000011 Wh minimum battery. Baseline evaluation still returns null comparison. Ticked proposal-example and independent-record-definition subtasks only | New integrated headless Godot modules plus separately labeled proposed audit assessments. Confirmed engine `4.7.2.stable.mono.official.ed1daf0bf`, probe zero failures, independent `python -` packet/hash/evidence/delta checks passed, byte-identical replay passed, evaluator 207 passed/0 failed/5 pending, adapted Results 17 passed/0 failed. Commands/logs in handoff. Windows certificate-store diagnostic persists. Active expanded UI, comparator/lifecycle, and exports remain unverified |

SE review recorded on 15 November 2026 confirms that the configuration draft remains unready for production integration. Separate Save A/B storage and navigation can start now. The [updated handoff](ke1-se-config-handoff.md#se-review-and-work-that-can-proceed) records the remaining contract, KE1, HPC, KE2 and revision/test deliverables. User-confirmed IDs/goal meanings retain their recorded status. This review completes the corresponding 00.2 documentation subtask. Storage/navigation implementation and task 40.3 remain open. Verification for this update consists of source/status inspection, local-link and checklist checks, and `git diff --check`. Gameplay checks reference the existing evidence packet and logs.

| 2026-11-15 | Step-by-step prompt guide | Reordered all 35 original prompt IDs into numbered Steps 1-35 with phase, readiness, output, and decision/dependency guidance. Marked Step 6 / 10.1 as next ready work, retained confirmed IDs/goal meanings, and described conditional configuration, scoring/report, and saved-record/comparison decisions. Routine authorized KE2 work and owner-approved independent SE storage remain able to proceed | Document/source checks with inline `python -` verified 35 unique IDs, sequential step metadata, 36 prompt/context blocks, 11 local links/anchors, fences and whitespace. `git diff --check` passed. No gameplay test execution for this documentation change |

## 15 November post-pull Imaging verification and report review

Current inspected revision is `features/KE2` at `8b76b5df4f0b327d8d4293be22ed984b610f8647`, after the pulled `dce75db` and local handoff-document commit. The earlier baseline table remains a historical record. Initial working change was root `README.md`; preserved. No production or other-owner implementation file changed.

- [x] 10.1: actual Estuary Watch and Tropical Forest Watch buttons, own config/schedules, native engine/report publication and Debrief values verified. New `tests/ke2_imaging_presets_check.gd`: 53 passed / 0 failed. Estuary: 5 captures, 60 MB, success/100. Tropical: 5 captures, 44.3200000032 MB, partial/87, with 15.6799999968 MB onboard.
- [x] 30.1 proposal review: reused the existing handoff/four examples; eight production hashes and the source packet hash match, actual replies remain separate from proposed goal assessments, and all 17 legacy report fields are retained. Shared report/score agreement and implementation remain open.
- [x] Existing checks: evaluator 207 passed / 0 failed / 5 declared pending; adapted Results 17 passed / 0 failed; Debrief summary 57 passed / 0 failed. Final commands exit 0 on confirmed Godot 4.7.2. Certificate-store diagnostic persists. The repository runner remains 43 programs and was not rerun in full or edited.
- [x] Corrected prompt/consumer-handoff wording to reuse KE1's recorded four-choice confirmation. KE1 artifacts and remaining SE/HPC coordination are still pending.

See [commands, verification scope and next handoffs](imaging-baseline-and-report-review.md) and the [source-bound native evidence](evidence/imaging-presets-8b76b5d.json). This is fixture/native-module/headless-scene evidence as identified per suite; no exported browser execution. Step 8 can advance with agreed delivery semantics or labeled fixtures; production scoring/report publication still requires the unresolved shared decision. SE's independent storage/navigation work remains available.

## KE1 K20 draft-2 receipt and independent verification

Received the user-supplied folder `KE1-KE2-K20-Review-draft-2` on 15 November 2026. Reviewed revisions: `expansion-goals-v2-draft-2`, `five-presets-candidate-2`, Communication preset revision 2, base main `dce75db`; live KE2 checkout remains `8b76b5d` with prior working changes preserved.

- [x] 00.2 artifact receipt/review: all 16 supplied file hashes and four executed-input hashes match. Registry/API/tests/diagnostic/documentation and logs are archived as [17 exact review-only files](evidence/ke1-k20-draft2-review-package.zip). Nothing was installed into live producer paths.
- [x] 00.2 preset-default check: supplied tests preserve all three original v1 configs; both Imaging definitions equal the previously measured actual card configs.
- [x] Independent isolated rerun: 70 catalog + 265 starter + 294 existing validator = 629 passes / 0 failures, all exit 0. Parsed catalog and starter JSON exactly match KE1's supplied evidence. Confirmed Godot 4.7.2; certificate-store diagnostic persists.
- [x] 20.2 mechanics evidence subtask: a labeled KE2 derivative keeps capture quota 2 in both trials and passes another 265 checks. Two Observes return 24 MB over positive steps 7/10; one Observe returns 12 MB at step 7 and step 10 is rejected `NO_DATA`. Both complete at step 30 with ordered stable same-run events and reconciled MB.

See the [receipt/review and exact commands](ke1-k20-draft2-receipt-review.md) and [verification packet](evidence/k20-draft2-ke2-verification.json). These are real native-engine runs of test-only v1 Imaging physical surrogates, with official new-goal scores null; they are not production Communication-v2 integration or browser evidence. KE1 owns remaining production validation/bounds/custom identity; HPC owns evidence confirmation and Weather traces; SE owns propagation/storage; KE2/KE3/SE still need scoring/report/comparison agreement. A reply to KE1 is prepared locally in the review; no message or remote action was sent.

## Step 8 / 10.2 implementation preparation

On 15 November 2026, following the ordered prompts, added the private `_measure_survey_deliveries` helper in KE2's evaluator and focused checks in the existing evaluator test. The user reports no HPC reply yet. Missing selected-target entries therefore remain unavailable errors; explicit fixture zeros are never inferred from native sparse maps. `evaluate_mission`, publication, public report fields and scoring remain unchanged.

- [x] Match launch snapshot, select configured targets, count each explicitly delivered target once and retain raw per-target counts.
- [x] Add 27 fixture checks covering extra/unrelated deliveries, unavailable/malformed evidence, missing entries, repeatability, input preservation and reviewed minimum-one scope.
- [x] Add 20 real native packet checks: one partial transmission leaves no completion counter; completing the packet supplies one counter and returns all 12 MB.
- [x] Verify evaluator 254 passed / 0 failed / 5 existing pending; Imaging presets 53 passed / 0 failed; adapted Results 17 passed / 0 failed, all exit 0 with confirmed Godot 4.7.2. `git diff --check` passed; certificate-store diagnostic persists.
- [ ] Finish 10.2 after HPC confirms absent-entry/packet semantics and the helper can be integrated against agreed inputs.

See [Step 8 evidence and exact commands](survey-delivery-measure-step8.md) and [source/log hashes](evidence/survey-delivery-step8-checks.json). Verification uses labeled fixtures plus actual native modules and headless Imaging scenes; no browser/export run. Step 9 / 10.3 needs the Survey scoring/progress decision and coordinated report migration. KE1-owned, HPC-owned, SE-owned and KE3-owned implementations, signed contracts and unrelated working changes were preserved.

## KE3 report-schema response received

On 15 November 2026, at `features/KE2`, `f04ab66`, the user relayed KE3's explicit agreement on the four-example `goal_progress` schema. Recorded the [owner response and scope](ke3-report-schema-agreement.md); ticked KE3-specific subtasks in 00.4 and 30.1. Confirmed fields, Survey target detail, supplied verdicts/ratios, legacy Imaging display, measured-zero versus unavailable values, abort/null score, same-execution evidence and source credits. No required field changes were requested.

The supplied response identifies KE3 even though the selected earlier request was addressed to SE. SE agreement was not inferred. `GoalProgress.gd` is a planned consumer and is absent locally. KE3 implementation/live acceptance, Survey scoring, SE report version/storage and HPC sparse-map semantics remain pending. Parent tasks 00.4 and 30.1 remain open.

Verification: branch/HEAD/status, current handoff/consumers, `Test-Path`, inline Python JSON-field/local-link checks and `git diff --check`. Documentation-only update; no new fixture/native engine/browser/export execution. Current production reports and signed contracts remain unchanged. No messages or remote actions were sent.

## SE conditional report review and evidence follow-up

On 15 November 2026 at `features/KE2`, `f04ab66` plus local documentation changes, the user relayed SE's acceptance in principle of the envelope/17 fields plus objective/goal progress. Recorded report-v1/report-v2 recommendation and proposed saved-A fields, execution binding and completed-attempt lifecycle. Exact version/revision, serialization/evidence details and full integration acceptance remain open. KE3's earlier schema agreement does not imply agreement to this later version proposal.

- [x] Prepared separate report-v2 candidate examples and a candidate report-contract label in review-file metadata. Original examples, production replies, runtime output and contracts remain unchanged.
- [x] Addressed missing evidence by preparing a shareable source packet/probe/checker bundle with manifests and historical source snapshots. No delivery was claimed.
- [x] Investigated eight actual execution-key failures after JSON reload. Typed native replay on the original eight matching module/data sources reproduced every original key, trace and actual reply; exact hash preimages are retained. Godot reserializes integer `[1]` as float `[1.0]` after loading, so portable serialization remains unresolved with SE.
- [x] Review-only checker verifies preimage hashes/inputs, event references, actual replies and ratios for original/v2 candidates: 85 passed / 0 failed, exit 0, while explicitly reporting all eight known JSON-roundtrip mismatches. Isolated native reconstruction reports zero probe failures. Certificate-store diagnostic persists.

See [SE review, commands and prepared reply](se-report-review-and-version-proposal.md). Evidence combines historical records, candidate fixtures and isolated replay of existing native cases. No production v2 evaluator, storage/UI integration, full-suite, export or browser acceptance was performed. Parent 00.4/30.1 and scoring/HPC/custom-identity dependencies remain open. No teammate message or remote action was sent.

## KE3 Debrief display-contract follow-up

On 15 November 2026 the user relayed a further KE3 confirmation limited to presentation suitability, with implementation pending. Recorded [the clarification](ke3-display-contract-followup.md). Independent JSON checks reproduced 9 goal entries and 2 Survey target rows, required fields, consistent ratios/verdicts and unchanged original Imaging values. Clarified empty causes, null comparison, unavailable missing evidence and separately scoped credits. No additional display fields or repeat KE3 approval are required.

The reply does not approve goal semantics, scoring or report-version changes. `mission_results.gd` remains an SE-owned coordination point. Existing KE3 schema checkboxes stay complete; implementation and parent acceptance remain open. Preserved concurrently updated SE review/version/evidence records and shared notes. Checks: JSON/link assertions and `git diff --check`; no production change or new Godot/native/UI/browser execution. Remaining decisions stay with KE2, HPC and SE as detailed in the follow-up.

## Step 9 scoring-proposal prototype and Step 10 review

On 15 November 2026, at `features/KE2`, `f04ab66` plus local changes, followed prompt 10.3's labeled-fixture path after the user's request to start. Added `tests/fixtures/ke2_survey_scoring_proposal.gd`, imported only by the evaluator test. It uses the private Step 8 measure and explicit target counters, preserves raw actuals and returns `ok/proposal` with `not_for_publication`; public evaluator/report production and all shared/other-owner implementations remain unchanged.

- [x] 10.3 prototype: proposed capped equal thirds, success only with all goals, partial with scored progress, failed with none, abort failed/null score and raw-actual preservation.
- [x] 40 new fixture assertions: partial/83 worked case, success, no progress, caps, extra/unrelated delivery handling through Step 8, half-up boundaries, rounded-100 partial, deterministic input preservation, invalid goals/actuals, missing evidence and terminal checks.
- [x] Existing evaluator plus new fixtures: 294 passed / 0 failed / 5 existing pending. Imaging presets 53 passed / 0 failed; adapted Results 17 passed / 0 failed. All exit 0 on confirmed Godot 4.7.2; `git diff --check` passed. Certificate-store diagnostic persists.
- [x] 60.2 checkpoint output: reused the four existing worked report examples and format candidates, distinguished native/proxy actuals from proposed scores, and identified HPC/SE/KE3/KE1 dependencies and independent Communication counting preparation.

See [Step 9 and checkpoint](survey-scoring-proposal-step9.md) and [source/log verification](evidence/survey-scoring-step9-checks.json). New scoring checks are numerical fixtures, not new native Survey scoring or official reports; existing native packet/engine and headless Imaging checks reran. No full-suite, export, browser or remote action. Scoring ratification, HPC sparse-map semantics and report integration remain open; parent 10.3 is not ticked. Unrelated local SE/KE3 evidence/document work was preserved.

## Independent KE2 sequence in progress

On 15 November 2026, following the user's requested sequence, implemented 20.1's unwired Communication counter and focused same-execution evidence validation. Initial suite: 25 passed / 0 failed, including the eight historical native contact counts. Ticked completed counting/dedup/exclusion subtasks only. HPC confirmation, scoring and real-objective publication remain open. See [implementation record](independent-ke2-algorithms.md). Preserved previous working changes and other-owner code.

20.3 preparation then added 17 Weather checks: frozen-step mapping/dedup/target isolation, boundary cases and both recorded proxies. The focused suite passes 42 checks. Completed counting/fixture subtasks are ticked; owner-confirmed mapping, scoring and real Weather acceptance remain open.

40.1 then added a proposed normalized-record eligibility module with historical input-byte binding, requirements/context/scenario matching and policy/manual classification. Focused suite: 65 passed / 0 failed. The normalized Imaging pair is a fixture-backed comparison candidate, not SE saved-A acceptance. Final record properties, legacy rules and transported-record serialization remain open.

40.2 then added 16 signed-measure checks: the normalized native pair reproduces +4.6133333328 MB/+60 g/+7 credits/+19 score points, with negative/zero/optional-unavailable cases and initial/terminal sample boundaries. Focused suite: 81 passed / 0 failed. Sampling/record/output rules remain labeled proposals; no saved-A/UI comparator call was wired.

30.2 added 21 evidence/comparison boundary cases and retained-whole-history/report-digest guards in the internal prototypes. Focused suite: 102 passed / 0 failed; existing evaluator rerun: 294 passed / 0 failed / 5 original pending. JSON whole numeric versions remain accepted. Parent production acceptance stays open; digest/normalization fields are fixture proposals, not an SE record contract.

30.3 completed the sequence with 15 proposed goal-feedback checks. Focused suite: 117 passed / 0 failed. Known contact/storage causes cite recorded same-run IDs; Survey sparse evidence, conditional Weather mapping and unknown/irrelevant/conflicting evidence remain neutral. No production feedback/report publication was changed.

## Independent sequence final verification

All requested independent task outputs are now implemented: 20.1 counting, 20.3 proposed revolution mapping, 40.1 normalized-record eligibility, 40.2 signed measures, 30.2 boundaries and 30.3 proposed goal feedback. Also audited source-ledger integrity and fixed two stale validator/profile-catalog presence flags without changing NASA/rule/credit/gameplay verification claims.

Final focused suite: **125 passed / 0 failed** (25 contact, 17 Weather, 23 compatibility, 16 deltas, 21 boundary, 15 feedback and 8 source-integrity checks). Existing final reruns: evaluator **294 passed / 0 failed / 5 original pending**; Imaging **53**, Results **17**, Debrief summary **57**, all zero failures/exits 0. Confirmed Godot 4.7.2; certificate-store diagnostic persists; `git diff --check` passed.

See [files, exact commands, scope and remaining handoffs](independent-ke2-algorithms.md) and [source/log verification](evidence/independent-ke2-checks.json). New helpers remain unwired and normalized record/digest/sampling/legacy policies are explicit proposals. Verification combines handcrafted fixtures, recorded native traces and current native/headless regressions; no production expanded-objective publication, Save A/B UI lifecycle, full 43-program run, browser or export acceptance was performed. Preserved prior working changes and other-owner implementations; no remote action.

## KE2 K20–K31 owner-response preparation

On 15 November 2026, at `features/KE2`, inspected HEAD `0e77c488a121dbaa63898d01cfea5d07cf340b73` plus existing local evaluator/comparator changes and an untracked comparison check. Preserved those files. Read the user's supplied `OrbitBridge-K20-K31-Owner-Replies.md` as review material and prepared the [KE2 response](ke2-k20-k31-owner-reply.md) for the user to send. It supplies D1–D6 replies, exact proposed partial/score rules, report-version candidate, current and intended callable scope, existing packet reference, evidence limits and owner blockers. No shared contract was ratified and no message was sent.

Completed the response-preparation subtask only; parent 00.2 and production tasks remain open. New scoring/report/record choices remain proposals. Named missing K22/K23 preparation documents for KE1, without requesting the already verified combined packet again. Next handoff is KE1 consolidation plus HPC producer semantics and SE/KE3 record/report integration.

Verification in this session: branch/status/diff and source/document inspection; reply-to-form coverage and packet SHA-256 checks; `git diff --check`. Gameplay results in the response are explicitly historical recorded fixture/native/headless evidence, not reruns. No Godot invocation, expanded-objective integration, browser or exported-build test was required for this documentation-only preparation.

## KE3 production request, retained proposal decision and callable comparison

At `features/KE2`, `0e77c48`, the user relayed KE3's request for production Survey/Communication/Weather evaluation and a callable comparison, confirming the original JSON packet/eight keys are already verified. Reused those artifacts without requesting them again. The user then explicitly chose **Keep scoring as a proposal** for the three expansion scoring formulas. Production scoring/report-v2 enablement remains unapproved; recorded the decision rather than asking repeatedly.

- [x] Delivered public `Comparison.compare_runs(a_record, b_record)` for existing SE v1 Imaging records, with bound run/mission IDs and execution keys, reproduction of approved report data, requirements/scenario matching and signed core deltas.
- [x] Keep absent/contradictory requested operations unclassified; explicit valid versioned policy/manual context yields Design or Design + operations. Optional unratified resource extrema remain null. No single-component causal guarantee is asserted.
- [x] Support original typed-key bytes for JSON-transported historical inputs without rewriting keys. Validate their hash and JSON values before typed reconstruction; no new packet or native scenario evidence was requested.
- [x] Harden production objective dispatch: unsupported Survey/Communication/Weather/unknown objectives return structured errors and cannot inherit Imaging's score.
- [x] New public API suite: 34 passed / 0 failed on actual native launches/current report publication, changed-goal run, preserved inputs, explicit manual-context fixtures and historical transport. Existing evaluator 294 / 0 / 5 pending; independent 125, Imaging 53, Results 17, Debrief 57 all pass with zero failures. T07/T08 wording now identifies missing SE runtime/baseline wiring; original pending count remains five.

See [callable API, exact commands and prepared KE3 reply](callable-comparison-ke3-handoff.md) and [verification hashes](evidence/callable-comparison-checks.json). API tests are direct native/module evidence, not UI Save A/B or new-objective runs. SE/KE3 integration, HPC semantics, KE1/SE/HPC v2 acceptance and final report/record contracts remain open. No other-owner implementation, signed contract, source packet, browser/export or remote action was changed/performed.

## K20–K31 owner reply reported delivered

On 15 November 2026 at `features/KE2`, `6554823`, the user reports they have already replied to KE1. Recorded delivery status in the owner-reply note/checklist and marked that handoff complete. Exact sent wording, teammate receipt and consolidated agreement were not independently verified. Do not ask the user to send the same reply or unchanged verified packet again.

Read-only inspection found the live canonical contract still identifies `v1.0-agreed` / schema 1; `data/mission_presets.json` and `scripts/core/mission_preset_catalog.gd` are absent from live production paths. The previously reviewed draft-2 artifacts remain received/archived. A consolidated frozen expansion revision has not been found in the checked paths. Next is receipt/reconciliation of KE1's freeze and remaining HPC/SE decisions, then actual Survey integration, Communication/Weather and expanded comparison. Callable v1 Imaging comparison is already available for SE/KE3 wiring.

Updated documentation only. Checks: branch/HEAD/status, explicit path existence, current contract/owner-note inspection, local links/fences and `git diff --check`. No gameplay/browser/export tests were rerun and no message or remote action was sent by Codex.

## Independent KE2 implementation completed for 16 November sync

On 15 November 2026 (Asia/Rangoon), at `features/KE2`, base `65548235958de72e531774670a785b0285032cf0`, completed the user's request to finish all independent KE2 work locally. Preserved four pre-existing documentation edits; no active evaluator/runtime, teammate code, signed contract, `.gitignore` or source packet was changed.

- [x] **10.2/10.3:** implement callable Survey evaluation/report2 candidate with captures, returned MB, complete selected-target coverage, by-target detail and proposed equal-thirds score. Native shortfall/complete mechanics give 83/100 under explicit sparse-zero trial policy. Strict default missing keys remain unavailable.
- [x] **20.1/20.3:** implement Communication and Weather report/scoring candidates. Historical native-mechanics proxy pairs reproduce 75/100; new same-config/quota Communication control yields 12 MB/one send/75 versus 24 MB/two sends at 7/10/100. Typed config-v2 fixtures are never presented as native config-v2 acceptance.
- [x] **30.1–30.3:** retain all 17 existing report fields plus objective/goals, same-run ordered evidence binding, malformed/nonterminal structured errors, deterministic input preservation, raw actuals, abort failed/null and neutral/evidenced feedback with one experiment.
- [x] **40.1/40.2 and KE2 portion of 40.3:** implement immutable record construction/verification, original execution-key byte retention and content digest, all-objective comparison eligibility, manual/policy classification, signed goal/MB/score/cost/mass/resource output. Unknown sampling/context remains unavailable; resource samples also match accepted event resource changes.
- [x] **50/60 independent scope:** final new suite 702 passed/0 failed. Seven-program KE2 runner passed; final focused rerun after additions is 702/0. Existing suites: evaluator 294/0/5 pending; independent 125, v1 comparison 34, actual Imaging cards 53, Results 17, Debrief 57 pass. Existing repository runner: all 43 active programs pass, exit 0. Godot version verified `4.7.2.stable.mono.official.ed1daf0bf`; known certificate-store diagnostic persists without check failures.
- [x] Prepared ten frozen candidate records, exact commands, verification hashes, local source/evidence archive and owner merge order in [the delivery note](ke2-integration-candidate.md). Updated README, scope/work checklists and prompt/owner-reply pointers in this session.

Commands: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_ke2_expansion_checks.ps1 -GodotExe $orbitGodot`; existing `run_all_checks.ps1` with the same verified executable; final direct `--headless --path . --log-file D:/orbitbridge-mission-architect/exports/check-logs/ke2_expansion_candidate_check.log --script res://tests/ke2_expansion_candidate_check.gd`; `git diff --check`. The exact executable assignment and reproduction commands are in the delivery note. Expected values and actual results agree, including all expanded qualifying-count deltas +1, score deltas +17 Survey / +25 Communication/Weather, and native Imaging +4.6133333328 MB/+19 score/+60 g/+7 credits.

Verification is fresh native v1 validator/adapter/engine plus labeled typed proxy fixtures and existing headless presentation/integration checks. No actual new-objective config-v2 producer acceptance, Save A lifecycle, browser, export or public deployment was claimed. The five original evaluator pending declarations remain. Remaining dependencies: **KE1** consolidated revision/config producer and custom identity; **HPC** sparse-map/contact/Weather/sampling semantics plus real new-objective traces; **SE** activation, bound publication, persistent A, runtime comparator and export; **KE3** dynamic goals/comparison and real report UI acceptance; **affected owners/KE2** adopt or revise proposed scoring/report/record policies together. Existing parent production items remain open. All work stayed local; no remote action, teammate message, commit or merge occurred.

## Evidence format for future completions

For each completed item, record its task ID, revision, owner, verification level, command or player steps, expected and actual values, run/event IDs where relevant, and an evidence link. For pending integration, name the missing producer/consumer handoff and its owner. Update the work-package status table when its state changes.
