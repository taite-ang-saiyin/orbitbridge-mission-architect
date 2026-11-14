# SE controller evaluation integration

Status: implemented and tested locally on `se`, based on `d60d224`. These follow-up changes are not committed or pushed. Scene files are unchanged.

## Producer version and remaining blockers

The only KE2 implementation available locally was cached `origin/memberKE2` commit `f313e6fbf5c0eed7f67885edb45ce5ba45b85bba`. Its evaluator and feedback scripts were imported without changing their scoring rules. SE added `MissionEvaluator.evaluate_hpc_state(state)` as a compatibility entry point over its existing `evaluate_mission(...)`: it requires native `config_snapshot` and full `event_log`, copies inputs, and maps HPC `terminal_reason` to the cached feedback adapter's abort-reason field.

The newer handoff for `ke3_validated_1u_55d4f33_9dfd942_20261114_01` was not present. The original trace and KE2's newer native adapter have not been verified. The cached evaluator cannot score the game's added multi-target Survey delivery requirements: it returns an explicit `UNSUPPORTED_SURVEY_EXTENSION` error rather than an inaccurate score. KE2 must supply the current evaluator/handoff and confirm Survey scoring. The imported upstream evaluator suite itself reports five pending items; these are not claimed complete by importing it.

Fetching was blocked: this environment could not write `.git/FETCH_HEAD` and could not resolve `github.com`. No commit or push is claimed. A teammate KE3 verification session, screenshots and export/build are not available; all evidence here is local headless testing.

## Script / method locations

| Responsibility | Location |
| --- | --- |
| Terminal native-state evaluation | `scripts/MissionController.gd::on_terminal_state` |
| One successful publication per run ID; immutable report/history/launch validation | `scripts/integration/mission_results.gd::publish` |
| Baseline eligibility for matching goals, targets, duration and orbit | `scripts/integration/mission_results.gd::baseline_for` |
| Retry: preserve results/baseline, revalidate, assign new ID, show zeroed initial state | `scripts/MissionController.gd::retry_mission`, `mission_results.gd::retry`, `mission_runtime.gd::launch` |
| New Mission: clear reports, errors, launch history and baseline | `scripts/MissionController.gd::start_new_mission` |
| Abort the actual current playback state | `scripts/MissionController.gd::abort_current_run` |
| Playback terminal signal and Abort Mission control | `scripts/screens/MissionOperations.gd::refresh`, `build_visualization` |
| KE2 status/score/feedback, actionable errors, Retry button and all published report history | `scripts/prototype/Screen.gd::show_actual_run`, `debrief`, `result_history` |
| Visible sample source linkage | Results reads the retained launch `ValidationResult.checks.profile_mass`; Readiness retains its explicit sample `<1330 g` credit |

Operations emits its actual currently displayed terminal native state, rather than evaluating the future final state when the policy trace is first precomputed. Reopening Results invokes the same idempotent publication boundary. Prior successful reports are never replaced by later duplicate notifications. Evaluation errors retain `message` and `suggested_fix`, and preserve report history and the eligible baseline. Aborted reports retain actual counters and have a null score. Run IDs increase across New Mission within the session, even though mission results/baselines are cleared.

## Local reference reproduction

`se_reference_reproduction_01` uses the current real valid-1U fixture, one observe action at step 1, one transmit at step 7 and power-save elsewhere. It independently reproduces **partial / score 25 / 1 of 4 captures / 7.7333333328 of 30 MB returned**. This is not the original KE3 trace and does not prove the supplied KE1/HPC commit hashes. Full native state, events, actual launch validation and report are saved in `integration-evidence/controller-reference-reproduction.json`.

## Executed verification

Engine: Godot `4.7.2.stable.mono.official.ed1daf0bf`. From the project root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/se-check.log --script res://tests/controller_evaluation_smoke.gd
```

Use the same invocation with each runner below. Every listed command exited 0. macOS reports a CA-certificate environment diagnostic; no GDScript errors occurred in these passing runs.

| Runner | Result |
| --- | --- |
| `tests/controller_evaluation_smoke.gd` | Player-driven Launch, Results reopen, Retry, Abort, New Mission; duplicate publication; baseline and validation retention; error message/fix display; exact numeric reference reproduction |
| `tests/test_mission_evaluator.gd` | 143 passed, 0 failed, 5 upstream pending |
| `tests/integration_smoke.gd` | Real KE1 metrics, launch gate, HPC playback and evaluated Results at two sizes |
| `tests/operations_smoke.gd` | Playback, filters, telemetry, Results and layout at five sizes |
| `tests/prototype_smoke.gd` | Screen navigation, inputs, components and evaluated Results at two sizes |

The earlier `tests/readiness_smoke.gd` and `tests/expanded_missions_smoke.gd` evidence covers actual Builder profile switching, source mass limits and multi-target flight behavior. No new claim of teammate receipt, external sharing or selected export is made. Current logs are under `docs/integration-evidence/`.
