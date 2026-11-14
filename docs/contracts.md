# OrbitBridge - Agreed technical contract v1

**Status:** AGREED, aligned to `team-agreement.md` revision `v1.0-agreed`.  
**Schema version:** `1`.  
**Approval record:** all five roles approved the source revision, recorded 14 November 2026 at 10:01 Asia/Rangoon. The user confirmed the agreement is fully agreed and requested this synchronization.

This document translates the [signed team agreement](team-agreement.md) into the shared implementation contract. The final decision table, agreed API signatures, examples, and signoff rows govern where the source retains older editorial words such as proposed or pending. The signed source is preserved by this synchronization. Interface changes after this revision follow its change process.

The [v1 example pack](contracts/v1-draft/README.md) is aligned to this revision. Its directory retains the earlier `v1-draft` name for existing links; its current status and agreement revision, not its directory name, identify the approved interface. Example payloads remain hand-authored documentation fixtures, not results of implemented game logic.

## 1. Ownership and entry points

| Owner | Owned files / responsibility |
| --- | --- |
| KE1 | `scripts/core/mission_validator.gd`, component/launch-profile/launcher catalogs, `tests/validation/`; config, design metrics and pre-launch readiness |
| HPC | `core/MissionStepEngine.gd`, legacy `core/MissionSimulator.gd`, `core/OrbitPlanner.gd`, orbit/scenario metadata; operation steps and events |
| KE2 | `scripts/evaluation/mission_evaluator.gd`, feedback/comparison splits if needed, evaluator tests, `data/nasa_sources.json`; outcomes, score and evidence-based feedback |
| SE | `scripts/MissionController.gd`, project shell/settings and setup/readiness screens; validation calls, snapshots, routing, one report per run and retry/reset |
| KE3 | Operations HUD, orbital view, debrief/results screens and retry interaction; displays state/events/reports |

Game logic is callable without rendering scenes. The UI does not calculate its own competing readiness verdict, simulation result, or mission score. Validation is deterministic and does not mutate the caller's config or catalogs. Local JSON is sufficient; no external backend or network request is required during a run.

## 2. Units and legacy boundaries

| Quantity | Public v1 representation |
| --- | --- |
| Spacecraft mass | Whole grams, `_g`; exclude launcher mass |
| Power | Watts, `_w` |
| Energy | Watt-hours, `_wh` |
| Time | Explicit `step_duration_hours` supplied by scenario metadata |
| Data | Decimal MB, `_mb`; `1000 KB = 1 MB` |
| Radio capacity | `downlink_mb_per_hour`; HPC derives step capacity by multiplying by `step_duration_hours` |
| Cost/budget | Whole illustrative credits, `_credits`; no real-world price claim |
| Counts and indices | Whole numeric values; positive goals and duration, nonnegative counters/indices |

The legacy HPC whole-run model may use `RunInput` with `brief`/`brief.policy`, `RunTrace`, Ws, and KB. Preserve it behind an explicit adapter. At the public boundary: `energy_wh = battery_ws / 3600.0`, `stored_data_mb = buffer_kb / 1000.0`, and `returned_data_mb = returned_kb / 1000.0`. Do not expose legacy units under v1 field names or silently reinterpret a per-step rate as an hourly rate.

Godot JSON parsing can produce floating-point values for integer semantics. Accept finite whole numeric values where appropriate and convert deliberately. Reject fractions for whole-value fields, booleans, numeric strings, nulls where disallowed, nonfinite values, and invalid ranges. Check arithmetic results before using them as bounds or totals.

## 3. MissionConfig

SE/controller produces the selected config. KE1 validates it; HPC consumes the current validated config; KE2 evaluates its requirements. Run and mission identities are passed through the run API and state, rather than added as unagreed required config fields.

Required top-level keys: `schema_version`, `mission`, `design`. `schema_version` is `1`.

