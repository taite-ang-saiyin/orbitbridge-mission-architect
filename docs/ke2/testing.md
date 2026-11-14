# KE2 testing and verification

Owner KE2. Updated 14 November 2026.

## Run the evaluator suite

The project uses a lightweight `SceneTree` runner. Run from the repository root. The executable below was previously verified as `4.7.2.stable.mono.official.ed1daf0bf`. Substitute the local Godot 4.7.2 executable on another machine and check its version before running the suite. [Runner](../../tests/test_mission_evaluator.gd).

```powershell
$ke2Godot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $ke2Godot --headless --version
New-Item -ItemType Directory -Force -Path './tmp' | Out-Null
& $ke2Godot --headless --log-file './tmp/ke2-evaluator-parse.log' --path . --script res://scripts/evaluation/mission_evaluator.gd --check-only
& $ke2Godot --headless --log-file './tmp/ke2-tests-parse.log' --path . --script res://tests/test_mission_evaluator.gd --check-only
& $ke2Godot --headless --log-file './tmp/ke2-evaluator-tests.log' --path . --script res://tests/test_mission_evaluator.gd
$LASTEXITCODE
```

Each invocation should exit 0. The runner prints each executed result, expected/actual values for failures, and a final count. It exits 1 if any assertion fails. Pending groups are printed separately. The latest standalone summary is `165 passed, 0 failed, 5 pending`. With the pinned HPC/KE1 dependencies present, the same runner reports `205 passed, 0 failed, 5 pending`. [Runtime setup and reproduction](hpc-integration.md).

## Recorded results

| Work | Recorded result | Evidence |
| --- | --- | --- |
| Prompt 2 setup | 9 passed, exit 0 | Checklist task history |
| Prompt 3 scoring | 80 passed, exit 0 | Checklist task history |
| Prompt 4 independent review | 98 passed, 0 failed, 7 pending, exit 0 | `tmp/ke2-prompt4-tests.log` |
| Prompt 4 deliberate failure | T01 expected 99, actual 100, exit 1 | `tmp/ke2-prompt4-intentional-failure.log` |
| Prompt 5 feedback | 143 passed, 0 failed, 5 pending, exit 0 | `tmp/ke2-prompt5-tests.log` |
| Recorded HPC trace | 146 passed, 0 failed, exit 0 | Existing report metadata and verification note |
| NASA ledger | 8 documentation check groups passed, exit 0 | Checklist source-ledger evidence |
| Prompt 7 standalone adapter | 165 passed, 0 failed, 5 pending, exit 0 | `tmp/ke2-prompt7-local-tests.log` |
| Prompt 7 combined KE1/HPC/KE2 | 205 passed, 0 failed, 5 pending, exit 0 | `tmp/ke2-prompt7-integrated-tests.log` |
| Prompt 7 unchanged producer suite | 31 passed, exit 0 | `tmp/ke2-prompt7-producer-tests.log` |

T01's intentional failed expectation was restored before the final passing Prompt 4 run. Local `tmp` logs and the trace/export helper are ignored scratch artifacts. The shared HPC report and its provenance are retained under `docs/handoffs/`. These results describe prior executions reviewed during documentation preparation. [Task evidence](../ke2-todo.md), [HPC verification](../handoffs/ke2-hpc-report-v0.1.md).

Godot emitted a Windows root-certificate-store error during the recorded successful headless runs. The verification notes record that diagnostic alongside exit codes and assertion results.

## Acceptance coverage

Unless specified otherwise, the mission targets are 3 observations and 30 MB received on Earth.

| Case | Actuals or condition | Expected result | Evidence status |
| --- | --- | --- | --- |
| T01 | 3 observations, 30 MB returned | `success`, 100 | Passed fixture suite |
| T02 | 3 observations, 10 MB returned | `partial`, 67 | Passed fixture suite |
| T03 | 3 observations, 0 MB returned, onboard data present | `partial`, 50 | Passed fixture suite |
| T04 | 0 observations, 0 MB returned | `failed`, 0 | Passed fixture suite |
| T05 | 4 observations, 30 MB returned | `success`, 100, actual count retained | Passed fixture suite |
| T06 | Target 4 observations, actual 3, returned 30 MB | `partial`, 88 | Passed fixture suite |
| T07 | Eligible retry, 10 to 30 MB returned | +20 MB, +33 points, 0 capture delta | Pending optional comparison |
| T08 | Baseline unavailable or ineligible | `comparison: null` | Dedicated eligibility cases pending |
| T09 | Relevant recognized blocked event | Cause, matching evidence ID, corrective experiment | Passed fixture suite, plus recorded NO_LINK_WINDOW trace |
| T10 | Unknown, missing, irrelevant, or invalid cause evidence | Neutral summary and empty causes | Passed fixture suite |
| T11 | Sample 1U at 1329 g, other readiness checks valid | Mass check passes | Actual KE1/Builder execution pending |
| T12 | Sample 1U at 1330/1331 g, plus profile switching | Sample mass check fails at both masses, other profile uses its rules | Actual KE1/Builder execution pending |
| T13 | Zero target | Structured input error | Evaluator passed, KE1 integration pending |
| T14 | Abort, including after meeting both targets | `failed`, null score, actuals retained | Passed fixture suite |

Additional assertions cover negative/nonfinite values, fractional counts, wrong types, completion boundaries, ratio caps, half-up rounding, fractional MB targets, repeated-input determinism, input preservation, output copying, duplicate evidence, foreign-run events, and evidence ordering. Literal expectations are checked against the agreed contract and reference vectors. [Scoring vectors](../contracts/v1-draft/scoring-cases.example.json), [validation plan](../validation-plan.md).

## Remaining integration checks

The runner still prints five pending groups for T07, T08, T11, T12, and the combined lifecycle. The pinned combined run verifies actual readiness-approved initialization, completion, block evidence, and abort handling. In that run the pending lifecycle label lists Results, duplicate publication, and retry/reset. The current KE2 checkout lacks producer modules, so its standalone run also retains the HPC runtime portion of the pending label. Actual Results bindings, duplicate terminal notifications, New Mission reset, retry history, visible credits, and the selected export remain pending.

Optional comparison needs its implementation before T07/T08 can establish eligibility and deltas. Mass checks need KE1's validator and SE's Builder. UI and export checks need SE/KE3. Record the owner revision, inputs, observed results, and build evidence when those checks run. [Integration handoff](integration-handoff.md), [KE2 checklist](../ke2-todo.md).

## Verification for this documentation task

Five documentation check groups passed with zero failures and exit 0. They covered 51 local links/anchors, balanced code fences, all 17 report fields, four cause fields, five error fields, references to existing scripts, three exact ledger credits, recorded report metrics, historical counts, and T01-T14 coverage. `git diff --check` passed. Gameplay test results above retain their original execution history.
