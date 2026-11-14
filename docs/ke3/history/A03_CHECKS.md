# A03 fixture evidence - 2026-11-14

Ran A03 only in `C:\Workspace\OrbitBridge\Event\ke3_outline_preview`, with the requested A01/A02 regressions. No applicable AGENTS.md was found in this folder or its ancestors. No installation, historical project, startup, renderer, export, real simulation, evaluation or source-ledger changes were made. All new preview data is explicitly SYNTHETIC.

Executable: `C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe`; `--version` reported `4.7.2.stable.official.ed1daf0bf`. Import exited 0. The graphics log reported NVIDIA OpenGL 3.3 Compatibility.

## Changed files

- Added `ke3/operations_screen.gd`, `ke3/operations_screen.tscn`, and script `.uid`: A03 Operations view using the existing copied `set_inputs(context, state, report)` surface and intent signals.
- Updated `ke3/presentation_session.gd`: pending guard, generation/request/run tokens, deferred delivery callback, route/Retry cancellation, retired-view deactivation and provider snapshot refresh on re-entry. Existing synchronous provider calls remain supported.
- Added `preview/a03_provider.gd` and `.uid`: provider-only adapter over the original A02 fixture provider. It authors phase, target access, cumulative generated MB and capability/reason fields as literals. All A02 resource/step/observation values are reused. It supplies an authored direct Power-save reply after Observe; it does not implement numerical simulation.
- Added `preview/a03_preview.gd`, `preview/a03_preview.tscn`, and script `.uid`: explicit SYNTHETIC entry and demonstration route/Retry handlers.
- Updated `preview/fixture_provider.gd`: explicit-entry allowlist also recognizes the mounted A03 entry. Existing A02 gating behavior still passes.
- Added `tests/a03_operations_check.gd` and `.uid`: scripted UI-signal, exact-metric, pending, stale delivery, re-entry, replacement, Retry, provider-error and route tests.
- Added `A03_CHECKS.md` (this record). Generated ignored `verification/a03-*` logs, baseline/preservation JSON, exact metrics JSON, process results JSON and ready/blocked/terminal PNG captures; generated local `.godot` import cache.

Original `project.godot`, `preview/mission_fixtures.gd`, `preview/mission_preview.gd`, both A01/A02 test scripts, original outline script and original scene files are byte-identical to the pre-A03 baseline. SHA-256 comparisons are in `verification/a03-preservation.json`. The default main scene remains the empty A01 outline; the renderer remains Compatibility. A03 is reached only by explicitly opening `res://preview/a03_preview.tscn`.

## Display and ownership

The Operations screen shows step/phase, target access, contact, energy (Wh), generated/stored/returned data (MB) and observations versus goal. It preserves measured numeric zero and false flags; missing/null values display `Unavailable`. It never subtracts costs, advances steps, calculates generated data, evaluates outcomes, or infers legality from telemetry. Buttons consume provider `state.action_availability[action_id].enabled/reason`; Results route availability comes from `state.results_route`. Provider-blocked reasons remain visible beside disabled buttons, including while pending or inactive. The label Transmit maps to the already provisional provider action ID `downlink`.

A02 did not supply phase, target-access, generated-data or capability fields. The explicit A03 fixture provider authors these additional fields; the view does not derive them. They are fixture contract proposals, not confirmed KE1 field names. Reused A02 fixture files are unchanged.

## Exact expected / actual metrics and counts

Metric order below: **step / phase / target access / contact / energy / generated / stored / returned / observations-goal**. Count order: **action intents / route intents / provider action calls**. Values come directly from the test evidence JSON.

