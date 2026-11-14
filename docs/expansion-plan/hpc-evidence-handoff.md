# HPC evidence handoff for KE2 expansion

Prepared on 15 November 2026 in Asia/Rangoon from `features/KE2` at `4c65496`. Task 00.3 planning deliverable. Field descriptions below follow inspected source and existing records. New objective fields, thresholds, and sampling decisions retain their proposal status.

## Existing producer and runtime route

`MissionStepEngine.init_validated_run(config, ke1_catalogs, run_id, mission_id)` calls the KE1 validator, then `HPCContractAdapter.build_scenario()`, then `init_run()`. The adapter copies registered objectives, target/window data, component rows, profiles, and launchers into the run scenario. It maps instrument `data_per_observation_mb` to `packet_mb` and preserves hourly radio rates. The selected scenario is retained in `state.scenario_snapshot`, with config in `state.config_snapshot`.

Active `mission_runtime.gd` retains `trace.frames`, `trace.events`, `trace.config`, `trace.catalogs_snapshot`, policy, and final state. Its first frame is the initialized state, and later frames hold returned states and request events. Policy playback can be precomputed through completion while the player's `active_run_state` is still operating. SE owns binding a reached execution and retaining its evidence for Results and Save A.

The legacy `MissionSimulator.gd` / `LegacyTraceAdapter.gd` route has separate units and event semantics. Native step-engine energy is already Wh and data already decimal MB. Apply the legacy Ws/KB conversion at its documented boundary when consuming legacy records.

Source entry points are [engine](../../core/MissionStepEngine.gd), [adapter](../../core/HPCContractAdapter.gd), [planner](../../core/OrbitPlanner.gd), and [runtime](../../scripts/integration/mission_runtime.gd).

## Fields and exact meaning already available

| Evidence | Native producer output | KE2 use and boundary |
| --- | --- | --- |
| Terminal status | `phase`, nullable `run_status`, `step_index`, `total_steps`, `terminal_reason` | Completion is `finished` / `completed` at exactly `total_steps`. Abort is `finished` / `aborted` and preserves current progress/reason |
| Run identity and snapshots | `run_id`, `mission_id`, `config_snapshot`, `scenario_snapshot`, `scenario_id` | Bind evidence to the launch setup. Here `scenario_id` equals the orbit preset ID |
| Stable ordered events | `event_log`, `next_event_sequence`, `event_id` formatted as `evt_%03d`, plus run/mission IDs | Preserve array order and identify an event by run plus event ID. Blocked requests also allocate IDs |
| Accepted versus blocked | Reply `ok` and `allowed`, event `type: action_accepted` / `code: ACTION_ACCEPTED`, or `type: action_blocked` with a specific code | `ok: true` can accompany `allowed: false`. Count an accepted operation from its event semantics |
| Step identity | Accepted event `step_index` is the requested pre-action step. Returned state advances by one. Blocked requests retain the step | Use event step for timing, visibility, contact, and revolution mapping |
| Returned MB | State cumulative `returned_data_mb`; accepted Transmit event `data_transmitted_mb` and `delta_returned_data_mb` | Event values agree in current code. Deduplicate qualifying positive Transmit steps within the matching run |
| Capture target and amount | Accepted Observe event `target_id`, `data_added_mb`, `delta_observations`; state `observations_by_target` | Select the configured target and successful capture events for Weather visits |
| Revolution identity | Planner steps contain zero-based `orbit_index` and `step_in_orbit` | Native events/state omit those fields. Current planner uses `int(event_step / steps_per_orbit)` and modulo; confirm that mapping with HPC |
| Packet completion | State `data_packets`, `returned_data_by_target_mb`, `observations_delivered_by_target` | FIFO packets hold `target_id` and `remaining_mb`. Complete deliveries increment only when a packet remainder drops below the engine's `1e-8 MB` tolerance |
| Battery and storage samples | Every returned state supplies `energy_wh`, capacity, `stored_data_mb`, and storage capacity. Accepted events supply energy/data deltas and generated/consumed Wh | Keep initial and post-request frames for proposed extrema. Native events omit an absolute `energy_wh` after-value |
| Scenario timing/version | `scenario_snapshot.scenario_version`, selected orbit's `steps_per_orbit`, `step_duration_hours`, sunlight/contact/target windows | Use the actual snapshot and matching orbit. The existing authored presets use ten steps per revolution |

On a successful Observe, exactly one observation and one target-labelled packet are added. A selected target's capture count and returned MB are independent of its completely delivered-observation count. Newly initialized target maps are empty and entries appear as activity occurs. In a genuine initialized native state, an absent target key in an existing map represents zero activity. Confirm legacy or incomplete-input handling with HPC; an unavailable whole map cannot establish zero delivery.

