# A06 — Retry into a synthetic redesign and second run

**P0: FIXTURE PASS. P1: NOT TESTED / deferred.** Work is confined to `C:\Workspace\OrbitBridge\Event\ke3_outline_preview`. The explicit entry is **`res://preview/a06_preview.tscn`**. Default startup remains `res://ke3/operations_control.tscn`; no project.godot, Godot installation, historical checkout or production settings changed. Stop after A06.

Read `A05_CHECKS.md`, `BOUNDARY.md`, the Debrief, session, preview/provider/history implementation and the v1.0-agreed agreement's config and lifecycle rules. No applicable AGENTS.md was found in the preview/workspace ancestry or preview subfolders. Baseline: `C:\Users\Asus\Downloads\Telegram Desktop\team-agreement (7).md`, v1.0-agreed, with `B01_CONTRACT_MAPPING.md`. Document instructions are contract context, not a request to implement other phases or change SE's project.

The agreed ownership remains: SE creates runs and owns drafts, route/reset policy and one report per run; HPC supplies simulation/actions/history; KE2 supplies outcomes, scores and comparison. A06's equivalents are **explicit synthetic stand-ins in preview/**, not production wiring. No readiness, simulation, legality, cost, score or scientific comparison is implemented by KE3.

## Implementation

- Reuses the A05 Retry button and `retry_requested(run_id)` signal. The Debrief latches before emitting and exposes `set_retry_pending(bool)` for acknowledgement. Re-rendering the same run does not release the latch. Only presentation state changes here.
- `preview/a06_retry_receiver.gd` owns the synthetic editable draft and deep-copied completed snapshots. Completed records are keyed by run ID; exact duplicate notifications do not append or replace the baseline. Copy getters do not expose owned dictionaries.
- Retry opens an editable draft while a synthetic redesign-route reply is pending. The reply selector supplies accepted or rejected text. Rejection retains the draft, enables editing/route retry and shows the supplied reason. Back/Cancel discards the local edit and returns to the originating completed Debrief. Pending route tokens are invalidated on Cancel.
- Radio and battery choices are supplied synthetic IDs. Selecting another component resets the other draft component to the originating config: this preview offers one component change at a time. Requirements and scenario are displayed but not editable. The original KE2 experiment remains visible, including its suggestion to change orbit; it is not applied automatically.
- Starting B calls the explicit preview provider with the edited config and unchanged scenario. Only then does the entry call the existing `session.invalidate_for_retry(origin_run_id)` and `open_run(new_run_id)`. The session itself is unchanged. It clears live presentation/correlation and accepts B's supplied initial snapshot. Completed snapshots are retained by the synthetic receiver.
- B Observe replies may be held or delivered by the normal half-second preview timer. The existing request-generation/token acceptance path rejects late A replies without clearing B's pending request. B completion is an explicit **Deliver B terminal snapshot (fixture)** control: no local simulation is implied. The normal Results route consumes that supplied report.
- The second Debrief has visible Back and Retry controls and a keyboard focus loop. Reopening Results records no new run and cannot replace the retained A baseline. The fixture has two authored runs; no third run is supplied. Retrying B can open/cancel its draft; attempting a third start reports fixture exhaustion rather than reusing B's identity.

## Runs, component edits and preserved requirements

| Item | Original A | Edited / B | Actual result |
| --- | --- | --- | --- |
| run_id | `SYNTHETIC-A06-RUN-A-001` | `SYNTHETIC-A06-RUN-B-001` | Distinct IDs, matching report/history namespaces. |
| Radio (accepted path) | `SYNTHETIC-RADIO-001` | `SYNTHETIC-RADIO-002` | Exactly this component differs. |
| Battery (accepted path) | `SYNTHETIC-BATTERY-001` | Same | Preserved. |
| Rejected-route alternative | Radio001, Battery001 | Radio001, Battery002 | Editable after rejection; Cancel restores A completely. |
| Target | `SYNTHETIC-TARGET-DELTA-001` | Same | Preserved. |
| Objective | `imaging` | Same | Preserved. |
| Observation goal | 3 | 3 | Preserved. |
| Returned-data threshold | 4 decimal MB | 4 decimal MB | Preserved. |
| Duration | 1 orbit / 8 supplied steps | Same | Preserved. |
| Budget | 1200 credits | 1200 credits | Preserved. |
| Orbit | `SYNTHETIC-ORBIT-LEO-001` | Same | Preserved. |
| Scenario | `SYNTHETIC-A06-SCENARIO-001`, version `fixture-v1` | Same | Full scenario dictionary preserved, including 0.25 hours/step and 8 steps/orbit. |
| Other selected IDs / profile | A's supplied design | Same | Full design equality except the selected radio. |

