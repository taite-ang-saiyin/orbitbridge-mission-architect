# B01 mapping to v1.0-agreed

Baseline: `C:\Users\Asus\Downloads\Telegram Desktop\team-agreement (7).md`, revision **v1.0-agreed**. The exact SHA-256 and its four JSON examples are in `verification/b01-inspection.json` / `b01-agreement-examples.json`; an unchanged evidence copy is `verification/b01-team-agreement-v1.0-agreed.md`.

The user's B01 request controls this work. The attachment is the requested interface baseline, not authorization to change branches/renderers, sign an agreement, publish, start another phase, or treat a planned kickoff as completed. Other chats were consulted as handoff evidence only; their proposed A05 instructions were not executed.

## Confirmation level

The preview-side paths and behavior below were confirmed by reading the local implementation. The v1-side names and semantics were confirmed against the attached agreement sections 4–8, its decisions, and Examples 1–4. **No v1 HPC/evaluator/controller implementation or payload emitted by an identified implementation commit is available in the inspected checkout.** Therefore every producer/SE implementation mapping and live integration check is **NOT TESTED**. Matching names in a document are not a live-provider pass.

The only available repository checkout is `C:\Workspace\OrbitBridge\orbitbridge-mission-architect`, clean `main` at `01e1d063244111b79939e06388a7d81be92af940`. HEAD contains only seven starter files and none of the requested contracts/provider/controller files. Remote `origin` advertises that same `main` commit only. The event integration revision and actual kickoff are unverified. Under B01's conditional instruction, no production context entry or adapter was wired.

## Context / mission / profile

| Preview implementation | Agreed v1 source / mapping | Evidence and remaining owner input |
| --- | --- | --- |
| `context.run_id`, also `state.run_id` and report run ID | Keep SE's active `run_id`; preserve `mission_id`, scenario identity and config snapshot | `presentation_session.gd` correlates preview envelopes. Agreement sections 5/7/8 define identities, but SE's actual getter/signal/context signature is missing. SE must provide it. |
| `context.config_selections.label` and `target_label` | `MissionConfig.mission.title` and `mission.target_region`; display a target label only when supplied by catalog/context metadata | `preview/mission_fixtures.gd:12–35` is synthetic. No real selected config or target catalog handoff exists. SE + KE1. |
| `config_selections.profile_id` / `profile_label` | `MissionConfig.design.launch_profile_id`, with the actual selected profile metadata | Do not treat the fixture profile ID/label as a real catalog ID/label. SE provides the selected profile context; KE1 provides catalog ID resolution. |
| `config_selections.source_labels` and synthetic report credits | Supplied profile/source label and KE2's canonical credit metadata; report `source_ids` selects sources, not their display names | The agreement does not define a profile source-label field or controller context signature. SE + KE1 + KE2 must supply the exact field/file and source-ID resolution. Show Unavailable when absent. |
| Flat synthetic selected part/orbit IDs | Real `design.bus_id`, `instrument_id`, `solar_id`, `battery_id`, `radio_id`, `storage_id`, `launch_profile_id`, `launcher_id`, `orbit_id` | Preserve SE's config and requirements; KE3 must not rewrite IDs or select the first target from a multi-target prototype. KE1/SE validated adapter required. |

## Operations and A04 visualization

