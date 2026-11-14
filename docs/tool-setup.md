# Godot and workspace setup

## Use this repository

This cloned repository is the active KE1 workspace. Open its root in Codex and Antigravity so they read AGENTS.md, GEMINI.md, tasks.md, and docs/. The earlier OrbitBridge-KE1 folder is a preparation snapshot; make new project changes here.

The existing project.godot and icon came from the team repository. K01-K09 are complete; calculated totals/full readiness/source-linked mass results are implemented and tested. Gameplay scripts, scenes, and production validator tests have not been implemented. Import this existing project in Godot instead of creating another project or Git repository.

## Editor and team agreement

The downloaded local editor is Godot 4.7.2 Standard for Windows x64; its direct version check passed. GDScript is the planned language. Teammates can use the .NET edition at the same exact Godot version while keeping project code and plugins GDScript-only. C# would require an explicit team decision and the appropriate editor/SDK setup.

The user confirmed the team uses Godot 4.7.2. Keep editor and export-template versions aligned; matching export templates have not been installed. Godot is portable; no installer or PATH change was made. No external server, database, or Python environment is required for game runtime.

Official downloads: https://godotengine.org/download/windows/

## Current target and renderer

The original repository README identified offline Windows as primary; final demo packaging is now recorded as pending. Existing project.godot uses Forward Plus and the Windows d3d12 driver. Those files are preserved during documentation integration.

The signed v1.0-agreed selects Compatibility/GDScript support while final packaging can wait until the first playable slice. The agreement reports gl_compatibility on master, while inspected local main still uses Forward Plus/d3d12. SE owns branch/settings synchronization and an early Web export check; this documentation task preserves engine configuration. If browser delivery is chosen, use the documented Web-compatible rendering/export setup and test a served build. If Windows remains primary, verify the actual Windows export. Neither export has been tested here.

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
- Graphical renderer: not checked. Export templates: not installed. Gameplay tests and exports: not run.

From this repository root, using the current sibling tool layout:

```powershell
& '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe' --version
```

On another machine, use that machine's editor location. Do not place editor executables, archives, or machine-specific paths in gameplay code.

## Remaining preparation

1. Complete: the user confirmed Codex and Antigravity assistant checks are successful.
2. Godot 4.7.2 and the 09:00 kickoff are user-confirmed. The user has now authorized local K01-K04 work; final delivery and early browser-option constraints still need team review.
3. Open the existing project in Godot and check rendering; do not claim a version check proves graphical compatibility.
4. Install the export templates matching Godot 4.7.2; installation remains pending.
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

Current Godot 4.7.2 results: field/catalog regression suite 294 passed; totals/readiness suite 671 passed; saved-fixture suite 470 passed; 1435 total, 0 failed, all three exit code 0. This tests full KE1 readiness with native HPC orbit data. It does not test HPC runtime simulation, screens or exports. See [k07-k08-progress.md](k07-k08-progress.md) for coverage/provenance and [k09-k10-progress.md](k09-k10-progress.md) for saved-case verification.

## Version control

Preserve the repository's existing editor and Git settings. The additional preparation ignore entries cover generated exports, downloaded tools, temporary work, and private local environment files. Documentation integration is a local working-tree change; no commit or push is performed automatically.
