# Godot and workspace setup

## Use this repository

Use this repository for shared code and docs. The user's AGENTS.md, GEMINI.md and tasks.md are personal KE1 branch notes and are deliberately not shipped on shared main. They are not runtime dependencies. The earlier OrbitBridge-KE1 folder is a preparation snapshot.

K01-K14 including K13a are complete locally. Import the current project in Godot instead of creating another project or Git repository. The active scenes, catalogs, validator, simulator/evaluator integration and Windows demo are implemented and tested; see k13a-k14-progress.md.

## Editor and team agreement

The downloaded local editor is Godot 4.7.2 Standard for Windows x64; its direct version check passed. GDScript is the planned language. Teammates can use the .NET edition at the same exact Godot version while keeping project code and plugins GDScript-only. C# would require an explicit team decision and the appropriate editor/SDK setup.

The user confirmed Godot 4.7.2 and Windows for the first demo. Matching Windows x86_64 release/debug export templates and version.txt are installed in Godot's standard export_templates/4.7.2.stable user-data folder. Godot is portable; no installer or PATH change was made. No server, database, Python runtime or editor installation is needed to play the standalone demo.

Official downloads: https://godotengine.org/download/windows/

## Current target and renderer

Current target: Windows x86_64 first demo, selected by the user and subsequently accepted by the team per the user's report. SE's imported Compatibility-renderer/main-scene settings are used. The standalone app passes its full check with OpenGL graphics enabled.

Compatibility/GDScript remains the agreed technology. The Windows Demo export preset embeds game data and includes the real runtime JSON catalogs. Browser export has not been built or tested; it remains a separate possible future target.

## Local editor verification record

- Windows x64 architecture confirmed; Git is available.
- Editor is in the sibling ../Godot/4.7.2-stable/ folder, outside the Git repository.
- Direct executable --version: PASSED; `4.7.2.stable.official.ed1daf0bf`.
- ZIP integrity: PASSED; every archive entry passed CRC validation.
- Official SHA512: MATCHED against https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/SHA512-SUMS.txt; a copy is beside the editor.
- SHA512: `83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993`.
- Recorded SHA256: `731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953` (audit record; SHA512 was compared with the official release).
- Signature inspection found Prehensile Tales B.V., but the local API returned UnknownError; successful certificate-chain validation is not claimed.
- Console wrapper returned CreateProcess error 193 in this execution environment. The main executable's direct version check succeeded; use that executable here.
- Current K13a/K14 verification: Compatibility graphics tested; Windows templates installed; 1706 source checks plus legacy suite passed; standalone Windows export passed 61 checks with graphics and headlessly.

From this repository root, using the current sibling tool layout:

```powershell
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --version
```

On another machine, use that machine's editor location. Do not place editor executables, archives, or machine-specific paths in gameplay code.

## Remaining preparation

1. Complete: the user confirmed Codex and Antigravity assistant checks are successful.
2. Complete: Godot 4.7.2, 09:00 kickoff and Windows first-demo target are user-confirmed; team Windows-demo acceptance was reported by the user.
3. Complete: actual Compatibility/OpenGL scene rendering and graphical Windows export were checked.
4. Complete: matching Windows x86_64 release/debug templates installed; other platform templates were not installed.
5. Review contracts and validation plans, keeping proposed interfaces distinct from approved decisions.

## Assistant check record

The current Codex session read and summarized the root instructions. The user subsequently confirmed Codex and Antigravity assistant checks are successful. This item is complete based on user confirmation. The earlier UI check stopped with Escape; no further UI input is needed. The reusable read-only prompt remains in [pre-kickoff-review.md](pre-kickoff-review.md).

## K02 project-load check

A temporary copy of the existing project.godot and icon files loaded using the installed main Godot 4.7.2 executable with --headless --editor --path <scratch-copy> --quit. Exit code 0; no reported errors. Original tracked engine/config files were preserved. Headless mode uses a dummy display, so graphical rendering and export remain unverified. The project has no main scene and this was not a playable-game run.

## Tests after kickoff

From the project root, using the current sibling editor layout:

```powershell
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/validation/test_mission_validator.gd
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/validation/test_mission_readiness.gd
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/validation/test_mission_fixtures.gd
```

Current Godot 4.7.2 results: KE1 294 + 671 + 470; HPC 26; KE2 143 (five original pending declarations); new real-flow 32; new screen-flow 30. K14 adds 40 acceptance assertions: total 1706 counted passes, zero failures; the legacy simulator suite also exits 0 without a count. All nine programs exit 0. This tests the local validator, real simulator/evaluator, scene controls and results; the Windows export also passes 61 checks headlessly and with graphics; browser/another-machine testing remain unverified. See k12-k13-progress.md for provenance and limitations. See [k07-k08-progress.md](k07-k08-progress.md) for coverage/provenance and [k09-k10-progress.md](k09-k10-progress.md) for saved-case verification.

## Version control

Preserve the repository's existing editor and Git settings. The additional preparation ignore entries cover generated exports, downloaded tools, temporary work, and private local environment files. Documentation integration is a local working-tree change; no commit or push is performed automatically.

## K12/K13 integrated project checks

The imported SE project settings already select Main.tscn and Compatibility rendering. Let Godot import the new assets before running screen tests (or run the first command below). From the project root:

```powershell
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --editor --import --path . --quit
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_hpc.gd
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_simulator.gd
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_mission_evaluator.gd
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/integration/test_mission_flow.gd
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/integration/test_screen_flow.gd
```

Also run the three KE1 commands above. On another machine, substitute its Godot 4.7.2 executable path. Native input automation was unavailable in this session; actual scenes/signals and GPU-rendered images were used to verify screen behavior/appearance. The optional A/B comparison is not implemented by KE2. Windows/browser export templates and packaging remain outside K12/K13.

## K13a/K14 Windows demo

The built executable/README are in the sibling OrbitBridge-Windows-Demo folder. The app has embedded data; no separate PCK or editor is needed to play it. The user selected Windows and reported team demo acceptance.

From the project root, rebuild and verify with installed matching 4.7.2 Windows templates:

```powershell
.\scripts\build_windows.ps1 -GodotExe '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' -OutputDirectory '..\OrbitBridge-Windows-Demo' -Verify
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/acceptance/test_k14_acceptance.gd
& '..\OrbitBridge-Windows-Demo\OrbitBridge.exe' --headless --log-file verification.log -- --verify-demo
```

Omit --headless to exercise real graphics. Normal double-click startup opens Home; verification runs only when explicitly requested. Results: source K14 40/0; standalone scene 40/0 plus package 21/0, exits 0 in both modes. See k13a-k14-progress.md and verification/windows-demo-checks.json for source/hash provenance, precise template integrity checks and limitations.

## K15 stable integration verification

The latest merge retains main's newer HPC engine/tests and current KE2 runtime/tests. All 12 active programs pass: 1790 counted assertions plus the four uncounted smoke/legacy programs. The merged Windows release passes 61 assertions headlessly and with real graphics. Run `tests/run_all_checks.ps1 -GodotExe <your-Godot-4.7.2-executable>` from PowerShell, then `scripts/build_windows.ps1 -GodotExe <your-executable> -Verify`. Artifacts are generated under ignored exports/. See k15-integration.md and sunday-blockers.md; earlier counts/manifests in this document record older milestones.