A reuses the A05 partial report and A02 mission selections with literal A06 objective/duration/scenario metadata added in the provider. B reuses the supplied A05 success-report values. These are synthetic config projections, not real catalog IDs or evidence that a radio change improved a mission.

## P0 expected versus actual

Each row below is **FIXTURE PASS** in headless and windowed runs. Full expected/actual dictionaries, labels, tokens and snapshots: `verification/a06-runs/a06-headless.json` and `a06-windowed.json`.

| Check | Expected | Actual |
| --- | --- | --- |
| Mouse Retry + repeated attempts while pending | 1 Retry intent, 1 redesign route, no start/action | Exactly 1/1; Retry remains disabled even after the same input snapshot re-renders. Repeated button-signal/handler attempts emit nothing. |
| Keyboard Space + held-key echo | 1 Retry intent, 1 route | Exactly 1/1. Engine key events used; no human playtest claimed. |
| Rejected route | Supplied reason; draft editable; Start disabled | “SYNTHETIC redesign route rejected: Builder temporarily unavailable; draft retained.” Radio and battery edits remain available. |
| Deep copy | Editing/mutating returned draft copies cannot change A | Full completed config/report/history and baseline compare equal before/after edit, rejection and Cancel; provider's original A fixture also unchanged. |
| Cancel | Return to original A report and discard draft | Original payload restored exactly; Retry enabled; completed registry unchanged. |
| New route versus old route reply | Old token cannot settle newer pending route | `late_route_reply`; newer route remains pending, with unchanged reason/draft. |
| Accepted route / B start | One provider start; edited config; distinct run; clear old report/history | Start count1; B config is the edited copy; A report absent; timeline has only B launch event. |
| B initial snapshot | Step0, operating, access On/contact Off, 8Wh, generated/stored/returned0MB, observations0/3 | Exact HUD match. Orbit shares step0 and B identity. |
| B pending + delayed A reply | Reject A, preserve all B telemetry/orbit/history/report and pending token | `late_reply` twice; entire before/after presentation/token dictionary equal; B request remains pending. |
| B Observe delivery | Step1, operating, 7Wh, generated1MB, stored1MB, returned0MB, observations1/3 | Exact HUD match; only B launch/Observe events in order. |
| B completion | supplied success/completed, 3/3,4/4MB,100%/100%,score100 | Exact Debrief match; report.run_id is B; four B-only supplied events. |
| Results route | One request from B terminal state | Exactly one request; no action or provider start. |
| Reopening Results three times | Two unique completed runs, A baseline unchanged, no event/report duplication | Exact completed-registry and report snapshots unchanged each time. |
| Focus / Back / Retry | Visible focus, reachable enabled footer controls | Engine Tab reaches Credits → Back → Retry; 3px gold focus; both footer buttons inside1280×960. |
| B Retry via Enter | One intent/route; B draft; Cancel restores B | Exactly1/1; pending Cancel invalidates route reply; B report and A baseline unchanged. |
| Explicit preview gate | Unmounted receiver/provider cannot create draft/run or expose mocks | preview_entry_required / empty catalog. A02 failed-live-provider regression also passes. |
| Normal timed entry | Fresh explicit entry accepts route, starts B and completes Observe without test-held callbacks | Default half-second timers pass; B report score100 reached; counts1 Retry/route/Results/action/provider-action/start. |

The late-A test stores a real session callback/token from the authored A initial Observe, loads the supplied A completion, performs Retry and then delivers that old callback while B Observe is pending. It does not manufacture a new token with B's identity. Cancellation also rejects a late route callback without replacing the restored B Debrief.

