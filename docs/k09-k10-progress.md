# K09/K10: source details and saved examples

Status: complete on 14 November 2026 against contract `v1.0-agreed`. K09's required result fields were implemented with K08 and have now been verified directly against saved passing and failing examples. No public interface or game-catalog change was needed.

## K09 result details

`checks.profile_mass` returns total_mass_g, threshold_g, comparator, profile_id, source_id, passed, status and message. The sample 1U profile uses strict `< 1330 g` and `cubesat_101_1u_sample`. Failing sample-mass issues also carry that source ID. The alternative uses its own `<= 5000 g` assumption, null source_id, and an assumption_id; it does not claim a NASA limit. Invalid selections leave dependent mass fields null and status not_evaluated.

A passing mass check does not permit launch when budget or compatibility fails. The saved tests verify both cases. They also verify that repeated calls return the same answer and do not change the input config or catalogs.

## K10 saved cases

See [the fixture guide](../tests/fixtures/README.md) and `tests/fixtures/ke1_readiness_cases.json` for the 15 runnable cases and their expected result fields/error codes. Existing valid, near-limit, overweight, alternative-profile, budget-failure and incompatible-launcher configs were preserved and added to the runner. New configs cover budget equality, the second orbit, a missing radio and an unknown instrument.

The real saved configs produce 1060 g / 82 credits (valid), 1320 g / 99 credits (near limit), 1380 g / 96 credits (sample overweight), and 1380 g / 116 credits (compatible alternative). Exact 1329/1330/1331 g and 5000/5001 g tests use explicitly labeled overrides on private catalog copies. Production component values are unchanged. All component values and non-source-backed limits remain labeled training assumptions.

## Verification

Godot `4.7.2.stable.official.ed1daf0bf`, run against the actual project:

| Runner | Passed | Failed | Exit |
| --- | --- | --- | --- |
| test_mission_validator.gd | 294 | 0 | 0 |
| test_mission_readiness.gd | 671 | 0 | 0 |
| test_mission_fixtures.gd | 470 | 0 | 0 |
| Total | 1435 | 0 | |

Commands are recorded in [tool-setup.md](tool-setup.md). The new suite reads the saved inputs and expectations, calls the public validator, checks actual totals and source fields, compares exact blocking error codes, and confirms all required checks control launch permission.

The signed agreement, production validator/catalog scripts, existing saved configs, game catalog values, project settings and HPC orbit data are unchanged by K09/K10. HPC orbit-file SHA256 remains `0ed028a477998057ede2e6f79bd29d7d7569b32e6a9869d00c9826a0f8aa36d4`.

## Blockers and next task

No blockers for K09/K10. K11 is the team handoff. Screens, simulator calls and exports still require their owners' integration and have not been tested here. No commits, pushes or team messages were made.
