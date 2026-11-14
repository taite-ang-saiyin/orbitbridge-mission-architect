# A04 orbit and timeline fixture evidence - 2026-11-14

Completed A04 only in `C:\Workspace\OrbitBridge\Event\ke3_outline_preview`, plus the requested A01–A03 regressions. No applicable AGENTS.md was found in this folder or its ancestors. A03_CHECKS.md, BOUNDARY.md, the current Operations screen, presentation session and preview provider were inspected before changes. Production wiring remains Part B.

## Selected view and scope

**2D orbit diagram**, chosen to keep P0 delivery and Compatibility rendering simple without a 3D scene, textures, physics or external runtime dependency. Browser performance was not measured. A stylized Earth disk, satellite primitive and exactly one elliptical path are labeled **Illustrative trajectory**. The explicit entry is `res://preview/a04_preview.tscn`; SYNTHETIC is visible on the entry and data. Default startup remains the original empty outline.

The diagram, HUD and timeline consume the same accepted `context/state/report` through existing `presentation_session.gd` -> `set_inputs`. Marker placement is an authored 12-position-per-turn diagram mapping of the supplied step, not a physical propagator or a mission clock. Position is normalized before resize. Missing step hides the marker and displays Unavailable. Provider false flags display Off, not Unavailable. Access/contact text uses both words and color.

The only animation is a cosmetic pulse around the fixed marker. It has no provider reference, action signal or step update. Events are replaced from each full accepted ordered snapshot, not appended locally or sorted. Event IDs and run IDs stay attached to each displayed row; IDs are available in row tooltips. Current lifecycle/phase/step is supplied state text. Event label and step/time are preserved, including step zero and time-only entries.

## Changed files

- Added `ke3/orbit_diagram.gd` and generated `.uid`: passive diagram, marker and provider-flag indicators.
- Added `ke3/event_timeline.gd` and generated `.uid`: provider-ordered rows and current state header.
- Updated `ke3/operations_screen.gd`: responsive orbit/HUD row, timeline and preview attribution footer. Existing A03 telemetry/intents remain in place.
- Updated `preview/a03_preview.gd`: small provider/banner/selector factory hooks so A04 reuses its existing entry/lifecycle methods. A03 still creates its original provider and original 13 cases.
- Updated `preview/fixture_provider.gd`: explicit mounted-entry allowlist also permits the A04 entry; no default fixture selection or failed-provider fallback was added.
- Added `preview/a04_preview.gd`, `.tscn` and script `.uid`: explicit opt-in entry. Native-size scaling is set only at runtime in this A04 entry so narrow windows stack the orbit/HUD instead of shrinking the text. Saved startup settings are unchanged.
- Added `preview/a04_provider.gd` and `.uid`: reuses all A02/A03 replies and authors `fresh_run_empty` / `fresh_run_showcase` for stable distinct run `SYNTHETIC-KE3-RUN-OPS-002`. Only this fixture provider supplies the additional launch/orbit/Save event examples; the UI invents no events.
- Added `tests/a04_visual_check.gd` and generated `.uid`: synchronization, blocked-event/click, resize, animation, re-entry, restart and fresh-run stale-delivery checks.
- Added `A04_CHECKS.md` and `A04_SOURCES_FOR_KE2.md`; generated ignored `verification/a04-*` logs, JSON, retrieved source HTML, rendered playbook page and captures; local `.godot` cache updated by import.

The historical project and Godot installation were not edited. SHA-256 baseline comparisons confirm that `project.godot`, `ke3/presentation_session.gd`, original mission fixtures, A03 provider, A01–A03 test scripts and original outline/scene files remained byte-identical. See `verification/a04-baseline.json` and `verification/a04-preservation.json`.

## Exact synchronization evidence

All accepted original A03 snapshots and the two fresh-run snapshots were replayed through the session. The deliberate stale-run and dangling-report-reference A02 cases were rejected and cleared the visual data. For every accepted update the marker step matched the HUD, flags matched the provider, and timeline text/order/IDs matched the full supplied event array. Independent expected marker coordinates used tolerance 0.00001.

