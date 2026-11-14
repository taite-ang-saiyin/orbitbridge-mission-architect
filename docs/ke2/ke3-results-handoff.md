# KE2 to KE3 Results handoff

Owner KE2. Reviewed 14 November 2026 against `v1.0-agreed`. Root revision `dbf65ad` and integration candidate `14c0f97` contain identical KE2 evaluator/feedback modules.

The actual scene is `ke3/results_control.tscn`, using `ke3/debrief_screen.gd`. Its entry point is `set_inputs(context: Dictionary, state: Dictionary, report: Dictionary)`. SE's `scripts/prototype/Screen.gd::show_actual_run` obtains the payload through `scripts/integration/mission_results.gd::presentation(trace)` and passes the three dictionaries to this method.

## Example MissionReport

This is the unwrapped report for the original validated partial run. Its full wrapper, inputs and provenance are available in the existing handoff. [Original report](../handoffs/ke3_validated_1u_55d4f33_9dfd942_20261114_01/evaluation-v0.1.json).

```json
{
  "schema_version": 1,
  "run_id": "ke3_validated_1u_55d4f33_9dfd942_20261114_01",
  "mission_id": "ke3_validated_1u_feasible_20261114",
  "run_status": "completed",
  "status": "partial",
  "observations_completed": 1.0,
  "required_observations": 4.0,
  "returned_data_mb": 7.7333333328,
  "required_returned_data_mb": 30.0,
  "observation_completion_ratio": 0.25,
  "data_return_completion_ratio": 0.25777777776,
  "score": 25,
  "explanation": "1.0/4.0 observations captured and 7.7333333328/30.0 MB received on Earth. 4.2666666672 MB remain onboard. At step 8.0, a transmission was blocked because no ground-contact window was available.",
  "root_causes": [{
    "code": "NO_LINK_WINDOW",
    "segment": "ground",
    "evidence_event_ids": ["evt_008"],
    "explanation": "At step 8.0, a transmission was blocked because no ground-contact window was available. Retry and transmit during an available ground-contact window."
  }],
  "next_experiment": "Retry and transmit during an available ground-contact window.",
  "source_ids": [],
  "comparison": null
}
```

## Fields and display

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | Integer | Contract version, currently 1 |
| `run_id` | String | Nonempty attempt identity |
| `mission_id` | String | Nonempty mission identity |
| `run_status` | String | `completed` or `aborted` |
| `status` | String | Verdict, `success`, `partial` or `failed` |
| `observations_completed` | Nonnegative whole number | Actual successful captures, including excess captures |
| `required_observations` | Positive whole number | Observation target from the launched config |
| `returned_data_mb` | Nonnegative finite number | Actual decimal MB received on Earth |
| `required_returned_data_mb` | Positive finite number | Launched return target in decimal MB |
| `observation_completion_ratio` | Float, 0–1 | Observation completion fraction |
| `data_return_completion_ratio` | Float, 0–1 | Returned-data completion fraction |
| `score` | Integer, 0–100, or null | Evaluator score, null for aborted attempts |
| `explanation` | String | Summary with the onboard/returned distinction and supported evidence |
| `root_causes` | Array of Dictionaries | Recorded causes relevant to unmet goals |
| `next_experiment` | String | Recommended next action |
| `source_ids` | Array of Strings | Report source references, currently empty |
| `comparison` | Dictionary or null | Optional retry result, currently null |

Each cause contains `code: String`, `segment: String`, `evidence_event_ids: Array[String]` and `explanation: String`. Current segment values are `ground` and `space`. Resolve evidence IDs against this attempt's ordered events. The four recognized codes are `NO_LINK_WINDOW`, `LOW_BATTERY`, `STORAGE_FULL` and `TARGET_NOT_VISIBLE`.

KE3 formats whole-valued JSON floats as counts and multiplies the supplied ratios by 100 for percentages. The example displays 1/4 observations, 7.7333333328/30 MB, 25% and 25.78%, with score 25. Decimal MB uses `1000 KB = 1 MB`. A separate onboard field can use `state.stored_data_mb`.

