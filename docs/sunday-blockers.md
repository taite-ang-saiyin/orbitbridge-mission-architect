# Sunday readiness and open work

Recorded for Sunday 15 November 2026, Asia/Rangoon. Times are the team's planning targets from the proposal, not independently verified organizer deadlines. This records known gaps without treating optional features as launch blockers.

## Blocking defects in the stable Windows flow

None found in K15 verification. All 12 active check programs passed: 1790 counted assertions plus the legacy simulator, Home/settings, live layout and isolated 3D checks. The merged Windows executable passed all 61 scenario/package assertions with real graphics and headlessly.

The working path is Creator → Builder → Readiness → HPC Operations → KE2 Results. Heavy mass, insufficient launcher capacity, unsupported target and excessive cost block launch. Retry, abort and report deduplication are covered. Source rules, units and signed agreement remain intact.

## Required Sunday checks

| Item | Owner | Target | Status / next action |
| --- | --- | --- | --- |
| K16 actual player journey on the merged version | KE1 + SE + HPC + KE2/KE3 | By 11:00 | Automated merged flow passes. Repeat the walkthrough with the team using the final main build; prior team acceptance was for the earlier Windows demo. |
| K17 clear limits/source credit before feature freeze | KE1 + KE2 + SE | By 14:00 | Mass credit is visible and verified in the Windows check. Final content/credit review remains. |
| K18 Windows demo on another computer | SE + team | Before submission checks | Only this computer has been used. Try another Windows x86_64 computer, including launch, display sizing, controls and retry. |
| K19 challenge resource-list evidence | KE2 | Before submission | NASA primary source/locator is verified. Eligibility/listing in the actual challenge resource tab remains unverified in docs/sources.md. Confirm and record it without claiming the prior PDF check proved it. |
| Final package matches the final main commit | SE + KE1 | Before submission | K15 has a separately tested merged build. Rebuild after any later code changes and rerun verification. Keep binaries, tools and logs outside Git. |

## Optional or outside the chosen demo

- Controlled A/B comparison is still unimplemented in KE2; reports return comparison null. Run history and retry work. Keep comparison out of the submission claims unless separately implemented and tested.
- Browser export is not the chosen first demo and is not verified. The committed experimental Web preset is retained, and the user's unfinished local Web output-path edit is preserved on ke1.
- Native mouse automation was unavailable; real Godot control signals, rendered screens and graphical exported execution were used. A manual walkthrough remains useful for K16/K18.

No individual teammate sign-offs or another-computer test are invented here. No team messages were sent by this work.
