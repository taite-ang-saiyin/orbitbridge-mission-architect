# Four-owner integration review

Prepared on 15 November 2026, Asia/Rangoon. KE2 assembled and tested the supplied branches in `exports/team-alignment-20261115`. Expanded scoring uses an explicit preview entry point and retains proposal status under the user's instruction.

## Pinned sources

| Owner | Branch | Tested commit |
| --- | --- | --- |
| KE1 | `ke1-expand` | `cd5b863dc0502bb931948eb7a0ff6e56e4f8f5c3` |
| KE3 | `ke3/v2-se-integration` | `274990e8eeadc4d42378b48c3adee181258997f3` |
| SE | `se` | `0d9e275fc270630c74324f29c11281f9883909a2` |
| HPC | `feature/hpc-ke3-goal-evidence-v1` | `61a2772acbb55a069d4472079611fcdb91c43960` |
| KE2 | `features/KE2` plus current local implementation | Base `cb458c7d9c9b3b2484e8111dbbec4ea1468f51b8`, with payload hashes in the manifest |

KE3 already includes the SE implementation. That tree is the base. KE1's core validation, registry, capabilities, tests and handoff documents are overlaid next. HPC contributes the native adapter, step engine and whole-run simulator. KE2 contributes its evaluator, evidence, feedback, records and comparison modules. Resolved cross-owner files and tests are supplied as patches and exact payload files.

The `files/.gdignore` marker keeps the review payload outside the parent project's Godot resource scan. Keep it with the package so copied `class_name` declarations remain scoped to the assembled review project. `assemble.py` verifies and copies the listed payload files into that project's normal runtime paths.

The Windows checkout has an existing `origin/KE3` reference that conflicts with `origin/ke3/v2-se-integration`. KE3 was fetched into `refs/remotes/team-alignment/ke3-v2-se-integration`. The existing reference was retained.

## Resolved interfaces

| Boundary | Tested behavior |
| --- | --- |
| KE1 to native simulation | Exact `expansion-goals-v2-agreed-1` configs for all five presets, with frozen `mission_v2` registry/capability context and original physical catalogs |
| HPC validation | The same pure KE1 shape/reference rules govern v2 initialization and subsequent step context. One common physical resolver consumes each original config envelope. Scenario snapshots retain the full capability/catalog context |
| Native counts | Communication counts positive accepted transmit steps. Weather counts distinct selected-target revolutions. Imaging captures and Survey complete-target coverage retain their separate native counters |
| SE evaluation | An optional evaluator callable supplies KE2's 19-field report and bound readiness credits. `enable_expansion_candidate()` installs the local review providers explicitly |
| SE storage to KE2 comparison | The new provider verifies SE packet digests, original execution keys, reports, readiness and frame identity, then derives initial/accepted-step resource samples. Requested plans and manual overrides remain distinct from accepted outcomes |
| KE3 goals | Bound `goal_progress` rows drive the actual display, preserving supplied actuals, ratios and verdicts. Survey per-target details and zero/unavailable handling are retained |
| KE3 comparison | Supplied count and delta rows use captures for Imaging, delivered targets for Survey, positive steps for Communication and revolutions for Weather. Wh, percentage-point, MB, mass and credit measures retain units |
| Portable saved A | Report revision metadata is retained outside the 19-field report. Original execution bytes and content digests survive JSON transport |
| Player flow | Authored cards feed the exact KE1 configs through Creator acknowledgement, Builder, readiness, Operations, Debrief, Save A, fresh B and visible comparison |

The six earlier HPC integration issues have concrete resolutions in this checkout. Its alternate config aliases are replaced by the published KE1 fields, KE1's strict validator handles positive goals, and KE2's provider derives counts from events. HPC's overlapping evaluator edit is reconciled through the KE2 implementation. Simulator tests now use the authored preset and separately verify a four-capture over-target run. SE's existing source-version snapshot is extended with evaluator and validator dependency inventories.

## Actual verification

All **62 distinct check programs** passed against the resolved source, including the 46 maintained programs, eight KE1 expansion programs, two HPC v2 programs, four KE2 regressions and two new integration programs. The maintained runner completed successfully, and the additional programs were run individually. The supplied combined runner reproduces their union.

