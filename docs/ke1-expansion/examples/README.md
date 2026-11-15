# Prepared examples: inputs, not implemented new features

K20/K21 update: the concrete candidate definitions are now in [data/mission_presets.json](../../../data/mission_presets.json), and exact field naming is in [the K20 review](../k20-interface-review.md). This earlier wrapper remains a historical preparation example; it is not the new loader input.

| File | Meaning | Current support |
| --- | --- | --- |
| mission-presets.proposed.json | Five-preset proposal with separate logical goals and stock config references | Documentation wrapper; not a production catalog or ratified schema |
| legacy-configs/*.json | Current schema-v1 physical/setup inputs using actual catalog IDs | Validate through MissionRuntime.load_game_catalogs and MissionValidator |
| design-a.v1.json / design-b-radio.v1.json | Same existing imaging mission, changing only radio_basic to radio_fast | Valid current inputs; no prewritten performance verdict |
| k27-ab/ | Tested one-radio-change v1 Imaging pair, exact same operations and current KE2 reports | 36 native checks passed; live A/B UI/comparator and expanded matching remain pending |
| comparison-pair.proposed.json | Matching conditions and the intended one-field change | Comparison matching itself is not implemented by these examples |
| k24-k25-action-plans.json | Eleven tested Communication/Weather schedules and negative controls | Current-engine feasibility only; owner confirmation and production goals pending |
| k26-survey/ | Actual v1 Survey configs, complete/missing/partial delivery schedules and draft-v2 counterpart | Native traces checked; scorer, HPC acceptance and K20 agreement pending |
| action-plans.proposed.json | Explicit zero-based pre-action schedule for testing possible new goals | Audit can exercise today's engine; production goal scoring/policy remains owner work |

Communication/Weather legacy configs intentionally use the existing imaging engine objective to study physical feasibility. **They are not working Communication/Weather objectives.** The proposed wrapper carries the intended goal separately; do not display an imaging score as if it evaluated contacts or revisits. Implement a versioned end-to-end goal extension only after K20 agreement.

Existing presets are copied from the current UI defaults and mappings. Source windows are authored training data. Weather uses the registered equator region for a repeat-observation exercise; no real atmospheric data is added. The normal Observe First policy can exhaust two captures in one orbit, which is why the explicit revisit schedule is included.

See ../verification.md for actual example checks, measured totals and outstanding dependencies. A passing readiness result is not mission success.
