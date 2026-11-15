# K23 preparation: five-mission readiness report

Prepared 15 November 2026, Asia/Rangoon. Report revision: `k23-five-mission-readiness-1`. **All five candidates pass the recorded draft and physical checks. All v2 launch approvals remain pending.**

This report reuses existing results; **no game tests were rerun**. It changes no preset, part value, code, launch gate, score or approval. Existing v1 behavior remains unchanged, including the original three cards. Physical readiness does not establish completed mission success.

## Recorded checks and physical totals

| Mission | Draft fields/IDs/goals | Physical gates | Mass | Parts + launch cost | V2 launch approval |
| --- | --- | --- | --- | --- | --- |
| Estuary Watch | Pass under proposal | 8/8 pass | 1060 g | 82 credits | Pending; checker returns false |
| Tropical Forest Watch | Pass under proposal | 8/8 pass | 1060 g | 82 credits | Pending; checker returns false |
| Polar Ice Survey | Pass under proposal | 8/8 pass | 1060 g | 82 credits | Pending; checker returns false |
| Communication | Pass under proposal | 8/8 pass | 1120 g | 89 credits | Pending; checker returns false |
| Weather Monitoring | Pass under proposal | 8/8 pass | 1060 g | 82 credits | Pending; checker returns false |

The checks cover fields, registered selections, profile mass, launcher capacity, budget, launch/orbit compatibility, target opportunities and essential power. The selected sample profile uses strict mass <1330 g; current catalog values are illustrative training values. These are proposed-v2 review results and existing physical checks, not final capability approval or flight certification.

All setups use bus_basic, instrument_basic, solar_standard, battery_standard, storage_standard, launcher small and cubesat_1u_sample. Communication uses radio_fast (120 MB/hour); the other four use radio_basic (48 MB/hour). Shared physical metrics are 2 W baseline, 3 W solar output, 25 Wh battery/initial energy, 64 MB storage and 12 MB per capture. New Communication/Weather capability is still proposed; their physical check uses a private supported v1 Imaging surrogate. No new capability is registered by this report.

## Exact preserved candidate settings

| Preset ID / revision | Objective / goal | Target | Orbit | Captures / returned MB | Orbits / budget |
| --- | --- | --- | --- | --- | --- |
| estuary_watch / 1 | imaging / imaging | coastal_region | high_inc | 5 / 60 MB | 6 / 100 credits |
| tropical_forest_watch / 1 | imaging / imaging | tropical_forest | low_eq | 5 / 60 MB | 6 / 100 credits |
| polar_ice_survey / 1 | survey / survey_delivery: one complete observation per selected target, plus retained overall goals | arctic_ice | high_inc | 5 / 60 MB | 6 / 100 credits |
| communication / 2 | communication / communication_contacts: two positive transmission steps | equator | high_inc | 2 / 12 MB | 3 / 100 credits |
| weather_monitoring / 1 | weather_monitoring / weather_revisit: two distinct orbit visits; delivery meaning pending | equator | high_inc | 2 / 12 MB | 3 / 100 credits |

All five current presets select one target. Survey's separate two-target training examples are not additional authored presets. Root config contract is `expansion-goals-v2-draft-2`, registry is `five-presets-candidate-2`, and checker is `k22-v2-review-1`. The original three v1 configs are preserved exactly; Communication retains its KE2-supported fast-radio candidate setting. No custom/edit identity decision is inferred.

## Runtime support and goal evidence

| Mission | Existing support and reused evidence | Missing support or limitation |
| --- | --- | --- |
| Estuary Watch | Existing v1 Imaging setup/scoring retained; exact draft config and stock metrics match recorded input | This readiness evidence does not establish a completed run for this exact stock preset; v2 migration/approval is pending |
| Tropical Forest Watch | Existing v1 Imaging setup/scoring retained; exact draft config and stock metrics match recorded input | This readiness evidence does not establish a completed run for this exact stock preset; v2 migration/approval is pending |
| Polar Ice Survey | Existing v1 Survey setup/simulation retained; K26 records five captures but only about 54.1333 MB for the basic-radio stock design | Current Survey evaluation is unavailable; stock design falls short of 60 MB under its shared capture/contact windows. A separate fast-radio design returns 60 MB; defaults are unchanged |
| Communication | Candidate-derived v1 physical/action evidence returns 24 MB in positive steps 7 and 10 with the fast radio | Production objective/catalog/mapping/launch/evaluator integration is absent. Contact-step/window meaning and owner acceptance remain pending |
| Weather Monitoring | Recorded manual two-orbit plans return 24 MB completely, or only 12 MB from the first image while the second remains onboard | W1 capture/delivery meaning is unresolved; current Observe First and Downlink First policies take both captures in one orbit. Production goal/scoring/launch integration is absent |

No new Communication, Weather or Survey score is claimed. The existing K27 Imaging A/B reports concern a separate controlled training mission and do not prove success of these five exact stock configs. The launch flag in every recorded v2 review is false. Passing a physical target-opportunity check says windows exist; it does not prove enough useful actions or complete data delivery within the mission.

## Evidence reused and report verification

The report uses K22's recorded **466 draft checks and 2,019 checks across six programs, zero failures**. Those are earlier executed results, not new runs in this task. It cross-checks all five metrics with the earlier 70-check candidate-2 catalog evidence and uses existing K24/K26/fast-radio/Weather traces only for their stated action/outcome facts.

For this report, stored evidence/source hashes were verified, each full candidate config was matched to its recorded fixture input, all eight statuses and both metrics were checked, original v1 settings were compared, and current physical/runtime inputs were matched to the recorded main baseline. This is report consistency/provenance checking, not a rerun of the game. Existing test records, source files and shared packets remain unchanged.

Machine-readable snapshots, gate outputs, metrics, blockers and source hashes are in [readiness-report.json](evidence/k23-readiness/readiness-report.json).

Source records:

- [Candidate registry](../../data/mission_presets.json).
- [K22 recorded results](evidence/k22-draft/v2-draft-check.json) and [verification](evidence/k22-draft/verification.json).
- [Candidate-2 physical results](evidence/ke2-draft-2/mission-presets-check.json).
- [Exact Communication starter evidence](evidence/ke2-draft-2/communication-fast-radio-check.json).
- [Survey evidence](evidence/k26-survey/summary.json).
- [Weather delivery alternatives](evidence/k20-review-additions/physical-qa.json) and [automatic-policy evidence](evidence/k24-k25/summary.json).

Base main is `dce75db845f6c494b8c25c9028dd9c0648aabd91`. Newer owner patches or source/catalog changes require their own integration checks; this report cannot approve them from older evidence. The report JSON is evidence, not a runtime preset catalog or launch authorization.

## Blockers and next owners

- K20: exact rules, Weather delivery, transmission steps versus windows, custom/edit identity and capability registration still need final agreement.
- HPC: confirm evidence, windows/policy choices, event/orbit/packet meanings, resource samples and versions; review the stock Survey design shortfall.
- KE2: provide coordinated Survey/Communication/Weather evaluation, partial outcomes, reports and comparison rules.
- SE/HPC/KE1: integrate agreed live v2 validation/config propagation, frozen mission review, adapter acceptance, launch/storage and guards.
- KE3: integrate the confirmed progress/result definitions and execution-bound reports, then complete owner acceptance.

K23 remains unchecked as **REPORT PREPARATION READY, LIVE FIVE-MISSION ACCEPTANCE PENDING**. Existing v1 flows are not disabled or reapproved here. Personal planning files are preserved. Nothing was committed, pushed, deployed or sent to teammates.
