# Agreed v1 readiness and runtime policies

Status: ALIGNED TO v1.0-agreed. K04 policy decisions are recorded complete in tasks.md and the signed team agreement. This file documents those decisions without implementing game logic.

## Pre-launch checks

- The sample 1U profile requires modeled spacecraft mass strictly below 1330 g. 1329 passes this check; 1330 and 1331 fail. Other profiles use their own rules.
- Capacity/budget use their applicable less-than-or-equal limits; profile, launcher/orbit and target checks remain independent.
- Battery capacity and initial energy must be positive; initial energy respects capacity. Sunlit solar generation must be at least baseline load. Equality is permitted. This is the agreed illustrative pre-launch gate, not proof of energy sufficiency through active tasks or eclipse.
- Static target/orbit suitability uses HPC's actual agreed metadata. Preset IDs are low_eq/high_inc and target equator. Unknown/missing or incompatible metadata cannot authorize launch; do not invent access from the preset label. The production compatibility matrix is HPC's implementation data, not supplied by these examples.

## Runtime behavior owned by HPC

Accepted power_save applies baseline/solar accounting, generates no science data, advances exactly one step and clamps energy at zero when needed without aborting the run. A valid low-energy operating state is distinct from an invalid empty-battery launch configuration. Upper energy and storage bounds still apply.

Rejected action requests emit action_blocked, change no resources, and do not advance step_index. At the final accepted step, step_index equals total_steps, phase is finished and run_status is completed. An explicit abort uses aborted status and preserves progress/reason for evaluation.

The public rate is downlink_mb_per_hour. HPC derives per-step capacity from explicit step_duration_hours and exposes Wh and decimal MB at the boundary (1000 KB per MB, 3600 Ws per Wh). The legacy whole-run Ws/KB model stays behind its documented adapter.

## Expectation examples and implementation work

agreed-behavior-cases.example.json records illustrative power, strict mass and action-timing vectors. unit-conversions.example.json records adapter/rate arithmetic. These are consistency checks on examples, not executed simulator or validator tests.

HPC still authors actual scenario values, supported-target metadata, initial-charge implementation and deterministic energy-update equations, then aligns its candidate engine to the signed APIs. Changes to the agreed public policies require the affected owners' approval; routine data/code implementation is separate from approval status.
