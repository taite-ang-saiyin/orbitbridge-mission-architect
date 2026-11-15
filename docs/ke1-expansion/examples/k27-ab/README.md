# K27 matched radio pair

Actual supported v1 Imaging configs for a fixed experiment. This is an edited training mission, not a new authored preset. K20 and expanded five-goal comparison remain pending.

| File | Purpose |
| --- | --- |
| [design-a.v1.json](design-a.v1.json) | Basic-radio design: 1060 g / 82 credits |
| [design-b.v1.json](design-b.v1.json) | Only radio_id changes to fast: 1120 g / 89 credits |
| [action-plan.json](action-plan.json) | Identical accepted 30-step operation sequence for both radios |
| [matching-policy.proposed.json](matching-policy.proposed.json) | Comparison matching proposal; not implemented runtime logic |
| [matching-cases.proposed.json](matching-cases.proposed.json) | Cases for owner review: goal/budget/orbit/version/history changes, reused run IDs and unavailable scores |

Both have two captures/24 MB/three orbits/100 credits and equator/high_inc. Observe 1/6; transmit 7/10; Power-save otherwise. The basic radio returns about 15.4667 MB; the fast radio returns 24 MB. Both transmissions are positive for both radios, so no blocked-action fallback changes the accepted sequence. Display the actual heavier/costlier/more-energy trade-off alongside the data gain.

[Handoff and owner checklist](../../k27-ab-handoff.md), [audit](../../tools/check_ab_radio_examples.gd), [summary](../../evidence/k27-ab/summary.json), [A report/trace](../../evidence/k27-ab/run-a.json), [B report/trace](../../evidence/k27-ab/run-b.json). Existing Imaging scoring produces partial/82 and success/100 respectively. Both official report.comparison fields remain null; no new comparison schema is invented.