An accepted request updates resources, advances the step, and refreshes lighting/contact flags for the next step. Its returned flags therefore describe the next opportunity. A successful transmission at step 7 can return a state at step 8 with `in_ground_contact: false`. Use its accepted event and the step-7 schedule as evidence.

The final accepted request may emit both its accepted-action event and a separate `MISSION_FINISHED` event at `total_steps`. Aborts emit `MISSION_ABORTED` with a recorded reason. Count qualifying actions from action events. Repeated rejection attempts at one step have different IDs and zero resource deltas.

## Existing trace excerpt

The [portable JSON excerpt](evidence/hpc-existing-trace-excerpt.json) is extracted from an existing [local stock-catalog provider-integration record](../../exports/check-evidence/ke3_power_launcher_check/power-a.json). Its generator is [the existing power/launcher check](../../tests/ke3_power_launcher_check.gd). This planning task inspected that record and copied selected values. The source record's generator revision is absent, so the excerpt records it as null and pins the inspected file with SHA-256.

Source SHA-256 is `1424d1a62f0ce30adcdcef266f0688971234e3426dff3384f9cd8bb5ca847b57`.

The source run is `ke3_stock_power8_a` in mission `ke3_stock_power_acceptance`, using `high_inc`, the advanced instrument's 24-MB packets, and the fast radio. Its configured Imaging goals are eight captures and 192 MB over nine orbits. The record contains 95 events and 95 frames. The row count happens to match here; a terminal request can contain two events in one frame.

| Event | Requested step | Actual event | Data result | Recorded state after request |
| --- | --- | --- | --- | --- |
| `evt_001` | 1 | Accepted Observe of `equator` | Adds 24 MB and one capture | State step 2, stored 24 MB, delivery map empty |
| `evt_007` | 7 | Accepted Transmit | Returns `19.333333332` MB | State step 8, packet remainder `4.666666668` MB, delivery map still empty |
| `evt_008` | 8 | Blocked Transmit, `NO_LINK_WINDOW` | Zero deltas | State remains step 8 with the same resources |
| `evt_011` | 10 | Accepted Transmit | Returns remaining `4.666666668` MB | State step 11, cumulative return 24 MB, `equator` complete-delivery count becomes 1 |
| `evt_094` | 90 | `MISSION_FINISHED` | Terminal notification | Final state is completed at step 90 of 90 |

The terminal record has seven captures, 168 MB returned, seven complete equator deliveries, and an empty packet queue. Its Imaging evaluation is `partial` with score `88`. Thus engine completion and goal completion remain distinct facts.

The planner/snapshot supports deriving revolution 0 for capture step 1 and revolution 1 for Transmit step 10. The derived minimum energy across initial and post-request frames is `0.0 Wh`, and maximum stored data is `24.0 MB`. HPC still needs to agree the sampling convention for published A/B measures.

An older tracked [HPC/KE3 trace](../hpc-ke3-ops-trace-v0.2.json) is also available. It completes at step 60 with one capture and `7.7333333328` MB returned, but omits the newer per-target delivery maps and packet queue in its terminal projection. Keep that limitation visible when using historical packets.

## Communication test payload proposal

The plan's Communication teaching goal can reuse Observe to generate a test payload with the selected instrument's normal access, capture-limit, energy, and storage rules. `instrument_basic` supplies 12 MB per accepted Observe. Actual ground reception through subsequent accepted Transmit events then supplies the count and returned-data measures.

The [00.2 config handoff](ke1-se-config-handoff.md) proposes one capture, two positive contact steps, 12 MB, and three orbits. With current `low_eq` / `equator` windows and the basic radio, a candidate action plan is Observe at step 2, Transmit at steps 8 and 18, and Power-save otherwise through step 29.

Source-derived arithmetic gives `48 MB/hour * 0.1538888889 hours = 7.3866666672 MB` capacity per contact step. A 12-MB packet would drain as `7.3866666672` MB and `4.6133333328` MB over those two positive steps, if the actual run accepts the requests. These values are a planning hypothesis; request the real stock-design trace from HPC.

A candidate count-only shortfall uses that one 12-MB packet with the fast radio. Its contact-step capacity exceeds 12 MB, so a single accepted transmission can return the whole payload while producing only one qualifying step. Ask HPC to verify that isolation under the chosen configuration and policy. More radio capacity can change how many positive steps the goal records.

The current production registrations/mapping still support Imaging/Survey, with Survey evaluation pending. A replay using existing Imaging inputs can demonstrate the mechanics before agreed new-objective integration. Label that result as an Imaging mechanics/proxy run. New Communication setup, field rules, instrument support, and reports require the coordinated handoff.

