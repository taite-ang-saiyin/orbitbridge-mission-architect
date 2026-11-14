# A07 accessibility fixes and verified retest

**D01 CLOSED. D02 CLOSED. B02 NOT TESTED.** This task changes local presentation/accessibility only; production integration and source-of-truth data remain unchanged.

## Changes

| File | Change |
|---|---|
| `ke3/debrief_screen.gd` | Connect DebriefScroll.gui_input; handle pressed Down/Up/PageDown/PageUp only when the report region has focus and overflows. Preserve modifier shortcuts/Tab/Shift+Tab, clamp pixel scrolling, accept handled events to prevent accidental footer focus changes. No report values recalculated. |
| `ke3/operations_screen.gd` | Enable native ScrollContainer.follow_focus. After action focus enters, retain4px vertical space for the focus outline; no action request or telemetry mutation in focus handling. |
| `tests/a07_local_qa_check.gd` | Retain original scrolling/clipping assertions; add separate four-direction key tests, region-only scope, report/snapshot equality, all three action-button visibility, focus0/enabled1/disabled0 dispatch and full focus-outline containment. |
| `A07_DEFECTS.md` | Record verified closure, exact before/after behavior and reproduction evidence. |
| `A07_CHECKS.md`, `A07_QA_SHEET.md`, `A07_DEMO_SHOT_LIST.md` | Add dated current-status notes while retaining historical failing QA/planning records. |
| `verification/run_a07_fix_verification.py` (new) | Reuse existing A07 runner functions in separate before/after output directories. Preserve old runner, original A07 commands/logs/captures; explicitly verify only allowed files changed. |

New `A07_FIX_CHECKS.md`/`A07_FIX_COMMANDS.md` are the retest report/commands. Import creates normal generated Godot cache/UID output; no preview project.godot or startup edits. Active team checkout is not used for Godot tests.

## Original reproduction and preservation

Archived original source/doc bytes and the complete original A07 run directory under `verification/a07-fix-before/`. `source-sha256.json` records91 original non-cache/non-verification files. Fresh original900x680 run: **78 checks,2 failures, exit1**; same original D01/D02 failure labels. No original failing evidence was overwritten. Original `A07_COMMANDS.md` remains unchanged.

The fix-run preservation report lists the explicit expected changes, with no unexpected changes; original startup, session/providers/scenes, fixture JSONs, A03-A06 tests and recorded report/trace bytes are preserved. Independent team-checkout preservation is recorded in `..\ke3_validated_run_a07_fixes\evidence\final-preservation.json`.

## Final actual executions

Godot `4.7.2.stable.official.ed1daf0bf`, preserved Standard console executable. Windowed logs report OpenGL3.3 Compatibility / NVIDIA RTX4060 Laptop GPU. All36 latest canonical after commands pass, exit0, with no script/parser/runtime error lines. Earlier before/diagnostic records remain in the full manifest.

| Suite | Headless | Windowed | Exit |
|---|---|---|---|
| A01 Operations and Results, empty inputs | FIXTURE PASS | FIXTURE PASS |0 each|
| A02 fixtures |254 passed,0 failed|255 passed,0 failed|0 each|
| A03 Operations |256 passed,0 failed|259 passed,0 failed|0 each|
| A04 orbit/timeline |206 passed,0 failed|210 passed,0 failed|0 each|
| A04 first/second restart processes |9 each,0 failed|10 each,0 failed|0 each|
| A05 Debrief |139 passed,0 failed|156 passed,0 failed|0 each|
| A06 Retry P0 |100 passed,0 failed|104 passed,0 failed|0 each|
| Recorded KE2 Debrief |49 passed,0 failed|52 passed,0 failed|0 each|
| Project import, all9 scene startups, A07 parser |PASS|Not a human playtest|0 each|

| A07 viewport | Checks passed | Failed | Exit |
|---|---:|---:|---:|
|1280x720|91|0|0|
|1024x768|91|0|0|
|900x680|91|0|0|
|Independent1024x768 process|91|0|0|

Full semantic records match between the two1024x768 processes; only diagnostic ObjectIDs are normalized. The final matrix was rerun after adding focus-outline padding; prior passing90-check runs remain in the manifest. No broader tests were repeated after the final documentation-only updates.

At900x680: D01 PageDown0→362, Down362→394, Up394→362, PageUp362→0; focus stays on DebriefScroll. PageDown while Retry has focus leaves scroll/counters unchanged. The report, goals/actuals, score, reasons and telemetry remain identical. Credits, Retry, visible focus, Tab/Shift+Tab, Escape option dismissal, Cancel, immutable A and clean B reset still pass.

D02: before Transmit y665..696 was below clip y144..656; after y621..652 and3px focus outline fit. Observe and Power-save also remain visible when focused. Focus emits0; enabled Transmit Space emits exactly1; disabled Transmit emits0. Legality remains supplied by the provider.

Recorded sample remains partial25,1/4 observations,7.7333333328/30MB and evt_008 step8, with launch_approved=false, empty source_ids and null comparison. It is not relabeled as the fresh validated run.

## Commands and evidence

Working directory `C:\Workspace\OrbitBridge\Event\ke3_outline_preview`:

```powershell
& 'C:\Program Files\WindowsApps\OpenAI.CodexPrimaryRuntime.v26-1112-737-0_26.1112.737.0_x64__3k8sg7r9htsxt\dependencies\python\python.exe' -X utf8 -B verification/run_a07_fix_verification.py before
# Executed before edits: exit1, both defects reproduced and archived.
& 'C:\Program Files\WindowsApps\OpenAI.CodexPrimaryRuntime.v26-1112-737-0_26.1112.737.0_x64__3k8sg7r9htsxt\dependencies\python\python.exe' -X utf8 -B verification/run_a07_fix_verification.py after
# Final actual execution after fixes: exit0.
```

The before phase deliberately refuses to overwrite an existing archive. Use the preserved commands to reproduce rather than deleting evidence. `finish` refreshes retest commands/preservation without executing scenes. Every child invocation and exit is in `A07_FIX_COMMANDS.md` / `verification/a07-fix-runs/manifest.json`; current36-command results are `current-results.json`. Per-viewport JSON/PNGs are `confirm-*`; original/reproduced failures are under `a07-fix-before/`. The Transmit after PNG was visually checked for a complete focus border; long Debrief/credits captures were reviewed.

No remaining failure was observed in the requested local matrix/regressions. Live module wiring, human playtest, browser/export and B02 remain NOT TESTED. The separate SE prototype route probe is mock UI evidence only.