| Preview field / source | v1 field / required treatment | Confirmation / gap |
| --- | --- | --- |
| `state.step` | `state.step_index`, supplied nonnegative zero-based index | Agreement section 7 / Example 1. Current HUD and orbit read `step` (`operations_screen.gd:100`, `orbit_diagram.gd`); a real adapter is required. Preserve zero. |
| No provider `total_steps`; fixture config has `duration_steps` | `state.total_steps` | Do not derive it from fixture duration, mission orbits, or the diagram's 12 positions. HPC supplies run length and confirms terminal `step_index == total_steps` in implementation. |
| Fixture `phase: Operations / Terminal`; `lifecycle: ready / terminal` | `phase: operating / finished`; separate `run_status` | Display canonical enums. Do not conflate finished with completed: aborted is also a terminal run status. The old lifecycle is not a valid substitute. |
| No canonical `run_status` in preview states | `state.run_status`: null while operating, `completed` / `aborted` at finish | Consume HPC's value; never infer it from score, counters or the word Terminal. |
| `state.energy_wh` | `state.energy_wh` | Name/Wh unit agrees; real adapter and finite-value behavior still need implementation evidence. Display zero Wh as zero. |
| `state.stored_mb` | `state.stored_data_mb` | Explicit field rename at the agreed consumer boundary; no silent KB conversion in the UI. |
| `state.returned_mb` | `state.returned_data_mb` | Cumulative actually returned decimal MB, not generated or stored data. |
| `state.observations_completed` | `state.observations_completed` | Same captured-count name. It does not imply that every observation has been fully delivered. |
| `state.observations_requested` | Original `config.mission.required_observations` | v1 state Example 1 does not carry this goal. SE must give KE3 the original immutable config; do not infer a goal from completed count. |
| Fixture return threshold | `config.mission.required_returned_data_mb`, or KE2's supplied report target in Debrief | Config and report identity must match; do not use the fixture's hard-coded 4 MB in production. |
| `state.target_access` | `state.in_target_access` | Example 1 confirms bool. Preserve false as Off; missing/null as Unavailable. No geometric visibility calculation in KE3. |
| `state.contact_on` | `state.in_ground_contact` | Example 1 confirms bool. Preserve false and provider reason; no local contact-window inference. |
| Fixture `state.generated_mb` | **No agreed cumulative generated-data field** | A03 provider authors this synthetic value; it is not inferred by the screen. HPC must supply the exact canonical field/units/payload or this telemetry remains Unavailable. Do not sum stored + returned or multiply captures by an assumed observation size. |
| Fixture `state.results_route.enabled/reason` | **No agreed state field** | SE owns routes, terminal notification, evaluation and one report per run. Obtain the controller's actual route-availability/signal policy. Do not silently turn `phase == finished` into a replacement controller verdict. |
| A04 optional event `time` | No agreed Event time field; scenario has `step_duration_hours` | Show supplied `step_index`. Event time remains Unavailable unless HPC supplies exact field, units and origin. Do not fabricate a timestamp from the step. |
| A04 step-mapped marker and provider-ordered timeline | Same accepted v1 `step_index`, flags and run-scoped history after an agreed adapter | Keep the trajectory illustrative. No propagator, costs, step timer or event generation is added to KE3. |

`Unavailable` is the missing-value display policy. Zero, false and null must be tested independently; absence is not an implicit numeric zero. Agreed numeric validation remains producer-owned.

## Actions and availability

| Preview | v1 mapping / behavior | Implementation confirmation |
| --- | --- | --- |
| `observe` | `observe` | Contract-confirmed; HPC implementation NOT TESTED. |
| `downlink` (button label Transmit) | **`transmit`** | Must translate the action identifier as well as the availability key. Do not send `downlink` into the v1 API. |
| `power_save` | `power_save` | Provider owns resource accounting, clamp at 0.0 Wh and the accepted one-step advance. |
| `state.action_availability.<preview_action>.enabled` | `state.available_actions.<v1_action>.allowed` | Example 1 confirms true/false and `blocked_code` / `reason`. No local legality calculation. |
| Visible blocked reason | Preserve `available_actions.*.reason` and code from HPC | A null/missing reason is unavailable text, not permission to invent a physical explanation. Disabled buttons still show a supplied reason. |
| Disabled click guard | Send **no action** and add no event | Existing A03/A04 synthetic checks verify zero intents/provider calls. Live controller path NOT TESTED. |
| A request received and rejected by HPC | Return provider `action_blocked` event; no `step_index` or resource/counter changes | Agreement section 7 and Event example confirm intended semantics. This is distinct from a disabled click. Real HPC implementation/trace is missing; no behavior inferred from the zero-delta example. |

The preview's `request_action(run_id, action_id)` provider seam is not the agreed engine signature `request_action(state, action)`. SE must own the actual state and call HPC; KE3 emits one intent to the existing controller. A new competing state-owning controller must not be introduced.

