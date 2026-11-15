# HPC handoff: connect the agreed v2 config to native simulation

Please integrate the KE1 work from branch **ke1-expand** into your own working branch. [Start here](README.md) for versions and test evidence. K20 rules are already agreed, including your final Survey correction; no repeat approval is requested.

## What is ready

- `MissionValidator.validate(config, catalogs)` accepts supported v1 unchanged and explicit agreed v2 context. ValidationResult remains schema version 1 with the original eight readiness gates/nine metrics.
- Agreed stock definitions are in `data/mission_presets_v2.json`; both training instruments' objective support is in `data/mission_capabilities_v2.json`.
- `MissionV2Context.load_context(effective_catalogs)` reads those files outside validation. Its pure `attach` and `inspect_context` APIs validate the same documents for producers. The returned catalog snapshot has `catalogs.mission_v2`, containing the full registry/capability documents. Existing physical/target/orbit/objective arrays remain unchanged.
- Pure `mission_capabilities_v2.gd::inspect(document, catalogs)` returns `capability_context.instrument_objectives`. Use that agreed source when extending the v2 scenario/objective registration. Do not infer support from the legacy objective_ids alone or register UI-only support.

## Work needed from HPC

1. Extend the typed config-v2 adapter/scenario path and all later step/context validation. Current main and your published v1-evidence branch still reject v2. Do not strip goals, rewrite the objective to Imaging or convert the frozen config to v1.
2. Preserve the complete launch config, goal/identity revisions, effective catalog/capability/scenario snapshots and ordered same-run events. Every A/B execution gets a fresh run ID and clean native state.
3. Preserve positive transmission counting: accepted Transmit, `delta_returned_data_mb > 0`, distinct step evidence; zero/rejected/duplicate steps do not add counts. Multiple positive steps in one window count separately.
4. Weather evidence requires accepted Observe, `delta_observations > 0`, selected target and distinct revolutions. Use the event's zero-based pre-action step and frozen steps_per_orbit. No complete-delivery-per-visit condition. Communication/Weather capture quota supplies/limits captures, not an extra success condition.
5. Survey: missing whole required map means unavailable. A missing selected-target entry is zero **only in a verified native state containing observations_delivered_by_target**. Historical/incomplete projections without verified native provenance remain unavailable. Preserve complete packet delivery separately from partial MB.
6. Expose initialization plus every accepted post-clamp resource state, including terminal. Missing samples remain unavailable. Verify state/event v1 compatibility with the full config-v2 snapshot; do not claim it from the schema number alone.
7. Supply actual typed-v2 Communication/Weather passing and isolated-shortfall runs, plus complete/missing/partial Survey delivery controls. Existing proxy/v1 evidence stays labelled as such. KE2 still owns official outcomes/scores.

## APIs and tests

See the [integration example](../../ke1-expansion/k21-k22-live-integration.md). Load the existing effective target catalogs, attach/load the agreed context, then pass the exact v2 config and that same frozen catalog snapshot to KE1 validation/native initialization.

From a checkout after importing it with Godot 4.7.2:

```powershell
& $GodotExe --headless --path . --script res://tests/validation/test_mission_presets_v2.gd -- ./exports/presets-v2
& $GodotExe --headless --path . --script res://tests/validation/test_mission_validator_v2.gd -- ./exports/validation-v2
& ./tests/run_all_checks.ps1 -GodotExe $GodotExe
```

The new validator test currently asserts native rejection for all five v2 presets because that is the present gap. After adding real native support, replace those expected-rejection assertions with checks for real state creation, complete snapshots, compatible envelopes and correct goal evidence. Keep malformed/context-missing/v1 downgrade controls and all legacy checks. Do not simply suppress the assertions.

The validator now spans multiple files. Include the full [source inventory](../../ke1-expansion/evidence/k21-k22-live/validation-source-files.json) when coordinating producer fingerprints with SE; hashing only mission_validator.gd misses its dependencies. That historical inventory records local observed file bytes. Git line-ending normalization can change raw digests; use the actual checked-out/deployed bytes or the explicitly agreed normalization, and preserve historical execution-key preimage bytes. Do not regenerate old keys to conceal a difference.

Please return your branch/commit, exact adapter/init entry points, state/event versions, evidence/sample paths, native v2 results and remaining integration failures. This is an implementation handoff, not a request for another K20 vote.


## New K23/K24 evidence

See the [current five-mission report](../../ke1-expansion/k23-five-mission-readiness.md) and [current Communication cases](../../ke1-expansion/k24-communication-current.md). 636 + 711 new checks passed on the current KE1 source. Stock Forest and Survey need a design/operation improvement to return 60 MB; the tested fast-radio player designs return 60 MB without changing presets. Communication physics trials remain explicitly v1-labelled while native v2 rejects. These are new local branch edits; no commit/push or teammate message was performed for this task.
