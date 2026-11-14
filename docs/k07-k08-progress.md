# K07 and K08 - totals and launch readiness

Status: COMPLETE. K07 calculates the selected design's metrics; K08 evaluates all required readiness checks. The mass result also fulfills K09's source-linked response fields. Screens, operations and evaluator integration remain separate tasks.

## Implemented totals

The validator sums each of the six selected spacecraft parts exactly once. Launcher mass is excluded; launch service cost is included. It reads baseline load, solar output, battery capacity/initial charge, storage, instrument data per capture and the hourly radio rate from the selected parts. Integer sums are guarded before overflow or loss of reliable representation. Malformed input/catalog data cannot become fabricated zero totals.

| Base selection metric | Actual catalog result |
| --- | --- |
| Total spacecraft mass | 1060 g |
| Total parts-plus-launch cost | 82 illustrative credits |
| Baseline power | 2 W |
| Sunlit solar power | 3 W |
| Battery capacity / initial energy | 25 Wh / 25 Wh |
| Storage | 64 decimal MB |
| Data per successful capture | 12 decimal MB |
| Radio rate | 48 decimal MB/hour |

The returned metric keys remain the nine fields in the agreed v1 contract. Runtime action costs and step-by-step battery/storage accounting remain HPC's responsibility. Passing pre-launch checks is not a guarantee that science goals will be met.

## Implemented checks

- Profile-specific mass: the cited 1U sample requires <1330 g; the illustrative alternative uses its own <=5000 g rule. The mass record returns actual mass, threshold, strict comparator, profile ID, source ID when applicable and pass/fail. Alternative assumptions are not mislabeled as NASA sources.
- Launcher capacity: compare spacecraft mass to the selected launcher's limit for the selected orbit; equality passes. An unsupported orbit cannot borrow another orbit's capacity.
- Budget: include launch service cost and allow equality.
- Compatibility: independently check the profile's supported orbits, the launcher's supported profiles and its supported orbits.
- Target suitability: use HPC's authored target observation windows, not an inferred coverage claim from an orbit's name or drawing.
- Essential power: require positive battery capacity/initial charge and sunlit solar power >= baseline, with initial energy within capacity. This remains the agreed illustrative pre-launch gate, not whole-mission energy prediction.

Independent failures are returned in the agreed check order, with code, field_path, message and suggested_fix. Valid metrics remain available when feasibility fails. ready_to_launch is true only when all eight required checks pass and no blocking errors remain. Missing/unusable target metadata leaves target_orbit not_evaluated and blocks launch explicitly.

## HPC data provenance and adapter

The user identified feature/hpc-simulator as the source. Read commit ab7865cf45e65de84637b4319899759928ee7082 from that branch and copied only data/orbits.json without edits. No other HPC scripts, branches, tests or project settings were merged.

Copied file SHA256: 0ed028a477998057ede2e6f79bd29d7d7569b32e6a9869d00c9826a0f8aa36d4.

The native file declares schema_version 1, scenario_version orbit-presets-v1 and unit_conventions for hours/decimal MB. It includes low_eq and high_inc presets, each with explicit equator target_windows. Their window_model text states that the authored windows are gameplay assumptions, not real coverage predictions.

CatalogLoader.load_catalogs() reads this optional HPC file into catalogs.orbit_catalog, preserving its native fields and scenario version. Unlike the four KE1 files, HPC's native file does not declare contract_revision; its schema/version/unit fields are checked instead. The validator reads target_windows: at least one valid observation index for the selected target is required. It checks the selected preset's positive finite step duration, whole steps_per_orbit, valid in-range observation indices, unique registered orbit IDs, and matching public units. No physical orbit or visibility model is invented.

If the file is absent, field/catalog loading can still succeed, but validation returns a blocking structured metadata error and no launch approval. If the file is malformed, loading/validation reports the error rather than falling back to guessed coverage. A supplied catalogs.orbit_catalog dictionary uses the same native format.

## Verification

Godot 4.7.2 results:

- tests/validation/test_mission_validator.gd: 294 checks passed, 0 failed. Earlier field/catalog tests were updated to assert completed readiness rather than temporary K05 placeholders.
- tests/validation/test_mission_readiness.gd: 671 checks passed, 0 failed.
- Total: 965 checks passed; both programs exited with code 0.

Coverage includes independent expected totals, every selected-part swap, launch cost/mass separation, fractional initial charge, strict 1329/1330/1331 g boundaries, alternate-profile equality, launcher/budget equality and failure, profile/launcher/orbit mismatches, power equality/low charge, actual HPC target windows, missing/invalid metadata, safe aggregate arithmetic, multiple simultaneous failures, stable result order and unchanged inputs.

Run both from the project root with the current sibling editor layout:

```powershell
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/validation/test_mission_validator.gd
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/validation/test_mission_readiness.gd
```

These checks exercise KE1 code and the read-only HPC orbit data. They do not claim to test HPC's simulator, UI scenes, actual physics or exports. Original signed agreement, component/launcher/profile data and project settings are preserved.

## Blockers and next work

No blockers remain for K07/K08: the orbit file was found on the user-named branch. K09's source-linked response requirement is covered by the mass check and its tests. Subsequent K09/K10 work has verified the source fields and 15 saved readiness cases; see [k09-k10-progress.md](k09-k10-progress.md). All three suites now pass 1435 checks. K11/team integration is next. Final UI/source-credit display and renderer branch sync remain their existing owners' tasks. No commits or pushes are performed by this work.
