# Validated KE1-to-HPC component run for KE2

Run ID: **ke3_validated_1u_55d4f33_9dfd942_20261114_01**  
Mission ID: **ke3_validated_1u_feasible_20261114**

Repository: https://github.com/taite-ang-saiyin/orbitbridge-mission-architect.git

- KE1: `ke1@55d4f336e72a68ff31cf37e44f65a98c1cdcc193`, `tests/fixtures/valid_1u_feasible.json`.
- HPC: `feature/hpc-simulator@9dfd942e6fccf230d03dfdf8bf097bf65d8f143f`, `core/HPCContractAdapter.gd`, `core/MissionStepEngine.gd`, `core/OrbitPlanner.gd`, `data/orbits.json`.
- Scenario: high_inc, orbit-presets-v1, 10 steps/orbit, 0.1611111111 hours/step. These are authored educational windows, not physical coverage predictions.

`original-config.json` preserves the fixture bytes. `readiness.json` is the unchanged actual validator result: ready_to_launch=true, all8 checks pass,1060g,82credits; sample profile cubesat_1u_sample, source cubesat_101_1u_sample. The actual source-linked mass check used comparator `<`, threshold1330g. Selected profile/source record is in validation-packet.json; no source attribution was inferred merely from an ID.

The documented HPC API does **not** take ValidationResult as an argument. The isolated coordinator verified/stored the actual passing result before calling `build_scenario(loaded_catalogs, orbit_data)`, `validate_config(original_config, scenario)`, and `init_run(original_config, scenario, run_id, mission_id)`. No gate was bypassed and no extra API/physics was implemented.

Actions reuse the supplied high_inc sample schedule: Power-save at0, Observe at1, Power-save2-6, Transmit7, deliberately rejected Transmit8, then Power-save8-59. Full61-request sequence and returned availability are in actions.json. This is a fresh actual engine execution using the validated fixture, **not replay of the old recorded file** and not a player-controlled SE run.

Final state: completed60/60,1 captured observation,7.7333333328 decimalMB returned,4.2666666672MB stored,21.9388888890999Wh. Readiness does not guarantee the science goals; the deliberate schedule observes only once. No mission score/outcome has been assigned by KE3.

Events:62 in provider order, evt_000 through evt_061, all with this run/mission identity. evt_001 is accepted Observe; evt_007 is accepted contact transmission; evt_008 is the no-contact action_blocked/NO_LINK_WINDOW at step8; evt_061 is mission_finished. The rejected request preserves every state field except event_log/next_event_sequence. The cumulative log exactly equals the collected new-event arrays. Selected raw before/replies are in selected-action-replies.json.

To evaluate with the agreed KE2 implementation:

```gdscript
MissionEvaluator.evaluate_mission(original_config, final_state, full_ordered_events)
```

Use original-config.json, final-state.json and events.json. Return a revisioned matching report, exact same-run evidence IDs, evaluator SHA and applicable source-credit/ledger metadata. Keep empty report source_ids if that is the current contract output; do not silently inject labels into MissionReport. Coordinate any separately versioned readiness-source credit metadata explicitly.

The older **run_ke2_handoff_v01** report remains bound to its ce478f9 recorded trace and launch_approved=false metadata. It must not be relabeled as this run, despite similar numerical counters. This bundle is component verification; **B02 NOT TESTED**.

All exact provider and bundle SHA256 hashes are in provenance.json. Commands/exits and the SE/A07 checks are recorded beside this bundle, not inside production game code.
