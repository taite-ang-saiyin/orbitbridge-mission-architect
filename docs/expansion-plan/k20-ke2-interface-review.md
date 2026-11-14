# KE2 review of KE1 K20 interface draft

Prepared on 15 November 2026 in Asia/Rangoon at `features/KE2`, `4c65496`. Reviewed the supplied [K20 draft](<C:/Users/Min Sett Paing/Downloads/Telegram Desktop/k20-interface-review.md>), revision `expansion-goals-v2-draft-1`, against the [initial KE2 config proposal](ke1-se-config-handoff.md), [HPC evidence map](hpc-evidence-handoff.md), and [report/A/B handoff](ke3-ke2-results-ab-handoff.md).

The user confirmed agreement on the mission IDs and goal meanings. That covers the five preset IDs and four objective IDs listed below, with Imaging capture/data goals, complete selected-target Survey delivery, positive accepted Communication steps, and distinct selected-region Weather revolutions.

Confirmation update on 15 November 2026: the user reports KE1 confirmed the four choices in the reply prepared from this review and will share the required files later. Record config v2, K20 nested goal names, root preset identity/revision, and the specified high_inc two-capture/basic-instrument/fast-radio Communication starter as KE1-confirmed. The sections below retain the review rationale. Artifact receipt, SE/HPC implementation alignment, scoring/report decisions, and integrated verification remain open. The signed v1 agreement and production contracts retain their current status.

## Four differences and KE2 recommendations

| Item | Initial KE2 proposal | KE1 K20 proposal | KE2 review recommendation |
| --- | --- | --- | --- |
| Configuration version | Add fields to schema 1 | Explicit config schema 2 with a contract revision | Prefer config v2, preserve the supported v1 path and its fixtures/results |
| Goal field names | Flat `mission.required_contact_steps` and `mission.required_orbit_visits` | Typed `mission.goal` object with precise count fields | Prefer K20's nested goal names and one canonical returned-MB threshold |
| Preset identity | Optional `mission.preset_id` for compatible older inputs | Root `preset_id` and positive `preset_revision` for v2 | Prefer root identity/revision for v2 authored presets, retain v1 inputs with identity absent |
| Communication starter | `low_eq`, one basic-instrument capture, basic radio, 12 MB, two positive steps, three orbits | `high_inc`, `equator`, capture quota 2, 12 MB, two positive steps, three orbits; hardware details absent from the supplied draft | Prefer K20's orbit/target/two-capture setup. Propose an explicit basic instrument and fast radio, with stock parts, budget, and policy below |

## Version boundaries and compatibility

Config v2 makes the new required goal object and preset metadata explicit. Existing v1 inputs keep their current required fields, unknown-field rejection, goal meanings, numeric ranges, units, and Imaging results. A v1 config can continue omitting `preset_id` and `mission.goal`. An authored v2 config requires its reviewed identity and goal fields. Keep the existing three cards' defaults during migration.

The current validator, adapter, runtime config constructor, and evaluator support config v1. The evaluator currently checks both config and state against the same `SCHEMA_VERSION` constant. Adding config v2 requires independent config/state version checks. A config bump alone cannot establish that state, event, catalog, or report schemas changed. HPC owns state/event acceptance, and KE2/SE/KE3 need to settle the report envelope separately while preserving old callers.

K20 distinguishes registry-format version 1 from candidate config version 2. Preserve that distinction in loader/check names and records. The proposed config `contract_revision` also needs its own validation, separate from the current catalog bundle's `contract_revision: v1.0-agreed`. Use an agreed expansion revision when the team ratifies it.

## Goal field spelling

Use these K20 spellings for the coordinated v2 proposal.

| Preset ID | Objective ID | `mission.goal` |
| --- | --- | --- |
| `estuary_watch` | `imaging` | `{"kind":"imaging"}` |
| `tropical_forest_watch` | `imaging` | `{"kind":"imaging"}` |
| `polar_ice_survey` | `survey` | `{"kind":"survey_delivery","minimum_complete_observations_per_target":1}` |
| `communication` | `communication` | `{"kind":"communication_contacts","required_positive_contact_steps":2}` |
| `weather_monitoring` | `weather_monitoring` | `{"kind":"weather_revisit","required_distinct_orbits":2}` |

`mission.required_returned_data_mb` remains the only MB threshold. `mission.required_observations` keeps its capture/quota meaning. Communication and Weather outcomes use their agreed count requirement and returned MB; the retained capture quota controls payload generation. Survey keeps its aggregate capture/data requirements plus the selected-target delivery requirement.

Require the objective and `goal.kind` to match. Keep goal objects strict about unknown or inapplicable fields. New counts use finite whole positive values. Weather visit requirements must fit the configured duration and capture quota. The initial Survey preset uses a per-target minimum of one; KE1/KE2 should explicitly settle whether higher minima are supported in this revision. Partial-result rules and score weights still require their separate scoring decision.

The earlier flat-field example was a proposal with no production implementation. Retain it as historical review evidence and use the reviewed nested spelling for new v2 examples. Introducing compatibility aliases for those unimplemented flat fields would add another input shape to maintain.

## Root preset identity

