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

Each invocation should exit 0. The runner prints each executed result, expected/actual values for failures, and a final count. It exits 1 if any assertion fails. Pending groups are printed separately. After the explicit Survey guard, the latest standalone summary is `167 passed, 0 failed, 5 pending`. With the pinned HPC/KE1 dependencies present, the same runner reports `207 passed, 0 failed, 5 pending`. Use `-- --ke2-standalone` after the script argument to skip producer-runtime cases when testing a different producer revision. [Runtime setup and reproduction](hpc-integration.md).

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
| KE3 supplied focused Results preview | 63 headless / 67 windowed, zero failures | `data/ke3-results-verification/evidence/validated-*.log` |
| KE3 supplied additional display/error cases | 24 headless / 29 windowed, zero failures | `data/ke3-results-verification/evidence/ke2-reply-edges-*.log` |
| SE reply follow-up, explicit Survey guard | 167 standalone / 207 combined passed, zero failed, exits 0 | `tmp/ke2-se-standalone-tests.log`, `tmp/ke2-se-integrated-tests.log` |
| Current KE2 against original validated packet | Exact report through both APIs, inputs preserved, exit 0 | `tmp/ke2-se-original-trace-check.log` |
| Actual operator-abort bundle at HPC 3990d3c | 71 passed, zero failed, exit 0, including actual KE1/HPC action/abort replay | `docs/handoffs/ke2-hpc-abort-v0.1/verification-v0.1.json` |
| Current candidate SE/KE3 Results integration at 14c0f97 | Independently rerun, 57 passed, zero failed, exit 0 | `tmp/ke2-status-results-integration.log` |
| Current candidate standalone evaluator | Independently rerun, 167 passed, zero failed, five pending labels, exit 0 | `tmp/ke2-status-evaluator.log` |

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
| T11 | Sample 1U at 1329 g, other readiness checks valid | Mass check passes | KE1 recorded fixture passed at 55d4f33, independent KE2 rerun/Builder pending |
| T12 | Sample 1U at 1330/1331 g, plus profile switching | Sample mass check fails at both masses, other profile uses its rules | KE1 recorded fixtures passed at 55d4f33, independent KE2 rerun/Builder pending |
| T13 | Zero target | Structured input error | Evaluator passed, KE1 integration pending |
| T14 | Abort, including after meeting both targets | `failed`, null score, actuals retained | Passed fixture suite |

Additional assertions cover negative/nonfinite values, fractional counts, wrong types, completion boundaries, ratio caps, half-up rounding, fractional MB targets, repeated-input determinism, input preservation, output copying, duplicate evidence, foreign-run events, and evidence ordering. Literal expectations are checked against the agreed contract and reference vectors. [Scoring vectors](../contracts/v1-draft/scoring-cases.example.json), [validation plan](../validation-plan.md).

## Remaining integration checks

The runner still prints five pending groups for T07, T08, T11, T12, and the combined lifecycle. The pinned combined run verifies actual readiness-approved initialization, completion, block evidence, and abort handling. The newer isolated SE/KE3 candidate at `14c0f97`, implementation `b23de72`, separately passes 57 checks for the actual Results scene binding, complete event delivery, scoped readiness credit, duplicate publication, reopening, Retry identity/baseline/event reset, New Mission catalog reset, malformed inputs and Survey error routing. This suite supplies candidate lifecycle evidence alongside the standalone runner's existing pending label. The candidate KE2 evaluator, feedback and runner bytes match the root working files. The root checkout remains at `79e249b` with local changes.

Manual controls and navigation, original partial/abort packets through the selected-release Results route, independent exact mass-boundary/Builder checks, Survey scoring, optional comparison, official B10 and the selected export remain pending. The latest status-review rerun confirmed Godot `4.7.2.stable.mono.official.ed1daf0bf` and executed the following from the repository root.

```powershell
& $ke2Godot --headless --path './tmp/se-ke2-integration' --log-file 'D:/orbitbridge-mission-architect/tmp/ke2-status-results-integration.log' --script res://tests/ke2_results_integration.gd
& $ke2Godot --headless --path './tmp/se-ke2-integration' --log-file 'D:/orbitbridge-mission-architect/tmp/ke2-status-evaluator.log' --script res://tests/test_mission_evaluator.gd -- --ke2-standalone
```

The KE3 packet review verified 64 supplied source/evidence hashes and all 16 named input hashes, inspected its source seam and recorded logs, and visually checked four supplied screenshots. The 63/67 and 24/29 counts are owner executions. A new KE2 UI test was not run during this review. Its preview is local and uncommitted, identified by `SOURCE_SHA256.json`. B02 and official B10 remain pending. [Consumer evidence and history mapping](integration-handoff.md#reviewed-ke3-results-preview).

Optional comparison needs its implementation before T07/T08 can establish eligibility and deltas. Mass checks need KE1's validator and SE's Builder. UI and export checks need SE/KE3. Record the owner revision, inputs, observed results, and build evidence when those checks run. [Integration handoff](integration-handoff.md), [KE2 checklist](../ke2-todo.md).

## Verification for this documentation task

Five documentation check groups passed with zero failures and exit 0. They covered 51 local links/anchors, balanced code fences, all 17 report fields, four cause fields, five error fields, references to existing scripts, three exact ledger credits, recorded report metrics, historical counts, and T01-T14 coverage. `git diff --check` passed. Gameplay test results above retain their original execution history.
