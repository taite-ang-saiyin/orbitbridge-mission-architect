# KE3, SE, and HPC report and saved-run handoff

Prepared by KE2 on 15 November 2026 in Asia/Rangoon for task 00.4, from `features/KE2` at `4c65496`. All extensions in this draft are proposals for owner review. Existing behavior follows the [signed agreement](../team-agreement.md) and [technical contract](../contracts.md).

This consumer-focused draft reuses the existing [reports/A/B response](ke3-ke2-results-ab-handoff.md) and local headless evidence packet. Its [four complete report examples](evidence/report-examples-proposal.json) retain actual production replies separately from proposed goal-progress output. Verification in this task is source inspection and example validation using existing records.

The newer local [K20 interface review](k20-ke2-interface-review.md) records user-confirmed mission IDs and goal meanings. It recommends config v2, nested goals, root preset identity/revision, and a two-capture Communication starter, with those interface details still under coordinated review. The [SE response](ke1-se-config-handoff.md#se-review-and-work-that-can-proceed) records that separate Save A/B storage and navigation work can proceed. This handoff supports that independent record work while report and config adoption are settled.

## Current evaluator envelope and field dependencies

`MissionEvaluator.evaluate_mission(config, final_state, events, comparison_baseline = null)` returns `{ "ok": true, "report": MissionReport }` or `{ "ok": false, "error": EvaluationError }`. A valid aborted terminal run uses the report envelope with preserved actuals, failed status, and null score. Errors contain `code`, nullable `field_path`, `message`, `suggested_fix`, and nullable `run_id`.

The current report has 17 required fields. Preserve their meanings during an additive migration.

| Fields | Current consumers |
| --- | --- |
| `schema_version` | Evaluator and fixture/mock checks require numeric 1 |
| `run_id`, `mission_id`, `run_status` | Publication and presentation bind report to execution and distinguish abort |
| `status`, `score` | Headline, badge, score label, and gauge use the supplied evaluator values |
| `observations_completed`, `required_observations`, `observation_completion_ratio` | Existing photo values and progress bar |
| `returned_data_mb`, `required_returned_data_mb`, `data_return_completion_ratio` | Existing returned-data values and progress bar |
| `explanation`, `next_experiment` | Overview/Flight log and next-flight suggestion |
| `root_causes` | Cause code, segment, explanation, and `evidence_event_ids` resolved against the same run |
| `source_ids` | Report attribution, alongside separate scoped readiness/feedback metadata |
| `comparison` | Currently null, with the baseline parameter reserved and ignored |

The active route is [DebriefCompare.tscn](../../scenes/screens/DebriefCompare.tscn) -> [Screen.gd](../../scripts/prototype/Screen.gd) -> [DebriefPresentation](../../scripts/presentation/DebriefPresentation.gd), [PlayerLanguage](../../scripts/presentation/PlayerLanguage.gd), and [DebriefSummary](../../scripts/presentation/DebriefSummary.gd).

`DebriefPresentation.build()` correlates identities, execution binding, existing requirements, actual captures/MB, and terminal status. It produces report, evaluation-error, pending, or stale-report state. Event references preserve run identity and reject ambiguous duplicates. Extend those checks to the new objective/count goals when their contract is agreed.

`Screen.show_actual_run()` currently renders exactly two goal rows. `DebriefSummary` reasons from photo/data progress, which cannot explain a missing Survey delivery when both aggregate goals are met. KE3 should render the new supplied goal list for expanded objectives and retain the older path for records without it. Overview, Flight log, Sources, authoritative outcome/score, and execution binding remain part of the integration check.

The evaluator suite checks the exact report key set as well as required fields. Coordinate new optional output and expected tests with current consumers before publishing it.

Keep config, state/event, catalog, report, and saved-record versions explicit and independent. The current evaluator uses one `SCHEMA_VERSION` check for both config and state. A proposed config-v2 path needs separate version acceptance while preserving current report/state behavior. Config v2 adoption alone leaves report schema evolution as an owner decision.

## Proposed goal-progress entries

Propose report `objective`, optional source-backed `preset_id`, and `goal_progress`. Retain the existing report fields and successful-capture meaning, including for new objectives that score a different count.

| Entry field | Proposed meaning |
| --- | --- |
| `id` | Stable goal ID |
| `actual`, `required`, `unit` | Raw measurement, positive requirement, and explicit unit |
| `met` | Evaluator-supplied goal verdict |
| `completion_ratio` | Evaluator-supplied capped ratio from 0 to 1 |
| `evidence_event_ids` | Relevant recorded context within this report's run |
| `by_target` | Survey selected-target delivery details, with raw complete-observation count, requirement 1, met state, ratio, and returned MB |

Use the existing draft IDs `captures`, `returned_data`, `selected_targets_delivered`, `positive_transmit_steps`, and `selected_target_revolution_visits`. Survey scores three aggregate terms under the proposed weights. Nested target rows explain the delivery term. Communication/Weather score their qualifying count and returned MB under their proposed two-term weights.

Use supplied verdicts and ratios for new goal rows. Keep score and mission outcome authoritative. Optional unavailable diagnostics use null and a reason. Missing required scoring evidence follows the agreed evaluation-error behavior. A missing whole delivery map cannot establish zero deliveries. The absent-key interpretation inside a genuine sparse native map awaits HPC confirmation.

## One report example per goal type

The [JSON examples](evidence/report-examples-proposal.json) contain four full `ok/report` examples, source identities, goal entries, and separate actual `production_reply` envelopes. They derive from [ke2-handoff-current.json](evidence/ke2-handoff-current.json), SHA-256 `a42a1ca3aaa4cbafca548576c14f68578961cef9084fec4275557583a7ceeb7e`. Its eight recorded module/data hashes match this checkout.

| Objective and source case | Recorded actuals and goals | Example status/score | Production evidence |
| --- | --- | --- | --- |
| Imaging, `imaging_a` | 1/1 captures, `7.3866666672`/12 MB | Actual partial / 81, with proposed additive fields | Actual Imaging evaluator report |
| Survey, `survey_shortfall` | 2/2 captures, `15.466666665600002`/12 MB, 1/2 selected targets completely delivered | Proposed partial / 83 | Actual Survey engine run, evaluator returns `INVALID_EVALUATION_INPUT` at `config.mission.objective` |
| Communication, `communication_candidate_shortfall` | 1/2 positive Transmit steps, `18.466666668`/12 MB | Proposed partial / 75 | Supported Imaging mechanics/proxy run, actual Imaging evaluator returns success / 100 |
| Weather, `weather_candidate_shortfall` | 1/2 selected-target revolution visits, `22.1600000016`/12 MB | Proposed partial / 75 | Supported Imaging mechanics/proxy run, actual Imaging evaluator returns success / 100 |

These are custom diagnostics with no preset IDs. Imaging uses one orbit, while the other cases use three. They demonstrate report fields and goal differences. Acceptance of the actual preset cards remains separate work.

Survey preserves Arctic Ice delivery count 1 and Antarctic Region count 0, with Antarctic data partly returned. Weather capture steps 2 and 5 are both revolution 0 under the candidate ten-step mapping. The samples keep raw over-target MB, legacy captures, null comparison, and empty causes where a specific cause was not established. Goal references provide their recorded measurement context.

All additive fields and new-objective assessments are labeled proposals. Keep the actual source-config reply separate. Expanded-objective reports need matching approved inputs and execution binding before using them as production records. The example metadata retains execution keys and provenance outside the report. Readiness credits remain bound to executed validation and scoped source metadata.

## Report history and trace retention

| Current storage | Observed behavior |
| --- | --- |
| `run_history` | Runtime retains at most two full traces, including frames and snapshots |
| `evaluation_store.reports`, `errors`, `bindings` | Indexed by run ID, report copies and bindings preserve identity. Evaluation errors leave earlier successful history intact |
| `evaluation_store.history` | Each successful record has report, terminal `state`, validation, execution key, and optional result/source context. Terminal state contains config/scenario snapshots and full events. Full resource frames and versioned requested policy are absent |
| `evaluation_store.baseline` | Automatically captures the first successfully evaluated completed record. `baseline_for()` checks orbit, objective, targets, legacy goals, and duration |
| `Screen.result_history()` | Reconstructs older display traces from evaluated records and appends distinct recent traces |

`mission_results.input_key()` hashes config, terminal state, events, and readiness. `evaluate_trace()` calls the evaluator with three arguments, so comparison needs explicit input/call wiring. Current `comparison` remains null even when invoking the evaluator's baseline parameter.

Immediate Retry uses the active trace's frozen setup. Modify design copies the session and stores a restoration snapshot. Cancel restores it, while New Mission clears session history/baseline. Selecting historical Results changes the display and does not select a dedicated saved A for the controller. SE should make the source of B explicit.

## Immutable data SE needs for saved A

Retain the existing record properties `report`, `state`, `validation`, and `execution_key`, with agreed extensions below. Deep-copy them at explicit Save A from the actually reached completed execution and bound report. Prepared future terminal playback data cannot establish reached completion.

| Independent saved data | Purpose |
| --- | --- |
| Record format version, run/mission IDs, execution key, and actual report | Identify the attempt and preserve authoritative outcome |
| Complete terminal `state`, including launch config/scenario snapshots, ordered events, target maps, and packet queue | Retain requirements and objective evidence |
| Catalog snapshot or resolvable fingerprint, scenario/schedule identity, and simulation/adapter versions or hashes | Match and reproduce the environment |
| Original readiness result | Preserve calculated mass/cost and actual source-rule evidence |
| Initial state and initialization policy | Retain starting energy, storage, and counters, including component-derived differences |
| Complete ordered manual requests or policy ID/version/parameters with overrides | Classify operations changes and preserve repeated requests at the same step |
| Compact resource samples and/or agreed extrema with units and sampling ID | Preserve initial/post-step measures after trace eviction, including needed packet/target samples |
| Bound source-credit metadata and necessary display context | Reopen attribution with the correct execution |

Agree the exact extended property names with SE/HPC. Save these independently of the latest-two-trace buffer. B, Retry, Cancel, playback, and explicit replacement of active A preserve historical reports. New Mission clears the active pair. Current-session retention includes the refresh-clears-it notice.

## Comparison eligibility and action-plan classification

The existing `MissionComparison.compare_runs(a_record, b_record)` proposal remains subject to wrapper and reason-code agreement.

1. Require two completed, input-bound executions with actual reports for their recorded objectives. Give an actionable reason for aborted, incomplete, mismatched, or missing required evidence.
2. Match preset identity or the agreed legacy/custom identity rule, objective, ordered targets, all mission-affecting goals, orbit, duration, and budget/setup constraints. Normalize an omitted target array to its primary target. Preserve target order where native selection can depend on it.
3. Match authored preset revision where present, scenario/schedule, catalog and simulation versions/fingerprints, and starting-condition policy. Keep unknown version evidence unresolved. Intended component changes may derive different battery capacity or initial Wh, so record and interpret those changes.
4. Matching versioned requested policy or manual plan supports the `Design` label. Accepted actions can differ when the same policy meets different hardware limits. Different manual requests with otherwise matching conditions receive `Design + operations`. Retain manual overrides of a policy for classification.
5. Show changed design fields and signed B-minus-A differences for available numeric values. Use count, MB, Wh, grams, credits, or score points. Percent differences use percentage points. Optional missing measures and deltas remain null with a reason. Explain measured trade-offs within the evidence's causal limits.

The existing custom Imaging pair changes only `radio_basic` to `radio_fast` under `observe_first_v1`. It measures `+4.6133333328 MB`, `+60 g`, and `+7 credits`. Its proposed label is Design, with `eligible: null` and `CONTRACT_PENDING`, because production comparison and legacy preset identity rules remain open.

## Open owner decisions and acceptance

| Owner | Needed result |
| --- | --- |
| KE2 + KE3 + SE | Confirm additive fields/goal IDs, required existing fields, ratio/met semantics, unavailable data behavior, and report schema/revision strategy |
| KE2 + affected owners | Confirm score weights, partial/failed progress, and required-evidence errors |
| KE3 | Replace fixed photo/data assumptions for expanded objectives and verify Overview/Flight log/Sources against bound reports |
| SE + KE2 | Agree saved-record properties, explicit A selection/replacement, legacy/custom identity, baseline/comparator call wiring, and lifecycle beyond trace eviction |
| HPC + SE + KE2 | Confirm policy/request evidence, revolution mapping, sparse-map semantics, sample bounds, and version/fingerprint rules |
| KE1 + SE | Resolve the K20 version/goal/preset-location choices, preserve confirmed ID/goal meanings, and supply actual matching expansion inputs with root identity/revision where agreed |

The handoff is prepared for sharing. Owner agreement and delivery of this additional consumer draft remain pending. Integration acceptance still needs actual expanded-objective reports, dynamic goal rendering, one report per run, saved-A survival through B/Cancel/Retry/trace turnover, measured comparator results, and public browser journeys.

## Verification

This planning task inspected current sources and existing headless evidence. It checked eight source hashes, retained actual replies separately, and generated four labeled full-envelope examples. Python checks cover required fields, source/run/event identity, raw actuals, goal ratios/verdicts, proposed scores, Survey target details, and local links. No new engine/UI execution was used for these checks.

Reproducible JSON and diff commands are below. The full source/arithmetic check used an inline `python -` program during this task.

```powershell
python -m json.tool docs/expansion-plan/evidence/report-examples-proposal.json > $null
git diff --check
```

## Draft completion record

- [x] Inspect the evaluator envelope, actual consumer fields, report history, and trace retention.
- [x] Prepare four labeled full-envelope report examples with proposed goal-progress entries.
- [x] Draft eligibility/action classification and independent immutable saved-A requirements.
- [x] Check source hashes, example identity/arithmetic, and local document links.
- [ ] Obtain owner decisions, implement coordinated producer/consumer changes, and verify real UI/browser integration.

The shared task tracker already records 00.4 proposal examples and independent-record definition as completed subtasks. During this task, another local workflow updated that tracker and the K20/SE review. This task records its additional draft completion here while shared-file updates are active, following the checkout's take-turns instruction.
