# A/B comparison flow and responsive Results

Implemented 15 November 2026. No simulation, catalog, readiness, mission-goal or score formula changes.

## Behavior

Save A and create B → Builder → Readiness → Flight → automatic A/B comparison. The saved A execution stays immutable. Completing B selects the comparison tab and displays paired measurements and B-minus-A values. Historical result selection uses the full archived execution, preserving comparison lineage, scenario/version metadata and original key inputs rather than reconstructing a shortened trace.

Explicit Open A/Open B actions show the standalone Overview and do not loop back to comparison. The Design comparison action reopens the pair; Try another B edits another independent trial against saved A. Replace/Clear A remain explicit confirmation actions under Saved A. Flight numbering remains independent from A/B role labels.

The default provider compares records only after existing completed-run, mission/goal/orbit/profile/launcher/catalog/version/start-condition and execution-binding guards. Scores are reused from actual published reports. Survey, Communication and Weather compare verified native measurements with no invented score or outcome. Aborted or invalid records remain ineligible. Survey complete delivery and partial returned MB stay distinct; a missing whole delivery map remains unavailable.

Resource extrema use recorded initial and step states, including terminal; these are discrete samples, not continuous-time estimates. Interpretations describe measured differences and do not claim single-component causality.

## UI

Result body/table/action text stays at readable sizes instead of shrinking with window height. Buttons have meaningful minimum widths and flow to new rows. The comparison table becomes stacked measurement cards below 640px available content width. Comparison mode hides B's standalone hero so the actual pair is prominent. Each full Debrief remains available. Technical flight IDs are kept in tooltips; visible headings distinguish Design A/B from Flight numbers. Existing Myanmar display scope and raw data protection remain intact.

## Verification

- End-to-end tests through all five actual mission cards: saved A → component-edited B → readiness → flight → automatic bound comparison; numeric deltas and score availability verified; immutable A and explicit history selection verified.
- New comparison tests pass layout checks at 1440×900, 1024×768 and 900×680. Recorded OpenGL windowed runs passed all four objective classes; final rendered captures were visually inspected at 1440×900 and 900×680. Final five-card suite also passes headlessly.
- Player UI: 174 passed. Debrief summary: 57 passed. Design Lab hooks: 77 passed. Localization: 38 passed. Owner guards: 38 passed. Saved records: 19 passed. Native expanded contract tests passed for both new missions. Navigation/resume suite passed for Imaging/Communication/Weather.
- Added comparison_flow_smoke.gd to the maintained runner. Missing-provider and foreign-pair rejection controls remain covered. Whitespace checks pass.
- Browser export not tested. Existing uncommitted shared-header hamburger changes were preserved.
