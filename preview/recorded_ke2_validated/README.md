# KE2 evaluation of the validated 1U run

Handoff revision `ke2-validated-1u-v0.1`, prepared 14 November 2026, Asia/Rangoon.

Run ID `ke3_validated_1u_55d4f33_9dfd942_20261114_01` belongs to mission `ke3_validated_1u_feasible_20261114`.

- [Evaluation result](evaluation-v0.1.json) contains the evaluator's returned `{ "ok": true, "report": MissionReport }` wrapper.
- [Metadata](metadata-v0.1.json) supplies evaluator provenance, input hashes, evidence links, source credits, and verification results.

## Outcome

The run completed at step 60/60 with **partial** status and a score of **25**. It captured **1/4 observations** and returned **7.7333333328/30 MB** to Earth. Another **4.2666666672 MB** remain onboard. Completion ratios are **0.25** and **0.25777777776**. The equally weighted score before rounding is **25.388888888**.

The report proposes one experiment, to transmit during an available ground-contact window on retry.

## Evaluator revision

Repository https://github.com/taite-ang-saiyin/orbitbridge-mission-architect

Branch `memberKE2`, commit `8c3ed816f5122a6645c0517aecd83880876a0cd7`.

Entry point `scripts/evaluation/mission_evaluator.gd`, feedback `scripts/evaluation/mission_feedback.gd`.

```gdscript
MissionEvaluator.evaluate_mission(original_config, final_state, full_ordered_events)
```

The inputs came directly from `data/ke2_bundle/original-config.json`, `final-state.json`, and `events.json`. Calling `evaluate_hpc_state(final_state)` also produced the identical result. The report's SHA256 is recorded in its metadata. This handoff revision is locally generated and awaits publication.

## Evidence

All evidence belongs to the requested run and mission. JSON pointers identify entries in the supplied ordered event file. The metadata includes complete copies of these four records and repository links pinned to the bundle commit. [Full event history](../../../data/ke2_bundle/events.json)

| Event | JSON pointer | Step | Recorded behavior |
| --- | --- | --- | --- |
| `evt_001` | `/1` | 1 | Accepted observation adds one capture and 12 MB onboard |
| `evt_007` | `/7` | 7 | Accepted transmission returns 7.7333333328 MB |
| `evt_008` | `/8` | 8 | Transmission blocked with `NO_LINK_WINDOW` and zero resource deltas |
| `evt_061` | `/61` | 60 | Mission completes |

The report's ground-segment root cause references `evt_008`. That event establishes the blocked operation. The capture shortfall has no observation-block evidence supporting a hardware or visibility cause.

## Applicable credits

KE1's supplied result has `ready_to_launch=true`, all eight checks passing, total mass 1060 g, and total cost 82 credits. The source-linked `profile_mass` check explicitly records `cubesat_101_1u_sample`, profile `cubesat_1u_sample`, comparator `<`, and threshold 1330 g. [Readiness evidence](../../../data/ke2_bundle/readiness.json)

The current evaluator emits `source_ids: []`. Metadata records this exact output, an empty report-source resolution, and two applicable credits with their scope and evidence. The ledger's existing primary-source verification is carried forward with the relevant bibliographic details. [Source ledger](../../../data/nasa_sources.json)

- The readiness credit is **NASA CubeSat Launch Initiative, CubeSat 101**, October 2017, Appendix C item 6, printed p. 79 / PDF p. 87. Its sample 1U criterion is spacecraft mass strictly below 1.33 kg, converted to strictly below 1330 g. The source ID is `cubesat_101_1u_sample`. [NASA reference](https://science.nasa.gov/wp-content/uploads/2023/06/nasa_csli_cubesat_101_508.pdf)
- The feedback vocabulary credit is **NASA, Design and Develop Science Missions**, Julie Levri, 26 March 2025, slide 8. OrbitBridge adapts its mission-segment vocabulary for the emitted `ground` cause. `nasa_design_develop_science_missions_2025` remains a ledger-local bibliographic ID. [NASA reference](https://www.nasa.gov/wp-content/uploads/2025/04/250323-design-and-develop-science-mission.pdf?emrc=a454cf)

Exact attribution text, locators, actual use, and evidence pointers are included for each credit in the metadata. Credits display and exported-build verification remain pending.

## Verification

All 17 supplied file SHA256 hashes match `data/ke2_bundle/provenance.json`. The producer records KE1 commit `55d4f336e72a68ff31cf37e44f65a98c1cdcc193` and HPC commit `9dfd942e6fccf230d03dfdf8bf097bf65d8f143f` for the validated component run.

Godot `--version` returned `4.7.2.stable.mono.official.ed1daf0bf`. The run-specific checks passed **32/32**, covering report identity, literal expected counters/status/score, native snapshot and event-log equality, determinism, input preservation, event ordering and identities, counter reconciliation, supported cause references, and all eight supplied readiness results. The existing evaluator suite passed **165 checks**, with **0 failures and 5 pending groups**.

Commands ran from the repository root with `$ke2Godot` pointing to `D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe`.

```powershell
& $ke2Godot --version
& $ke2Godot --headless --log-file 'D:\orbitbridge-mission-architect\tmp\validated-ke2-evaluation.log' --path . --script res://tmp/evaluate_validated_ke2_bundle.gd
& $ke2Godot --headless --log-file 'D:\orbitbridge-mission-architect\tmp\validated-ke2-suite.log' --path . --script res://tests/test_mission_evaluator.gd
powershell -NoProfile -ExecutionPolicy Bypass -File 'D:\orbitbridge-mission-architect\tmp\package_validated_ke2_handoff.ps1'
git diff --check
```

The export/check helper and metadata packager are local scratch files. Both Godot executions exited 0 and emitted the environment error `Failed to read the root certificate store`. The checks use local inputs. This evaluation consumed the supplied KE1/HPC results. Live module replay, mass-boundary/profile-switch checks, SE B02, Results/retry lifecycle, visible credits, and exports remain pending.

The older `run_ke2_handoff_v01` artifacts retain their original identity and file hashes. Next, KE3 can bind this report and metadata to the requested run, show the recorded evidence and applicable credit text, and verify display through SE's Results flow.
