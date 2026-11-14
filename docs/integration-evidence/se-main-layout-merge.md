# SE layout and model integration

The SE redesign is combined with main's current mission execution and Results behavior. This merge uses main `4c65496661a491a2641005906f490d894f683f01` and SE `f749b92365c2c7d16043a41a2b22162a03ed5dd5` as its parents.

## Resulting behavior

- SE's Home, Creator, Builder, Earth framing, compact antenna, ACRIMSAT hull, mission acknowledgement and readiness-details changes are included.
- Main's current Operations player, manual actions, launch-time validation, frozen execution/report binding and latest Results presentation are retained.
- Retry same mission starts immediately with the original configuration and a fresh run ID. Modify design opens an editable copy; Cancel restores the original session and report.
- Player navigation requires an acknowledgement of the current mission requirements before entering the engineering flow. Changed requirements invalidate the acknowledgement. Live-run edit guards apply before review routing.
- Invalid launch requests stay blocked on Readiness and are checked again against current inputs before any run is created. Mission acknowledgement does not replace engineering validation.
- The obsolete shared step navigation is removed from view; sidebar text remains readable in the browser without relying on unsupported symbol glyphs.

The eleven original conflicts were resolved by combining the SE layout/review flow with main's execution behavior. Existing fixture tests now acknowledge their intended mission inputs; Creator route checks exercise the actual acknowledgement overlay. Existing simulation, scoring and immutable-report assertions remain in place.

## Validation

Godot 4.7.2 Standard, Compatibility rendering:

- All 43 active programs in `tests/run_all_checks.ps1` passed, including the five new SE review/model checks.
- The expanded integration check passed 25 assertions, including SE navigation attempts while a mission is operating.
- The K14 game acceptance flow passed 48 checks with zero failures.
- A release Web export loaded in Chrome using WebGL 2.0. The exported game passed the same 48 acceptance checks with zero failures and no JavaScript page errors.
- Browser checks cover 1440 x 900 and 1024 x 768 rendering. Review-overlay geometry is tested at 1024 x 768, 1280 x 720 and 1920 x 1080 by the SE review test.

Reproduce native checks from the project root:

```powershell
.\tests\run_all_checks.ps1 -GodotExe 'C:\Tools\Godot\Godot.exe'
```

The optional `--verify-demo` application argument runs the acceptance flow. Windows packaging checks run only in an exported Windows app, so the same acceptance flow can also run in a Web export. Verification setup must perform acknowledgement outside `assert`, because release builds omit assertions.

## Limits

This is the SE integration, not implementation of the separately proposed five-mission/A-B expansion. Existing Survey scoring limitations and the evaluator's five previously pending cases remain explicitly reported. Browser testing used a local server; the public Netlify deployment has not been checked by this merge task.

Generated exports, temporary conflict previews, browser captures and personal planning files are excluded from this commit. The user's local Web export-path setting is preserved separately.
