# OrbitBridge: Mission Architect - Team Agreement

**Revision:** v0.1-draft  
**Status:** Proposed for review; no team approvals recorded  
**Prepared:** 14 November 2026  
**Confirmed setup:** Godot 4.7.2; kickoff 09:00 Asia/Rangoon; assistant checks successful, as confirmed by the user

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

Current repository settings use Forward Plus and name Windows as primary delivery. The earlier proposal used a browser target. **This document does not change project.godot.**

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

Proposed shared-state owner: SE coordinates the scene-transition/controller entry point with HPC. Confirm this before implementation.

## 4. Shared names, units, and rules

| Quantity | Agreement proposed for v1 |
| --- | --- |
| Mass | Integer grams; field names end in `_g` |
| Power | Watts; `_w` |
| Energy | Watt-hours; `_wh` |
| Time step | Hours; explicit `step_duration_hours` in the scenario |
| Data | MB consistently throughout catalogs, simulation, goals and UI; `_mb` |
| Cost / budget | Integer illustrative credits; `_credits`, not real-world prices |
| Counts / indices | Nonnegative integers; required observations and duration are positive |
| Component / preset IDs | Stable strings; one agreed ID vocabulary across modules |
| Numeric validity | Finite values; no silent parsing of strings or truncation of fractions for integer fields |
| Errors | Stable code plus plain explanation and suggested correction |

Use `instrument_id`, not a mixture of camera_id, payload_id, and instrument_id. Use `budget_credits` consistently. Names are proposals until this revision is approved.

The UI displays readiness and simulation results; it does not calculate its own competing verdict. Game logic can be called without rendering scenes. Validation does not mutate its inputs. No network requests are needed during a run.

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

Required metrics when the design resolves correctly: `total_mass_g`, `total_cost_credits`, `baseline_power_w`, `solar_generation_power_w`, `battery_capacity_wh`, `initial_energy_wh`, `storage_capacity_mb`, `data_per_observation_mb`, and `downlink_mb_per_step`.

Proposed readiness rules:

- Sum all modeled spacecraft mass once. Exclude launcher mass. Bus mass excludes separately selected subsystems.
- For the sample CubeSat 101 1U profile, mass must be **strictly below 1330 g**. Return actual mass, threshold, comparator `<`, pass/fail, profile ID, and source ID `cubesat_101_1u_sample`.
- Exactly 1329 g passes this mass check; 1330 g and 1331 g fail. Other profiles use their own rules.
- Total spacecraft-plus-launch cost must be less than or equal to budget.
- Apply the selected launcher's orbit-specific payload capacity and launcher/profile/orbit compatibility independently of the sample mass check.
- Require the selected orbit's agreed static target suitability. HPC separately handles actual observation windows.
- **Proposed simplified power gate for team review:** battery capacity and initial energy are positive, and sunlit solar generation is at least baseline load. This is a conservative gameplay rule, not a general physical requirement. It does not guarantee enough energy for observations, transmissions, or eclipse. HPC and KE1 must agree this rule before implementation.

An unresolved required check is not a pass. SE disables Launch when `ready_to_launch` is false and shows the actual issues. HPC must not start a run from a design that failed readiness.

