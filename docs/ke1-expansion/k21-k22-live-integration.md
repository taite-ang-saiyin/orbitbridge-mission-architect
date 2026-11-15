# K21/K22 agreed preset and live validation integration

Base main: dce75db845f6c494b8c25c9028dd9c0648aabd91, verified against GitHub in this task. K20 rules are agreed. Main's existing game/export work and personal files are preserved. No branch merge, push, deployment or teammate message was performed.

## K21 delivered

Agreed definitions are `data/mission_presets_v2.json` (five-presets-agreed-1) and `data/mission_capabilities_v2.json` (v2-capabilities-agreed-1), with contract marker expansion-goals-v2-agreed-1. Only the original three plus Communication/Weather are included. The first three supported v1 configs and all five stock design/mission values are preserved; only the agreed contract marker/registry wrapper changes. Communication keeps fast-radio preset revision 2; the others keep revision 1. Existing candidate/draft files remain historical review fixtures.

`mission_presets_v2.gd` provides pure inspect, config_for and legacy_config_for. It checks exact fields, canonical order, revisions, goal shape, labels and unchanged legacy defaults. Lookups return deep copies. New goals have no v1 fallback. Availability labels continue to describe unfinished UI/simulator/scoring support; agreeing the rules does not make a card playable.

`mission_capabilities_v2.gd` is the explicit agreed capability inspector. Both current training instruments support the four authored objective types. It resolves real instrument IDs/categories/assumption labels and rejects unknown/duplicate fields/IDs/objectives. It changes no physical values and does not insert objectives into v1 catalogs.

## K22 public validation implemented; full launch integration blocked

`MissionValidator.validate(config, catalogs)` is still the public pure entry point. Supported v1 delegates to `mission_validator_v1.gd`, an exact logic copy of the former implementation with only the class declaration removed. Constants and the two prior candidate helper seams are retained. V1 result fields, arithmetic, gates and errors remain unchanged.

Config v2 routes to `mission_validator_v2.gd`. It requires explicit agreed data in `catalogs.mission_v2`, checks the full shape/identity/capabilities/bounds and runs the same safe physical routines. There is no Imaging substitution, goal stripping, title inference, catalog mutation, file I/O, run-ID allocation or simulation inside validation. Invalid input/context leaves metrics null; overflow is checked before totals. ValidationResult stays schema version 1 independently of config version 2.

Load files outside validation, using effective runtime catalogs with the authored target pack:

```gdscript
const Runtime = preload("res://scripts/integration/mission_runtime.gd")
const V2Context = preload("res://scripts/core/mission_v2_context.gd")
const PresetsV2 = preload("res://scripts/core/mission_presets_v2.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")
var base = Runtime.load_game_catalogs()
if base.ok:
    var loaded = V2Context.load_context(base.catalogs)
    if loaded.ok:
        var selected = PresetsV2.config_for(loaded.catalogs.mission_v2.registry, "communication")
        if selected.ok:
            var verdict = Validator.validate(selected.config, loaded.catalogs)
            # This checks KE1 physical readiness. Native v2 launch is still unsupported.
```

`V2Context.load_context(effective_catalogs, base_path)` reads the two agreed files. `attach(effective_catalogs, registry, capabilities)` and `inspect_context(context, catalogs)` are pure. The sidecar format is schema_version 1, contract_revision, registry and capabilities. Loading returns an independent catalog snapshot with this sidecar; all legacy physical/target/orbit/objective arrays are unchanged. Every stock definition is checked against the same effective context before use. The selected edited config is then checked separately.

## Tested behavior and owner boundary

New preset/context program: 97 passed. New live-v2 program: 373 passed. All five stock v2 designs pass eight KE1 readiness gates with preserved 1060 g/82 credits, except Communication 1120 g/89 credits. The current native init_validated_run still rejects every one without returning a state. Missing/mismatched agreed context also blocks v2 readiness. V1 new-goal downgrades remain rejected even with a v2 sidecar.

The production validator can return ready_to_launch=true for a physically valid explicit-v2 input. That is the KE1 readiness decision; **it does not bypass the separate native adapter** or establish a successful mission. The current UI still produces supported v1, and no new card/button is enabled. HPC must implement typed-v2 adapter/scenario acceptance with full snapshots; SE must connect registry/context/config propagation and preserve review/launch guards. KE2 supplies production goal evaluation; final combined launch readiness/mission acceptance is still pending. K22 remains unchecked until that live path is integrated and tested.

HPC published branch feature/hpc-ke3-goal-evidence-v1 at 345e5bdecd41d716ba3f580ae615628edf00f6ca adds labelled v1 evidence only. Its adapter still accepts config version 1 only. feature/hpc-simulator was also inspected; no owner code was merged or rewritten. The source-control fetch hit an unrelated Windows case collision for KE3 versus ke3/... refs; main and the relevant HPC branches were fetched/inspected successfully. No remote pruning/global Git settings were used.

## Producer version binding

The validator now has multiple source dependencies. SE/HPC must bind all listed [source-file hashes](evidence/k21-k22-live/validation-source-files.json), not just the small public dispatch file, when extending saved execution versions/comparison eligibility. Physical/scenario/registry/capability data remain frozen catalog snapshots. This manifest is handoff evidence, not an invented replacement saved-record field or a completed metadata migration.

## Checks and remaining work

Run the two new programs individually or use the maintained tests/run_all_checks.ps1. The runner includes both; the unsupported-version regression case now uses 3 instead of 2 because numeric 2 has an explicit valid path. Historical review tests keep their draft inputs and still verify they cannot launch. **All 49 active check programs passed, zero failed**, including 97 new preset/context checks and 373 new live-v2 checks. The [summary](evidence/k21-k22-live/checks.json), [full runner log](evidence/k21-k22-live/full-suite.log) and per-program logs record this execution. Existing evaluator pending declarations remain separate; this run does not establish production new-goal scoring. Headless checks do not establish final public Netlify acceptance.

Remaining blockers are implementation: HPC v2 adapter/compatible state-event support, SE live context/identity/guard integration, KE2 goal evaluation and final integrated/browser testing. No agreement round is reopened. Survey sparse-map/Weather/resource meanings are fixed by the [agreed contract](../contracts/expansion-v2.md).
