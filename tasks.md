# KE1 tasks

Phase: IMPLEMENTATION - v1.0-agreed remains the authority. K01-K14 including K13a are complete locally: Windows first demo confirmed by the user, 1706 source checks plus the legacy simulator suite passed, 61 standalone checks passed in headless and graphical modes. The user confirmed the Windows demo is okay by team review; individual manual case signatures were not supplied. See docs/k13a-k14-progress.md and docs/k14-team-review.md. K15 review/merge is next. No commit, push or team message was made. Times below are Asia/Rangoon; checked items have recorded evidence.

## Before kickoff

- [x] Review the supplied proposal, especially pages 7-11, 13, 15, and 18.
- [x] Create this planning workspace, shared assistant instructions, draft contract, validation plan, and source ledger.
- [x] Download and verify the official Godot Standard Windows x64 editor. Official SHA512 matches; direct executable reports 4.7.2.stable.official.ed1daf0bf. See docs/tool-setup.md.
- [x] Independently verify the CubeSat 101 sample mass criterion: Appendix C, item 6, printed page 79 / PDF page 87. Offline guide included in docs/references/.
- [x] Read and summarize the root instructions in the current Codex session; evidence is in docs/pre-kickoff-review.md.
- [x] Verify Codex and Antigravity assistant checks: the user confirmed both are successful.
- [x] Clone the user-selected team repository and integrate KE1 preparation documents at its root.
- [x] Confirm exact Godot version: the user confirmed the team uses 4.7.2; README, instructions, and setup notes now record it.
- [x] Confirm local kickoff time: the user confirmed 09:00; schedule is 14 November, 09:00 Asia/Rangoon.
- [x] With SE, agree early rendering/feature constraints if browser support should remain possible. Agreed: support Compatibility rendering (`master` sets `gl_compatibility`; verify `main` sync), GDScript-only, and early Web export check before feature freeze; see `docs/team-agreement.md`.
- [x] Complete a local technical review of the contract draft and prepare an owner-by-owner review packet; see docs/pre-kickoff-review.md.
- [x] Prepare docs/team-agreement.md for all five members, covering ownership, units, config/validation/state/events/report interfaces, decision points, and blank approval records.
- [x] Review the team agreement with SE, HPC, KE2, and KE3 and record actual decisions and approvals. All 5 roles marked `AGREE` on `v1.0-agreed` (2026-11-14 10:01 Asia/Rangoon).

## Kickoff: Saturday 14 November, 09:00-10:30

- [x] K01 - Confirm P0 and KE1 ownership; phase set to `IMPLEMENTATION` in `README.md` and `tasks.md`.
- [x] K02 - Review existing repository/config; temporary project-copy headless load passed with Godot 4.7.2 (exit 0). Compatibility rendering agreed (`master` has `gl_compatibility`; verify `main` sync) and original `project.godot` preserved.
- [x] K03 - Contract v1 frozen in `docs/team-agreement.md` (`v1.0-agreed`) and `docs/contracts.md`: IDs (`low_eq`, `high_inc`, `equator`), units (`Wh`, decimal `MB` `1000 KB = 1 MB`, `downlink_mb_per_hour`), `MissionConfig`/`ValidationResult`/`MissionStepEngine`/`MissionEvaluator` interfaces, and error shapes.
- [x] K04 - Essential-power prelaunch gate and target/orbit compatibility agreed with HPC in `docs/team-agreement.md` (`v1.0-agreed`): simplified solar-vs-baseline gate is illustrative prelaunch only; HPC enforces runtime bounds and clamps `power_save` at `0.0 Wh`.

## First KE1 delivery: by Saturday 13:00

- [x] K05 - Implemented mission/config field checks and catalog lookup, with structured errors and deterministic input-preserving results. Godot 4.7.2: 296 checks passed, 0 failed. See docs/k05-k06-progress.md.
- [x] K06 - Created 12 labeled training parts (two per category), two launchers, two profiles and agreed orbit/target vocabulary. The sample <1330 g rule keeps its source ID; all other invented values carry assumption labels. Catalog loading/validation passed the Godot suite.
- [x] K07 - Calculated all nine agreed design metrics, counted each selected part once, included launch cost and excluded launcher mass. Arithmetic is guarded; base design is 1060 g and 82 credits. See docs/k07-k08-progress.md.
- [x] K08 - Implemented all required readiness checks, independent actionable failures and fail-closed metadata handling. Uses unchanged HPC data/orbits.json from feature/hpc-simulator commit ab7865c. Godot suites: 294 + 671 checks passed, 0 failed.
- [x] K09 - Source-linked result fields verified against saved pass/fail/unevaluated cases: mass, threshold, comparator, profile/source IDs and alternative assumptions. No launch approval after any required failure. See docs/k09-k10-progress.md.
- [x] K10 - Saved valid/overweight examples and 15 manifest cases tested, including 1329/1330/1331 g, alternative profile, budget, invalid input and compatibility. New fixture suite: 470 passed; all three suites: 1435 passed, 0 failed. See tests/fixtures/README.md and docs/k09-k10-progress.md.
- [x] K11 - Prepared the local SE/HPC/KE2 handoff: public interface, units, valid/overweight/alternative configs and real result snapshots, verified source/credit, actual test logs and file hashes. Guide example and all three snapshots executed successfully; existing 1435 checks apply to unchanged inputs. See docs/ke1-handoff.md. Teammate receipt and sharing remain unconfirmed; nothing pushed or sent.

