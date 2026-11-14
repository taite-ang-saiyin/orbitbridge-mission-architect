# Independent KE2 implementation sequence

Started on 15 November 2026 at `features/KE2`, HEAD `f04ab66` plus preserved working changes. The user authorized the ordered independent sequence 20.1, 20.3, 40.1, 40.2, 30.2 and 30.3. New modules are internal/unwired; unsettled mapping, comparison, sampling and feedback rules remain explicitly marked proposals. No shared production contract or other-owner implementation is changed.

Subsequent update at `0e77c48`: the [public v1 Imaging comparison](callable-comparison-ke3-handoff.md) now accepts existing SE records and passes 34 native/API checks. The internal expansion prototypes below remain proposals. The user explicitly retained expansion scoring as a proposal; production evaluator now rejects every unsupported objective rather than allowing an Imaging fallback. The historical results below retain their original scope.

## 20.1 Communication counting

Added `mission_goal_evidence.gd` with internal accepted-event measurement and strict same-execution validation. Positive accepted Transmit steps count once; two steps in one contact window count twice. Exact duplicate events are deduplicated, conflicting IDs/foreign runs/invalid MB fail, and rejected/zero-MB requests add nothing. Whole-valued int/float steps normalize to the same integer identity.

Initial focused verification: 25 passed / 0 failed, including counts from all eight historical native runs in `ke2-handoff-current.json`. These are existing recorded native inputs, not new Communication-v2 runs. Native type/card/report enablement, scoring and HPC ratification remain pending.

Final verification and later sequence entries are appended below as completed.

## 20.3 Weather counting

Added same-run selected-target capture counting using the frozen orbit's positive whole `steps_per_orbit`. The proposed mapping derives revolution indices from pre-action event steps, deduplicates captures per revolution, excludes other targets and rejects missing/contradictory mapping evidence. Output explicitly labels the mapping pending HPC. It never substitutes orbit preset ID for revolution identity.

Focused suite now 42 passed / 0 failed: 17 added checks cover mapping boundaries including a three-step orbit, missing metadata and two historical native Imaging-mechanics Weather proxies. No Weather-v2 report/card is enabled; missing-evidence production policy and goal weights remain open.

## 40.1 Comparison eligibility

Added the unwired `mission_comparison.gd` prototype against explicit normalized fixture records. It requires completed, readiness-approved executions; verifies retained hash bytes and matching input values; binds report identity/goals/actuals and cause references; matches requirements, target order, setup, context versions and actual scenario snapshots. Unknown context blocks comparison. Full-battery/empty-start and legacy identity policies are explicit fixture proposals, not inferred production guarantees.

Matching requested policy/manual overrides yields proposed Design; changed manual requests yield Design + operations. Availability-derived requested/accepted differences under the same policy do not imply a manual change. Aborts, unfinished/tampered records, changed initial conditions/versions/goals/schedules and negative manual indices are rejected with actionable reasons. The typed-preimage approach preserves the earlier JSON transport finding without changing SE's hashing function.

Focused suite now 65 passed / 0 failed, adding 23 compatibility checks. The historical radio pair is eligible only under this labeled normalization/proposed legacy policy. No SE Save A record or actual comparator integration is claimed.

## 40.2 Signed comparison measures

The internal delta helper returns supplied outcomes, requirement/goal snapshots, raw per-target delivery maps, changed component IDs and signed B-minus-A values. The historical radio pair reproduces +4.6133333328 MB, +60 g, +7 credits, +19 score points and approximately -0.4616666667 Wh minimum battery. Percent changes are percentage points. Identical/reversed pairs demonstrate zero/negative deltas.

Resource extrema use the explicitly named **proposed** initial-and-every-accepted-poststep/terminal sampling definition. Missing/unsupported/incomplete or invalid samples yield null optional values/deltas, not zero or extrema from a subset. Samples must cover every step and match initial/final resource values. Missing readiness cost stays unavailable. Reports, source records and caller inputs remain unchanged; interpretation limits claims to the measured pair.

Focused suite now 81 passed / 0 failed, adding 16 measure checks. Final sampling IDs, saved-record format, content digest and comparison output remain proposals requiring SE/HPC coordination before wiring.

## 30.2 Boundary and preservation checks

Added 21 cases for malformed/future steps, strictly positive tiny MB, absent/fractional state, incomplete retained history, duplicate evidence, report-only mutation, missing legacy fields, whole-valued JSON versions, fractional capture goals, unknown cause IDs and malformed samples. Native retained event history must match after exact-entry deduplication. A fixture-only report digest guards accidental report changes separately from the execution preimage. This is not SE's final whole-record digest or a serialization fix.

Focused suite now 102 passed / 0 failed. Re-ran the existing evaluator suite: 294 passed / 0 failed / 5 original pending. Existing abort/null-score, structured-error, determinism and input-preservation assertions remain green. Production expanded-objective abort/evidence behavior and final contracts remain pending.

