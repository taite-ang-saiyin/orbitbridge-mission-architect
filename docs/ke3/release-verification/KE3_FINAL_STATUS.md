> Archived candidate audit. Evidence links below download `candidate-audit.zip`; extract it to use the original report with its relative evidence links. This audit targets 14c0f97 plus the stated local diff, not the newer KE3 publication base. See README.md for the port and its independent retest.

# KE3 six-checkpoint verification

Recorded 2026-11-14T19:00:02+06:30 (Asia/Rangoon). Scope: B01, B03, B10, B11, B12 and B13 only.

Fetched target: **`integration/ke2-se-results-d60d224@14c0f973c140e9644650e94e769b6b1b3dfb3951`**. Tested first as-is, then with one local KE3 presentation correction. This is a **candidate**: no SE confirmation designating this SHA as the shared/release build was found in the supplied messages or checked local handoffs. A public default-main README is not that confirmation.

| Checkpoint | PASS / PARTIAL / FAIL / NOT TESTED | SHA/build/run | Evidence | Remaining action | Owner |
|---|---|---|---|---|---|
| B01 — Contracts & context | PARTIAL | Clean `14c0f973c140e9644650e94e769b6b1b3dfb3951`; run `run_7ac31e438f5f6650b860a19a_001` | Agreed v1.0 document and actual Creator→Builder→8 KE1 checks→HPC→same-execution KE2 report; re-entry checks pass. [clean route packet — archive: evidence/clean/windowed/ui-run.json](candidate-audit.zip), [retest checks — archive: evidence/patched/windowed/checks.json](candidate-audit.zip). | Confirm explicit kickoff evidence, integration/release designation and policy/Survey route scope; review local Results correction. | SE / coordinator; KE2 for Survey scope |
| B03 — Operations & Debrief | PASS | **Local corrected candidate only**: `14c0f973c140e9644650e94e769b6b1b3dfb3951` + `KE3_PRESENTATION.diff`; run `run_2a932be4e0ba42a374a249f6_001` | 162/162 focused checks in headless and windowed modes; real policy playback, all 61 HUD frames, full ordered history, same-run report, event evidence, re-entry and Retry. [commands/results — archive: evidence/patched/commands.json](candidate-audit.zip). Clean target failed 2 negative identity/credit checks before correction. | Adopt/retest correction on the designated shared build. Manual dispatch controls are absent and not claimed; Survey returns the recorded unsupported response. | KE3 correction review / SE build owner |
| B10 — Web playtest | NOT TESTED | No served team URL/build; no human run or elapsed time | [browser evidence — archive: evidence/browser-observations.json](candidate-audit.zip) verifies public GitHub access only. Desktop/windowed engine checks do not verify Web behavior. | Supply served Compatibility URL + exact build/SHA + matching trace; perform browser checks, then separate uncoached timed teammate playtest. | SE; teammate tester + KE3 observer |
| B11 — Demo evidence | PARTIAL | Candidate QA PNGs from `14c0f973c140e9644650e94e769b6b1b3dfb3951` + local diff; visible run `run_67ad2962e5dd2f7dc0c474cb_001` | [candidate report — archive: evidence/visible/candidate-results.png](candidate-audit.zip), [candidate credits — archive: evidence/visible/candidate-credits.png](candidate-audit.zip); prepared 2:30 list below. These are QA, not approved release footage. | Designate build/cases; capture approved full loop, success, shortfall/failure and Retry with build/scenario/run labels. | SE / release capture owner |
| B12 — Public links & submission | PARTIAL | Signed-out public repo/README/source ledger; no final playable/demo or receipt | [URL access observations — archive: evidence/browser-observations.json](candidate-audit.zip) at recorded timestamp; actual GitHub public pages accessible. PDF viewer readability unverified. | Supply and check final playable/demo/source URLs signed out; obtain designated submitter's receipt. No submission or fallback acceptance was inferred. | SE / designated submitter; KE2 source owner |
| B13 — Closeout | NOT TESTED | No confirmed correction/replacement release or no-correction statement | Local correction has before/after logs, but it is not a released replacement build and no submitter closeout confirmation was supplied. | Retest confirmed replacement build/URL, or record submitter's explicit no-correction confirmation. | Designated submitter / SE; KE3 retest |

