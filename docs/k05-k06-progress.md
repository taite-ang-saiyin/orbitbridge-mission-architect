# K05 and K06 implementation

Status: COMPLETE for K05/K06. Current update: K07/K08 now add totals/full readiness and also cover K09 source-linked fields; see [k07-k08-progress.md](k07-k08-progress.md). The original K05/K06 milestone below had 296 passing checks; the updated current regression suite has 294 and the readiness suite has 671. Signed agreement and project settings are preserved.

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
    # Check result["ready_to_launch"] and display its metrics/checks/errors.
else:
    # Show loaded["errors"] rather than using an empty or fallback catalog.
    pass
```

At the original K05/K06 milestone only the first two checks ran. K07/K08 have now replaced those temporary null/false placeholders with actual metrics and readiness, using HPC metadata. Invalid inputs still cannot become fabricated zero totals or launch approval.

## Verification

Godot 4.7.2 ran tests/validation/test_mission_validator.gd: **296 checks passed, 0 failed**, exit code 0. The suite loads the actual JSON catalogs and a mission fixture; tests valid selections, input/range failures, missing/unknown/wrong-category IDs, malformed files/collections, duplicate IDs, invalid/nonfinite catalog values, source-rule integrity, broken catalog links, deterministic results and preservation of inputs. It also confirms K05 cannot accidentally approve Launch.

Run from the project folder with the current sibling editor layout:

```powershell
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/validation/test_mission_validator.gd
```

Use the installed editor path on other machines. These are real Godot checks of the K05/K06 implementation. Runtime mass/budget/power/orbit checks, simulation, screens and exports have not been tested by this suite because they are outside these two tasks.

## Blockers and next work

No blockers for K05/K06 or the completed K07/K08 extension. HPC's orbit file is now available and imported unchanged; K09 response fields are covered by the mass check. K10/K11 saved fixture handoff and team/screen integration are next. No commits or pushes are performed by this work.
