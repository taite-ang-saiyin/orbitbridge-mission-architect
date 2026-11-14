# A05 — SYNTHETIC Debrief, evidence and credits

**FIXTURE PASS.** Work is confined to `C:\Workspace\OrbitBridge\Event\ke3_outline_preview`. A05 stops here. This is a local automated Compatibility fixture result; live integration, browser, human playtest, publication and A06 Retry lifecycle are **NOT TESTED**.

Baseline: `C:\Users\Asus\Downloads\Telegram Desktop\team-agreement (7).md`, **v1.0-agreed**, interpreted through `B01_CONTRACT_MAPPING.md`. The attachment defines report fields; it does not authorize other phases or establish kickoff. No applicable AGENTS.md was found in the preview/workspace ancestry. `BOUNDARY.md`, A04 checks/source notes and the current Results/session/provider/history path were read. B01's description of the old dangling-event rejection is historical; A05 implements the user's new retain-report policy. B01 and A04 documents remain unchanged.

## Implementation and ownership

`ke3/results_control.tscn` now uses `ke3/debrief_screen.gd`, retaining the existing `set_inputs(context, state, report)` method and intent signals. The explicit entry is **`res://preview/a05_preview.tscn`**, with SYNTHETIC labels, a fixture selector and inherited A03/A04 Operations. The entry selects the partial Debrief initially. Default `project.godot` still starts `res://ke3/operations_control.tscn`; no startup or renderer setting changed.

| Display | Supplied input | Treatment |
| --- | --- | --- |
| Mission / goal | `context.config.mission.title`, `required_observations`, `required_returned_data_mb` | Read-only synthetic canonical config projection; legacy A02 selections remain supported. |
| Selected profile / source | `context.profile_metadata.{label,source_label,credit}` | Fixture-only metadata envelope; production SE/KE2 mapping pending. Missing values show Unavailable. |
| Outcome / run status | `report.status`, `report.run_status` | Preserve success / partial / **failed** and completed / aborted. No threshold-based outcome calculation. |
| Actuals / targets | `observations_completed`, `required_observations`, `returned_data_mb`, `required_returned_data_mb` | Supplied report counters; decimal MB boundary; no unit conversion or inferred values. Legacy names are only fallback support for old A02 fixtures. |
| Completion / score | `observation_completion_ratio`, `data_return_completion_ratio`, `score` | Ratio ×100 is formatting to at most two decimals. No calculation from counts, no scoring. Score 0 is 0; null/missing is Unavailable. |
| Summary / constraint / cause | `explanation`, optional `failed_constraint`, `root_causes[].{code,explanation}` | Supplied text only. `failed_constraint` is an optional preview extension, not an inferred v1 field. |
| Linked evidence | `root_causes[].evidence_event_ids` against accepted `state.events` | Lookup in matching active-run history only, preserving supplied event ID, step_index and message. Legacy flat references are displayed separately, never invented as causes. |
| Experiment | `next_experiment` | One supplied string; no cause selection or recommendation logic. |
| Credits | `report.source_ids`, fixture `context.source_metadata`, `context.visual_attributions` | IDs resolve only through supplied metadata; absent title/credit/URL shows Unavailable. Production ledger remains pending. |

The session still rejects stale run/report/event envelopes and duplicate event IDs. It no longer rejects a current-run report for an absent evidence link. Such a report and explanation remain visible, with **Evidence Unavailable**. Stale reports are rejected even when their referenced event IDs match current history. `report_failure` now supplies canonical `failed`; A02's dangling-event fixture and assertion now expect retention. No simulation, legality, costs, step advancement, evaluator, shared draft owner or real router was added.

Terminal state with no report displays **Awaiting evaluation**. A supplied evaluation error displays **Evaluation error**, its code/message/fix and unavailable score, rather than a failed mission. The pre-launch example selects a SYNTHETIC Readiness notice, not Debrief; actual SE Readiness routing is NOT TESTED. The fixture error/context envelopes are not production interfaces.

## Expected versus actual

Every row below matched in headless and windowed checks. Each fixture has actual section-label text in `verification/a05-runs/a05-headless.json` and `a05-windowed.json`, plus `verification/a05-<fixture>.png` from the windowed run. This is visible-label and framebuffer evidence, not a human playtest.

