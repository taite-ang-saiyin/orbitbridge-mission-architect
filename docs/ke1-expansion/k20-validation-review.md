# K20 validation additions: owner review only

Review revision: `k20-review-additions-1`, 15 November 2026, Asia/Rangoon. Supplements [K20 draft 2](k20-interface-review.md), `expansion-goals-v2-draft-2`, and registry `five-presets-candidate-2`. These are exact **proposed** rules for review, not implemented K22 validation or team agreement. The candidate config format and preset values are unchanged by this addendum. No new config field is introduced for this review revision.

SE accepted the direction for review and requested bounds, compatibility, examples and clearer delivery/contact semantics. KE2 supports the previously relayed v2/nested-goal/root-identity/fast-radio choices. HPC, SE final acceptance, KE2's remaining outcome/report choices and KE3 integration approval remain pending. Existing signed contracts are unchanged.

## Validation order and result contract

1. Check shape, required/unknown fields, types, finite numbers, ranges and objective/goal compatibility. Do not calculate totals with invalid values.
2. Resolve preset identity/revision and registered IDs/categories against the frozen registry and effective catalogs. Then check cross-field count bounds and proposed instrument capability. Do not hydrate unsupported objectives merely to make validation pass.
3. Keep all eight existing readiness checks: input_schema, catalog_references, profile_mass, launcher_capacity, budget, launch_orbit, target_orbit, essential_power. Preserve existing v1 input behavior.
4. Any blocking issue makes `ready_to_launch: false`. On shape/reference errors, metrics remain null and dependent gates are not evaluated. Warnings cannot override blocking issues. Goal feasibility/outcomes belong to HPC/KE2, not a readiness success claim.

Keep the existing issue keys `code`, `field_path`, `message`, `suggested_fix`. Existing codes below retain their meanings; `INSTRUMENT_OBJECTIVE_UNSUPPORTED` is a proposed new code. Exact new message wording and the validation-result envelope version need owner confirmation. Consumers use code/path, not array order; report all independently detectable issues in the current phase.

## Exact root and common-field proposal

All objects use strict known-field lists; an extra key is `INVALID_SCHEMA` at its full path. Missing keys or wrong container types are `INVALID_SCHEMA` (missing design slot: existing `MISSING_COMPONENT`). Nonempty strings must be trimmed; IDs are case-sensitive. Counts accept finite whole JSON numbers such as 2 or 2.0; booleans, strings, fractions, null and nonfinite numbers are invalid. Never truncate.

| Path | Required / proposed rule | Rejection |
| --- | --- | --- |
| root | Object with exactly schema_version, contract_revision, preset_id, preset_revision, mission, design | INVALID_SCHEMA |
| schema_version | Whole numeric 2; route supported numeric 1 to the unchanged v1 path | INVALID_SCHEMA at schema_version |
| contract_revision | Exact reviewed config-contract revision, currently expansion-goals-v2-draft-2 | INVALID_SCHEMA at contract_revision |
| preset_id | One of the five IDs in the candidate registry; authored-preset v2 only in this proposal | INVALID_VALUE at preset_id |
| preset_revision | Positive whole number <= 9007199254740991; match the selected published entry (Communication 2, others 1) | INVALID_VALUE at preset_revision |
| mission | Object with exactly the eight required fields below, plus optional target_regions | INVALID_SCHEMA |
| mission.title | Required trimmed nonempty string, maximum 80 characters; editable title is not preset identity | INVALID_VALUE |
| mission.objective | Required imaging, survey, communication or weather_monitoring; must match preset lineage and goal table | INVALID_VALUE |
| mission.target_region | Required registered primary target ID from effective runtime catalogs | INVALID_VALUE |
| mission.target_regions | Optional array; omission means [target_region]. One/two distinct registered targets for Imaging/Survey; exactly one for Communication/Weather. First entry must equal primary | INVALID_VALUE at array or primary path |
| mission.required_observations | Required whole 1-20; remains capture quota | INVALID_VALUE |
| mission.required_returned_data_mb | Required positive finite numeric decimal MB; no integer coercion or duplicated threshold inside goal | INVALID_VALUE |
| mission.duration_orbits | Required whole 1-12 | INVALID_VALUE |
| mission.budget_credits | Required whole 1-9007199254740991; illustrative credits | INVALID_VALUE |
| mission.goal | Required object; exact allowed keys depend on objective below | INVALID_SCHEMA / INVALID_VALUE |
| design | Required object with exactly nine required ID fields listed in the parts review | Missing slot: MISSING_COMPONENT; unknown key: INVALID_SCHEMA |

The eight required mission fields are title, objective, target_region, required_observations, required_returned_data_mb, duration_orbits, budget_credits and goal. `target_regions` is the sole optional mission key. No root or goal key is optional in authored-preset v2 except counts that do not apply to that goal and therefore must be absent.

Existing v1 accepts its existing fields only, with no preset identity or goal required. Do not add v2 goal keys to v1 or infer a goal from an editable title. General/custom v2 configs without authored preset identity are **not covered**; SE/KE1/KE2 must decide that separate use case before it is accepted. Mission edits may retain authored lineage, but A/B eligibility must match the complete requirements, not merely preset_id. That identity/edit policy still needs SE/KE2 confirmation.

## Objective, goal and count compatibility proposal

