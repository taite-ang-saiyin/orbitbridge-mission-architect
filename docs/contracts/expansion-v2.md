# Agreed expansion contract: config v2

Contract marker: **expansion-goals-v2-agreed-1**. Registry: **five-presets-agreed-1**. Capability declaration: **v2-capabilities-agreed-1**. Recorded 15 November 2026, Asia/Rangoon.

This names the settled K20 rules: draft 2/review additions plus the clarified wording and HPC's final Survey correction. The user confirmed all other owners' agreement and relayed HPC's final agreement, then identified a later-pasted conditional note as historical. No further K20 confirmation is pending. The marker records those decisions; it is not a claim that this implementation or the release has passed all-owner acceptance. The signed [v1 agreement](../team-agreement.md) and [v1 contract](../contracts.md) are preserved.

## Config and authored identity

Keep the existing mission/design fields, numeric units and supported v1 behavior. Config v2 has exactly schema_version, contract_revision, preset_id, preset_revision, mission and design. Freeze the full config at launch. Capture quota, returned MB and goal-specific counts stay separate. Numeric counts must be finite whole numbers; booleans/fractions/strings are not silently coerced.

| Preset | Objective / nested goal | Authored revision |
| --- | --- | --- |
| estuary_watch | imaging / kind imaging | 1 |
| tropical_forest_watch | imaging / kind imaging | 1 |
| polar_ice_survey | survey / kind survey_delivery, minimum_complete_observations_per_target 1 | 1 |
| communication | communication / kind communication_contacts, required_positive_contact_steps 2 | 2 |
| weather_monitoring | weather_monitoring / kind weather_revisit, required_distinct_orbits 2 | 1 |

Original three v1 defaults remain byte-for-field equivalent after JSON numeric normalization. Communication retains high_inc/equator, two captures, three orbits, 12 MB, basic instrument, fast radio and 100 credits: 1120 g / 89 credits. Weather retains its basic-radio starter at 1060 g / 82 credits. Do not convert new objectives to Imaging. Compatible mission edits retain authored template lineage and freeze the edited full requirements. An objective switch requires matching preset context and a new comparison. Titles do not establish identity. General custom-v2 identity is deferred.

## Exact validation bounds

Mission has required title, objective, target_region, required_observations, required_returned_data_mb, duration_orbits, budget_credits and goal; only target_regions is optional. Title is trimmed/nonempty and at most 80 characters. Capture quota is whole 1–20; duration whole 1–12; budget whole 1–9007199254740991; MB positive/finite. Preset revision must match the authored entry. Targets are distinct registered IDs, with primary equal to the first target; allow one/two for Imaging/Survey, exactly one for Communication/Weather.

Goal kind must match objective and authored lineage. Reject unknown root/mission/goal/design fields. Survey supports only per-target minimum one in this revision and needs enough capture quota for all selected targets. Communication step count is positive/whole and cannot exceed duration times the selected frozen scenario's safe positive steps_per_orbit; do not cap it by capture quota. Weather visit count is positive/whole, at most 12 and no greater than duration/capture quota.

Keep the nine required design IDs and existing component categories. All selected IDs, capabilities and authored target opportunities must resolve. Preserve the eight readiness gates and nine physical metrics. Strict sample mass remains <1330 g with its existing source credit; other profiles use their own limits. Budget, launch/orbit compatibility and essential power remain independent. Static readiness is not proof of action-plan feasibility or mission success.

## HPC evidence and success meanings

- Communication: distinct accepted Transmit steps with delta_returned_data_mb > 0. Two positive steps in one window count twice; duplicates count once; rejected/zero-data steps count zero. Success requires its positive-step and returned-MB goals.
- Weather: accepted Observe, delta_observations > 0, matching selected target, deduplicated by selected target/revolution. Use the accepted event's zero-based pre-action step and frozen steps_per_orbit. Success uses distinct-revolution visits plus aggregate returned MB; no complete-delivery-per-visit rule.
- Communication/Weather capture quota limits/generates payload; reaching the capture quota is not an extra success condition.
- Survey: fully delivered observations use observations_delivered_by_target. Overall capture and returned-MB goals still apply. Missing whole required map is unavailable. In a verified native state containing that map, a missing selected-target entry is zero deliveries because native maps start empty and gain entries with activity. Historical/incomplete projections without verified native provenance remain unavailable.
- Resource extrema use initialization plus every accepted post-clamp state, including terminal. Missing required samples/maps stay unavailable. Preserve decimal MB and Wh.
- State/event envelopes may remain v1 only if structures and meanings remain compatible while retaining the full v2 config snapshot. Verify that compatibility during actual implementation; it is not established by this agreement.

## Evaluation, comparison and rollout

KE2's [owner reply](../ke1-expansion/owner-replies/ke2-k20-k31-owner-reply.md) gives the settled raw success/partial/failed rules, capped-ratio scores/final half-up rounding, abort behavior, missing evidence errors and report-v1/v2 migration. Those rules are not implemented by the KE1 readiness validator. Preserve the already verified packet/eight execution keys and original key preimage bytes.

A/B requires matching full mission/orbit/conditions/versions, separate completed run IDs, immutable A, frozen inputs and ordered events. Compare requested policy/manual choices; hardware-dependent action acceptance under the same requested plan is not automatically changed operations. Changed requests are Design + operations; unknown requests stay unclassified. Reports bind to full config, readiness, state and ordered events, not just run ID.

The explicit v2 context attaches the same agreed registry/capability documents to effective legacy physical catalogs. It does not change v1 objective registration. HPC/SE must consume that same capability source and include every validator dependency in producer-version binding; see the [K21/K22 integration guide](../ke1-expansion/k21-k22-live-integration.md).

No new card is enabled by these data files. KE1 validation can approve physical readiness, but the current native adapter still rejects v2 and the existing UI mapping/evaluator still require coordinated owner work. Keep unsupported launches blocked; do not strip goals or downgrade configs to bypass the adapter. Public browser and five-mission/A-B release acceptance remain separate.