Coordinates below are normalized diagram positions, not orbital coordinates. Values are rounded to six decimals for readability; full values and ordered rows are retained in `verification/a04-headless-evidence.json` and `verification/a04-compatibility-evidence.json`.

| Snapshot | Expected step / target / contact | Actual step / target / contact | Expected marker | Actual marker | Expected / actual events |
| --- | --- | --- | --- | --- | --- |
| ready_step_2 | 2 / On / Off | 2 / On / Off | 0.846410, 0.340000 | 0.846410, 0.340000 | 1 / 1 |
| observe_allowed | 3 / On / Off | 3 / On / Off | 0.900000, 0.500000 | 0.900000, 0.500000 | 2 / 2 |
| contact_on | 4 / Off / On | 4 / Off / On | 0.846410, 0.660000 | 0.846410, 0.660000 | 3 / 3 |
| downlink_contact_on | 5 / Off / On | 5 / Off / On | 0.700000, 0.777128 | 0.700000, 0.777128 | 4 / 4 |
| downlink_no_contact | 3 / On / Off | 3 / On / Off | 0.900000, 0.500000 | 0.900000, 0.500000 | 3 / 3 |
| power_save | 4 / Off / Off | 4 / Off / Off | 0.846410, 0.660000 | 0.846410, 0.660000 | 4 / 4 |
| terminal | 8 / Off / Off | 8 / Off / Off | 0.153590, 0.660000 | 0.153590, 0.660000 | 5 / 5 |
| fresh_run_empty | 2 / On / Off | 2 / On / Off | 0.846410, 0.340000 | 0.846410, 0.340000 | 0 / 0 |
| fresh_run_showcase | 5 / Off / On | 5 / Off / On | 0.700000, 0.777128 | 0.700000, 0.777128 | 7 / 7 |

Action replies for Observe, contact-on downlink and Power-save were also replayed through the original action/session path and checked for synchronization. A03's direct Power-save reply contains three events, while the separately selected A02 post-blocked Power-save snapshot contains four. The timeline displays exactly the supplied history for each rather than inventing or deducing a common sequence.

## Expected versus actual lifecycle and blocked behavior

| Check | Expected | Actual | Status |
| --- | --- | --- | --- |
| Existing scripted no-contact blocked reply | One provider action call; no UI action intent; step 3 unchanged; ready, Observe, blocked rows in that order | Exact match; 3 supplied rows | FIXTURE PASS |
| Disabled no-contact Transmit clicked twice | 0 action intents, 0 provider opens/actions, 0 added rows; marker/HUD unchanged | Exact match; original 2 rows retained | FIXTURE PASS |
| Cosmetic pulse and 30 repeated renders | Pulse runs; 0 intents/provider calls; step/marker/timeline unchanged | Exact match | FIXTURE PASS |
| Operations re-entry three times | 0 action/route/retry intents; 0 provider actions; 3 snapshot opens; 7 data rows and 7 widget rows | Exact match; no duplicates | FIXTURE PASS |
| Two fresh Compatibility processes | Both restart at OPS-001 ready step 2, one supplied event, zero actions; identical snapshot/counts | Exact JSON comparison | FIXTURE PASS |
| Fresh distinct run | OPS-002 replaces OPS-001; empty supplied event list clears old rows | Exact match; 0 event data rows and one empty-state widget | FIXTURE PASS |
| Held reply from previous run | `{accepted:false,error:late_reply}`; no old events, marker/HUD changes or extra calls | Exact reply and unchanged new-run snapshot/counts | FIXTURE PASS |
| Supplied non-sorted and time-only rows | Preserve array order; display `Time T+00:05` and measured `Step 0` | Exact match | FIXTURE PASS |
| Missing visual fields | No marker; access/contact/step Unavailable | Exact match | FIXTURE PASS |