## Missing native fields and decisions for HPC

| Missing field or unconfirmed semantic | Why KE2 needs it | Existing evidence or requested action |
| --- | --- | --- |
| Event-level revolution index / step-in-revolution | Count Weather visits and handle boundary steps accurately | Planner already computes them. Confirm deriving from accepted-event step and snapshotted timing, or emit agreed fields |
| Published qualifying-contact or visit counters | New objectives need explicit actual counts | Existing accepted events support derivation. Agree canonical event fields and duplicate/conflict handling before exposing new report fields |
| Explicit delivery-completion events and stable packet IDs | Per-packet causal references or direct delivery-to-event attribution | Current maps, FIFO queue, and frame differences support completion tracking. Confirm their sufficiency, or define added identifiers/events if required |
| Complete target maps in older exported terminal projections | Missing maps cannot prove zero deliveries | Native states contain sparse maps. Historical projections may omit them. Confirm adapter/error handling and absent-key semantics |
| Published battery/storage extrema and sampling definition | Compare A/B battery minimum and storage peak | Full frames support derived values. Agree initial/terminal inclusion, post-clamp state boundaries, and handling of unavailable samples |
| Explicit simulation/catalog implementation versions | Reliable A/B matching when source data or engine behavior changes | Scenario version and snapshots exist. HPC/SE should agree version IDs or fingerprints and store them with saved A |
| Native action policy/request log | Distinguish requested decisions from hardware-limited outcomes | Engine event log records requests; runtime stores policy and frames. HPC/SE should agree enough requested-action and policy-version evidence for comparisons |
| New-objective stock success/shortfall traces | Freeze achievable thresholds and verify the evaluator through actual producers | Provide new configs with KE1, or labeled mechanics/proxy traces while fields are being agreed |

Current authored contacts are isolated steps, `[8]` for `low_eq` and `[0, 7]` for `high_inc`. Two positive steps in a continuous contact window require an explicitly authored test scenario or labeled fixture to exercise that edge case. Current no-data Transmit requests are blocked with `NO_DATA`; accepted zero-MB entries should be handled in evaluator fixtures according to the agreed evidence contract.

## Request to share with HPC

Please review the field map and excerpt above and supply the following handoff.

1. Confirm accepted-event semantics, the canonical returned-MB delta, zero-based revolution mapping, sparse delivery-map handling, completion tolerance, and A/B resource sampling. Give exact field names and a real excerpt where additions are needed.
2. With KE1, provide feasible stock success and isolated-shortfall configs and traces for Communication and Weather. For Communication, exercise the proposed three-orbit, two-positive-step, 12-MB target. For Weather, demonstrate two distinct accepted-capture revolutions for the selected target plus 12 MB, and a sufficient-data shortfall confined to one revolution.
3. Provide Arctic Ice and valid two-target Survey traces. Include a partly returned selected-target packet and an aggregate-goals-met case where one selected target lacks a complete delivery, followed by a complete-delivery case. Preserve trace inputs and action plans for reproducibility.
4. Include matching evidence for both existing Imaging presets so the full package covers all five named presets. Record the actual configured goals and success/shortfall outcomes.
5. For each record include run/mission identity, config/scenario/catalog snapshots or agreed fingerprints, generator revision, validation verdict, ordered full events, initial and post-request resource/packet samples, requested actions or policy identity/version, terminal state, expected qualifying counts, and expected MB.
6. Identify the unchanged conditions for candidate A/B runs and any hardware-dependent accepted-action differences. Coordinate saved-record fields with SE. When an edge case uses a custom schedule or fixture, label it.

The request is prepared for the user to share. Owner confirmation and new-objective traces remain pending in [progress](progress.md).

## Verification and replay

This task used source inspection, existing local integration evidence, and Python integrity/accounting checks. It executed no new simulation. The JSON excerpt retains exact selected source values and labels its derived extrema. Check commands used `python -` for extraction/validation and `git diff --check` for tracked changes. A simple portable JSON check is available below.

```powershell
python -m json.tool docs/expansion-plan/evidence/hpc-existing-trace-excerpt.json > $null
git diff --check
```

To regenerate the source evidence later, run the existing checker from the repository root with the confirmed engine. This command is recorded for replay and was not executed during this planning task.

```powershell
$orbitGodot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $orbitGodot --version
& $orbitGodot --headless --path . --script res://tests/ke3_power_launcher_check.gd -- 'D:\orbitbridge-mission-architect\exports\check-evidence\ke3_power_launcher_check'
```
