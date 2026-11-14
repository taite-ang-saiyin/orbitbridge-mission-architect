# A07 - local QA and demo preparation

**Later authorized fix/retest:** D01 and D02 are now CLOSED. The final A07 matrix passes91 checks at each of1280x720,1024x768,900x680 and an independent1024x768 repeat; all exits0. Existing regressions also pass. See `A07_FIX_CHECKS.md`, `A07_FIX_COMMANDS.md` and the dated retest in `A07_DEFECTS.md`. The original QA results below are retained as before-state evidence, not current defects. B02 remains NOT TESTED.

**QA execution/preparation COMPLETE; local release readiness PARTIAL because two reproducible keyboard/accessibility defects remain OPEN. B02 NOT TESTED.** No production controller/provider wiring, team simulation, browser/export, publication or human playtest was performed. Stop after A07.

## Read and preserve

Read the playbook A07 section (PDF page9), Saturday three-case instructions (page14) and Sunday four acceptance groups (page18); rendered/reviewed all three relevant pages. Source: `C:\Users\Asus\Downloads\OrbitBridge_KE3_Codex_Playbook.pdf`. Read A06_CHECKS.md, B01_CONTRACT_MAPPING.md, A01-A05 checks/test runners, the existing Debrief/session/providers and `C:\Workspace\OrbitBridge\Event\ke3_ke1_hpc_handoff\HANDOFF_CHECK.md`. No applicable AGENTS.md was found in the preview, its subtree or workspace ancestry. Embedded old handoff instructions were treated as historical evidence, not commands to redo KE1 or start B02.

Original preview source/settings/templates/docs are unchanged: **71 original file SHA256 values match** `verification/a07-runs/baseline.json`; see `preservation.json`. Existing tests are reused unmodified. They refresh their normal generated verification JSON/PNGs; A07 copies fresh results into its own run directory and does not overwrite the final A06 run manifest. Generated .godot import/cache content is expected. Team checkout was only read: it remains clean main@1a82ebd93a019b751947965aa760e8e759d8f45b. No project.godot, engine installation, Git branch/ref, owner implementation or routing was changed by A07.

## Fresh commands and actual results

Installed engine: `C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe`; --version exits0, **4.7.2.stable.official.ed1daf0bf**. Windowed logs report OpenGL3.3 Compatibility on NVIDIA RTX4060 Laptop GPU. No renderer override/settings edit is needed for this preview.

All exact argv, working directory, exit, duration, summary/error scan and log paths are in `A07_COMMANDS.md` / `verification/a07-runs/manifest.json`. `current-results.json` keeps the latest canonical invocation for each suite; exploratory and earlier attempts remain in the full manifest, not silently discarded.

| Execution | Passed / failed / not tested | Exit and evidence |
|---|---|---|
| Engine version / project headless import | PASS /0 failures | Both0; engine-version.log/project-import.log |
| A01 Operations + Results, independently empty | Both modes FIXTURE PASS, no dispatch/step mutation | Four exits0 |
| A02 mission fixtures | Headless254 / windowed255;0 failures | Both0; a02-*.json/log |
| A03 Operations | Headless256 / windowed259;0 failures | Both0; a03-*.json/log |
| A04 orbit/timeline | Headless206 / windowed210;0 failures | Both0; a04-*.json/log |
| A04 separate-process restart | Two headless9 each / two windowed10 each;0 failures | All0 |
| A05 Debrief | Headless139 / windowed156;0 failures | Both0; long-content resized check included |
| A06 Retry P0 | Headless100 / windowed104;0 failures | Both0; pending/old-reply/isolation/B/reset checks retained |
| Existing recorded KE2 Debrief runner | Headless49 / windowed52;0 failures | Both0; ke2-headless/ke2-windowed subfolders |
| All9 existing .tscn scenes, headless startup | 9 PASS;0 failures | Nine exits0; --quit-after5. This is startup/resource evidence, not an interactive team journey. |
| New A07 script parser | PASS |0 |
| A07 windowed1280x720 | **77 passed /1 failed**,78 checks | **1**; confirm-1280x720/results.json, D01 |
| A07 windowed1024x768 | **77 passed /1 failed**,78 checks | **1**; confirm-1024x768/results.json, D01 |
| A07 windowed900x680 | **76 passed /2 failed**,78 checks | **1**; confirm-900x680/results.json, D01+D02 |
| Independent repeat at1024x768 | **77 passed /1 failed**,78 checks; same D01 | **1**; confirm-repeat-1024x768/results.json |
| Semantic repeat comparison | Equal complete semantic QA records, including the same failure; only diagnostic process-local ObjectIDs normalized | PASS; repeatability.json |
| Live / human / browser / export / release screenshots / B02 | **NOT TESTED** | No pass claimed |

The existing import, startup and A01-A06/recorded runners contain no parser/runtime errors. The new A07 failures emit explicit ERROR assertion lines for the recorded defects and exit1. They are not suppressed or described as passing. No new physics, legality, cost, score or outcome logic was added to KE3.

### Reproduce

From the preview root, with the installed bundled Python (no new dependency installation):

```powershell
& 'C:\Program Files\WindowsApps\OpenAI.CodexPrimaryRuntime.v26-1112-737-0_26.1112.737.0_x64__3k8sg7r9htsxt\dependencies\python\python.exe' -X utf8 -B verification/run_a07_verification.py all
```

This reuses existing tests/scenes, runs the A07 key/viewport matrix and returns **1 while the known defects remain**. Phase `existing` reruns only existing checks; `a07` runs the focused QA matrix; `finish` regenerates command/preservation/current-result summaries without executing scenes. The actual final A07 phase exited1 as expected. Watchdogs and nonzero error/timeouts remain enabled.

