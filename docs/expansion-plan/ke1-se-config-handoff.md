# KE1 and SE handoff for expansion configuration

Prepared by KE2 on 15 November 2026 in Asia/Rangoon. Task 00.2 draft for owner review. All additions below are proposals. Existing behavior follows the [signed agreement](../team-agreement.md) and [current contract](../contracts.md).

Review update on 15 November 2026: the user confirmed agreement on mission IDs and goal meanings, then reported KE1 confirmed the four choices in the [K20 comparison](k20-ke2-interface-review.md): explicit config v2, nested goal fields, root preset identity/revision, and the specified high_inc two-capture/basic-instrument/fast-radio Communication starter. KE1 will share the required registry/API/tests later. The additive-v1/flat-field examples below retain their initial-proposal status. Artifact receipt, SE/HPC alignment, and production migration remain open.

Inspected `features/KE2` at `4c65496`. Local `main` matches that revision. Recorded `origin/main` is `dce75db`, three commits ahead, including controller, preset-screen, layout, and runner changes. SE should reconcile those producer changes when choosing the integration revision.

## SE review and work that can proceed

Artifact update on 15 November 2026: KE1's [draft-2 package has been received and reviewed](ke1-k20-draft2-receipt-review.md). Registry/API/tests and starter evidence are verified and archived as review artifacts; 629 supplied checks reproduce in an isolated copy. The live production paths remain unchanged. Earlier artifact-absence statements below describe the preceding inspection. HPC/SE confirmation, remaining bounds/custom identity, production migration and scoring/report agreement remain open.

On 15 November 2026, the user relayed SE's review of this handoff. SE considers the proposal unready for production integration and explicitly confirms that separate Save A/B storage and navigation work can start now. This records SE's readiness assessment and available work. Implementation completion and receipt of a storage branch remain pending.

The user's earlier confirmation covers mission IDs and goal meanings. The [K20 interface review](k20-ke2-interface-review.md) records the remaining recommendations for config v2, nested goals, root preset identity/revision, and the Communication starter. Exact schema/field adoption, custom-mission identity, scoring, and runtime verification still require the owner decisions below.

| Work | Owner | Current readiness and required output |
| --- | --- | --- |
| Save A/B record storage and navigation | SE, with KE3 on presentation | Can start using completed supported Imaging executions and their bound reports. Retain launch config, readiness, catalogs/scenario identity, action information, and resource evidence independently of the latest-two-trace buffer. Preserve the full goal/config snapshots as the interface evolves |
| Save/retry/modify/cancel/reset behavior | SE | Gate Save A on the reached completed active execution and matching report. Keep A through B, Retry, Cancel, Results reentry, and trace turnover. Replace A deliberately, preserve historical reports, and clear the active pair for New Mission. Return implementation commit and test evidence |
| Exact configuration contract | KE1 + KE2 + SE, with HPC/KE3 on affected fields | Resolve config/state/report version boundaries, nested field spellings, authored/custom identity, and compatibility. Publish the same contract/examples for producers and consumers |
| Validator, catalogs and instrument support | KE1 | Supply the actual updated code and checks for supported objectives and their positive goals. Current flat-field examples still fail the existing schema |
| Communication and Weather evidence | HPC + KE1 | Supply real expanded-objective success and isolated-shortfall traces with launch config, ordered accepted events, positive returned-MB deltas, selected target, and revolution identity/mapping. Existing mechanics evidence is linked in the [KE3 report handoff](ke3-ke2-results-ab-handoff.md) |
| Evaluator and analytical comparison | KE2 | Implement Survey scoring, explicit Communication/Weather outcomes and partial rules, then matching and signed measures against the coordinated inputs. Current example assessments remain proposed, and production comparison remains null |
| Integration candidate and verification | SE + each producer owner | Identify exact owner commits and a combined candidate revision, run affected checks, and provide exit codes, logs, and input-bound example run records |

