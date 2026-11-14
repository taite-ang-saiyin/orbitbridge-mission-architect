# SE updates merged with main

This merge combines main `e71aaf8712b9b9438247cb514467bb33bc015989` with SE `4712bc15440f5a71cb2165f7f7e7acc8fc15484f` and the newer SE navigation update `8399c319cfe0aef3ba6acbfc0cfc9c3680a48b15`. It also uses KE2's current evaluator and checks from `dbf65ad` so unsupported Survey scoring is reported explicitly.

## Conflict decisions

- Keep SE's Mission Control presets, new navigation, Creator, catalog controls, expanded targets, simulation playback, and per-target packet accounting.
- Keep main's validated launch, exact budgets, manual engine actions, immutable retry snapshots, abort handling, terminal evaluation, and report deduplication. Prevent edits during a run and prevent replay from changing a recorded result.
- Keep the current whole-project README and extend the implementation contracts. The signed team agreement and native `data/orbits.json` are unchanged.
- Keep historical mock tests archived. Restore the updated SE versions as active tests and update their fixtures to finish a run before editing it. Exclude the archive from Godot imports to avoid duplicate script UIDs.
- Fix new-run playback position, clear playback caches when reused, and make result-history columns readable. Manual-action predictions use the native engine and appear in the action buttons' tooltips.

## Verification

Godot 4.7.2 Standard, Compatibility renderer, Windows x86_64.

Run `tests/run_all_checks.ps1` for the 25 active programs. Counted suites cover validation (294), readiness (671), saved fixtures (470), HPC (48), KE2 (207), pure mission flow (32), merged screen edge cases (19), and acceptance (44). Other smoke programs cover the full UI, responsive layouts, multi-target accounting, prediction parity, controller evaluation, and 3D assets. KE2's five declared pending checks remain pending; they are not counted as passes.

The release build is checked with `scripts/build_windows.ps1 -Verify`, including the exported executable's own `--verify-demo` mode. It checks 44 mission assertions and 22 package assertions. A graphical run checks the same exported program. GPU-rendered captures of Mission Control, Creator, Builder, Readiness, Operations, and Results supplement automated layout checks; this is not a teammate acceptance review.

Final results and executable hash: [verification record](verification/se-main-merge-checks.json). Generated logs, captures, and builds remain local rather than entering source control.

## Limits

Survey simulation and delivery counters work, but KE2 Survey scoring is unavailable. The UI warns before launch and displays an evaluation error instead of an Imaging score. Controlled A/B comparison, browser export, and testing on another Windows computer are not established by this merge. Educational scenario windows are not physical coverage forecasts.

The merge was prepared in an isolated checkout. Personal files and the unfinished Web export edit in the user's existing KE1 checkout were preserved and excluded.
