# K22 separate capability-file preparation

**Current update, 15 November:** Only HPC confirmation remains. [Consolidated non-HPC decisions](k20-consolidated-non-hpc-decisions.md), [candidate validator](k22-v2-candidate-validator.md), [aligned copy](k29-mission-wording-preparation.md) and [single current handoff](current-implementation-handoff.md) supersede earlier pending-owner labels below. Candidate tests: 2429 passed. Latest SE checks still expose two implementation issues; final integration remains pending.


Status: review code tested; final capability ownership/registration and live v2 approval remain pending.

The explicit file is `data/mission_capabilities_v2.draft.json`, revision `v2-capabilities-draft-1`, targeting `expansion-goals-v2-draft-2`. Its `schema_version: 1` describes this separate file format, not the MissionConfig version. Both registered training instruments propose Imaging, Survey, Communication and Weather support. This is an illustrative gameplay proposal, not a claim about real instruments or production support. Existing component IDs and assumption labels are reused; no physical values are duplicated or changed.

`scripts/core/mission_capability_draft_loader.gd` exposes:

```gdscript
var loaded = CapabilityLoader.load_review(effective_catalogs)
# Or inspect_review(parsed_document, effective_catalogs) for an explicit pure call.
if loaded.ok:
    var checked = DraftChecker.check(config, effective_catalogs, registry, loaded.checker_context)
    # checked.ready_to_launch is ALWAYS false.
```

Here `CapabilityLoader` and `DraftChecker` refer to preloaded script resources; `effective_catalogs` is the runtime catalog snapshot used for the review. `load_review` optionally accepts an explicit alternate file path. `inspect_review` performs no file access. Both return `ok`, `draft_only`, `ready_to_launch`, `production_enabled`, `capability_revision`, `document`, `checker_context` and `errors`. Failed input produces no partial document/context. Returned data is deeply copied.

The loader rejects missing/unknown fields, unsupported revisions, approval spoofing, enabled-production flags, malformed JSON, duplicate IDs/objectives, unknown/non-instrument IDs, unknown objectives and mismatched part assumption labels. It validates the supplied catalogs. An empty objective list explicitly declares no proposed support. The checker receives the existing proposed-only context shape; neither production catalogs nor the launch pipeline imports this module.

Verification: 83 loader checks and 2,102 total checks across seven focused programs passed. Existing v1 validator/readiness/fixtures, preset catalog, draft checker and HPC contract tests were rerun. Communication/Weather and all v2 inputs remain blocked by live validation/engine initialization. See [evidence](evidence/ordered-preparation/checks.json).

Run from the project root, using your local Godot executable:

```powershell
& $GodotExe --headless --path . --script res://tests/validation/test_mission_capability_draft_loader.gd -- ./exports/capability-check
```

The maintained main runner includes this test. Final owners must agree the capability source, entries and revision policy before any production registration. No owner approval is inferred from these tests.