Source evidence: [NASA CubeSat 101](https://www.nasa.gov/wp-content/uploads/2017/03/nasa_csli_CubeSat_101_508.pdf), Appendix C, item 6, printed p.79 / PDF p.87. An offline copy is in the project at `docs/references/NASA_CubeSat_101.pdf`. Other component values and game limits are illustrative unless individually sourced.

## 7. MissionState and Event: HPC to operations UI

HPC documents the actual entry-point names before the interface freeze. Proposed responsibilities: initialize a validated mission and scenario; apply one requested action; return the next state and new events.

| State field | Proposed meaning |
| --- | --- |
| schema_version | Integer 1 |
| scenario_id | Identifies the fixed scenario used for replay |
| step_index / total_steps | Current zero-based step and run length |
| phase | `operating` or `finished`; pre-launch readiness stays outside the run |
| energy_wh / battery_capacity_wh | Current battery energy and its capacity |
| stored_data_mb / storage_capacity_mb | Current stored data and capacity |
| returned_data_mb | Cumulative data successfully received on the ground |
| observations_completed | Cumulative successful captures |
| available_actions | Availability and blocked reason for `observe`, `transmit`, `power_save` |

Scenario metadata includes `step_duration_hours`, `steps_per_orbit`, sunlit/eclipse assumptions, target access and ground-contact windows. HPC owns the values; KE1 consumes the compatibility fields needed for readiness. Keep all per-step rates tied to that same step duration.

Every event provides `step_index`, `type`, `code`, a readable `message`, and actual observation/energy/data changes where relevant. The UI reads these events; KE2 uses them as evidence for feedback.

Proposed action behavior for approval:

- `observe`: only succeeds with target access, sufficient energy, and enough storage; success increments captured observations and adds data.
- `transmit`: only succeeds in a ground-contact window with sufficient energy and stored data; only actually transmitted MB increases returned data.
- `power_save`: generates no science data, applies baseline/solar accounting, and advances time.
- A rejected action returns an `action_blocked` event, applies no resource changes, and does not advance the step. The player can choose power_save to advance time. HPC/KE3 must approve this time behavior.
- An accepted action advances one step. Reaching total_steps finishes the run. Energy and stored data remain within bounds; data is never falsely returned outside a contact window.
- Record reasons for unsuccessful science opportunities. A warning is not proof of the cause of a failed mission.

HPC documents the exact energy-update order and action-cost equations alongside the simulator. The agreed order must be deterministic and tested; it is not inferred by the UI.

## 8. MissionReport: KE2 to debrief

**Inputs:** the original config, final state, and full event history. **Consumer:** KE3/results UI.

| Report field | Proposed meaning |
| --- | --- |
| schema_version | Integer 1 |
| status | `success`, `partial`, or `failed` |
| observations_completed / required_observations | Captured count and player-selected target |
| returned_data_mb / required_returned_data_mb | Returned amount and player-selected target |
| observation_completion_ratio | Captured count / target, capped at 1 |
| data_return_completion_ratio | Returned MB / target, capped at 1 |
| score | Proposed rounded 0-100 score defined below |
| root_causes | Evidence-based cause records with event step/code where applicable |
| next_experiment | One concrete change the player can try |
| source_ids | Sources actually used in the run/feedback |
| comparison | Optional comparison with another attempt; null when unavailable |

Proposed outcome rule: success requires both observation and returned-data targets. Otherwise partial means at least some captures or returned science data; failed means neither. Invalid pre-launch designs do not receive a completed-mission report or score.

Proposed score for KE2 approval: `round(100 * min(observation_completion_ratio, data_return_completion_ratio))`. Status and score are separate: partial progress can round to zero. If the team chooses another scoring rule, write it down here before implementing it.

Retry uses the same scenario conditions and preserves the mission requirements unless the player explicitly changes them. A/B comparisons identify the changed design/action and measured outcome; they do not invent explanations unsupported by events.

## 9. Minimal handoffs and acceptance checks

| Owner | Handoff | Acceptance evidence after kickoff |
| --- | --- | --- |
| KE1 | Config/schema, catalogs, readiness result, valid/overweight fixtures | Strict mass boundaries, budget, bad IDs, profile switching, deterministic output |
| HPC | State/event shape, scenario assumptions, trace | Observation, downlink, blocked action, bounded resources, repeatable replay |
| KE2 | Report shape, labels, source credit and next-experiment text | Success/partial/failure examples match the agreed goals |
| SE | Setup/readiness screen and launch control | Selections persist; metrics update; invalid design cannot launch |
| KE3 | Operations/debrief/retry scenes | Actual events drive the HUD; result and retry use the same mission/scenario |

Freeze interface decisions by the proposal's Saturday 10:30 milestone. KE1's first fixture/validator handoff is planned by 13:00; the first joint config-to-results integration is planned for 16:30. These are team planning milestones, not verified organizer requirements.

## 10. Changes after agreement

When changing a field, unit, enum, method, or rule: identify affected producers/consumers, agree the change with them, update this document and contracts.md, update examples/tests, and integrate the change together. Do not silently rename a field in only one module.

Use small changes. In the same checkout, Codex and Antigravity take turns on shared files. Do not overwrite another member's unfinished work. Preparation of this document does not authorize pushing, publishing, or sending messages to teammates.

## 11. Decisions to resolve before signing v1

| Decision | Proposed answer / current fact | Required reviewers | Actual decision |
| --- | --- | --- | --- |
| Keep browser delivery possible during development? | Final format can wait; proposed early Compatibility/browser-feature check with SE | SE + KE3 + team | PENDING |
| Config names, ranges, units and component IDs | Sections 4-5 and contracts.md | KE1 + SE + HPC + KE2 | PENDING |
| Separate launcher and profile selections? | Yes, separate IDs | KE1 + SE | PENDING |
| Static power readiness gate | Simplified rule in section 6 | KE1 + HPC | PENDING |
| Target suitability, step duration and shared orbit IDs | HPC authors scenario/orbit metadata; explicit hours per step | KE1 + HPC | PENDING |
| Rejected actions advance time? | Proposed no; power_save advances time | HPC + KE3 + KE2 | PENDING |
| Captured versus fully delivered observations | Proposed captures plus independent returned-MB goal | HPC + KE2 + KE1 | PENDING |
| Outcome labels and score | Proposed formulas in section 8 | KE2 + KE3 | PENDING |
| Shared scene/controller state owner | Proposed SE coordinates with HPC | SE + HPC + KE3 | PENDING |
| Source record and visible mass credit | Source locator and rule in section 6 | KE1 + KE2 + SE | PENDING |

## 12. Team approval

Each member records their own approval of the same revision. Changes requested must be resolved before the agreement is marked AGREED. No approvals are pre-filled.

| Role | Member name | Decision: agree / changes requested | Approved revision | Date/time | Notes |
| --- | --- | --- | --- | --- | --- |
| KE1 | | PENDING | | | |
| HPC | | PENDING | | | |
| KE2 | | CHANGES REQUESTED | PENDING | 2026-11-14 09:20 Asia/Rangoon | Reviewed v0.1-draft; see KE2 review below. Final approval pending resolution and review of the revised agreement. |
| SE | | PENDING | | | |
| KE3 | | PENDING | | | |

**KE2 review of v0.1-draft - reply to KE1**

KE2 agrees with the ownership split, consistent names and units, launch-time configuration snapshot, and separation of readiness validation from mission evaluation. Successful captures and data received on Earth are separate goals; stored data must never count as returned data. The following requests are review proposals, not approved changes to sections 4-11.

1. **Section 8 - score:** replace the minimum-ratio proposal with the equal-weight average of capped completion ratios: `score = round_half_up(100 * (observation_completion_ratio + data_return_completion_ratio) / 2)`. Round once with .5 rounded up, preserve raw actuals, and derive status from actuals versus targets. Both targets remain necessary for success. With targets of 3 observations and 30 MB, actuals of 3/10 should score 67, and 3/0 should score 50. With targets of 4 observations and 30 MB, actuals of 3/30 should score 88. This matches KE2's planned rubric and tests; the current minimum formula gives 33, 0, and 75 respectively. KE2 and KE3 must confirm the final rule.

2. **Sections 7-8 - run identity, termination and errors:** add `run_id`, `mission_id`, and `run_status` to the terminal input and report. Keep report `status` values `success`, `partial`, and `failed` for evaluation outcomes; proposed terminal `run_status` values are `completed` and `aborted`. Proposed abort policy: preserve counters and the recorded abort reason, return `status: failed` and `score: null`, and display "Mission aborted" even if targets were reached. Define an explicit evaluation error dictionary for missing, malformed, nonfinite, or nonterminal input; do not present these errors as completed failed missions. Invalid pre-launch designs remain KE1/Builder concerns. Confirm with HPC and KE3.

3. **Section 7 - event evidence:** freeze an event dictionary with `event_id`, `step_index`, `action`, `type`, `code`, and `message`, plus named resource-change fields and units where relevant. HPC must confirm code/action semantics, including candidate codes `NO_LINK_WINDOW`, `LOW_BATTERY`, `STORAGE_FULL`, and `TARGET_NOT_VISIBLE`. Define event ordering, step boundaries, and whether a finished state's step index equals `total_steps`. Multiple blocked actions can share a step under the current proposal, so step alone cannot identify evidence.

4. **Section 8 - feedback and empty states:** define each `root_causes` entry, for example `code`, `segment`, `evidence_event_ids`, and `explanation`. Without supported evidence, return `root_causes: []`, a neutral report explanation, and a concrete `next_experiment`. Unknown or irrelevant codes must not break evaluation or produce invented causes. A blocked action does not by itself prove the sole cause of the final shortfall. Keep `comparison: null` when unavailable and document nullable fields, including abort scores.

5. **Sections 4-5 - zero targets:** KE2 can accept positive-only observation and returned-data targets for the MVP. If adopted, KE1 and KE2 must both reject zero targets, and KE2's earlier inactive-zero-target proposal and test expectations must be updated. Validation and evaluation must use the same policy; record it explicitly before implementation.

6. **Sections 7-8 - lifecycle and retry:** assign SE/controller responsibility for publishing one report per `run_id`; duplicate terminal notifications or reopening Results must not advance retry history. Retain immutable snapshots of scenario identity/version, mission requirements, duration, selected parts, and action history. Retry clears live counters/events and starts a new run ID while preserving an eligible baseline; New Mission clears the baseline. Define comparison eligibility, signed current-minus-previous deltas, and null-score handling. Changed targets or environmental conditions are different scenarios; multiple or unknown design/action changes support descriptive comparison, not a claim that one change caused improvement. Proposed policy excludes aborts from controlled comparisons.

7. **Section 6 - scenario-dependent downlink:** `downlink_mb_per_step` depends on HPC's scenario step duration. Specify how validation receives the selected scenario, or expose a rate with an explicit time unit and let HPC derive the per-step amount. Keep one authoritative calculation and document the units at both boundaries. Resolve with KE1 and HPC.

8. **Sections 3 and 9 - exact ownership, calls and tests:** record primary file owners and freeze KE2's evaluator input/output dictionaries and error behavior with HPC/KE3. Proposed KE2 files are `scripts/evaluation/mission_evaluator.gd`, optional splits `scripts/evaluation/mission_feedback.gd` and `scripts/evaluation/mission_comparison.gd`, `tests/test_mission_evaluator.gd`, and `data/nasa_sources.json`. Evaluation must be callable headlessly, deterministic, and preserve inputs. Acceptance checks must cover score boundaries, dynamic targets, stored versus returned data, invalid inputs, the agreed zero/abort policies, unknown or missing evidence, duplicate terminal notifications, and reset behavior. Optional comparison tests cover improvement, regression, changed scenarios, and absent baselines. Mass-boundary integration checks must use KE1's real validator rather than duplicate it.

**Documentation corrections requested:**

- `docs/contracts.md`, `docs/validation-plan.md`, and `docs/sources.md` are referenced but absent in the reviewed checkout. Mark them as planned or create them before treating them as authoritative.
- Section 6's claimed offline reference at `docs/references/NASA_CubeSat_101.pdf` is absent. The current local copy is `PDF files/nasa_csli_cubesat_101_508.pdf` in an ignored directory. Correct the location claim or coordinate adding the intended reference. Retain the strict sample-1U threshold and source ID `cubesat_101_1u_sample`, explicitly scoped to that educational profile.
- Replace "assistant checks successful" in the setup statement with the specific checks performed and their evidence, or remove that phrase.

**Other KE2 positions:** the proposed rejected-action behavior (no resource change and no time advance) is acceptable from KE2's perspective, subject to HPC/KE3 confirmation and deterministic event ordering. The simplified static power gate remains a KE1/HPC decision. Other members' approvals remain pending, and this review does not mark the agreement AGREED. Resolve these requests in the next revision and return it to KE2 for final approval.

**Agreement status:** DRAFT  
**Agreed revision:** PENDING  
**Recorded by / date:** PENDING
