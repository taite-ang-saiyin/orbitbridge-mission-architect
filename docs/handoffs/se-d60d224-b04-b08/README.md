# KE2 evaluations for SE B04/B08 packets

Revision `se-d60d224-b04-b08-v0.1`, prepared 14 November 2026, Asia/Rangoon.

Both independent packets retain the supplied `run_001` / `mission_local` identifiers. Each case directory, original input SHA256 hashes and distinct execution key identify its report. All 20 supplied manifest hash entries match the original files.

| Case | Steps | Observations | Returned MB | Stored MB | Status | Score |
| --- | --- | --- | --- | --- | --- | --- |
| `low_eq_3orbits` | 30/30 | 4/4 | 22.1600000016/30 | 25.8399999984 | `partial` | 87 |
| `return_goal_60mb` | 60/60 | 4/4 | 48/60 | 0 | `partial` | 90 |

The outputs preserve raw actuals, original identities, `source_ids: []`, `root_causes: []` and `comparison: null`. The histories contain accepted actions and natural completion. Each report therefore uses the evaluator's neutral explanation, stating that the available events do not establish the shortfall cause.

## Files

- Low-equatorial case has a [report](low_eq_3orbits/evaluation-low_eq_3orbits.json), [metadata](low_eq_3orbits/metadata.json), original [manifest](low_eq_3orbits/source-manifest.json) and [binding context](low_eq_3orbits/binding-context.json).
- Higher-return-goal case has a [report](return_goal_60mb/evaluation-return_goal_60mb.json), [metadata](return_goal_60mb/metadata.json), original [manifest](return_goal_60mb/source-manifest.json) and [binding context](return_goal_60mb/binding-context.json).

## Evidence and scoped credits

For `low_eq_3orbits`, capture events are `evt_002`, `evt_005`, `evt_012`, and `evt_015`. Downlinks are `evt_008`, `evt_018`, and `evt_028`. Completion is `evt_030`.

For `return_goal_60mb`, capture events are `evt_001`, `evt_006`, `evt_011`, and `evt_016`. Downlinks are `evt_007`, `evt_010`, `evt_017`, `evt_020`, `evt_027`, `evt_030`, and `evt_037`. Completion is `evt_060`.

Each metadata file embeds the supporting records with their case ID, original event-file digest and JSON pointer. These references support recorded progress and completion. The report's root-cause evidence list is empty.

Each packet generated 48 MB in its four accepted captures. The first returned 22.1600000016 MB and retained 25.8399999984 MB. The second returned 48 MB and retained zero. These are recorded accounting facts. Both reports preserve the current evaluator's proposed timing experiment verbatim.

The applicable credit in both cases is `cubesat_101_1u_sample`, scoped to the executed KE1 readiness mass check, **1060 g < 1330 g**. Metadata includes the exact attribution, official NASA URLs and CubeSat 101 locator, Appendix C item 6, printed p. 79 / PDF p. 87. Existing source-verification records are carried forward from the committed ledger. Both reports emit no mission-segment cause requiring a feedback-vocabulary credit.

## Evaluator revision and verification

Repository https://github.com/taite-ang-saiyin/orbitbridge-mission-architect

Evaluator commit `b23de72dc251ee7cc1d4e3662aa0a8b3de0cfb6e`, branch `integration/ke2-se-results-d60d224`, entry point `scripts/evaluation/mission_evaluator.gd`, feedback `scripts/evaluation/mission_feedback.gd`.

The checked-out revision is `14c0f973c140e9644650e94e769b6b1b3dfb3951`. Evaluator and integration-adapter source is unchanged from the evaluator commit. Both producer packets identify SE `d60d2242d72fda0e933cc99524c113e9ca0594d9`.

Each report was generated through `MissionEvaluator.evaluate_mission(config, final_state, events)`. `evaluate_hpc_state(final_state)` and the existing `mission_results.gd` adapter produced identical reports. **39 checks passed, 0 failed**, comprising 19 checks per packet and one cross-packet execution-key isolation check. They cover expected outcomes and scores, exact counters, full event history, native snapshots, event ordering and identity, counter reconciliation, determinism, input preservation and readiness-only credit scope. [Verification log](verification.log)

Godot returned `4.7.2.stable.mono.official.ed1daf0bf` from `--version`. The temporary local harness ran with the following arguments from the KE2 workspace, using the confirmed installed executable as `$ke2Godot`.

```powershell
& $ke2Godot --version
& $ke2Godot --headless --path 'D:\orbitbridge-mission-architect\tmp\se-ke2-integration' --log-file 'D:\orbitbridge-mission-architect\tmp\se-additional-packet-checks.log' --script res://.godot/evaluate_extra_se_packets.gd -- 'C:\Users\Min Sett Paing\Downloads\Telegram Desktop\ke2_se-d60d224' 'D:\orbitbridge-mission-architect\docs\handoffs\se-d60d224-b04-b08'
```

Exit code was 0. The log includes the environment's certificate-store diagnostic. This task evaluates the supplied runtime packets. UI acceptance for B04/B08 and export checks remain with the owners. Existing report files retain their prior hashes. Concurrent KE2 documentation edits were left in place.

These report artifacts are local and await publication. KE3 can bind each report using its case metadata and exact input hashes, then verify the expected partial verdict, score, actuals, neutral cause display and readiness-scoped credit.
