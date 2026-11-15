# K22 preparation: separate draft v2 checker

Prepared 15 November 2026, Asia/Rangoon. Base main: `dce75db845f6c494b8c25c9028dd9c0648aabd91`, confirmed as GitHub main before this work. Checker revision: `k22-v2-review-1`. **Preparation is ready; production v2 integration and owner agreement remain pending.**

## What is ready

[mission_config_v2_draft_checker.gd](../../scripts/core/mission_config_v2_draft_checker.gd) is a separate, pure checker for the proposed draft-2 authored-preset config. It checks required/unknown fields, types, finite whole numeric counts, common bounds, objective/goal pairs, target consistency, preset identity/revision, registered part categories, explicit proposed instrument capabilities and cross-field count limits.

Survey delivery counts cannot exceed available captures per selected target. Weather's orbit count cannot exceed duration or capture quota; its delivery meaning is still unresolved. Communication's step count is bounded by the selected scenario's actual steps_per_orbit and duration, with an overflow check; it is not capped by capture count or a hard-coded ten.

The checker delegates physical metrics and eight readiness gates to the unchanged v1 validator using a local private physical input. For Communication/Weather this is a test-only Imaging surrogate. It is never returned, registered or launched. The supplied catalogs are not extended or changed. Instrument support is checked against explicit proposal data; existing Imaging/Survey must also retain support in the effective legacy catalog. Missing/spoofed capability context fails closed.

## API and result meaning

```gdscript
const Draft = preload("res://scripts/core/mission_config_v2_draft_checker.gd")
var review = Draft.check(config, effective_catalogs, candidate_registry, capability_proposal)
```

All four arguments are explicit input data. Obtain effective catalogs from the existing MissionRuntime loader outside the checker; load the candidate registry and K20 proposed capability data separately. The checker does no file access, scene work, randomness, clock lookup, mutation or I/O. It inspects registry identity/revision context for its five canonical lineages; it does not replace the complete registry-definition loader or authenticate owner approval.

| Result field | Meaning |
| --- | --- |
| draft_only | Always true |
| config_valid | Proposed input shape, references, identity, capability context and count relations passed; independent of physical feasibility |
| physical_setup_ready | Existing physical readiness result for the local surrogate; never launch approval |
| review_valid | All draft config checks and physical checks passed |
| ready_to_launch | **Always false, including valid Imaging/Survey v2 configs** |
| launch_blockers | Always includes V2_DRAFT_ONLY and K20_DECISIONS_PENDING |
| metrics / checks / errors / warnings | Copied physical results after valid draft inputs, or phase-specific issues and null metrics before arithmetic |
| pending_decisions | Outstanding semantics, identity, capabilities, versions and exact-rule ratification |

On input/context errors, later checks stay not_evaluated and totals stay null. Shape/reference issues retain structured code/field_path/message/suggested_fix. A shape-valid design may have config_valid true while review_valid/physical_setup_ready are false, for example a mass violation. Counts accept whole JSON numbers like 2.0, but reject booleans, strings, fractions and nonfinite values.

This review result has its own checker revision, not a newly agreed validation-result envelope. No approval flag, opt-in switch or valid review result enables launch. The production validator, catalog loader, runtime, adapter, evaluator, controller and UI do not call this module.

## V1 and launch safeguards

Existing callers continue using MissionValidator.validate unchanged. The new entry point handles v2 review only; it does not dispatch, wrap or change v1 results. Original preset configs and optional single-target input behavior are preserved.

Tests verify that the native validated-launch API rejects proposed v2 inputs, the registry refuses new-goal v1 fallback, v1 configs with Communication/Weather objectives still fail, and the existing UI mapping/review/launch paths refuse those new objectives. No actual v2 run or new-goal score is created. The candidate registry, physical catalogs, exports and signed shared agreements are unchanged.

## Executed checks

Godot 4.7.2 in an isolated main-based copy:

| Program | Passed / failed |
| --- | --- |
| New draft v2 checker tests | 466 / 0 |
| Existing v1 validator | 294 / 0 |
| Existing v1 readiness | 671 / 0 |
| Existing saved fixtures | 470 / 0 |
| Existing preset catalog checks | 70 / 0 |
| Existing HPC contract checks | 48 / 0 |

**Total: 2,019 checks across six programs, zero failures.** The new tests run all 40 documented examples plus missing fields/slots, malformed contexts, numeric/nonfinite boundaries, unknown IDs, false agreement/capability markers, dynamic/overflow timing bounds, exact mass/budget boundaries, independent return copies, immutable/repeatable calls, v1 preservation and real launch rejection. Hypothetical mass/timing mutations exist only in test memory.

[Tests](../../tests/validation/test_mission_config_v2_draft.gd), [forty recorded review results](evidence/k22-draft/v2-draft-check.json), [verification/counts/source hashes](evidence/k22-draft/verification.json). Final logs are retained in that evidence folder. The new test is added to the maintained runner for later full integration runs. The full now-45-program suite, browser UI/export and public Netlify site were not run in this task.

Repeat the new check from the project root after Godot import:

```powershell
$godotExe = '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe'
$draftEvidence = Join-Path $env:TEMP 'orbitbridge-k22-draft'
& $godotExe --headless --path . --script tests/validation/test_mission_config_v2_draft.gd -- $draftEvidence
```

## Remaining blockers

K20's exact bounds, Weather capture/delivery meaning, transmission steps versus windows, custom/edit identity, instrument registration source and owner evidence/scoring/envelope decisions remain pending. HPC confirmation and final affected-owner agreement are not inferred from passing review checks. Once agreed, production implementation must be coordinated across validator/catalog registration, SE mapping/frozen review, HPC acceptance, KE2 evaluation/report binding and UI before any new card can launch.

K22 stays unchecked as **DRAFT CHECKER PREPARATION READY, LIVE INTEGRATION PENDING**. Personal AGENTS.md/GEMINI.md/tasks.md and prior packets remain preserved. Nothing was committed, pushed, deployed or sent to teammates.
