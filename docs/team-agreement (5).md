# OrbitBridge: Mission Architect - Team Agreement

**Revision:** v0.5-draft  
**Status:** Updated with KE2, KE3, HPC, and SE v0.4 reviews; concrete API signatures, error shape, and 4 example payloads added for final v1 signoff  
**Prepared:** 14 November 2026  
**Confirmed setup:** Godot 4.7.2 (user confirmed, including Mono/.NET locally); kickoff 09:00 Asia/Rangoon (proposal); Codex instruction check completed in session (Antigravity repository-scoped check pending)

The purpose of this agreement is to make the five members' work fit together. Each member reviews their responsibilities and the data they produce or consume, proposes corrections, and records approval in the final table. A prepared document does not count as team approval.

The working copy belongs in the project at `docs/team-agreement.md`. Supporting project documents are `docs/contracts.md`, `docs/validation-plan.md`, and `docs/sources.md`. This standalone review copy can be shared; record final decisions and approvals in the repository's working copy.

## 1. How to approve this agreement

1. Read the responsibilities and shared conventions.
2. Review every interface your code will use, including names, units, and failure behavior.
3. Resolve the decisions in section 11. Write the actual choice, owner, and date rather than assuming silence means agreement.
4. Update the supporting contract if names or behavior change. All five members approve the same revision.
5. Mark the revision AGREED when all approvals and required decisions are recorded. Later interface changes follow section 10.

This document is preparation. It does not mark gameplay implementation as started; the team still explicitly starts work at kickoff.

## 2. Scope and shared setup

The MVP follows one complete loop: define a satellite mission, choose components and launch/orbit options, check readiness, operate the satellite, inspect results, and retry with an engineering change.

| Item | Confirmed fact or proposed agreement |
| --- | --- |
| Engine | Godot 4.7.2, confirmed by the user |
| Language | Proposed: GDScript for all game scripts and plugins; no external backend needed |
| Editor edition | Standard or .NET is acceptable for the same GDScript-only project and exact engine version |
| Project | Use the existing team repository and project.godot; do not initialize a second project |
| Data | Proposed: local JSON catalogs and explicit scenario/preset data |
| Simulation | Proposed: deterministic step-based model; no random events in the MVP |
| Visual scope | Proposed: clear Control screens and a lightweight orbital view |
| Extra features | Proposed: add optional features only after the full loop works |

### Demo format can be decided later; compatibility needs an earlier check

The final presentation can be a Windows executable, browser demo, or both. The recommended decision point is the first working end-to-end slice, before feature freeze, leaving time to test the actual export. Waiting until all development is finished risks discovering unsupported features too late.

