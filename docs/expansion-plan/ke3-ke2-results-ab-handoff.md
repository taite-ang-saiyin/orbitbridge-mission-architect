# KE2 reports and A/B handoff to KE3

Prepared 15 November 2026, Asia/Rangoon, against `features/KE2` at `4c65496`. KE1/HPC expansion code, scoring confirmation, and trace handoffs remain pending, as confirmed by the user in this session.

## Current implementation and requested deliverables

KE3's `comparison: null` observation matches the current code. `MissionEvaluator.evaluate_mission(config, final_state, events, comparison_baseline = null)` accepts the baseline argument, ignores it, and writes `comparison: null`. `evaluate_hpc_state(final_state, comparison_baseline = null)` forwards that argument. The active `mission_results.evaluate_trace(trace)` calls the evaluator with three arguments. `publish(...)` evaluates the bound trace through that path. SE's `baseline_for(...)` provides a preliminary config match and returns a copied record. Comparison computation and baseline forwarding remain implementation work.

Survey initializes through the real validator and engine, then produces `INVALID_EVALUATION_INPUT` at `config.mission.objective`. Communication and Weather candidate configs produce `MISSION_NOT_READY`, with `INVALID_SCHEMA` for `mission.preset_id` and their new count field. Their UI labels also lack mappings in `Runtime.config_for()`. The full actual responses are in the evidence packet.

The [reproducible evidence packet](evidence/ke2-handoff-current.json) contains eight completed headless engine executions, original configs, readiness results, terminal states, ordered events, resource samples, execution keys, actual evaluator replies, and separately labeled proposed report examples. The six expansion examples include success and isolated-shortfall measurements. Communication and Weather measurements use supported `imaging` configs to exercise existing engine semantics. Their production reports consequently describe Imaging. Expanded-objective production reports and a callable A/B implementation remain outstanding.

The probe uses custom configs chosen by KE2 to isolate the proposed goal checks. They use real stock parts and unmodified production catalogs. The three-orbit, two-capture, 12-MB setups differ from the current Polar Ice card's five-capture, 60-MB, six-orbit defaults. Existing preset acceptance remains open.

## Execution identity and evidence

All executions use `mission_id = ke2_handoff_20261115`. Each table entry is a complete `run_id`. Evidence event IDs are scoped to that execution. `cases.<case_id>.execution_key` contains the full binding key produced by `mission_results.input_key(trace)`, covering config, terminal state, events, and validation. The packet also records SHA-256 hashes of the inspected production modules and data.

| Case and exact run ID | Recorded engine result | Supporting evidence | Proposed expansion assessment |
| --- | --- | --- | --- |
| `ke2_probe_20261115_survey_shortfall` | 2/2 captures, 15.466666665600002/12 MB, 1/2 selected targets fully delivered | `evt_000` captures Arctic Ice, `evt_007` captures Antarctic Region, `evt_010` and `evt_017` transmit. Arctic receives 12 MB, Antarctic receives 3.466666665600002 MB | `partial`, 83 |
| `ke2_probe_20261115_survey_complete` | 2/2 captures, 24/12 MB, 2/2 selected targets fully delivered | Same captures, plus transmissions `evt_010`, `evt_017`, `evt_020`, `evt_027`. Each target has one fully delivered packet | `success`, 100 |
| `ke2_probe_20261115_communication_candidate_shortfall` | 1/2 positive transmit steps, 18.466666668/12 MB | `evt_008` returns 18.466666668 MB. Step 18 uses `power_save` | `partial`, 75 |
| `ke2_probe_20261115_communication_candidate_complete` | 2/2 positive transmit steps, 24/12 MB | `evt_008` returns 18.466666668 MB and `evt_018` returns 5.5333333320000015 MB | `success`, 100 |
| `ke2_probe_20261115_weather_candidate_shortfall` | 1/2 selected-target revolution visits, 22.1600000016/12 MB | Equator captures `evt_002` and `evt_005` are both in revolution 0. Positive downlinks occur at 8, 18, 28 | `partial`, 75 |
| `ke2_probe_20261115_weather_candidate_complete` | 2/2 selected-target revolution visits, 22.1600000016/12 MB | Equator captures `evt_002` and `evt_012` map to revolutions 0 and 1. Positive downlinks occur at 8, 18, 28 | `success`, 100 |

The proposed assessments apply equal capped ratios with one final half-up rounding. Survey uses capture, returned-MB, and delivered-selected-target ratios. Communication and Weather each use their qualifying-count ratio and returned-MB ratio. These rules retain proposal status. Actual evaluator responses reside in each case's `evaluation`. Proposed examples reside in `proposed_report` and include `goal_progress`, raw actuals, the existing report fields, and one next experiment.

