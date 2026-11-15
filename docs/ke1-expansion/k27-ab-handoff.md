# K27 A/B radio handoff: supported Imaging first

Prepared 15 November 2026, Asia/Rangoon. Base main: `dce75db845f6c494b8c25c9028dd9c0648aabd91`, confirmed as GitHub main before this work. Status: **TESTED EXAMPLES READY; EXPANDED COMPARISON AGREEMENT/INTEGRATION PENDING**.

This package gives SE, KE2 and KE3 a real supported v1 Imaging experiment while K20 decisions remain open. It does not implement their UI, comparison evaluator or Save A storage. It does not enable Communication/Weather or create a sixth preset.

## The experiment

Same mission, same parts except radio, same initial resources, same frozen catalogs/scenario, same accepted actions. Equator/high_inc; two captures, 24 MB required, three orbits, 100-credit budget. Observe at pre-action steps 1 and 6; transmit at 7 and 10; Power-save otherwise. All requested actions are accepted in both runs, so there is no hidden fallback changing the experiment.

| Actual result | A: basic radio | B: fast radio |
| --- | --- | --- |
| Mass | 1060 g | 1120 g |
| Parts + launch cost | 82 credits | 89 credits |
| Captures | 2 | 2 |
| Returned data | About 15.4667 MB | 24 MB |
| Energy remaining | About 21.7778 Wh | About 20.8111 Wh |
| Existing Imaging report | partial / score 82 | success / score 100 |

These are actual current KE2 Imaging reports, not proposed new-mission scores. The fast radio returns more within the same two transmission steps, but costs 60 g and seven credits and consumes about 0.9667 Wh more. This conclusion applies to this fixed experiment; it is not a universal best-part claim. Values/windows are illustrative educational parameters.

## Files members can use now

| Owner | Supplied material | Immediate use | Still needs their implementation/decision |
| --- | --- | --- | --- |
| SE | Two passing v1 configs, fixed plan, immutable run A/B snapshots, validation, ordered events, bound reports | Wire one supported Imaging A/B loop and field mapping; use exact mission requirements in B | Explicit Save A storage, Continue B/Cancel routing, immutable execution lookup and final comparison eligibility; reconcile SE's branch rather than rebuilding its claimed existing hooks |
| KE2 | Actual partial/success Imaging reports, same-operation evidence and proposed matching cases | Build/test comparison presentation and report rules with genuine outcomes | Final comparison schema/eligibility, score/partial rules for new goals and v2 report versions |
| KE3 | Telemetry, readable result values, run/report IDs and heavier/costlier/faster-radio trade-off | Draft Operations/Results comparison display and unavailable states | Final Save A/Continue B/Cancel signals with SE, comparison view and execution-bound presentation |
| HPC | Same-config-except-radio pair with frozen scenario and exact action history | Verify deterministic resource/radio evidence and plan conventions | K20 event/version/capability confirmations and any production policy changes |

[Configs and plan](examples/k27-ab/README.md), [proposed matching rules](examples/k27-ab/matching-policy.proposed.json), [proposed negative cases](examples/k27-ab/matching-cases.proposed.json), [measured summary](evidence/k27-ab/summary.json), [A trace/report](evidence/k27-ab/run-a.json), [B trace/report](evidence/k27-ab/run-b.json), [integrity record](evidence/k27-ab/integrity.json).

## Proposed matching boundaries for agreement

Match the entire mission (including budget, ordered targets, capture/data requirements), all non-radio design choices, actual operating plan/history, initial conditions, catalog/scenario/source versions and terminal status. Require separate run IDs and exact run-bound reports. A saved title or preset ID alone is insufficient.

Future v2 also needs exact contract/preset revisions and complete mission.goal matching. New goal definitions and custom/edit identity are still pending. A changed operation plan must be excluded from hardware-only comparison or explicitly labelled design + operations under the final KE2/SE policy. Aborted/incomplete/evaluation-unavailable runs must not acquire invented zero scores or false controlled-comparison status.

The negative matching cases are review expectations, not outputs of an implemented comparator. Actual current `report.comparison` remains null in both reports. No shared report schema or live comparison code is changed.

## Integration acceptance checklist for the owners

- Explicit Save A captures an owned immutable execution. The automatic compatibility baseline is not a substitute for deliberate Save A.
- Not now retains A; Continue B starts an owned draft with matching mission requirements and allowed component edits.
- Cancel discards B's draft and restores the original A execution/result; launching B validates freshly and starts a distinct run ID with clean counters.
- Completing B cannot overwrite A. Results and comparison point to the requested saved executions and reject mismatched report/config evidence.
- Different requirements/catalogs/scenarios/operations are rejected or clearly labelled according to the agreed comparison policy. Missing measurements show Unavailable.
- Browser copy explains session/refresh loss accurately. Unsupported missions stay unavailable for launch.

These are future product checks, **not tests executed against SE's A/B UI or its branch**. SE reported separate design_lab hooks; they are absent from this tested main baseline. Preserve their work and agree integration ownership.

## Checks executed

Godot 4.7.2 ran [the example audit](tools/check_ab_radio_examples.gd): **36 checks passed, zero failed**. It verifies one-field config difference, both readiness results, identical accepted actions, resource bounds, deterministic native replay, fresh run IDs, same snapshots, actual existing Imaging reports, stale-requirement rejection and unchanged A while constructing B's local evidence fixture. That last check does not claim production Save A/Cancel storage works.

Independent inspection verifies run/event/config binding, physical metrics, actual data/energy trade-offs, complete action sequences and existing score arithmetic. Full maintained suite, five-mission A/B, browser UI and public Netlify acceptance were not run in this preparation.

Repeat from the project root after Godot import:

```powershell
$godotExe = '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe'
$pairExamples = Join-Path (Get-Location) 'docs\ke1-expansion\examples\k27-ab'
$pairOutput = Join-Path $env:TEMP 'orbitbridge-k27-radio'
& $godotExe --headless --path . --script docs/ke1-expansion/tools/check_ab_radio_examples.gd -- $pairExamples $pairOutput
```

## Blockers and next handoff

HPC confirmation is missing, and SE/KE2 still have conditional decisions on Weather/contact meaning, Creator/custom identity, capability source, scoring/evidence and envelope versions. The independent v1 pair lets planning proceed without pretending those decisions are resolved. Final five-preset comparison remains dependent on K20 and coordinated owner integration.

K27 is marked preparation-ready, not complete. K30's final multi-owner handoff remains pending; this local packet does not claim teammates received it. Existing game code, presets, signed agreements, reviewed archives and exports remain unchanged. Personal planning files are preserved. Nothing was committed, pushed, deployed or sent to teammates.