- Five complete card-to-comparison journeys pass **364 checks** using real native-v2 modules and headless controls. Checks include selected execution binding, duplicate publication, preservation of A, fresh B identity, visible goal/count cells, scoped credits, portable records and report-packet mutation rejection.
- Twelve additional native goal controls pass **51 checks**, covering feasible completion, isolated count/delivery shortfall, all-five-preset zero progress, abort after meeting goals, and missing delivery maps. These use the exact agreed config shapes and real readiness/simulation APIs.
- The KE2 candidate suite passes **706 checks**. The existing evaluator passes **294**, with its five original pending declarations still printed. Independent algorithms pass 125, callable v1 comparison 34 and actual Imaging-card checks 53.
- KE1's agreed v2 validator passes 373 checks. Its other expansion programs pass 70, 466, 83, 327, 97, 636 and 711. The maintained SE/KE3 suites cover their original controls alongside the new goal/record checks.

| Preset | A in the actual UI journey | Fast-radio B under the saved requested plan |
| --- | --- | --- |
| Estuary Watch | Success, 100 | Success, 100 |
| Tropical Forest Watch | Partial, 87 | Success, 100 |
| Polar Ice Survey | Partial, 97 | Success, 100 |
| Communication | Success, 100 | Success, 100 |
| Weather Monitoring | Partial, 75 | Partial, 75 |

Weather's unchanged timing covers one revolution in that design comparison. Its separate real-v2 control observes at steps 1 and 11 and reaches success/100. Communication's same-config shortfall returns 12 MB in one positive step for proposed score 75, compared with 24 MB across two steps for 100. Two-target Survey controls produce proposed 83 with a partial second packet and 100 after both targets receive complete deliveries. Over-target raw counts remain uncapped.

The verification JSON contains execution keys, reports, comparisons and per-program log hashes. The bundle retains full native goal-control inputs/states and the mission-journey results. [Verification](verification.json), [review bundle](../evidence/ke2-team-alignment.zip)

## Rebuild and rerun

Run from `D:\orbitbridge-mission-architect` in PowerShell. The pinned Git objects must be available locally. Fetch commands for the supplied branches are shown below.

```powershell
git fetch --no-tags origin ke1-expand se feature/hpc-ke3-goal-evidence-v1
git fetch --no-tags --refmap= origin refs/heads/ke3/v2-se-integration:refs/remotes/team-alignment/ke3-v2-se-integration
python .\docs\expansion-plan\team-alignment\assemble.py
$orbitGodot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $orbitGodot --version
& $orbitGodot --headless --editor --path D:/orbitbridge-mission-architect/exports/team-alignment-20261115 --log-file D:/orbitbridge-mission-architect/exports/check-logs/team-alignment-import.log --import
powershell -NoProfile -ExecutionPolicy Bypass -File .\docs\expansion-plan\team-alignment\run_checks.ps1 -GodotExe $orbitGodot
# Open the explicit local expansion preview:
& $orbitGodot --path D:/orbitbridge-mission-architect/exports/team-alignment-20261115 --script res://tests/team_alignment_preview.gd
git diff --check
```

`assemble.py` writes only inside the repository's `exports` directory and verifies every payload hash. Godot is verified as `4.7.2.stable.mono.official.ed1daf0bf`. The new runner fails on script errors even when Godot exits 0. The full journey program has a longer timeout than the small regression programs.

The review bundle can be extracted independently. Its `team-alignment/assemble.py --repo D:\orbitbridge-mission-architect` uses the repository's pinned Git objects and the bundled payload. Supply the extracted `run_checks.ps1` with an explicit `-ProjectPath` when it is outside the repository docs directory.

## Owner review and adoption

- [x] Fetch and pin all four owner branches, with prior local edits preserved.
- [x] Reconcile and test a combined native-v2 implementation for all five presets.
- [x] Finish KE2's agreed-input support, opt-in SE packet provider and comparison mapping.
- [x] Verify native goal controls, visible saved A/B widgets, credits and portable records.
- [x] Prepare per-owner patches, exact resolved files, reproducible assembly and check commands.
- [ ] Owners review/adopt the shared-file patches in their integration branch.
- [ ] Confirm the expanded scoring rollout. The user's instruction keeps the implemented weights proposed and explicitly enabled for this review build.
- [ ] SE verifies Windows/Web exports and the deployed revision. KE3/SE verify the actual public-browser journey.
- [ ] Reconcile the original evaluator pending declarations against the adopted runtime. The combined checkout now supplies T07/T08 and publication/retry evidence. Exact Builder mass-boundary declarations remain under KE1/SE review.

Review `hpc.patch` for adapter/state and native tests, `se.patch` for context propagation/provider/portable records and Creator, `ke3.patch` for goal/count presentation and current UI expectations, and `ke1.patch` for native-acceptance test updates. The manifest pins their source commits and full resolved payload. [Manifest](manifest.json)

The cross-owner corrections were prepared as a local review implementation. Remaining release work concerns patch adoption, scoring rollout and exported/browser acceptance. The tested source is reproducible without regenerating historical execution keys.
