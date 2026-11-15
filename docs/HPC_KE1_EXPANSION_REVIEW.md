# HPC / KE1 expansion integration review

Reviewed 15 November 2026 (Asia/Rangoon). Local source branches: `feature/hpc-ke3-goal-evidence-v1` at `345e5bd` and `ke1-expand` at `3ec299d`. The supplied `hpc/` and `ke1/` directory copies are older; they were preserved unchanged. No branch merge, commit, push or deployment was performed.

## Follow-up: supplied updated folders

The later supplied `ke1-expand/` and `hpc-ke3-goal-evidence-v1/` folders were reviewed alongside `ke1/` and `hpc/`. This section supersedes the earlier preview-only integration status below.

- The two older copies retain the original single-target baseline. The expansion readiness sources and agreed preset data match the already imported production files. No replacement of those files was necessary.
- The updated simulation copy adds native counters and a candidate evaluator, although its handoff README still describes the older proxy-only state. Its adapter uses `v2.0-agreed`, goal kinds equal to objective IDs and a generic `required_count`, with several aliases. These disagree with the readiness contract (`expansion-goals-v2-agreed-1`, `communication_contacts` / `weather_revisit`, and explicit named count fields). Its test also uses two Weather targets, contrary to the single-target agreement.
- Integrated the native counter/action logic, replacing the permissive adapter path with validation against the complete agreed frozen catalog context. Shared physical resolution operates on the original v2 config without stripping the goal or changing the objective/schema. Scenario data must match reconstruction from that context. Unknown lineage, aliases, missing context and fractional schema versions fail.
- Communication counts distinct accepted positive-data Transmit steps. Weather counts only the first accepted selected-target observation in each revolution. Goal progress/evidence is reconstructed from the full ordered same-run event log before subsequent actions; inconsistent or missing evidence is rejected. Original physics, windows, component values and v1 behavior remain unchanged.
- Both new Mission Control cards now launch real **unscored** flights. Operations and Results display native goal counts. Myanmar setup labels indicate flight availability and missing scoring. No numeric score is invented.
- The candidate evaluator was deliberately not imported: it trusts supplied counters, takes requirements from state rather than the authored goal, and emits a report shape different from the agreed expansion report. Verified production scoring remains outstanding. The production evaluator returns an explicit unavailable result for v2; captured/returned totals and native goal progress remain visible.
- Shared UI text sanitization now covers all five prohibited team labels, including SE; the report battery label uses plain wording. New mission UI tests scan Operations and Results. The existing player-copy test now checks SE too.
- Added `.gdignore` to the two newly supplied reference copies so the editor does not import duplicate global script classes/assets. Reference implementation files were left unchanged.

Follow-up verification on Godot 4.7.2: native canonical-contract/count/prediction/abort/immutability/forged-evidence tests pass for both missions; both real preset → flight → Results paths and Myanmar flight notices pass; player UI 174/0; v2 readiness 373/0; presets/context 97/0; legacy native tests 48/0; readiness 671/0; translation 28/0; owner guards 38/0; execution records 19/0; both legacy objectives/orbits pass prediction parity; integrated player flow passes at two resolutions. The PowerShell runner includes the new native contract suite. Browser export and rendered visual QA were not performed.

The official NASA links and scientific limits below were rechecked for this follow-up. The mass comparator is directly source-backed for the cited historical sample profile. Power/downlink/orbit concepts are educational adaptations. NASA does not define or approve these authored positive-transmission/revolution quotas, contact windows, fictional hardware or Weather success conditions. Weather is an observation revisit exercise, not a meteorological forecast model.

## Earlier integration record

- Imported the agreed five-preset registry, capability document, explicit v2 context loader, pure v2 readiness validator and unchanged v1 validator implementation. Public entry remains `MissionValidator.validate(config, catalogs)`.
- Mission Control now offers Communication and Weather Monitoring readiness previews. Selection uses the agreed registry, not duplicated defaults. Creator, review and Builder retain full contract/preset revisions, typed goal and chosen engineering parts. Existing three playable presets keep their v1 path.
- Communication revision 2: high_inc / Equator, fast radio, two capture quota, 12 MB returned, three orbits, two positive transmission steps; 1120 g / 89 credits.
- Weather revision 1: high_inc / Equator, basic radio, two capture quota, 12 MB returned, three orbits, two distinct observed revolutions; 1060 g / 82 credits.
- Readiness previews show physical checks but disable launch. Both direct runtime and native initialization continue to reject unsupported v2 inputs without creating a run. Goals are never stripped or converted to Imaging. HPC's published evidence branch adds v1 proxy evidence, not a native v2 adapter or production scoring. Those are remaining launch dependencies.
- Creator refuses objective switching within a v2 template, keeping goal and lineage consistent. Starting another preset is supported. Edited goal/identity values invalidate review.
- Design B and independent comparison guards now require unchanged orbit, launcher and launch profile, matching the existing components-only comparison UI.
- Producer validator hash now binds all nine production validation dependency files using exact file bytes, in the existing version field. Historical records and key preimages remain untouched.
- Myanmar phrases cover the new names, preview status, goal explanations, review counters and v2 readiness status. IDs, numeric goals, config and historical evidence stay unchanged. Existing scoped language behavior still excludes Operations/Debrief.

