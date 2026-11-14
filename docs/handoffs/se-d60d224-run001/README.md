# SE candidate run and KE2 Results integration

Packet revision `se-d60d224-run001-v0.1`, evaluated on 14 November 2026, Asia/Rangoon.

The submitted SE candidate at `d60d2242d72fda0e933cc99524c113e9ca0594d9` identifies this execution as `run_001` / `mission_local`. The retained config, terminal state, full event history and readiness result define this packet. Its execution key and byte hashes are in the metadata. All 15 original packet file hashes were checked against the supplied provenance.

- [Matching evaluator result](evaluation-v0.1.json)
- [Evidence links, scoped credits and source revisions](metadata-v0.1.json)
- [Exact Results context](context-v0.1.json)
- [Retained submitted inputs](../../../data/fixtures/se_d60d224_run_001/provenance.json)

## Evaluation

The report is **success**, score **100**, completed **60/60** steps, **4/4 observations**, **48/30 MB returned**, and **0 MB onboard**. Both capped completion ratios are 1.0. Raw returned data remains 48 MB.

`root_causes` and `source_ids` are empty. Supporting observation evidence is `evt_001`, `evt_006`, `evt_011`, and `evt_016`. Actual ground-return evidence is `evt_007`, `evt_010`, `evt_017`, `evt_020`, `evt_027`, `evt_030`, and `evt_037`. Completion is `evt_060`. The metadata links these records to JSON pointers in the full 61-event file.

The applicable scoped credit is **readiness**, source `cubesat_101_1u_sample`. KE1 recorded the selected sample profile's passing mass check at **1060 g < 1330 g** and overall `ready_to_launch=true`. The metadata includes exact attribution text and the NASA CubeSat 101 locator, Appendix C item 6, printed p. 79 / PDF p. 87. This report emits no mission-segment cause requiring a feedback-vocabulary credit.

## Source revision

Repository https://github.com/taite-ang-saiyin/orbitbridge-mission-architect

Branch `integration/ke2-se-results-d60d224`. Evaluator and integration implementation commit `b23de72dc251ee7cc1d4e3662aa0a8b3de0cfb6e` contains the source used to produce this report.

The evaluator entry point is `scripts/evaluation/mission_evaluator.gd`, with `scripts/evaluation/mission_feedback.gd`. The caller is `scripts/integration/mission_results.gd`.

```gdscript
MissionEvaluator.evaluate_mission(packet.config, packet.final_state, packet.events)
```

The report uses the packet's actual launched `config.json`, including its single-target array. Supplied input files are retained byte-for-byte with scoped Git attributes preserving their original line endings.

## Connected Results behavior

Launch validates the current design, executes the selected HPC policy and evaluates the terminal trace. Controller routing binds KE3's actual Results view through `set_inputs(context, state, report)`. Its history projection preserves every provider event in order. Successful runs display their outcome, score and raw actuals. Errors display the evaluator's message and suggested correction.

Report caching and publication use a full input fingerprint, so independent legacy packets named `run_001` receive their own evaluations. Newly launched runs use collision-resistant session identifiers and a sequence number. Duplicate publication and reopening Results retain history. Retry revalidates the selected launch snapshot, starts a new run and retains its completed baseline. New Mission clears the baseline and history.

Scoped credit records come from the actual trace's readiness result and emitted feedback. The successful submitted packet receives its readiness credit. Recent Runs uses an expanding run-ID column and fixed widths for captures, returned MB and score. These columns remain readable at 1280×720.

KE3 source was imported from the manifest-pinned recorded preview supplied in KE2's checkout. The production adapter replaces its preview banner and binds the active trace. Existing SE Operations retains policy playback. Its Play, Step, Pause, Replay and Skip controls inspect the computed policy run. The signed API supports manual Observe/Transmit/Power Save requests, and SE/KE3 still need to wire those controls for the corresponding B02 interaction test. Survey evaluation continues to return the current KE2 input correction until its scoring extension is agreed.

## Verification and retest

Godot version `4.7.2.stable.mono.official.ed1daf0bf` was confirmed with `--version`.

- Exact packet, active-run binding and Results lifecycle checks passed **57/57**.
- Standalone evaluator checks passed **167**, with **0 failures** and the existing **5 pending groups**.
- Player-flow smoke passed at 1440×900 and 1024×768.
- Operations smoke passed at 1440×900, 1280×720, 1024×768, 1920×1080 and 3360×2100.
- Prototype smoke passed at 1280×720 and 1024×768.
- Rendered Results, report and credit captures were inspected at 1280×720 using Compatibility/OpenGL 3.3 on Intel UHD Graphics.

Exact checks cover the packet hashes and outcome, same-ID/different-config isolation, complete evidence delivery, immutable input snapshots, duplicate publication, reopening, fresh-session IDs, Retry IDs/baseline, New Mission reset, malformed-input handling and Survey error routing. All final commands exited 0. Raw logs and the three captures are under [evidence](evidence/results-integration.log).

From this branch's project root, substitute the installed Godot executable for `godot`.

```sh
godot --version
godot --headless --path . --script res://tests/ke2_results_integration.gd
godot --headless --path . --script res://tests/test_mission_evaluator.gd -- --ke2-standalone
godot --headless --path . --script res://tests/integration_smoke.gd
godot --headless --path . --script res://tests/operations_smoke.gd
godot --headless --path . --script res://tests/prototype_smoke.gd
godot --path . --rendering-method gl_compatibility --script res://tests/ke2_results_integration.gd -- --preview
```

The standalone flag selects KE2's evaluator cases. The older optional runtime cases depend on HPC's later `init_validated_run` extension. This branch's dedicated integration suite exercises the SE candidate's actual KE1/HPC path and Results.

Retest the normal route with Capture Imagery, Equator, Body 1, Wings 1, Radio 1, sample 1U profile, small launcher, Polar orbit, 4 observations, 30 MB, 6 orbits and budget 100. Launch, skip playback to the end and open Debrief. Expect success/100 and 4/4 captures, 48/30 MB. Inspect Recent Runs, the full event history and Show credits. Retry should produce a new run ID, reopening should preserve history, and New Mission should clear it.

Manual-action B02 checks, official B10 served-build review and exports remain pending. Older KE2 reports retain their original run identities in the KE2 checkout.
