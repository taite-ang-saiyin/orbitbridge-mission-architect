# KE1 review package for KE2: K20 draft 2

Prepared 15 November 2026, Asia/Rangoon. Base main: `dce75db845f6c494b8c25c9028dd9c0648aabd91`. This is a review overlay for that existing Godot project, not a complete game or a merged release.

Current follow-up: this original draft-2 package is supplemented by review revision `k20-review-additions-1`: exact proposed validation, parts/capabilities and examples. Read the links from the current K20 draft. The original ZIP is retained as a dated review snapshot; it does not contain these later additions. A separate review-additions packet accompanies the update. No team approval is inferred.

## Revisions and status

KE2's relayed proposal is incorporated: config v2, `mission.goal`, root preset identity and the Communication starter with `radio_fast`. Registry: `five-presets-candidate-2`; contract: `expansion-goals-v2-draft-2`; Communication preset revision: `2`. Other presets keep revision `1`, unchanged mission/design values and unchanged supported v1 inputs. Their candidate contract marker advances to draft 2 so reviewers use one interface revision.

Communication uses high_inc, equator, two captures, three orbits, 12 MB, two positive transmission steps, basic instrument, fast radio, remaining stock parts and a 100-credit budget. Measured totals: **1120 g / 89 credits**.

**HPC and SE confirmations remain pending.** KE2's support for these choices is recorded from the user's message; package receipt, complete scoring/report decisions and integrated approval are not assumed. KE3 supported the earlier draft's direction; integration approval remains pending. Signed shared agreements are unchanged.

## Files to review

| File | Purpose |
| --- | --- |
| [K20 draft](k20-interface-review.md) | Fields, goals, evidence rules, starter and owner status |
| [Candidate registry](../../data/mission_presets.json) | Five definitions and proposed config v2 objects |
| [Catalog API](../../scripts/core/mission_preset_catalog.gd) | Load/inspect/look up independent copies; no launch authorization |
| [Catalog tests](../../tests/validation/test_mission_presets.gd) | 70 checks: defaults, totals, revisions, malformed inputs and no fallback |
| [Starter diagnostic](tools/check_communication_starter.gd) | Derives the actual candidate and tests hardware/actions through a test-only supported v1 Imaging surrogate |
| [Starter evidence](evidence/ke2-draft-2/communication-fast-radio-check.json) | Intended candidate, physical inputs, events and final states for success and count-only shortfall |
| [Catalog evidence](evidence/ke2-draft-2/mission-presets-check.json) | Five physical readiness results and revision markers |

The ZIP retains repository-relative paths and includes GDScript `.uid` sidecars, final logs, a root README and a SHA256 manifest. Personal `AGENTS.md`, `GEMINI.md`, `tasks.md`, PDFs, export settings, builds and editor caches are excluded.

## How to use the package

1. Extract into a separate review folder. Read the root README and manifest before copying anything into a checkout.
2. Use shared main at the base revision above, or reconcile later changes with SE. KE2's previously described `4c65496` checkout is older than this baseline.
3. Copy included files into matching paths after checking local edits. Do not replace entire directories or overwrite another member's work.
4. Import with Godot 4.7.2 and run the checks below. Existing runtime, validator, validation support, mock design catalog and native engine modules are dependencies already present on the specified main; this ZIP does not replace them.
5. Reply with the exact contract/registry/preset revisions reviewed and remaining questions. Keep the new cards disabled until goals propagate through validation, the HPC adapter/engine, frozen storage, KE2 reports and UI.

From the project root, replace `$godotExe` with your executable path:

```powershell
$godotExe = 'C:\Tools\Godot\Godot.exe'
$reviewOutput = Join-Path $env:TEMP 'orbitbridge-ke2-draft-2-review'
& $godotExe --headless --path . --script tests/validation/test_mission_presets.gd -- $reviewOutput
& $godotExe --headless --path . --script docs/ke1-expansion/tools/check_communication_starter.gd -- $reviewOutput
```

Expected: 70 catalog checks and 265 starter checks, zero failures. Inspect both JSON results and console output. The existing `tests/validation/test_mission_validator.gd` also passed 294 checks in this task: **629 checks across three programs**. The full suite and browser/deployment were not tested here.

## API boundary

```gdscript
const Presets = preload("res://scripts/core/mission_preset_catalog.gd")
var loaded = Presets.load_registry()
if loaded.ok:
    var found = Presets.get_preset(loaded.registry, "communication")
    if found.ok:
        var proposed_config = found.preset.candidate_config_v2
```

This retrieves review data, **not a currently accepted launch config**. `existing_v1_config(..., "communication")` and Weather deliberately return `GOAL_EXTENSION_PENDING` without a config. The physical surrogate is never exposed by that API. Do not discard goals and present an Imaging score as a new-objective result.

Preset revisions accept positive whole numeric values and must match the candidate's root `preset_revision`. Booleans, zero and mismatches are rejected safely. Registry format remains version `1`; config v2 and state/event/report versions are separate concepts.

## Measured evidence and decisions

| Trial | Positive return steps | MB | Diagnostic result |
| --- | --- | --- | --- |
| Candidate: captures 1/6; transmit 7/10 | 7 and 10 | 24 | Count and data met |
| Control: capture 1; attempt transmit 7/10 | 7 only | 12 | Data met; count missed; second attempt rejected with `NO_DATA` |

The candidate returns approximately 19.3333 MB then 4.6667 MB. These are zero-based pre-action steps from same-run engine events. Exact inputs and events are in the evidence. Values/windows are illustrative gameplay assumptions, not physical coverage or radio predictions.

- HPC: confirm this exact starter and shortfall, pre-action/event semantics, policy and its state/event versions.
- SE: confirm v2 mapping, root identity/revisions, frozen snapshots, review invalidation, retry and storage.
- KE2: align goal-specific evaluation, partial/score rules, report version and comparison against this revision after coordination.

No commit, push, deployment, teammate message or receipt claim is part of package preparation.
