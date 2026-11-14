# KE1 / HPC game integration

Merged-main follow-up: [SE merge record](se-main-merge.md) describes the current behavior. Operations now also supports manual native-engine actions and immutable retry; Debrief uses KE2 for Imaging and explicitly reports Survey evaluation unavailable. The earlier sections below record SE's integration stages.

Current follow-up: both mission types and all displayed target buttons are enabled. See the expanded mission section at the end; it supersedes the initial single-target scope below.

Integrated 14 November 2026. No `.tscn`, theme, model, visual asset or project setting was changed. Screen scripts keep the existing panel layout and feed it actual validation and simulation results. Existing Builder controls now also expose launch profile and launcher choices.

## Runtime boundary

`scripts/integration/mission_runtime.gd` maps the UI draft to MissionConfig. `name` becomes `mission.title`; the application's OrbitBridge title is unchanged. It loads the production KE1 catalogs, validates the current config on Launch, builds an HPC scenario, then executes the deterministic policy through `MissionStepEngine`. The run retains independent config/scenario snapshots and events. Only launch-ready configurations start. Direct Operations navigation uses the same gate. Catalog failure blocks launch.

`scripts/integration/mission_playback.gd` projects actual HPC snapshots into the existing playback controls. Play, Pause, Step, scrub and Replay inspect a computed policy run; they do not submit manual observation/transmit actions. No resource accounting is duplicated in presentation scripts. The ground track and orbital graphics remain illustrative. Temperature/attitude estimates are not fabricated.

Readiness shows all eight KE1 checks, actual mass/cost/power/storage and actionable failures. The visible source credit identifies NASA CubeSat 101, Appendix C item 6, p.79, for the sample strict `<1330 g` rule. Catalog component values, launcher limits/costs and authored orbital windows remain illustrative.

Debrief displays actual captured observations, returned MB, final energy/storage and the two most recent launches. It does not invent KE2 scores or success/failure reports. A completed simulation means its final step was reached; it does not itself mean mission goals were achieved. New Mission resets session selections/history; Modify Design preserves recent runs for inspection.

## Explicit mappings and supported scope

| Existing choice | Contract value |
| --- | --- |
| Capture Imagery | `imaging` |
| Equator (single target) | `equator` |
| LEO – 400 km | `low_eq` |
| Polar – 600 km | `high_inc` |
| Body 1 | `bus_basic`, `instrument_basic`, `battery_standard`, `storage_standard` |
| Body 2 | `bus_light`, `instrument_basic`, `battery_standard`, `storage_large` |
| Body 3 | `bus_basic`, `instrument_advanced`, `battery_standard`, `storage_standard` |
| Wings 1 / 2 / 3 | `solar_standard` / `solar_large` / `solar_standard` |
| Radio 1 / 2 / 3 | `radio_basic` / `radio_fast` / `radio_basic` |
| Sample / alternative launch profile | `cubesat_1u_sample` / `illustrative_alternative` |
| Small / medium launcher | `small` / `medium` |

These are authored gameplay presets assigned explicitly to existing buttons, not specifications inferred from NASA artwork. Variants 1 and 3 of the wings/radio are cosmetic alternatives with identical assigned engineering capabilities. The body button describes its four-component bundle. Standalone battery/instrument/storage selectors are not added.

Survey/multiple targets and unsupported regions are unavailable in the supplied scenario. Existing unsupported target/objective buttons remain visible but disabled. Legacy unsupported draft values fail validation; no multi-target draft silently picks its first target. The current UI derives the returned-data goal as 12 MB times requested captures, explicitly stated in Creator; an explicit `required_returned_data_mb` draft value overrides it. Captures and returned MB remain separate goals. Operations uses Observe First or Downlink First as the deterministic policy.

Starter is 1060 g / 82 illustrative credits. Body 3 alone is 1380 g / 96 credits and correctly fails the sample 1U limit; the alternative profile and medium launcher pass at budget 120 (116 credits). Profile/launcher choices are explicit, never silently upgraded after mass failure.

## Files and provenance