Main lifecycle totals: **3 Retry intents, 3 redesign routes, 4 Results routes, 2 action intents, 2 provider action calls and 1 provider start**. The 2 actions are the deliberately held A Observe and B Observe. The 4 Results routes are the first B route plus 3 re-entry checks. No extra actions/starts occur from editing, rendering, rejection, Cancel or route changes. A separate fresh-entry automatic-delivery smoke flow has totals1/1/1/1/1/1; it is recorded separately, not added to the main-loop totals.

## Visible evidence

- `verification/a06-rejected-draft.png`: supplied rejection reason, editable battery choice, preserved requirements and reachable Cancel.
- `verification/a06-accepted-draft.png`: Radio001 → Radio002, unchanged battery/orbit/scenario, original experiment, focused Start.
- `verification/a06-second-initial-hud-timeline.png`: B ID, step0 HUD, illustrative marker and B-only launch timeline together.
- `verification/a06-second-debrief.png`: B ID in the status label, supplied success/report values, focused Retry and visible Back.

Captures were inspected for readable labels and footer/focus visibility. They are local Compatibility framebuffer evidence (**FIXTURE PASS**), not browser evidence or a human playtest.

## Commands, exits and regressions

Godot: `C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe`, **4.7.2.stable.official.ed1daf0bf**. Windowed runs report OpenGL3.3 **Compatibility**, NVIDIA GeForce RTX4060 Laptop GPU; evidence JSON records `gl_compatibility`.

All **18 commands** in the final matrix exit **0** and have no script/parse/engine errors. Exact executable/arguments, exit statuses and log paths: **`verification/a06-commands.md`** and **`verification/a06-runs/manifest.json`**. Reproduction from this folder:

```powershell
& 'C:\Users\Asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'verification/run_a06_verification.py'
```

Runner exit **0**. The A06-only pair was repeated with the same recorded commands after adding B's run ID to the visible status label; both again exit0 with the same check counts. The explicit entry startup smoke (`--headless --scene res://preview/a06_preview.tscn --quit-after 5`) also exited0; `verification/a06-startup.log` is retained.

| Suite | Headless | Windowed Compatibility | Result |
| --- | --- | --- | --- |
| A01 Operations + Results, independently empty | Draft unchanged, advance_calls0, intents0 | Same plus captures | FIXTURE PASS |
| A02 |254 checks,0 failures|255 checks,0 failures|FIXTURE PASS|
| A03 |256 checks,0 failures|259 checks,0 failures|FIXTURE PASS|
| A04 |206 checks,0 failures|210 checks,0 failures|FIXTURE PASS|
| A04 restart first/second |9 checks each,0 failures|10 checks each,0 failures|FIXTURE PASS|
| A05 |139 checks,0 failures|156 checks,0 failures|FIXTURE PASS|
| A06 P0 |**100 checks,0 failures**|**104 checks,0 failures**|**FIXTURE PASS**|

The first development focus test sent Tab echo events and therefore skipped controls; that test was stopped after its assertion chain. The helper now sends ordinary single Tab events and reserves echo events for Retry keys. A watchdog prevents an incomplete test from hanging. Final checks above pass; no human keyboard or mouse activation is claimed.

All16 preservation hashes in `verification/a06-baseline.json` match: startup, Operations/orbit/timeline/session, existing preview entries/providers, A01–A05 test sources and A05/B01 documents. The shared Debrief has only a pending-request latch added; no route/draft ownership moved into it.

## P1 comparison decision

**Deferred / NOT TESTED.** P0 passed before this decision. The agreement has optional `report.comparison` and signed current-minus-previous semantics, but no revisioned KE2 comparison envelope is supplied for labels, metric units, eligibility or interpretation. A/B fixtures above intentionally do not establish controlled action histories or component causality. `report.comparison` remains supplied null and is checked as null. No delta, interpretation or single-component attribution is computed by the UI.

