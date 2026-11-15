# HPC native goal evidence v1.0.0

Prepared 15 November 2026, Asia/Rangoon. Native producer baseline: `dce75db845f6c494b8c25c9028dd9c0648aabd91` (`main`). Generator revision: `hpc-goal-evidence-v1.0.0`, with its exact source hash recorded in each example. New generator files are separate from that baseline commit. No engine, validator, catalog, evaluator, controller or UI implementation is changed by this handoff.

This package supplies 12 actual native executions covering the five proposed presets and four requested goal types. It confirms HPC measurement semantics. Expanded config/report/scoring adoption remains a coordinated owner task.

**Scope:** Imaging and Survey use their real schema-1 objectives and KE1-validated effective game catalogs. Communication and Weather use explicitly labeled native Imaging mechanics proxies because production `main` does not accept those objective IDs or schema-2 launch configs. Their native events/resources are real; no Communication/Weather launch approval, report or score is invented. All examples retain `expanded_objective_score: null`.

## Start here

- [Manifest, summaries and SHA-256 hashes](manifest.json)
- [Commands, exit codes and verification log hashes](verification.json)
- [Authored run inputs](../../../tests/fixtures/hpc_goal_examples_v1.json)
- [Pinned native source-file hashes](../../../tests/fixtures/hpc_goal_source_v1.json)
- [Generator and native replay verifier](../../../tests/run_hpc_goal_examples.gd)
- [Combined PowerShell checks](../../../tests/run_hpc_goal_evidence.ps1)

Each example contains the original native launch config, readiness result, effective catalog/scenario snapshots, initial/terminal native states, complete ordered native events, run/mission IDs, scenario ID/version, explicit requested actions, post-request packet/resource frames, accepted-step resource samples, derived goal measures and extrema. Events are retained exactly as emitted; no orbit fields or display values are inserted into them. The source-file hashes include the target extension and runtime catalog loader, since `scenario_version` alone does not identify the extended target schedule.

## Canonical native counters and derived measurements

Native `MissionState` and `Event` stay at schema version 1. The evidence wrapper's `schema_version` and `bundle_revision` version this handoff separately. The `goal_measurements` names below are measurement output, not newly added native state fields or KE2 report fields.

| Meaning | Canonical native source / evidence measure | Confirmed meaning |
| --- | --- | --- |
| Captured observations | `final_state.observations_completed` | Successful captures, not complete deliveries or opportunities |
| Received data | `final_state.returned_data_mb` | Cumulative decimal MB received on Earth; excludes stored MB |
| Captures per target | `final_state.observations_by_target[target_id]` | Successful captures attributed to that selected target |
| Received data per target | `final_state.returned_data_by_target_mb[target_id]` | Received MB from that target, including partial packets |
| Complete Survey deliveries per target | `final_state.observations_delivered_by_target[target_id]` | Count of complete observation packets delivered for that target |
| Survey selected-target count | `goal_measurements.selected_targets_delivered` | Number of selected targets with at least one complete delivered observation; raw counts are in `complete_deliveries_by_selected_target` |
| Qualifying Communication steps | `goal_measurements.positive_transmit_steps` | Distinct pre-action steps with `type == action_accepted`, `action == transmit`, and `delta_returned_data_mb > 0` |
| Selected-region observed revolutions | `goal_measurements.selected_target_revolution_visits` | Distinct zero-based revolution indices with accepted positive captures of the single selected Weather region |
| Observation revolutions for each region | `goal_measurements.observed_orbit_indices_by_target[target_id]` | Explicit indices derived from accepted Observe event steps for that target; matching evidence IDs are retained |
| Battery and storage | State/sample `energy_wh`, `stored_data_mb`, `battery_capacity_wh`, `storage_capacity_mb` | Native post-clamp resource quantities in Wh and decimal MB |
| Sampled resource extrema | `resource_extrema.lowest_battery_wh`, `highest_battery_wh`, `lowest_battery_percent`, `highest_storage_mb`, `lowest_storage_mb` | Extrema under the explicit sampling rule below |

### Acceptance, step and revolution semantics