## Events and active-run evidence

| Preview | v1 mapping / preservation | Confirmation / unresolved point |
| --- | --- | --- |
| Array order | Keep provider/SE history order exactly | No sorting by step: multiple blocked events may share a step. HPC + SE must confirm accumulation/ordering semantics. |
| `event_id` | Keep `event_id` | Preserve IDs through display and KE2 evidence lookup. Never derive an event ID from its step. |
| Event `step` | `step_index` | Preserve zero. If absent, show Unavailable; do not substitute the current HUD step for an older event's step. |
| Event `label` | `message` | Preserve provider text. |
| Optional fixture `kind` / text-only action descriptions | Keep supplied `type`, `code` and `action` independently | v1 uses `type: action_blocked`, e.g. `code: NO_LINK_WINDOW`, `action: transmit`. Do not infer type/code by parsing message text. Current timeline has no canonical type/code presentation. |
| Preview requires every event's `run_id` | v1 Event example **omits per-event `run_id`** | Current session rejects an event without its preview run ID; the timeline also filters on it. SE must provide a trusted run-scoped history envelope or confirm per-event IDs. Do not stamp arbitrary late events with the currently visible run ID. |
| Preview history lives at `state.events` | HPC returns `{state, events:[new events]}` | A full cumulative history at `state.events` is not agreed. SE's MissionController must expose the active run and accumulated history, with reset/re-entry semantics. Actual getter/signal names are unknown until its file is supplied. |
| Flat preview `report.evidence_event_ids` | `root_causes[].evidence_event_ids` | Resolve each reference only in SE's active-run history. Matching event strings from another run are not evidence. Current preview only checks its old flat list, not the nested v1 structure. |

Current preview behavior rejects its flat dangling-reference fixture and clears the display. That is **not confirmation of the v1 Debrief evidence policy**. The agreement supplies report-level explanation and neutral missing/unknown-evidence behavior; the current Results outline must not be assumed compliant. A current-run report with unavailable linked evidence should retain its supplied explanation rather than invent a cause; finalize the precise display behavior with KE2. No A05 or report rewrite was performed during B01.

## Debrief / KE2 report

| Preview | Agreed v1 consumption | Confirmation / gap |
| --- | --- | --- |
| `status: success / partial / failure` | `status: success / partial / failed` | Correct the enum at a future agreed boundary; never recompute outcome in KE3. |
| No canonical report `run_status` | Preserve `run_status: completed / aborted` | An aborted run is `status: failed`, `score: null`, with the supplied abort explanation, even if counters meet goals. |
| No supplied score in A02 fixtures and no dedicated score formatter | Display supplied `score`, including **0**; null/missing -> **Unavailable** | The current Results outline falls back to raw JSON; raw `null` is not the requested Unavailable presentation. Contract Example 3 has 88, Example 4 has null; a genuine KE2 score-0 payload is still required. No score was calculated or score UI claimed verified. |
| No report-level explanation field | `explanation` | Keep KE2's supplied summary visible, including when root causes are empty or evidence is unavailable. |
| String list `causes` | `root_causes[]` with `code`, `segment`, `explanation`, `evidence_event_ids` | Do not generate, rank or select causes in the UI. Nested evidence mapping is pending. |
| List `suggested_changes` | `next_experiment` | Consume the supplied experiment; do not manufacture an engineering recommendation. |
| Synthetic `credits[]` | `source_ids[]` plus supplied source-ledger metadata | IDs alone are not source labels or verified credits. KE2 supplies canonical resolution/credit strings and ledger revision. |
| `observations_requested`, `returned_mb`, `return_threshold_mb` | `required_observations`, `returned_data_mb`, `required_returned_data_mb` | Preserve KE2's raw actuals/targets and report identity. |
| No supplied completion ratios | `observation_completion_ratio`, `data_return_completion_ratio` | Consume KE2's ratios; any percent formatting must not become competing evaluation or scoring. |
| Synthetic report dictionary directly in envelope | Evaluator `{ok:true, report}` or `{ok:false,error:EvaluationError}` | An evaluation error is not a failed completed mission. Preserve code, field path, message and suggested fix through SE's error route; do not advance retry history. |
| Local `_matching_run_id()` checks | Confirm report `run_id` / `mission_id` against SE's active run/config/history | Preview identity checks are local fixture evidence. The real controller handoff is missing. |

