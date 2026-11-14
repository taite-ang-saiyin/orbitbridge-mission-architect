# KE1 tasks

Phase: IMPLEMENTATION - `docs/team-agreement.md` (`v1.0-agreed`) is agreed and `K01`–`K11` are complete locally; the SE/HPC/KE2 package is in docs/ke1-handoff.md with verified examples, source details and 1435 passing checks. Teammate receipt is not confirmed; no push or message was made. `K12` Builder integration with SE is next. Dates and milestones below come from the team proposal; times are Asia/Rangoon. A checked item means completed with evidence, not merely planned.

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

- [ ] K12 - Integrate Builder metrics and launch blocking with SE; swap a component and verify the displayed totals and explanation.
- [ ] K13 - By 16:30, pass a validated config into HPC's simulation and through KE2's evaluation to the result screen.
- [ ] K13a - At the first working slice, choose the demo format with the team and run a small export test. Leave time to fix export issues before Sunday feature freeze.
- [ ] K14 - Run heavy-camera/small-launcher, target-change, and passing-mass-but-failing-budget scenarios with the team.
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

| Task | Status/evidence | Next action |
| --- | --- | --- |
| Preparation docs | Agreed contract, implementation/test notes and K11 handoff available locally | K12 Builder integration with SE |
| Codex instructions | Root files read in this session; user confirms assistant checks successful | Complete |
| Antigravity | User confirms assistant checks successful | Complete |
| Exact editor version | User confirmed 4.7.2; docs updated | Match export templates and teammate versions |
| Repository/project shell | Existing team project cloned; main branch; engine settings preserved; 09:00 kickoff confirmed by user | Confirm delivery target with SE |
| Tool setup | Editor extracted; official checksum matches; direct version check passed; 4.7.2 confirmed | Graphical check and matching export templates |
| Primary mass source | Verified locally and visually: printed p.79 / PDF p.87 | KE2 confirms challenge-tab listing and exported credit |
| K01-K04 | Complete per v1.0-agreed; supporting contract and examples verified | SE handles renderer branch sync |
| K05-K06 | COMPLETE: fields/lookup and actual catalogs; updated regression suite passes 294 checks | Retained and integrated into completed readiness |
| K07-K10 | COMPLETE: totals/readiness/source fields and saved examples; 671 readiness + 470 fixture checks passed | Covered by K11 handoff |
| K11 | COMPLETE locally: docs/ke1-handoff.md, three real results, test logs, source credit and file hashes; guide example verified | Share through team workflow; receipt unconfirmed; K12 with SE |
| Game code / tests / scenes | Complete KE1 readiness validation implemented; HPC orbit data imported unchanged; three suites pass 1435 checks total | K12 screen integration; runtime operations/screens not merged |