| Fixture | Expected | Actual / evidence |
| --- | --- | --- |
| `debrief_success` | success/completed; 3/3; 4/4 MB; 100%,100%; score100 | Exact match; `a05-debrief_success.png`. |
| `debrief_partial` | partial/completed; 1/3; 2/4 MB; 33.33%,50%; score42; one NO_LINK_WINDOW cause; linked step4; one suggested change | Exact match; `a05-debrief_partial.png`; supplied experiment is “SYNTHETIC: choose a higher-contact orbit profile.” |
| `debrief_failed` | failed/completed; 0/3; 0/4 MB; 0%,0%; score0; LOW_BATTERY cause at step4 | Exact match; `a05-debrief_failed.png`. |
| `debrief_zero_score` | Valid supplied score0 remains visible | Score: 0; `a05-debrief_zero_score.png`. |
| `debrief_aborted` | failed/aborted even with 3/3 and4/4; null score unavailable; supplied abort explanation | Exact match; “Mission aborted before completion.”; `a05-debrief_aborted.png`. |
| `debrief_missing_optional` | Missing data-return ratio is Unavailable; raw2/4 and score42 remain | Exact match; `a05-debrief_missing_optional.png`. |
| `debrief_missing_score` | Missing score is Unavailable | Exact match; `a05-debrief_missing_score.png`. |
| `debrief_awaiting` | Finished state without report: Awaiting evaluation; 1/3 and2/4; no invented score/ratios | Exact match; `a05-debrief_awaiting.png`. |
| `debrief_stale` | Reject other report run despite matching event ID; clear report; show stale reason | accepted=false / stale_run_id, no stale explanation or experiment; `a05-debrief_stale.png`. |
| `debrief_missing_event` | Retain current report, score42 and explanation; linked evidence unavailable | accepted=true; Evidence Unavailable: SYNTHETIC-A05-EVENT-NOT-IN-ACTIVE-RUN; `a05-debrief_missing_event.png`. |
| `debrief_evaluation_error` | Distinct evaluation error, not failed outcome | INVALID_EVALUATION_INPUT, supplied message/fix, score Unavailable; `a05-debrief_evaluation_error.png`. |
| `debrief_prelaunch` | Rejection stays in preview Readiness notice; no Debrief outcome/score | Selected tab2 ReadinessNotice; `a05-debrief_prelaunch.png`. |
| `debrief_missing_credit` | Missing profile/source metadata shows Unavailable, with unresolved ID retained | Exact match; `a05-debrief_missing_credit.png`. |
| `debrief_long` | Long explanation/credits scroll; footer Retry remains reachable | Scroll position2692/max3366 at1280×960; Tab reaches credits then Retry; visible gold3px focus; `a05-long-credits-keyboard-focus.png`. Resize900×680 retains footer; `a05-long-resized.png`. |

Additional **FIXTURE PASS** checks: supplied ratio0.125 displays12.5% while raw observations remain1/3; supplied score17 displays17. Foreign-run history rejects with stale_event_run_id. Direct stale report source IDs cannot leak. Re-entry reproduces exactly the same label strings, with no duplicate cause/credit text. Rendering, evidence lookup, scrolling, focus, re-entry and resize produce **0 action intents, 0 route intents, 0 Retry intents and 0 provider action calls**. Source fixture dictionaries remain unchanged. An unmounted A05 provider exposes no catalog and returns preview_entry_required. Existing A02 failed-live-provider checks confirm no fallback to mocks.

The A05 keyboard test sends engine Tab key events and inspects focus; Retry is not activated by this new suite. A03's pre-existing cancellation checks still run. A06's new-run/draft/reset lifecycle is not implemented or claimed.

## Commands and exits

Executable: `C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe`, version **4.7.2.stable.official.ed1daf0bf**. Windowed log confirms **OpenGL 3.3 Compatibility, NVIDIA GeForce RTX 4060 Laptop GPU**. Both A05 evidence JSON files record gl_compatibility.

Full exact PowerShell commands, arguments, per-run exit status and log paths are in **`verification/a05-commands.md`** and **`verification/a05-runs/manifest.json`**. Reproduction from this preview folder:

```powershell
& 'C:\Users\Asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'verification/run_a05_verification.py'
```

Runner exit **0**; all **16 Godot processes exit0**, with no script/parse/engine errors in their captured output. Final run results:

| Suite | Headless | Windowed Compatibility | Result |
| --- | --- | --- | --- |
| A01 Operations, empty | draft unchanged, advance_calls0, all intents0 | same + capture | FIXTURE PASS |
| A01 Results, empty | draft unchanged, advance_calls0, all intents0 | same + capture | FIXTURE PASS |
| A02 | 254 checks,0 failures | 255 checks,0 failures | FIXTURE PASS |
| A03 | 256 checks,0 failures | 259 checks,0 failures | FIXTURE PASS |
| A04 | 206 checks,0 failures | 210 checks,0 failures | FIXTURE PASS |
| A04 restart first | 9 checks,0 failures | 10 checks,0 failures | FIXTURE PASS |
| A04 restart second | 9 checks,0 failures | 10 checks,0 failures | FIXTURE PASS |
| A05 | 139 checks,0 failures | 156 checks,0 failures | FIXTURE PASS |

