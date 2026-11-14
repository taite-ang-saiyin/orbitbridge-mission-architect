# KE3 merged with main

Base main: `9a5f1743549e61bcacae5c5f59bf9a658018e8af` (includes KE2).
KE3: `52a4d4aa39fe7e2fe9baf53bf43a00d1147c8dc0`.

## Result

KE3's execution-bound Results, event evidence, scoped credits, keyboard accessibility, and editable redesign are combined with main's manual engine actions, predictions, immutable immediate Retry, launch validation, lifecycle guards, playback resumption, and Windows verification hook.

The user explicitly selected both Results actions:

- **Retry same mission:** immediately starts a new run using saved config and catalog snapshots, with clean counters/events and prior reports preserved.
- **Modify design:** opens a separate Builder draft. Invalid changes stay blocked by real readiness checks. **Cancel Retry** restores the original session, report, and baseline exactly. A successful edited launch clears the pending edit and creates a new run.

Both actions are disabled for a mismatched/stale report. Survey can still be inspected and retried with an explicit scoring-unavailable message; no Survey score or A/B comparison is fabricated.

## Conflict decisions

| File | Resolution |
| --- | --- |
| `scripts/MissionController.gd` | Main's launch/edit/result/abort guards and verification hook, plus separate editable redesign and Cancel from KE3. |
| `scripts/integration/mission_runtime.gd` | Main's frozen snapshots, bounded policy generation, manual dispatch and trace resumption; KE3's session-based identity namespacing. |
| `scripts/prototype/Screen.gd` | KE3's Results/evidence/keyboard layout, both user-selected buttons, readable history and main's per-target totals. |
| `scripts/screens/MissionOperations.gd` | Main's three manual controls and native predictions, with KE3's event identities, step telemetry and focus scrolling. |
| `tests/controller_evaluation_smoke.gd` | Main's lifecycle cases, using the explicit immediate-retry button label; editable redesign is separately covered by KE3 and merge tests. |
| `data/nasa_sources.json` | Keep the newer KE2 ledger already in main, including its independent boundary-verification record. |

The signed agreement, KE1 validation/catalog rules, native HPC engine/orbit data, current KE2 evaluator/feedback, project startup, and export presets are unchanged from base main.

The complete published KE3 revision and its evidence archive were verified by Git object hashes. No archive content was substituted or regenerated. Historical handoff/status documents remain historical; this report describes the merged application.

## Verification

The active runner covers 36 programs: the existing 25 plus KE2/KE3 adapter/binding/route/power checks, isolated preview regression checks, and a 23-assertion merge suite for both retry intents and preserved controls. Synthetic preview checks validate presentation/session wiring; they are not independent verification of flight physics. The five declared KE2 pending checks are not counted as passes.

Older preview tests now create their output folders and honor `--output-dir`; the mission-fixture check recognizes the production startup as well as the isolated preview project's startup. These changes preserve the assertions and keep generated evidence under ignored `exports/` when using the active runner.

The Windows release passes 48 scenario assertions plus 22 package assertions (70/0), headlessly and with graphics. Export logs have no error diagnostics. GPU-rendered checks inspect the workflow, real manual-action HUD, long Results at 1440x900 and 900x680, editable Builder and Cancel restoration. This is automated/visual QA, not a teammate playtest.

Final program results, log hashes, protected-input hashes, and executable SHA-256: [verification record](verification/ke3-main-merge-checks.json).

## Remaining limits

- Survey scoring and controlled A/B comparison remain unavailable.
- The separate `ke3_checkpoint_cases.gd` archived-sequence comparisons and `ke3_packet_reports_check.gd` require original external packet folders, including input files/hash manifests that the tracked handoff summary does not contain. Their archived-packet assertions are not claimed as rerun. Fresh route, science-goal, real power/launcher, execution-binding and recorded-Results checks are included in the active runner.
- Browser behavior, another Windows computer, final human acceptance, and final submission are separate work.
- Existing local user files are preserved; only the isolated integration checkout was used.