## NASA checks and limits

1. [NASA CubeSat 101](https://www.nasa.gov/wp-content/uploads/2017/03/nasa_csli_CubeSat_101_508.pdf), Appendix C, printed page 79 / PDF page 87: the sample checklist specifies mass below 1.33 kg. The profile correctly uses total spacecraft mass <1330 g; 1329 passes and 1330/1331 fail. This is the cited historical sample checklist, not a universal current launch certification rule. Other profile limits remain illustrative.
2. [NASA Small Spacecraft Technology: Power](https://www.nasa.gov/smallsat-institute/sst-soa/power-subsystems/), sections 3.1–3.2: eclipse removes solar generation and storage supports electrical loads. HPC's W × hours = Wh balance is dimensionally correct. Constant output, clamping and always-available power-save are game simplifications; no efficiencies, degradation, thermal model or brownout are represented. Static readiness does not prove endurance.
3. [NASA Small Spacecraft Technology: Communications](https://www.nasa.gov/smallsat-institute/sst-soa/soa-communications/), section 9.2.4: real communications trades include rate, power, mass, ground stations and link budget. HPC caps returned MB by stored MB and rate × step hours during authored contact. That is consistent simplified accounting; its fixed windows/rates are not NASA link predictions. The two-transmission goal is a game requirement.
4. [NASA Basics of Space Flight, chapter 5](https://science.nasa.gov/learn/basics-of-space-flight/chapter5-1/): inclination is measured relative to the equator, with exactly polar at 90 degrees. The source high_inc orbit is 97.8 degrees (near-polar retrograde), not exactly polar. Original orbit metadata is retained. Weather's distinct-revolution counter is an authored revisit objective, not a weather forecast or measured coverage model.

Communication must count distinct accepted positive-MB transmission steps, not windows, attempts or total MB. Weather must count selected-target positive observations by pre-action step / frozen steps_per_orbit; repeated captures in the same revolution count once. These semantics match the agreed expansion contract and HPC examples. Survey complete delivery is separate from partial returned MB and captured counts. Missing historical maps are unavailable, not evidence of zero delivery.

## Verification performed

Godot 4.7.2 headless commands use `--path . --script res://tests/<program>`:

- `validation/test_mission_presets_v2.gd`: 97 passed.
- `validation/test_mission_validator_v2.gd`: 373 passed, including native-v2 rejection controls.
- `validation/test_mission_validator.gd`: 294 passed. Its unsupported-version case now uses 3 because numeric 2 has a production validation path.
- `validation/test_mission_readiness.gd`: 671 passed.
- `validation/test_mission_fixtures.gd`: 470 passed, including strict mass boundaries.
- `test_hpc.gd`: 48 passed.
- `integration/test_se_owner_contract_preparation.gd`: 38 passed; previously documented seven owner-guard failures resolved.
- `myanmar_localization_smoke.gd`: 28 passed.
- `se_design_lab_hooks.gd`: 76 passed; `se_execution_record.gd`: 19 passed.
- `prediction_multitarget_smoke.gd`: both objectives on both orbits passed.
- `expanded_missions_smoke.gd`: mission/target interaction at three resolutions and resource conservation passed.
- `integration_smoke.gd`: player flow at 1440×900 / 1024×768 and launch/result snapshot checks passed.
- `mission_expansion_integration.gd`: both authored new presets, hardware totals, review invalidation, direct launch rejection, real card callbacks and Myanmar preview status passed.

Historical HPC evidence: imported unchanged with its original source pins and manifest. Replayed all 12 examples in an isolated temporary project assembled from the original branch files, with `tests/run_hpc_goal_examples.gd -- --verify-only`: 8266 checks passed, zero failed. Running that historical verifier directly against the changed integration working tree intentionally fails original-byte source pins; do not rewrite those pins to disguise a different producer. This replay verifies historical v1 mechanics, not live v2 support.

Added the four new production/owner integration suites to the maintained PowerShell runner without replacing existing checks. The PowerShell runner itself and browser/export/native visual layouts were not executed in this review. Current UI checks are headless; Myanmar copy has not had independent linguistic review.
