# K20 review draft: exact expansion interface

**Latest implementation update:** K20 is agreed and K21 definitions are delivered. [K21/K22 production API and current blockers](k21-k22-live-integration.md) and the [agreed v2 contract](../contracts/expansion-v2.md) supersede earlier pending-confirmation/candidate-only status. The public validator now supports explicit agreed v2 context; native launch integration remains blocked. Existing reviewed ZIPs are unchanged historical snapshots and do not contain these later files.


**Latest HPC status:** [Conditional review received and exact clarifications](hpc-k20-clarifications.md). Final HPC acknowledgment remains pending; non-HPC agreements stay settled. State/event v1 is conditional on implementation compatibility. Current code still rejects v2. Earlier pending-owner statements below are historical. Existing ZIPs remain unchanged; this clarification postdates the current handoff archive.


**Current update, 15 November:** Only HPC confirmation remains. [Consolidated non-HPC decisions](k20-consolidated-non-hpc-decisions.md), [candidate validator](k22-v2-candidate-validator.md), [aligned copy](k29-mission-wording-preparation.md) and [single current handoff](current-implementation-handoff.md) supersede earlier pending-owner labels below. Candidate tests: 2429 passed. Latest SE checks still expose two implementation issues; final integration remains pending.


**Current K20 status — user confirmation, 15 November 2026:** All non-HPC agreement items are already agreed. **HPC is the only remaining K20 confirmation.** Do not request SE/KE2/KE3 agreement again for those settled items. This records the user's confirmation; earlier pending-owner notes below describe previous checkpoints. K20 remains unchecked until HPC replies and the matching consolidated revision is recorded. Code implementation, known SE guard/Creator fixes, production evaluator/comparison support and final build/browser tests remain separate unfinished work. New mission launches remain blocked. Reviewed ZIPs and signed v1 contracts remain unchanged.


Revision: `expansion-goals-v2-draft-2`. Date: 15 November 2026, Asia/Rangoon. Status: **UPDATED TO KE2'S PROPOSAL; HPC AND SE CONFIRMATIONS PENDING**. The user relayed KE2's support for config v2, nested goals, root preset identity and the fast-radio Communication starter, then requested this update and a review package. This records support for those choices, not full team agreement or integration sign-off. `docs/team-agreement.md` and `docs/contracts.md` remain unchanged.

This supersedes draft 1 for current interface review. Registry revision is `five-presets-candidate-2`; Communication preset revision is `2` because its radio changes. Other presets retain preset revision `1` and their prior mission/design values. All candidate configs identify this draft 2 contract. Supported v1 inputs and fixtures remain unchanged.

SE review additions (15 November): [exact proposed validation rules](k20-validation-review.md), [selectable parts and proposed capabilities](k20-parts-review.md), and [valid/invalid examples](examples/k20-review/README.md) form review revision `k20-review-additions-1`. They supplement this still-unapproved draft; candidate values and the config contract marker are unchanged. Exact rules, Weather delivery choice (W1), transmission-step/window meaning (C1), capability registration and owner confirmations remain pending. Acceptance would require a coordinated frozen contract revision, not silent implementation of this addendum.

## Recommended decision

Use explicit **MissionConfig version 2** for the new goal-bearing contract, while preserving supported version 1 inputs exactly. Do not overload `required_observations` with contact or orbit counts and do not use a separate, mutable UI goal outside the frozen execution snapshot.

The candidate registry format is version 1; its `candidate_config_v2` records describe the proposed game config version 2. These are different version numbers for different objects. Current runtime/validator/evaluator code rejects the candidate game configs; the registry does not change that.

## Exact proposed fields

Retain the current `mission` and `design` fields and units. Add the following to the root config:

| Field | Type / proposed value | Purpose |
| --- | --- | --- |
| schema_version | integer `2` | Distinguish the new goal contract from v1 |
| contract_revision | string `expansion-goals-v2-draft-2` during review | Record the exact reviewed goal rules; replace with agreed revision only after review |
| preset_id | one of five stable IDs below | Identify the authored mission, independent of its editable title |
| preset_revision | positive integer; Communication `2`, other current candidates `1` | Identify the authored preset definition; must match its registry entry |
| mission.goal | object with `kind` and the goal-specific count below | Carry success requirements inside the immutable launch config |

`mission.required_returned_data_mb` remains the sole returned-data threshold. `mission.required_observations` retains its captured-observation/quota meaning; it never becomes a contact/visit count. For Communication it controls test-payload generation, not the number of successful contacts. No duplicated MB threshold is added inside `goal`.

| Preset ID | mission.objective | mission.goal | Common requirements |
| --- | --- | --- | --- |
| estuary_watch | imaging | `{"kind":"imaging"}` | Preserve 5 captures, 60 MB, 6 orbits and current target/orbit/budget |
| tropical_forest_watch | imaging | `{"kind":"imaging"}` | Preserve 5 captures, 60 MB, 6 orbits and current target/orbit/budget |
| polar_ice_survey | survey | `{"kind":"survey_delivery","minimum_complete_observations_per_target":1}` | Preserve current overall capture/data goals and require complete delivery for every selected target |
| communication | communication | `{"kind":"communication_contacts","required_positive_contact_steps":2}` | Proposed 12 MB over 3 orbits; generate test payload with capture quota 2 |
| weather_monitoring | weather_monitoring | `{"kind":"weather_revisit","required_distinct_orbits":2}` | Proposed 12 MB over 3 orbits; capture quota 2; one selected region in the initial preset |

The new presets use existing training hardware, high_inc and the registered equator region. They add no real RF model, atmospheric instrument or forecast. All invented values/windows retain assumption labels.

