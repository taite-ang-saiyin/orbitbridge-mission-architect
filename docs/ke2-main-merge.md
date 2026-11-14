# KE2 merge into main

Base main: `ec4bee64d9b06db5e57223be93c177d141fddeca`.
Merged branch: `memberKE2@dbf65adc5c23793dcdf4acb31bc18382cd3ca936`.

The merge brings in KE2's source ledger, handoff packets, documentation, and historical verification material. Main already contains this revision's evaluator, feedback implementation, and evaluator tests; those files are unchanged. This merge does not add Survey scoring or controlled A/B comparison.

## Conflict resolution

- Preserve main's `.gitignore`, including generated-build exclusions and personal assistant/task-file exclusions.
- Preserve main's `tests/test_mission_evaluator.gd.uid` to retain the established Godot script identity.
- Preserve the current signed `docs/team-agreement.md`, implementation contracts, native orbit data, active screens, runtime code, and export presets.

The copies of earlier agreements and KE3 previews arriving from KE2 remain historical evidence. They do not replace the signed agreement, designate a release, or introduce the KE3 branch's Operations/Retry route.

Add `.gdignore` to `data/ke3-results-verification/` so Godot does not import/export archived preview scenes as production resources. Before this exclusion, export tried to load missing `res://ke3/` and `res://preview/` scripts from those old scenes. The evidence files remain in Git. The rebuilt export has no error diagnostics.

## Verification

- All 25 active check programs passed: 1785 counted assertions, plus the uncounted smoke programs. KE2 retains its five declared pending checks; they are not counted as passes.
- Windows release: 44 scenario assertions plus 22 packaging assertions passed, both headlessly and with graphics (66/0 in each mode).
- A separate five-check compatibility probe retains manual actions, unfinished-run editing/New Mission/Results guards, and the Windows verification hook.
- Active calculation/UI code, project settings, signed agreement, original orbit catalog, and export presets match the base main byte-for-byte in Git. Local builds and test logs are excluded from this commit.

Executable hash and recorded checks: [verification record](verification/ke2-main-merge-checks.json).

KE3 is not merged by this change. Its branch still needs manual integration with main's existing controls and protections. Browser behavior, another Windows computer, and teammate review of this exact merged build are not established by these automated checks.