Exact supplied blocked text: `SYNTHETIC Downlink blocked: no contact; no step advance`. The provider exercise passes that authored reply through `session.request_action` / payload acceptance. It is intentionally separate from clicking the disabled A03 Transmit control, which dispatches nothing.

## Native Compatibility resize

| Requested window | Actual window | Actual logical viewport | Layout | Result |
| --- | --- | --- | --- | --- |
| [1280, 960] | [1280, 960] | [1280.0, 960.0] | 2 columns | FIXTURE PASS |
| [900, 820] | [900, 820] | [900.0, 820.0] | 2 columns | FIXTURE PASS |
| [720, 900] | [720, 900] | [720.0, 900.0] | 1 columns | FIXTURE PASS |

Each resize preserved the full semantic snapshot and emitted zero intents/provider calls. Orbit/HUD/timeline fit horizontally; scrolling brought the entire event timeline into view. Agent-reviewed 720-pixel captures confirm native-size text and the stacked layout. The representative wide capture contains the entire orbit/HUD/seven-row timeline together. A04 runtime scaling changes are confined to its explicit preview entry; project.godot is unchanged.

## Exact commands and exit statuses

Executable: `C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe`; verified version `4.7.2.stable.official.ed1daf0bf`. Working directory for every command: `C:\Workspace\OrbitBridge\Event\ke3_outline_preview`. Both imports and final explicit startup exited 0. The initial startup check found a GDScript bool type-inference parse error despite engine exit 0; it was treated as FAIL, fixed, and replaced by clean final import/startup/suite evidence. Final results below require both exit 0 and absence of script/error messages.

| Run | Exit | Status | Actual result |
| --- | --- | --- | --- |
| a04-headless | 0 | FIXTURE PASS | SYNTHETIC A04 SUITE: 201 checks; 0 failures |
| a04-compatibility | 0 | FIXTURE PASS | SYNTHETIC A04 SUITE: 205 checks; 0 failures |
| a04-restart-first | 0 | FIXTURE PASS | SYNTHETIC A04 RESTART: 10 checks; 0 failures |
| a04-restart-second | 0 | FIXTURE PASS | SYNTHETIC A04 RESTART: 10 checks; 0 failures |
| a01-operations-headless | 0 | FIXTURE PASS | Empty-input scene fixture passed |
| a01-results-headless | 0 | FIXTURE PASS | Empty-input scene fixture passed |
| a01-operations-compatibility | 0 | FIXTURE PASS | Empty-input scene fixture passed |
| a01-results-compatibility | 0 | FIXTURE PASS | Empty-input scene fixture passed |
| a02-headless | 0 | FIXTURE PASS | SYNTHETIC FIXTURE SUITE: 246 checks; 0 failures |
| a02-compatibility | 0 | FIXTURE PASS | SYNTHETIC FIXTURE SUITE: 247 checks; 0 failures |
| a03-headless | 0 | FIXTURE PASS | SYNTHETIC A03 SUITE: 256 checks; 0 failures |
| a03-compatibility | 0 | FIXTURE PASS | SYNTHETIC A03 SUITE: 259 checks; 0 failures |

Each entry is a separate engine process. Both restart probes were actual windowed Compatibility processes. `verification/a04-actual-results.json` contains exact commands, stdout, executable and exits; `verification/a04-restart-comparison.json` contains expected/actual restart snapshots and counts. Windows/OpenGL graphics logs are local fixture evidence, not browser evidence.

```text
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a04-headless-godot.log --headless --script res://tests/a04_visual_check.gd
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a04-compatibility-godot.log --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x960 --script res://tests/a04_visual_check.gd -- --capture
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a04-restart-first-godot.log --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x960 --script res://tests/a04_visual_check.gd -- --restart-first --capture
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a04-restart-second-godot.log --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x960 --script res://tests/a04_visual_check.gd -- --restart-second --capture
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a01-operations-headless-godot.log --headless --script res://tests/empty_outline_check.gd -- operations
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a01-results-headless-godot.log --headless --script res://tests/empty_outline_check.gd -- results
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a01-operations-compatibility-godot.log --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x960 --script res://tests/empty_outline_check.gd -- operations --capture
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a01-results-compatibility-godot.log --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x960 --script res://tests/empty_outline_check.gd -- results --capture
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a02-headless-godot.log --headless --script res://tests/mission_fixture_check.gd
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a02-compatibility-godot.log --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x960 --script res://tests/mission_fixture_check.gd -- --capture
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a03-headless-godot.log --headless --script res://tests/a03_operations_check.gd
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-run-a03-compatibility-godot.log --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x960 --script res://tests/a03_operations_check.gd -- --capture
```