**Passed: 1/6 (16.67%). PARTIAL: 3/6 (50%). FAIL: 0/6 (0%). NOT TESTED: 2/6 (33.33%).** B03's PASS applies to the locally corrected desktop candidate and implemented playback scope. It is not a clean-commit, served-Web, approved-release, or timed-human PASS. The unmodified target's two failed negative checks remain recorded below.

## Target, preservation and provenance

- Detached test worktree: `C:\Workspace\OrbitBridge\Event\ke3_release_verification\worktree`. It belongs to an isolated local clone at `C:\Workspace\OrbitBridge\Event\ke3_release_verification\source`. No branch was switched in the user's team checkout.
- Active checkout remains `main@1a82ebd93a019b751947965aa760e8e759d8f45b`; working-tree status before and after: `clean`. Checked 247 tracked team files and 1099 preview/prior-evidence files by SHA-256: changed/missing counts 0/0; branch/head/status unchanged: True. [before — archive: evidence/preservation-before.json](candidate-audit.zip); [after — archive: evidence/preservation-after.json](candidate-audit.zip).
- Applicable AGENTS.md was checked in the workspace/repository ancestry and target tree; none found. Read the relevant previous REPORT, B01_B13_CHECKLIST and DEMO_CAPTURE_CHECKLIST under `C:\Workspace\OrbitBridge\Event\ke3_close_remaining`. Existing evidence was reused rather than relabelled as this target's execution.
- Branch ancestry includes SE `d60d2242d72fda0e933cc99524c113e9ca0594d9`, KE2 Results/scoped-credit binding `b23de72dc251ee7cc1d4e3662aa0a8b3de0cfb6e`, then target `14c0f97`. KE3 `ke3/results_control.tscn`, `outline_control.gd` and `debrief_screen.gd` are present. Later KE3 editable-Retry/manual-route fixes from other branches were not imported.
- Compared target with the **team checkout's locally available `origin/main@e71aaf8712b9b9438247cb514467bb33bc015989`**. This is the recorded local comparison ref, not an assertion about a newer unfetched main. Exact diff-stat and ancestry results: [final command evidence — archive: evidence/final-commands.json](candidate-audit.zip).
- Engine actually used: `4.7.2.stable.official.ed1daf0bf`, executable `C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe`. Windowed tests use Compatibility OpenGL 3.3 / NVIDIA RTX 4060; headless import/parser checks and real scene execution also ran.
- No shared merge, commit, push, publication, submission or messages. Engine import generated `.godot` cache and a few `.uid`/`.import` sidecars **inside the isolated worktree only**; their exact list is in final `git status`. Only one tracked source file differs.

## B01: actual context boundaries

