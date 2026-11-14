# K01-K04 - agreed contract synchronization

Status: K01-K04 COMPLETE as already recorded in tasks.md and the signed team agreement. The user confirmed all members fully agreed to revision v1.0-agreed and requested supporting contract/example updates. Approval is recorded at 14 November 2026, 10:01 Asia/Rangoon in the source; this synchronization preserves that signed source unchanged.

## What changed

- contracts.md now records the agreed units, fields, APIs, readiness gate, action timing, event/run identities, evaluator errors, score and abort behavior.
- The existing v1-draft example directory is retained for links but now identifies itself as aligned to v1.0-agreed. Old orbit/target labels and the old per-step radio boundary were replaced.
- Four state/event/report examples are reproduced exactly from the signed source. Wrappers, positive-goal errors, cause evidence, conversions, rounding, power and action-timing expectations were added.
- Instruction/readiness documents now recognize the signed agreement. K05 remains the next implementation task.

## Verification and limits

Documentation checks cover strict JSON, fields and IDs, check/error consistency, mass boundaries, zero-goal rejection, ratios/half-up scoring, abort overrides, nullable evaluation-error fields, evidence-event IDs, adapter arithmetic and rejected/accepted action timing. These checks do not execute a production validator, evaluator or simulator.

The earlier Godot 4.7.2 headless load of a temporary project copy passed with exit code 0. Graphical rendering and exports were not tested here. The agreed Compatibility settings are reported on master while local main still declares Forward Plus/d3d12; SE owns that sync and early export check. Actual catalogs, scenario data and runtime adapters remain implementation work. No commits, pushes, branch merges or runtime engine/settings changes are made by this synchronization.

See [the agreed contract](contracts.md), [the source agreement](team-agreement.md), and [the aligned examples](contracts/v1-draft/README.md).
