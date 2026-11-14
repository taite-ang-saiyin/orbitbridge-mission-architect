# K05 and K06 implementation

Status: COMPLETE for mission/config field checks, selected-ID lookup and minimum catalog creation. Full launch readiness is still K07-K09. Signed agreement v1.0-agreed and project settings are preserved.

## K05 - mission fields and lookup

Implemented scripts/core/mission_validator.gd and the supporting catalog_loader.gd / validation_support.gd. validate(config, catalogs) accepts malformed arguments safely and returns the agreed ValidationResult keys.

Checks cover required/unknown fields, correct object/text/number types, trimmed nonempty titles up to 80 characters, positive observation/data/duration targets, 1-20 captures, 1-12 orbits, and positive whole budgets. Whole numeric JSON floats are accepted; booleans, fractions for whole-value fields, nonfinite values and numeric strings are rejected. Whole numeric values are limited to the exactly representable JSON-integer range, 9007199254740991, for safe Godot conversion; this is a storage guard rather than a gameplay price estimate.

Every selected component, launch profile, launcher, objective, target and orbit ID is checked. A known component in the wrong slot gets WRONG_COMPONENT_CATEGORY; unknown parts/profiles/launchers/orbits use the agreed codes. Missing parts and malformed input return code, field_path, message and suggested_fix. Multiple safe-to-report input problems are returned together.

The catalog helper reads local JSON and validates its schema, required numeric fields, category-specific fields, unique IDs, metadata labels and internal links. It rejects malformed/missing files and inconsistent catalog data with structured errors. Validation leaves input configuration and shared catalogs unchanged; repeated inputs return repeatable results.

## K06 - actual minimum catalogs

Added 12 illustrative parts: two options for each of bus, instrument, solar, battery, radio and storage. Added two launchers and two profiles. The sample profile stores the strict NASA-derived <1330 g rule with its source ID. The alternate <=5000 g rule, all component values and all launcher capacities/costs are explicitly illustrative.

Agreed IDs low_eq, high_inc and equator are registered separately from physical orbital metadata. Actual target suitability/windows/step duration remain HPC-owned data. No data/orbits.json or source ledger owned by another member was created or replaced.

Read [data/README.md](../data/README.md) for file shapes, units, assumptions and loading behavior.

## Use from Godot

```gdscript
const CatalogLoader = preload("res://scripts/core/catalog_loader.gd")
const Validator = preload("res://scripts/core/mission_validator.gd")

var loaded: Dictionary = CatalogLoader.load_catalogs()
if loaded["ok"]:
    var result: Dictionary = Validator.validate(config, loaded["catalogs"])
    # input_schema and catalog_references are the completed K05 checks.
    # Full launch approval is not implemented yet.
else:
    # Show loaded["errors"] rather than using an empty or fallback catalog.
    pass
```

At this stage, valid fields/IDs produce passing input_schema and catalog_references checks. metrics remains null, ready_to_launch remains false, and the other six checks remain not_evaluated with an explicit explanation. The profile_mass record has its agreed keys with null values until the corresponding readiness step is implemented. This preserves the public response layout without inventing a launch verdict or completed metrics.

## Verification

Godot 4.7.2 ran tests/validation/test_mission_validator.gd: **296 checks passed, 0 failed**, exit code 0. The suite loads the actual JSON catalogs and a mission fixture; tests valid selections, input/range failures, missing/unknown/wrong-category IDs, malformed files/collections, duplicate IDs, invalid/nonfinite catalog values, source-rule integrity, broken catalog links, deterministic results and preservation of inputs. It also confirms K05 cannot accidentally approve Launch.

Run from the project folder with the current sibling editor layout:

```powershell
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/validation/test_mission_validator.gd
```

Use the installed editor path on other machines. These are real Godot checks of the K05/K06 implementation. Runtime mass/budget/power/orbit checks, simulation, screens and exports have not been tested by this suite because they are outside these two tasks.

## Blockers and next work

No blockers for K05/K06. K07 adds calculated totals, K08 adds feasibility checks and K09 completes the source-linked readiness result. Actual orbit suitability/scenario metadata must come from HPC before its later readiness/simulation integration. SE connects the helper results to the screens in the later integration tasks. No commits or pushes are performed by this work.
