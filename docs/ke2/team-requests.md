# KE2 replies and member requests

Prepared 14 November 2026 against `v1.0-agreed` and the validated KE1/HPC bundle. These messages are ready for the user to send. Attach the matching KE2 handoff ZIP when sending the SE and KE3 messages. [Handoff ZIP](../handoffs/ke3_validated_1u_55d4f33_9dfd942_20261114_01.zip), [report and evidence](../handoffs/ke3_validated_1u_55d4f33_9dfd942_20261114_01/README.md).

## Reply to KE3 and SE on Survey release scope

Prepared after KE3's scope question. The following reply proposes imaging-only release scope for SE/team confirmation.

Hi KE3 + SE — KE2 currently supports imaging evaluation under `v1.0-agreed`. The agreement starts with `mission.objective: imaging` and requires working evaluation support for an expansion.

I recommend an imaging-only release. At KE2 commit `c1ce6de39ee331300464ca9391dc73ee5dc786df`, `scripts/evaluation/mission_evaluator.gd` returns `INVALID_EVALUATION_INPUT` at `config.mission.objective` for Survey. Per-target Survey scoring remains pending.

SE, please confirm imaging-only release scope and align Creator/Launch accordingly, including loaded Survey drafts. KE3 can then present the imaging reports through the verified Results binding.

If the release requires Survey, we need agreed per-target delivery semantics, score weights, report fields and versioned examples for all goals met, a missing region, partial delivery and abort. KE2 can implement that extension once these are aligned with KE1/HPC/SE/KE3. Please record the final release-scope decision in the shared agreement or release note.

## Message to SE

Hi SE, thanks for the controller handoff. I recorded your local implementation based on `d60d224`, including publication, Retry, Abort, New Mission, error handling, and validation retention. Your tests used cached KE2 `f313e6f`.

I prepared `ke2-se-controller-v0.1.zip` for offline transfer. It includes the current KE2 evaluator/feedback pair with the native adapter, original validated trace and matching report, a standalone verification project, tests, current source ledger, and KE3's verification ZIP. Its manifest pins the supplied working-tree source bytes. The Git base is `79e249b`; the new Survey guard and standalone-test option are uncommitted KE2 changes. [Package instructions](../handoffs/ke2-se-controller-v0.1/README.md).

Please replace the cached imported evaluator/feedback pair with the supplied pair and use its existing `evaluate_hpc_state(state)` entry point. Current checks pass 167 standalone assertions and 207 against pinned KE1/HPC modules. Both APIs reproduce the original `ke3_validated_1u_55d4f33_9dfd942_20261114_01` report exactly. Please verify that original packet separately from `se_reference_reproduction_01`.

Survey's per-target delivery extension appears in your base revision, but the agreed KE2 scoring contract supplies aggregate goals. The current package returns `INVALID_EVALUATION_INPUT` at `config.mission.objective` for Survey, using the existing error envelope. This differs from your temporary `UNSUPPORTED_SURVEY_EXTENSION` code. Please route the supplied message/fix and send versioned Survey config/state/events examples plus proposed expected verdicts/scores for missing-region delivery, partial delivery, all goals met, and abort. We need aligned delivery semantics, score weighting, and report/display fields with KE1/HPC/KE3.

KE3 has now verified this report in its recorded Results preview. Its binding is `ke3/results_control.tscn` through `ke3/debrief_screen.gd`, using `set_inputs(context, state, report)`. Source identity is supplied by `data/ke3-results-verification/SOURCE_SHA256.json`; KE3's preview changes are currently local and uncommitted.

Please complete or share evidence for these controller steps.

- At completed or aborted terminal state, call `MissionEvaluator.evaluate_hpc_state(state)` with the native state containing `config_snapshot` and full `event_log`. It returns the agreed `ok/report` or `ok/error` wrapper.
- Publish one report per `run_id`. Verify duplicate terminal notifications and reopening Results preserve the existing result/history.
- Retry must assign a new run ID, reset counters/events, and preserve the eligible baseline. New Mission must clear the baseline.
- Retain the actual launch `ValidationResult` for source-credit linkage. Show evaluation errors through `message` and `suggested_fix` while preserving result/retry history.
- Please confirm the presentation mapping from HPC's complete `event_log` to the Results `state.events` history seam, with matching run IDs and original event order. Supply scoped credit records through `context.applicable_source_credits` and pass the unwrapped report dictionary to `set_inputs`.
- Verify the player-driven Launch, Operations, Results, and Retry flow with KE3, including Builder profile switching and the visible sample-1U mass criterion.