## 30.3 Evidence-based feedback

Added `mission_goal_feedback.gd` as an unwired proposal using the existing verified blocked-event vocabulary. It checks same-run history and goal actuals before citing one recorded contact/storage block and offering one corrective experiment. Unknown/irrelevant/foreign/conflicting/absent or contradictory evidence produces neutral text and empty causes. Recorded abort reasons are preserved.

Survey missing sparse entries remain unavailable; an explicit-zero fixture can receive a remaining-packet experiment without inventing a causal event. Weather advice labels the proposed mapping and never presents it as a confirmed cause. Existing production `mission_feedback.gd`, source IDs and source-credit policy remain unchanged by this module.

Focused suite now 117 passed / 0 failed, adding 15 feedback checks. All six requested independent task outputs are implemented and verified. Their parent integration/owner-confirmation tasks remain open.

## Source-ledger integrity audit

Also completed the independent integrity/presence work from the earlier task list. Eight additional checks verify unique source IDs, the local PDF's recorded SHA-256, recorded Appendix C/item/page/index and mass-boundary metadata, current implementation paths, and historical report/readiness references. Corrected only two stale `path_present_in_checkout: false` entries for the existing KE1 validator/profile catalog and recorded the presence-check date. NASA text, source-verification dates/status, rule values, credits and gameplay/export acceptance statuses were not promoted or changed. The PDF was hashed, not newly read or visually reviewed.

## Final verification and rerun commands

Confirmed Godot `4.7.2.stable.mono.official.ed1daf0bf`. Final runs:

| Program | Passed | Failed | Pending | Scope |
| --- | --- | --- | --- | --- |
| `ke2_independent_work_check.gd` | 125 | 0 | Owner/integration dependencies below | New pure/internal algorithms, labeled fixtures, historical native inputs, source-ledger integrity |
| `test_mission_evaluator.gd` | 294 | 0 | 5 original declarations | Existing contract/proposal fixtures plus actual native engine/packet checks |
| `ke2_imaging_presets_check.gd` | 53 | 0 | None for existing cards | Actual buttons, native runs, publication and headless Debrief |
| `ke2_results_integration.gd` | 17 | 0 | Expanded integration remains open | Existing runtime/publication/retry module integration |
| `debrief_summary_check.gd` | 57 | 0 | Expanded UI remains open | Headless legacy report UI/credits |

All final commands exited 0. `git diff --check` passed. The certificate-store diagnostic persists. The full 43-program runner, new-objective runtime publication, actual Save A/B workflow and exported/public browser builds were not exercised. Source/log hashes and the chronological checkpoint counts are retained in [the verification record](evidence/independent-ke2-checks.json).

Run from the repository root:

```powershell
$godot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $godot --version
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_independent_work_check.log' --script res://tests/ke2_independent_work_check.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/test_mission_evaluator.log' --script res://tests/test_mission_evaluator.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_imaging_presets_check.log' --script res://tests/ke2_imaging_presets_check.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_results_integration.log' --script res://tests/ke2_results_integration.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/debrief_summary_check.log' --script res://tests/debrief_summary_check.gd
git diff --check
```

## Files and integration boundaries

Added `scripts/evaluation/mission_goal_evidence.gd`, `mission_comparison.gd`, `mission_goal_feedback.gd` and `tests/ke2_independent_work_check.gd`. They are imported only by the new focused suite and each other, not by production evaluator/controller/UI entry points. Private prototype methods do not change the agreed `evaluate_mission` signature or existing report schemas. Existing `mission_evaluator.gd`/`mission_feedback.gd`, other-owner code, signed agreements and previous working changes were preserved. The only existing data change is source-ledger presence metadata; tracking documents are updated separately.

The normalized comparison fixture includes a report digest and original execution preimage bytes. Those names/strategies and sampling/legacy/initialization IDs are explicit test proposals. They do not settle SE's saved-record API, complete-record digest or JSON normalization. Goal rows, classifications and reason codes from these private helpers are not ratified public report properties.

Remaining owner checks:

- HPC: confirm event/packet/sparse-map/revolution meanings, sampling boundaries and real Communication/Weather traces. Weather mapping and resource sampling remain labeled proposals.
- KE1/SE/HPC: deliver the coordinated production v2 config path; the already-received KE1 registry is not requested again.
- KE2 with affected owners: settle scoring/partial rules, report/output revision and comparator rules before enabling new outputs.
- SE: final normalized record/serialization/content-digest contract, independent saved-A implementation, eligibility/call wiring and lifecycle evidence. The observed JSON transport key issue remains unresolved.
- KE3: dynamic goal/comparison presentation and live report/credit/evidence acceptance after agreed outputs arrive.

All six independent implementations plus the source integrity audit are complete within this preparation scope. Parent 20.1/20.3/40.1/40.2/30.2/30.3 production acceptance remains open. No remote action was taken.
