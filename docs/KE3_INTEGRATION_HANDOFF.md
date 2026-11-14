# KE3 integration against SE 1a311a9

Base: `1a311a94ed183ddc83b93cfa7847bbd86927f366` on fetched `origin/se`.
This integration is maintained on KE3 over the SE base above. The update preserves
the existing KE3 preview; remote se/main are unchanged by this branch update.

## Runtime boundaries

Keep SE's Main scene and controller. Builder's six canonical catalog selectors,
KE1 readiness and HPC `init_validated_run` remain authoritative. Operations still
plays a policy-generated HPC trace. Every selected frame updates the controller's
active native state; only terminal/aborted states enter KE2 `evaluate_hpc_state`.
The controller accumulates and owns the native ordered event history.

`scripts/presentation/DebriefPresentation.gd::build(trace, store)` formats supplied
fields and correlates report run/mission/goals/counters with the selected native
run. It does not evaluate, score, simulate, or choose legal actions. It preserves
zero, unavailable fields, `source_ids` and `comparison`, retains readable reports
with missing event links, and rejects mismatched reports. Evidence IDs resolve
only against that native state's full event log, including terminal events.

`mission_results.publish` still publishes once per run. It additionally rejects
an evaluator reply for a different run/mission. Optional
`reply.source_credit_metadata.applicable_source_credits` is deep-copied into the
history record beside the unchanged report. Each credit uses `credit_scope`,
`title`, `attribution_text`, `url`, and `actual_use`; no credit is added to the
report's `source_ids`. Readiness attribution is bound to the executed validation.
The current evaluator supplies no feedback-credit metadata: display Unavailable.

## Retry behavior change

`retry_requested` still calls SE's `MissionController.retry_mission`. It now pins
the previous session, deep-copies an editable draft, clears only active run state
through SE's existing `mission_results.retry`, and opens Builder. Continue goes
through Readiness and the existing validated launch. Cancel Retry in Builder or
Readiness restores the original run/report exactly. A blocked draft can recover
or cancel. A repeated pending intent is ignored. Successful Operations entry
releases the restore snapshot; completed history and reports remain retained.

The existing controller smoke test now traverses Builder/Readiness after Retry
instead of assuming an immediate relaunch. Its original lifecycle assertions
remain. This explicit routing change is required for the requested editable
Retry flow, rather than introducing a second controller.

## Presentation changes

- Results history columns no longer wrap one character per line; small layouts
  stack their cards and remain scrollable.
- Focused Results handles Arrow/Page keys; Tab navigation remains native.
- Show credits and Retry are keyboard reachable; focused Operations controls
  follow the scroll region with room for their focus outline.
- HUD explicitly shows native run/step and Wh/decimal MB; missing optional
  numeric values display Unavailable. Selected frame details show all raw event
  IDs, including a terminal event sharing the final frame.

## Local verification

Installed Godot 4.7.2, Compatibility renderer. KE1: 294 + 671 + 470 passing checks;
HPC: 36 passing; KE2: 143 passing, 5 upstream pending. Existing controller,
integration, canonical Builder, expanded-target, Operations and prototype suites
pass. New `tests/ke3_team_integration_check.gd`: 336 headless and 336 windowed
checks pass, including 1280x720, 1024x768 and 900x680 Results/keyboard checks and
900x680 Operations focus containment. The normal candidate journey produces
two independently validated runs with matching real KE2 reports.

Run the new test with an explicit evidence-output directory:

```sh
godot --headless --path . --script res://tests/ke3_team_integration_check.gd -- /absolute/evidence-directory
```

The test-only missing-event, malformed/stale-reply, long-text and credit-metadata
cases never enter the runtime. No preview provider, recorded report or preview
startup setting was imported.

## Remaining boundaries

- No manual Observe/Transmit buttons: disabled-button dispatch and deliberate
  rejected requests through the UI are NOT TESTED. Separate real-engine rejection
  probes remain outside both player-run histories.
- KE2's cached evaluator rejects Survey explicitly; current Survey scoring and
  applicable scoped feedback/source-ledger metadata require the newer KE2 handoff.
- Run IDs increase across New Mission within a process; fresh processes can
  restart the same IDs and `mission_local`. Current publication is synchronous and
  in memory. SE must namespace identities before cross-session persistence or
  accepting external asynchronous reports; bundle/session provenance remains
  necessary for exported evidence.
- Browser export and official human B10 playtest are NOT TESTED. No release or
  spacecraft-physics validation is claimed.
