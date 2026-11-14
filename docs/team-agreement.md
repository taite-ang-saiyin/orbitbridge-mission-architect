# OrbitBridge: Mission Architect - Team Agreement

**Revision:** v0.2-SE-review-draft  
**Status:** SE review completed with changes requested; no team approvals recorded  
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

Repository inspection on 14 November 2026: `project.godot` explicitly selects `gl_compatibility` for desktop and mobile rendering, although its feature tag still says Forward Plus. A Windows D3D12 driver setting is present; it does not by itself establish an approved delivery target. The team must confirm the final export target. **This review does not change project.godot.**

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
| KE2 | | PENDING | | | |
| SE | Not provided | Changes requested | Not approved; reviewed v0.2-SE-review-draft | 14 November 2026 (review date; signature pending) | SE responsibilities accepted in principle; resolve section 13 before approval. Prepared at the user’s request; personal signature not recorded. |
| KE3 | | PENDING | | | |

**Agreement status:** DRAFT  
**Agreed revision:** PENDING  
**Recorded by / date:** PENDING


## 13. Completed SE role review — 14 November 2026

**Review outcome:** Suitable as a draft team agreement, with the changes below required before SE approval. This records the requested SE role review; it does not represent another member’s consent or a personal signature.

### SE responsibilities and handoff

SE will maintain the existing project shell, Mission Creator, Spacecraft Builder, readiness presentation, and launch control. SE proposes owning `scripts/MissionController.gd` and the setup/readiness scripts, with HPC owning simulation logic and KE3 owning operations/debrief presentation. Shared-file ownership and controller handoff still require those members’ agreement.

SE will consume KE1’s catalogs and validator through the agreed contract, display returned metrics/issues without a competing readiness calculation, invalidate readiness after edits, and revalidate on Launch. A successful launch passes a deep configuration snapshot to HPC. Every navigation route into operations must use the same launch guard. Retry preserves requirements and scenario unless the player explicitly edits them. SE coordinates export builds and complete-run testing with the team.

### Required changes and unresolved dependencies

| Item | SE review / requested resolution | Owner / confirmation needed |
| --- | --- | --- |
| Renderer and export | Correct the outdated Forward Plus statement (corrected above). Compatibility is already configured; a browser export remains unverified. Agree delivery targets and test actual exports before feature freeze. | SE proposes; KE3 + team confirm |
| Supporting contracts | `docs/contracts.md`, `docs/validation-plan.md`, and `docs/sources.md` were absent from the inspected checkout. Create and review them before interface freeze; references to them are planned deliverables, not existing evidence. | Contract producers/consumers; KE2 coordinates sources |
| Existing implementation | The shell and screens already exist as a prototype. Preserve that work and distinguish prototype/UI progress from production gameplay integration; kickoff wording must not imply the repository is empty. | SE + team |
| Schema migration | Current controller/UI use mock state such as `name`, `targets`, `observations`, `duration`, `budget`, and `components.payload`; section 5 proposes a different nested config. Agree an explicit adapter or migration, including multiple current targets versus one `target_region`, before integrating gameplay. | SE + KE1 + HPC + KE2 |
| Validator integration | Readiness currently uses `data/mock/SatelliteAdapter.gd`; prototype checks and authored warnings are not proof that the proposed KE1 validator contract is implemented. Agree callable names and fixtures, then replace mock readiness and verify all launch paths. | KE1 + SE |
| Controller handoff | Agree initialization, action, completion, report, and retry calls/signals, ownership of immutable config and mutable run state, plus failure behavior when initialization fails. | SE + HPC + KE3; KE2 for report |
| Time and milestone record | Confirm the kickoff date and whether the Saturday 10:30, 13:00, and 16:30 milestones are still applicable; record the chosen timezone with the date. Do not backdate approvals. | Team |
| Engine/source claims | The project feature tag identifies 4.7, not the installed patch version. Exact 4.7.2 and source-page claims remain inherited statements from the supplied draft, not independently verified by this SE review. Verify before final agreement. | SE for engine; KE1 + KE2 for sources |

### SE positions on section 11

SE supports the proposed config vocabulary/units, separate launcher/profile IDs, source credit in readiness, and controller ownership in principle. These are SE review positions only. Keep section 11 decisions pending until the listed reviewers confirm the same revision. Static power rules, action time semantics, and scoring remain with their designated reviewers.

### SE acceptance evidence required after integration

- Screen transitions preserve selections; invalid/missing IDs produce actionable field errors.
- Editing inputs invalidates prior readiness; Launch revalidates the current configuration and cannot be bypassed by navigation.
- A launched run retains its configuration snapshot independently of subsequent UI edits.
- KE1 fixtures drive readiness consistently, including strict 1329/1330/1331 g boundaries and budget failures.
- Operations, debrief, and retry preserve the agreed config/scenario handoff; the chosen export completes one full mission loop.

**SE member name:** Not provided.  
**SE approval:** Changes requested; signature and approval timestamp pending.  
**Team agreement status:** DRAFT; other roles and joint decisions remain pending.
