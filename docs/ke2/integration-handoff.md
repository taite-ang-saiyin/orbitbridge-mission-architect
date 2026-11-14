# KE2 integration handoff

Owner KE2. Prepared 14 November 2026 for KE1, HPC, SE, and KE3 against `v1.0-agreed`.

The current KE3 handoff includes a complete original MissionReport, every field/type, nullability, the actual scene binding, error routing, comparison display, reset guidance and candidate verification. The reviewed candidate is `14c0f97`, with integration implementation `b23de72`. [KE3 Results handoff](ke3-results-handoff.md).

## Team boundaries

| Owner | Handoff to or from KE2 | Current evidence |
| --- | --- | --- |
| KE1 | Validated config, positive goals, selected profile, readiness result, and sourced mass-check fields | Real readiness-approved launch and 470 independently rerun fixture checks verified; Builder boundaries pending |
| HPC | Terminal state, run/mission identity, ordered events, received/stored MB, successful capture count | Native engine completion, blocked transmission, and operator abort verified at b9817c3 |
| SE | Immutable launch config, terminal evaluation call, error handling, one report per run, retry/reset state | Candidate actual route and 57 Results/lifecycle checks verified; selected-release manual acceptance pending |
| KE2 | Structured evaluation wrapper with score, status, evidence, and next experiment | Evaluator, feedback, tests, ledger, and recorded report available |
| KE3 | Rendered report, event references, retry interaction, and source credits | Candidate scene verified through the actual adapter, including original partial/abort reports, evidence, credits and clearing stale display |

## Invocation

Use this expression in the controller's terminal handler, with the launch snapshot and the matching run's terminal state/events.

```gdscript
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")

func preview_terminal_report(
    config: Dictionary, final_state: Dictionary, events: Array
) -> void:
    var result: Dictionary = Evaluator.evaluate_mission(config, final_state, events)
    if result["ok"]:
        var report: Dictionary = result["report"]
        print(report["explanation"])
    else:
        var error: Dictionary = result["error"]
        print(error["message"])
        print(error["suggested_fix"])
```

This preview illustrates the evaluator API. The actual candidate calls `mission_results.presentation(trace)` then `report_view.set_inputs(payload.context, payload.state, payload.report)` in `Screen.show_actual_run`. The fourth evaluator argument accepts a comparison baseline and is reserved for optional comparison.

For a native `MissionStepEngine` terminal state, call `Evaluator.evaluate_hpc_state(state)`. This uses the retained launch config and cumulative event log. HPC's `terminal_reason` is supported for abort feedback. The current combined KE1/HPC/KE2 suite passed 207 checks in the isolated pinned project. [Mapping and runtime checks](hpc-integration.md).

## MissionReport fields

The success wrapper contains `ok: true` and `report`. All fields below are present in a successful evaluation response. `ok` indicates whether evaluation produced a valid report. The mission verdict is in `report.status`.

| Field | Value type | Meaning and display |
| --- | --- | --- |
| `schema_version` | Integer | `1` |
| `run_id` | String | Identity of this attempt, used to prevent duplicate publication |
| `mission_id` | String | Identity of the mission |
| `run_status` | String | `completed` or `aborted` |
| `status` | String | `success`, `partial`, or `failed`, mapped to readable UI labels |
| `observations_completed` | Whole number | Raw successful captures, possibly above target |
| `required_observations` | Positive whole number | Goal from the launch snapshot |
| `returned_data_mb` | Number | Raw MB received on Earth, possibly above target |
| `required_returned_data_mb` | Positive number | Return goal in decimal MB |
| `observation_completion_ratio` | Float | Capped 0-1 ratio, multiply by 100 for a display percentage |
| `data_return_completion_ratio` | Float | Capped 0-1 ratio, multiply by 100 for a display percentage |
| `score` | Integer or null | 0-100 for completed runs, null for aborts |
| `explanation` | String | Mission summary with onboard/returned distinction and supported evidence |
| `root_causes` | Array of dictionaries | Supported causes, or `[]` when evidence is insufficient |
| `next_experiment` | String | Primary concrete change to try on retry |
| `source_ids` | Array | Source references used by the report, currently `[]` |
| `comparison` | Dictionary or null | Optional comparison result, currently always null |

