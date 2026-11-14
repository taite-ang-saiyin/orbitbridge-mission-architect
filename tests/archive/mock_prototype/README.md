# Historical mock-prototype checks

These seven scripts describe the old UI contract: fixed mock results, 136 kg buses,
multiple unsupported targets, development-only body IDs and reference playback.
They are preserved as history, not executable acceptance checks for the integrated app.
They were moved explicitly during K15 rather than changing real readiness to satisfy mock assertions.

The later SE merge adds updated versions of these seven checks at the tests root for the real catalog and playback flow. Those active versions are included in the runner; this archive retains the historical versions and is excluded from Godot imports.

Use tests/integration/test_mission_flow.gd, tests/integration/test_screen_flow.gd,
tests/acceptance/test_k14_acceptance.gd and the three tests/validation suites for
current real calculations, part changes, launch gates, Operations, Results and retry.
Home/settings, responsive-layout and isolated 3D preview smoke checks remain active.
The suite entry point is tests/run_all_checks.ps1. Do not recursively execute this archive.
