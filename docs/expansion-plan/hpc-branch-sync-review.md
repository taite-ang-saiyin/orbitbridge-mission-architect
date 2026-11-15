# HPC branch sync review

Fetched `origin/feature/hpc-ke3-goal-evidence-v1` on 15 November 2026, Asia/Rangoon. Both `FETCH_HEAD` and the remote-tracking reference resolve to `61a2772acbb55a069d4472079611fcdb91c43960`. KE2's current branch is `features/KE2` at `cb458c7d9c9b3b2484e8111dbbec4ea1468f51b8` with the existing local candidate changes. The branch was inspected and exercised in `exports/hpc-branch-61a2772`.

## What arrived

Since evidence release `345e5bd`, commits `c316766` and `61a2772` add native config-v2 support to the adapter, step engine and whole-run simulator. They also change KE1's catalog loader/validator, SE's runtime snapshot list and KE2's evaluator. These cross-owner edits need consolidation with the current owner implementations.

Four reproduced executions use actual config-v2 inputs and preserve native events and snapshots. Communication complete/shortfall counts are 2/1 with 24/12 MB returned. Weather complete/shortfall counts are 2/1 revolutions with 24 MB returned in both cases. Native initialization through the branch's readiness path succeeds for the supplied valid Communication config.

The original 12-example release remains recorded by its existing receipt. The new commits introduce an additional config/report format. [Original evidence receipt](hpc-evidence-receipt.md)

## Compatibility findings

| Area | Fetched branch behavior | Required owner handoff |
| --- | --- | --- |
| Config revision and presets | Upstream tests use `v2.0-agreed` and `hpc_communication` / `hpc_weather_monitoring`, each revision 1 | KE1/HPC reconcile the consolidated revision and preset identity. The reviewed KE1 draft uses `expansion-goals-v2-draft-2`, `communication` revision 2 and `weather_monitoring` revision 1 |
| Communication goal | `{kind: communication, required_count: 2}` plus several accepted aliases | KE1/HPC align with the reviewed `{kind: communication_contacts, required_positive_contact_steps: 2}`. The canonical draft config currently returns `INVALID_GOAL` from the fetched engine |
| Weather goal | `{kind: weather_monitoring, required_count: 2}`, with alternate count aliases. One upstream test selects two targets | KE1/HPC align with `{kind: weather_revisit, required_distinct_orbits: 2}` and the reviewed single-target rule |
| Report shape | 29 fields, dictionary `goal_progress`, `goal_type`, and snapshot fields. Existing `required_observations` and `observation_completion_ratio` are missing, and `objective` is absent | KE2/SE/KE3 consolidate the reviewed 17-plus-two envelope. Calling existing feedback produces `SCRIPT ERROR` at `mission_feedback.gd:41` |
| Goal validation | A Communication config with `goal.required_count: 0` returns `ready_to_launch: true` | KE1 validates new positive goal requirements before readiness succeeds. The adapter's later rejection cannot replace readiness validation |
| Evaluator evidence | Changing a genuine shortfall's stored `actual_count` from 1 to 2 yields a successful upstream report for the same event history | KE2 derives or validates counts against accepted events and frozen requirements. SE coordinates execution keys and immutable retained records |
| Simulator test | The existing test asserts exactly 2 qualifying steps. Its deterministic four-capture config produces 4 steps and 48 MB | HPC reconciles the test with the intended action policy and preserves over-target raw counts |

The `v2.0-agreed` string above is the upstream test value. The local signed contract still identifies `v1.0-agreed`. Proposed expansion scoring and report/config choices continue through the recorded owner decisions.

## Commands and actual results

| Check | Actual result |
| --- | --- |
| Scoped fetch | Exit 0, remote tip `61a2772` |
| Upstream `test_hpc_config_v2.gd` | Prints 6 passed and exits 0, but contains three feedback `SCRIPT ERROR` traces. Recorded as failed acceptance |
| Upstream `test_simulator_v2.gd` | Assertion at line 29, expecting count 2. Process interrupted after the failed assertion left it running |
| Existing upstream `test_hpc.gd` | 48 pass, exit 0 after including its original documentation fixture in the snapshot |
| Existing upstream `test_simulator.gd` | Exit 0 with a clean log |
| Existing upstream validator suite | 293 pass, 1 fail on the previous unsupported-schema expectation. KE1 must update the version expectation together with full v2 validation |
| Native review driver | Retains four original config-v2 traces and demonstrates the report/validation gaps. Its log includes the reproduced upstream feedback errors |
| KE2 consumer review | 29 pass, 0 fail, clean log. Independent event measurements agree with the native counters |