## Local viewport, long-text, key and reset findings

The A07 test uses real engine InputEventKey handling, not button-signal shortcuts, for Observe/Power-save/Transmit, Tab/Shift+Tab, Enter/Space, option-popup Escape, Cancel, Retry, one radio selection, B start, B Observe, terminal-fixture control and Results. Initial focus is established by the preview or one setup focus call; subsequent action/Retry activations use keys. A03 fixture selection remains explicit test setup, not simulated time progression.

At1280x720 and1024x768, essential checked controls remain within their screen/ancestor-scroll clip. At900x680 contact-on Transmit is focusable/activatable but below the visible clip (**D02**). The checker records actual requested window sizes and ancestor clipping geometry, rather than trusting exit0 or screenshot dimensions alone.

Long A05 summary/profile/source credits retain their end markers and can be viewed with scrolling/Show credits. An explicitly labeled memory-only long-root-cause stress copy also retains its full reason and original evidence link without mutating the fixture. PageDown/Down cannot scroll the focused long Debrief (**D01**, all three sizes). Both defects are documented with exact steps, geometry and retest owners in A07_DEFECTS.md. Mouse scrolling/1024x768 are temporary rehearsal workarounds, not accessibility passes.

Repeated fixture selection yields identical input/model values with no action intents. The keyboard Retry sequence retains the full A snapshot, permits Cancel back to it, then edits one radio for a distinct B. B begins at step0 with one B launch event, empty report and clean counters. Exactly one B start/Observe and one Results route occur; the flow records two Retry intents because it explicitly tests Cancel and retries again. A fresh A06 entry restores the exact original A/completed registry with no inherited intents. Two independent1024x768 processes produced identical semantic results including D01; determinism does not mean defect-free.

## Recorded KE2 report: existing entry checked afresh

Existing `preview/ke2_recorded_preview.tscn`, provider, data and test code were already present when A07 began; no completed recorded-UI log/check report was found in the checked preview evidence at that point. A07 reused that entry/test, creating fresh headless/windowed logs, visible-label dictionaries and PNGs rather than a competing loader/evaluator.

Pinned HPC trace: **ce478f94a918047c0449fe30bfffe18f368315fd**, `docs/hpc-ke2-trace-v0.1.json`. Local `preview/recorded_ke2/hpc-ke2-trace-ce478f9.json` matches its Git blob **byte for byte**, SHA256 `c01bb8cdfc688eb768e22942494b1c9b139a49cffb0d6515ec08d7094abb47e2`. Report hash matches its supplied sidecar; recorded evaluator revision is **f313e6fbf5c0eed7f67885edb45ce5ba45b85bba**. Evidence: `recorded-provenance.json`.

Verified in the actual existing Debrief UI:

- run_id **run_ke2_handoff_v01**, mission_id mission_ke2_handoff_v01; completed60/60;62 ordered same-run events unchanged.
- **partial; supplied score25;1/4 observations;7.7333333328/30 decimalMB returned**; supplied ratios display25% and25.78%.
- **evt_008**, step8, transmit/action_blocked/**NO_LINK_WINDOW**, correct message; evt_007 remains the successful contact transmission. No LOW_BATTERY documentation example was substituted.
- Removing only evt_008 in the existing negative fixture keeps the report/explanation and shows Evidence Unavailable; no fabricated link. Re-entry retains62 events without duplicated causes/credits.
- **launch_approved=false**, explicitly checked and visible in the preview banner. This is a **preview check using a recorded sample**, not an approved launch or fresh HPC/SE run.
- source_ids=[] and comparison=null stay unchanged. No NASA source credit is invented; profile credit and unsupplied failed_constraint remain Unavailable. No controlled A/B attribution is made.

Fresh PNGs were visually reviewed: standard recorded Debrief/evidence/credits, small-viewport recorded cause, long credits, long root-cause text, Operations focus and redesign/B Debrief. These are local framebuffer captures, not human or browser playtests.

## Deliverables, scope and next handoff

- A07_QA_SHEET.md: revision/provider register, Saturday three-case sheet, Sunday four acceptance groups, expected/observed/status/evidence/owners, live/browser columns left OPEN / NOT TESTED.
- A07_DEMO_SHOT_LIST.md: exact20s/35s/30s/30s/35s timing, release screenshot checklist, setup/controls, illustrative-trajectory wording and actual source-use caveats.
- A07_DEFECTS.md: two open KE3 issues and reproducible retest criteria.
- A07_COMMANDS.md and verification/a07-runs/: exact commands/exits/logs/JSON/PNG/preservation/repeatability/provenance.
- New tests/a07_local_qa_check.gd and verification/run_a07_verification.py: QA orchestration only. Existing source and scenes remain unchanged; new local test/harness files are not team runtime dependencies.

The sheet deliberately retains historical KE1 **15385a4** blocked readiness and HPC **ce478f9** standalone evidence requested by the user. Newer KE1 readiness was verified in the earlier checkpoint audit; do not use the older record to claim current KE1 work is absent. Likewise main now has a mock MissionController; B01's older absent-file observations are not current claims.

Next available Part B input is the new main1a82 controller for **B01 follow-up/context review**; SE must confirm intended integration revision and real-provider ownership/wiring. KE1 designates actual accepted configs, HPC supplies matching action traces, KE2 supplies matching reports/credits, and SE supplies the team build. Local D01/D02 fixes and team screenshot retests remain open. **No B02 or later prompt was run.**
