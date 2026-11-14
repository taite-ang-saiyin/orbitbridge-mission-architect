# Mission evaluation and feedback

Owner KE2. Updated 14 November 2026 against the current implementation and `v1.0-agreed`.

## Public methods

Both modules extend `RefCounted` and expose static functions. Callers can preload them for scene-independent use.

```gdscript
MissionEvaluator.evaluate_mission(
    config: Dictionary,
    final_state: Dictionary,
    events: Array,
    comparison_baseline = null
) -> Dictionary

MissionFeedback.build_feedback(
    report: Dictionary, final_state: Dictionary, events: Array
) -> Dictionary

MissionFeedback.explain_event(event: Dictionary) -> Dictionary

MissionEvaluator.evaluate_hpc_state(
    final_state: Dictionary, comparison_baseline = null
) -> Dictionary
```

`evaluate_mission` validates its consumed inputs, calculates the report, and calls `build_feedback`. The feedback function returns `explanation`, `root_causes`, and `next_experiment`. `explain_event` returns one recognized event's code, segment, evidence references, explanation, and corrective experiment. An unsupported event produces an empty dictionary. [Evaluator implementation](../../scripts/evaluation/mission_evaluator.gd), [feedback implementation](../../scripts/evaluation/mission_feedback.gd).

`mock_report_result(report)` checks required report keys and returns a deep copy in the success wrapper. It supports explicitly labeled documentation fixtures. Mission scoring uses `evaluate_mission`.

## Consumed inputs

| Location | Requirement |
| --- | --- |
| `config.schema_version` | Numeric value `1` |
| `config.mission` and `config.design` | Dictionaries from the launch snapshot |
| `config.mission.required_observations` | Whole numeric value from 1 through 20 |
| `config.mission.required_returned_data_mb` | Finite numeric value greater than zero, in decimal MB |
| `config.mission.duration_orbits` | Whole numeric value from 1 through 12 |
| `final_state.schema_version` | Numeric value `1` |
| `final_state.run_id` and `mission_id` | Nonempty strings |
| `final_state.phase` | `finished` for evaluation |
| `final_state.run_status` | `completed` or `aborted` |
| `final_state.observations_completed` | Finite nonnegative whole numeric value |
| `final_state.returned_data_mb` | Finite nonnegative MB received on Earth |
| `final_state.stored_data_mb` | Finite nonnegative onboard MB used in the explanation |
| `final_state.total_steps` | Finite positive whole numeric value |
| `final_state.step_index` | Whole numeric value from zero through `total_steps` |
| `events` | Ordered array of dictionaries, with `[]` accepted |
| `comparison_baseline` | Reserved optional argument, currently unused |

Natural completion requires `step_index == total_steps`. An aborted state may terminate earlier. Feedback first reads a nonempty native HPC `terminal_reason` string, then falls back to optional `abort_reason` as a string or dictionary containing a string `message`.

`evaluate_hpc_state` reads the native state's `config_snapshot` and complete `event_log` and delegates to `evaluate_mission`. Missing or incorrectly typed snapshot/log fields produce a structured input error. The adapter preserves raw counters and units. [HPC runtime mapping and verification](hpc-integration.md).

Whole-valued JSON numbers such as `3.0` are accepted for count fields. Strings, booleans, fractional counts, invalid ranges, negative actuals, and nonfinite numbers produce input errors. The GDScript signature requires dictionaries and an array at the call boundary. The evaluator checks the fields it consumes, while KE1 and HPC retain their schema, catalog, and simulation responsibilities.

The SE scenario extension adds Survey per-target delivery goals. An explicit `objective: survey` currently returns `INVALID_EVALUATION_INPUT` at `config.mission.objective` through either evaluator entry point. Survey delivery weighting, verdict rules, and report fields await coordinated examples and agreement. Imaging evaluation retains its aggregate rules.

## Scoring

```text
observation_completion_ratio = min(completed_observations / required_observations, 1)
data_return_completion_ratio = min(returned_mb / required_returned_mb, 1)
score = floor(50 * (observation_completion_ratio + data_return_completion_ratio) + 0.5)
```

Both targets must be positive. Ratios range from 0 through 1 and the integer score ranges from 0 through 100. The evaluator rounds once, with halves rounded up. Raw actual values remain available above the targets. Returned MB supplies the data ratio. Stored MB appears in the explanation.

| Terminal condition | Report status | Score |
| --- | --- | --- |
| Completed and both thresholds reached | `success` | 100 |
| Completed with positive progress and an unmet goal | `partial` | Formula above |
| Completed with zero captures and zero returned MB | `failed` | 0 |
| Aborted, at any progress level | `failed` | `null` |

A partial run with very small positive progress can round to score 0. Status follows the raw counters. Aborted reports retain their actuals and ratios and identify the abort in `explanation`. An operating state returns `NONTERMINAL_RUN_STATE`. Malformed terminal inputs return `INVALID_EVALUATION_INPUT`. [Report and error contract](../contracts.md#8-missionevaluator-missionreport-and-evaluationerror).

## Evidence-based feedback

| Recorded code | Supported blocked action | Segment | Suggested experiment |
| --- | --- | --- | --- |
| `NO_LINK_WINDOW` | `transmit` | `ground` | Transmit during an available ground-contact window |
| `LOW_BATTERY` | `observe`, `transmit` | `space` | Try Power Save before the operation with other settings fixed |
| `STORAGE_FULL` | `observe` | `space` | Transmit stored data during contact before another observation |
| `TARGET_NOT_VISIBLE` | `observe` | `space` | Observe during a target-access window |

The four codes and action semantics were checked against cached HPC source at `ab7865c`. The recorded HPC handoff also demonstrates `NO_LINK_WINDOW`. Segment labels follow the user's requested launch/space/ground/user vocabulary. Current rules emit space and ground labels. [Recorded HPC evidence](../handoffs/ke2-hpc-report-v0.1.md).

Evidence requires a nonempty event ID, `action_blocked` type, recognized code/action pairing, and a nonnegative whole step. When delta fields are present, each must be finite and zero. At report level, the event must match any supplied run/mission identity and fall within the terminal timeline. Observation blocks contribute to an observation shortfall and transmission blocks contribute to a returned-data shortfall.

Causes sort by observation-goal priority, earliest step, then input order. Identical duplicate IDs collapse. Conflicting duplicate IDs are excluded. Unsupported, irrelevant, malformed, or missing evidence produces a neutral summary and empty `root_causes`.

Each cause contains `code`, `segment`, `evidence_event_ids`, and `explanation`. Its explanation includes the corrective action. The primary correction also appears as report-level `next_experiment`. Successful runs acknowledge both met goals. Aborts use optional recorded abort text when available and otherwise provide neutral termination wording.

## Current extension points

The implementation preserves its inputs and returns fresh outputs. Every current report has `source_ids: []` and `comparison: null`. NASA credit lookup and optional retry comparison remain integration work. [Integration handoff](integration-handoff.md), [NASA sources](nasa-sources.md).