## Communication starter aligned with KE2

Use `high_inc`, `equator`, two captures, three orbits, 12 MB, two positive transmission steps and a 100-credit budget. Use `bus_basic`, `instrument_basic`, `solar_standard`, `battery_standard`, **`radio_fast`**, `storage_standard`, `cubesat_1u_sample` and launcher `small`. Current catalog totals are **1120 g and 89 credits**. Weather keeps its basic radio and other prior settings.

KE1's current-engine feasibility check captures at pre-action steps 1 and 6 and transmits at 7 and 10. The fast radio returns approximately 19.3333 MB then 4.6667 MB, for 24 MB total and two distinct positive contacts. A one-capture control returns 12 MB at step 7; step 10 is rejected with `NO_DATA`, isolating a contact-count shortfall while the data threshold passes.

These are measured with a test-only supported v1 Imaging surrogate derived from the candidate definition. The production validator still rejects v2; no Communication score or playable card is enabled. HPC must independently confirm this exact starter, event meanings and the shortfall. The [review audit](tools/check_communication_starter.gd) and [measured evidence](evidence/ke2-draft-2/communication-fast-radio-check.json) are included in the package. State/event/report schema versions remain separate owner decisions.

## Evidence rules for HPC and KE2

- **Contacts (C1 still proposed):** count distinct accepted Transmit steps with `delta_returned_data_mb > 0`. This would count two positive steps in one contact window as two; it is not a distinct-window/pass count. HPC/KE2/SE confirmation is pending. Zero-data/off-window/rejected attempts do not count. Deduplicate by `(run_id, step_index)` after validating stable event identity.
- **Weather visits (W1 open):** this draft's accepted-capture interpretation matches selected-target Observe events and deduplicates `(run_id, target_id, orbit_index)`. Another region or a same-orbit second image cannot add a visit. SE requested a decision on complete image delivery per visit; the stronger alternative is not adopted here. See both interpretations and actual traces in the validation addendum before ratification.
- **Orbit indexing:** use zero-based pre-action `step_index` from HPC events. Derive `orbit_index = floor(step_index / steps_per_orbit)` from the frozen scenario, not a UI clock and not a hard-coded 10. The candidate source happens to have 10 steps per orbit. HPC confirms this convention or proposes a documented alternative before agreement.
- **Survey:** `observations_delivered_by_target` counts only fully delivered packets. Partly returned packets and high pooled MB must not fill a missing target requirement. Preserve overall captured/data goals in the existing Survey preset.
- **Outcome:** each goal-specific requirement and returned MB must pass. KE2 confirms exact partial-result and numeric-score behavior; this draft does not invent new scoring formulas.
- **Identity:** snapshot full config, catalogs/scenario versions and actual ordered events. Bind reports to the full goal-bearing config and run ID. New requirements invalidate mission review confirmation and old results. Retry/Modify/Cancel and live-edit guards must survive.
- **State/report versions:** each owner must explicitly declare whether its state/event/report envelope changes version when accepting config v2. Do not assume a config bump automatically changes unrelated schemas. Required config snapshot/evidence semantics above apply whichever reviewed envelope version is selected.

## Backward compatibility and rollout

1. Preserve all supported v1 fixtures and original three-preset defaults. Existing Survey may still fly with an explicit unavailable-score message until KE2 extends it.
2. K22 and the other owners add a coordinated v2 path; never silently strip goals or reinterpret new objectives as Imaging.
3. Freeze instrument capability rules and the common/goal-specific bounds together. Do not rewrite `data/components.json` solely to bypass an unsupported objective.
4. Propagate new fields through runtime mapping, mission-review snapshots, HPC adapter/init checks, frozen run storage, result binding, KE2 evaluation and A/B matching before enabling the new cards.
5. For A/B, compare matching preset/goal definitions, targets, orbit, duration, budget, catalog/scenario/engine versions and policy. Keep actual action histories. Changed actions mean design + operations comparison; no hardware-only causal claim. Each run has a new ID and A remains unchanged.

Owner-review update: see [reported receipts, checks and remaining decisions](k20-owner-review-record.md). This records review support, not final ratification. Shared ZIPs/manifests remain unchanged.

## Owner decisions still needed

| Owner | Concrete review item | Status |
| --- | --- | --- |
| KE1 | Config v2 fields, objective/goal IDs, type/range rules and v1 compatibility | Supports draft 2 candidate; local catalog/readiness/feasibility checked; shared ratification pending |
| HPC | Config v2 acceptance, state/event versions, target/packet/orbit evidence and revisit policy | Pending owner review |
| KE2 | Config/report versions, Survey/new-goal evaluation, partial/score rules and A/B evidence | Support received for listed config choices and fast-radio starter; draft-2/candidate-2/revision-2 receipt confirmed and 629 passing checks reported; report version, scoring/partial/A-B details remain pending |
| SE | Config mapping, five cards, review invalidation, immutable storage and version propagation | Additions 1 planning review confirmed; 110 physical and 70 catalog checks reported passing; exact rules/capabilities, W1/C1, identity/reports and final acceptance pending |
| KE3 | Mission progress/Results presentation and preserved retry/edit interactions | Additions 1 review confirmed for presentation planning; 110 checks reported reproduced; final definitions/scoring and integration sign-off pending |

Review artifacts: [candidate definitions](../../data/mission_presets.json), [catalog API](../../scripts/core/mission_preset_catalog.gd), [checks](../../tests/validation/test_mission_presets.gd), and [KE2 package guide](ke2-review-package.md). HPC and SE remain pending. Package preparation does not mean receipt, approval, commit, push or deployment.