| Field | Type and rule |
| --- | --- |
| mission.title | Trimmed nonempty string, maximum 80 characters |
| mission.objective | Stable objective ID; v1 starts with `imaging` |
| mission.target_region | One stable target ID; current agreed fixture target is `equator` |
| mission.required_observations | Whole numeric value 1-20; successful captures |
| mission.required_returned_data_mb | Strictly positive finite MB requirement |
| mission.duration_orbits | Whole numeric value 1-12 |
| mission.budget_credits | Strictly positive whole credit budget |
| design.bus_id | Exactly one valid bus ID |
| design.instrument_id | Exactly one valid instrument ID |
| design.solar_id | Exactly one valid solar option ID |
| design.battery_id | Exactly one valid battery ID |
| design.radio_id | Exactly one valid radio ID |
| design.storage_id | Exactly one valid storage ID |
| design.launch_profile_id | Selected rule profile; separate from the launcher |
| design.launcher_id | Selected launch service |
| design.orbit_id | Agreed current fixture IDs: `low_eq` or `high_inc` |

Every ID must resolve in the proper catalog category. The component and launcher labels in the examples are fixture labels; K06 creates actual catalogs. Those labels are not claims that a production catalog or its physical values already exists.

Captured observations and returned MB are independent requirements. Stored data does not count as returned data. The MVP does not claim that every image was fully delivered merely because a total MB threshold was reached. Both KE1 and KE2 reject zero observation targets, zero returned-data targets, and zero duration.

## 4. Catalog boundary and derived metrics

Physical components identify their category, ID, display name, `mass_g`, `cost_credits`, and source/assumption metadata. IDs are unique and slots must match categories. Bus mass/cost exclude separately selected subsystems; any fixed spacecraft allowance must be explicit and counted once.

| Catalog category | Additional fields / responsibility |
| --- | --- |
| Bus | `baseline_power_w`; includes the documented always-on load model |
| Instrument | `observe_power_w`, `data_per_observation_mb`, supported objectives |
| Solar | `generation_power_w` under the documented sunlit condition |
| Battery | `capacity_wh`, agreed initial-charge policy; derived initial energy stays within capacity |
| Radio | `transmit_power_w`, `downlink_mb_per_hour` in decimal MB/hour |
| Storage | `capacity_mb`; document whether its power is included in baseline |
| Launcher | `cost_credits`, supported profiles/orbits and orbit-specific payload capacity |
| Launch profile | Its own mass comparator/limit, source ID or illustrative assumption |
| Orbit/scenario | HPC owns preset assumptions, target suitability, step duration and runtime windows |

Mass is the sum of all modeled spacecraft parts and explicit fixed mass, excluding the launcher. Cost includes spacecraft parts and launch service. Operation energy and access windows belong to HPC. A positive sunlit power margin does not establish whole-mission energy sufficiency.

The agreed orbit/target vocabulary is `low_eq`, `high_inc`, and `equator`. The actual scenario values, compatibility matrix, component values and window tables are implementation data owned by their respective catalog authors. Do not invent real target access from an orbit's label or visualization.

## 5. ValidationResult

Public call: `validate(config, catalogs) -> ValidationResult`. Catalog loading remains outside the pure validation function.

| Field | Meaning |
| --- | --- |
| schema_version | Integer 1 |
| ready_to_launch | Boolean; true only when every required check passes and errors is empty |
| metrics | Object of resolved metrics, or null when invalid inputs prevent safe calculation |
| checks | Object keyed by the eight checks below |
| errors | Ordered array of blocking issues |
| warnings | Ordered array of nonblocking advice |

Metric keys: `total_mass_g`, `total_cost_credits`, `baseline_power_w`, `solar_generation_power_w`, `battery_capacity_wh`, `initial_energy_wh`, `storage_capacity_mb`, `data_per_observation_mb`, and `downlink_mb_per_hour`.

Retain the check-object layout from the referenced technical draft, in stable stage order: `input_schema`, `catalog_references`, `profile_mass`, `launcher_capacity`, `budget`, `launch_orbit`, `target_orbit`, `essential_power`. Every check has `status`, `passed`, and `message`. Status `pass` requires `passed: true`; `fail` requires false; `not_evaluated` requires null. An unresolved dependent check cannot authorize Launch.

Every issue has `code`, `field_path`, `message`, `suggested_fix`, and an optional `source_id`. Use the vocabulary in [reference-ids.json](contracts/v1-draft/reference-ids.json); order issues by stage then field. Invalid data produces structured issues rather than crashes, fabricated zero totals, or silent substitutions.

Readiness rules:

- The sample CubeSat 101 1U profile passes only when total modeled spacecraft mass is **strictly below 1330 g**. Its record exposes `total_mass_g`, `threshold_g: 1330`, `comparator: "<"`, `passed`, `profile_id`, and `source_id: "cubesat_101_1u_sample"`. 1329 g passes this check; 1330 g and 1331 g fail. Other profiles use their own rules.
- Budget and applicable launcher capacity use less-than-or-equal comparisons. Launcher/profile/orbit compatibility and target suitability remain independent checks.
- The agreed illustrative pre-launch power gate requires positive battery capacity and initial energy, with sunlit solar generation at least baseline load. Initial energy must also respect battery capacity. Equality of solar generation and baseline is allowed.
- This power gate does not prove energy sufficiency through eclipse or active science/downlink loads. HPC enforces runtime bounds. `power_save` can clamp energy to zero and continue; zero energy during operations is not a new pre-launch verdict.
- SE disables Launch on readiness failure, displays its issues, and revalidates the current config when Launch is requested. A passing mass check alone is insufficient. Editing a design invalidates its previous verdict.

Blocking vocabulary: `INVALID_SCHEMA`, `INVALID_VALUE`, `MISSING_COMPONENT`, `UNKNOWN_COMPONENT`, `WRONG_COMPONENT_CATEGORY`, `UNKNOWN_PROFILE`, `UNKNOWN_LAUNCHER`, `UNKNOWN_ORBIT`, `PROFILE_MASS_EXCEEDED`, `LAUNCHER_CAPACITY_EXCEEDED`, `BUDGET_EXCEEDED`, `LAUNCH_ORBIT_INCOMPATIBLE`, `TARGET_ORBIT_INCOMPATIBLE`, `ESSENTIAL_POWER_INFEASIBLE`.

Advisory vocabulary: `LIMITED_BATTERY_RESERVE`, `LOW_DOWNLINK_CAPACITY`, `HIGH_STORAGE_DEMAND`. An advisory must follow from actual model data; it is not proof of the cause of an unsuccessful run.

Source: [offline NASA CubeSat 101](references/NASA_CubeSat_101.pdf), Appendix C item 6, printed p.79 / PDF p.87. The strict rule applies to this educational sample profile, not universal CubeSat certification. Other values are illustrative unless individually sourced.

## 6. MissionStepEngine and MissionState

Agreed HPC API on `core/MissionStepEngine.gd`:

- `init_run(config: Dictionary, scenario: Dictionary, run_id: String, mission_id: String) -> Dictionary`: returns `{ "ok": true, "state": MissionState, "events": [] }` or `{ "ok": false, "error": { "code": String, "message": String } }`.
- `get_available_actions(state: Dictionary) -> Dictionary`: availability for `observe`, `transmit`, `power_save`.
- `request_action(state: Dictionary, action: String) -> Dictionary`: returns `{ "state": MissionState, "events": [Event, ...] }`.

These are the step-based interfaces; the legacy whole-run simulator remains behind its documented adapter. Avoid naming a script class `Engine`, which conflicts with Godot's native class. HPC aligns its candidate implementation; this document does not claim that code has been integrated or tested in this checkout.

| State field | Meaning |
| --- | --- |
| schema_version | Integer 1 |
| run_id / mission_id | Stable run and mission identifiers |
| scenario_id | Scenario/preset identity; examples use `high_inc` |
| step_index / total_steps | Current zero-based position and run length |
| phase | `operating` or `finished` |
| run_status | Null while operating; `completed` or `aborted` when finished |
| is_sunlit | Current lighting condition |
| in_target_access | Current target opportunity |
| in_ground_contact | Current contact opportunity |
| energy_wh / battery_capacity_wh | Energy and capacity in Wh |
| stored_data_mb / storage_capacity_mb | Stored amount and capacity in decimal MB |
| returned_data_mb | Data actually received on the ground |
| observations_completed | Successful captures |
| available_actions | Map of each action to `allowed`, nullable `blocked_code`, nullable `reason` |

HPC supplies `step_duration_hours`, `steps_per_orbit`, scenario identity/version and the documented lighting/access/contact assumptions. Derive radio step capacity from the hourly rate and actual step duration.

Rejected action requests emit `action_blocked` and change neither resources nor `step_index`. Accepted actions advance exactly one step. An accepted `power_save` applies baseline/solar accounting, generates no science, clamps energy at 0.0 Wh when baseline cannot be covered, and continues the run. It still respects the upper battery bound.

