# KE1 catalogs - K06

The four KE1 files use schema_version 1 and contract_revision v1.0-agreed. HPC's unchanged orbits.json instead uses schema_version, scenario_version and unit_conventions in its native format. Each file is an object containing its named data and metadata. Use the loader instead of assuming a successful parse means valid catalog data.

| File | Contents |
| --- | --- |
| components.json | 12 parts: two buses, instruments, solar panels, batteries, radios and storage options |
| launch_profiles.json | CubeSat 101 sample 1U profile and one illustrative alternative |
| launchers.json | Small and medium training launchers with profile/orbit links and payload limits |
| ke1_reference_ids.json | Agreed objective, target and orbit identifiers |
| orbits.json | Unchanged HPC-authored presets, versions, units and observation/contact windows from feature/hpc-simulator commit ab7865c |

## Values and sources

Every part has id, category, display_name, mass_g, cost_credits and assumption_id. Numeric component values, launcher costs/capacities, profile compatibility and the alternative mass threshold are invented training parameters. They are not NASA hardware specifications or real launch prices.

The one source-backed limit is the sample profile's mass_rule: comparator <, threshold_g 1330, source_id cubesat_101_1u_sample. Source: NASA CubeSat 101, Appendix C item 6, printed p.79 / PDF p.87. See [the source ledger](../docs/sources.md). Other settings on that profile remain illustrative and have their own assumption label. The alternative profile uses <= 5000 g and an assumption_id; it does not inherit the sample NASA limit or source claim.

Bus mass/cost exclude separately selected subsystems. The bus baseline includes small always-on electronics/storage demand; the simulator charges observe/transmit demand separately. Battery initial_charge_fraction is a documented training starting condition, not a mission-life guarantee. All radio data rates are decimal MB/hour. Storage is decimal MB and energy is Wh.

## Loading and shape

CatalogLoader.load_catalogs() reads the four KE1 files, loads native orbits.json when present, and returns {ok, catalogs, errors}. On failure, catalogs is empty and the errors have code, field_path, message and suggested_fix. The helper uses INVALID_SCHEMA for malformed/missing catalog data. No exception or silent replacement is used.

On success, catalogs contains schema_version, contract_revision, components, launch_profiles, launchers, objective_ids, orbit_ids and target_region_ids. The first three collections are arrays of entries. When native HPC orbit data is present, its original document is attached as orbit_catalog. This bundle is the catalogs argument to MissionValidator.validate(config, catalogs).

Components carry category-specific fields listed in the agreed contract. Launch profiles expose supported_orbit_ids and mass_rule with comparator/threshold_g/source_id or assumption_id. Launchers expose supported_profile_ids, supported_orbit_ids, max_payload_g_by_orbit and cost_credits. The loader checks links and duplicate IDs. inspect_catalogs() is a pure helper returning {ok, indexes, errors}; its returned indexes are independent copies.

HPC owns data/orbits.json, step_duration_hours and access/contact windows. Its file has now been copied without edits from feature/hpc-simulator commit ab7865cf45e65de84637b4319899759928ee7082 (SHA256 0ed028a477998057ede2e6f79bd29d7d7569b32e6a9869d00c9826a0f8aa36d4). The validator uses nonempty valid target_windows for static suitability; it does not infer real access from orbit names. The source file labels its windows as authored gameplay assumptions.

## Current implementation stage

K05/K06 field/lookup/catalog work is now extended by K07/K08 totals and all required readiness checks. Ready designs have metrics and ready_to_launch=true only when every check passes. Valid metrics remain visible on feasibility failures; unsafe/invalid inputs keep metrics null. Missing/unusable orbit data produces a blocking issue and a not_evaluated target check. Source-linked mass fields also satisfy K09. Catalog lookup alone is never permission to launch.

The old docs/contracts/v1-draft payloads remain hand-authored interface mocks. Their totals are not calculated from this catalog, and instrument_boundary_heavy is a documentation-only boundary fixture, not a production part. The real advanced instrument is instrument_advanced.


## Five-preset candidate registry (K21)

`mission_presets.json` registers Estuary Watch, Tropical Forest Watch, Polar Ice Survey, Communication and Weather Monitoring. Its registry format is version 1, while `candidate_config_v2` contains an unapproved goal-bearing config proposal. `scripts/core/mission_preset_catalog.gd` validates and returns independent copies of these definitions.

This catalog is not connected to Mission Control or the current runtime. `existing_v1_config()` returns unchanged inputs only for the three existing presets, with Survey's unavailable scoring labelled explicitly. New Communication/Weather definitions return `GOAL_EXTENSION_PENDING` instead of an Imaging fallback. Stock design checks establish physical readiness only; they do not validate new mission outcomes.

See [the K20 review](../docs/ke1-expansion/k20-interface-review.md), [progress](../docs/ke1-expansion/k20-k21-progress.md) and `tests/validation/test_mission_presets.gd`. Keep the agreed v1 contract/catalogs unchanged until the draft is reviewed and K22 plus runtime/evaluator support are integrated.

Review update: `five-presets-candidate-2` uses `expansion-goals-v2-draft-2`. Communication preset revision 2 uses the fast radio (1120 g / 89 credits); the other presets keep prior values and revision 1. HPC and SE confirmation remain pending. See `docs/ke1-expansion/ke2-review-package.md`.


## Separate capability review file

`mission_capabilities_v2.draft.json` is a proposed-only declaration referencing existing instrument IDs and assumption labels. Its loader is explicit and isolated; production catalogs do not import it. File schema version 1 is independent of MissionConfig v2. See [review API and tests](../docs/ke1-expansion/k22-capability-loader.md). New objectives remain blocked.


The separate [v2 candidate validator](../docs/ke1-expansion/k22-v2-candidate-validator.md) consumes the explicit capability document and full v2 config. It does not register objectives in the live catalogs or enable launch; HPC confirmation and coordinated integration remain pending.


## Agreed config-v2 data

Use `mission_presets_v2.json` and `mission_capabilities_v2.json` through `scripts/core/mission_v2_context.gd` for explicit v2 validation. These are the agreed K20 rules. Earlier mission_presets.json / mission_capabilities_v2.draft.json remain historical review fixtures. The new sidecar preserves legacy physical/catalog values; no new goal falls back to Imaging. See [K21/K22 API, tests and current launch limitations](../docs/ke1-expansion/k21-k22-live-integration.md).