| Case | Expected metrics | Actual metrics | Expected counts | Actual counts | Status |
| --- | --- | --- | --- | --- | --- |
| Observe | 3 / Operations / On / Off / 7 Wh / 3 MB / 3 MB / 0 MB / 1/3 | 3 / Operations / On / Off / 7 Wh / 3 MB / 3 MB / 0 MB / 1/3 | 1 / 0 / 1 | 1 / 0 / 1 | FIXTURE PASS |
| Power-save | 4 / Operations / Off / Off / 8 Wh / 3 MB / 3 MB / 0 MB / 1/3 | 4 / Operations / Off / Off / 8 Wh / 3 MB / 3 MB / 0 MB / 1/3 | 1 / 0 / 1 | 1 / 0 / 1 | FIXTURE PASS |
| Contact-on Transmit | 5 / Operations / Off / On / 6 Wh / 3 MB / 1 MB / 2 MB / 1/3 | 5 / Operations / Off / On / 6 Wh / 3 MB / 1 MB / 2 MB / 1/3 | 1 / 0 / 1 | 1 / 0 / 1 | FIXTURE PASS |
| Blocked no-contact Transmit | 3 / Operations / On / Off / 7 Wh / 3 MB / 3 MB / 0 MB / 1/3 | 3 / Operations / On / Off / 7 Wh / 3 MB / 3 MB / 0 MB / 1/3 | 0 / 0 / 0 | 0 / 0 / 0 | FIXTURE PASS |
| Terminal route request | 8 / Terminal / Off / Off / 5 Wh / 3 MB / 1 MB / 2 MB / 1/3 | 8 / Terminal / Off / Off / 5 Wh / 3 MB / 1 MB / 2 MB / 1/3 | 0 / 1 / 0 | 0 / 1 / 0 | FIXTURE PASS |
| Pending duplicate Observe clicks | 2 / Operations / On / Off / 8 Wh / 2 MB / 2 MB / 0 MB / 0/3 | 2 / Operations / On / Off / 8 Wh / 2 MB / 2 MB / 0 MB / 0/3 | 1 / 0 / 1 | 1 / 0 / 1 | FIXTURE PASS |

The disabled no-contact Transmit click is not an accepted action: expected/actual action intents and provider calls are both zero. Separately, the provider's original A02 blocked reply is still exercised through `accept_payload` and leaves step/resources unchanged. Terminal rendering does not automatically route; one accepted Results click sends one route intent, and a second press is suppressed. The demonstration tab changes to Results without a provider action or step advance.

## Pending and lifecycle evidence

- Pending Observe: two button emissions plus a direct duplicate session call produce one intent and one dispatch. Before delivery, the view stays at ready step 2, 8 Wh, generated/stored 2 MB, returned 0 MB, 0/3 observations. The matching callback supplies step 3 and all new metrics. Duplicate completed callbacks are rejected.
- Route exit invalidates the request generation. On re-entry, `open_run(existing_run_id)` fetches the provider's current snapshot without replaying an action. The test provider had already authored Observe, so re-entry shows step 3 from a fresh snapshot, not from the rejected late callback.
- Retained old views are inactive after rebinding. Replacement/re-entry has one action receiver and emits one intent per accepted click.
- Retry invalidates pending presentation work, clears the old run display and waits for SE/provider to open a run. The actual Retry button emits once even when its signal is artificially repeated. No provider action/reset/step is invoked by Retry.
- Provider errors release pending, visibly report the error and show Unavailable telemetry. Explicit reopening recovers. Re-entry open errors clear old telemetry. No provider failure activates mock fallback.

Cancelling presentation does not undo a provider action or promise simulation cancellation. The provider remains authoritative. Deferred callbacks must use `receive_action_reply(token, reply)`; `accept_payload` is the synchronous/pushed-snapshot acceptance boundary, not an asynchronous callback without a token. Callbacks are delivered on the Godot main thread by the tested adapter.

| Late delivery case | Expected error | Actual error | Expected pending | Actual pending | Telemetry/counts unchanged |
| --- | --- | --- | --- | --- | --- |
| Duplicate completed delivery | late_reply | late_reply | False | False | True |
| Reply after route change | late_reply | late_reply | False | False | True |
| Old same-run reply after re-entry with newer request | late_reply | late_reply | True | True | True |
| Reply targeting replaced screen | late_reply | late_reply | False | False | True |
| Reply after Retry | late_reply | late_reply | False | False | True |
| Old Retry-era reply with newer same-ID request | late_reply | late_reply | True | True | True |

