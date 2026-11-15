# K24 current Communication checks

Revision: **k24-agreed-communication-1**, 15 November 2026. K20 rules are agreed; this work uses expansion-goals-v2-agreed-1, five-presets-agreed-1 and Communication preset revision 2. Baseline is ke1-expand 3ec299d. No production simulator/evaluator, part values, defaults or launch gates changed.

## Native v2 status versus explicit physical trials

The exact full v2 configs pass the current public validator, including explicit capabilities and all eight physical gates. Actual native v2 initialization still returns UNSUPPORTED_SCHEMA_VERSION without a state for every case. Therefore there is **no production Communication execution, success/partial/failure classification or official score** in these results.

Separately, the diagnostic explicitly creates labelled **test-only supported v1 Imaging physical inputs**. These exercise real native hardware, action windows, event deltas and resource clamps. The original agreed v2 config and native rejection remain next to each physical trace. This is not a fallback in the game, and it must never be used to pretend a Communication launch succeeded.

## Fresh measured cases

All rows retain a capture quota of two and count requirement of two. Only the labelled edited-data case changes the MB target from 12 to 25. Only the labelled basic-radio player design changes the selected radio. Step indices are zero-based pre-action indices from the native event.

| Case | Actual captures / quota | Positive transmission steps | Returned data | Offline count comparison | Offline MB comparison |
| --- | --- | --- | --- | --- | --- |
| Fast-radio starter | 2 / 2 | 7, 10 | 24 MB | Met | Met |
| Same config, only one capture | 1 / 2 | 7 | 12 MB | Missed | Met |
| Edited data target: 25 MB | 2 / 2 | 7, 10 | 24 MB | Met | Missed |
| Captures without transmission | 2 / 2 | None | 0 MB | Missed | Missed |
| Basic-radio player design, one capture | 1 / 2 | 7, 10 | 12 MB | Met | Met |

The first two cases use **the identical full agreed v2 config**. Only requested actions change: capture at 1/6 versus only 1, then request transmissions at 7/10. The second case returns 12 MB but has only one positive step; its step-10 request is rejected with NO_DATA. This isolates count shortfall without changing hardware, quota or requirements.

The 25-MB case has two positive steps but only 24 MB of payload, isolating data shortfall. The no-transmission case captures two but makes zero scoring progress. The basic-radio case captures only one of its permitted two images, splits that 12-MB image across steps 7/10 and meets both agreed comparisons. This demonstrates that reaching the capture quota is not an extra Communication success target. It also shows why fast radio is not universally better for a transmission-step objective.

These labels are offline requirement comparisons, not KE2 production outcome/score output. A data target can be physically ready yet exceed supplied payload; readiness does not promise mission success. No stock values were edited by the audit.

## Evidence/provenance and controls

Every trial records exact v2 input/readiness/native rejection, explicit v1 physical input, clean native initial/final states, requested plan, blocked attempts and initial plus every accepted post-clamp resource sample including terminal. Empty-buffer and off-window requests add no transmission progress and do not advance time/resources. The engine leaves caller inputs unchanged.

The deliberately local diagnostic counts only accepted Transmit events with positive delta_returned_data_mb, deduplicating repeated event/step evidence. Its controls show exact duplicates count once and zero-data events add no count. Foreign run IDs, conflicting event IDs, fractional steps, negative data or missing event arrays produce unavailable diagnostic evidence, not zero progress. This helper lives inside the test; it is not a production evaluator or a replacement for KE2's complete event validation.

**711 checks passed, zero failed.** [Raw evidence](evidence/k23-k24-current/communication-current-check.json), [log](evidence/k23-k24-current/test_k24_communication_current.log), [source/verification summary](evidence/k23-k24-current/checks.json).

```powershell
& $GodotExe --headless --path . --script res://tests/integration/test_k24_communication_current.gd -- ./exports/k24-current
```

K24 remains open for typed-v2 native evidence and official evaluation of passing/count-shortfall/data-shortfall cases. HPC/SE native/config integration and KE2 production publication remain implementation dependencies, not missing K20 agreement. When native v2 support lands, replace this audit's expected native-rejection assertions with positive full-snapshot/native-outcome checks while preserving the explicit old v1 evidence labels and all negative controls. Do not silently rewrite the original v2 config.


A separate boot-splash settings/image edit appeared in the shared folder during this task. It was copied only into the isolated audit checkout and both audits were rerun successfully. That unrelated original edit is preserved and is not included in this task's writes; no visual splash acceptance is claimed.
