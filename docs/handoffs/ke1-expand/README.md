# KE1 expansion handoff for HPC and SE

Branch: **ke1-expand**. Prepared 15 November 2026. Base main: `dce75db845f6c494b8c25c9028dd9c0648aabd91`.

**K20 is agreed. K21 definitions/loaders are complete. K22's public validator is implemented; native launch integration remains unfinished.** There is no new K20 confirmation request.

Start with your owner handoff: [HPC](hpc.md) or [SE](se.md). Then read the [agreed v2 contract](../../contracts/expansion-v2.md), [public API and implementation evidence](../../ke1-expansion/k21-k22-live-integration.md), and [49-program test summary](../../ke1-expansion/evidence/k21-k22-live/checks.json).

Current data are [mission_presets_v2.json](../../../data/mission_presets_v2.json) and [mission_capabilities_v2.json](../../../data/mission_capabilities_v2.json). Markers: `expansion-goals-v2-agreed-1`, `five-presets-agreed-1`, `v2-capabilities-agreed-1`. Older candidate/draft files are retained because historical diagnostics/regression checks use them. They are not the live integration input.

Included: KE1 production code, required earlier review helpers/fixtures, all five agreed presets, explicit capability context, tests, K20/K22/K23/K26/K27 resources and current evidence. Personal AGENTS.md/GEMINI.md/tasks.md, local exports, export preset edits, caches, downloaded tools and credentials are excluded. No HPC simulator, SE UI/controller or KE2 evaluator code is replaced by this branch.

All 49 active programs passed on the prepared source, including 97 new preset/context checks and 373 new live-v2 checks. All five v2 designs pass KE1 physical readiness. Current native launch rejects all five without creating state. This documents an integration gap, not successful expanded gameplay or public-browser acceptance.

Review and merge `origin/ke1-expand` into your own integration branch. Preserve your current owner changes and combine test-runner entries if both branches added tests. Do not deploy/merge into main just because readiness is green. No message to teammates or remote push is performed by preparing this handoff; the user will push the branch.
