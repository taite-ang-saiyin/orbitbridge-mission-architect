# A07 reproducible local defects - fixes verified

The original QA pass below recorded two display/accessibility defects without changing the UI. The subsequent authorized fix/retest changed only KE3 preview accessibility code and its QA assertions. Both defects are now **CLOSED**, after their original reproduction checks passed. No HPC science, KE2 report, production controller or startup setting was changed.

## Fix/retest - 14 November 2026

Before editing, the original A07 run directory, logs, captures, test sources and command record were copied to `verification/a07-fix-before/`. A fresh run of the unmodified test at900x680 reproduced **78 checks /2 failures, exit1**, under `a07-fix-before/reproduction/`.

| Defect | Fix | Actual retest | Status |
|---|---|---|---|
| D01 | `ke3/debrief_screen.gd`: focused DebriefScroll gui_input consumes only Down/Up/PageDown/PageUp while content overflows; bounded32px arrow/page-height scrolling. Tab/Shift+Tab and unfocused controls are untouched. | At900x680, PageDown0→362, Down362→394, Up394→362, PageUp362→0; same behavior passes all sizes. Raw context/state/report and visible metric values remain equal; focus stays in report. Credits/Retry and outside-region PageDown checks pass. | **CLOSED** |
| D02 | `ke3/operations_screen.gd`: native follow_focus plus deferred4px vertical space for the action focus outline. Focus callbacks change scroll position only. | At900x680, Transmit rect y621..652 lies within scroll clip y144..656;3px focus outline fits too. Observe/Power-save containment passes; focus dispatches0, enabled Space Transmit exactly1, disabled Transmit0. Telemetry/snapshots unchanged by focus. | **CLOSED** |

Final matrix: **91 passed,0 failed, exit0** at1280x720,1024x768,900x680 and an independent1024x768 repeat. Complete semantic repeat records match, excluding process-local diagnostic ObjectIDs only. Original scrolling/clipping assertions remain active; new checks add both reverse keys, scope/immutability and focus/disabled dispatch coverage. A03-A06 and recorded KE2 Debrief regressions pass (counts in `A07_FIX_CHECKS.md`).

Before evidence: `verification/a07-fix-before/original-a07-runs/confirm-*`, fresh `reproduction/`, and `source/`. After evidence: `verification/a07-fix-runs/confirm-*/results.json` and PNGs, especially `confirm-900x680/operations-transmit-focus.png`. Exact invocations/exits: `A07_FIX_COMMANDS.md`. The separate `A07_COMMANDS.md` remains the original failing QA record. **B02, browser/export and human playtest remain NOT TESTED.**

## Original reproduction record (before fixes)

## A07-D01: long Debrief cannot be scrolled through using focused PageDown/Down

- Owner: KE3. Priority: P2 accessibility; originally open, **CLOSED by the verified retest above**.
- Reproduced at1280x720,1024x768 and900x680; repeated in an independent1024x768 process.
- Setup: launch A05 explicit preview, select debrief_long. The existing report has a long supplied explanation and long profile/source credits. The additional long-root-cause case is a memory-only SYNTHETIC A07 layout stress copy.
- Reproduction: focus `DebriefScroll` (Tab/Shift+Tab from Credits/Retry reaches its explicit focus loop), start at scroll0, press PageDown, then Down eight times. No mouse action is involved in the measured key sequence.
- Expected: keyboard navigation can move through the long supplied report text; every section is readable.
- Actual: PageDown leaves scroll0 with focus still on DebriefScroll; Down shifts focus to ShowCredits without scrolling. The vertical scrollbar has focus_mode0. Credits shortcut via Enter works but jumps to credits; it does not make the long reason/summary keyboard-scrollable.
- Evidence: `verification/a07-runs/confirm-1024x768/results.json`, failed check `Long Debrief focused scroll responds to PageDown/Down`; equivalent records at the other sizes and `confirm-repeat-1024x768/`. PNGs `debrief-long-top.png`, `debrief-long-credits.png`, `debrief-long-cause.png`.
- Scope: source text remains intact; no truncation or outcome mutation was observed. This is keyboard access, not missing data.
- Workaround for rehearsal: mouse wheel/scrollbar; Show credits for credits. Do not describe that workaround as keyboard-only accessibility.
- Retest: implement intentional keyboard scrolling/focus behavior in a separately authorized fix; rerun the A07 matrix and existing A05/A06 regressions. D01 makes the new A07 process exit1 as intended.

## A07-D02: focused Transmit is clipped at900x680

- Owner: KE3. Priority: P2 accessibility/responsive view; originally open, **CLOSED by the verified retest above**.
- Setup: launch A03 preview at900x680; select contact_on; Tab from the fixture selector until Transmit receives focus.
- Expected: focusing an enabled operation brings its full button into the visible scroll area.
- Actual: Transmit's global rectangle is x310,y665,width271,height31; its ancestor scroll clip ends at y656. The focused button is below the visible area. Space still dispatches the supplied action, so an invisible focused control can activate. This containment check passes at1280x720 and1024x768.
- Evidence: `verification/a07-runs/confirm-900x680/results.json`, failed `Keyboard-focused Transmit visible`; `operations-transmit-focus.png` shows the missing button. `operations-observe-focus.png` shows the smaller viewport layout before the contact case.
- Workaround: scroll with the mouse, or rehearse at1024x768/1280x720. Do not call the900x680 keyboard path fully usable.
- Retest: make Operations scrolling follow focused controls, without changing provider legality/state ownership; rerun the900x680 sequence and larger viewports. No fix was made during A07.

## Contract gaps, not local defects

- R-K1 at15385a4 is intentionally blocked/incomplete; it is preserved historical evidence, not a current failing KE1 regression. Newer KE1 readiness exists separately.
- The recorded report has no failed_constraint field, source IDs or comparison object. Unavailable/null displays are correct; do not manufacture fields.
- Saturday's captures-met/data-short case and Sunday's integrated acceptance groups need actual owner-selected inputs and SE routes. Neither fixture selection nor the recorded sample supplies a live pass.
- B02, browser/export, release screenshots and human playtest remain NOT TESTED.
