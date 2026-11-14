# KE2 report for HPC run_ke2_handoff_v01

Revision: `ke2-hpc-report-v0.1`. This is an evaluator-generated report from HPC's committed sample trace, not a hand-authored contract example. The report artifacts are local files pending publication; their revision and SHA256 identify this sample independently of a future commit.

- [Evaluation result](ke2-hpc-report-v0.1.json): unchanged `{ "ok": true, "report": MissionReport }` output.
- [Provenance, source credits, and evidence](ke2-hpc-report-v0.1.metadata.json): sidecar metadata, separate from the agreed MissionReport schema.

## Revisions

Repository: https://github.com/taite-ang-saiyin/orbitbridge-mission-architect

Evaluator branch `memberKE2`, commit `f313e6fbf5c0eed7f67885edb45ce5ba45b85bba`:

- `scripts/evaluation/mission_evaluator.gd`
- `scripts/evaluation/mission_feedback.gd`

HPC branch `feature/hpc-simulator`, commit `ce478f94a918047c0449fe30bfffe18f368315fd`, input `docs/hpc-ke2-trace-v0.1.json`. That file includes the launch config, terminal state, and all 62 ordered events. The trace retains its original generation metadata, which describes changes as uncommitted against an earlier base; the complete bundle is now retrievable at this pinned commit. No unit conversion or config alteration was applied.

Evaluation call: `MissionEvaluator.evaluate_mission(trace.config, trace.final_state, trace.events)`.

## Result and evidence

Run `run_ke2_handoff_v01`, mission `mission_ke2_handoff_v01`: naturally completed at step 60/60, `partial`, score **25**. Captures: **1/4**. Data received on Earth: **7.7333333328/30 MB**. Another **4.2666666672 MB** remain onboard and do not count toward returned data.

Completion ratios are 0.25 and 0.25777777776; the equal-weight score before rounding is 25.388888888, rounded once to 25.

- `evt_001`: accepted observation, +1 capture and +12 MB stored.
- `evt_007`: accepted transmission, +7.7333333328 MB received on Earth. This event is not the LOW_BATTERY event from the contract examples.
- `evt_008`: blocked transmission, `NO_LINK_WINDOW`, step 8, zero resource deltas. The report references this event in its ground-segment cause.
- `evt_061`: natural mission completion at step 60.

The blocked transmission establishes a specific operation failure, not the complete cause of both unmet goals. No observation-block event supports a cause for the capture shortfall. The proposed experiment is to transmit during an available ground-contact window on retry.

## Source-credit metadata

The actual report has `source_ids: []`; the sidecar therefore has `resolved_sources: []` and `unresolved_source_ids: []`. The evaluator currently emits no NASA source IDs. The trace's selected launch profile alone does not establish that a NASA-derived readiness check was executed. Keep NASA credit integration pending rather than attaching a source to an unverified rule use. `docs/sources.md` contains the existing background ledger notes.

## Verification and limits

Confirmed engine with `--version`: `4.7.2.stable.mono.official.ed1daf0bf`.

Commands run from the repository root, with `$ke2Godot` set to `D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe`:

```powershell
& $ke2Godot --version
& $ke2Godot --headless --log-file 'D:\orbitbridge-mission-architect\tmp\ke2-hpc-report.log' --path . --script res://tmp/export_ke2_hpc_report.gd
& $ke2Godot --headless --log-file 'D:\orbitbridge-mission-architect\tmp\ke2-evaluator-checks.log' --path . --script res://tests/test_mission_evaluator.gd
git diff --check
```

The temporary export/check helper and extracted input are local scratch files, not part of the shared implementation. The helper invokes the evaluator call above and writes its returned wrapper without modifying fields.

Recorded HPC trace checks: **146 passed, 0 failed**, including literal outcome expectations, exact run/mission identity, evidence references, unique event IDs, event-counter reconciliation, determinism, and input preservation. Evaluator fixture suite: **143 passed, 0 failed, 5 pending**. Both Godot commands exited 0. The certificate-store environment error appeared in both runs; these checks use local inputs and no network. `git diff --check` passed.

HPC explicitly labels this a sample with `launch_approved: false`. This verification evaluates its committed recorded trace; it does not replay the HPC engine, approve launch readiness, or verify Results UI, duplicate report publication, retry/reset, source-credit display, or an exported build. The suite's five pending integration/comparison/readiness labels are preserved; the separate recorded-trace check closes only this report handoff.

Next handoff: KE3 can bind this report and its referenced events; SE/KE1 still need to supply an approved launch and integrated lifecycle check. Resolve NASA source metadata when actual rule use is established. No teammate message, commit, or push was performed for this sample.
