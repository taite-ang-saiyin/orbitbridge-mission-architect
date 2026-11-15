# K23 current five-mission readiness report

Report revision: **k23-live-readiness-2**, 15 November 2026, Asia/Rangoon. Tested working source based on `ke1-expand` commit `3ec299d20a9b244b56888fc99f89eec4b1bea17f`; GitHub main remains `dce75db845f6c494b8c25c9028dd9c0648aabd91`. **K20 is agreed.** This is fresh execution against the agreed public validator, replacing this document's older draft-only readiness summary. Historical evidence/ZIPs remain unchanged.

## Agreed v2 physical readiness and actual launch gate

| Mission | Public KE1 gates | Mass | Credits, including launch | Actual native v2 initialization |
| --- | --- | --- | --- | --- |
| Estuary Watch | 8/8 pass | 1060 g | 82 | Blocked: UNSUPPORTED_SCHEMA_VERSION |
| Tropical Forest Watch | 8/8 pass | 1060 g | 82 | Blocked: UNSUPPORTED_SCHEMA_VERSION |
| Polar Ice Survey | 8/8 pass | 1060 g | 82 | Blocked: UNSUPPORTED_SCHEMA_VERSION |
| Communication | 8/8 pass | 1120 g | 89 | Blocked: UNSUPPORTED_SCHEMA_VERSION |
| Weather Monitoring | 8/8 pass | 1060 g | 82 | Blocked: UNSUPPORTED_SCHEMA_VERSION |

All use the agreed v2 config, registered preset identity/revision and explicit capability context. Communication retains fast radio revision 2; all other stock values remain. The validator returns physical ready_to_launch=true, but the current native adapter rejects schema version 2 before creating state. None of these results is v2 mission success, official new-goal scoring or public-browser acceptance. No new card or launch path was enabled.

## Fresh supported game-runtime runs

The exact original three **v1** presets were mapped through the current UI/runtime boundary and run with both existing policies. Full config/event binding, initial/final native states, and initialization plus accepted post-clamp resource samples are retained. These are real current native game-policy/evaluator runs; no screens were clicked and they are not v2 acceptance.

| Original mission | Requested policy | Actual captures / returned data | Actual current v1 evaluation |
| --- | --- | --- | --- |
| Estuary Watch | Downlink First | 5 / 60 MB | success / 100 |
| Estuary Watch | Observe First | 5 / 60 MB | success / 100 |
| Tropical Forest Watch | Downlink First | 5 / 44.32 MB | partial / 87 |
| Tropical Forest Watch | Observe First | 5 / 44.32 MB | partial / 87 |
| Polar Ice Survey | Downlink First | 4 / 48 MB | Unavailable: Survey evaluation unsupported |
| Polar Ice Survey | Observe First | 5 / 54.133333 MB | Unavailable: Survey evaluation unsupported |

Estuary Watch succeeds with its current stock design. Tropical Forest Watch's stock basic radio returns 44.32 MB against 60 MB; its actual supported Imaging result is partial/87. Polar Ice Survey's stock Observe First plan captures five, returns about 54.133333 MB and fully delivers four Arctic images; Downlink First captures/delivers four and returns 48 MB. Its current production scorer explicitly refuses Survey, so there is no official score rather than a fabricated zero.

## Tested redesign options, with defaults preserved

For Forest and Survey, changing only the radio to radio_fast gives 1120 g / 89 credits and passes the same v2 physical gates. With the existing Observe First policy, both actual **legacy** design-option runs capture five, return 60 MB and completely deliver five target images. Forest's real supported Imaging result becomes success/100. Survey still has no production score. Each redesign uses a distinct run ID and retains its full edited config; original preset definitions and prior runs remain unchanged.

These are useful player experiments, not automatic preset changes, formal A/B acceptance or proof that a faster radio is always better. [K24's one-capture control](k24-communication-current.md) shows why a slower radio can help satisfy a positive-step count.

## Evidence and checks

**636 checks passed, zero failed**, with five agreed v2 readiness/native attempts, six exact-stock legacy policy runs and two radio-only legacy redesign runs. [Machine report](evidence/k23-k24-current/five-mission-readiness-current.json), [log](evidence/k23-k24-current/test_k23_five_mission_readiness.log), [source/provenance summary](evidence/k23-k24-current/checks.json). Resource projections are explicitly labelled; missing fields in historical/incomplete projections are not inferred as native zeros. Final native states preserve Survey maps under the agreed provenance rule.

Reproduce after importing the project with Godot 4.7.2:

```powershell
& $GodotExe --headless --path . --script res://tests/integration/test_k23_five_mission_readiness.gd -- ./exports/k23-current
```

The prior 49-program fresh-checkout pass belongs to commit 3ec299d. This task ran the two new audits; the expanded 51-program runner was not rerun in full. Production game/catalog code is unchanged.

## Remaining blockers

K23 stays unchecked for final live five-mission acceptance. HPC must provide the typed-v2 adapter/scenario path; SE must connect the agreed presets/context/full goals through the live flow; official expanded evaluation/reporting must be integrated. KE2 has published candidate helpers on features/KE2 at cb458c7d9c9b3b2484e8111dbbec4ea1468f51b8, but the public production entry point still requires v1 and this candidate is not merged/tested here. No K20 agreement needs repeating. Later integrated/public-browser testing remains necessary.


A separate boot-splash settings/image edit appeared in the shared folder during this task. It was copied only into the isolated audit checkout and both audits were rerun successfully. That unrelated original edit is preserved and is not included in this task's writes; no visual splash acceptance is claimed.