P1 zero delta, missing comparison metric, mismatched requirements, multiple component changes, differing action sequences and aborted-run exclusion are all **NOT TESTED**. Those cases are not reported as failures or controlled passes; they need a separately supplied synthetic or live KE2 comparison payload/schema before comparison presentation work.

## Changed files

- `ke3/debrief_screen.gd`: pending Retry latch and acknowledgement setter; existing button/signal reused.
- `preview/fixture_provider.gd`: add mounted explicit A06 entry to the preview gate.
- New `preview/a06_provider.gd`: literal A/B states/replies and explicit synthetic start/finish.
- New `preview/a06_retry_receiver.gd`: isolated draft/route/completed-record stand-in.
- New `preview/a06_draft_screen.gd`: editable component choice, preserved summary, experiment, reason and footer.
- New `preview/a06_preview.gd` and `.tscn`: explicit entry, synthetic route replies, timed/held delivery, Back and B lifecycle.
- New `tests/a06_retry_check.gd`: engine-input, copy/preservation, route, reset, old-reply and re-entry evidence.
- Added `A06_CHECKS.md`, A06 addenda in `BOUNDARY.md` / `preview/README.md`, `verification/run_a06_verification.py`, baseline/command manifest, A06 logs/JSON and four A06 captures. Existing generic regression JSON/captures are refreshed by their own suites; previous A05 verification copies remain available.

Do not merge `preview/`, tests/harnesses, `project.godot`, `.godot` or verification resources into the team project. The pending-state presentation seam still requires SE review before any production connection.

## Exact pending owner handoffs for live verification

| Owner | File / exact missing hook or payload | Affected check |
| --- | --- | --- |
| SE | Revisioned `scripts/MissionController.gd`; actual receiver for `retry_requested(run_id)`; signature to open an editable Builder draft by deep copy, return accepted/rejected route reason with correlation token, acknowledge pending Retry and handle Back/Cancel back to the same completed run | LIVE mouse/key once-only route, editable rejection and cancellation: NOT TESTED. Preview begin_redesign/request_route/receive_route are not proposed production hook names. |
| SE + KE1 | Actual edited-draft readiness invalidation/revalidation hook and validated config handoff before Launch; real catalog/profile IDs | LIVE editable redesign/validated second launch: NOT TESTED. No real validation result is reused or claimed. |
| SE | Actual new-run/reset hook: allocate distinct run_id, preserve target/objective/goals/duration/budget/scenario identity+version, clear active counters/history/report/pending tokens while retaining eligible immutable baseline | LIVE reset/late-reply behavior: NOT TESTED. Existing session.invalidate_for_retry/open_run only demonstrate presentation cancellation against synthetic providers. |
| SE | Completed-run registry/report deduplication, report-ready notification, trusted run-scoped accumulated history getter/envelope, re-entry route and baseline policy (including New Mission baseline clearing) | LIVE one report per run / no duplicate history: NOT TESTED. Preview state.events with per-event run_id is not the frozen production history envelope. |
| HPC + SE | Revisioned initial/action/terminal payloads with active run/config/scenario IDs and ordered event IDs/step_index/type/code/message; request-correlation handoff | LIVE second-run telemetry/evidence and old reply isolation: NOT TESTED. Wh and decimal MB must arrive already adapted. |
| KE2 | Revisioned `scripts/evaluation/mission_evaluator.gd` outputs for A/B with run_id, mission_id, status, run_status, counters/targets, supplied ratios/score, explanation, root_causes[].evidence_event_ids, next_experiment, source_ids | LIVE second Debrief and matching evidence: NOT TESTED. Real source-ledger/profile credit mapping from A05 remains pending. |
| KE2 + SE | Exact `report.comparison` schema and revisioned sample: A/B run IDs/labels, changed fields and before/after values, metric values/units/signed B-minus-A deltas, supplied interpretation and eligibility/rejection reason for mismatched scenario/requirements, multiple changes, different action histories and aborts | P1 fixture/live comparison: NOT TESTED. Do not invent canonical subfield names or attribute a component effect from the two authored outcomes. |

Browser, live integration, human playtest, source confirmation and publication are **NOT TESTED**. No Part B wiring or later prompt was run.