Development corrections before final verification: the first A05 test used an incorrect expected mission title and no explicit headless window size (exit1). The expectation was corrected to the reused A02 mission title and the harness now explicitly sets1280×960. No fixture value was changed to make that assertion pass. The final repeated runs above pass.

SHA-256 preservation checks pass for `project.godot`, A04 Operations/orbit/timeline, A03/A04 providers, A04 entry, unchanged A01/A03/A04 suites and A04/B01 documents. The historical checkout was not modified by this work. A read-only end check found clean main at `e78cf459c79ee7bb63255a2891282e6d37cbca14`; B01's older checkout snapshot is not a current integration assertion. No branch, checkout, renderer, installation, fetch or production wiring was performed for A05.

## Changed files

- Added `ke3/debrief_screen.gd`: supplied-value Debrief, scoped evidence, credits, scrolling and focus.
- Changed `ke3/results_control.tscn`: attach that presentation script.
- Changed `ke3/presentation_session.gd`: retain current-run report with missing evidence; stale identity checks remain.
- Changed `preview/mission_fixtures.gd`: canonical failed and accepted dangling-event expectation.
- Changed `tests/mission_fixture_check.gd`: updated dangling-event assertion; all old scenarios rerun.
- Changed `preview/fixture_provider.gd`: permit mounted explicit A05 entry.
- Changed `preview/a03_preview.gd`: Results factory hook, with existing default scene returned; A03/A04 reuse unchanged entry behavior.
- Added `preview/a05_provider.gd`, `preview/a05_preview.gd`, `preview/a05_preview.tscn`: explicit synthetic canonical report cases and Readiness notice.
- Added `tests/a05_debrief_check.gd`: literal expected metrics, evidence, focus/scroll and isolation checks.
- Added `A05_CHECKS.md`, `verification/run_a05_verification.py`, `verification/a05-commands.md`, `verification/a05-baseline.json`, `verification/a05-runs/*`, `verification/a05-*.png`, `verification/a05-results.json` and A05 startup/development logs. Existing generic regression artifacts (`mission-fixtures.json`, A03/A04 JSON/captures and A01/A02 captures) were refreshed by their suites. Nothing reads verification artifacts during gameplay.
- Appended A05 notes to `BOUNDARY.md` and `preview/README.md`.

## Pending team handoffs / next boundary

| Owner | Exact missing fields/file or sample | Affected verification |
| --- | --- | --- |
| KE2 | Production source-ledger file and revision; `source_ids` → record mapping; canonical title, URL, approved credit text and required attribution/license wording; selected profile ID → source label and credit mapping | Real credits, source confirmation and ledger lookup: NOT TESTED. Fixture keys profile_metadata/source_metadata/visual_attributions are provisional, not frozen production names. |
| KE2 | Revisioned `scripts/evaluation/mission_evaluator.gd` / `evaluate_mission(config, final_state, events, comparison_baseline)` outputs for success/partial/failed, score0, aborted/null score, missing evidence and EvaluationError; exact failed-constraint metadata if supplied | Real score/outcome/cause/error display against evaluator: NOT TESTED. No evaluation is performed by KE3. |
| SE | `scripts/MissionController.gd` actual active run/context/history getters or signals, report/error delivery and Results/Readiness routes; trusted accumulated history envelope, route re-entry and report readiness policy | Live report/evidence/run correlation and routing: NOT TESTED. Current synthetic state.events requires per-event run_id; v1 Event examples do not define that envelope. |
| HPC + SE | Revisioned ordered action event trace (`event_id`, `step_index`, `type`, `code`, `message`) tied to the controller's active run; actual config/profile metadata | Real evidence provenance and selected config: NOT TESTED. No production history envelope was invented. |
| SE / A06 | Retry/new-run lifecycle, draft ownership/reset policy and distinct new run ID | Deferred to A06; only existing Retry intent/cancellation behavior remains. |

A04 Mission Visualization attribution is reused from `A04_SOURCES_FOR_KE2.md` in the supplied preview metadata: **Mission Visualization** (https://nasa.github.io/mission-viz/), **Trajectory from GMAT** (https://nasa.github.io/mission-viz/X3Dom/20160129_Earth_MoonMission_X3D.html), and **Elliptical Orbit Simulator** (https://nasa.github.io/mission-viz/RMarkdown/Elliptical_Orbit_Design.html). The existing Operations footer remains where the visual cue is used; Debrief credits show exact titles/URLs and limited adaptation notes. No new source research or confirmation, NASA data, code, assets, physics or real profile values are claimed. KE2 approval and real ledger IDs/credit wording remain pending. Production, browser, human playtest and publication: **NOT TESTED**.