| Preset lineage / objective | Exact mission.goal keys | Proposed count range and meaning |
| --- | --- | --- |
| estuary_watch or tropical_forest_watch / imaging | kind: imaging only | No goal-specific count; existing capture and MB requirements |
| polar_ice_survey / survey | kind: survey_delivery; minimum_complete_observations_per_target | Whole 1-20, also <= floor(capture quota / selected-target count). Count only fully returned observations per target; retain overall capture and MB requirements |
| communication / communication | kind: communication_contacts; required_positive_contact_steps | Positive whole <= 9007199254740991 and <= duration_orbits * frozen steps_per_orbit. Captures are payload supply, not contacts; do not cap contacts by capture quota |
| weather_monitoring / weather_monitoring | kind: weather_revisit; required_distinct_orbits | Whole 1-12 and <= duration_orbits and <= capture quota; one selected region. Whether a qualifying visit needs complete delivery is still OPEN below |

These count bounds and capability rules are KE1's concrete proposal, not HPC-approved attainability limits. Current two source orbits have ten steps per orbit, so the absolute Communication ceiling in this data revision is 120; compute from metadata, never hard-code ten. Actual contact/target windows, storage, energy and operating policy can make a structurally valid request unattainable. HPC must define any further pre-launch schedule gate without changing legacy readiness silently.

Missing the matching count: `INVALID_SCHEMA` at the missing key. Unknown/inapplicable goal key, including a different objective's count or a duplicate MB threshold: `INVALID_SCHEMA` at that key. Unknown/mismatched kind: `INVALID_VALUE` at `mission.goal.kind`. Unknown objective or preset/objective mismatch: `INVALID_VALUE` at `mission.objective`. Invalid count or violated cross-field bound: `INVALID_VALUE` at the specific count. These failures block launch; no fallback, renaming or score substitution is allowed.

## Part and readiness proposal

Use [the exact parts/capability matrix](k20-parts-review.md). Registered parts are selectable candidates, not automatically feasible combinations. Keep sum-of-six-part mass, launcher-inclusive cost, profile comparator, orbit-specific launcher capacity, target windows and static power checks. Do not invent new radios or weather instruments.

Unknown component: `UNKNOWN_COMPONENT` at its design slot. Known part in wrong slot: `WRONG_COMPONENT_CATEGORY`. Unknown profile/launcher/orbit: `UNKNOWN_PROFILE`, `UNKNOWN_LAUNCHER`, `UNKNOWN_ORBIT`. Known instrument without the objective's accepted capability: proposed `INSTRUMENT_OBJECTIVE_UNSUPPORTED` at `design.instrument_id`. Missing capability metadata or unavailable objective must block the rollout, not default to Imaging support.

Retain existing `PROFILE_MASS_EXCEEDED`, `LAUNCHER_CAPACITY_EXCEEDED`, `BUDGET_EXCEEDED`, `LAUNCH_ORBIT_INCOMPATIBLE`, `TARGET_ORBIT_INCOMPATIBLE` and power errors for their existing readiness gates. A valid shape may still fail readiness or later fail a mission goal. Use the selected profile rule: the sample is strictly <1330 g, not <=1330 g.

## Open gameplay decisions: do not ratify either by inference

**W1 — Weather delivery:** current draft 2 counts accepted captures in distinct orbits plus aggregate MB. That could return only orbit 0's image and still meet a two-visit / 12-MB goal after a second unreturned capture. The stronger alternative counts a visit only when its complete image reaches Earth. KE1 recommends discussing the stronger alternative, but it is NOT selected here. HPC/KE2/SE must choose the definition, evidence fields/packet-to-orbit association and whether a new explicit frozen goal option/revision is needed. Do not silently reinterpret required_distinct_orbits. Both example interpretations remain pending; no score is supplied.

**C1 — Transmission-step counting:** the proposed field counts distinct accepted Transmit steps returning positive MB. Two consecutive positive steps within one contact window therefore count as two. This is not a count of distinct contact windows or ground-station passes. HPC/KE2/SE must explicitly accept this gameplay meaning or request a separately named/frozen window-based goal. Current authored windows do not demonstrate the hypothetical multi-step window case; its example is synthetic and labelled accordingly. Suggested UI wording while discussing it: successful transmission steps.

| Decision | Owners / current state |
| --- | --- |
| Exact shape, count bounds, mismatch codes, custom/edit identity | KE1 proposes above; SE/HPC/KE2 acceptance pending |
| Instrument capability registration/source and training labels | KE1 + HPC + SE pending; no catalog modified |
| W1: accepted captures + pooled MB vs fully delivered visit images | HPC + KE2 + SE pending; no selection or implementation |
| C1: positive steps vs distinct windows | HPC + KE2 + SE pending; step meaning remains proposed |
| Pre-action indexing, packet/orbit evidence and production policy | HPC pending; local traces are evidence only |
| Scores, partial/failed rules, A/B reports and report version | KE2 + SE/KE3 pending |
| State/event/validation/report envelope versions | Each producer/consumer must confirm separately; config v2 alone does not decide these |
| Draft 2 + this addendum ratification and integration | All affected owners pending; SE/KE3 review direction is not final approval |

## Review examples and verification

[Example index](examples/k20-review/README.md) links full configs and their expected proposed issues. Candidate-valid means **valid under these proposed rules and pending capability adoption**, never currently accepted by the production v1 validator. Invalid examples isolate errors or explicitly identify multiple expected issues. Nonfinite tests are described as in-memory/invalid-JSON cases, not disguised as legal JSON fixtures.

[Verification record](evidence/k20-review-additions/checks.json) separates document checks, actual current-engine physical checks and unresolved gameplay. New v2 validation, scoring, cards, schema registration and deployment are not implemented by these materials.
