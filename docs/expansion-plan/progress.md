# Expansion Progress Record

Last updated on 15 November 2026 in Asia/Rangoon.

Use the [team scope](team-scope-v2.md) and [KE2 task checklists](ke2-work-plan.md) for checkbox status. This record holds evidence, current dependencies, and completion history.

## Current status

| Work package | Status | Owner and next action |
| --- | --- | --- |
| Markdown plans and task tracking | Complete | Both supplied PDFs converted, task IDs retained, and tracking instructions added |
| 00 Contracts and handoffs | In progress | KE1 draft-2 artifacts received, hashes verified and 629 checks reproduced in isolation. 00.3 evidence request and 00.4 examples are prepared. Remaining bounds/custom identity, owner alignment and production integration stay open |
| 10 Imaging and Survey | In progress | 10.1 complete, 53 checks. 10.2 private helper/fixtures and native packet checks verified: evaluator now 254 passes. HPC absent-entry policy, Survey scoring and public integration remain open |
| 20 Communication and Weather | Open | KE1/HPC prove goal feasibility, KE2 implements agreed evaluation |
| 30 Reports and feedback | In progress | 30.1 proposal reviewed against current consumers and four source-bound examples. KE2/KE3/SE agreement and output/presentation migration remain open |
| 40 A/B Design Lab | Open | SE confirms separate storage/navigation can start now. Await implementation commit and lifecycle evidence. KE2 matching/deltas and KE3 presentation continue against the pending contract |
| 50 Expansion acceptance | Open | Collect fixture, integrated, and public-browser evidence for the expanded revision |
| 60 Release | Open | SE confirms templates, public URL, and deployed revision, team verifies final journeys |

## Baseline and verification

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
| D02 | Survey three-way weighting and qualifying progress | KE2 + affected team owners | Proposed, confirm task 10.3 rules before treating the 83 example as approved behavior |
| D03 | Accepted-event fields, absent Survey target entries, and revolution identity/mapping | HPC + KE2 | Source map and existing-run excerpt in [HPC handoff](hpc-evidence-handoff.md), confirm mapping, sparse-map/legacy handling, and packet semantics with HPC |
| D04 | Communication/Weather thresholds and stock-design feasibility | KE1 + HPC + KE2 | KE1 confirmed the specified high_inc two-capture/basic-instrument/fast-radio Communication starter. Existing [headless evidence](ke3-ke2-results-ab-handoff.md) exercises Imaging mechanics proxies. Actual typed v2 runs, Weather revisit policy, and HPC confirmation remain pending |
| D05 | Extended report schema and existing-field compatibility | KE2 + KE3 + SE | [00.4 proposals](ke3-ke2-results-ab-handoff.md) prepared with actual Imaging and engine-backed proposed new-goal reports. Agree fields and implement evaluator/consumer migration |
| D06 | Comparison matching, action-policy identity, and independent saved-A record | KE1 + HPC + SE + KE2 | Measured radio-swap pair and signed-unit payload proposal prepared, actual baseline call still returns null. Agree eligibility/versions/sampling, implement KE2 comparator and SE saved-record/call wiring |
| D07 | Save A eligibility from the reached active execution | SE + KE2 | SE confirms storage/navigation can start now. Gate Save A on reached completion and its bound report, then supply actual lifecycle evidence and the implementation commit |
| D08 | Web templates, Netlify URL, deployed revision, and browser evidence | SE + team | Open, confirm release dependencies and test public journeys |
| D09 | Newer recorded main producer/controller baseline | SE | Open, recorded `origin/main` is `dce75db`. SE requests exact owner commits, combined integration revision, commands, exit codes and example run records before production integration |
| D10 | KE1 registry, catalog API, and validation tests | KE1 | User reports KE1 will share later. At this update, `data/mission_presets.json`, `scripts/core/mission_preset_catalog.gd`, and `tests/validation/test_mission_presets.gd` are absent locally |

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

## Evidence format for future completions

For each completed item, record its task ID, revision, owner, verification level, command or player steps, expected and actual values, run/event IDs where relevant, and an evidence link. For pending integration, name the missing producer/consumer handoff and its owner. Update the work-package status table when its state changes.
