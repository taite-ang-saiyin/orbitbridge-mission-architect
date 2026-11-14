# Readable Operations and mission results

Updated 14 November 2026 (Asia/Rangoon), starting from main commit `2358e6818f2ad9e643764a2a98e6d88ef3341255`.

Operations now puts the two mission goals first, followed by one Earth view and one action area. The three main actions explain themselves: take a photo, send data to Earth, or save power/wait. Contextual guidance explains observation/contact windows. Main text is 16–18 px and goal values are 28 px. The redundant six-step navigation row is hidden on this screen. Speed, finish/stop, seeking and expanded view remain under More flight controls; the mission log, per-target details and ground track remain under Flight details.

Results now has a single readable column: an explicit outcome, both goals, what happened, a suggested next experiment, and the existing Modify design / Retry same mission / New Mission actions. Previous flights, evidence/resources and sources are expandable. Sources have keyboard-accessible HTTPS links. Developer ownership labels, implementation commentary and long internal run identifiers no longer dominate the player screens. Run IDs remain available in metadata/tooltips. The shared shell, Readiness caption and Mission Control availability wording also use player-facing labels.

Numbers are formatted to at most two decimal places for player display; small nonzero values below the display precision say `< 0.01`. Original simulation values, reports, scores, ratios, evidence IDs, credit scopes and snapshots remain unchanged. Zero scores remain zero; aborted null scores say Not scored; unsupported Survey scoring stays explicitly unavailable. The existing validator, simulation and evaluator algorithms and project/export configuration are unchanged.

Presentation corrections included:

- Earth framing retains the vertical field of view, matching its existing height-based distance calculation; the entire globe/orbit stays inside wide panels.
- Keyboard focus waits for layout/scroll bounds, including when guidance changes while an action already owns focus.
- Disabled Send data clicks dispatch no action; enabled Space activation dispatches once.
- Flight-data rows rebuild after a manual action. Native blocked transmissions are labelled Data transfer blocked, not Data sent, and appear in the warning filter. Rejected requests retain their original step/resources.

## Verification

Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility renderer. The final full runner exits **0**: **all 37 active check programs pass**. The evaluator suite still records its existing **207 passing / 5 pending** cases; no pending team feature is claimed complete.

```powershell
& .\tests\run_all_checks.ps1 -GodotExe 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe'
```

The new `tests/player_ui_check.gd` passes **134 checks** headless and windowed. It checks 1440×900, 1280×720, 1024×768 and 900×680, font sizes, horizontal containment, globe framing, progressive disclosure, readable labels, disabled/accepted/blocked actions, native data-table updates, source links, snapshot preservation, null/zero scores, and a real partial-result case. Windowed captures use the actual game scene.

```text
godot --path . --rendering-method gl_compatibility --script res://tests/player_ui_check.gd -- res://exports/player-ui
```

Existing UI assertions were updated to exercise the expanded sections before measuring their contents, use the new Stop mission early label, and distinguish player-readable attribution from the unchanged detailed metadata. They continue to check native results, immutable reports, missing evidence, aborts, Retry and source binding.

Local execution records are under `C:\Workspace\OrbitBridge\Event\ke3_minimal_ui`: `all-checks-final.log`, `windowed-release.log`, `native-final.log`, earlier failure/retest logs, and `release-screenshots/`. Earlier failures were retained, including the new small-window focus reproduction; the original containment assertion remains active and passes after correction. Standard per-program logs are under the ignored `exports/check-logs/` directory.

**Web export verification is blocked on this machine:** the existing Web preset requires `web_nothreads_debug.zip` and `web_nothreads_release.zip` under `%APPDATA%\Godot\export_templates\4.7.2.stable`, and neither is installed. The attempted `--headless --export-release Web exports/web-minimal/index.html` exits 1 for that dependency. No software was installed and no project/export preset was changed. No browser/deployed-site verification is claimed; a successful repository push alone is not proof of a Netlify deployment.
