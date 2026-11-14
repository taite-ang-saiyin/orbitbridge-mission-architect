# KE3 SYNTHETIC mission fixture record - 2026-11-14

Completed the requested fixture prompt in the isolated GDScript Compatibility preview. Standard executable: `C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe`; version `4.7.2.stable.official.ed1daf0bf`. No applicable AGENTS.md or event gameplay project was found on reinspection. Historical repository Git status remains clean (`main...origin/main`). Installation and startup settings were preserved.

## Changed files

- Added `preview/mission_fixtures.gd` and generated `.uid`: literal mission, stable run/event IDs, seven operations cases and six report cases; expected values accompany each reply.
- Added `preview/fixture_provider.gd` and generated `.uid`: scripted reply selection; requires the actual mounted explicit preview entry; no numerical simulation or real legality decisions.
- Added `preview/mission_preview.tscn`, `preview/mission_preview.gd` and generated `.uid`: explicit preview selector and SYNTHETIC action buttons using existing intents and the shared provider seam.
- Added `ke3/presentation_session.gd` and generated `.uid`: proposed injected-provider `open_run` / `request_action` / `accept_payload` seam feeding existing `set_inputs` on both views. No fixture reference or fallback exists in this file.
- Updated `ke3/outline_control.gd`: display-only boundary diagnostics and literal state/report summaries; Operations emphasizes state and Results emphasizes report. Rendering remains free of gameplay side effects.
- Added `tests/mission_fixture_check.gd` and generated `.uid`: fixture, UI-signal, identity, reference, isolation and failure-path checks.
- Added `preview/README.md`, this check record, and `verification/.gdignore`; updated `BOUNDARY.md` and linked this record from `KE3_CHECKS.md`.
- Generated ignored `verification/mission-fixtures.json` (full inspectable fixture values), `mission-actual-results.json`, `entry-startup-results.json`, suite/startup/import logs and `mission-partial.png`. Local `.godot` cache remains outside handoff.

`project.godot` was not changed: default main scene is still `res://ke3/operations_control.tscn`; renderer is still `gl_compatibility`. Neither normal outline scene nor the general provider seam imports `preview/`. Local startup, preview fixtures and harnesses must remain outside the production merge.

## Fixture coverage

The mission has a synthetic target, 3 requested observations, 4 MB return threshold, duration 8 steps, budget 1200 synthetic credits, seven selected part/launcher IDs, selected orbit ID and SYNTHETIC profile/source labels. Values and labels have no external confirmation.

Ready: step 2, 8 Wh, 2 MB stored, 0 MB returned, contact off. Allowed Observe: step 3, 7 Wh, 3 MB stored, 1/3 observations. No-contact Downlink: blocked reply with unchanged step/resources. Power-save after that blocked reply: step 4, 8 Wh, 3 MB stored. Independent contact-on example Downlink: step 5, 6 Wh, 1 MB stored, 2 MB returned. Terminal: step 8 with no scripted action transition. Every state/event has a stable run/event identifier.

Success report: 3/3 observations, 4/4 MB. Partial: 1/3 observations, 2/4 MB, exactly one cause and one suggested change. Failure: 0/3 observations, 0/4 MB. Missing report remains `{}`. Stale report run ID and dangling report event reference are deliberate invalid examples, rejected with cleared views and explicit diagnostics. No score, outcome, threshold result, or source confirmation is calculated locally.

All 13 fixture cases travel through `open_run` -> `accept_payload` -> both existing `set_inputs` methods. Scripted actions travel from actual preview button signals -> Operations intent -> session `request_action` -> provider reply -> the same acceptance/rendering path. Future live providers must use this same proposed seam after SE/KE1/KE2 agree the actual interfaces; no actual production provider has been supplied or wired.

## Commands

Exact commands, stdout and exits are saved in `verification/mission-actual-results.json` and `verification/entry-startup-results.json`. PowerShell equivalents:

```powershell
$godot = 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe'
$preview = 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview'
& $godot --headless --path $preview --editor --import --log-file "$preview\verification\fixtures-import.log"
& $godot --path $preview --log-file "$preview\verification\mission-headless-godot.log" --headless --script res://tests/mission_fixture_check.gd
& $godot --path $preview --log-file "$preview\verification\mission-compatibility-godot.log" --rendering-method gl_compatibility --audio-driver Dummy --resolution 1100x820 --script res://tests/mission_fixture_check.gd -- --capture
& $godot --path $preview --log-file "$preview\verification\operations-empty-regression-godot.log" --headless --script res://tests/empty_outline_check.gd -- operations
& $godot --path $preview --log-file "$preview\verification\results-empty-regression-godot.log" --headless --script res://tests/empty_outline_check.gd -- results
& $godot --headless --path $preview --quit-after 5
& $godot --headless --path $preview --quit-after 5 --scene res://preview/mission_preview.tscn
```

To inspect interactively, explicitly run the preview scene (this last command is a user launch instruction, not a claimed human playtest):

```powershell
& $godot --path $preview --rendering-method gl_compatibility --scene res://preview/mission_preview.tscn
```

## Actual results

| Check | Exit | Evidence status |
| --- | --- | --- |
| Import/parse | 0 | FIXTURE PASS |
| Headless mission suite | 0 | FIXTURE PASS: 246 assertions, 0 failures |
| Windowed Compatibility mission suite | 0 | FIXTURE PASS: 247 assertions, 0 failures; NVIDIA OpenGL 3.3 Compatibility log; capture saved |
| Operations empty-input regression | 0 | FIXTURE PASS: no draft mutation, step advance or emitted intent |
| Results empty-input regression | 0 | FIXTURE PASS: no draft mutation, step advance or emitted intent |
| Default normal startup | 0 | FIXTURE PASS: normal empty outline still the configured main scene |
| Explicit preview scene startup | 0 | FIXTURE PASS |
| Partial report capture, agent visual inspection | N/A | FIXTURE PASS: SYNTHETIC markings, partial status, 1/3 observations, 2/4 MB, one cause and one change visible |
| Actual live team provider / domain behavior | N/A | NOT TESTED |
| Browser/export | N/A | NOT TESTED |
| Human playtest / publication / external source confirmation | N/A | NOT TESTED |

Selection isolation checks reject direct provider construction without the entry, detached entry objects, and providers retained after the entry leaves the tree. Missing and failed live providers clear presentation and never activate mocks. A failure injected after a mock provider had previously been used made zero calls to that mock provider. Malformed live replies also stayed unavailable. Those live-failure-path checks use synthetic test doubles and are FIXTURE PASS, not LIVE PASS.

Render/selection of all fixture cases emits no action, route or retry intent. Stable IDs were checked across fresh fixture construction, reused event contents were checked for consistency, and all valid payloads were presented through the shared methods without mutation. Both deliberate invalid report cases produced their expected diagnostics. No new real HPC state, legal-action rules, evaluation logic or shared draft owner was introduced.

## Next handoff

SE: supply event project path, kickoff record, revision, applicable AGENTS.md, real provider factory and actual context/intent/run-identity contract. KE1: supply revision and state/events/action-reply payload file/schema, including real run/event IDs, step/time/resource fields and units, action IDs and legality representation. KE2: supply revision and report/credits/ledger payload file/schema, including real run ID, metrics/units, event evidence references and source ledger revision. These actual filenames/field mappings are still pending and must be inspected before Part B wiring. Missing inputs affect LIVE integration, action legality/simulation, evaluation and source-credit tests respectively. SE also supplies a browser build/URL before any browser check.

The fixture-specific field names and values are documented in `preview/README.md` and the exported fixture JSON. They are proposals and illustrative samples, not confirmed team payloads. SE reviews the candidate presentation/session boundary; keep `preview/`, harnesses and local startup out of production. No LIVE PASS, BROWSER PASS, human playtest, publication, or source-confirmation claim is made.