Survey delivery qualification uses the actual `observations_delivered_by_target` map. In the shortfall execution, Antarctic has an incomplete packet and no delivered-count entry. The audit treats that absent entry as zero. HPC still needs to confirm this public interface meaning. Weather uses the source-derived candidate mapping `floor(accepted_event.step_index / steps_per_orbit)`, with the actual catalogs supplying ten steps per revolution. `orbit_id` remains `low_eq` or `high_inc` throughout each run.

The actual current evaluator leaves Survey with an error in both cases. It reports success/100 for all four Communication/Weather candidates under their supported Imaging configs. That result exposes the missing objective-specific checks. Every proposed example has `root_causes: []` and `source_ids: []`. The packet supplies recorded measurements and neutral goal summaries. Owner-agreed feedback rules still need implementation.

The paired shortfall/completion scripts demonstrate feasible corrective experiments through actual engine actions. Survey adds contact steps 20 and 27. Communication adds contact step 18. Weather moves the second capture from step 5 to step 12. These pairs change operations and serve as goal evidence. The separate Imaging pair below changes only a radio under one fixed policy.

## Actual A/B call and measured design pair

The current callable boundary is the following.

```gdscript
var reply = MissionEvaluator.evaluate_hpc_state(b_state, a_record)
# Actual reply.report.comparison is null.
```

The evidence probe supplies the existing SE record shape for `a_record`.

```gdscript
{
    "report": a_report,
    "state": a_state,
    "validation": a_readiness_result,
    "execution_key": a_execution_key,
}
```

The separately stored `ab_payload_proposal` names the proposed future signature `MissionComparison.compare_runs(a_record, b_record) -> Dictionary`. The comparison module is pending. Its payload fields are reviewable proposed output, with deltas calculated by the evidence probe from real executions.

| Identity | A | B |
| --- | --- | --- |
| Run ID | `ke2_probe_20261115_imaging_a` | `ke2_probe_20261115_imaging_b` |
| Execution key | `3f9d1187c4c61348792e2de818726d5773d4b1ddf3960ce1da1fbb5f377423b4` | `c219ed23feecf5be59bc629f7ac9e0406e809023cf3fc51e618c5dfadbed613b` |
| Terminal status | completed | completed |
| Actual evaluator outcome | partial | success |
| Actual evaluator score | 81 | 100 |
| Changed part | `radio_basic` | `radio_fast` |

Both use Imaging, Equator, `low_eq`, one orbit, one required capture, 12 required returned MB, a 100-credit budget, and the same effective catalog and authored schedule. The battery starts at 25 Wh, storage starts empty, and counters start at zero. Both pass actual KE1 readiness. These are custom diagnostic configs with optional preset identity absent.

Both execute `observe_first_v1`, defined in the probe as choosing the first allowed action in `observe`, `transmit`, `power_save` order at every step. Both request Observe at step 2 and Transmit at step 8. The packet retains every requested action. This policy derives requests from authoritative action availability. Future eligibility should allow hardware-dependent accepted-action differences under the same versioned policy.

| Measure | A | B | Signed B minus A | Delta unit |
| --- | --- | --- | --- | --- |
| Captures, goal 1 | 1 | 1 | 0 | count |
| Returned data, goal 12 MB | 7.3866666672 | 12 | +4.6133333328 | MB |
| Lowest battery | 23.307222222100005 | 22.845555555400004 | -0.4616666667000011 | Wh |
| Lowest battery percent | 93.22888888840002 | 91.38222222160002 | -1.8466666668000045 | percentage points |
| Highest onboard storage | 12 | 12 | 0 | MB |
| Total modeled cost | 82 | 89 | +7 | illustrative credits |
| Total spacecraft mass | 1060 | 1120 | +60 | g |
| Evaluator score | 81 | 100 | +19 | points |

Energy and storage extrema include the initial sample and every accepted post-step sample, including terminal. Percent uses each run's actual battery capacity. Sampling agreement with HPC remains open. Raw floating-point values are preserved in the packet.

For this schedule and fixed policy, the fast-radio run delivers the complete 12-MB packet, with greater modeled mass/cost and a lower battery minimum. This supports the measured scenario-specific trade-off. The production report's `comparison` remains null. Production comparison eligibility is unavailable. The proposal records `eligible: null`, candidate label `Design`, and an actionable `CONTRACT_PENDING` reason.

## Proposed record and eligibility contract for SE, HPC, and KE3

