# Expansion interface proposal - not ratified

K20 update (15 November): [the exact v2 interface review](k20-interface-review.md) now names the proposed fields, objective IDs, goal rules, versions and owner decisions. The user confirmed agreement is not yet available and requested a draft. The brainstorming below is retained for history; use the v2 review for the current concrete proposal. No shared contract or signature was changed.

Status: prepared for K20 review. Preserve docs/team-agreement.md and docs/contracts.md exactly. No new signatures or agreement are implied by the user's scope approval.

## Proposed preset wrapper

Keep preset metadata and goal definitions separate from a current v1 engine config during preparation. The sample registry references legacy config files and includes status/assumption labels. It is not a drop-in runtime catalog. Before implementation, KE1/HPC/KE2/SE must choose whether to extend MissionConfig or carry a versioned goal context through every snapshot and evaluation boundary. The chosen design must bind new goals to the execution and report; a UI-only label is insufficient.

| Field | Proposal | Owners to confirm |
| --- | --- | --- |
| preset_id | estuary_watch, tropical_forest_watch, polar_ice_survey, communication, weather_monitoring | KE1 + SE; IDs are new proposals, existing cards have names |
| goal kind | imaging, survey_delivery, communication_contacts, weather_revisit | KE1 + HPC + KE2; these are not registered engine objective IDs yet |
| Required captures | Keep existing Imaging/Survey setup goals and allowed ranges | KE1 + KE2 |
| Required contacts | Positive whole number, proposed 2; count distinct accepted steps with returned MB > 0 | HPC event meaning + KE2 count |
| Required orbit visits | Positive whole number, proposed 2 for one selected region; deduplicate by region + orbit index | HPC event/orbit meaning + KE2 count |
| Required returned MB | Finite positive decimal MB, proposed 12 for new presets | KE1 + HPC + KE2 |
| Duration | Existing whole-orbit range; proposed 3 for new presets | KE1 validates bounds; HPC proves windows |
| Evidence identity | Run ID, stable event ID, step index, action outcome, target ID, orbit index and positive transmitted MB | HPC; KE2 binds evidence to the exact run |
| Version identity | Preset, goal schema, component catalog, scenario and engine versions | KE1 + HPC + SE + KE2 |

Clarify step/orbit indexing (zero-based or one-based) once. The sample action plan uses zero-based **pre-action** step indices and derives an orbit index as floor(step / steps_per_orbit). Production consumers must use the agreed HPC event semantics rather than guessing from elapsed UI time.

## Rules to agree

1. Keep v1 imaging/Survey input compatibility. Define exact new fields and reject unsupported/malformed goals. Do not silently turn Communication or Weather into an imaging score.
2. Preserve Survey complete-delivery semantics: each selected target needs at least one complete observation received on Earth, plus any retained overall requirements. Partial packets and pooled returned MB cannot satisfy a missing target.
3. Count only accepted observations for Weather and only accepted positive-data transmissions for Communication. Duplicate events do not count twice. Both the mission count and MB threshold must pass for success.
4. A completed run with unmet goals is a valid experiment for A/B. Aborted or incomplete runs are not a controlled comparison pair in v1.
5. A/B matching includes preset, goal definitions, targets, budget, orbit, duration, initial conditions except intended design differences, catalog/scenario/engine versions and action policy. Store exact actual action histories. A changed manual plan must be labelled design + operations.
6. Review confirmation and retry/report keys must include new goal/version fields. Two runs with a reused ID but different goals must not share a result.
7. Agree partial/failed results and unavailable metrics. Never treat a missing counter as zero or claim a causal improvement without controlled evidence.
8. No save server is needed. The proposed first Design Lab keeps A/B in the current browser session and explains refresh loss; changing this requires an explicit product decision.

## Owner review record

| Role | Decision needed | Status |
| --- | --- | --- |
| KE1 | Config validation, capabilities, IDs and backward compatibility | Pending |
| HPC | Evidence fields, windows, action policy and orbit identity | Pending |
| KE2 | Goal outcomes, evidence rules, comparison and partial results | Pending |
| SE | Runtime adapters, storage, mission review invalidation and export | Pending |
| KE3 | Goal presentation, Results and retry/edit behavior | Pending |

Record decisions and the actual agreed revision here before updating shared contracts. Do not copy a pending row into an approved signature table.