Raw count fields can contain whole-valued floats after JSON loading. Format them as counts in the UI. Format decimal MB consistently while retaining the original values for evaluation and comparison. Display a null abort score with an unscored/aborted label. Empty causes can use the report's neutral explanation. An absent comparison can hide the comparison area or show that comparison is unavailable.

Each root cause has four fields.

| Field | Type | Meaning |
| --- | --- | --- |
| `code` | String | Recorded simulator reason code |
| `segment` | String | Current feedback emits `space` or `ground` |
| `evidence_event_ids` | Array of strings | References into the matching run's event timeline |
| `explanation` | String | Evidence-based cause and corrective action |

Stored MB is consumed from `final_state` and appears in the explanation. A dedicated structured onboard-data display can bind HPC's `stored_data_mb` alongside the report. The agreed report fields are listed in the technical contract. [Contract](../contracts.md#8-missionevaluator-missionreport-and-evaluationerror).

## EvaluationError fields

The error wrapper contains `ok: false` and `error`.

| Field | Type | Meaning |
| --- | --- | --- |
| `code` | String | `INVALID_EVALUATION_INPUT` or `NONTERMINAL_RUN_STATE` |
| `field_path` | String or null | Input location when available |
| `message` | String | Human-readable problem |
| `suggested_fix` | String | Correction to show the caller/player |
| `run_id` | String or null | Available valid run identity |

On an error, SE shows the correction and preserves result/retry history. A valid aborted run uses the report wrapper with `run_status: aborted`, `status: failed`, and `score: null`. [Top-level error example](../contracts/v1-draft/evaluation-top-level-error.example.json), [nonterminal example](../contracts/v1-draft/evaluation-nonterminal-error.example.json), [abort example](../contracts/v1-draft/evaluation-aborted.example.json).

## Recorded HPC example

The existing handoff evaluates run `run_ke2_handoff_v01` at terminal step 60/60. It records 1/4 observations, 7.7333333328/30 MB received on Earth, 4.2666666672 MB onboard, status `partial`, and score 25. Cause `NO_LINK_WINDOW` references blocked-transmit event `evt_008`. The accepted transmission is `evt_007`. [Complete evaluation wrapper](../handoffs/ke2-hpc-report-v0.1.json), [provenance and event evidence](../handoffs/ke2-hpc-report-v0.1.metadata.json).

The sample carries `launch_approved: false`. Its verification covers the recorded trace and evaluator output. Engine replay, approved readiness, Results, retry/reset, and export checks remain pending. [Detailed verification record](../handoffs/ke2-hpc-report-v0.1.md).

## Lifecycle and remaining integration

1. SE validates the current design at Launch and retains its config snapshot.
2. HPC initializes a new run identity and produces state/events using the agreed units.
3. At a terminal state, SE calls the evaluator with the matching snapshot, state, and ordered events.
4. SE publishes a successful evaluation result once per `run_id`. Reopening Results and repeated terminal notifications reuse that result.
5. Retry starts a fresh run with fresh counters/events and preserves an eligible baseline. New Mission clears the baseline.
6. KE3 renders the report and resolves event/source references from the same attempt.

Candidate controller wiring and lifecycle checks now have execution evidence at `14c0f97`. Original partial/abort reports also pass the adapter-to-scene binding checks. Manual selected-release and export acceptance remain pending. Native producer abort metadata is verified as the `terminal_reason` string at b9817c3. The older `abort_reason` string/dictionary boundary remains supported. The existing recorded sample uses empty source IDs. [Current KE3 binding](ke3-results-handoff.md), [NASA integration evidence](nasa-sources.md), [HPC runtime verification](hpc-integration.md).

