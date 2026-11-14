# K13a/K14: Windows demo and acceptance scenarios

Completed locally on 14 November 2026. The user selected Windows for the first demo and subsequently confirmed that the team considers the Windows demo okay. No commit, push, upload or team message was made.

## K13a: standalone Windows app

The Windows x86_64 release build uses Godot 4.7.2 Standard, Compatibility rendering and an embedded game-data pack. `OrbitBridge.exe` runs without an editor installation or a separate PCK file. The demo and README are in the sibling `OrbitBridge-Windows-Demo` folder under the user's Desktop OrbitBridge directory; generated binaries remain outside tracked source files.

Added `export_presets.cfg` with the `Windows Demo` preset and `scripts/build_windows.ps1` for reproduction. The preset includes runtime JSON catalogs and excludes tests, source documentation and personal assistant/task files. It has no machine-specific template paths. Matching Windows debug/release templates were installed in Godot's standard `4.7.2.stable` template folder.

Templates came from the [official Godot 4.7.2 archive](https://godotengine.org/download/archive/4.7.2-stable/). Only the required Windows entries and version file were fetched, using HTTP ranges to avoid downloading unrelated platforms. Complete entries passed ZIP CRC checks and their SHA256 values were recorded. The full 1.28 GB TPZ archive was not downloaded, so its full SHA512 was not computed or claimed. [Godot's Windows export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html) describes the template/data-pack export mechanism.

The exported app passed **61 checks, zero failures**, both headlessly and with real OpenGL graphics enabled. These comprise 40 scene/mission scenario assertions and 21 packaging checks. The package checks verify the engine version, all nine modular art variants, the five required runtime JSON files, and exclusion of personal docs/test sources. The real launch → HPC → KE2 → Results flow runs inside the exported executable, not just the editor.

The app's explicit `-- --verify-demo` option performs this check and exits with code 0 on success. Normal startup opens Home and never runs the verification mode. The runtime verifier is `scripts/verification/demo_verification.gd`; it connects existing controls/owner APIs and does not add another validator, simulator or scoring model.

## K14: mission scenarios

| Scenario | Observed result |
| --- | --- |
| Starter parts | 1060 g / 82 credits, ready |
| Advanced camera + standard battery + small launcher | 1380 g / 96 credits, blocked by the strict sample weight rule; launcher capacity itself passes |
| Advanced camera + large battery + small launcher; budget 120 | 1580 g / 106 credits, blocked by sample weight and the high-inc launcher's 1500 g capacity; budget passes |
| Starter parts; budget 81 | Weight passes; cost 82 exceeds budget; launch stays blocked |
| Unsupported target in a saved draft | Rejected with an explicit instruction to choose Equator; no silent target substitution or false totals |
| Choose Equator again | Readiness becomes passing |
| high_inc mission | 4 captures, 48 MB returned, success / 100 |
| low_eq mission | 4 captures, about 44.32 MB returned, success / 100 |
| Invalid button/navigation entry | Cannot bypass launch validation |
| Retry, abort, repeated Results, New Mission | Correct reset, null abort score, one report per run, cleared history for New Mission |

The unsupported-target correction was made clearer in the UI adapter. The public validator/schema and its blocking verdict are unchanged. Only the agreed Equator target is offered in Creator; the malformed-target case is exercised by the automated check instead of inventing another supported target.

## Test evidence and team review

The source project passes **1706 counted checks, zero failures**: the previous 1666 plus the new 40-assertion K14 suite. The separate legacy simulator suite also exits 0 without a count. All nine source test programs exit 0. The unchanged KE2 owner suite retains its five older pending declarations, including optional comparison; new source/exported scene checks supply actual full-flow acceptance evidence. Optional controlled A/B comparison is still unimplemented and not represented as working.

The standalone release independently passes 61 checks in both headless and graphical modes, exits 0, and loads real models/catalogs from its embedded pack. [Structured evidence](verification/windows-demo-checks.json) records executable size/hash, exact runtime inputs and actual scenario results. Reproduction commands are in [tool-setup.md](tool-setup.md).

[The team review sheet](k14-team-review.md) records the user's final team-demo acceptance. Local scenario checks are automated; individual reviewer names and per-case manual signatures were not supplied and are not invented. The signed agreement and all KE1/HPC/KE2 calculation rules remain unchanged.

## Next work and limits

No blockers remain for K13a/K14 under the user's confirmed Windows choice and team-demo acceptance. Browser export and optional comparison remain outside this demo. The Windows app was tested on this machine; another computer was not available. Native desktop input automation was unavailable, so screen actions were verified through actual Godot controls/signals and the graphical exported app. K15 is next: review and merge/share stable work through the team's normal Git process when requested.