1. `scripts/screens/MissionCreator.gd` retains goal selections; `scripts/screens/SpacecraftBuilder.gd` uses `data/mock/SatelliteAdapter.gd`/`DesignCatalog.gd` as visual-preset mapping boundaries. `scripts/integration/mission_runtime.gd::config_for()` produces canonical IDs. The word `mock` in those adapter paths does not mean the active validator or report is a fixture.
2. `FlightReadiness.gd` invokes `mission_runtime.gd::review()`, which loads this revision's catalogs with `scripts/core/catalog_loader.gd` and calls `scripts/core/mission_validator.gd::validate(config, catalogs)`. Actual launch result: ready=true, 8 passing checks, 1060 g, 82 credits, `cubesat_1u_sample`, `cubesat_101_1u_sample`, strict `1060 < 1330 g`. The saved trace retains the exact validated config and readiness dictionary.
3. Selected canonical IDs in this run: `instrument_basic`, `bus_basic`, `battery_standard`, `solar_standard`, `storage_standard`, `radio_basic`, `small`, `cubesat_1u_sample`, `high_inc`. Mission: imaging/equator, 4 observations, 30 decimal MB; profile/source are explicit.
4. `mission_runtime.gd::launch()` calls `core/HPCContractAdapter.gd::build_scenario`, then `core/MissionStepEngine.gd::init_run()` and `request_action()`. It executes the selected policy to terminal immediately and stores independent config/scenario/frame/event snapshots. Public values remain Wh and decimal MB. It does not simulate manually in response to playback buttons.
5. `scripts/integration/mission_results.gd::evaluate_trace()` calls the real `scripts/evaluation/mission_evaluator.gd::evaluate_mission(config, final_state, events)`. It validates terminal config/history equality and per-event run/mission identity. Its input key hashes config, terminal state, ordered events and readiness; `publish_results()` owns the evaluated trace/history. Evaluation occurs during Launch after policy completion on this branch, rather than a later interactive-terminal event.
6. `scripts/MissionController.gd::show_screen(5)` → `scripts/prototype/Screen.gd::debrief()/show_actual_run()` → `ke3/results_control.tscn` → `set_inputs(context,state,report)`. Context has execution key and scoped source metadata; state has complete ordered events. Three re-entries preserve history with exactly one navigate connection and one embedded Retry connection.
7. Clean actual UI run `run_7ac31e438f5f6650b860a19a_001` reached step60/60, completed, 4 observations, returned48 MB, stored0 MB, energy17.1055555560999 Wh. Its actual KE2 report is success/100, matching mission/run/goals/counters; `source_ids: []`, `comparison: null` remain unchanged. Clean execution key: `f29feab519cf6804e0a708477ad36c78382e8d15a88a530817c1b63a35c0a2c9`. Full config, readiness, final state, events and report are in the clean route packet; it is not the old 62-event recorded run.

`docs/contracts.md`/`docs/team-agreement.md` identify **v1.0-agreed**, all-role agreement recorded 14 November 2026 10:01 Asia/Rangoon. Agreement evidence is not independent kickoff or release designation evidence. Supplied handoff messages and recent local Telegram files did not supply the missing served Web/release/submission decisions.

## B03: interaction, evidence and local correction

The implemented controls are **policy playback**: Play, Pause, Step, scrub/select frame and replay-style controls. The focused probe verifies Step, Play/Pause, every native-frame HUD counter, terminal duration, own report/evidence, history ownership and Retry. Existing Operations tests additionally cover playback, tabs/filtering, telemetry, completion/comparison presentation and five viewport sizes. The visible timeline is a projection of frames; it is not a claim that all native event IDs are individually printed there. The full native event history remains in the saved trace.

There are no manual Observe/Transmit/Power-save buttons on this target. Enabled-one-dispatch and disabled-Transmit-click checks are therefore **not available for this UI**. Manual button results from another branch were not reused as a pass here.

A separate copied engine probe requests no-contact Transmit and receives `action_blocked` / `NO_LINK_WINDOW`; step, energy, stored MB, returned MB and observations stay unchanged. It is saved in [separate probe — archive: evidence/patched/windowed/separate-rejection-probe.json](candidate-audit.zip) and never appended to the UI run history. Another separately labelled native API run `six_check_evidence` produces partial/completed, score25, 1/4 observations, 7.7333333328/30 MB and cause `evt_008` at step8. That report displays its actual explanation/experiment and linked event. Missing evidence preserves the valid report and displays Evidence Unavailable. [component evidence — archive: evidence/patched/windowed/component-evidence.json](candidate-audit.zip) is not the UI run's history.

**Survey:** real validation/HPC execution is runnable, but the actual evaluator returns `ok:false`, `INVALID_EVALUATION_INPUT`, field `config.mission.objective`, message “Survey requires per-target delivery evaluation beyond the agreed v1 aggregate goals.” Suggested fix is supported imaging or agreement on Survey scoring. [actual Survey response — archive: evidence/patched/windowed/survey.json](candidate-audit.zip). No score or outcome was invented. SE/KE2 release scope confirmation remains missing.

**Reproducible clean defect:** reuse the valid component report's run ID but change its mission ID. The clean KE3 view accepts it as `presentation_state=report` and also shows report-scoped vocabulary attribution. Both focused modes record **160 pass / 2 fail, exit1**. These are presentation binding failures, not a failing normal-success evaluator run.

