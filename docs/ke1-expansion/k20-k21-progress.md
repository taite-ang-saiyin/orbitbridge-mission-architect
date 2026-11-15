# K20/K21 work record

Date: 15 November 2026, Asia/Rangoon. Base main: `dce75db845f6c494b8c25c9028dd9c0648aabd91`. Work is local and uncommitted.

## Latest owner review status

The user relayed explicit SE/KE3 review of Additions 1 and KE2 receipt/support for draft 2, candidate 2 and Communication revision 2. [The owner-review record](k20-owner-review-record.md) separates their reported checks from local runs. SE/KE3 confirm planning material; KE2 confirms the listed config/starter choices. HPC, open definitions/identity/capability/report decisions and final agreement remain pending. K26 receipt is not inferred. The earlier records below retain their historical wording/status.

## Current review additions: exact rules, parts and examples

User requested K20 review additions after SE feedback. Review revision `k20-review-additions-1` supplies [exact proposed rules](k20-validation-review.md), [parts/capabilities](k20-parts-review.md), [40 full config/context examples](examples/k20-review/README.md) and [separate verification evidence](evidence/k20-review-additions/checks.json). Seven candidate-valid and 33 invalid/context expectations were checked offline; 110 native-engine checks verify nine physical examples and two Weather delivery traces. These are documentation/physical checks, not K22 or v2 acceptance. W1 delivery, C1 window/step semantics, exact rules/capability registration and owner approvals remain pending. Candidate 2 and config marker draft 2 are unchanged. Prior tests below remain historical to their stated update.

## Earlier fast-radio update: draft 2 and candidate 2

The user relayed KE2's support for config v2, nested goals, root preset identity and a fast-radio Communication starter, then requested the matching update/package. [K20 draft 2](k20-interface-review.md) incorporates those choices. **HPC and SE confirmations remain pending**. KE2 package receipt and complete scoring/report approval are not assumed. KE3 supported the earlier direction; integration approval remains pending. Shared contracts and signatures are unchanged.

Current contract: `expansion-goals-v2-draft-2`. Registry: `five-presets-candidate-2`. Communication preset revision: `2`, with basic instrument and fast radio: **1120 g / 89 credits**. All other presets keep revision `1` and prior mission/design values; all candidate configs now name draft 2. The three original v1 configs are unchanged.

Executed in this update: **70 catalog checks + 265 exact-starter checks + 294 existing validator checks = 629 passed, zero failed**. [Current catalog evidence](evidence/ke2-draft-2/mission-presets-check.json) replaces candidate 1 measurements for current review. The other four physical setups remain 1060 g / 82 credits. [Exact fast-radio traces](evidence/ke2-draft-2/communication-fast-radio-check.json) show two captures returning 24 MB at steps 7/10; a one-capture control returns 12 MB in one positive step, isolating the count shortfall. These use test-only v1 physical surrogates, not enabled new objectives.

The [KE2 package guide](ke2-review-package.md) lists files, API boundaries, commands and pending decisions. API signatures are unchanged; preset revisions now accept positive whole values matching the candidate identity. Booleans/zero/mismatches fail safely. New missions still return `GOAL_EXTENSION_PENDING` from the legacy-config API. Full suite/browser/deployment were not tested in this update. K20/K21 remain unchecked.

The earlier record below is retained as history, including its original test counts and basic-radio setup. It does not describe candidate 2's radio or current owner-review status.

## Original K20 draft 1 record (historical)

The user confirmed that HPC/KE2/SE have not agreed on the expansion interface and requested a review draft. [k20-interface-review.md](k20-interface-review.md) now specifies canonical IDs, distinct goal count fields, config version 2, preserved v1 inputs, packet/contact/orbit evidence, review/report identity and the owner decisions still needed. Existing signed agreement and contracts are unchanged.

K20's review-draft work is delivered, but its agreement checkbox remains open. No owner acceptance, revised score formula or state/report version has been invented.

## Original K21 candidate 1 record (historical)

| ID | Name | Current state |
| --- | --- | --- |
| estuary_watch | Estuary Watch | Original Imaging input preserved |
| tropical_forest_watch | Tropical Forest Watch | Original Imaging input preserved |
| polar_ice_survey | Polar Ice Survey | Original Survey input preserved; scorer still unavailable |
| communication | Communication | Candidate contact-count goal; awaiting v2 support |
| weather_monitoring | Weather Monitoring | Candidate repeat-orbit goal; awaiting v2 support |

Files: [data/mission_presets.json](../../data/mission_presets.json), [safe loader](../../scripts/core/mission_preset_catalog.gd), [tests](../../tests/validation/test_mission_presets.gd). This is KE1's registry delivery. The task stays marked candidate-ready because final agreement and activation are not complete. Mission Control still shows its original three cards; SE must wire five cards after the goal path is supported. No UI, simulator or evaluator file was modified by this work.

Loader entry points:

```gdscript
const Presets = preload("res://scripts/core/mission_preset_catalog.gd")
var loaded = Presets.load_registry()
var definition = Presets.get_preset(loaded.registry, "communication")
var old_input = Presets.existing_v1_config(loaded.registry, "estuary_watch")
```

Check `.ok` before consuming results. Definition retrieval does not authorize launch. `existing_v1_config(..., "communication")` and Weather return `GOAL_EXTENSION_PENDING` with no config. Every retrieval is an independent copy. Registry/schema mistakes return structured errors and no partial registry.

## Original tests executed (historical)

Godot 4.7.2, headless, on an isolated copy of the same source plus this change:

| Program | Result |
| --- | --- |
| tests/validation/test_mission_presets.gd | 60 passed, 0 failed |
| tests/validation/test_mission_validator.gd | 294 passed, 0 failed |
| tests/validation/test_mission_readiness.gd | 671 passed, 0 failed |
| tests/validation/test_mission_fixtures.gd | 470 passed, 0 failed |
| tests/mission_control_smoke.gd | Passed, exit 0 |
| tests/integration/test_ke3_merge.gd | 25 passed, 0 failed |

Total: six programs passed, 1,520 counted assertions plus the uncounted Mission Control smoke assertions. New checks cover exact five IDs, three unchanged defaults, all eight readiness gates on five stock designs, independent copies, malformed/mixed goals, invalid counts, unknown/missing IDs, false agreement/availability markers, unsupported config v2 and no Imaging fallback. All five stock setups measure 1060 g and 82 credits in the current illustrative catalog. Readiness checks for new missions use a test-only v1 physical surrogate, not an exposed runtime conversion or a new-goal success claim.

The new test is included in `tests/run_all_checks.ps1` for later integration runs. The entire expanded 44-program command was not rerun because this isolated catalog is not connected to gameplay. No new Web export or public Netlify test is claimed. [Structured preset evidence](evidence/k21-preset-check.json).

Reproduce from the project root after Godot import:

```powershell
$godotExe = '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe'
& $godotExe --headless --path . --script tests/validation/test_mission_presets.gd
```

## Original blockers and handoff (historical; current status above)

- K20 needs actual HPC/KE2/SE review and agreement before its contract can be frozen.
- K22 and owner integration must accept and propagate goal-bearing config v2 before new missions can launch with correct scoring. Do not remove that gate to make a card appear playable.
- HPC still owns the Weather revisit policy and event meaning. Existing Observe First can take both images in one orbit.
- KE2 still owns Survey, contact/revisit scoring and A/B outcome rules. SE/KE3 own the player-facing integration.

Personal instructions/task files are retained and updated to the current task scope. Local export settings, generated browser files, original signed agreements, shared v1 catalogs and existing execution behavior are preserved. Nothing is committed, pushed, deployed or sent to teammates.