All 17 report keys are required in a valid report. Only `score` and `comparison` allow null. `root_causes` and `source_ids` may be empty arrays. Unknown or missing cause evidence gives a neutral explanation and empty causes. A missing linked event displays “Evidence Unavailable” while preserving the report.

An aborted attempt has `run_status: aborted`, `status: failed` and `score: null`. Current KE3 displays the null score as “Unavailable” alongside the aborted status. Keep `comparison: null` when unavailable and leave the comparison area hidden. The current debrief renders the core mission fields. Optional comparison rendering requires KE3 coordination.

## Evaluation and UI binding

```gdscript
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")
var result: Dictionary = Evaluator.evaluate_mission(
    config, final_state, events, comparison_baseline
)
# comparison_baseline defaults to null when omitted.
# Native HPC callers can also use Evaluator.evaluate_hpc_state(final_state).
```

The wrapper is `{ "ok": true, "report": MissionReport }` or `{ "ok": false, "error": EvaluationError }`. For successful evaluation, supply `result.report` as the third UI argument. SE's existing adapter performs the binding preparation.

```gdscript
const Results = preload("res://scripts/integration/mission_results.gd")
var payload: Dictionary = Results.presentation(trace)
results_view.set_inputs(payload.context, payload.state, payload.report)
```

`trace` contains `config`, `final_state`, the complete ordered `events` array and the actual `validation` result. The adapter checks config/history against `final_state.config_snapshot` and `final_state.event_log`. It projects the history into presentation `state.events`, supplies matching `context.run_id`, `context.mission_id` and `context.config`, and derives scoped credits in `context.applicable_source_credits`. Preserve the report's own source IDs.

An evaluation error supplies `code`, nullable `field_path`, `message`, `suggested_fix` and nullable `run_id`. The adapter puts it in `context.evaluation_error` with an empty report. A matching known identity lets KE3 display the error and correction. Errors without a valid identity use SE's outer error presentation. Keep prior history and baseline when evaluation fails.

## Reset and retry

SE owns publication, cached evaluation and lifecycle state. Its candidate uses an input fingerprint in `evaluation_key` and `context.execution_key` to distinguish retained legacy packets sharing `run_001`. New runs receive fresh identities. Reopening reuses the retained attempt. Duplicate terminal notifications preserve one history entry.

Retry revalidates the launch snapshot, assigns a fresh run ID and event sequence, and retains a completed baseline. New Mission clears live trace, history, cached evaluation and baseline through the existing reset. Clear a retained view with `set_inputs({}, {}, {})`, or bind the newly selected attempt. Route delayed updates using the active attempt identity and execution key.

## Verification

Confirmed Godot `4.7.2.stable.mono.official.ed1daf0bf` before execution. The existing candidate Results/lifecycle suite passed **57 checks**, zero failed, exit 0. An additional local KE2 harness passed **50 checks** through SE's actual adapter and KE3's actual scene using the original partial run and actual HPC abort bundle. It checked report equality, values, percentages, cause/evidence, exact explanation/experiment, scoped credits, null score/comparison, missing-event fallback, input preservation and clearing stale display.

```powershell
& $ke2Godot --headless --path './tmp/se-ke2-integration' --script res://tests/ke2_results_integration.gd
& $ke2Godot --headless --path './tmp/se-ke2-integration' --script 'D:/orbitbridge-mission-architect/tmp/ke2-prompt8-report-binding.gd' -- 'D:/orbitbridge-mission-architect'
```

Use the confirmed executable from the testing guide as `$ke2Godot`. Logs are `tmp/ke2-prompt8-results-integration.log` and `tmp/ke2-prompt8-report-binding.log`. The extra harness is local verification under ignored `tmp`. Runtime checks emitted the known Windows certificate-store diagnostic. Headless candidate verification covers the adapter and scene. Manual navigation with the original partial/abort packets, the selected release, B02, official B10 and exports remain pending. [Testing guide](testing.md).
