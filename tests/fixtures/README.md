# KE1 saved readiness examples

These files work with the current KE1 catalogs and `MissionValidator.validate(config, catalogs)` from contract `v1.0-agreed`. They describe pre-launch checks, not completed missions. Component values, launch prices, power rules, and orbital windows are illustrative training assumptions.

## Configs usable directly

| Config file | Mass | Cost | Expected result |
| --- | --- | --- | --- |
| valid_1u_feasible.json | 1060 g | 82 credits | Ready |
| valid_1u_1320g.json | 1320 g | 99 credits | Ready, near the sample limit |
| overweight_1u_1380g.json | 1380 g | 96 credits | Blocked: PROFILE_MASS_EXCEEDED |
| alternate_profile_1380g.json | 1380 g | 116 credits | Ready with alternative profile and medium launcher |
| budget_fail.json | 1060 g | 82 credits | Blocked: BUDGET_EXCEEDED; budget is 81 |
| incompatible_launch_profile.json | 1060 g | 82 credits | Blocked: LAUNCH_ORBIT_INCOMPATIBLE; small launcher does not support alternative profile |
| budget_equal.json | 1060 g | 82 credits | Ready; budget equals cost |
| valid_low_eq.json | 1060 g | 82 credits | Ready using the other agreed orbit |
| missing_radio.json | Unavailable | Unavailable | Blocked: MISSING_COMPONENT |
| unknown_instrument.json | Unavailable | Unavailable | Blocked: UNKNOWN_COMPONENT |
| ke1_config.json | 1060 g | 82 credits | Original feasible regression config |

The six existing named examples and original regression config were preserved. The runner reads the saved JSON files rather than rebuilding them in code.

## Exact boundary cases

`ke1_readiness_cases.json` is a test manifest, **not a MissionConfig**. Each case selects a config file and lists expected result fields and exact blocking error codes. `test_only_bus_mass_g`, when present, changes only a private copy of the component catalog in the test. Never copy these overrides into game data or the UI.

| Profile | Test bus mass | Expected total | Expected mass result |
| --- | --- | --- | --- |
| Sample 1U | 569 g | 1329 g | Pass |
| Sample 1U | 570 g | 1330 g | Fail |
| Sample 1U | 571 g | 1331 g | Fail |
| Illustrative alternative | 3920 g | 5000 g | Pass |
| Illustrative alternative | 3921 g | 5001 g | Fail; launcher capacity also fails |

The sample's strict `< 1330 g` rule carries source ID `cubesat_101_1u_sample`: NASA CubeSat 101, Appendix C item 6, printed p.79 / PDF p.87. This is the designated sample profile, not a universal CubeSat certification rule. The alternative uses `<= 5000 g`, source_id null, and assumption_id `illustrative_small_sat_mass_limit_v1`. See [the source ledger](../../docs/sources.md).

## Run the saved cases

From the project root, using the current sibling editor layout:

```powershell
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/validation/test_mission_fixtures.gd
```

For another computer, replace the executable path with that computer's Godot 4.7.2 executable. A successful run prints all 15 cases and `470 checks passed; 0 failed`, then exits with code 0. It checks source details on passing/failing/unevaluated results, independent launch blocking, invalid input, both orbits, repeatable output, and unchanged inputs.

Load an individual config through the public interface:

```gdscript
const Loader = preload("res://scripts/core/catalog_loader.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")

func check_saved_example() -> Dictionary:
    var loaded: Dictionary = Loader.load_catalogs()
    if not loaded["ok"]:
        return loaded # Caller must handle loading errors and keep launch blocked.
    var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(
        "res://tests/fixtures/valid_1u_feasible.json"))
    return Validator.validate(config, loaded["catalogs"])
```

Display the returned checks and errors; enable Launch only when `ready_to_launch` is true. Do not recompute mass or readiness in the screen. The older `docs/contracts/v1-draft/` files are documentation mocks and are separate from these real-catalog examples. Screen, simulator, and export integration remain K11 onward.
