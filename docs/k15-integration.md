# K15 stable integration

Prepared 14 November 2026. This integrates the stable KE1 workflow with current main, preserves later owner fixes, and records Sunday's known gaps in [sunday-blockers.md](sunday-blockers.md).

## Inputs and conflict resolution

| Input | Revision | Resolution |
| --- | --- | --- |
| Current main | d592f52c02a978257bf9bb1f8245ea8e4368b771 | Base; preserved latest HPC engine, legacy adapter, predictions and owner tests/docs |
| Stable KE1 | f4aeb0c2c63a8b415b8acfe45c56f84a75369b34 | Real Builder/readiness, validated launch snapshots, live Operations/Results, source catalogs and verification |
| Current KE2 runtime/tests | 79e249b09b4226916e013ad5f745abccd0a3c1c0 | Preserved native-state evaluation helper and terminal_reason feedback mapping |

The merge was prepared in a separate checkout. The original ke1 working directory, its head and unfinished Web export-path edit are not reset, stashed or overwritten. This is a squash integration onto the latest main base, so personal-file history from ke1 is not imported into main.

Conflicts in the controller/screens use the tested real KE1 flow. Conflicts in the HPC engine/test/handoff use newer main. README retains main's English structure with updated real-flow status and commands. Ignore rules combine macOS metadata, generated builds and local tooling. AGENTS.md, GEMINI.md and tasks.md are deliberately excluded from the shared result per the user's preference; these are not runtime dependencies.

Seven old scripts that asserted fixed mock results, unsupported multiple targets and development-only body selections are preserved in tests/archive/mock_prototype/. Their assumptions no longer describe the active app. Replacement real-flow suites remain active; Home/settings, responsive layout and isolated 3D tests are retained. The layout check supports the agreed single objective while retaining clipping, control-size and model-framing assertions.

## Verification

Godot 4.7.2.stable.official.ed1daf0bf:

| Active suite | Counted passes | Failures |
| --- | ---: | ---: |
| KE1 field/catalog | 294 | 0 |
| KE1 readiness | 671 | 0 |
| KE1 saved examples | 470 | 0 |
| Current HPC owner tests | 48 | 0 |
| Current KE2 owner tests | 205 | 0 |
| Real mission flow | 32 | 0 |
| Screen flow | 30 | 0 |
| K14 acceptance | 40 | 0 |
| Counted total | **1790** | **0** |

The legacy simulator, Home/settings, responsive-layout and 3D-preview programs also exit 0 without assertion counts. All 12 active programs passed through tests/run_all_checks.ps1. The unchanged KE2 owner suite still prints five original pending declarations; optional comparison remains open, while real integration is covered by the active flow/acceptance suites.

Rebuilt the merged Windows app separately from the user-approved earlier demo. It passed 40 scenario and 21 package assertions, exit 0, in headless and OpenGL graphics modes. Actual starter result remains 4 captures, 48 MB returned, success / 100. See [current structured evidence](verification/k15-merge-checks.json). Older K11/K13a manifests are historical build snapshots, not hashes for this merge.

Reproduce from the project root with an explicit local Godot path:

```powershell
.\tests\run_all_checks.ps1 -GodotExe 'C:\Tools\Godot\Godot.exe'
.\scripts\build_windows.ps1 -GodotExe 'C:\Tools\Godot\Godot.exe' -Verify
```

The output logs and executable are generated under ignored exports/. Default source APIs and units remain unchanged; the current owner additions are retained rather than replaced with the older tested copies. There are no known runtime blockers to the stable Windows flow. K16 final player-journey verification is next; publication state is reported separately from the code/test evidence.
