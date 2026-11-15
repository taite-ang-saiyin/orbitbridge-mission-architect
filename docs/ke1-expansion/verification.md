# Preparation verification and preservation

## Main and workspace

- Base: main `dce75db845f6c494b8c25c9028dd9c0648aabd91`, fetched and checked before this preparation.
- Workspace: `Desktop/OrbitBridge/OrbitBridge-KE1-Expanded`.
- Local branch: `ke1-expanded-scope-preparation`. It starts from main and contains no new commit from this preparation. Do not push the branch with personal files without an explicit user request.
- The original project remains on deploy with its unfinished export changes. Existing ke1 and ke1-sunday branches are retained.
- Only planning documents, reference copies, example JSON and the documentation example checker are prepared. No game script, live catalog, scene, signed agreement, existing contract or export preset is changed.

## Exact backup

Before editing, 87 original files were saved from the current project's planning files/docs and the older OrbitBridge-KE1 planning folder. The full archive is in the sibling `KE1-Planning-Backups/ke1-planning-backup-20261114.zip`; a working copy also remains with this task's local preparation records.

The archive contains the original AGENTS.md, tasks.md, GEMINI.md, README.md, supporting docs and source references from both folders. [The manifest](preservation-manifest.json) records each entry's size and SHA256. The original folders are not replaced or cleaned. Completed K01-K14 history is retained in the extended task list; K15 is corrected to complete using the actual published merge evidence. Historical rows remain labelled as historical.

## Checks actually executed in this preparation

Godot 4.7.2 ran a resource audit against an unchanged copy of the exact main source. **23 checks passed; 0 failed.** The audit verifies seven current v1 config examples (five stock/engine-training inputs plus the A/B pair), input preservation, current preset defaults, one-field A/B difference and fixed-plan diagnostics. JSON number representation was normalized when comparing loaded examples with constructed dictionaries; no goal/default values were changed to make a check pass.

Actual audit: [example-audit.json](evidence/example-audit.json). The checker is [tools/audit_examples.gd](tools/audit_examples.gd). From this project root after Godot has imported the project:

```powershell
$godotExe = '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe'
& $godotExe --headless --path . --script docs/ke1-expansion/tools/audit_examples.gd -- 'res://docs/ke1-expansion/examples' (Join-Path $env:TEMP 'orbitbridge-ke1-example-audit.json')
```

| Observed input or plan | Actual result | What it establishes |
| --- | --- | --- |
| Three existing preset configs | Match current defaults: 5 captures, 60 MB, 6 orbits, 100-credit budget, existing target/orbit mappings | Preserves current preset inputs; not a claim of new scoring |
| Five stock physical configs | All pass current readiness | IDs, setup fields and physical rules are valid using extended catalogs |
| Design A: basic radio | 1060 g, 82 credits, 48 MB/hour radio | Current catalog metrics, not real spacecraft specifications |
| Design B: fast radio | 1120 g, 89 credits, 120 MB/hour radio | One radio change; both setups pass; no claim B is universally better |
| Communication fixed plan | Positive downlinks at pre-action steps 7, 10, 17 and 20; 24 MB returned | Proposed 2-contact/12-MB target is attainable in the current training engine |
| Weather revisit plan | Captures at steps 1 and 11, orbit indices 0 and 1; 15.4667 MB returned | Proposed 2-visit/12-MB target is attainable with deliberate timing |
| Same-orbit Weather plan | Captures at steps 1 and 6; one distinct orbit | A count of two captures alone is insufficient |
| Current Observe First on Weather training input | Both captures in orbit 0; 24 MB returned | Existing policy can meet aggregate imaging goals while missing the proposed revisit goal |

At Communication step 27 no data remains; the audit uses Power-save and does not add a positive-contact count. Action-plan indices are zero-based pre-action indices with 10 steps per orbit. HPC must confirm the production convention and policy.

## What remains unverified or pending

The official new mission objectives, Survey evaluator, versioned goal propagation, Design Lab UI/storage/matching, expanded browser journey and public Netlify deployment are not implemented or validated here. Counts above are engine diagnostics using supported v1 inputs, not official new-goal scores.

The preceding main merge's 43 active programs and 48 browser acceptance checks are inherited evidence in docs/integration-evidence/se-main-layout-merge.md. They were not rerun merely for this documentation update and do not prove expanded-feature acceptance.

Before handoff, the preparation also checks JSON parsing, links, unchanged original-file hashes and deploy status, backup integrity, preserved signed-agreement/contract bytes, and that main's tracked game files remain unchanged. These are document/preservation checks, separate from gameplay tests.