For v2 authored presets, prefer root `preset_id` and `preset_revision`, alongside config version/revision. An editable title remains display content. Freeze the complete config and goal object in the execution record and compare their actual values during A/B eligibility checks. Matching preset ID/revision alone cannot establish equal mission requirements.

SE must propagate root identity/revision through config construction, review invalidation, launch snapshots, Retry/Modify/Cancel, saved A, result bindings, and comparison inputs. Decide how a v2 mission created through Creator without selecting a preset obtains its identity. Existing v1 custom missions remain supported; changing goals in a preset-derived mission must retain the full edited requirement snapshot.

## Communication starter recommendation

Use the K20 high-inclination, equator, two-capture setup and specify the following candidate design. These are proposed starter values derived from current catalog and schedule data.

```json
{
  "schema_version": 2,
  "contract_revision": "expansion-goals-v2-draft-1",
  "preset_id": "communication",
  "preset_revision": 1,
  "mission": {
    "title": "Communication",
    "objective": "communication",
    "target_region": "equator",
    "target_regions": ["equator"],
    "required_observations": 2,
    "required_returned_data_mb": 12.0,
    "duration_orbits": 3,
    "budget_credits": 100,
    "goal": {
      "kind": "communication_contacts",
      "required_positive_contact_steps": 2
    }
  },
  "design": {
    "bus_id": "bus_basic",
    "instrument_id": "instrument_basic",
    "solar_id": "solar_standard",
    "battery_id": "battery_standard",
    "radio_id": "radio_fast",
    "storage_id": "storage_standard",
    "launch_profile_id": "cubesat_1u_sample",
    "launcher_id": "small",
    "orbit_id": "high_inc"
  }
}
```

The catalog arithmetic gives 1120 g and 89 credits, including the small launcher. Two basic captures produce 24 MB. At the selected orbit's `0.1611111111 hours/step`, the fast radio's `120 MB/hour` provides `19.333333332 MB` per contact step. A candidate Observe First sequence captures at steps 1 and 6, then transmits at steps 7 and 10. Those transfers would return approximately 19.333333332 MB and 4.666666668 MB, giving two qualifying steps. Power-save handles the other steps through completion at step 30.

One 12-MB capture with that radio can drain in one step. A two-capture quota therefore supports the requested two-positive-step starter. A count-only shortfall candidate captures twice but transmits only at step 7, returning more than 12 MB over one qualifying step. Keep this explicit action sequence in the success/shortfall evidence request.

The current [engine-backed proxy packet](evidence/ke2-handoff-current.json) already demonstrates two-capture Communication mechanics with the fast radio under `low_eq`, using supported Imaging inputs. Its complete case returns 24 MB over steps 8 and 18; its shortfall returns `18.466666668 MB` at step 8 alone. That record supports the count meaning. The K20 `high_inc` starter and typed v2 config still need their own coordinated real-run verification. The existing native source excerpt also demonstrates split transmission capacity under `high_inc`, with a different instrument/quota setup.

## Remaining owner handoffs

| Owner | Needed response |
| --- | --- |
| KE1 | Four interface choices confirmed per user report. Supply the candidate registry, catalog API, tests, exact revision, and expected results. Document any remaining bounds or Survey-minimum details with the files |
| SE | Confirm root preset metadata, v1/custom-Creator policy, config/review/snapshot propagation, and the integration revision |
| HPC | Confirm config v2 acceptance, unchanged or revised state/event versions, revolution mapping, capture/revisit policy, and actual high_inc Communication success/count-only-shortfall traces |
| KE2 + SE + KE3 | Confirm report envelope/goal progress migration and scoring separately, then implement objective-aware evaluation and comparison |

The supplied K20 links `data/mission_presets.json`, `scripts/core/mission_preset_catalog.gd`, and `tests/validation/test_mission_presets.gd`. All three are absent from this checkout at review time. Starter analysis uses the attached draft, current production catalogs/source, and existing proxy evidence.

## Verification and task status

This is a planning review. Checks inspect the attached K20 text, current version/allowlist consumers, existing evidence, candidate JSON, and catalog/rate arithmetic. The proposed v2 config is expected to fail current production version/unknown-field checks. Its gameplay result requires the coordinated v2 path and real execution. The attached source file SHA-256 is `9bc353ec64e1619280b531c21e5d8f939cde87be22ebb5b6f30f2a0bdd2d95c2`.

Commands used include `Test-Path` for the three missing K20 artifacts, inline `python -` for source/packet/catalog checks, and `git diff --check`. A portable JSON parsing check is provided below.

```powershell
python -c "import json,pathlib,re; s=pathlib.Path('docs/expansion-plan/k20-ke2-interface-review.md').read_text(encoding='utf-8'); f=chr(96)*3; b=[json.loads(x) for x in re.findall(f+'json\n(.*?)\n'+f,s,re.S)]; assert len(b)==1; print('PASS K20 starter JSON')"
git diff --check
```

The checklist records the user-confirmed IDs/goal meanings, review, and KE1 confirmation as complete subtasks. Task 00.2 remains open for artifact receipt, remaining producer/consumer alignment, production migration, and integrated compatibility checks.