Repository inspection (14 November 2026): local `main` `project.godot` declares `config/features=PackedStringArray("4.7", "Forward Plus")` and `rendering_device/driver.windows="d3d12"` (no `gl_compatibility` setting is present in `main` `project.godot` yet; SE's review noted `gl_compatibility` in their inspected branch/copy). Both Windows and Web exports remain possible if the team switches `project.godot` to `gl_compatibility` and runs an early Web export check before feature freeze. **This document does not change `project.godot`.**

Note on supporting docs: `docs/contracts.md`, `docs/validation-plan.md`, `docs/sources.md`, and `docs/references/NASA_CubeSat_101.pdf` are present in KE1's local `orbitbridge-mission-architect` checkout and pending push/sync to remote `main` so all members have the same copy.

Proposed approach if both delivery options should remain possible: agree with SE to use GDScript and browser-compatible features, consider Compatibility rendering early, and try a small browser export at the first working slice. Choosing Compatibility also permits a Windows export; it does not commit the team to a browser submission.

Godot's current documentation requires Compatibility rendering for Web export; Forward Plus is not supported there. Godot 4 C# projects cannot currently export to Web. Source: [Godot Web export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

## 3. Who owns what

| Member | Produces / owns | Uses / coordinates with |
| --- | --- | --- |
| KE1 | Mission/config schema, component and launcher/profile catalogs, design metrics, readiness validator, validator tests | SE's selections; HPC's orbit metadata; KE2's source record |
| HPC | Orbit/scenario presets, observation/contact windows, step engine, energy/storage accounting, actions and events | KE1's validated config; provides state/events to KE3 and KE2 |
| KE2 | Goal evaluation, success/partial/failure status, score, evidence-based causes, learning suggestions, optional comparison, source-ledger coordination | Original config and HPC's final state/event history |
| SE | Existing project shell, Mission Creator, Satellite Builder, readiness UI, export coordination | KE1's catalogs/validator; shared state/controller; KE3's scene handoff |
| KE3 | Operations HUD, orbital view, debrief screen, retry interaction | HPC's state/events and action availability; KE2's report |

One primary owner per shared script or scene. Coordinate changes to another member's primary files. SE coordinates exports; all five members help test the complete run.

Proposed primary file ownership (confirm at v1 signoff):
- **KE1:** `scripts/core/mission_validator.gd`, `data/components.json`, `data/launch_profiles.json`, `data/launchers.json`, `tests/validation/`
- **HPC:** `core/MissionStepEngine.gd` (v1 per-step API), legacy `core/MissionSimulator.gd`, `core/OrbitPlanner.gd`, `data/orbits.json`
- **KE2:** `scripts/evaluation/mission_evaluator.gd` (optional splits `mission_feedback.gd`, `mission_comparison.gd`), `tests/test_mission_evaluator.gd`, `data/nasa_sources.json`
- **SE:** `scripts/MissionController.gd`, `project.godot`, Mission Creator / Satellite Builder / readiness UI scenes
- **KE3:** Operations HUD, orbital view, debrief/results UI, retry interaction

## 4. Shared names, units, and rules

| Quantity | Agreement proposed for v1 |
| --- | --- |
| Mass | Integer grams; field names end in `_g` |
| Power | Watts; `_w` |
| Energy | Watt-hours; `_wh` |
| Time step | Hours; explicit `step_duration_hours` in the scenario |
| Data | MB consistently throughout catalogs, simulation, goals and UI; `_mb` |
| Cost / budget | Integer illustrative credits; `_credits`, not real-world prices |
| Counts / indices | Nonnegative integers; `required_observations`, `required_returned_data_mb`, and `duration_orbits` are strictly positive (zero targets rejected by both KE1 and KE2) |
| Component / preset IDs | Stable strings; one agreed ID vocabulary across modules |
| Numeric validity | Finite values; no silent parsing of strings or truncation of fractions for integer fields |
| Errors | Stable code plus plain explanation and suggested correction |

Use `instrument_id`, not a mixture of camera_id, payload_id, and instrument_id. Use `budget_credits` consistently. Names are proposals until this revision is approved.

The UI displays readiness and simulation results; it does not calculate its own competing verdict. Game logic can be called without rendering scenes. Validation does not mutate its inputs. No network requests are needed during a run.

**HPC unit-adapter note (confirm decimal MB):** Existing migrated HPC scripts on `feature/hpc-simulator` serialize energy in watt-seconds (`Ws`) and data in kilobytes (`KB`), whereas the v1 contract uses `Wh` and decimal `MB` (`1000 KB = 1 MB`) at the UI/evaluator boundary. Preserve legacy `RunInput -> RunTrace` behind an explicitly documented adapter boundary (`energy_wh = battery_ws / 3600.0`, `stored_data_mb = buffer_kb / 1000.0`, `returned_data_mb = returned_kb / 1000.0`). Confirm with HPC before locking. No silent unit or field renames.

## 5. MissionConfig: setup screens to game logic

**Producer:** SE/controller. **Consumers:** KE1, HPC, KE2; KE3 reads the mission summary.

| Field | Proposed meaning |
| --- | --- |
| schema_version | Integer 1 |
| mission.title | Nonempty title; proposed maximum 80 characters |
| mission.objective | Start with `imaging`; expand only with working evaluation support |
| mission.target_region | Agreed target ID present in scenario/orbit metadata |
| mission.required_observations | Proposed 1-20 captured observations |
| mission.required_returned_data_mb | Positive finite amount of data that must reach the ground |
| mission.duration_orbits | Proposed 1-12 orbits; number of steps derives from the scenario |
| mission.budget_credits | Positive integer credit budget |
| design.bus_id | Selected bus |
| design.instrument_id | Selected instrument |
| design.solar_id | Selected solar option |
| design.battery_id | Selected battery |
| design.radio_id | Selected radio |
| design.storage_id | Selected storage |
| design.launch_profile_id | Selected sample/illustrative rule profile |
| design.launcher_id | Selected launch service |
| design.orbit_id | Selected orbit preset |

Every selected ID must exist in its expected category. A missing component is a blocking input issue, not a zero-mass component.

Proposed science semantics: `required_observations` counts successful captures. The returned-data requirement is a separate MB threshold. The MVP does not claim that every captured image was fully delivered merely because total returned MB is sufficient. KE2 must approve these labels and semantics.

The controller keeps the same configuration throughout readiness, operations, and evaluation. Editing a design invalidates its previous readiness result. On Launch, validate the current selection again and pass a snapshot of that configuration into the run.

**HPC integration note (pending contract freeze):** The migrated whole-run simulator on `feature/hpc-simulator` consumes a `RunInput` dictionary with `brief` (including `brief.policy`) and `design`, which differs from `MissionConfig` above. KE1, SE, and HPC must agree on a validated `MissionConfig`-to-simulator adapter and stable component/orbit IDs.

**SE prototype migration note (pending SE + KE1 + HPC + KE2 confirmation):** SE's existing prototype controller/UI (`scripts/MissionController.gd` and `data/mock/SatelliteAdapter.gd`) currently uses mock fields (`name`, `targets`, `observations`, `duration`, `budget`, `components.payload`). Agree an explicit adapter or migration to `MissionConfig` v1—including multiple current `targets` vs. one `target_region`—and replace mock readiness with KE1's validator.

## 6. ValidationResult: KE1 to Builder and launch control

Proposed call: `validate(config, catalogs) -> ValidationResult`.

| Field | Proposed meaning |
| --- | --- |
| schema_version | Integer 1 |
| ready_to_launch | True only when every required readiness check passes |
| metrics | Calculated design metrics; null when malformed inputs prevent safe calculation |
| checks | Individual pass / fail / not_evaluated results |
| errors | Ordered list of issues that block Launch |
| warnings | Ordered list of advice that does not block Launch |

Each issue includes `code`, `field_path`, `message`, `suggested_fix`, and optional `source_id`. Return issues in a stable order. Do not calculate a mission score here.

Required metrics when the design resolves correctly: `total_mass_g`, `total_cost_credits`, `baseline_power_w`, `solar_generation_power_w`, `battery_capacity_wh`, `initial_energy_wh`, `storage_capacity_mb`, `data_per_observation_mb`, and `downlink_mb_per_step` (or `downlink_mb_per_hour` if HPC derives per-step downlink from `step_duration_hours`—confirm one authoritative boundary with KE1 and HPC).

Proposed readiness rules:

- Sum all modeled spacecraft mass once. Exclude launcher mass. Bus mass excludes separately selected subsystems.
- For the sample CubeSat 101 1U profile, mass must be **strictly below 1330 g**. Return actual mass, threshold, comparator `<`, pass/fail, profile ID, and source ID `cubesat_101_1u_sample`.
- Exactly 1329 g passes this mass check; 1330 g and 1331 g fail. Other profiles use their own rules.
- Total spacecraft-plus-launch cost must be less than or equal to budget.
- Apply the selected launcher's orbit-specific payload capacity and launcher/profile/orbit compatibility independently of the sample mass check.
- Require the selected orbit's agreed static target suitability. HPC separately handles actual observation windows.
- **Proposed simplified power gate for team review:** battery capacity and initial energy are positive, and sunlit solar generation is at least baseline load. This is a conservative gameplay rule, not a general physical requirement. It does not guarantee enough energy for observations, transmissions, or eclipse. HPC and KE1 must agree this rule before implementation.

An unresolved required check is not a pass. SE disables Launch when `ready_to_launch` is false and shows the actual issues. HPC must not start a run from a design that failed readiness.

**HPC proposal (pending KE1 confirmation):** Accept the simplified solar-versus-baseline readiness check as an *illustrative prelaunch gate* only, not proof that energy will last through observations, downlinks, or eclipse. HPC still enforces runtime energy bounds during operations.

Source evidence: [NASA CubeSat 101](https://www.nasa.gov/wp-content/uploads/2017/03/nasa_csli_CubeSat_101_508.pdf), Appendix C, item 6, printed p.79 / PDF p.87. An offline copy is in the project at `docs/references/NASA_CubeSat_101.pdf`. Other component values and game limits are illustrative unless individually sourced.

## 7. MissionState and Event: HPC to operations UI

HPC documents the actual entry-point names before the interface freeze. Proposed responsibilities: initialize a validated mission and scenario; apply one requested action; return the next state and new events.

| State field | Proposed meaning |
| --- | --- |
| schema_version | Integer 1 |
| run_id / mission_id | Unique run identifier and mission identifier |
| scenario_id | Identifies the fixed scenario used for replay |
| step_index / total_steps | Current zero-based step and run length (confirm with HPC whether finished `step_index == total_steps`) |
| phase | `operating` or `finished`; pre-launch readiness stays outside the run |
| run_status | Terminal status when finished: `completed` or `aborted` (preserve counters and abort reason on abort) |
| energy_wh / battery_capacity_wh | Current battery energy and its capacity |
| stored_data_mb / storage_capacity_mb | Current stored data and capacity |
| returned_data_mb | Cumulative data successfully received on the ground |
| observations_completed | Cumulative successful captures |
| available_actions | Availability and blocked reason for `observe`, `transmit`, `power_save` |

Scenario and state metadata for HPC + KE3 orbital view includes `step_duration_hours`, `steps_per_orbit`, sunlit/eclipse state, target access, and ground-contact windows. HPC owns the values; KE1 consumes the compatibility fields needed for readiness. Keep all per-step rates tied to that same step duration.

Every event provides `event_id`, `step_index`, `action`, `type`, `code`, a readable `message`, and named observation/energy/data delta fields with units where relevant (`event_id` distinguishes multiple blocked actions on the same step). Candidate blocked codes: `NO_LINK_WINDOW`, `LOW_BATTERY`, `STORAGE_FULL`, `TARGET_NOT_VISIBLE`. HPC confirms event ordering and exact code/action semantics before v1 freeze. The UI reads these events; KE2 uses them as evidence for feedback.

Proposed action behavior for approval:

- `observe`: only succeeds with target access, sufficient energy, and enough storage; success increments captured observations and adds data.
- `transmit`: only succeeds in a ground-contact window with sufficient energy and stored data; only actually transmitted MB increases returned data.
- `power_save`: generates no science data, applies baseline/solar accounting, and advances time.
- A rejected action returns an `action_blocked` event, applies no resource changes, and does not advance the step. The player can choose power_save to advance time. HPC/KE3 must approve this time behavior.
- An accepted action advances one step. Reaching total_steps finishes the run. Energy and stored data remain within bounds; data is never falsely returned outside a contact window.
- Record reasons for unsuccessful science opportunities. A warning is not proof of the cause of a failed mission.

HPC documents the exact energy-update order and action-cost equations alongside the simulator. The agreed order must be deterministic and tested; it is not inferred by the UI.

**HPC baseline & proposed `MissionStepEngine.gd` (review draft):** Seven pre-existing HPC files were copied to `feature/hpc-simulator` (`core/MissionSimulator.gd`, `core/OrbitPlanner.gd`, `data/fixtures/hpc_catalog.json`, `data/fixtures/hpc_golden_radio_ab.json`, `tests/test_simulator.gd`, `tests/run_demo.gd`, `docs/HPC_INTEGRATION.md`). `MissionSimulator.simulate(run_input, catalog)` is a whole-run `RunInput -> RunTrace` API with events (`seq`, `slot`, `t_s`, `code`, `params`), currently has one orbit preset, and `tests/test_simulator.gd` fails on `RunInput brief missing policy` (while falsely printing "passed"—do not record as passed until fixed and rerun).

Proposed v1 step-based API on `MissionStepEngine.gd` (for HPC + SE + KE3 confirmation; units converted to `Wh` and decimal `MB` at boundary):
- `init_run(config: Dictionary, scenario: Dictionary, run_id: String, mission_id: String) -> Dictionary` (returns `{ "ok": true, "state": MissionState, "events": [] }` or `{ "ok": false, "error": { "code", "message" } }`)
- `get_available_actions(state: Dictionary) -> Dictionary` (returns availability and blocked reason for `observe`, `transmit`, `power_save`)
- `request_action(state: Dictionary, action: String) -> Dictionary` (returns `{ "state": MissionState, "events": [Event, ...] }`; rejected action emits `action_blocked`, changes no resources, and does not advance `step_index`; `power_save` advances 1 step—HPC confirms behavior when `power_save` cannot cover baseline energy, e.g. clamp at `0.0` or abort; reaching `step_index == total_steps` sets `phase = "finished"`, `run_status = "completed"`)

**Example 1 — Operating `MissionState` (proposed):**
```json
{
  "schema_version": 1,
  "run_id": "run_001",
  "mission_id": "mission_001",
  "scenario_id": "leo_sun_sync_500km",
  "step_index": 2,
  "total_steps": 12,
  "phase": "operating",
  "run_status": null,
  "is_sunlit": true,
  "in_target_access": true,
  "in_ground_contact": false,
  "energy_wh": 18.5,
  "battery_capacity_wh": 25.0,
  "stored_data_mb": 12.0,
  "storage_capacity_mb": 64.0,
  "returned_data_mb": 0.0,
  "observations_completed": 1,
  "available_actions": {
    "observe": { "allowed": true, "blocked_code": null, "reason": null },
    "transmit": { "allowed": false, "blocked_code": "NO_LINK_WINDOW", "reason": "No ground station contact in this step." },
    "power_save": { "allowed": true, "blocked_code": null, "reason": null }
  }
}
```

**Example 2 — `action_blocked` `Event` (proposed):**
```json
{
  "event_id": "evt_003",
  "step_index": 2,
  "action": "transmit",
  "type": "action_blocked",
  "code": "NO_LINK_WINDOW",
  "message": "Transmit blocked: no ground station contact window at step 2.",
  "delta_energy_wh": 0.0,
  "delta_stored_data_mb": 0.0,
  "delta_returned_data_mb": 0.0,
  "delta_observations": 0
}
```

## 8. MissionReport: KE2 to debrief

**Inputs:** the original config, final state, and full event history. **Consumer:** KE3/results UI.  
**Proposed call:** `MissionEvaluator.evaluate_mission(config: Dictionary, final_state: Dictionary, events: Array, comparison_baseline = null) -> Dictionary` (returns `{ "ok": true, "report": MissionReport }` or `{ "ok": false, "error": EvaluationError }`).

| Report field | Proposed meaning |
| --- | --- |
| schema_version | Integer 1 |
| run_id / mission_id | Identifies the evaluated run and mission |
| run_status | `completed` or `aborted` (aborts return `status: failed`, `score: null`, and `"Mission aborted"` even if targets were reached) |
| status | `success`, `partial`, or `failed` |
| observations_completed / required_observations | Captured count and player-selected target |
| returned_data_mb / required_returned_data_mb | Returned amount and player-selected target |
| observation_completion_ratio | Captured count / target, capped at 1 |
| data_return_completion_ratio | Returned MB / target, capped at 1 |
| score | Rounded 0-100 score (`null` on abort); see formula below |
| explanation | Report-level summary text (neutral fallback when `root_causes` is `[]`, or when events are missing/unknown/irrelevant) |
| root_causes | Evidence-based cause records (`code`, `segment`, `evidence_event_ids`, `explanation`), or `[]` when unsupported |
| next_experiment | One concrete change the player can try |
| source_ids | Sources actually used in the run/feedback |
| comparison | Optional comparison with another attempt (signed current-minus-previous deltas); `null` when unavailable |

**Proposed `EvaluationError` dictionary** (for missing, malformed, nonfinite, or nonterminal inputs—never presented as a completed failed mission):
`{ "code": String, "field_path": String, "message": String, "run_id": Variant }` (e.g., `INVALID_EVALUATION_INPUT`, `NONTERMINAL_RUN_STATE`).

Proposed outcome rule: success requires both observation and returned-data targets. Otherwise partial means at least some captures or returned science data; failed means neither. Invalid pre-launch designs do not receive a completed-mission report or score.

Proposed score (**KE2 + KE3 aligned**, pending final v1 signoff): `round_half_up(100 * (observation_completion_ratio + data_return_completion_ratio) / 2)`, preserving raw actuals and deriving `status` from actuals vs. targets (`success` requires both targets; aborted runs return `score: null`).

**Example 3 — Completed `MissionReport` (proposed):**
```json
{
  "schema_version": 1,
  "run_id": "run_001",
  "mission_id": "mission_001",
  "run_status": "completed",
  "status": "partial",
  "observations_completed": 3,
  "required_observations": 4,
  "returned_data_mb": 30.0,
  "required_returned_data_mb": 30.0,
  "observation_completion_ratio": 0.75,
  "data_return_completion_ratio": 1.0,
  "score": 88,
  "explanation": "Returned data target was met, but 1 of 4 required observations was missed due to blocked contact/energy windows.",
  "root_causes": [
    {
      "code": "LOW_BATTERY",
      "segment": "operations",
      "evidence_event_ids": ["evt_007"],
      "explanation": "Observation at step 6 was blocked because battery energy was below the required action cost."
    }
  ],
  "next_experiment": "Try a higher-capacity battery or use power_save before the target access window.",
  "source_ids": ["cubesat_101_1u_sample"],
  "comparison": null
}
```

**Example 4 — Aborted `MissionReport` (proposed):**
```json
{
  "schema_version": 1,
  "run_id": "run_002",
  "mission_id": "mission_001",
  "run_status": "aborted",
  "status": "failed",
  "observations_completed": 4,
  "required_observations": 4,
  "returned_data_mb": 30.0,
  "required_returned_data_mb": 30.0,
  "observation_completion_ratio": 1.0,
  "data_return_completion_ratio": 1.0,
  "score": null,
  "explanation": "Mission aborted: spacecraft power fell below survival threshold at step 9.",
  "root_causes": [],
  "next_experiment": "Increase solar generation or battery reserve to survive eclipse steps.",
  "source_ids": [],
  "comparison": null
}
```

Lifecycle, retry, and comparison rules (pending SE + HPC + KE2 + KE3 signoff): SE/controller publishes one report per `run_id` (duplicate terminal notifications or reopening Results must not advance retry history) and retains immutable snapshots of scenario identity/version, mission requirements, duration, selected parts, and action history. Retry clears live counters/events, starts a new `run_id`, and preserves mission requirements, scenario, and an eligible baseline; New Mission clears the baseline. Controlled A/B comparisons exclude aborts, require matching scenario/target conditions, and do not claim a single cause when multiple changes occurred.

## 9. Minimal handoffs and acceptance checks

| Owner | Handoff | Acceptance evidence after kickoff |
| --- | --- | --- |
| KE1 | Config/schema, catalogs, readiness result, valid/overweight fixtures | Strict mass boundaries, budget, bad IDs, profile switching, deterministic output |
| HPC | State/event shape, scenario assumptions, trace | Observation, downlink, blocked action, bounded resources, repeatable replay |
| KE2 | Report shape, labels, source credit and next-experiment text | Success/partial/failure examples, score boundaries, invalid inputs, aborts (`score: null`), zero-target rejection, stored-vs-returned data, determinism, input preservation, and duplicate-report/lifecycle checks |
| SE | Setup/readiness screen and launch control | Selections persist; metrics update; invalid design cannot launch |
| KE3 | Operations/debrief/retry scenes | Actual events drive the HUD; result and retry use the same mission/scenario |

Freeze interface decisions by the proposal's Saturday 10:30 milestone. KE1's first fixture/validator handoff is planned by 13:00; the first joint config-to-results integration is planned for 16:30. These are team planning milestones, not verified organizer requirements.

## 10. Changes after agreement

When changing a field, unit, enum, method, or rule: identify affected producers/consumers, agree the change with them, update this document and contracts.md, update examples/tests, and integrate the change together. Do not silently rename a field in only one module.

Use small changes. In the same checkout, Codex and Antigravity take turns on shared files. Do not overwrite another member's unfinished work. Preparation of this document does not authorize pushing, publishing, or sending messages to teammates.

## 11. Decisions to resolve before signing v1

| Decision | Proposed answer / current fact | Required reviewers | Actual decision |
| --- | --- | --- | --- |
| Keep browser delivery possible during development? | Final format can wait; proposed early Compatibility/browser-feature check with SE | SE + KE3 + team | SE + KE3 + HPC aligned: `gl_compatibility` is already set in `project.godot`; keep GDScript-only and run an early Web export check before feature freeze; confirm final delivery target. |
| Config names, ranges, units and component IDs | Sections 4-5 and contracts.md | KE1 + SE + HPC + KE2 | SE supports v1 vocabulary/units and requests explicit migration from prototype fields (`targets` vs. `target_region`, `components.payload`); HPC requests Wh/MB adapter over legacy Ws/KB (`brief.policy`). Confirm MB definition, IDs, and migration. |
| Separate launcher and profile selections? | Yes, separate IDs | KE1 + SE | SE supports separate IDs in principle; confirm with KE1 for v1 freeze. |
| Static power readiness gate | Simplified rule in section 6 | KE1 + HPC | HPC PROPOSAL (14 Nov): accept as illustrative prelaunch gate only; HPC retains per-action runtime energy checks. PENDING KE1. |
| Target suitability, step duration, downlink rate boundary, and shared orbit IDs | HPC authors scenario/orbit metadata; explicit hours per step; confirm `downlink_mb_per_step` vs. `downlink_mb_per_hour` boundary | KE1 + HPC | HPC PROPOSAL (14 Nov): two deterministic illustrative presets with documented windows and explicit `step_duration_hours`; orbit IDs, compatibility metadata, and downlink boundary still need KE1/HPC approval. |
| Rejected actions advance time? | Proposed no; power_save advances time (KE2 + KE3 support, pending HPC) | HPC + KE3 + KE2 | HPC PROPOSAL (14 Nov): rejected action emits `action_blocked`, no time/resource changes; `power_save` advances one step (aligns with KE2 + KE3). PENDING final v0.3 signoff. |
| Captured versus fully delivered observations & zero targets | Captures plus independent returned-MB goal; positive-only targets (KE1 + KE2 aligned, pending HPC) | HPC + KE2 + KE1 | HPC PROPOSAL (14 Nov): track captured observations separately from returned MB; never label a capture fully delivered from aggregate MB alone. PENDING KE1/KE2/HPC final signoff. |
| Run identity, abort policy, and event evidence schema | `run_id`, `mission_id`, `run_status`, `event_id`, abort `score: null`, candidate blocked codes | HPC + KE2 + KE3 + SE | PENDING |
| Outcome labels and score | Section 8 outcome rules; equal-weight `round_half_up` average (`score: null` on abort; both targets required for `success`) | KE2 + KE3 | KE2 + KE3 ALIGNED (14 Nov): confirm in v0.5-draft signoff. |
| Shared scene/controller state owner & retry handoffs | Proposed SE coordinates with HPC; one report per `run_id`; retry preserves requirements/scenario | SE + HPC + KE3 + KE2 | HPC PROPOSAL (14 Nov): SE owns controller/scene transitions; HPC owns pure-logic simulation state and action results; KE3 consumes API output (aligns with KE3). PENDING SE/KE2. |
| Source record and visible mass credit | Source locator and rule in section 6 | KE1 + KE2 + SE | PENDING |

## 12. Team approval

Each member records their own approval of the same revision. Changes requested must be resolved before the agreement is marked AGREED. No approvals are pre-filled.

| Role | Member name | Decision: agree / changes requested | Approved revision | Date/time | Notes |
| --- | --- | --- | --- | --- | --- |
| KE1 | | PENDING | | | |
| HPC | | CHANGES REQUESTED | Not approved; reviewed v0.4-draft | 2026-11-14 (time pending) | Agrees with HPC proposals in draft (Wh/MB adapter, `MissionConfig` adapter, 2 orbit presets, `MissionStepEngine.gd`, prelaunch power gate, blocked-action rules, SE controller ownership). Does not approve until remaining HPC decisions are locked: orbit IDs, downlink rate boundary, run/event schema, `power_save` low-energy behavior, energy-update order, and baseline test fix. |
| KE2 | | CHANGES REQUESTED | Not approved; reviewed v0.4-draft | 2026-11-14 09:43 Asia/Rangoon | Agrees with score, `run_status`/abort, positive-only targets, separate captures/returned MB, event IDs, causes, and retry/reset rules. Requests merged into v0.5-draft: `EvaluationError` dict & evaluator call, decimal `1000 KB = 1 MB` & downlink/step boundaries, report-level `explanation`, KE2 file ownership & test scope, and repo-sync/renderer factual notes. |
| SE | | CHANGES REQUESTED | Not approved; reviewed v0.4-draft | 2026-11-14 (review date; signature pending) | Agrees with direction and SE responsibilities (`scripts/MissionController.gd`, setup/readiness UI). Requests locking exact IDs/decimal MB/prototype migration (`targets` vs. `target_region`, `brief.policy`), initialize/action/report/retry API, simulation rules (`power_save` low-energy, energy-update order, finished step), joint choices, synced supporting docs, and updating all signoff references to the same revision (`v0.5-draft`). |
| KE3 | | CHANGES REQUESTED | Not approved; reviewed v0.4-draft | 2026-11-14 09:40 Asia/Rangoon | Supports most of v0.4 and accepts KE2's equal-weight score (both targets for success; `score: null` on abort), Wh/decimal MB at UI boundary, and SE routing/retry ownership. Requests exact HPC step-based API method names and 4 concrete example payloads (merged into v0.5-draft Sections 7–8) for final confirmation. |

**Agreement status:** DRAFT  
**Agreed revision:** PENDING  
**Recorded by / date:** PENDING
