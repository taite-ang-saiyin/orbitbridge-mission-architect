# KE3 Debrief display-contract follow-up

Recorded on 15 November 2026, Asia/Rangoon, at `features/KE2`, HEAD `f04ab662e19c3ada6fdbd2240e355f27541a9e46` plus local documentation changes. Source: the user's further relayed KE3 response. This clarifies the existing [KE3 schema agreement](ke3-report-schema-agreement.md); no new approval request is needed for that display shape.

## Confirmed scope

KE3 agrees to the proposed Debrief display contract based on the [four original report examples](evidence/report-examples-proposal.json). Independent JSON checks confirm exactly **9 goal entries and 2 Survey target rows**, required goal fields, consistent capped ratios and supplied verdicts, and preservation of every original Imaging report field/value.

- Use supplied goal IDs, actuals, requirements, units, met states, completion ratios and evidence IDs; Survey adds per-target detail. No additional display fields are requested for these examples.
- Render the goal list dynamically. Retain the existing Imaging display when `goal_progress` is absent.
- Display evaluator-supplied scores, outcomes, goal verdicts and ratios. Support aborts/null scores, unavailable values, measured zero, empty causes and `comparison: null`.
- Resolve evidence only against the matching execution. Missing references show as unavailable. Preserve report `source_ids` and separately scoped source credits.
- This confirms presentation suitability only. Unresolved goal semantics, scoring and report-version changes remain open. Implementation and integrated UI verification are pending.

The original report examples remain unchanged. KE3's review does not approve the separately prepared report-v2 candidates or their version/revision proposal. The [separate SE review](se-report-review-and-version-proposal.md) records acceptance in principle with serialization/binding/version/retention details still under review.

## Consumer ownership

KE3 identifies `scripts/prototype/Screen.gd`, `scripts/presentation/DebriefSummary.gd`, `DebriefPresentation.gd` and `PlayerLanguage.gd` for dynamic rows, understandable labels/units, expanded binding/evidence and replacing fixed photo/data assumptions. These remain KE3 presentation changes.

KE3 also identifies `scripts/integration/mission_results.gd` for coordinated report adoption and retention. That file remains **SE-owned**; its inclusion is a cross-owner handoff, not authorization to edit it as KE3 work. The supplied `C:/Workspace/OrbitBridge/...` links identify equivalent repository-relative paths, not evidence of files delivered to this `D:/` checkout. The earlier reply's planned `GoalProgress.gd` likewise does not establish implementation receipt.

## Verification and tracking

Commands: `git branch --show-current`, `git rev-parse HEAD`, `git status --short`, `git diff --stat`, focused document reads, inline Python JSON/link checks and `git diff --check`. The JSON assertions checked `id`, `actual`, `required`, `unit`, `met`, `completion_ratio`, `evidence_event_ids`, exact goal/target counts, capped ratios, actual-versus-required verdicts and unchanged original Imaging field values. Checks passed.

Only this follow-up and its progress entry are added for the clarification. Other local SE review/evidence/example changes were preserved; an attempted shared-note patch failed because those notes changed concurrently, so it was not reapplied over that work. No production file, signed contract or report payload changed. No fixture simulation, native-module, integrated UI, browser or export test was run. Existing KE3 agreement checkboxes remain complete; implementation and parent acceptance tasks remain open.

Next dependencies: KE2's Survey scoring decision, HPC's sparse-map/packet/revolution/sampling semantics, SE's version/binding/retention decisions, and coordinated evaluator/consumer implementation. This reply requires no repeat KE3 display-schema approval and does not settle those separate decisions.
