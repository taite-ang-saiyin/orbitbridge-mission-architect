# K22 candidate v2 validator

Status: candidate implemented and tested separately. HPC is the only remaining K20 confirmation. Live integration and acceptance remain unfinished.

`scripts/core/mission_validator_v2_candidate.gd` exposes:

```gdscript
var result = CandidateValidator.validate(config, effective_catalogs, registry, capability_document)
```

`CandidateValidator` is a preloaded script resource. All inputs are supplied explicitly; the call reads no files, writes no files and mutates no caller data. Pass the parsed `data/mission_capabilities_v2.draft.json` document, not its loader result, as `capability_document`. The capability declaration is checked using the existing loader's pure `inspect_review`. File format version 1 is independent of MissionConfig v2.

For supported numeric config version **1**, the candidate delegates directly to the unchanged `MissionValidator.validate(config, catalogs)`. It returns the exact existing result, with no candidate fields and without requiring v2 registry/capability context. Supported legacy launch permission is preserved.

For config version **2**, it checks exact fields, values, preset lineage/revision, goal/objective combinations, existing part categories, explicit capabilities and count bounds. Survey supports exactly one complete observation per selected target in this agreed revision; higher minima are rejected pending a future extension. Titles may change without changing authored lineage; an objective switch cannot retain unrelated lineage. No general custom-v2 identity is introduced.

Shared rules are in `scripts/core/mission_config_v2_rules.gd`. The earlier review checker delegates its field/reference work to these rules; its existing 466 checks still pass. The earlier review checker retains its explicitly labelled physical surrogate for historical diagnostics. **The new candidate does not rewrite v2, remove goals, substitute Imaging or modify catalogs.** It calls KE1's existing pure `_calculate_metrics` and `_run_readiness` helpers with the full original v2 config and validated indexes. Those helpers are internal integration seams in this candidate; the unchanged live validator remains their owner. No new duplicate physics formulas are introduced.

The eight original physical/readiness gates and nine metrics remain. Invalid shapes/references/context leave metrics null. Overflow is rejected before totals. Supported profile-specific limits, budget equality, launcher/target compatibility and the static essential-power rule remain independent. Readiness is not a promise of science success or a feasible action plan.

Candidate v2 results retain ValidationResult envelope `schema_version: 1` independently of config version. They add `candidate_revision`, `candidate_only`, `config_valid`, `physical_setup_ready`, `config_snapshot`, `pending_confirmation_owners` and `launch_blockers`. A structurally/reference-valid config gets a deep full v2 snapshot, even if a later physical gate fails. `physical_setup_ready` means all eight gates passed. **`ready_to_launch` is always false for v2**, with separate `HPC_CONFIRMATION_PENDING` and `V2_INTEGRATION_PENDING` blockers. Errors still describe bad input/designs; launch blockers describe unfinished integration. Do not show an all-green candidate as permission to launch.

Run:

```powershell
& $GodotExe --headless --path . --script res://tests/validation/test_mission_validator_v2_candidate.gd -- ./exports/v2-candidate-check
```

Executed: **327 candidate checks passed**; **2,429 across eight focused programs**, zero failures. Includes the 40 prior cases, unchanged valid/invalid v1 results, mass/source/budget/power/target/profile gates, unsupported versions, contexts, input/output isolation, overflow, full-goal preservation and unchanged native v2 rejection. See [evidence](evidence/v2-candidate-1/checks.json). No full player/browser or expanded scorer acceptance is claimed.

No live runtime, adapter, simulator, physical catalog, production validator, signed agreement or launch button imports this candidate. HPC confirmation and coordinated producer/evaluator/UI integration are required before rollout. Keep Communication and Weather unavailable for launch.
