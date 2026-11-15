# K20 review additions: summary and handoff

Review revision `k20-review-additions-1`, 15 November 2026, Asia/Rangoon; base main dce75db. This supplements config-contract draft 2 and candidate registry 2 without changing their IDs, values or acceptance status. The earlier fast-radio ZIP is a preserved snapshot; the new additions packet is the current review material.

## Added for review

- [Exact validation rules](k20-validation-review.md): required/unknown fields, numeric limits, allowed objective/goal pairs, count relations, proposed issue codes and strict rejection behavior.
- [Selectable parts and capabilities](k20-parts-review.md): exact slot IDs, existing physical values, current actual objective registration and proposed training support. Selectable parts must still pass readiness.
- [Full example configs](examples/k20-review/README.md): seven candidate-valid examples and 33 invalid/context examples, with expected proposed code/path pairs. Candidate-valid does not mean current game acceptance.
- [Open gameplay examples](examples/k20-review/open-decision-examples.json): Weather's two interpretations and a synthetic two-transmission-steps-in-one-window example. Neither owner decision is settled.

## Checks actually run

An offline document-fixture audit checked all **40** examples against the stated proposal expectations. A separate Godot 4.7.2 check passed **110 assertions**, using current runtime-extended catalogs and unchanged validator/engine source. It checked seven physical surrogate setups, two existing readiness failures and two real Weather runs. Actual v2 inputs remain rejected. The advanced valid example measures 1300 g / 104 credits; Communication remains 1120 g / 89 credits.

| Real Weather run | Captures / transmissions | Actual returned images/data | Unresolved interpretation |
| --- | --- | --- | --- |
| Second visit unreturned | Observe 1/11; transmit 7/10 | One complete image returned, 12 MB; second full 12-MB image remains onboard | Capture-plus-pooled-MB interpretation meets thresholds; complete-delivery-per-visit alternative misses a visit |
| Complete return | Observe 1/11; transmit 7/10/17/20 | Both images fully returned, 24 MB | Meets either proposed interpretation |

These are zero-based pre-action schedules with authored high_inc/equator windows and current basic-radio Weather hardware. The production packet state does not itself supply an agreed capture-orbit association for a new Weather report. HPC/KE2 must agree that evidence path before a delivered-visit rule is implemented. No official new-goal score is supplied.

[Check record](evidence/k20-review-additions/checks.json), [proposal expectations audit](evidence/k20-review-additions/proposal-audit.json), [native physical checks and traces](evidence/k20-review-additions/physical-qa.json), [native audit](tools/check_k20_review_examples.gd). Original fast-radio/catalog tests and their evidence remain historical and unchanged; this task does not claim they were rerun, a full regression suite passed, or a browser/public release was tested.

Repeat the physical audit from the project root after Godot import:

```powershell
$godotExe = '..\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe'
$exampleFolder = Join-Path (Get-Location) 'docs\ke1-expansion\examples\k20-review'
$auditFile = Join-Path $env:TEMP 'orbitbridge-k20-review-physical.json'
& $godotExe --headless --path . --script docs/ke1-expansion/tools/check_k20_review_examples.gd -- $exampleFolder $auditFile
```

## Still pending

HPC, KE2 and SE must settle W1 (Weather delivery), C1 (transmission steps versus contact windows), exact bounds and capability registration. HPC owns event indexing/evidence and policy confirmation; KE2 owns scores/partial results; envelope versions remain separate owner decisions. Custom mission identity/edit behavior and SE/KE3 integration still need coordination. Prior direction review is not ratification.

K20 remains unchecked. The game validator, runtime catalogs, candidate registry, simulator, scoring, UI, exports and signed shared agreements were not changed. Personal AGENTS.md, GEMINI.md and tasks.md remain local and preserved. No commit, push, deployment or message to teammates was performed. The review ZIP excludes those personal files.