The storage/navigation work can use the [proposed independent-record definition](ke3-ke2-results-ab-handoff.md#proposed-record-and-eligibility-contract-for-se-hpc-and-ke3). Final comparison eligibility and interpretation depend on KE2's agreed output and the matching contract. Keep an unavailable-comparison state for the current null result. SE retains ownership of its runtime/controller files.

## Integration evidence still required

The existing engine packet and check logs identify `4c65496` as their production-code baseline. The recorded `origin/main` revision `dce75db` supplies context for SE synchronization. A combined expansion integration revision has yet to be supplied.

For each owner handoff, record the owner/branch, exact commit, changed interfaces, test command, engine version, exit code, result counts, and log location. Each example record needs its immutable config and versions, `run_id`, `mission_id`, binding key, scenario/schedule identity, terminal state, ordered events, actual evaluation response, and applicable action/resource evidence. A/B evidence additionally needs both execution identities, changed parts, eligibility/reasons, operations scope, signed deltas with units, and interpretation.

The [current report evidence and reproduction commands](ke3-ke2-results-ab-handoff.md#reproduction-and-checks) include the eight engine executions, evaluator 207 passed/zero failed/five pending, and adapted Results 17 passed/zero failed, with successful commands exiting 0. These establish the recorded baseline and mechanics evidence. New expanded-objective integration and Save A/B lifecycle evidence remain open until the corresponding implementation commits are available.

## Current behavior to preserve

`MissionValidator.validate(config, catalogs)` requires top-level `schema_version`, `mission`, and `design`. Version is numeric `1`. Mission requires `title`, `objective`, `target_region`, `required_observations`, `required_returned_data_mb`, `duration_orbits`, and `budget_credits`. Optional `target_regions` has one or two unique registered targets, with its first entry equal to `target_region`. Omitting it preserves the single-target input. Survey requires at least one capture per selected target.

Unknown fields at the top level, mission level, or design level produce `INVALID_SCHEMA` with the offending `field_path` and message `Unrecognized configuration field.` Unknown registered-choice values produce `INVALID_VALUE`. Unknown component, profile, launcher, and orbit IDs use their existing specific error codes.

The base JSON reference catalog registers `imaging` and `equator`. Loader allowlists also recognize `survey` and seven targets. Active `mission_runtime.load_game_catalogs()` adds Survey and expanded target/window metadata to the loaded catalogs and adds Survey support to instruments in memory. Readiness and HPC adapters consume these effective catalogs.

The following inputs come from the actual preset producer plus its reset/default mapping. Each starts with one target, five required captures, 60 MB returned, six orbits, and a 100-credit budget. The returned-data default is initialized by Creator or derived by the runtime when absent. These are source-inspected settings, with actual preset runs still to verify under 10.1/10.4.

| Existing card | Objective ID | Target ID | Orbit ID | Proposed optional preset ID |
| --- | --- | --- | --- | --- |
| Estuary Watch | `imaging` | `coastal_region` | `high_inc` | `estuary_watch` |
| Tropical Forest Watch | `imaging` | `tropical_forest` | `low_eq` | `tropical_forest_watch` |
| Polar Ice Survey | `survey` | `arctic_ice` | `high_inc` | `polar_ice_survey` |

Keep these settings and existing one/two-target inputs compatible. Existing stored configs may omit `preset_id`. Editable titles cannot reliably identify a preset. Survey currently passes setup through the active runtime but receives an evaluator error because its delivery scoring is pending.

## Proposed IDs, goals, and field rules

| Field | Proposed rule |
| --- | --- |
| `mission.objective` | Preserve `imaging` and `survey`. Add `communication` and `weather_monitoring` |
| `mission.preset_id` | Optional registered string for older configs. New Communication and Weather cards emit `communication` and `weather_monitoring`. Existing cards may emit the IDs above after coordinated migration |
| `mission.target_region` / `target_regions` | Keep one/two-target Imaging and Survey behavior. Initially require exactly one target for each new objective. When the array is present, its first entry remains the primary target |
| `mission.duration_orbits` | Preserve finite whole numeric range 1-12. Both new presets start at proposed value 3 |
| `mission.required_observations` | Preserve finite whole numeric range 1-20 and successful-capture meaning. Retain it for new objectives as the engine's capture limit and test-payload supply. Agree its role in new-objective outcomes with HPC/KE2 |
| `mission.required_returned_data_mb` | Preserve positive finite decimal MB. Propose 12 MB for each new preset |
| `mission.required_contact_steps` | Required for Communication, positive finite whole count. Propose 2. Count distinct accepted Transmit steps returning positive MB, including distinct steps in one window |
| `mission.required_orbit_visits` | Required for Weather Monitoring, positive finite whole count at most `duration_orbits`. Propose 2. Count distinct revolutions containing an accepted capture of the selected target |
| `mission.budget_credits` | Preserve positive finite whole credits and existing mass, budget, power, launcher/profile, and target/orbit readiness checks |

Accept finite whole JSON numbers for integer semantics. Reject booleans, numeric strings, fractions for counts, nonfinite values, and zero/negative goals using the existing validation conventions. Propose rejecting objective-inapplicable goal fields to expose mismatched producers, with `INVALID_SCHEMA` at the field path. Actual limits derived from scenario timing need HPC agreement.

Propose an additive schema-1 extension with optional legacy preset identity and objective-specific new fields. KE1/SE must confirm the schema/revision approach. Keep strict unknown-field checks and expand the explicit allowed fields only through the coordinated change.

Weather revolution identity must come from HPC or an agreed mapping of accepted-event `step_index` and `steps_per_orbit`. Existing `orbit_id` identifies a preset throughout the run. A two-capture quota can be exhausted in one revolution under Observe First. HPC must demonstrate repeat-visit feasibility with the selected target/windows/action policy and retain the intended meaning of the capture field.

## Producer and consumer handoffs

| Owner | Paths | Coordinated work |
| --- | --- | --- |
| SE, with KE1/KE3 | `scripts/screens/MissionControl.gd`, `MissionCreator.gd`, `data/mock/DesignCatalog.gd` | Produce five stable preset identities, retain existing card settings, add objective controls and conditional positive goals |
| KE1 | `scripts/core/mission_validator.gd`, `catalog_loader.gd`, `data/ke1_reference_ids.json`, `components.json` | Agree allowed fields/IDs, objective-specific validation, and explicit instrument support |
| SE + KE1 | `scripts/integration/mission_runtime.gd` | Update label-to-objective mapping, effective catalog extension, `config_for()`, and draft/retry snapshots so new fields survive all normal routes |
| HPC | `core/HPCContractAdapter.gd`, `MissionStepEngine.gd`, `OrbitPlanner.gd`, `data/orbits.json`, `mission_scenarios.json` | Consume registered objectives, preserve capture semantics, and supply positive-transmission and selected-target revolution evidence using feasible authored schedules |
| KE2 | `scripts/evaluation/mission_evaluator.gd`, `mission_feedback.gd` | Add explicit objective handling and objective-specific count/data evaluation while preserving Imaging behavior and existing errors/aborts |
| SE + KE2 | `scripts/integration/mission_results.gd` | Include preset and objective-specific goals in immutable run records, comparison matching, and report/execution binding |
| KE3 | `scripts/prototype/Screen.gd`, `scripts/presentation/DebriefPresentation.gd`, `DebriefSummary.gd`, `PlayerLanguage.gd` | Render the appropriate count and unit for each objective while retaining required fields for older callers |
| KE1 + SE + affected owners | `docs/team-agreement.md`, `docs/contracts.md`, agreed examples, relevant existing tests | Publish the confirmed extension and prove backward compatibility together |

The earlier `scripts/integration/mission_workflow.gd` remains a separate tested caller. Keep its legacy inputs valid and decide whether it participates in the expansion.

The current evaluator explicitly rejects Survey and otherwise computes the aggregate capture/data score. Catalog registration alone would allow a new objective to receive the existing Imaging calculation through a bypassed or extended setup path. KE2 must add explicit handling alongside producer changes. Current presentation helpers also assume photo/data goals.

## Candidate valid config under the proposed extension

This hand-authored Communication example illustrates the proposed fields. It becomes a schema-valid candidate after the agreed validator, catalog/instrument support, adapter, producer, and evaluator changes. Its stock design resolves to 1060 g and 82 credits by catalog arithmetic. Real readiness and the two-positive-step/12-MB result remain checks for KE1/HPC.

```json
{
  "schema_version": 1,
  "mission": {
    "title": "Communication trial",
    "preset_id": "communication",
    "objective": "communication",
    "target_region": "equator",
    "target_regions": ["equator"],
    "required_observations": 1,
    "required_returned_data_mb": 12.0,
    "required_contact_steps": 2,
    "duration_orbits": 3,
    "budget_credits": 100
  },
  "design": {
    "bus_id": "bus_basic",
    "instrument_id": "instrument_basic",
    "solar_id": "solar_standard",
    "battery_id": "battery_standard",
    "radio_id": "radio_basic",
    "storage_id": "storage_standard",
    "launch_profile_id": "cubesat_1u_sample",
    "launcher_id": "small",
    "orbit_id": "low_eq"
  }
}
```

The basic instrument supplies a 12-MB test packet. Whether it returns over two positive contact steps must be verified from HPC events. Proposed Weather setup uses `objective: weather_monitoring`, `preset_id: weather_monitoring`, one selected target, `required_observations: 2`, `required_orbit_visits: 2`, `required_returned_data_mb: 12.0`, and `duration_orbits: 3`. KE1/HPC must select the target, orbit, and policy that demonstrate the intended visits.

## Invalid example and expected errors

Create the exact invalid counterpart by copying the candidate and setting its required contact count to zero.

```gdscript
var invalid: Dictionary = candidate.duplicate(true)
invalid["mission"]["required_contact_steps"] = 0
```

Under the proposed extension, expect `ready_to_launch: false`, a failed `input_schema` check, and the following proposed validation issue. Exact new wording remains for KE1 to agree.

```json
{
  "code": "INVALID_VALUE",
  "field_path": "mission.required_contact_steps",
  "message": "Required contact steps must be a positive whole number.",
  "suggested_fix": "Choose at least one accepted Transmit step returning positive MB."
}
```

At the inspected production revision, both examples are expected to fail earlier with `INVALID_SCHEMA` for `mission.preset_id` and `mission.required_contact_steps`, because those keys are outside the mission allowlist. The current message is `Unrecognized configuration field.` Shape errors stop reference lookup and metric calculation. If the two new fields are removed, objective lookup rejects `communication` with `INVALID_VALUE` at `mission.objective`. These are source-derived expectations pending an actual invocation of the relevant validator cases.

An unknown field such as `mission.required_contact_step` remains a schema error after the proposed extension. Existing invalid legacy values, including `required_observations: 0`, retain their current `INVALID_VALUE` behavior.

## Decisions and acceptance still open

| Decision | Owner | Needed outcome |
| --- | --- | --- |
| Exact IDs, field names, applicability, schema/revision strategy, optional older preset IDs | KE1 + SE + KE2 | Shared valid/invalid examples and confirmed field rules |
| Persisting preset identity for custom/edited missions and A/B | SE + KE1 + KE2 | Preserve exact identity and changed mission settings in matching rules |
| Source of extended objective/instrument registrations | KE1 + SE + HPC | Coordinate base catalogs, loader allowlists, and runtime hydration |
| Capture quota and payload supply for new objectives | HPC + KE1 + KE2 | Retain old capture semantics and demonstrate feasible new-goal runs |
| Contact-step and revolution evidence, three-orbit/two-count/12-MB thresholds | HPC + KE1 + KE2 | Real success and isolated-shortfall traces before freezing thresholds |
| New partial/failed rules, Survey weighting, and report compatibility | KE2 + KE3 + SE | Agreed scoring and objective-aware reports, preserving Imaging results |
| Newer producer/controller baseline at recorded `origin/main` | SE | Identify the integration revision and reconcile changed paths |

After agreement, verify old configs with omitted `target_regions`/`preset_id`, both actual Imaging cards, the current Arctic Ice Survey setup, two-target Survey, conditional new fields, unknown fields, and invalid numeric values. Run the relevant existing validation, evaluator, catalog/UI, and lifecycle checks against that coordinated revision.

## Verification of this draft

Evidence level is source inspection and documentation-fixture checks. The candidate and invalid transformation are planning examples. Expected production rejection follows `_check_mission()`, `_unknown()`, and `_check_references()` in the current validator. No new runtime acceptance or public-browser result is recorded for these proposed objectives.

The inline documentation check parsed both JSON blocks, constructed the zero-contact counterpart without changing the candidate, checked current allowlists/error code paths, resolved stock component IDs and 1060-g/82-credit arithmetic, verified preset/default settings, and checked local links and draft-only checklist status. All expected results matched.

Run these commands from the repository root to repeat JSON parsing and the tracked diff check.

```powershell
python -c "import json,pathlib,re; s=pathlib.Path('docs/expansion-plan/ke1-se-config-handoff.md').read_text(encoding='utf-8'); f=chr(96)*3; b=[json.loads(x) for x in re.findall(f+'json\n(.*?)\n'+f,s,re.S)]; assert len(b)==2; print('PASS candidate and proposed error JSON')"
git diff --check
```

The draft is ready for KE1/SE review. Task 00.2's shared agreement and production migration remain open in the [work checklist](ke2-work-plan.md#00-contracts-and-handoffs). Record owner replies and subsequent verification in the [progress record](progress.md).