Retain a deep-copied saved record independently of the latest-two-trace buffer. The minimum proposed record consists of the following fields.

- The bound evaluator report, `run_id`, `mission_id`, and `execution_key`.
- The immutable launch config, stable preset identity or agreed legacy identity rule, catalog identity/hash, simulation version, scenario version, and schedule identity/hash.
- The original readiness result for authoritative mass/cost and the initial-state record for starting conditions.
- A versioned requested policy or the complete requested manual plan, plus accepted/blocked action evidence when needed to explain differences.
- Resource extrema with units and sampling definition, or retained initial/post-step samples sufficient to reproduce them.
- Objective-specific goal progress, selected-target deliveries, and the relevant event records with execution identity.

The proposed eligibility rules require two completed, input-bound executions. Match preset, objective, selected targets, every goal, orbit, duration, scenario/schedule, catalog/simulation versions, and starting-condition policy. Starting values may differ where an intended component change derives them, such as battery capacity. Treat those differences explicitly in changed parts and interpretation. Compare requested operation policy/plan. Matching policy supports `Design`. Different manual decisions support `Design + operations` when the other conditions match. Reject aborts and incompatible pairs with actionable reason codes. Represent unavailable measures as null with a reason, including null deltas, and preserve the historical reports.

Proposed comparison output includes `a`, `b`, eligibility/reasons, operations scope, changed parts, both outcomes, per-goal measures, signed deltas with explicit units, and interpretation. The concrete measured example resides at `ab_payload_proposal` in the JSON packet. The current draft's `implemented_comparison_api: null` records the missing callable implementation.

## Remaining handoffs and implementation

| Owner | Required next result |
| --- | --- |
| KE2 | Implement objective-aware evaluation, agreed expansion scores/errors/aborts, evidence-supported feedback, comparison eligibility, and signed measures. Rerun outcome, rounding, invalid-input, determinism, immutability, and comparison checks |
| KE1 + KE2 + SE | Confirm the configuration/report extension, preset identities, goal names and scoring rules. Update the shared agreement, contracts, examples, validator and consumers together |
| HPC + KE2 | Confirm accepted-event semantics, absent delivery entries, step-to-revolution mapping, and extrema sampling. Supply or confirm real expanded-objective success/shortfall traces and feasibility |
| SE | Preserve new config fields through launch snapshots, wire baseline/comparison calls, store A independently, and verify reached-completion eligibility and retry/cancel/reset/history behavior |
| KE3 + KE2 | Verify objective labels, goal thresholds, evidence, comparison scope and unavailable states against the bound real reports |

The production evaluator work remains assigned to KE2. The missing expanded producer code does allow continuing with these labeled engine-backed examples and agreeing the payload. It leaves real expanded-objective integration, active Save A/Run B/Compare lifecycle, and exported/browser acceptance open.

## Reproduction and checks

Run from `D:\orbitbridge-mission-architect` using the confirmed executable.

```powershell
$orbitGodot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $orbitGodot --version
& $orbitGodot --headless --path . --script res://docs/expansion-plan/evidence/ke2-handoff-probe.gd --log-file 'D:\orbitbridge-mission-architect\docs\expansion-plan\evidence\ke2-handoff-probe.log'
& $orbitGodot --headless --path . --script res://tests/test_mission_evaluator.gd --log-file 'D:\orbitbridge-mission-architect\docs\expansion-plan\evidence\test_mission_evaluator.log'
& $orbitGodot --headless --path . --script res://tests/ke2_results_integration.gd --log-file 'D:\orbitbridge-mission-architect\docs\expansion-plan\evidence\ke2_results_integration.log'
git diff --check
```

Godot reports `4.7.2.stable.mono.official.ed1daf0bf`. The probe exits 0 with zero failures. Independent inline `python -` checks verified all eight terminal executions, config/event bindings, event uniqueness and identity, sample extrema, returned-MB accounting, proposed goal scores, source hashes, the single changed design field, matching requested operations, and every signed delta. Regenerating the packet produced an identical SHA-256 hash. The evaluator checks report 207 passed, zero failed, five pending. Adapted Results integration reports 17 passed, zero failed. Each Godot run logs the existing Windows root-certificate-store diagnostic while its checks pass. Initial probing used a relative log path that Godot resolved under `user://` and could not create. The recorded successful command uses the absolute workspace path above.

Verification covers direct integrated Godot modules and existing fixture/integration checks. Active expanded-objective UI and saved comparison routes require the pending implementations. Exported/browser acceptance remains unverified. The local `.gitignore` edit is preserved. The packet, probe, and document are local handoff artifacts. Delivery to teammates remains for the user.
