# KE1 catalogs - K06

All files use schema_version 1 and contract_revision v1.0-agreed. Each JSON file is an object containing its named collection and explanatory metadata. Use the loader instead of assuming a successful parse means valid catalog data.

| File | Contents |
| --- | --- |
| components.json | 12 parts: two buses, instruments, solar panels, batteries, radios and storage options |
| launch_profiles.json | CubeSat 101 sample 1U profile and one illustrative alternative |
| launchers.json | Small and medium training launchers with profile/orbit links and payload limits |
| ke1_reference_ids.json | Agreed objective, target and orbit identifiers; no orbital physics or access windows |

## Values and sources

Every part has id, category, display_name, mass_g, cost_credits and assumption_id. Numeric component values, launcher costs/capacities, profile compatibility and the alternative mass threshold are invented training parameters. They are not NASA hardware specifications or real launch prices.

The one source-backed limit is the sample profile's mass_rule: comparator <, threshold_g 1330, source_id cubesat_101_1u_sample. Source: NASA CubeSat 101, Appendix C item 6, printed p.79 / PDF p.87. See [the source ledger](../docs/sources.md). Other settings on that profile remain illustrative and have their own assumption label. The alternative profile uses <= 5000 g and an assumption_id; it does not inherit the sample NASA limit or source claim.

Bus mass/cost exclude separately selected subsystems. The bus baseline includes small always-on electronics/storage demand; the simulator charges observe/transmit demand separately. Battery initial_charge_fraction is a documented training starting condition, not a mission-life guarantee. All radio data rates are decimal MB/hour. Storage is decimal MB and energy is Wh.

## Loading and shape

CatalogLoader.load_catalogs() reads these four files and returns {ok, catalogs, errors}. On failure, catalogs is empty and the errors have code, field_path, message and suggested_fix. The helper uses INVALID_SCHEMA for malformed/missing catalog data. No exception or silent replacement is used.

On success, catalogs contains schema_version, contract_revision, components, launch_profiles, launchers, objective_ids, orbit_ids and target_region_ids. The first three collections are arrays of entries. This bundle is the catalogs argument to MissionValidator.validate(config, catalogs).

Components carry category-specific fields listed in the agreed contract. Launch profiles expose supported_orbit_ids and mass_rule with comparator/threshold_g/source_id or assumption_id. Launchers expose supported_profile_ids, supported_orbit_ids, max_payload_g_by_orbit and cost_credits. The loader checks links and duplicate IDs. inspect_catalogs() is a pure helper returning {ok, indexes, errors}; its returned indexes are independent copies.

HPC still owns data/orbits.json, supported-target metadata, step_duration_hours and access/contact windows. ke1_reference_ids.json only registers low_eq, high_inc and equator so K05 can check selection names. It does not establish target feasibility or a runnable scenario.

## Current implementation stage

K05 validates fields and resolves IDs. K06 supplies these catalogs. Full mass/cost/resource totals and readiness verdicts are K07-K09. Until those checks exist, ready_to_launch remains false, metrics is null and the six later checks are not_evaluated. Catalog lookup passing is not permission to launch.

The old docs/contracts/v1-draft payloads remain hand-authored interface mocks. Their totals are not calculated from this catalog, and instrument_boundary_heavy is a documentation-only boundary fixture, not a production part. The real advanced instrument is instrument_advanced.