- `ok: true` can accompany a blocked request. Count an accepted operation from `allowed: true` and its `action_accepted` event. Blocked requests change neither resources nor step, but do allocate new event IDs.
- The canonical returned-data delta is `Event.delta_returned_data_mb`. `data_transmitted_mb` describes the same amount, subject to floating-point rounding when cumulative totals are subtracted. Both are retained without rounding. Accounting/replay checks use `1e-7` absolute tolerance for arithmetic comparisons; integer counts remain exact.
- Identify an event by `(run_id, event_id)`. Preserve the native event order. This package checks sequential unique IDs, matching run/mission identities, and exact request-to-event associations. Missing, conflicting or cross-run evidence must not be silently counted.
- A Communication count is the number of distinct positive-MB accepted Transmit **steps**, not the number of contact windows. Multiple qualifying steps inside one continuous window would each count. Blocked `NO_DATA` / `NO_LINK_WINDOW` and zero-MB entries do not count. The stock presets use isolated contact steps.
- Accepted event `step_index` is the requested **pre-action** step. Returned state is already at the following step. Returned sunlight/contact flags therefore describe the following opportunity, not the action just taken.
- Select the matching orbit row in `scenario_snapshot.orbits`. `orbit_index = floor(event.step_index / steps_per_orbit)` and `step_in_orbit = event.step_index % steps_per_orbit`. Both are zero-based and match `OrbitPlanner`. With ten steps per orbit, steps 0-9 belong to orbit 0, and step 10 starts orbit 1. A terminal `mission_finished` event at `total_steps` is not an observation or an extra revolution visit.
- A Weather visit needs `type == action_accepted`, `action == observe`, positive `delta_observations`, and `target_id` matching the selected region. Two captures in one revolution count as one visit. Overflights and transmissions do not establish visits.

### Survey completion and sparse maps

One accepted Observe creates one target-labelled packet. Transmission drains `data_packets` in FIFO order. Complete delivery increments only when the native packet remainder is below `1e-8 MB`; that is the current engine's completion tolerance. Received MB and captured counts cannot substitute for the complete-delivery counter.

Native maps begin empty. An absent target key in an existing genuine native map means zero activity. A missing whole map, a legacy projection without these fields, or an unverifiable historical record means **unavailable**, not zero. `final_state` retains the original sparse maps; the evidence-only `complete_deliveries_by_selected_target` view fills absent selected keys with zero only after confirming native provenance. No stable packet IDs or separate delivery-completed events are emitted by this engine revision. Use per-request packet/map snapshots to locate the native event associated with a completion transition.

### Resource sampling

Sampling ID: `initial_and_each_accepted_poststep_v1_proposal`. The identifier retains KE2's proposed spelling for interoperability; HPC confirms this sampling meaning for the current evidence release.

`resource_samples` includes the initialized state and every accepted action's post-clamp state, including the final accepted step. A completed run has `total_steps + 1` samples. `request_frames` additionally includes every blocked post-request frame, with unchanged resources and the corresponding event IDs. A terminal notification shares its action's final sample and does not create another physical step.

Lowest battery is the minimum sampled Wh. Battery percentage is `100 * lowest_battery_wh / battery_capacity_wh`. Highest storage is the maximum sampled stored MB. Initial and terminal values are included. These are discrete simulation-state extrema, not raw pre-clamp or continuous-time estimates. Missing samples must remain unavailable. Full-precision JSON preserves native floating-point values.

## Native examples and expected measurements

Numbers shown here are rounded for readability. JSON files preserve full precision. Every native run completes; goal satisfaction is a separate question. HPC provides measurements, leaving official status and scoring to KE2.

