# KE1 validation and test plan

Status: K05-K14 including K13a complete locally. New acceptance suite: 40 passed; combined source count 1706 plus successful legacy simulator suite, all nine programs exit 0. Standalone Windows app: 40 scenario + 21 package checks passed headlessly and graphically. User confirmed team demo acceptance. See k13a-k14-progress.md. The remaining paragraph retains the K12/K13 coverage record. The active screen and real runtime flow pass the new 32 mission-flow and 30 screen-flow checks. Imported owner suites also pass: HPC 26, KE2 143 (five original pending declarations), legacy simulator exit 0. Combined with KE1's 1435 checks: 1666 counted passes, zero failures; all eight programs exit 0. See k12-k13-progress.md. Godot 4.7.2: field/catalog suite passed 294 checks; readiness suite passed 671; saved-fixture suite passed 470; total 1435 passed with 0 failures. This includes unchanged HPC orbit data, strict mass/alternate-profile boundaries, cost/power/compatibility, safe arithmetic, source details and preserved inputs. The 15 saved cases are documented in ../tests/fixtures/README.md and k09-k10-progress.md. The local full-run/screens, Windows export and user-reported team demo acceptance are verified. Optional comparison, browser and another-machine testing remain separate work.

Authority: [contracts.md](contracts.md), aligned to team-agreement.md v1.0-agreed. Public rates use downlink_mb_per_hour, energy uses Wh, and data uses decimal MB (1000 KB = 1 MB). The current fixtures in contracts/v1-draft/ are documentation examples with consistency checks, not production-test results.

## Current stage

All eight checks and nine metrics are implemented. Valid designs pass only with usable HPC orbit metadata and no failed/unevaluated required check. Missing metadata is an explicit blocking issue. Actual native HPC target_windows are read from orbit_catalog; hypothetical mutations in tests do not alter the source file. Actual catalogs keep hourly radio rates and labeled training values.

## Validation order

1. Check config and catalog structure, required fields, numeric types, finiteness, and ranges.
2. Resolve every selected component, launcher, profile, and orbit ID. Check component categories.
3. Calculate metrics only from valid resolved values. Do not substitute zero for missing mass or cost.
4. Check selected profile mass, launcher capability for the selected orbit, budget, launch/orbit compatibility, target suitability, and essential power under the agreed model.
5. Return all safe-to-compute blocking issues and useful warnings in deterministic order. Invalid dependent checks are not_evaluated.

Avoid a single early mass return that hides an independent budget error. Structural failures may prevent downstream arithmetic; explain that explicitly. UI should display the result without recalculating it.

## Test cases to implement after kickoff

| ID | Change or input | Expected behavior |
| --- | --- | --- |
| V01 | Complete feasible design | Launch-ready; correct totals and no blocking issues |
| V02 | Sample 1U total is 1329 g | Sample mass check passes; other checks still apply |
| V03 | Sample 1U total is 1330 g | Sample mass check fails; launch blocked |
| V04 | Sample 1U total is 1331 g | Same failure, with actual mass and threshold |
| V05 | Same mass with a different profile | Uses the alternate profile rule; no inherited 1U threshold |
| V06 | Each selected part changed individually | Mass/cost and relevant subsystem metrics change exactly once |
| V07 | Heavy instrument with limited launcher | Explicit capability/profile reason and a useful correction |
| V08 | Cost equals budget / exceeds by one credit | Equality passes; excess fails |
| V09 | Missing selected slot / unknown ID / wrong category | Structured blocking issue; no exception or false zero totals |
| V10 | Zero/negative requirements, fractional counts, nulls, wrong types | Explicit field error; no silent coercion |
| V11 | Invalid catalog numeric values, including nonfinite programmatic inputs | Rejected before arithmetic; JSON itself cannot encode NaN/infinity |
| V12 | Launcher supports one orbit but another is selected | Launch-orbit incompatibility blocks launch |
| V13 | Target changed to unsupported region | Readiness changes according to shared target/orbit rule |
| V14 | Design violates agreed essential-power rule | Blocking issue; dynamic battery simulation remains HPC's responsibility |
| V15 | Mass passes but budget fails | Overall ready_to_launch remains false |
| V16 | Same config and catalogs validated twice | Same result; inputs remain unchanged |
| V17 | Malformed input prevents metrics | Metrics are null/unavailable, dependent checks not_evaluated |
| V18 | Missing/unknown profile or orbit | Blocks launch; no fallback to a more permissive profile |

Build one known feasible base fixture, then vary one property at a time. Verify the resulting total actually reaches each boundary. Keep fixtures small and include both source-derived limits and illustrative parameter labels.

## Agreed v1 integration cases

- Confirm low_eq/high_inc orbit IDs and equator target reach the same adapter/preset records; unsupported or unresolved metadata cannot silently pass.
- Check hourly radio rate multiplied by actual step_duration_hours, Ws divided by 3600, and legacy KB divided by 1000. Never relabel a per-step value as an hourly rate.
- Reject zero observation/data targets in both KE1 validation and KE2 evaluation.
- Rejecting an action request produces zero deltas and no step advancement. Accepted power_save at insufficient energy clamps to 0.0 Wh, continues, and advances one step; the final accepted step completes exactly at step_index == total_steps.
- Evaluate completed goals using equal-weight capped ratios and round_half_up. Exercise a 62.5-to-63 tie and a rounded 100 score whose raw data goal remains unmet.
- Abort even after goals were met produces failed/null-score report. Nonterminal/malformed input produces EvaluationError with nullable field_path/run_id as applicable, not a failed mission report.
- Validate root-cause event references; missing/unknown evidence produces neutral report-level explanation and no fabricated cause.
- Ensure repeated terminal notifications/reopening Results do not duplicate reports or retry history. Comparisons exclude aborts and preserve matching scenario/target conditions.

## UI and team checks

- With SE, choose the sample 1U profile, swap a component across the strict boundary, and observe metrics, explanation, citation, and Launch enabled state.
- Switch profiles and verify the source label and threshold change correctly.
- Carry selected IDs, mission goals, and validated config through scene transitions.
- With HPC, verify simulation cannot start from an invalid config and that no UI bypass skips readiness.
- With KE2, confirm target and science requirements are preserved for evaluation; feasibility is not recorded as mission success.
- In the exported browser build, confirm the same behavior and that credits are accessible.

## Verification record template

Record task ID, command/check performed, Godot version, passed/failed count, evidence or output, and any untested behavior. Add the actual runner command to tool-setup.md once the project and tests exist. Until then, do not claim headless tests or export validation passed.
