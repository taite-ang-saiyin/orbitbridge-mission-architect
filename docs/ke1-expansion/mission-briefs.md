# Five mission briefs

These are short educational briefs for K29/SE/KE3, not implemented screen text. Keep actual source links in the Sources view and distinguish authored scenarios from measurements.

| Preset | Player purpose | Engineering lesson | Scope limit |
| --- | --- | --- | --- |
| Estuary Watch - existing | Collect useful coastal observations and return them to Earth | Imaging load, downlink opportunities, battery/storage and budget interact | Authored Coastal Region windows; not a flood-warning or real coverage service |
| Tropical Forest Watch - existing | Gather repeat imagery of a tropical region and send it home | A reachable target still needs enough data capacity and communication | No real deforestation detection is computed |
| Polar Ice Survey - existing | Return complete observations from every selected Survey target | Taking an image is different from successfully delivering it | Regional training scenario, not global mapping; scoring must be added by KE2 |
| Communication - new | Deliver test data over at least two distinct positive contact steps | Ground access, radio rate, payload availability and power affect delivery | Existing Observe creates test payload; no real RF/link-budget model |
| Weather Monitoring - new | Observe one selected region on different orbits and return enough data | Timing and revisit goals can require a different operation plan | Repeat observation only; no forecast, atmospheric sensor or live weather feed |

Proposed new-mission targets: 2 qualifying contacts/visits plus 12 MB over 3 orbits. Existing preset defaults stay intact until a tested change is agreed. Source ideas: NASA Mission Design Lab for comparing designs; NASA Build It Yourself for connecting science goals to engineering choices. See resources.md.

Suggested debrief pattern: actual goal progress -> supporting events -> remaining shortfall -> one next experiment. An explanation about a missed contact needs a corresponding missed/failed contact event; do not derive it from low returned MB alone.


## Current goal wording

Use [copy candidate 2](k29-mission-wording-preparation.md) for implementation. The non-HPC rules are agreed; HPC confirmation remains. Weather uses accepted captures in distinct revolutions plus pooled returned MB, with no complete-delivery-per-visit requirement. Communication counts positive transmission steps, including two in one window. Its and Weather's capture quotas are not extra success conditions. Earlier suggested values are contextual; final numeric labels always read the frozen config.
