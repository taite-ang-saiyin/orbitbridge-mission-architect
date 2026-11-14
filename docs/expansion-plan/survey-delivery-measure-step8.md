# Step 8: Survey delivery measurement preparation

Implemented prompt 10.2's independent KE2 preparation on 15 November 2026 at `features/KE2`, HEAD `8b76b5d` plus local changes. The user explicitly reports no HPC reply yet. The helper and its tests are ready; task 10.2 remains open for HPC's absent-entry semantics and real report integration.

## Change and boundary

Added private `MissionEvaluator._measure_survey_deliveries(config, final_state)` and tests in the existing evaluator suite. It requires the matching launch snapshot, reads selected targets in configured order, and reads `observations_delivered_by_target`. Each selected target with at least one explicitly recorded complete delivery contributes once; raw per-target counts are retained. Other targets, extra deliveries to a qualifying target, pooled returned MB, and capture counts cannot fill a missing target requirement.

For example, selected targets `[arctic_ice, antarctic_region]` with explicit counters `{arctic_ice: 3, antarctic_region: 0, equator: 99}` produce one delivered selected target out of two, with per-target actuals 3 and 0. Explicit zero is supplied fixture evidence. No score or mission outcome is calculated by this helper.

Missing or malformed maps, omitted selected-target entries, negative/fractional/boolean/string/nonfinite counters, malformed selections and a config differing from the launch snapshot return structured internal errors. An omitted target returns an error at `final_state.observations_delivered_by_target.<target>`, while an unavailable map returns an error at the whole-map path. Neither is converted to zero. The current preparation supports the reviewed minimum of one; a higher minimum returns an error instead of being silently ignored.

This is an internal measurement helper, not a second MissionConfig validator or terminal-report evaluator. It is not called from `evaluate_mission()`, report publication or the UI. Existing Survey scoring remains unavailable. Imaging outcomes, the public evaluation envelope, report keys, schema acceptance, aborted-run behavior and shared contracts are unchanged. Helper row names are internal preparation data, not an approved goal-progress contract.

## Verification

Godot version verified: `4.7.2.stable.mono.official.ed1daf0bf`.

| Suite | Expected and actual result | Evidence scope |
| --- | --- | --- |
| Evaluator | 254 passed, 0 failed, 5 existing pending declarations | Original 207 checks plus 27 explicit Survey fixture checks and 20 new native producer checks |
| Imaging preset regression | 53 passed, 0 failed | Actual preset buttons, native modules, publication and headless Debrief |
| Adapted Results integration | 17 passed, 0 failed | Existing runtime/publication/retry module integration |

All final test commands exited 0. `git diff --check` passed. The certificate-store diagnostic persists. No full-suite, exported-build or browser run was performed.

The new native test launches a supported v1 Survey setup for Arctic Ice, captures at pre-action step 0 and transmits at steps 7 and 10. After step 7, data have reached Earth and some remain onboard, but the delivery map has no complete observation. The helper leaves that sparse entry unavailable pending HPC's rule. After step 10, the packet is fully delivered: 12 MB returned, no stored remainder and one explicit complete-delivery counter. The helper then counts one target. This test measures intermediate native state, without publishing a terminal verdict.

Fixture cases cover multiple selected targets, extra/unrelated deliveries, raw-count retention, empty/unavailable maps, invalid values, missing entries, legacy primary-target fallback, launch-snapshot binding, deterministic results and input preservation. The config-v2 goal fixture is only an input to the isolated helper; production acceptance is unchanged. The [verification record](evidence/survey-delivery-step8-checks.json) records source/log hashes and counts. Older evidence packets retain their historical pre-change evaluator hashes.

Exact commands, from the project root:

```powershell
$godot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $godot --version
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/test_mission_evaluator.log' --script res://tests/test_mission_evaluator.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_imaging_presets_check.log' --script res://tests/ke2_imaging_presets_check.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_results_integration.log' --script res://tests/ke2_results_integration.gd
git diff --check
```

## Next prompt and inputs

Step 9 / 10.3 is the Survey verdict/score task. The existing concrete proposal equally weights capped captures, returned MB and complete-delivery target coverage, then rounds once with halves upward. Meeting captures and MB with one of two selected targets delivered gives proposed `partial / 83`. This remains a requirement decision; no production scoring change was made here.

- HPC: confirm whether an omitted selected target inside the native map means zero complete deliveries, and distinguish an absent whole map. Confirm packet-completion semantics and retained evidence at the boundary. This unblocks finishing 10.2's real-input policy.
- KE2 with affected owners: confirm Survey weights/progress rules before production 10.3 implementation. Existing worked examples remain available for review.
- KE3/SE: provide report/goal-progress feedback and the agreed migration shape before public report changes. SE/HPC/KE1 still own coordinated config-v2 propagation.

No additional input is required for the completed fixture/helper work. Keep parent 10.2 open and continue independent preparation while these specific decisions are pending.