Final import command:

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --import --log-file 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-final-import.log'
```

Explicit preview launch (an instruction, not a claimed human playtest):

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --path 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' --rendering-method gl_compatibility --scene res://preview/a04_preview.tscn
```

## Captures and source notes

- `C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-orbit-hud-timeline.png` (1280 x 960), engine capture; agent visually reviewed representative, narrow/scroll and first-restart images.
- `C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-narrow.png` (720 x 900), engine capture; agent visually reviewed representative, narrow/scroll and first-restart images.
- `C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-narrow-timeline.png` (720 x 900), engine capture; agent visually reviewed representative, narrow/scroll and first-restart images.
- `C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-restart-first.png` (1280 x 960), engine capture; agent visually reviewed representative, narrow/scroll and first-restart images.
- `C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a04-restart-second.png` (1280 x 960), engine capture; agent visually reviewed representative, narrow/scroll and first-restart images.

Chosen NASA adaptations, exact titles/URLs and UI locations are in `A04_SOURCES_FOR_KE2.md`. The bounded reference review used 3m28s of the 45-minute maximum. NASA pages and source HTML were available. Optional historical 2023 VR and CSA pacing sources were not used; no attribution was invented for them. KE2's canonical production credits/ledger remain unverified.

## Pending live inputs and next handoff

| Provider | Exact fixture field/file or revision to confirm | Affected live check |
| --- | --- | --- |
| SE | Event repository/path, target commit SHA, applicable AGENTS.md; real Operations route, Retry and re-entry hooks | Production scene reuse, route lifecycle and restart |
| KE1/HPC | Provider commit/schema revision; `context.run_id`, `state.run_id`, numeric `state.step` and its indexing; `state.phase`, `state.lifecycle` | Marker/HUD identity and progression sync |
| KE1/HPC | `state.target_access` and `state.contact_on`: canonical names, bool types and missing/null conventions | True/false/Unavailable indicators |
| KE1/HPC | `state.events[]` cumulative full-snapshot versus delta contract; `event_id`, `run_id`, `step` or `time`, `label`; time units/origin and supplied ordering semantics | Active-run timeline order, display and re-entry duplication |
| KE1/HPC + SE | Actual `open_run(existing_run_id)` snapshot semantics, action reply/deferred callback signature and request generation/token correlation | Fresh-run reset and late-reply rejection without replaying simulation |
| KE1/HPC | Actual fields/units for energy/data/observation values and provider `action_availability` / `results_route` | Existing HUD and disabled-action behavior remains A03-owned fixture display |
| KE2 | Canonical source IDs, credit strings and ledger revision; confirmation of team-plan source links | Production attribution and credit integration |
| SE/export | Actual browser build URL and target browser/device | Browser performance and browser rendering |

These are exact current fixture paths/fields and requested revisions, not confirmed production names. No team revision or live payload was supplied. Inspect real revisions and payloads before Part B. A04 does not calculate a physical trajectory; a real position/ephemeris contract would be separate work if requested.

**FIXTURE PASS**: synchronization, blocked reply/click separation, native resize/scroll, animation/render purity, re-entry, fresh-process restart, distinct-run reset, stale delivery rejection, and A01–A03 regressions. **NOT TESTED**: browser, live team integration, human playtest and publication. NASA demo interactive playback and KE2's final attribution approval were not tested/confirmed. No LIVE or BROWSER pass is claimed. Stop after A04.