Optional controlled retry comparison remains P1. The agreement requires completed eligible attempts with matching scenario, goals, and duration, plus preserved design/action metadata for changed-choice explanations. Current output is `comparison: null`. [Lifecycle and comparison contract](../contracts.md#9-controller-migration-lifecycle-and-comparison).

## Reviewed KE3 Results preview

KE3 supplied `data/ke3-results-verification` for run `ke3_validated_1u_55d4f33_9dfd942_20261114_01`. KE2 checked all 64 source/evidence hashes and all 16 named input hashes, compared copied inputs/report/metadata with the originals, reviewed recorded command outcomes, and inspected four screenshots. The source manifest SHA256 is `e1f86bc937c5b0dc87f0a33a07e60e1395156c593cc0a00940ab59fe421b1256`. [Source manifest](../../data/ke3-results-verification/SOURCE_SHA256.json), [owner verification notes](../../data/ke3-results-verification/verification/KE2_REPLY_CHECKS.md).

| Consumer detail | Reviewed implementation or evidence |
| --- | --- |
| Results scene | `ke3/results_control.tscn` |
| Script and method | `ke3/debrief_screen.gd`, `set_inputs(context, state, report)` |
| Preview entry | `preview/ke2_validated_preview.tscn` |
| Report argument | Unwrapped `evaluation.report` dictionary |
| Identity | Context, state, report, and linked event history refer to the same run |
| History | Preview provider places original ordered history into presentation `state.events` |
| Credit context | `context.applicable_source_credits` carries scoped readiness and feedback-vocabulary records |
| Display | partial/completed, score 25, 1/4 observations, 7.7333333328/30 MB, 25%/25.78%, and onboard summary |
| Evidence fallback | Missing `evt_008` shows Evidence Unavailable while retaining the supplied report |
| Edge cases | Empty causes, synthetic abort/null score, and exact contract-error wrappers covered in owner preview tests |
| Focused checks | Owner recorded 63 headless and 67 windowed, zero failures |
| Additional edge checks | Owner recorded 24 headless and 29 windowed, zero failures |
| Revision | Local uncommitted preview source, identified by the supplied manifest. KE3 commit SHA remains unavailable |

KE2's review used the supplied source, hashes, logs, and screenshots. It preserves the execution attribution to KE3. Report payload correction is unnecessary for this reviewed presentation path.

The candidate's `mission_results.presentation(trace)` implements the projection from native cumulative `event_log` to KE3's `state.events`, retaining the original order and identity. The Results method receives the unwrapped report together with context and presentation state. This mapping is now verified through both the candidate route and original partial/abort binding checks. [Current handoff](ke3-results-handoff.md), [reviewed provider](../../data/ke3-results-verification/preview-source/preview/ke2_recorded_provider.gd), [reviewed Results source](../../data/ke3-results-verification/preview-source/ke3/debrief_screen.gd).

Candidate checks cover reopening, Retry, New Mission catalog reset, duplicate publication and error routing. Manual selected-release acceptance, B02, official B10, exports and source-link opening remain pending. The earlier supplied preview identifies its local source bytes independently of the reported clean team checkout at `main@1a82ebd93a019b751947965aa760e8e759d8f45b`.

## Earlier SE controller reply

SE's received handoff reports uncommitted controller/results changes based on `d60d224`, using cached KE2 `f313e6f` and a locally added native-state shim. It identifies `MissionController.on_terminal_state`, `mission_results.publish/baseline_for`, retry/abort/New Mission, and `scripts/prototype/Screen.gd` Results methods. Its latest source, raw logs, and saved reproduction JSON await delivery. The cached SE base is available for inspection. Acceptance of the latest controller execution remains pending that evidence and the shared KE3 walkthrough.

The subsequent candidate `14c0f97` supplies the implementation and passing execution evidence described in the current KE3 handoff. Its KE2 modules match root `dbf65ad`.

The KE2 offline package supplies the current native adapter and original validated packet. The new explicit Survey guard uses the existing `INVALID_EVALUATION_INPUT` envelope. The current code passes 167 standalone and 207 pinned combined assertions and reproduces the original report exactly. Its source snapshot extends Git base `79e249b` with uncommitted guard/test changes, identified by package hashes. SE's earlier runtime API can run the standalone suite with `-- --ke2-standalone`. [Package and commands](../handoffs/ke2-se-controller-v0.1/README.md).

The Survey extension needs versioned config/state/event examples, expected results, delivery semantics, scoring weights, and consumer fields aligned across the affected owners. The candidate's prototype Results methods now connect to KE3's `set_inputs` binding. Manual acceptance on the selected release and exported-build verification remain open.
