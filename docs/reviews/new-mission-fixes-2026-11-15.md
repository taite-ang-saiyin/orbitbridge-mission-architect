# Communication and Weather fixes — 15 November 2026

## What changed

- Both missions now produce a real goal report and score from their frozen v2 configuration and matching native flight evidence. Imaging v1 keeps its existing evaluator.
- The agreed KE2 rule gives half the score to the capped contact/orbit ratio and half to the capped returned-MB ratio, then rounds once, with .5 rounded up. Success requires both raw goals. Capture quota is not a third success goal. Stopped flights keep their measurements and have no score.
- Communication counts positive accepted transmission steps. Weather counts qualifying observations on different zero-based orbits. Neither rule was changed to make a test pass.
- Weather's automatic flight policy now saves its later captures for later orbits. Explicit action plans and manual actions still run as requested, so observing twice in one orbit can still miss the goal.
- Browser and Windows exports retain script source text. The existing evidence checker hashes these files; compiled-only exports previously lost those inputs and could not verify goals or enable Save A. Verification remains enabled. Source text is included in the downloadable game package.
- Results, Creator and readiness explain the supported goals. A stopped flight says “Mission stopped early”. Goal bars use the bound report's real ratios.
- Saved v2 executions carry their report revision in record metadata and survive a JSON round trip. Existing v1 report fields and record preimages remain unchanged. A helper-code hash is also retained for new-goal runs.

## Ownership and compatibility

This is a local implementation of the settled [expansion rules](../contracts/expansion-v2.md) under the user's explicit request to fix the E2E findings. It is not a new team approval. KE2's owner reply supplies the equal-weight, capped-ratio scoring rule; HPC's agreed rules supply contact, orbit and evidence meanings.

Production entry point remains `MissionEvaluator.evaluate_mission(config, final_state, events)`. Only config-v2 Communication and Weather delegate to `mission_goal_evaluator.gd`. Their reports use schema 2, retain the 17 legacy fields, and add `objective` plus two `goal_progress` rows. State/event envelopes remain v1 and retain the whole v2 config. The existing report-revision identifier is preserved for compatibility.

Survey scoring remains outside this fix. Historical files and incomplete evidence do not gain a score through a fallback. No new scientific scoring claims or fabricated causal/source evidence are added.

## Verification

- New evaluator suite: 134 checks passed, including partial/failed outcomes, .5 rounding, capture quota, stopped runs, forged/missing evidence and JSON reload.
- New real-controller E2E suite: 132 checks passed across both missions, including launch gates, Home/resume, goals, Save A, Not now, B editing/cancel, completed B comparison, retries and stopped runs.
- All five mission comparison flows passed. Legacy evaluation and native expansion/validation suites passed.
- Browser testing uses a real local Web export in headless Edge. Both starter flights show 100/100, 2/2 goals and 24/12 MB. Communication Save A and changed-radio B comparison work with readable component names and dash placeholders.
- Full source-suite results and screenshots are retained in the local `exports/new-mission-fixes` evidence folder. Older removed-preview tests and current font/layout assertions are recorded separately; they must not be treated as a clean full-suite result.

No Git push or live deployment is part of this change. The local Web folder must be deployed to replace a previously published build. Browser refresh still clears the session comparison, as the screen states.

## Reproduce

Run Godot 4.7.2 headlessly with `--path` set to this project and `--script` set to `res://tests/test_mission_goals_v2.gd` or `res://tests/integration/test_new_missions_e2e.gd`. Supply a writable output folder after `--` for the E2E report. The maintained `tests/run_all_checks.ps1` runner includes both suites.

Export the Web preset with an explicit output path inside this checkout's `OrbitBridge-Web` folder. Serve that folder through a local HTTP server; opening the HTML file directly is insufficient. Do not accidentally use another checkout's export path from a machine-specific preset.
