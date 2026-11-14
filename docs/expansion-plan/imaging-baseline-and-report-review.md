# Imaging baseline and report review

Verified on 15 November 2026 using `features/KE2` at `8b76b5df4f0b327d8d4293be22ed984b610f8647`, Godot `4.7.2.stable.mono.official.ed1daf0bf`, and the signed `v1.0-agreed` contract. This completes task 10.1 and the proposal-review output of prompt 30.1. Shared expansion report agreement and implementation remain open.

## Actual preset regressions

The new [KE2 regression](../../tests/ke2_imaging_presets_check.gd) presses each actual Mission Control preset button, follows its Creator routing, launches its untouched setup through the existing controller/runtime, finishes Operations playback, and inspects its published report and active Debrief nodes. It preserves the selected targets and schedules. This is integrated headless Godot scene/module evidence, with no exported browser execution.

| Preset | Target / orbit | Goals / duration | Expected and actual result |
| --- | --- | --- | --- |
| Estuary Watch | `coastal_region` / `high_inc` | 5 captures, 60 MB, 6 orbits | 5 captures, 60 MB returned, 0 MB stored; success / 100 |
| Tropical Forest Watch | `tropical_forest` / `low_eq` | 5 captures, 60 MB, 6 orbits | 5 captures, 44.3200000032 MB returned, 15.6799999968 MB stored; partial / 87 |

Estuary uses target steps `[2, 5]` and contact steps `[0, 7]` within each ten-step revolution, at `0.1611111111` hours per step. Tropical Forest uses target step `[2]`, contact step `[8]`, and `0.1538888889` hours per step. Both use the card's default hardware and Observe First policy. Actual selected-target captures and accepted Transmit deltas reconcile with the reports. Raw decimal MB are preserved; displayed Tropical Forest MB are rounded to `44.32`.

The 53 checks cover native readiness, actual reached terminal status, independent goal ratios, literal outcomes/scores, packet conservation, deterministic input-preserving evaluation, publication binding/idempotence, and Debrief actuals, verdicts, score and outcome. The [saved evidence](evidence/imaging-presets-8b76b5d.json) includes configs, selected orbit metadata, native reports, transmission events, visible label values, and source hashes. Run IDs identify the particular measured executions; replay uses fresh run IDs.

## Report proposal review

Reused the [consumer handoff](ke3-se-hpc-report-handoff.md) and [four existing examples](evidence/report-examples-proposal.json). Verified their source packet hash, all eight recorded production module/data hashes against this checkout, the four actual production replies, same-run identities, retention of all 17 legacy report fields, and proposed per-goal requirements/verdicts/ratios. No duplicate report format was introduced.

The proposed additive fields remain `objective` and `goal_progress`, with stable goal IDs, raw actual/required/unit, evaluator-supplied `met` and capped `completion_ratio`, same-run evidence IDs, and Survey target detail. The existing handoff also proposes optional source-backed preset identity. Production outputs are unchanged. Existing report/state schema version 1 is independent of KE1's confirmed config-v2 choice.

The current Debrief still creates exactly two photo/data rows. `DebriefSummary` derives their labels from bound report values, and `PlayerLanguage` assumes those two goals. Those consumers require coordinated KE3 changes before a Survey delivery shortfall or Communication/Weather count can be explained correctly. SE must retain binding to the exact config, state, events and readiness when publishing or saving A. The existing tests' exact report-key assertion must change together with an agreed output extension.

KE1's four K20 choices are already confirmed per the recorded user report; requesting that confirmation again is unnecessary. The candidate registry/API/tests are still absent. SE/HPC alignment, custom-mission identity, supported Survey minimum, scoring weights, missing/sparse evidence policy, report evolution and actual expansion integration remain dependencies. The Survey 83 and Communication/Weather 75 examples remain proposed assessments; the existing proxy runs retain their actual Imaging replies separately.

## Commands and results

Run from `D:\orbitbridge-mission-architect`:

```powershell
$godot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $godot --version
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_imaging_presets_check.log' --script res://tests/ke2_imaging_presets_check.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/test_mission_evaluator.log' --script res://tests/test_mission_evaluator.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_results_integration.log' --script res://tests/ke2_results_integration.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/debrief_summary_check.log' --script res://tests/debrief_summary_check.gd
git diff --check
```

Expected and actual final results: Imaging presets 53 passed / 0 failed; evaluator 207 passed / 0 failed / 5 declared pending; adapted Results 17 passed / 0 failed; Debrief summary 57 passed / 0 failed. All four final test commands exited 0. The evaluator suite combines contract fixtures with actual native HPC checks; Results and Imaging exercise native modules, and Debrief summary exercises headless scenes. The Windows certificate-store diagnostic remains, without a failed check. Explicit local log paths avoid the earlier user-log write diagnostic.

The repository runner still lists 43 programs. This new focused test is a separate documented command; the SE-owned runner was left untouched. A full 43-program run, expanded-objective production acceptance, saved-A lifecycle and public browser journeys were not performed here. Logs and replay output are under ignored `exports/check-logs/`.

## Next handoffs

- KE1: supply the confirmed config-v2 registry/API/tests, exact revision, valid/invalid examples and remaining bounds.
- HPC: confirm sparse target-map and revolution semantics, resource sampling, and real Communication/Weather success and isolated-shortfall traces.
- KE2 with KE3/SE: settle the concrete report/scoring proposal before publishing new goal fields; KE3 owns dynamic goal rendering and SE owns publication/storage integration.
- SE: separate Save A/B storage/navigation can proceed under the recorded review. Supply its record shape and implementation/lifecycle evidence for comparator integration.

Known-contract KE2 analysis and labeled fixtures may continue. No production contract or owner implementation file changed in this task.