Natural completion is `step_index == total_steps`, `phase: "finished"`, `run_status: "completed"`. An abort preserves counters and its reason, uses a finished state with `run_status: "aborted"`, and is handled distinctly by evaluation. A rejected request is not an abort.

Only successful observations increment captured count and add data; require actual target access, energy and storage. Only actual transmissions during contact increase returned MB. Energy and stored data remain within their bounds. HPC documents/tests the deterministic update order and actual action equations.

## 7. Event

Required event fields: `event_id`, `step_index`, `action`, `type`, `code`, `message`, and named deltas where relevant. The agreed examples use `delta_energy_wh`, `delta_stored_data_mb`, `delta_returned_data_mb`, and `delta_observations`.

An event ID distinguishes repeated blocked requests at the same step. Events preserve deterministic ordering. The shared blocked vocabulary includes `NO_LINK_WINDOW`, `LOW_BATTERY`, `STORAGE_FULL`, and `TARGET_NOT_VISIBLE`. The blocked example has zero deltas in all four fields. The UI renders event reasons; KE2 cites actual event IDs as evidence.

## 8. MissionEvaluator, MissionReport and EvaluationError

Agreed call: `MissionEvaluator.evaluate_mission(config: Dictionary, final_state: Dictionary, events: Array, comparison_baseline = null) -> Dictionary`.

Success wrapper: `{ "ok": true, "report": MissionReport }`. Error wrapper: `{ "ok": false, "error": EvaluationError }`. An aborted but otherwise valid terminal run returns a report through the success wrapper; `ok` describes input/evaluation validity, not mission success.

Required report fields: `schema_version`, `run_id`, `mission_id`, `run_status`, `status`, `observations_completed`, `required_observations`, `returned_data_mb`, `required_returned_data_mb`, `observation_completion_ratio`, `data_return_completion_ratio`, `score`, `explanation`, `root_causes`, `next_experiment`, `source_ids`, `comparison`.

Both goals are strictly positive. Preserve raw actual counts/MB; cap only the completion ratios at 1. For a completed run:

- `success` requires actual captures and returned MB to meet both targets.
- Otherwise `partial` means some captures or returned science data; `failed` means neither.
- Score is `round_half_up(100 * (observation_completion_ratio + data_return_completion_ratio) / 2)`, with equal weight for the two goals. For these nonnegative scores, half-up means a .5 tie rounds upward. A score rounded to 100 does not override unmet actual requirements.

On abort: `run_status: "aborted"`, `status: "failed"`, `score: null`, and an explanation stating the mission was aborted, even if the two targets were reached. Preserve actual progress and ratios. Invalid pre-launch designs do not receive mission reports/scores.

Every root cause contains `code`, `segment`, `evidence_event_ids`, and `explanation`. Root causes are `[]` when no cause is supported by relevant events. The report-level `explanation` still provides a neutral summary; do not invent a hardware cause from missing/unknown/irrelevant events. `next_experiment` suggests one concrete change. `source_ids` list sources actually used.

`EvaluationError` has `code: String`, `field_path: String | null`, `message: String`, `suggested_fix: String`, `run_id: String | null`. Codes include `INVALID_EVALUATION_INPUT` and `NONTERMINAL_RUN_STATE`. Missing identities and top-level error locations may be null. Missing, malformed, nonfinite, zero-target or nonterminal inputs yield a structured evaluation error, not a completed failed mission. SE displays the correction without advancing result/retry history.

The example completed report has 3/4 captures and 30/30 MB: ratios 0.75 and 1.0, score 88, status partial. The example abort reached 4/4 and 30/30 but still has failed status and a null score.

## 9. Controller migration, lifecycle and comparison

SE migrates prototype `name`, `targets`, `observations`, `duration`, `budget`, and `components.payload` into the agreed schema. Multiple prototype targets require an explicit player selection; do not silently choose the first. Map payload selection to a valid catalog `instrument_id` and replace mock readiness with KE1's validator.

SE owns configuration snapshots, pre-launch validation, scene routing, one report per `run_id`, and retry/reset. HPC owns simulation; KE2 evaluates; KE3 displays HUD/debrief. Repeated terminal notifications and reopening Results must not add duplicate history entries.