Full expected/actual dictionaries, counts and late-reply records are in `verification/a03-headless-metrics.json` and `verification/a03-compatibility-metrics.json`. Zero and missing/null telemetry checks use independent literal expected strings and inspect the rendered telemetry label.

## Commands and actual results

Exact executed process command lines, stdout and exit statuses are saved in `verification/a03-actual-results.json`. Each test ran in its own Godot process.

| Check | Exit | Status | Actual result |
| --- | --- | --- | --- |
| a03-headless | 0 | FIXTURE PASS | SYNTHETIC A03 SUITE: 256 checks; 0 failures |
| a03-compatibility | 0 | FIXTURE PASS | SYNTHETIC A03 SUITE: 259 checks; 0 failures |
| a01-operations-headless | 0 | FIXTURE PASS | Empty-input scene fixture passed |
| a01-results-headless | 0 | FIXTURE PASS | Empty-input scene fixture passed |
| a01-operations-compatibility | 0 | FIXTURE PASS | Empty-input scene fixture passed |
| a01-results-compatibility | 0 | FIXTURE PASS | Empty-input scene fixture passed |
| a02-headless | 0 | FIXTURE PASS | SYNTHETIC FIXTURE SUITE: 246 checks; 0 failures |
| a02-compatibility | 0 | FIXTURE PASS | SYNTHETIC FIXTURE SUITE: 247 checks; 0 failures |

Exact process commands:

```text
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a03-headless-godot.log --headless --script res://tests/a03_operations_check.gd
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a03-compatibility-godot.log --rendering-method gl_compatibility --audio-driver Dummy --resolution 1100x820 --script res://tests/a03_operations_check.gd -- --capture
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a01-operations-headless-godot.log --headless --script res://tests/empty_outline_check.gd -- operations
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a01-results-headless-godot.log --headless --script res://tests/empty_outline_check.gd -- results
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a01-operations-compatibility-godot.log --rendering-method gl_compatibility --audio-driver Dummy --resolution 1100x820 --script res://tests/empty_outline_check.gd -- operations --capture
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a01-results-compatibility-godot.log --rendering-method gl_compatibility --audio-driver Dummy --resolution 1100x820 --script res://tests/empty_outline_check.gd -- results --capture
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a02-headless-godot.log --headless --script res://tests/mission_fixture_check.gd
C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --path C:\Workspace\OrbitBridge\Event\ke3_outline_preview --log-file C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a02-compatibility-godot.log --rendering-method gl_compatibility --audio-driver Dummy --resolution 1100x820 --script res://tests/mission_fixture_check.gd -- --capture
```

Explicit interactive launch (instruction only; not a claimed human playtest):

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --path 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' --rendering-method gl_compatibility --scene res://preview/a03_preview.tscn
```

## Scope of evidence and next handoff

FIXTURE PASS: A03 headless and actual windowed Compatibility runs, all requested metric/intent cases, pending and lifecycle checks, A01 Operations/Results empty-input regressions in both modes, and A02 mission regressions in both modes. Agent-reviewed engine captures show ready telemetry, the persistent No contact blocked reason, and terminal routing availability without clipping. Automated button signals are not a human playtest.

NOT TESTED: actual live KE1/SE provider integration, browser/export, human playtest, publication and external source confirmation. No LIVE PASS or BROWSER PASS is claimed.

SE supplies the event project/revision and production route/Retry lifecycle hooks, plus confirmation that `open_run(existing_run_id)` returns an existing-run snapshot without recreating it. KE1 supplies the real state/action reply schema and units for `phase`, `target_access`, `generated_mb`, `action_availability` and `results_route`, plus deferred reply token/cancellation behavior. These are currently exact fixture fields, with actual production field/file mappings pending. Missing inputs affect LIVE telemetry, legality/capability display, late-reply integration and re-entry tests. KE2 report/ledger contracts remain pending and were not wired by A03. Inspect the supplied revision and payload before Part B.

Candidate handoff: review `ke3/operations_screen.gd/.tscn` and the updated session against the real event project. Keep explicit preview providers, fixture harnesses, local startup settings, cache and evidence resources out of production. SE owns production routing/export; KE1 owns simulation, costs, advancement and legality.