**Local correction:** `C:\Workspace\OrbitBridge\Event\ke3_release_verification\worktree\ke3\debrief_screen.gd` checks supplied mission identity, mission goals and terminal counters in addition to run ID. Mismatches become `stale_report`; rejected reports cannot contribute report-scoped source IDs or feedback credits. Independently executed readiness attribution remains. The evaluator, physics, source catalogs, controller, scene files and project settings are unchanged. Patch: [KE3_PRESENTATION.diff — archive: KE3_PRESENTATION.diff](candidate-audit.zip). `git diff --check` and parser check exit0. Patched modes record **162 pass / 0 fail, exit0** with no script/runtime error. Wrong-mission before/after: [before — archive: evidence/clean/windowed/wrong-mission-display.json](candidate-audit.zip); [after — archive: evidence/patched/windowed/wrong-mission-display.json](candidate-audit.zip).

Retry on this exact branch immediately revalidates/relaunches the same saved design with a distinct run ID, preserved mission and fresh initial counters/history. It is **not** the newer editable Retry flow. Use the separate Modify Design route for a component change; that branch distinction must be honoured in narration.

## Commands, exits and logs

All exact arguments, working directories, exits and log paths are in [COMMANDS.md — archive: COMMANDS.md](candidate-audit.zip). Machine-readable records: [clean — archive: evidence/clean/commands.json](candidate-audit.zip), [patched — archive: evidence/patched/commands.json](candidate-audit.zip), [final verification — archive: evidence/final-commands.json](candidate-audit.zip). Process watchdog timeouts are failures, not silently accepted. Log scans reject SCRIPT ERROR, ERROR, parser/assertion failures and timeouts.

Executed on both clean and patched source:

- Headless editor import: exit0, no error diagnostics.
- `tests/test_hpc.gd`: 26 pass, exit0.
- `tests/ke2_results_integration.gd`: 57 pass, exit0.
- `tests/integration_smoke.gd`: both1440×900 and1024×768 flows pass, exit0. It reports scenario/viewport outcomes, not an assertion count.
- `tests/operations_smoke.gd`: five viewport checks pass, exit0; no invented aggregate assertion count.
- `tests/prototype_smoke.gd`:1280×720,1024×768 and navigation pass, exit0.
- External `target_probe.gd`: clean headless/windowed each160/162, exit1; patched headless/windowed each162/162, exit0. Repeated executions do not create additional unique test cases.
- Supplemental `visible_probe.gd`: same162 checks, exit0; captures1440×900 with both outer and report scroll regions positioned to expose report/credits. Captures are programmatic native-window QA, not keyboard-only human or browser evidence. Source/capture script stays outside the project.

Clean tests ran before the production edit and a clean tracked-source diff check passed then. Current source diff is exactly the attached one-file correction. Patched images and models match actual counters; baseline views with the report below the outer fold are retained as-is rather than overwritten.

## B10: browser and human evidence are separate

**Team-build browser results: NOT TESTED.** No SE served Compatibility URL/build identifier or corresponding browser-created trace was supplied. Resize,900×680 keyboard focus/scroll, blocked feedback, in-game source-link activation and restored Retry context on that export cannot be inferred from desktop tests. Browser/version, build, Web run ID and elapsed time for that test are unavailable.

**Timed teammate results: NOT TESTED.** No other teammate played under observation; no timing, hesitation or uncoached navigation evidence exists. Once a build arrives, start timing at goal definition and record actual duration against roughly five minutes, exact step of each problem, browser/version and the same run's HPC trace. A desktop/recorded fallback is not an accepted submission alternative without organizer confirmation.

**Independent signed-out link check:** IAB displayed the public repository, rendered README and source ledger without login. Version is not exposed by that browser surface. URLs/results/timestamp are in the browser observation record. The live default README contains newer manual-action descriptions; it is not documentation evidence that this pinned policy branch has those controls. The NASA alternate PDF navigation reached its URL but the viewer stayed blank; readability remains unverified. This public-doc check does not satisfy B10 or final submission verification.

## B11: prepared 2:30 capture plan