Keep immutable snapshots of scenario identity/version, mission requirements, duration, selected parts and action history. Retry clears live counters/events and starts a new run_id while preserving the mission/scenario and eligible baseline. New Mission clears the baseline. Controlled A/B comparisons exclude aborts, require matching scenario/target conditions and controlled requirements/duration, report signed current-minus-previous deltas, and avoid single-cause claims when multiple choices changed. `comparison` is null when unavailable.

## 10. Frozen decisions versus implementation work

The signed v1.0 agreement resolves the public units, field vocabulary, separate launcher/profile selection, capture/data goal semantics, power gate, action timing, run/event identity, score/abort behavior, source credit and ownership. K01-K04 are already recorded complete in tasks.md.

Remaining implementation work includes KE1's actual catalogs/validator, HPC's real preset values/target matrix/step equations and legacy adapters, SE's prototype migration and branch configuration sync, and runtime integration tests. Those are implementation tasks, not a reason to relabel this contract as an unapproved draft. Do not claim another branch's scripts/tests were executed here.

Compatibility rendering is agreed, but the inspected local main project still declares Forward Plus/d3d12 while the agreement reports Compatibility on master. SE owns that sync and the early Web export check. This documentation/example synchronization does not modify project.godot or merge branches. Final Windows/Web packaging can be chosen at the first playable slice.

Change record for this synchronization: aligned with `v1.0-agreed`; replaced old example orbit/target IDs, replaced the public radio metric with MB/hour, added the four signed state/event/report payloads verbatim, documented agreed APIs and error wrappers, and added unit/rounding/abort/action-timing example checks. No production game behavior is implemented by these documentation fixtures.


## Local implementation extension: selectable missions and regions

Added at the user's request on 14 November 2026. This implementation addendum does not change the preserved signed team agreement or imply new teammate signoffs.

- `MissionConfig.mission.target_regions` is optional: an array of one or two unique registered IDs. When present, its first entry must equal `target_region`; every region must pass readiness. Omitted means the original single `target_region`.
- The integrated game scenario additionally registers `survey` as an imaging-instrument objective, plus `tropical_forest`, `equatorial_ocean`, `coastal_region`, `temperate_land`, `arctic_ice`, `antarctic_region`. The native IDs remain supported. New windows are explicitly illustrative and stored separately in `data/mission_scenarios.json`; the source HPC orbit file is unchanged.
- `imaging` retains aggregate captured-observation and returned-MB goals. `survey` additionally requires one fully delivered observation from every selected region. Required capture count must be at least the selected target count.
- HPC state additionally exposes `observations_by_target`, `returned_data_by_target_mb`, `observations_delivered_by_target` and `data_packets` (FIFO remaining-MB records). These fields extend the existing state without replacing aggregate counters. Observation events identify the chosen `target_id`; only actual transmitted MB increments returned totals and only exhausted packets count as complete deliveries.
- The step API, resource units, original profile mass rules and action/time semantics remain unchanged. The original single-target fixture suites remain the backward-compatibility baseline. KE2's scoring interface is not replaced by the UI's factual goal-progress summary.


### HPC validated initialization (refreshed owner implementation)

`MissionStepEngine.init_validated_run(config: Dictionary, ke1_catalogs: Dictionary, run_id: String, mission_id: String) -> Dictionary` validates the supplied config with KE1, constructs the scenario from that same catalog bundle and initializes only when readiness passes. Success retains the existing `ok/state/events` wrapper plus `validation_result`. Readiness failure returns `ok: false`, a `MISSION_NOT_READY` error and the actual `validation_result`. The lower-level `init_run` remains available for isolated tests. Active game Launch uses the validated entry point. This additive owner API does not change numeric catalog values or the preserved signed agreement.


### Optional next-step prediction (HPC bd51e55)

`MissionStepEngine.predict_next_step(state: Dictionary, action: String) -> Dictionary` returns `{ok: true, prediction: {...}}` for a well-formed state, including blocked actions, or the native `ok/error` wrapper for malformed state. Prediction includes action availability/reason, next index and terminal status, before/after resource values, energy generation/consumption/clamping, available storage and capture/data deltas. Blocked actions leave counters/time unchanged. It never modifies caller state, appends events or allocates event IDs. Prediction, eligibility and accepted execution share `_project_resources` accounting. SE retains its multi-target selection, FIFO packet attribution and Survey reservation logic. This addition does not add prediction controls to the UI.