## Integration: Saturday afternoon and evening

- [x] K12 - Connected actual SE Builder/readiness screens to KE1. Button swap displays 1060 g / 82 credits -> 1380 g / 96 credits and blocks launch with the strict-limit reason. Tested stale checks, profile/budget changes and all navigation gates. See docs/k12-k13-progress.md.
- [x] K13 - Passed validated config/scenario snapshots through unchanged HPC and KE2 code into live Operations/Debrief screens. Starter: 60 steps, 4 captures, 48 MB returned, success/100. Verified retry/abort, one report per run and New Mission reset. Eight programs exit 0, 1666 counted checks plus legacy suite. Local integration complete; teammate review/export still separate.
- [x] K13a - User chose Windows first demo. Matching 4.7.2 Windows templates installed; standalone x86_64 release built with embedded data. App passes 40 scenario + 21 packaging checks in headless and real graphics modes, exit 0; user confirmed team demo approval. See docs/k13a-k14-progress.md.
- [x] K14 - Heavy camera/small launcher, unsupported/restored target and passing-mass/failing-budget scenarios passed 40 screen assertions in source and exported app. Team Windows-demo acceptance confirmed by user. Individual per-case manual signatures not claimed; see docs/k14-team-review.md.
- [ ] K15 - By 22:00, merge stable validation work and record Sunday blockers. If the loop is incomplete, use the documented reduced scope.

## Sunday: 15 November

- [ ] K16 - By 11:00, verify all KE1 acceptance scenarios in the actual player journey.
- [ ] K17 - By 14:00 feature freeze, fix clarity and integration issues; confirm source label and profile-specific rules.
- [ ] K18 - Help test the agreed delivery target: the repository currently names an offline Windows build as primary. If the team also chooses browser delivery, agree Compatibility rendering and test Web export. Ensure chosen parts persist through scene transitions and retry resets correctly.
- [ ] K19 - By 17:00 submission target, give KE2 implementation paths, tests, assumptions, sources, and AI assistance disclosure details. Team cutoff is 18:00.

## KE1 definition of done

- Each component change updates the correct metrics, with no omitted or double-counted subsystem.
- Invalid designs cannot launch and get a specific explanation with a useful correction.
- Sample 1U strict mass check is visible and credited; alternate profile rules do not inherit it accidentally.
- Budget, essential power, and launch/orbit readiness remain enforced independently of the mass verdict.
- Headless tests pass and SE/HPC consume the same config and readiness result.
- Catalog assumptions, source verification, and remaining limitations are documented.

## Work record

15 November 2026 — user-requested Communication/Weather E2E fixes: real goal scoring, truthful stopped-flight wording, Weather automatic revisits and packaged evidence/Save A support implemented locally. New suites pass 134 scoring + 132 controller checks; all five mission comparison flows pass. Original v1 evaluation is preserved. Browser verification and full-suite limitations are recorded in [the fix report](docs/reviews/new-mission-fixes-2026-11-15.md). No push, deployment or additional owner signoff is claimed. Existing personal instructions and task history are preserved.

| Task | Status/evidence | Next action |
| --- | --- | --- |
| Preparation docs | Agreed contract, implementation/test notes and K11 handoff available locally | K15 review/merge |
| Codex instructions | Root files read in this session; user confirms assistant checks successful | Complete |
| Antigravity | User confirms assistant checks successful | Complete |
| Exact editor version | User confirmed 4.7.2; docs updated | Windows templates match 4.7.2; keep teammate versions aligned |
| Repository/project shell | Existing team project cloned; main branch; engine settings preserved; 09:00 kickoff confirmed by user | Windows first demo confirmed; local export tested |
| Tool setup | Editor extracted; official checksum matches; direct version check passed; 4.7.2 confirmed | Complete: graphics, Windows templates and export verified |
| Primary mass source | Verified locally and visually: printed p.79 / PDF p.87 | KE2 confirms challenge-tab listing and exported credit |
| K01-K04 | Complete per v1.0-agreed; supporting contract and examples verified | SE handles renderer branch sync |
| K05-K06 | COMPLETE: fields/lookup and actual catalogs; updated regression suite passes 294 checks | Retained and integrated into completed readiness |
| K07-K10 | COMPLETE: totals/readiness/source fields and saved examples; 671 readiness + 470 fixture checks passed | Covered by K11 handoff |
| K11 | COMPLETE locally: docs/ke1-handoff.md, three real results, test logs, source credit and file hashes; guide example verified | Share through team workflow; receipt unconfirmed; integrated locally in K12/K13 |
| K12/K13 | COMPLETE locally: real Builder/readiness and HPC -> KE2 -> Debrief; 32 flow + 30 screen checks; six rendered screen states reviewed | Windows demo accepted in K13a/K14; optional comparison remains pending |
| K13a/K14 | COMPLETE locally: Windows export and 40 scenario/21 package checks; source 1706 plus legacy suite; team demo approval reported by user | K15 review/merge; no commit or push |
| Game code / tests / scenes | Local integrated Windows demo passes all nine source programs and standalone checks; owner calculation code preserved | Optional comparison/browser work remains separate |
