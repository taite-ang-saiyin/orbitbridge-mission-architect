# K26 Survey examples

Preparation only; K20 agreement, HPC acceptance and KE2 Survey scoring remain pending. These are valid **v1 Survey engine inputs**, with a separately labelled proposed-v2 counterpart. They are not official evaluated mission reports.

| File | Meaning |
| --- | --- |
| [two-target-survey.v1.json](two-target-survey.v1.json) | Same two-capture/12-MB/three-orbit config for complete, absent and partial Antarctic delivery cases |
| [two-target-survey.proposed-v2.json](two-target-survey.proposed-v2.json) | Draft-2 counterpart with survey_delivery and minimum_complete_observations_per_target: 1; currently rejected by production validator; edited lineage policy pending |
| [polar-ice-stock.v1.json](polar-ice-stock.v1.json) | Exact original single-target preset config, unchanged five captures/60 MB/six orbits/basic radio |
| [polar-ice-fast-radio-variant.v1.json](polar-ice-fast-radio-variant.v1.json) | Original mission with only the radio changed; separate redesign example, not a new default |
| [plans.json](plans.json) | Five exact zero-based pre-action schedules, expected native counters and separate proposed goal conditions |
| [handoff-expectations.proposed.json](handoff-expectations.proposed.json) | Semantic expectations for KE2 review; no invented score or approved outcome label |

See [the handoff and findings](../../k26-survey-preparation.md), [native audit](../../tools/check_survey_delivery_examples.gd), [summary](../../evidence/k26-survey/summary.json) and [integrity record](../../evidence/k26-survey/integrity.json).

The matched three delivery cases have identical hardware and mission settings and differ only in operations. The unreturned/partial cases are valid experiments, not malformed launch configs. Both capture the selected regions and meet aggregate 12 MB, but cannot satisfy a proposed full-delivery-per-target requirement. They do not choose any unresolved Weather rule or implement Survey scoring.

The stock basic-radio setup has insufficient capture/transmit opportunities to return 60 MB after five captures under current windows; the fast-radio variant completes that goal. The original defaults are preserved for owner review. All physical values/windows are authored educational assumptions; Polar imagery here is not a physical coverage forecast.
