# KE3 provisional outline boundary

This is an isolated Part A SYNTHETIC preview, created because no event project was found. The historical repository uses Forward Plus and contains no gameplay code. No applicable AGENTS.md was found in the workspace or its ancestors. Official kickoff evidence/revision was not supplied; this work does not certify kickoff or team integration. All names below await producer agreement.

Operations shows context/config selections, a KE1 state/events area, a KE2 report/credits area, and action/result-route intent outlines. Results shows the same input boundary with report/credits emphasis and a retry intent. Missing values remain pending, never numeric zero or an invented successful outcome.

`set_inputs(context: Dictionary, state: Dictionary, report: Dictionary)` takes JSON-compatible snapshots. The scene makes deep dictionary/array copies and returns copies from `get_input_snapshot()`. It renders local UI only. No shared state owner, autoload, draft setter, simulation timer, scoring code, source ledger, navigation, or export implementation is added. Render never emits an intent. The fixture runner is not referenced by the scenes or startup configuration.

| Producer | Provisional name | Type | Unit | Missing behavior | Run identity |
| --- | --- | --- | --- | --- | --- |
| SE shell | `context.run_id` | String | Opaque ID | Pending identity; intent controls disabled | Exact equality; real field/name pending |
| SE Builder/shell | `context.config_selections` | Dictionary; selection keys pending | IDs/units pending SE catalog | Context pending; no draft edits or defaults | Carried in context envelope |
| KE1 HPC | `state.run_id` | String | Opaque ID | Operations route/action intents disabled | Must match context; all nonempty envelopes must agree |
| KE1 HPC | `state` state/event payload, including step/resources/events | Dictionary; exact fields/types pending | Step/time/resource units pending KE1 | State/step unavailable; no advance, simulation or inferred zero | State envelope must carry agreed run ID |
| KE1 legality | Action identifiers and legal-action payload | Pending KE1 file/schema | Pending | Action button stays disabled; KE3 makes no legality decision | Intent echoes correlated run ID |
| KE2 evaluation | `report.run_id` | String | Opaque ID | Retry intent disabled; no assumed report | Must match context and any state |
| KE2 evaluation | Report metrics/outcomes | Dictionary; exact fields/types pending | Metric units pending KE2 | Evaluation pending; no local score calculation | Report envelope must carry agreed run ID |
| KE2 source ledger | Report credits/source records | Pending KE2 file/schema | Citation IDs/URLs pending | Credits unconfirmed; no source-confirmation claim | Same report/run envelope; ledger revision pending |
| KE3 -> SE/KE1 | `action_requested(run_id: String, action_id: StringName)` | Signal; provisional | Opaque identifiers | Empty/mismatched IDs emit nothing | Echo only; KE1 validates legality before execution |
| KE3 -> SE routing | `result_route_requested(run_id: String)` | Signal; provisional | Opaque ID | Disabled without matching context/state | SE decides when/where to route; no scene switch here |
| KE3 -> SE retry | `retry_requested(run_id: String)` | Signal; provisional | Opaque ID | Disabled without matching context/report | SE owns new run/draft policy; no reset here |

## Pending inputs and affected checks

- **SE/event coordinator:** event project path, applicable event AGENTS.md, official kickoff record and team revision. Affects event-project reuse and LIVE integration checks. The isolated preview can be checked independently.
- **SE:** context envelope, actual `run_id` and config-selection fields; action/result-route/retry receivers and run-identity policy. Affects LIVE routing/retry/config tests. Signal names are proposals, not an agreed interface.
- **KE1:** supplied revision and HPC state/event/action-legality schema or fixture file, including run identity, exact step/time/resource fields and units, action IDs and legal-action representation. Affects LIVE Operations/action/step tests. `sentinel_step` in the test is a fixture sentinel, not a proposed HPC field.
- **KE2:** supplied revision and report/source-ledger payload or fixture file, including run identity, metric names/types/units and credits schema/revision. Affects LIVE Results/evaluation/source-credit tests.
- **SE/export:** browser build and launch URL, if browser testing is requested later. Affects BROWSER PASS; no export or browser check is part of this outline prompt.

No Part B wiring was performed. Inspect each producer's supplied revision and payload before replacing pending fields or connecting owners.

## A05 preview addendum

`A05_CHECKS.md` records the synthetic v1.0-agreed Debrief implementation and evidence. Results keeps `set_inputs(context, state, report)` and its existing Retry intent. A current-run report is retained when a linked event is absent; evidence is labeled Unavailable. Stale report/run/event envelopes are still rejected. Nested `root_causes[].evidence_event_ids` resolve only against the active run's accepted preview history. Score/outcome/ratios/causes/experiment are supplied, never evaluated here. Canonical outcome is `failed`; score0 remains0, null/missing is Unavailable. Explicit entry: `preview/a05_preview.tscn`. The default startup is unchanged. Production history/source-ledger envelopes and A06 Retry lifecycle remain pending their owners. A05 context metadata and Readiness notice are synthetic presentation examples, not new controller interfaces.

The subsequent SYNTHETIC fixture prompt adds an explicit `preview/mission_preview.tscn` entry, literal fixtures and a proposed `ke3/presentation_session.gd` provider seam. See `preview/README.md` for fixture keys, units, stable IDs and action sequence. These remain synthetic field proposals; no real producer schema was confirmed. Run/event/reference checks protect display correlation only and do not implement KE1 domain validation or legality. Missing/failed live providers never select fixtures. Only the mounted explicit preview entry can activate the mock provider.

## Team handoff

A06 adds an explicit `preview/a06_preview.tscn` entry with synthetic route receiver, editable draft and two-run provider. `ke3/debrief_screen.gd` reuses Retry and latches while pending; it owns no draft, routes or run creation. The existing presentation session remains unchanged. See `A06_CHECKS.md` for the P0 fixture pass, requirement-preserving copies, Cancel/rejection, second-run reset and late-reply evidence. Production ownership remains with SE; P1 comparison is deferred/NOT TESTED pending a KE2 envelope. The default startup and existing A01–A05 test sources remain unchanged.

Only `ke3/operations_control.tscn`, `ke3/results_control.tscn`, `ke3/outline_control.gd`, the proposed `ke3/presentation_session.gd` provider seam, and their generated `.uid` files are candidate presentation files, subject to SE review of their provisional interface and SYNTHETIC preview markings. `BOUNDARY.md` records the proposal. The `tests/` scripts are explicit fixture harnesses, not gameplay. **Do not merge this preview's `preview/`, fixture harnesses, `project.godot`, `.godot`, startup scene setting, or verification captures/logs into production.** SE owns the actual startup, renderer configuration, routing and export. Reuse the eventual event project's structure and renderer when that project is supplied.
