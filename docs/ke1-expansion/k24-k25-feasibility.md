# K24/K25: Communication and Weather feasibility

Date: 15 November 2026, Asia/Rangoon. Tested main: `dce75db845f6c494b8c25c9028dd9c0648aabd91`, also confirmed as GitHub main before this work.

**Local feasibility work is ready. HPC confirmation and K20 agreement remain pending.** No production objective, policy, scoring rule, interface, UI card or shared agreement was changed. Nothing was committed, pushed, deployed or sent to teammates.

## Simple summary

Communication can send data on at least two separate steps and return at least 12 MB with the current training hardware. Both KE1's two-packet setup and KE2's one-packet example have working action sequences.

Weather can observe the same region in two different orbits. The player must wait before taking the second picture. Both current automatic policies take both pictures in the first orbit, so they do not meet the proposed repeat-visit goal.

These results use supported version-1 **Imaging training inputs** to exercise existing physics and events. They do not enable Communication/Weather or award official scores. The new goals remain draft requirements under [K20](k20-interface-review.md).

## K24: Communication evidence

| Trial | Captures | Positive transmission steps | Returned data | Proposed 2-contact / 12-MB result |
| --- | --- | --- | --- | --- |
| KE1 candidate hardware: high_inc, basic radio, two packets | 1, 6 | 7, 10, 17, 20 | 24 MB | Both requirements met |
| KE2 example hardware: low_eq, basic radio, one packet | 2 | 8, 18 | 12 MB | Both requirements met |
| One packet with fast radio on high_inc | 1 | 7 | 12 MB | Data met; only one positive contact |

All steps above are **zero-based pre-action** indices. All trials use the registered `equator` target, three orbits and a 100-credit budget. Default hardware is 1060 g / 82 credits. The fast-radio control is 1120 g / 89 credits. Every configuration passes all eight existing readiness checks.

The basic radio rate is 48 MB/hour. One low_eq step lasts 0.1538888889 hours, so a 12-MB packet is split across steps 8 and 18 (approximately 7.3867 MB then 4.6133 MB). One capture can therefore supply two positive contacts. This independently supports the physical feasibility of KE2's example; its proposed fields/objective are still rejected by the current validator.

With a fast radio, that same 12-MB packet fits in one transmission. A faster part alone does not guarantee more positive contacts. Payload supply and operating plan must be checked with the final mission defaults.

Rejected tests include repeated empty-buffer attempts at step 0, repeated off-window attempts at step 2, and later attempts after the buffer is empty. They preserve time/resources, emit `action_blocked`, return no data and add no contact count. A separate 24-MB-threshold control gets two positive contacts but only about 15.4667 MB: meeting the count does not satisfy an independent data threshold.

## K25: Weather evidence

| Trial | Selected-target capture steps | Distinct orbit indices | Returned data | Proposed 2-visit / 12-MB result |
| --- | --- | --- | --- | --- |
| Explicit minimum-return revisit plan | 1, 11 | 0, 1 | About 15.4667 MB | Both requirements met |
| Explicit complete-return revisit variant | 1, 11 | 0, 1 | 24 MB | Both met; both packets fully delivered |
| Two pictures in the first orbit | 1, 6 | 0 | 24 MB | Data met; visit goal missed |
| Actual runtime Observe First | 1, 6 | 0 | 24 MB | Data met; visit goal missed |
| Actual runtime Downlink First | 1, 6 | 0 | 24 MB | Data met; visit goal missed |
| Revisit without transmission | 1, 11 | 0, 1 | 0 MB | Visits met; data goal missed |

The repeat-visit plan uses high_inc and `equator`. Capture at steps 1 and 11, transmit at 7 and 17, and power-save on all other steps. The complete-return variant also transmits at 10 and 20; it returns both 12-MB packets completely. This latter variant is a useful stronger demo candidate for HPC review.

