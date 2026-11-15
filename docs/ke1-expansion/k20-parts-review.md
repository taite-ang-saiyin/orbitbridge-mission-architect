# K20 selectable parts and proposed capabilities

Review revision: `k20-review-additions-1`. Owner review only. Physical IDs/values below come from current main dce75db catalogs; new-objective capability is proposed. See [validation rules](k20-validation-review.md). No physical catalog or runtime registration is changed.

## Required design slots and current IDs

Exactly one registered ID per slot; no extra design keys. Known parts in a different slot are rejected. All mass/cost values are illustrative gameplay parameters.

| Required field | Existing selectable IDs | Important current values |
| --- | --- | --- |
| bus_id | bus_basic; bus_light | 300 g / 12 credits / 2 W baseline; 220 g / 20 credits / 1.2 W |
| instrument_id | instrument_basic; instrument_advanced | 180 g / 16 credits / 12 MB per capture; 500 g / 30 credits / 24 MB |
| solar_id | solar_standard; solar_large | 160 g / 10 credits / 3 W; 280 g / 17 credits / 6 W |
| battery_id | battery_standard; battery_large | 250 g / 14 credits / 25 Wh; 450 g / 24 credits / 50 Wh; both start fully charged |
| radio_id | radio_basic; radio_fast | 120 g / 8 credits / 48 MB/hour / 3 W transmit; 180 g / 15 credits / 120 MB/hour / 6 W |
| storage_id | storage_standard; storage_large | 50 g / 7 credits / 64 MB; 100 g / 12 credits / 256 MB |
| launch_profile_id | cubesat_1u_sample; illustrative_alternative | Strict <1330 g sample; illustrative <=5000 g alternative |
| launcher_id | small; medium | 15 credits: sample profile only, capacity 2000 g low_eq / 1500 g high_inc; 35 credits: both profiles, 6000 g / 5000 g |
| orbit_id | low_eq; high_inc | Registered HPC source orbits; target/window suitability still required |

Current effective targets: equator, tropical_forest, equatorial_ocean, coastal_region, temperate_land, arctic_ice, antarctic_region. Use runtime-extended HPC windows, not latitude/graphics guesses. Initial Communication and Weather candidates use equator/high_inc; their allowed target count is proposed as one. All profiles currently list both source orbits, but launcher/profile compatibility still differs.

## Instrument capability review

| Objective | Current actual registration | Proposed training support after agreement |
| --- | --- | --- |
| imaging | Both instruments list Imaging in components.json | Both existing instruments |
| survey | MissionRuntime adds Survey to both instruments in memory | Both, with actual complete-per-target delivery scoring from KE2 |
| communication | Neither registered; no working production path | Both as test-packet sources, subject to explicit owner approval |
| weather_monitoring | Neither registered; no working production path | Both for repeat imagery of a selected region, subject to explicit owner approval |

Non-instrument parts have no separate objective restriction proposed; they must be in the correct slot and pass all physical/capacity checks. The capability table does not bypass validation, authorize a new objective or guarantee success. Catalog capability source (base JSON vs reviewed runtime extension), exact unsupported-objective wording and rollout remain pending KE1/HPC/SE agreement.

Both radios remain selectable candidates for Communication, not just the starter's fast radio. One packet may need multiple basic-radio steps but fit in one fast-radio step. Changing instrument packet size, capture supply, storage or actions can change contact counts. Do not label the fast radio universally better.

## Stock examples and limitations

- Communication candidate revision 2: basic instrument, fast radio, remaining basic/standard parts, small launcher and sample profile: 1120 g / 89 credits. Two captures generate 24 MB.
- Weather candidate revision 1: basic instrument/radio and remaining stock parts: 1060 g / 82 credits. Its fully delivered visit requirement is undecided, even though a complete-return action sequence is available.
- Advanced instrument substituted into otherwise basic Imaging hardware: 1380 g, failing the strict sample mass check. Selectability is not readiness.
- Advanced Imaging example with bus_light and otherwise basic/standard parts: 1300 g / 104 credits, requiring its example's 120-credit budget. It illustrates that the advanced instrument is not categorically prohibited.

Bus mass excludes the separately selected parts. Launcher mass is not spacecraft mass; its price is included in total credits. Essential power remains the existing illustrative static gate (positive battery/initial energy and solar output >= bus baseline); actual action energy/storage and science outcomes are simulated separately. Weather is repeat observation, not atmospheric forecasting; Communication is data-return training, not an RF link-budget calculation.

The existing sample mass source/locator remains in docs/sources.md and launch_profiles.json. This review makes no new external scientific claim and leaves the signed source rule unchanged.
