# Agreed v1 contract examples

Status: ALIGNED TO v1.0-agreed. Schema version 1. All five roles approved the source agreement, and the user requested synchronization. The legacy v1-draft directory name is retained to preserve existing links; these examples now follow the agreed interfaces.

## Source of truth

Read [contracts.md](../../contracts.md) and [team-agreement.md](../../team-agreement.md). Changes to the interface need the affected members' approval. The four signed JSON examples (operating state, blocked event, completed report and aborted report) are reproduced exactly as parsed JSON.

## Files

| Group | Files and purpose |
| --- | --- |
| Vocabulary | reference-ids.json: agreed units, orbit/target IDs, public status/error vocabulary; existing component labels remain illustrative fixture labels |
| Configuration | mission-config.example.json and mission-config-overmass.example.json: equator target, high_inc orbit, 4 captures and 30 MB; alternate instrument isolates the illustrative mass boundary |
| Invalid goals | mission-config-invalid-goals.example.json and validation-invalid-goals.example.json: positive-only targets, structured issues, null metrics and dependent checks not evaluated |
| Readiness | validation-ready.example.json and validation-overmass.example.json: 1329 g passes the mass check and 1330 g fails; public radio metric is MB/hour |
| Signed operations examples | mission-state.example.json and action-blocked.event.example.json: exact source examples with run/mission/event identity and named unit deltas |
| Rejected request wrapper | request-action-blocked.example.json: unchanged operating state plus blocked event; no step/resource advancement |
| Signed report examples | mission-report-completed.example.json and mission-report-aborted.example.json: 88/partial for 3 of 4 captures, or failed/null score on abort even when targets were met |
| Evaluator wrappers | evaluation-completed.example.json and evaluation-aborted.example.json: ok=true means evaluation input is valid, not necessarily mission success |
| Evaluation errors | evaluation-nonterminal-error.example.json and evaluation-top-level-error.example.json: errors are separate from reports; field_path and run_id can be null |
| Cause evidence | completed-report.evidence-events.example.json: the evt_007 low-battery event cited by the completed report; this is an excerpt, not a full mission trace |
| Unit examples | unit-conversions.example.json: Ws/Wh, decimal KB/MB, hourly-to-step radio conversion with an explicitly illustrative step duration |
| Scoring examples | scoring-cases.example.json: half-up ties, rounded 100 with unmet actuals, partial/no progress, overshoot and aborts |
| Policy/action examples | agreed-behavior-cases.example.json: strict mass boundary, pre-launch power gate, rejected requests and accepted power_save clamping/completion |

[fields-and-statuses.md](fields-and-statuses.md) summarizes the layout. [readiness-policies.md](readiness-policies.md) records agreed readiness/runtime distinctions.

## Limits of the examples

These are hand-authored interface fixtures, not outputs from a validator, simulator or evaluator. No actual catalogs or scenarios are implemented here. Ready/over-mass totals and other passing checks are illustrative assumptions; the shown totals are not calculated from a component catalog.

The new radio example uses an explicitly illustrative 48 MB/hour rate. The separate conversion example uses 0.25 hours to produce 12 MB per step; that duration is not an agreed orbit preset. No old per-step number was silently relabeled as an hourly rate.

Scenario/preset values and target compatibility tables remain HPC implementation data. Main/master Compatibility-renderer synchronization is SE's implementation task. Neither is claimed as tested by these documentation checks.

## Verification

All JSON files were parsed strictly; configuration IDs/required fields, response shape, check/issue status consistency, positive-goal failure, strict mass boundaries, and power-vector expectations were checked. The four source payloads match the signed agreement. Wrapper/error nullability, evidence-event references, ratio/score/abort rules, half-up ties, conversions, and action-timing expectation vectors were checked. Markdown links were checked.

This verifies documentation/example consistency. Production game tests, actual adapter execution, graphical rendering and exports have not been run by this synchronization.