The minimum-return plan meets the draft's aggregate 12-MB threshold, but does **not** fully return both observations. K20 currently requires accepted captures across two orbits plus returned MB; it does not require a complete delivered packet for every orbit. If the owners choose that stronger rule, use and retest the complete-return variant.

An additional two-target legacy Imaging control captures Equator in orbit 0 and Tropical Forest in orbit 1. Only the Equator capture counts for an Equator revisit goal. This is a negative evidence-filtering control, not a proposed two-target Weather preset.

No production visit-aware policy was added. HPC can adopt the tested explicit sequence or implement an agreed policy after review. A two-capture quota is retained: it is never reinterpreted as an orbit count.

## How the evidence was measured

- Runs start through `MissionStepEngine.init_validated_run` using `MissionRuntime.load_game_catalogs()`, including its target/window extensions. The two automatic controls use the real `MissionRuntime.launch` path.
- Count only `action_accepted` events from the same run. Positive contact steps require `action == transmit` and `delta_returned_data_mb > 0`.
- Weather observations must match the selected `target_id`. Derive `floor(step_index / steps_per_orbit)` from the run's frozen scenario. Do not divide by a hard-coded 10 or use the post-action state index.
- Deduplicate accepted steps within each run. Repeated events and events from another run do not increase totals.
- Event totals agree with final-state capture/data totals. Inputs and shared catalogs remain unchanged; step resources remain within battery/storage limits; explicit plans replay identically. Automatic controls reproduce physics while receiving fresh run identities.
- This extraction is a documentation audit. KE2 still owns production event validation, scoring, partial outcomes and report binding. Real contact and target windows are authored educational assumptions, not orbital coverage predictions or weather forecasts.

## Files and checks

- [Runnable audit](tools/check_contact_revisit.gd).
- [Exact action plans and expected controls](examples/k24-k25-action-plans.json).
- [Measured summary](evidence/k24-k25/summary.json), with links by filename to eleven raw run traces in the same folder. Each trace includes its config, frozen scenario, real ordered events, blocked attempts, resource samples and final state.
- [Independent trace-integrity check and source hashes](evidence/k24-k25/trace-integrity.json).

Godot 4.7.2 ran the audit: **1,740 checks passed, 0 failed, 11 traces**. Three existing programs also passed: `tests/test_hpc.gd` (48 checks), `tests/test_simulator.gd`, and `tests/prediction_multitarget_smoke.gd` (all four Imaging/Survey and low_eq/high_inc combinations). These were executed during this task. The full maintained suite, browser export and public Netlify site were not tested in this task.

Reproduce from the project root after Godot import; choose an output folder outside tracked source:

```powershell
$godotExe = '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe'
$auditOutput = Join-Path $env:TEMP 'orbitbridge-k24-k25-audit'
& $godotExe --headless --path . --script docs/ke1-expansion/tools/check_contact_revisit.gd -- $auditOutput
```

Inspect the generated `summary.json`: `failed` must be zero and all eleven cases must be present. Missing thresholds or a pending official score must never be displayed as a passing production mission.

## Decisions still needed from the owners

| Owner | Confirmation needed |
| --- | --- |
| HPC | Accept pre-action event/orbit semantics and the chosen contact/revisit schedule; choose production policy and final target/orbit/capture defaults. |
| KE1 + KE2 + SE + HPC | Resolve K20's version/field shape and preset identity. This audit does not choose between the two schema proposals. |
| KE2 | Implement count-plus-data evaluation and report evidence; preserve separate capture/contact/visit meanings and define partial results. |
| SE + KE3 | Wire the accepted goals and policy into frozen configs, playable cards, progress, Results and comparison storage after coordinated implementation. |

K24 and K25 remain unchecked as **EVIDENCE READY, HPC CONFIRMATION PENDING**. The user's reported KE3 review supports K20's direction; it is not HPC acceptance or finished integration approval. Existing candidate definitions, signed contracts, export work and personal planning files are preserved.
