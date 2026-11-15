# Current main findings and implementation order

Inspected baseline: main dce75db. K20 now has an exact review draft; K21 adds a candidate registry/loader and tests. Existing gameplay routes are unchanged. See k20-k21-progress.md for candidate registration. K24/K25 engine-feasibility work is now recorded in k24-k25-feasibility.md; explicit contact/revisit plans and eleven traces are ready for HPC review, with production goal integration still pending.

## What exists

| Area | Actual current path and behavior | Expansion implication |
| --- | --- | --- |
| Preset cards | scripts/screens/MissionControl.gd: three cards; apply_preset resets defaults and sets name, one target, objective and orbit | Preserve names/settings; agree stable IDs and append only two cards with SE |
| Active mapping | scripts/integration/mission_runtime.gd: config_for maps only Capture Imagery/imaging and Survey Target Regions/survey | New UI names currently map to unsupported; coordinate mappings rather than silently relabel imaging |
| Extended catalogs | mission_runtime.gd: load_game_catalogs adds Survey and data/mission_scenarios.json targets/windows | Use this loader for UI preset checks. Raw catalog_loader alone has fewer capabilities |
| Pure validation | scripts/core/mission_validator.gd: strict known config fields, whole-number/range checks, target_regions consistency and eight readiness gates | New fields require coordinated schema/contract changes; unknown fields currently fail closed |
| Data | data/components.json, launch_profiles.json, launchers.json, orbits.json and mission_scenarios.json | Values and target windows are authored training data. Retain IDs and HPC ownership |
| Simulation | core/MissionStepEngine.gd records packets, observations_by_target, observations_delivered_by_target and returned_data_by_target_mb | Survey must use complete deliveries; mere collected MB is insufficient |
| Evaluation | scripts/evaluation/mission_evaluator.gd explicitly rejects Survey; comparison is reserved/null | KE2 must implement Survey and new goal types and comparison; KE1 supplies validated inputs |
| Existing baseline | scripts/integration/mission_results.gd stores one eligible baseline and checks some mission fields | This is a starting point, not the full five-preset A/B Design Lab |
| Review and retry | mission_review.gd snapshot; MissionController.gd guards live edits, same-mission retry and owned Modify/Cancel | Include new mission-goal fields in review invalidation and frozen config matching, coordinated with SE/KE3 |
| Legacy route | scripts/integration/mission_workflow.gd is the older Equator-only path | Do not target new UI features here by mistake; main player flow uses mission_runtime.gd |

## Implementation slices

1. **K20 agreement:** choose IDs, extension shape/version and goal evidence. Include changes to mission review, runtime mapping, adapter validation and Results report binding, not only MissionValidator.
2. **K21-K23 setup:** keep three current presets, append two, add accepted schema/capability checks and verify five stock designs. Preserve v1 examples and all existing physical readiness rules.
3. **K24-K26 owner handoffs:** HPC proves window/action feasibility and per-target/orbit evidence. KE2 adds the three missing scoring paths. Keep those implementations under their owners.
4. **K27 A/B inputs:** use the provided radio pair, actual immutable snapshots and matching scenario/policy. Confirm requested metrics exist; display unavailable rather than zero.
5. **K28-K31 checks and handoff:** run relevant regression checks and new cases, update briefs/source labels, then test the actual five-mission/A-B browser build.

## Known dependencies

- Contact count is the number of distinct accepted steps returning positive data, not total Transmit clicks or observation count.
- Weather needs two distinct observed orbits for one region. Current Observe First can take both requested images in orbit one; aggregate imaging success does not prove revisit success.
- Survey can already record complete per-target deliveries, but its evaluator currently refuses scoring. The prepared examples do not remove that guard.
- Both proposed missions still need agreed logical objectives and compatible instrument support. Existing images are test payloads/repeat observations, not weather measurements or real communication engineering predictions.
- The earlier proposed wrapper stays in docs; the checked K21 candidate registry is data/mission_presets.json. Neither enables new goals. Do not feed proposed v2 configs into the current v1 execution path or silently strip goal fields.

## Preserve these constraints

Eight independent readiness checks; strict sample mass below 1330 g; profile-specific limits and labels; credits as fictional units; immutable config/catalog/scenario snapshots; distinct run IDs; input-bound Results; Retry same mission; Modify/Cancel; live-run edit guards; and no early results before terminal state.