## Required implemented interfaces and units

| Owner / exact file | Agreed signature / responsibility | Inspection result |
| --- | --- | --- |
| HPC `core/MissionStepEngine.gd` | `init_run(config: Dictionary, scenario: Dictionary, run_id: String, mission_id: String) -> Dictionary`; `{ok:true,state,events:[]}` or `{ok:false,error:{code,message}}` | File absent in the available HEAD; signature documented only. NOT TESTED. |
| HPC same file | `get_available_actions(state: Dictionary) -> Dictionary` for `observe`, `transmit`, `power_save` | File absent; permitted/blocked reasons not implementation-confirmed. NOT TESTED. |
| HPC same file | `request_action(state: Dictionary, action: String) -> Dictionary`; `{state,events}`; provider owns costs/time/legality | File absent; no actual request/trace or unit adapter inspected. NOT TESTED. |
| KE2 `scripts/evaluation/mission_evaluator.gd` | `MissionEvaluator.evaluate_mission(config: Dictionary, final_state: Dictionary, events: Array, comparison_baseline = null) -> Dictionary` | File absent; no function body or emitted report available. NOT TESTED. |
| SE `scripts/MissionController.gd` | Existing context delivery, action dispatch, active state/history, routes, one report per run, re-entry and Retry | File absent. The agreement does not give hook/getter/signal names. NOT TESTED; do not invent replacements. |

Agreed boundary units are **Wh** and **decimal MB (1000 KB = 1 MB)**. Step duration is explicitly hours in `scenario.step_duration_hours`; accepted actions advance one step and rejected requests do not. Section 4 documents the legacy Ws/KB adapter (`battery_ws / 3600.0`, buffer/returned KB `/ 1000.0`). This arithmetic belongs in HPC's documented adapter, not in KE3. No converter implementation or real boundary payload was supplied, so actual unit conversion is **NOT TESTED**. Keep legacy whole-run `MissionSimulator.simulate(RunInput, catalog)` separate from the agreed per-step API.

## Pending handoffs by owner

- **SE / event coordinator:** explicit kickoff confirmation, event checkout/repository URL, integration branch and commit SHA; repository `docs/team-agreement.md` matching `v1.0-agreed`, `docs/contracts.md`, applicable AGENTS.md; the actual `scripts/MissionController.gd` and its referenced Operations/Results routes. Provide the exact context entry/getter/signal for selected MissionConfig, profile metadata/source label, active run ID, state and complete event history. Confirm route availability, report readiness, once-only connections, Retry/new run ID, snapshot re-entry and report deduplication.
- **HPC:** implementation commit/schema revision and `core/MissionStepEngine.gd`; scenarios including IDs and `step_duration_hours`; emitted `init_run`, allowed-action and blocked-action replies from that revision. Confirm Wh/decimal-MB conversion, terminal indexing and action names. Supply generated-data telemetry's canonical field/units/sample or leave it Unavailable; do likewise for optional event time. Confirm ordered delta events versus SE's accumulated history and whether events carry run IDs.
- **KE2:** implementation commit and `scripts/evaluation/mission_evaluator.gd`; revisioned completed, aborted/null-score and valid zero-score reports with matching run history; nested cause/evidence and EvaluationError examples; canonical `source_ids` resolution, credit metadata and ledger revision. Missing evidence must not become an invented cause or score.
- **KE1 + SE:** actual validated MissionConfig/catalog revision, IDs and selected launch-profile/source metadata used by the context handoff. No real validated config or readiness flow is exercised by B01.

These are missing inputs, not permission requests. B01's conditional production entry remains **NOT TESTED**. The contract mapping is complete; B02's real validated-config/HPC-trace/KE2-report end-to-end exercise was not run.
