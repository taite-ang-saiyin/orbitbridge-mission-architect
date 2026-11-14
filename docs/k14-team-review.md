# K14 team review

Local automated checks passed on 14 November 2026. This sheet records the separate team review; passing local tests does not fill in a teammate's approval.

## Check these results

| Scenario | Expected result | Local result |
| --- | --- | --- |
| Starter design | 1060 g / 82 credits, ready | PASS |
| Advanced camera, standard battery, small launcher | 1380 g / 96 credits; sample `< 1330 g` rule fails; launcher capacity itself still passes | PASS |
| Advanced camera, large battery, small launcher, budget 120 | 1580 g / 106 credits; sample mass and high-inc launcher capacity fail; budget passes | PASS |
| Basic parts with budget 81 | Weight passes, cost 82 exceeds budget; launch stays blocked | PASS |
| Unsupported target in a saved draft | Reject it, name Equator as the available choice, no fabricated totals or launch | PASS |
| Restore Equator explicitly | Readiness returns to passing | PASS |
| Equator with either agreed orbit | Both presets finish through HPC and KE2; high_inc returns 48 MB, low_eq about 44.32 MB, both meet 30 MB | PASS |
| Launch attempted through a disabled button or Operations navigation | Invalid design cannot start a run | PASS |
| Retry, stop, and New Mission | New counters/run ID, null abort score, no duplicate reports, cleared history for New Mission | PASS |

The scripted source check executes 40 assertions across the real screens. The standalone Windows demo also exposes the same check using its explicit verification command. Normal app startup opens Home.

## Short team walkthrough

1. Open the Windows demo or the Godot project. Keep the starter mission goals.
2. In Builder, note 1060 g / 82 credits. Choose Advanced imaging camera: 1380 g and a clear blocked-launch reason.
3. Choose Large battery too and set budget 120 in Mission Creator. Readiness must also fail the small launcher's 1500 g high-inc limit.
4. Restore starter parts; set budget 81. Readiness must pass weight but fail budget.
5. Restore budget 100. Creator offers the supported Equator target only. The automated check covers an unsupported saved target and its explicit correction; the UI does not offer fictional extra targets.
6. Launch the starter design, Run to end, then View Debrief. Check 4 captured observations, 48 MB returned, success and score 100.
7. Retry, stop the run, and view its null-score failed result. New Mission should clear earlier run history.

## Team confirmation

Status: **TEAM WINDOWS-DEMO ACCEPTANCE CONFIRMED BY USER** on 14 November 2026. The user reported: "Windows demo is okay by the team review". This records the team's demo acceptance alongside the passing automated scenarios. It does not invent individual reviewer names or claim each case was manually exercised by every member.

| Role | Reviewer | Decision | Date/time | Notes |
| --- | --- | --- | --- | --- |
| KE1 | | Not individually recorded | | Team demo acceptance reported by user |
| SE | | Not individually recorded | | Team demo acceptance reported by user |
| HPC | | Not individually recorded | | Team demo acceptance reported by user |
| KE2 / KE3 | | Not individually recorded | | Team demo acceptance reported by user |

K14 has local scenario evidence and the user's subsequent confirmation of team demo acceptance. Members can add their own names, per-case notes and times if desired; blank details are not prefilled. The signed team-agreement.md is unchanged.
