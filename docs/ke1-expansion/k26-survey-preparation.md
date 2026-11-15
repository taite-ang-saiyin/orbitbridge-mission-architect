# K26 Survey preparation and KE2 handoff

Prepared 15 November 2026, Asia/Rangoon. Base main: `dce75db845f6c494b8c25c9028dd9c0648aabd91`, confirmed as GitHub main before testing. Status: **EXAMPLES AND EVIDENCE READY; HPC CONFIRMATION, K20 AGREEMENT AND KE2 SCORING PENDING**. No receipt or owner approval is claimed.

## Simple summary

The two-region examples show the difference between taking pictures, returning some data, and fully returning an image from every region. All use actual supported v1 **Survey** inputs; no Imaging score is substituted. They pass the existing eight readiness checks and run to completion in the unchanged native engine.

The missing and partial examples both meet their overall capture/data targets but have no complete returned image from the second region. They must not receive Survey success under the proposed per-target rule. Exact partial/failure labels and scores remain KE2's decision.

## Matched complete, missing and partial examples

All three use the **same config**: Arctic Ice + Antarctic Region, high_inc, two captures, 12 MB required, three orbits, basic/standard spacecraft parts, basic radio, small launcher, sample 1U profile, 100-credit budget. Totals: 1060 g / 82 credits. This is an edited training mission, not a replacement for the stock Polar Ice preset.

Capture Arctic at pre-action step 0 and Antarctic at step 17. All unspecified steps are Power-save.

| Example | Transmission steps | Total returned | Fully returned images: Arctic / Antarctic | Evidence for proposed goal |
| --- | --- | --- | --- | --- |
| Complete | 7, 10, 20, 27 | 24 MB | 1 / 1 | Capture, MB and per-target conditions all met |
| Second region unreturned | 7, 10 | 12 MB | 1 / 0 | Capture and MB met; second entire image stays onboard |
| Second region partly returned | 7, 10, 20 | About 19.7333 MB | 1 / 0 | Capture and MB met; about 4.2667 MB of second image remains onboard |

All capture counts are 1 / 1. The partial case has about 7.7333 MB returned from Antarctic but zero complete Antarctic observations. Only draining a packet completely increments `observations_delivered_by_target`. Pooled MB or `observations_by_target` cannot replace that counter.

Evidence is bound to each run's frozen config/scenario and ordered events. The current native engine provides the target dictionaries in each trace; a missing selected-target key within those existing dictionaries means no such native count yet. Missing entire measurements in future reports must be treated as unavailable, not invented as zero. Transmissions drain packets in capture order; an independent check reconstructed these deliveries from the actual Observe/Transmit events.

## Existing stock preset finding: a design shortfall

The stock single-target Polar Ice config is copied **unchanged**: five Arctic captures, 60 MB, six orbits and the original basic radio/design. A tested schedule captures at 0/7/10/17/20 and transmits at 27/30/37/40/47/50/57. It completes all five captures but returns only about **54.1333 MB** (four complete images and part of the fifth).

This is a bound for the current stock design, not merely a poor policy: all Arctic capture windows coincide with the two contact steps per orbit. Six orbits provide twelve contact opportunities. Five captures consume five of them; at most seven remain for transmission. The basic radio returns at most about 7.7333 MB per step, so seven steps cannot return the requested 60 MB. The engine permits one action per step and starts with an empty data buffer.

A separately tested design variant changes **only radio_basic to radio_fast**. Same five captures and mission requirements; transmissions at 27/30/37/40 return the full **60 MB / five complete images**. It passes readiness at **1120 g / 89 credits**. This is an available redesign example, not a change to the stock registry or preset. HPC/KE2 should decide whether the starter intentionally teaches redesign or whether authored defaults/windows/duration should change. No such decision is assumed here.

## Files supplied

- [Example/config index](examples/k26-survey/README.md).
- [Exact schedules and measured expectations](examples/k26-survey/plans.json).
- [Proposed semantic handoff](examples/k26-survey/handoff-expectations.proposed.json), with no invented score/report.
- [Reusable native audit](tools/check_survey_delivery_examples.gd).
- [Measured summary](evidence/k26-survey/summary.json), five full native trace files in that folder, and [independent integrity record](evidence/k26-survey/integrity.json).

The v2 counterpart retains draft-2 nested goals and preset lineage solely for K20 discussion. The production validator still rejects it. Its edited-mission identity and v2 rollout remain subject to the current review, with no new preset or contract ratification.

## Checks executed in this task

Godot 4.7.2: **95 checks passed, 0 failed, five native Survey traces**. Checks cover readiness, exact per-target captures/returned MB/full deliveries, resource bounds, frozen configs, unchanged inputs, deterministic replay and the existing Survey evaluation guard. Independent trace inspection verifies same-run unique events, native windows, ordered steps, FIFO packet delivery, total conservation and the stock opportunity bound.

All five terminal runs still receive the actual KE2 error `INVALID_EVALUATION_INPUT` at `config.mission.objective`: Survey scoring is not implemented at this baseline. No official numeric score, success/partial report or A/B outcome is fabricated. The maintained full suite, browser export and public Netlify site were not tested in this preparation.

Repeat from the project root after Godot import, writing results outside tracked source:

```powershell
$godotExe = '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe'
$surveyExamples = Join-Path (Get-Location) 'docs\ke1-expansion\examples\k26-survey'
$surveyOutput = Join-Path $env:TEMP 'orbitbridge-k26-survey'
& $godotExe --headless --path . --script docs/ke1-expansion/tools/check_survey_delivery_examples.gd -- $surveyExamples $surveyOutput
```

## Pending decisions and owner handoff

| Owner | Next confirmation/work |
| --- | --- |
| HPC | Confirm current packet counters/FIFO/target windows and pre-action timing; review stock shortfall and intended design challenge. |
| KE2 | Implement Survey outcomes using complete per-target delivery plus retained capture/MB requirements; decide partial/failed/score/report rules; use these positive and negative traces as cases. |
| KE1 + SE + affected owners | Finish K20 bounds/capability/identity/version decisions and coordinate v2 mapping; do not reinterpret a title or remove goal fields. |
| SE/KE3 | Display per-target completion and evaluation unavailable status correctly; integrate after agreed producer/scorer support. |

K26 remains unchecked as **PREPARATION READY, OWNER/SCORER ACCEPTANCE PENDING**. The simulator, evaluator, validator, catalogs, presets, UI, exports and signed agreements are unchanged. Personal planning files are retained. Nothing was committed, pushed, deployed or sent to teammates.
