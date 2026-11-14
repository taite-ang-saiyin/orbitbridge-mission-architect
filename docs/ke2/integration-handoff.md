# KE2 integration handoff

Owner KE2. Prepared 14 November 2026 for KE1, HPC, SE, and KE3 against `v1.0-agreed`.

## Team boundaries

| Owner | Handoff to or from KE2 | Current evidence |
| --- | --- | --- |
| KE1 | Validated config, positive goals, selected profile, readiness result, and sourced mass-check fields | Real readiness-approved launch verified with HPC at b9817c3, mass boundary cases pending |
| HPC | Terminal state, run/mission identity, ordered events, received/stored MB, successful capture count | Native engine completion, blocked transmission, and operator abort verified at b9817c3 |
| SE | Immutable launch config, terminal evaluation call, error handling, one report per run, retry/reset state | Controller call sites and complete lifecycle verification pending |
| KE2 | Structured evaluation wrapper with score, status, evidence, and next experiment | Evaluator, feedback, tests, ledger, and recorded report available |
| KE3 | Rendered report, event references, retry interaction, and source credits | Field meanings and recorded payload supplied below, actual screen verification pending |

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

This preview illustrates the existing API. SE binds the returned dictionaries to the actual navigation and Results methods when those call sites are available. The fourth argument accepts a comparison baseline and is reserved for optional comparison.

For a native `MissionStepEngine` terminal state, call `Evaluator.evaluate_hpc_state(state)`. This uses the retained launch config and cumulative event log. HPC's `terminal_reason` is supported for abort feedback. The combined KE1/HPC/KE2 suite passed 205 checks in the isolated pinned project. [Mapping and runtime checks](hpc-integration.md).

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

Actual controller/Results bindings, mass boundary evidence, source-credit lookup, and export behavior await their owner handoffs. Native producer abort metadata is verified as the `terminal_reason` string at b9817c3. The older `abort_reason` string/dictionary boundary remains supported. The existing recorded sample uses empty source IDs. [NASA integration evidence](nasa-sources.md), [HPC runtime verification](hpc-integration.md).

Optional controlled retry comparison remains P1. The agreement requires completed eligible attempts with matching scenario, goals, and duration, plus preserved design/action metadata for changed-choice explanations. Current output is `comparison: null`. [Lifecycle and comparison contract](../contracts.md#9-controller-migration-lifecycle-and-comparison).
