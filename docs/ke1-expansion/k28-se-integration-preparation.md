# K28 latest SE verification

Status: current published patch tested; **two implementation issues remain**, so K28 integrated acceptance stays open. All non-HPC agreement items are settled; these failures are not requests to repeat agreement.

Tested SE: `0d9e275fc270630c74324f29c11281f9883909a2`. Main remains `dce75db845f6c494b8c25c9028dd9c0648aabd91`. SE advanced from the earlier tested `9c58aad` through the portable-record update `5abc659` and Myanmar translation update `0d9e275`. Only the isolated checkout was tested. No SE production source was edited or merged.

| Test | Executed result | Meaning |
| --- | --- | --- |
| `tests/se_design_lab_hooks.gd` | 76 passed / 0 failed | Save A, Not now, Continue B, Cancel, rerun B, immutable A, archived evidence and supplied v2 propagation/review invalidation work in this tested local patch |
| `tests/se_execution_record.gd` | 19 passed / 0 failed | Current saved-record encode/reload/digest/tamper fixtures pass; original historical-eight-case option was not rerun and its packet is not requested again |
| `tests/integration/test_se_owner_contract_preparation.gd` | 31 passed / 7 failed | Six failed expectations for launch/comparison guards across launcher-only, profile-only and combined changes; one failed Creator goal/lineage consistency expectation |

## SE fix handoff

1. **Fixed B launch setup:** align `launch_b` and `comparison_inputs` in `scripts/integration/design_lab.gd` with the B UI's fixed launcher/profile. Current checks accept physically valid changed launch setup at both boundaries. The test creates an independently completed changed B so the comparison boundary is tested even after launch is fixed. Saved A remains unchanged. Keep agreed mission/orbit restrictions and intended part edits.
2. **Atomic goal/identity change:** in `scripts/screens/MissionCreator.gd`, switching a supplied-v2 Imaging draft to Survey changes the objective but retains `preset_id=estuary_watch` and `goal.kind=imaging`. Update the matching preset/goal together or refuse that transition. Preserve review invalidation and start a new comparison when requirements change. The test exercises the actual callback using a synthetic supplied-v2 state; it does not claim a new mission currently launches.

The fixes are not present in this published SE revision. The new test continues to expose failures rather than suppress them. It is excluded from main's maintained runner because main lacks the unmerged Design Lab patch. After SE applies its fixes, copy this test into that checkout and run:

```powershell
& $GodotExe --headless --path . --script res://tests/se_design_lab_hooks.gd
& $GodotExe --headless --path . --script res://tests/se_execution_record.gd
& $GodotExe --headless --path . --script res://tests/integration/test_se_owner_contract_preparation.gd -- ./exports/se-owner-check
```

Inspect logs/counts/JSON rather than relying only on the Windows executable's exit code. [Summary](evidence/se-latest-check/checks.json), [new test evidence](evidence/se-latest-check/se-owner-contract-check.json), [saved-A log](evidence/se-latest-check/se-hooks.log), [saved-record log](evidence/se-latest-check/se-record.log), [failure log](evidence/se-latest-check/se-contract.log).

The existing Design Lab suite uses a comparison-provider stand-in. These passes do not establish production expanded evaluation/comparison, general persistence, final report-v2 presentation or public browser acceptance. HPC confirmation and coordinated live integration remain necessary before new mission launches.