The KE2 consumer first verifies that direct raw HPC configs return an explicit contract-revision error. It then maps copies to the reviewed draft fields for fixture evaluation, retaining the original traces separately. Those fixtures yield the expected proposed 100/75 scores and the 19-field report. Original config/snapshot values remain available in the source packet. This fixture mapping is recorded for review, with SE production execution binding pending.

The review packet records original inputs, actual results, file hashes and logs. The review drivers reproduce both the upstream failures and the KE2 fixture checks. [Machine-readable receipt](evidence/hpc-branch-sync-61a2772.json), [review bundle](evidence/hpc-branch-sync-61a2772.zip)

## Exact reproduction

Run in PowerShell from `D:\orbitbridge-mission-architect`. Fetch updates Git references. All extracted source and generated reports are written under `exports/`.

```powershell
git fetch --no-tags origin feature/hpc-ke3-goal-evidence-v1
git rev-parse FETCH_HEAD
git archive --format=zip --output=exports/hpc-branch-61a2772.zip 61a2772 project.godot core scripts data tests docs/contracts docs/handoff docs/handoffs/hpc-goal-evidence-v1
Expand-Archive -LiteralPath .\exports\hpc-branch-61a2772.zip -DestinationPath .\exports\hpc-branch-61a2772 -Force
Copy-Item -LiteralPath .\docs\expansion-plan\evidence\hpc-native-v2-review.gd -Destination .\exports\hpc-branch-61a2772\tests\ke2_native_v2_review.gd
$orbitGodot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $orbitGodot --version
& $orbitGodot --headless --path D:/orbitbridge-mission-architect/exports/hpc-branch-61a2772 --log-file D:/orbitbridge-mission-architect/exports/check-logs/hpc-native-v2-review.log --script res://tests/ke2_native_v2_review.gd -- D:/orbitbridge-mission-architect/exports/check-evidence/hpc-native-v2-review.json
& $orbitGodot --headless --path . --log-file D:/orbitbridge-mission-architect/exports/check-logs/ke2-native-v2-consumer-review.log --script res://docs/expansion-plan/evidence/ke2-native-v2-consumer-review.gd
git diff --check
```

Upstream checks use the same verified Godot executable and isolated `--path`, with script paths `res://tests/test_hpc_config_v2.gd`, `res://tests/test_simulator_v2.gd`, `res://tests/test_hpc.gd`, `res://tests/test_simulator.gd` and `res://tests/validation/test_mission_validator.gd`. Inspect logs for script errors even when exit status is 0. The simulator assertion can leave its process running, so run that upstream test with a process timeout.

The sandbox blocked `.git/FETCH_HEAD`, and the authorized fetch succeeded outside it. Godot used the previously verified outside-sandbox executable. Local README edits and existing UID files were retained. Verification covers isolated native modules and review fixtures. Browser/export and saved-A lifecycle acceptance continue through SE/KE3.

## Prepared owner handoff

HPC, KE2 fetched your branch at `61a2772` and reproduced native Communication and Weather completion/shortfall traces. Event-derived counts agree. Please align config goal names and preset/revision identity with KE1's consolidated schema, and reconcile the simulator test's expected count with its four-capture policy.

Your config-v2 check currently exits 0 while feedback raises three script errors because the added report omits `required_observations`. The report also omits `observation_completion_ratio` and uses a different goal-progress shape. KE2 will coordinate the report implementation with SE/KE3. The current evaluator accepts a tampered progress count as success, so event-derived count validation must accompany publication.

KE1, please include positive count validation in v2 readiness. A zero goal currently passes readiness, and the old schema-version regression also needs a coordinated update. SE, retain the original producer config and ordered evidence when agreeing the evaluator boundary and saved execution key. The review-only config fixtures have separate identities. Expanded scoring remains proposed.

## Completion tracking

- [x] Fetch and identify the current published HPC tip.
- [x] Compare changes since the verified evidence release.
- [x] Reproduce native v2 traces, upstream checks and KE2 measurements.
- [x] Prepare concrete config/report/validation handoffs with source and log evidence.
- [ ] Resolve producer/consumer contracts with KE1/HPC/SE/KE3, then rerun direct integration checks.
- [ ] Verify actual publication, saved A/B and presentation through the combined runtime.