| Example | Captures | Returned MB | Positive Transmit steps | Additional evidence |
| --- | ---: | ---: | ---: | --- |
| [Estuary stock](estuary_watch_stock.json) | 5 | 60 | 8 | Five complete coastal deliveries |
| [Forest stock](tropical_forest_watch_stock.json) | 5 | 44.32 | 6 | Three complete deliveries; 60-MB goal remains unmet |
| [Forest fast radio](tropical_forest_watch_fast_radio.json) | 5 | 60 | 5 | Same setup and declared action plan, only radio changed |
| [Arctic Survey stock](polar_ice_survey_stock.json) | 5 | 54.133333 | 7 | Four complete Arctic deliveries; 60-MB goal remains unmet |
| [Arctic Survey fast radio](polar_ice_survey_fast_radio.json) | 5 | 60 | 5 | Five complete Arctic deliveries |
| [Two-target Survey partial packet](survey_two_targets_partial_packet.json) | 2 | 15.466667 | 2 | Captures and 12-MB aggregate goal met; complete deliveries: forest 1, ocean 0 |
| [Two-target Survey complete](survey_two_targets_complete.json) | 2 | 24 | 4 | Complete deliveries: forest 1, ocean 1 |
| [Communication complete mechanics](communication_complete_proxy.json) | 2 | 24 | 2 | Accepted positive steps 7 and 10; blocked no-contact step 8 does not count |
| [Communication count shortfall](communication_count_shortfall_proxy.json) | 1 | 12 | 1 | Same config/quota 2; step 10 is blocked `NO_DATA`; 12 MB alone cannot prove two steps |
| [Weather two revolutions](weather_two_orbits_proxy.json) | 2 | 24 | 4 | Captures at steps 1 and 11 establish revolution indices `[0, 1]` |
| [Weather one-revolution shortfall](weather_one_orbit_shortfall_proxy.json) | 2 | 24 | 4 | Same config, captures at steps 1 and 6; only revolution `[0]` qualifies |
| [Low-equatorial Communication mechanics](communication_low_eq_basic_radio_proxy.json) | 1 | 12 | 2 | Basic radio returns one packet across steps 8 and 18 |

The stock named presets retain five captures, 60 MB, six orbits and a 100-credit budget. Fast-radio variants are explicit design edits, not silent changes to starter presets. The two-target Survey cases are labeled custom goal examples. Package `preset_id` values are descriptive metadata, not config-v2 registry adoption; native mission titles identify each example. Communication's current candidate starter mechanics use high_inc, basic instrument, fast radio, capture quota 2 and three orbits. Weather mechanics use high_inc, basic instrument/radio, capture quota 2 and three orbits. Proposed Communication count 2 and Weather distinct-orbit count 2 are recorded in `example_inputs`, outside the native v1 launch config.

Survey packet detail: after request step 7, the first target's 12-MB packet is partly received and has no complete delivery. After step 10, the first target is complete while the second has received approximately 3.466667 MB and remains incomplete. Steps 17 and 20 complete the second packet in the complete variant. Per-target data conservation is verified at every frame.

## Reproduction and verification

Use the pinned producer revision and these three source artifacts: `tests/run_hpc_goal_examples.gd`, `tests/fixtures/hpc_goal_examples_v1.json`, and `tests/fixtures/hpc_goal_source_v1.json`. They are included in the portable archive alongside the evidence. Check the source hashes before treating a replay as evidence for this version. A changed native dependency requires an explicitly revised source pin and handoff revision.

From the project root with Godot 4.7.2 on PATH:

```sh
godot --headless --path . --script tests/run_hpc_goal_examples.gd
godot --headless --path . --script tests/run_hpc_goal_examples.gd -- --verify-only
```

Generation validates the authored expectations and replays every native request from the retained config/scenario. `--verify-only` loads the written JSON, verifies inputs, hashes, summaries, samples and native replay without overwriting the examples. To write to a separate directory, append `-- --output-dir <path>` to generation, or `-- --verify-only --output-dir <path>` for verification.

The portable wrapper additionally runs the existing 48-case HPC suite, multi-target/prediction checks for both orbits, and legacy simulator regression:

```powershell
.\tests\run_hpc_goal_evidence.ps1 -GodotExe 'C:\Tools\Godot\Godot.exe'
```

Replace the example executable path with the installed Godot 4.7.2 path. All five commands exit 0 with no script/test failures. Generation passes 9,824 checks; persisted verification passes 8,266 checks, including all 12 native replays in each mode. The manifest captures 9,822 passes before its own two output-write checks; the generator log includes those final checks. Results, exact commands, log hashes and manifest hash are in [verification.json](verification.json); logs are retained under `logs/`. The environment's certificate-store diagnostic is recorded separately from script/test failures.

No production configuration migration, expanded-objective scoring, saved-record execution binding, UI acceptance, or browser run is claimed by this HPC-only evidence package. KE1/SE still need coordinated typed-v2 launch acceptance; KE2 owns expanded goal verdicts and scoring. The same Communication/Weather physical mechanics are now demonstrated and measured by HPC.
