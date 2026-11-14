# SYNTHETIC mission fixtures - explicit entry only

Open `res://preview/mission_preview.tscn` explicitly to select a case. The default main scene remains the empty Operations outline. No autoload, command-line mock switch, environment switch, network fallback or startup fixture selection was added. The mock provider requires the actual mounted preview entry and stops serving fixtures when that entry leaves the tree.

The general `ke3/presentation_session.gd` takes an injected provider with provisional `open_run(run_id)` and `request_action(run_id, action_id)` methods. Replies have `{ok, payload: {context, state, report}}`, or `{ok: false, error}`. The session's `accept_payload()` checks run/event correlation and report references, then calls the same `set_inputs(context, state, report)` on both outline scenes. These are proposed production seams, not confirmed KE1/KE2/SE contracts. No real producer payload/revision was supplied.

In preview runtime, this entry loads `fixture_provider.gd`; an authorized fixture provider then loads `mission_fixtures.gd`. The test harness also inspects these scripts to verify rejection and stable identities. Fixture selection calls `open_run()` through the general session. Preview action buttons emit the existing Operations action intent, which calls the same session `request_action()` used for an injected live provider. Rendering never advances a scripted reply. A provider failure clears the displayed inputs, shows a diagnostic and returns an error. It never selects or contacts a fixture provider, including after a preview provider was previously bound.

## Literal mission and scripted replies

Mission `SYNTHETIC-KE3-MISSION-001`: target `SYNTHETIC-TARGET-DELTA-001`, three requested observations, 4 MB returned threshold, duration 8 steps, budget 1200 synthetic credits, seven selected part/launcher IDs, a selected orbit ID, and explicitly SYNTHETIC profile/source labels. These labels are not real catalog IDs or externally confirmed credits. Units are fixture-specific; a step has no assumed seconds conversion. MB and Wh are supplied as labeled display values; no physical calculations are implemented.

| Case | Step | Wh | Stored MB | Returned MB | Observations | Contact | Scripted reply |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `ready_step_2` | 2 | 8 | 2 | 0 | 0/3 | off | Ready snapshot |
| `observe_allowed` | 3 | 7 | 3 | 0 | 1/3 | off | Observe allowed |
| `contact_on` | 4 | 7 | 3 | 0 | 1/3 | on | Independent contact-on example |
| `downlink_contact_on` | 5 | 6 | 1 | 2 | 1/3 | on | Downlink allowed |
| `downlink_no_contact` | 3 | 7 | 3 | 0 | 1/3 | off | Blocked; no step/resource change |
| `power_save` | 4 | 8 | 3 | 0 | 1/3 | off | Power-save allowed after blocked reply |
| `terminal` | 8 | 5 | 1 | 2 | 1/3 | off | Terminal; no scripted actions |

Every reply includes an `expected` dictionary with directly supplied values. Script transitions select whole authored replies; they do not compute deltas or decide real action legality. The scripted sequence is ready -> Observe -> blocked Downlink -> Power-save. Select the independent contact-on case to exercise allowed Downlink. Report and terminal cases are separate snapshots, not calculated continuations of every branch.

Reports: success = 3/3 observations and 4/4 MB; partial = 1/3 and 2/4 MB with exactly one cause and one suggested change; canonical failed = 0/3 and 0/4 MB. Missing report is `{}`, with no synthesized evaluation. Stale report run ID is rejected and clears the views with a boundary diagnostic. Under A05, a current-run dangling report event reference retains the report and marks evidence Unavailable. Missing reports keep Results retry disabled.

Run IDs use stable `SYNTHETIC-KE3-RUN-*` constants; events have stable, run-prefixed `event_id` values. Reused event IDs identify identical event contents. No timestamps or random IDs are generated. Each report's `evidence_event_ids` references its state's event array, except the intentionally dangling case. `credits` contains synthetic source/profile labels only.

## Ownership and handoff

Fixture-only proposed keys: `context.config_selections` includes mission/target/requirements, budget, selected IDs and labels. `state` adds `lifecycle`, `step`, `energy_wh`, `stored_mb`, `returned_mb`, observation counts, `contact_on`, and `events[{run_id,event_id,step,label}]`. `report` adds status, observation counts, return threshold/amount, causes, suggested changes, evidence event IDs and synthetic credits. The original boundary table remains authoritative about which real names/types/units are pending.

KE1 still owns simulation and legality, KE2 report evaluation and source ledger, and SE shared state, Builder, routing and export. Before Part B, obtain and inspect their actual revisions and payloads. `preview/`, `tests/`, local `project.godot`, `.godot/` and `verification/` must stay outside the eventual production handoff. The session is a candidate boundary proposal for SE review, not an installed live integration.
# A05 explicit Debrief entry

Launch `res://preview/a05_preview.tscn` explicitly to select the SYNTHETIC canonical report cases. See `../A05_CHECKS.md` for exact commands, expected/actual results and screenshots. `project.godot` is unchanged. The A05 entry initially selects `debrief_partial`; the selector also includes success, failed, zero/null/missing score, missing optional ratio, awaiting evaluation, stale/missing evidence, evaluation error, long credits and pre-launch Readiness-notice cases. The inherited A02–A04 Operations fixtures remain available.

The preview-only profile_metadata/source_metadata/visual_attributions envelopes do not freeze production ledger or history wiring. KE2 supplies evaluation and credits; SE supplies actual routes/history/Retry. Missing active-run evidence retains the report and explanation with Unavailable, replacing the old A02 dangling-reference rejection expectation. The A05 entry contains no A06 lifecycle.

# A06 explicit Retry entry

`res://preview/a06_preview.tscn` is the separate SYNTHETIC two-run Retry entry. It starts at completed A. Choose accepted/rejected synthetic route reply, activate Retry, choose a radio or battery, then start B or Back/Cancel. Normal route/action fixture replies arrive after half a second. In B Operations, Observe uses a supplied reply; the explicit terminal-snapshot control delivers the authored completion, after which Request Results route opens B Debrief. Back and Retry remain available. This is not real readiness, simulation or a production Builder/controller. The two-run fixture reports exhaustion instead of creating a third run.

`../A06_CHECKS.md` lists exact commands, outcomes, captures and pending live hooks. `tests/a06_retry_check.gd` also holds replies to exercise pending and stale delivery. Optional P1 comparison is deferred; supplied comparison remains null, with no component-effect claim. Default startup is unchanged. All A06 route/draft/run-creation stand-ins stay under preview/ and must not enter the team merge.
