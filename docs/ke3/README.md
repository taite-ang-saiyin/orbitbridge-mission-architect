# KE3 review and integration handoff

This branch adds KE3's display-only Operations HUD, illustrative orbit/timeline, Debrief/evidence/credits and Retry intent handling. It also carries explicit development previews, regression tests and two separately identified recorded KE2 report fixtures. **No team production routing or project settings are replaced.**

## Folder map

| Folder | Responsibility | Production use |
|---|---|---|
| `ke3/` | Input-copying UI scenes/scripts, presentation session, event lookup, orbit diagram and action/route/Retry intents | SE reviews/adapts the integration seam; no science or state-owner duplication |
| `preview/` | Mounted synthetic providers, A01-A07 development routes and recorded report sources | Development only; normal startup does not load these |
| `tests/` | Existing KE3 fixture/UI regressions plus recorded-report and contract-error checks | Development only; names coexist with SE's existing tests |
| `tools/ke3/` | Portable standard-library Python verifier and standalone preview config template | Creates an isolated copied project outside this checkout |
| `docs/ke3/history/` | Historical local check reports, QA sheets and demo plan | Dates/paths describe original runs; stale observations are not current integration claims |
| `docs/ke3/evidence/` | Compact executed-check summary and report provenance | Actual branch verification result is `verification-summary.json` |

Earlier documents say previews must not enter the production merge. They remain development-only in this review branch; SE should select runtime files and wiring deliberately, not make `preview/` part of normal gameplay. The user's branch-publishing request authorizes sharing this review material, not connecting the mock providers to production.

## Public scene and signal boundary

- Operations: `res://ke3/operations_screen.tscn`, script `ke3/operations_screen.gd`.
- Results: `res://ke3/results_control.tscn`, script `ke3/debrief_screen.gd`, base `ke3/outline_control.gd`.
- Inject snapshots with `set_inputs(context: Dictionary, state: Dictionary, report: Dictionary)`. Inputs/getters are deep-copied. Rendering does not execute actions, score missions or alter provider values.
- Signals: `action_requested(run_id, action_id)`, `result_route_requested(run_id)`, `retry_requested(run_id)`. SE owns actual receivers, validated launch, state/history, report deduplication, editable drafts, new run IDs and New Mission reset.
- `ke3/presentation_session.gd` coordinates an injected provider and view activation. Its `open_run(run_id)` / `request_action(run_id, action_id)` provider seam is **not** HPC's native state-owning API. SE owns and calls the real engine.
- Native team action `transmit` needs an explicit mapping from this preview's legacy `downlink` intent/capability key. Do not pass `downlink` directly into HPC. State/history mappings are documented in historical B01 mapping, with subsequent implementation changes noted below.

## Display data and current limitations

Operations currently consumes preview-facing `step`, `energy_wh`, `stored_mb`, `returned_mb`, `generated_mb`, `observations_completed/requested`, `target_access`, `contact_on`, `action_availability.*.enabled/reason`, `results_route.enabled/reason`, and `state.events`. SE must map real `step_index`, `stored_data_mb`, `returned_data_mb`, `in_target_access`, `in_ground_contact`, `available_actions.*.allowed` and report-ready routing explicitly. Missing values show Unavailable. No cumulative generated-data or event timestamp is invented.

History stays in supplied order, with run-scoped event IDs. HPC's new-event delta and cumulative event_log must be accumulated once by SE, not appended twice. Debrief uses the matching KE2 report verbatim: outcome, run_status, actuals/targets, supplied ratios/score, explanation, root_causes[].evidence_event_ids, next_experiment, source_ids and comparison. Missing linked evidence retains the report and shows Evidence Unavailable. Empty causes remain neutral; null/missing scores display Unavailable; zero remains zero. Errors are not successful/failed mission reports.

Returned validated-run scoped credits are passed separately through `context.applicable_source_credits`, using the supplied `credit_scope`, title, attribution_text, URL and actual_use. They do not alter `report.source_ids=[]` or `comparison=null`. CubeSat 101 is credited for the executed readiness mass rule; Design and Develop Science Missions for feedback vocabulary. Source-link access and exported credits are separate checks.

A07-D01/D02 are closed in the local implementation: focused Debrief supports PageDown/Down/PageUp/Up; Operations scrolls focused actions and focus outlines into view. Original failing and retest reports remain historical evidence. The orbit diagram is labeled **Illustrative trajectory**; it is not a propagator or coverage prediction.

## Recorded runs and explicit previews

- `preview/ke2_recorded_preview.tscn`: older `run_ke2_handoff_v01`, HPC `ce478f9`, launch_approved=false. Never relabel it as a validated launch.
- `preview/ke2_validated_preview.tscn`: `ke3_validated_1u_55d4f33_9dfd942_20261114_01`, actual KE1 validation `55d4f336e72a68ff31cf37e44f65a98c1cdcc193`, HPC `9dfd942e6fccf230d03dfdf8bf097bf65d8f143f`, returned KE2 report declaring evaluator `8c3ed816f5122a6645c0517aecd83880876a0cd7`.
- Expected validated display: partial/completed, score25,1/4 observations,7.7333333328/30 decimalMB,25%/25.78%; supplied summary includes4.2666666672MB onboard. Cause NO_LINK_WINDOW -> same-run evt_008 at step8. Report SHA256: `8cfeaea913d096b42d05e7b07bf619ceb434ff760bf28880a427e42f47ec1a50`.
- A03/A05/A06 entries exercise Operations, long Debrief/error/credit cases and a synthetic two-run Retry draft. B completion is an explicit fixture delivery, not execution of HPC. Optional controlled A/B comparison is deferred.

The fixture JSON files retain their original bytes via local `.gitattributes`; report hash checks would fail if Git normalized their line endings. NASA reference URLs are supplied attribution metadata. Engine binaries, downloaded PDFs, archives, caches, large raw logs/screenshots and local Web rehearsal exports are not included.

## Reproduce without changing SE's project

Python 3 standard library and an installed Godot 4.7.2 Standard/compatible GDScript editor are sufficient. No dependencies are installed by the runner. Choose a **new output folder outside this repository**:

```powershell
python tools/ke3/verify.py --godot 'C:/path/to/Godot_v4.7.2-stable_win64_console.exe' --output-dir 'C:/Temp/ke3-check-01' --mode all
```

The runner copies only KE3 sources/fixtures/tests into output/project, installs the preview config in that copy, imports, executes suites with watchdogs, scans error logs and returns nonzero on failures/timeouts. It records exact argv/exits/logs and checks repeated inputs. `--mode headless` omits windowed/viewport checks; `--prepare-only` creates a standalone copy for manual F6 preview use without executing suites.

For manual use after preparing, launch the scene explicitly in the copied project, for example:

```powershell
godot --path 'C:/Temp/ke3-check-01/project' --scene res://preview/ke2_validated_preview.tscn
```

## SE integration still required

Current base main `1a82ebd93a019b751947965aa760e8e759d8f45b` has mock SatelliteAdapter/OperationsFixture/authored Results on its normal runtime route. This branch shares KE3 work; it does not replace those screens or wire producers. SE must supply the confirmed integration revision and implement validated canonical config/catalog mapping, actual KE1 readiness, HPC run/state/ordered history, matching KE2 report/errors and controller-owned Retry/New Mission lifecycle.

**B02 and official B10 remain NOT TESTED.** Local component/preview evidence does not establish a real player journey, teammate five-minute playtest, browser build, export, submission or scientific validation. The separate localhost Web rehearsal exported successfully but browser checks were stopped by the computer-use URL safeguard; it is not a B10 pass.