- KE1 runtime: `scripts/core/`; catalogs: `data/*.json`; regression inputs: `tests/fixtures/` and `tests/validation/`.
- HPC runtime: `core/`; original legacy fixtures: `data/fixtures/`; tests: `tests/test_hpc.gd`, `tests/test_simulator.gd`.
- Original supplied packages remain in `ke1/` and `hpc/`, excluded from engine scanning with `.gdignore` to avoid duplicate global class names.
- `data/orbits.json` is byte-identical to both supplied packages. No authored HPC orbit values were edited.
- `data/mock/SatelliteAdapter.gd` and `DesignCatalog.gd` retain their paths for existing callers, but use the actual KE1 validation boundary. Old fixture modules remain unused by integrated readiness/playback/debrief.

## Verification

Godot `4.7.2.stable.mono.official.ed1daf0bf`.

Run each suite from the project root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/orbit-check.log --script res://tests/integration_smoke.gd
```

Replace the final script path for the other suites. KE1 suites: `tests/validation/test_mission_validator.gd` (294), `test_mission_readiness.gd` (671), `test_mission_fixtures.gd` (470): 1435 passing checks. HPC contract suite: 26 passing; legacy simulator suite exits 0.

Player-flow coverage: default metrics, title mapping, unsupported multiple targets, budget launch blocking (including navigation bypass), component swaps, immutable run snapshot, real HPC playback, actual Debrief totals and two viewport sizes. Regression suites also cover all 27 visual combinations, selections/reset, readiness expansion, Operations controls, Home/settings and responsive layout. Runtime suites report the environment's macOS CA-certificate diagnostic; no GDScript errors are accepted as passing. Graphical appearance and exports have not been visually verified in this integration.

Remaining integration: KE2's actual evaluator/report API and any broader scenarios supplied by the team. No push, deployment or message was performed.

## Responsive Readiness follow-up

The preview now uses a content-sized panel instead of an anchored fixed-height wrapper. Its specs card remains inside the preview bounds. Checklist/preview columns, preview/specs, resource/coverage panels and banners stack independently when their available width decreases. Orbit metadata sits in normal document flow below the preview. Coverage values expand horizontally with a readable minimum width, and resource gauges have a minimum readable width and bounded arcs.

The integrated validator now overwrites the initially-null profile mass metadata when the check is evaluated (`Dictionary.merge(..., true)`). This corrects the UI's prior 1330 g fallback for the selected alternative profile; its real threshold is 5000 g. No rule or threshold changed. The layout regression verifies content containment, readable coverage, no resource/preview overlap, five viewport sizes and alternative-profile gauge values. Scene files remain unchanged.

## Expanded missions and orbit interaction

User-requested extension, 14 November 2026: both Creator objectives and one/two selected targets are implemented end to end. `imaging` uses pooled captures plus an independent returned-MB threshold; `survey` also requires at least one fully returned observation packet per selected target. Survey cannot request fewer captures than selected regions. Debrief displays actual per-target captures, complete deliveries and returned MB, and indicates whether the numeric goals were met; KE2 scoring remains pending.

The optional `mission.target_regions` array holds one or two unique registered target IDs. `mission.target_region` remains the first target for backward compatibility; validation rejects inconsistent fields. A legacy config without the array retains its original single-target behavior. The validator checks access for every selected target. HPC plans all selected target windows, selects visible targets deterministically, reserves survey captures for unsurveyed regions and tracks FIFO packets and actual returned bytes by target. UI counters read these results rather than dividing aggregate counts between targets.

`data/mission_scenarios.json` is a separately labelled illustrative extension, not an HPC-authored physical coverage table. Tropical Forest and Equatorial Ocean have LEO access; mid-latitude/polar targets require Polar. Both original orbit presets and their heights (400/600 km), inclinations (0/97.8 degrees), step hours, sunlight and contact windows remain byte-preserved in `data/orbits.json`. The game combines the target extension with the source catalogs at runtime. Missing extension data blocks readiness.

The Creator preview now uses the same 3D Earth/orbit stage as Operations. Both orbit paths are drawn from source height/inclination; selected is cyan, other is muted. Orbit radius is `1 + altitude_km / 6371` in Earth-radius units. Drag rotates the camera, wheel zooms, clicking a visible orbit selects it and synchronizes the dropdown. The miniature spacecraft and target markers remain illustrative. Preview completes one revolution per four display seconds and loops after the chosen 3/6/9 revolutions; duration/orbit changes reset its playhead. Operations rotates through `progress * duration_orbits * TAU` using actual mission elapsed time, including scrub/replay/expanded view. Its ground-track illustration uses the selected inclination and full orbit count; authored access windows still determine actions, not visual geographic intersections.

Budget labels now share the HSlider's actual grabber travel coordinates, including thumb-width inset; 120 credits aligns at two thirds of the 60–150 track. Tick positions recalculate on resize.

`tests/expanded_missions_smoke.gd` covers both objectives, selectable targets, LEO rejection for polar targets, full per-target deliveries, data conservation, 30/60/90-step runs, matching 3/6/9 revolution angles, orbit selection/highlighting, camera zoom and budget alignment at 1024x768, 1440x900 and 1920x1080. Existing validator/HPC/player-flow/layout suites are retained. No scene file was edited.

Readiness now shares the interactive orbit viewport, including selected-path highlighting and camera controls. Selecting another orbit there rebuilds readiness before Launch can proceed.

## Refreshed KE1/HPC creation and building

Latest local branch revisions inspected: KE1 `f4aeb0c2c63a8b415b8acfe45c56f84a75369b34`, HPC `1194b12f2cf532c23fdc70d0482e32d26d51269c`. The untracked `ke1/` and `hpc/` folders remain older reference packages; current branch objects supplied the updates. A wholesale branch merge would replace the current screens and remove the requested multi-target/Survey features, so integration is selective.

Builder now exposes all six actual KE1 catalog slots: bus, instrument, solar, battery, radio and storage. Each selection shows the catalog name/mass/cost and a capability tooltip in W, Wh, MB or MB/hour. `draft.engineering_parts` stores explicit choices, which override the existing named body/wing/radio presets when MissionConfig is assembled. Selecting a named visual preset deliberately applies its documented associated gameplay parts; independent engineering controls can then change any slot without changing the others. Reset clears custom slots. These are explicit preset mappings, never capabilities inferred from the artwork. The original catalog numeric values are unchanged.

Creator now allows `required_returned_data_mb` to be edited independently of observations. A draft without that goal starts at the previous 12 MB per requested capture default, but changing capture count no longer changes an explicitly chosen data goal. Both goals persist through Builder, readiness, native config snapshots and flight.

HPC's new `MissionStepEngine.init_validated_run(config, catalogs, run_id, mission_id)` revalidates against the exact bundle used to create the scenario and returns its `validation_result`. The game now launches through that entry point, and retains that actual returned validation with the run. Upstream operating/aborted terminal-bound checks, strict storage bounds, tighter energy epsilon and charge-clamping evidence were merged while retaining the requested multi-target tracking and packet accounting. The optional `LegacyTraceAdapter` is also imported; active Operations still uses native Wh/MB states.

Verification: `tests/creator_builder_catalog_smoke.gd` exercises actual OptionButton selections, independent data goals, camera mass/cost changes, battery/storage changes without overwriting other slots, alternative profile/launcher switching, actual validated launch and stale readiness rejection at two viewport sizes. HPC's refreshed owner suite passes 36 checks. Expanded mission, readiness, controller evaluation and responsive-layout regressions also pass. Scene files, project settings, original catalogs and native orbit data are preserved. Changes remain local; no commit/push was made.

## HPC prediction update

Integrated source commit `bd51e55` from the HPC branch (latest inspected tip `d592f52`). Imported its `predict_next_step` API and shared resource projection, while preserving SE multi-target/Survey behavior. Replaced the owner test runner with the updated source version: 48 checks pass. `tests/prediction_multitarget_smoke.gd` additionally compares all three action predictions against execution at every step for both mission types and both orbits, checks repeatability and unchanged inputs/event identity, and covers completed/aborted states and aggregate/per-target conservation. Expanded mission, Creator/Builder and controller/evaluation regressions also exit 0. No UI/scene changes or prediction display were added; this is an engine API update. No commit/push was made.