- 0:00–0:20: mission goal, selected target, observation and returned-data goals; record exact approved build/config/scenario.
- 0:20–0:55: design, canonical parts/profile/source and actual readiness. Explain1060g/82credits as this candidate's illustrative baseline; CubeSat source applies to the executed sample mass check.
- 0:55–1:25: actual Operations controls. For this candidate narrate Play/Pause/Step as **policy playback**, with Wh/decimal MB and ordered run evidence. Never narrate it as manual Observe/Transmit dispatch.
- 1:25–1:55: that run's KE2 outcome/score, unmet-goal cause/event if present, experiment and scoped credits. Use a separately approved shortfall case, not an unrelated report over the success history.
- 1:55–2:30: Retry's new identity/fresh context. This candidate retries the same design immediately; use separate Modify Design to change one component and revalidate if approved for the shot. Label any time-compressed/same-build recorded continuation.

Required approved captures still pending: full loop, goals-met success, approved shortfall/failure, Retry and credits/source access. Label each with filename/time/build+diff/scenario/run/mission/execution key. Existing prepared power evidence is a **different historical component case**, not newly verified target footage. If approved, label it **partial /88**, with `LOW_BATTERY` at step71; never failed/0. Its alternative profile does not justify CubeSat1U readiness attribution. No approval was supplied, so it remains preparation.

QA images now available: [actual success report — archive: evidence/visible/candidate-results.png](candidate-audit.zip), [readiness credit — archive: evidence/visible/candidate-credits.png](candidate-audit.zip), [separate component report — archive: evidence/visible/component-report.png](candidate-audit.zip), [component attribution — archive: evidence/visible/component-credits.png](candidate-audit.zip). Visible success packet run `run_67ad2962e5dd2f7dc0c474cb_001`, key `2535346d955c9b819669075724eded4999af7fa833d8c92b5bcb1e70ce9018e2`. These are not approved release footage. Illustrative trajectory/window/hardware assumptions must remain explicit; no physical flight certification claim.

## B12 / B13 remaining evidence

Public repo and README are accessible signed out. Source ledger is accessible; external PDF readability is not confirmed by the blank viewer. Final playable URL, demo URL, selected final source links, submission receipt/designated submitter confirmation and organizer fallback acceptance were not supplied. Nothing was submitted. B12 is partial solely for the independently verified public links, not submission completion.

No confirmed replacement build/correction request or submitter no-correction confirmation exists. Local negative-test correction and regression evidence are ready for SE review but cannot close B13 without that release evidence.

## Requests to send

SE / release coordinator:
Please confirm whether integration/ke2-se-results-d60d224@14c0f973c140e9644650e94e769b6b1b3dfb3951 is the shared/release target, or give its replacement full SHA. Confirm the Operations policy-playback scope and Survey scope, and explicit kickoff confirmation if separately recorded. I verified Creator→KE1→HPC→KE2 locally; one Results identity/credit presentation fix remains local in KE3_PRESENTATION.diff. Please review/adopt it and supply the exact replacement build SHA plus served Compatibility Web URL/build ID and the approved demo cases. This candidate's Retry immediately relaunches the same design; it is not the later editable Retry route.

KE2 (only if Survey is included in the agreed release):
At the pinned target, actual Survey execution returns INVALID_EVALUATION_INPUT at config.mission.objective: per-target delivery scoring requires agreement. Please confirm imaging-only release scope with SE, or provide the agreed Survey evaluator revision and a same-run report/evidence sample. Imaging reports and NO_LINK_WINDOW event evidence are already verified; please do not resend the old imaging packet.

Teammate playtester / KE3 observer (after SE provides the build):
Please reserve an uncoached roughly five-minute playtest of SE's exact served Web build: goal→design→Readiness→Launch→Operations→credits→explain Debrief→name one change→Retry. We need actual elapsed time, browser/version, run ID/trace, and any hesitation; no human timing has been collected yet.

Designated submitter / release capture owner:
Please supply the approved playable/repository/demo/source URLs and the submission receipt or equivalent confirmation. Confirm approved shortfall/power case and share labelled full-loop, success, shortfall and Retry footage from that build. If a desktop or recorded-demo fallback is proposed, include organizer acceptance. For closeout, give the exact correction/replacement build to retest, or explicitly confirm no correction is needed.

**Single next action — SE:** confirm the designated release SHA and policy/Survey scope, review the attached local Results fix, and provide the corresponding served Compatibility Web URL/build ID so release checks can continue against one identified build.