Please provide the changed local source and raw evidence as a hash-pinned portable snapshot while it remains uncommitted, or share the integration branch/commit when available. Include `mission_results.gd`, controller/runtime/screen changes, listed smoke tests/logs, and `controller-reference-reproduction.json`. Your Results implementation is named as `scripts/prototype/Screen.gd`; please confirm its connection to KE3's supplied `set_inputs` binding. KE3 and KE2 can then check reopening, Retry, New Mission, duplicate publication, and error routing on the shared revision. B02, official B10, and selected-export checks remain pending.

HPC has also supplied the actual operator-abort attempt `run_hpc_ke2_abort_3990d3c_01` at source commit `3990d3c`. KE2 verified its supplied hash, both evaluator APIs, and pinned producer replay with 71 passing checks. Its report is failed/aborted with null score and preserves counters and the operator reason. Please use this matching attempt for the integrated abort/Results check. [Abort handoff](../handoffs/ke2-hpc-abort-v0.1/README.md).

## Message to KE3

Hi KE3, thanks for the Results verification package for run `ke3_validated_1u_55d4f33_9dfd942_20261114_01`. I verified all 64 manifest hashes, all 16 named input hashes, the copied report/metadata/input identity, and the supplied logs and screenshots.

I have recorded your preview results of 63 headless / 67 windowed checks and the additional 24 headless / 29 windowed checks, all with zero failures. The report values, same-run `evt_008`, missing-evidence fallback, null-score handling, and scoped credits are covered by the supplied preview evidence. KE2's payload is accepted for this presentation path.

The binding is recorded as `ke3/results_control.tscn` -> `ke3/debrief_screen.gd`, `set_inputs(context, state, report)`. Your manifest identifies the current source bytes while the preview remains uncommitted.

Next, please coordinate with SE on its confirmed integration revision, especially complete-history mapping from HPC `event_log` to presentation `state.events` and credits through `context.applicable_source_credits`. We still need controller-driven reopening, Retry, New Mission, duplicate publication, and error-routing evidence. B02, official B10, and export verification remain pending.

Please share the resulting integration/source revision when available. I will keep the preview evidence and the integrated-controller checks recorded with their respective scope.

A real operator-abort report is now available for `run_hpc_ke2_abort_3990d3c_01`, with its original input history and abort event `evt_009`. KE2's 71 checks cover current evaluation and pinned KE1/HPC action/abort replay. This supplies the actual aborted-attempt payload for the shared-controller display check. [Abort handoff](../handoffs/ke2-hpc-abort-v0.1/README.md).

## Message to KE1

Hi KE1, thanks for the handoff. I confirmed the validator/loader entry points, 15-case manifest, saved results, runner, and recorded log at `55d4f33`.

The supplied evidence covers 1329 g passing and 1330/1331 g failing for `cubesat_1u_sample`, with the agreed strict `< 1330 g` rule and source ID. It also covers the alternative profile's own `<= 5000 g` rule, `source_id: null`, and illustrative assumption ID.

I have recorded your 470-check passing fixture suite as owner test evidence in the KE2 source ledger. An independent KE2 boundary-suite rerun remains pending. I will coordinate the Builder/profile-switch/Launch display with SE and source-credit display with KE3.

This supplies the requested KE1 boundary and profile evidence. Please let me know if the shared integration build changes the validator or catalog revision from `55d4f33` so our evidence stays aligned.

## Message to HPC

Hi HPC, thanks for the operator-abort bundle. Its SHA256 matches `4283f1dc663736b46462cbbb452f5fd1c5ab91cf0caa892c3e7c21f55c60697b`.

Current KE2 evaluation and pinned producer replay at `3990d3c` pass 71 checks. Both evaluator APIs return `run_status: aborted`, `status: failed`, and `score: null` for `run_hpc_ke2_abort_3990d3c_01`. Step 8, one capture, returned/stored MB, and the recorded operator reason are preserved. The history includes the `evt_008` no-contact block and `evt_009` operator abort.

I also checked the commit ancestry from `9dfd942`, replayed the actual readiness-approved action sequence and `abort_run`, and recorded the supplied local/uncommitted bundle identity separately from its producer source commit. The requested abort handoff is complete.

The matching report and verification package are ready for SE/KE3's shared-controller tests. Please flag any producer revision change chosen for that integration so we can keep the evidence aligned. [KE2 abort report and verification](../handoffs/ke2-hpc-abort-v0.1/README.md).
