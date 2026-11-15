# SE handoff: connect preset/context loading to the existing game flow

Please integrate the KE1 work from branch **ke1-expand** into your own working branch. [Start here](README.md) for versions/evidence. K20 is agreed. KE1 readiness code is ready; actual v2 launch/evaluation is not yet connected.

## Use the production input, not the old draft checker

- Registry: `data/mission_presets_v2.json`, `five-presets-agreed-1`.
- Capability file: `data/mission_capabilities_v2.json`, `v2-capabilities-agreed-1`.
- Config contract: `expansion-goals-v2-agreed-1`.
- Preset API: `mission_presets_v2.gd::config_for(registry, preset_id)` returns an independent full v2 config. `legacy_config_for` preserves the original three v1 configs and refuses a new-goal fallback.
- Context API: `mission_v2_context.gd::load_context(effective_catalogs)` returns `loaded.catalogs` with a verified mission_v2 sidecar. Load outside validation, then pass that same catalog/config snapshot through review and launch.
- Validation remains `MissionValidator.validate(config, catalogs)`. It reads no files, mutates no inputs and retains the existing ValidationResult shape. Old candidate/draft files are historical test inputs; do not wire them to the production UI.

See the [copyable API example](../../ke1-expansion/k21-k22-live-integration.md). Existing target extensions still come from the effective game catalogs; loading v2 context does not guess target windows or change physical values.

## Work needed from SE

1. Read the agreed five presets for Creator/cards. Preserve the first three settings; Communication is fast-radio revision 2, others revision 1. Do not claim a stock Survey design meets 60 MB merely because readiness passes; it remains a redesign exercise.
2. Propagate schema_version, contract_revision, preset_id/revision and nested mission.goal through Creator review, Builder, launch, immutable run storage, Retry, Modify/Cancel and Results. Freeze complete edited requirements and invalidate old confirmation after changes. Compatible edits retain template lineage; changing objective needs matching preset/goal context and a new comparison.
3. Keep unsupported new cards/launches blocked until HPC's typed-v2 path and KE2's production evaluation are integrated. `ready_to_launch=true` from KE1 describes physical readiness; it cannot override native adapter rejection or absent scoring. Never strip goals or use an Imaging fallback to make a launch pass.
4. Keep the existing Save A / Not now / Continue B / Cancel route and immutable saved A. Running B gets fresh validation/run identity/native counters; it cannot silently replace A. Retain original historical key-preimage bytes when transporting saved records.
5. Fix the two reproduced SE issues: launcher/profile edits must be checked at both design_lab launch_b and comparison_inputs boundaries; Creator objective switching must update matching preset/goal atomically or refuse the edit. The separate test is `tests/integration/test_se_owner_contract_preparation.gd` and requires your Design Lab patch. At tested/published SE 0d9e275 it had 31 passes/7 failures across those two issue groups. Existing saved-A tests passed 76 and record tests 19. These are implementation issues, not missing agreement.
6. Bind all validator dependency sources, not only mission_validator.gd, in producer-version/comparison metadata. Use the [source inventory](../../ke1-expansion/evidence/k21-k22-live/validation-source-files.json). Its recorded local-byte hashes may differ after Git newline normalization; coordinate a consistent actual/canonical byte rule with HPC. Preserve historical keys and avoid inventing a new saved-record field without the owners' existing record contract.
7. Coordinate actual report-v1/v2/goal-progress presentation and comparison with KE2/KE3. Optional missing metrics show Unavailable, required missing evidence is an evaluation error, and aborted runs have no numeric score. Same requested policy may yield different accepted actions because hardware differs; changed requested choices are Design + operations.

## Integration checks

Combine any changes to tests/run_all_checks.ps1 instead of replacing your own additions. KE1's maintained main-based runner has 49 passing programs, including 97 new preset/context and 373 new validation checks. The native-rejection assertions in the new validation test must become positive native-v2 checks when HPC actually adds support; retain invalid/downgrade controls.

After merging into your working branch, rerun that runner plus your Design Lab/record checks and the separate owner-contract test. Exercise Creator objective changes; stale review; invalid mass/budget/power; Save A → Not now → Continue B → Cancel; rerun B with A unchanged; Retry same mission; Modify/Cancel; and later all five missions in the public browser build.

Please return your branch/commit, exact context/Creator/runtime/storage entry points, guard-fix results, source/version binding and launch/report limitations. No main merge, deployment or further K20 confirmation is requested by this handoff.
