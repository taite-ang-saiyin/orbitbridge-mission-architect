# KE3 report-schema agreement

Recorded on 15 November 2026, Asia/Rangoon, at `features/KE2`, `f04ab662e19c3ada6fdbd2240e355f27541a9e46`. Evidence: the user relayed KE3's written response to the [report handoff](ke3-se-hpc-report-handoff.md) and [four examples](evidence/report-examples-proposal.json).

Although the selected earlier request was addressed to SE, the supplied response explicitly identifies KE3, describes KE3 consumers and limits agreement to KE3's review. Record this as KE3 agreement only. SE's separate response arrived subsequently, as recorded below.

Subsequent update: [SE's separate conditional review is now received](se-report-review-and-version-proposal.md). It proposes legacy report v1 and expanded report v2, with exact revision/evidence details still open. KE3's earlier schema agreement does not establish support for that later version strategy; confirm dual-version consumer handling during coordination.

## Confirmed by KE3

KE3 agrees that the proposed `goal_progress` schema supplies the required Debrief data, with no required field changes:

- Every goal supplies `id`, `actual`, `required`, `unit`, `met`, `completion_ratio` and `evidence_event_ids`.
- Survey `by_target` supplies target identity, actual/required complete deliveries and returned MB. The parent Survey goal's evidence IDs suffice for a goal-level evidence link; additional child evidence fields are not required by this reply.
- Use supplied goal progress for expanded reports, retaining the existing captures/returned-data display for older Imaging reports.
- Display KE2's supplied outcomes, scores, goal verdicts and ratios. An aborted run retains its null score. Measured zero and `met: false` remain visible; missing values show **Unavailable**.
- A missing Survey delivery map remains unavailable. The meaning of an omitted target inside a valid sparse map still awaits HPC.
- Resolve evidence against the same execution; retain report `source_ids` and scoped source credits.

This confirms schema suitability for KE3's implementation. It does not approve scoring weights, partial-result rules, SE's storage/versioning interface or completed live integration. Public report production and the signed shared contracts are unchanged by recording this reply.

## KE3 implementation handoff

| Planned consumer | Responsibility in KE3's reply |
| --- | --- |
| `scripts/presentation/GoalProgress.gd`, `PlayerLanguage.gd` | Goal rows, units, labels and Survey target detail |
| `scripts/presentation/DebriefPresentation.gd` | Bind objective/goals to the exact execution and resolve evidence |
| `scripts/presentation/DebriefSummary.gd` | Explain supplied missed goals, including Survey delivery shortfall despite met aggregate goals |
| `scripts/prototype/Screen.gd` | Dynamic goal list in `show_actual_run()`, preserving legacy Imaging display |

Implementation and live expanded-objective acceptance remain pending. `GoalProgress.gd` is a planned path in the reply and is absent in the inspected checkout; no code delivery was inferred. KE3 owns these consumer changes.

## Remaining decisions and checks

- SE: structure accepted in principle; report-v2 and saved-A proposals received. Settle exact revision/selection, serialization, properties and version/snapshot propagation with affected owners.
- KE2 with affected owners: settle Survey/new-goal scoring and partial-result semantics. The existing three-way Survey weighting and proposed partial/83 example remain proposals.
- HPC: confirm missing/sparse delivery entries, packet completion, revolution evidence and sampling semantics.
- KE2/KE3/SE: implement coordinated output/consumer changes and verify the four objective types, legacy Imaging, abort/null score, unavailable data, evidence and credits against bound executions.

## Verification

Read-only inspection verified the live branch/HEAD, clean starting working tree, current handoff/checklists and all four example goal field sets. Survey target rows contain the fields described in the reply. Checked `GoalProgress.gd` with `Test-Path` (false). Updated documentation/checklist status only; no evaluator, runtime, UI, contract or example payload changed.

Commands included `git branch --show-current`, `git rev-parse HEAD`, `git status --short`, `git diff --stat`, `Test-Path scripts/presentation/GoalProgress.gd`, inline Python JSON field/link checks and `git diff --check`. Documentation checks passed. No Godot suite, fixture simulation, browser or export was run for this owner-response update.
