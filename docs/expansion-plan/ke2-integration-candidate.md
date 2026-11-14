# KE2 integration candidate for 16 November

Prepared locally on 15 November 2026, Asia/Rangoon, on `features/KE2` at base `65548235958de72e531774670a785b0285032cf0` plus the files listed in the manifest. The pre-existing four documentation edits were preserved. This is the completed independent KE2 implementation candidate for tomorrow's integration. The signed `v1.0-agreed` contract remains authoritative; expansion scoring, evidence policies, report/record revisions and identity rules below remain **proposals**.

## Completed KE2 work

- [x] **10.2/10.3** Callable Survey evaluation: captures, Earth-returned decimal MB and selected-target complete deliveries, raw per-target details, capped equal-thirds candidate score, and all-goals verdict.
- [x] **20.1/20.3** Callable Communication and Weather evaluation: distinct positive accepted transmit steps or distinct selected-target revolution visits, plus returned MB; equal-halves candidate scores. Capture quota remains diagnostic for these objectives.
- [x] **30.1/30.2** Report-v2 candidate preserves the envelope and all 17 legacy fields, adds `objective` and `goal_progress`, validates full same-run history and frozen inputs, rejects nonterminal/malformed data, preserves inputs and handles aborts with failed/null score.
- [x] **30.3** Objective-aware feedback uses existing evidence helpers, retains recorded cause IDs and abort reasons, offers one experiment and remains neutral when causes are unproved.
- [x] **40.1/40.2** Callable expanded comparison validates frozen records, checks requirements/context/versions, classifies supplied operations and emits signed core/goal/resource measures with explicit unavailable values.
- [x] **40.3 KE2 portion** Pure record builder/validator retains complete evidence, snapshots, original key bytes, context and a content digest. It returns independent copies. SE owns Save A storage and lifecycle.
- [x] **50 KE2 portion** 702 new assertions pass, including fresh native replays, typed proxy fixtures, proposed weights, malformed evidence, aborts, determinism, transport integrity, signed deltas and missing-context behavior. Seven KE2 programs pass; all 43 programs in the existing repository runner pass.
- [x] **60 KE2 portion** Local source/evidence package, reproduction commands, manifests and owner dependencies prepared. Existing source-ledger integrity checks pass; no new NASA-derived rule was introduced.

Parent production, team-agreement, UI, Save A lifecycle and browser/export checkboxes remain open until their actual acceptance conditions pass. No deployment, push, merge, teammate message or commit was performed.

## APIs and activation boundary

```gdscript
const Expansion = preload("res://scripts/evaluation/mission_expansion_candidate.gd")
const Records = preload("res://scripts/evaluation/mission_expansion_records.gd")
const Comparison = preload("res://scripts/evaluation/mission_expansion_comparison.gd")

# Explicit opt-in candidate; active MissionEvaluator is unchanged.
var result = Expansion.evaluate_mission(config, final_state, events)
# result: {ok: true, report: ...} or {ok: false, error: ...}

var policy = Expansion.default_policy()
var saved = Records.build_record(config, final_state, events, original_readiness,
    captured_context, policy)
if saved.ok:
    var checked = Records.validate_record(saved.record)
    var compared = Comparison.compare_runs(saved.record, another_record)
```

`evaluate_with_policy(config, state, events, policy)` is available for explicit candidate-policy trials. `comparison_baseline` remains a reserved optional argument; use the separate record comparison API. Error objects retain `code`, `field_path`, `message`, `suggested_fix`, nullable `run_id`. Incompatible valid pairs return `{ok: true, comparison: {eligible: false, reasons: [...]}}`; malformed/binding failures return an error. The active `mission_evaluator.gd`, v1 `mission_comparison.gd`, runtime, controllers, validators, catalogs, UI and signed contracts were not edited.

Input config v1 supports existing Imaging and Survey shapes. Candidate config v2 uses revision `expansion-goals-v2-draft-2`; preset IDs are `estuary_watch`, `tropical_forest_watch`, `polar_ice_survey`, `communication`, `weather_monitoring`. Goal kinds/fields follow the received KE1 draft-2 proposal. Unknown config, design and goal fields are rejected. Candidate validation does not replace KE1 readiness or imply native config-v2 acceptance. Custom identity and catalog capability decisions remain pending; unknown presets are rejected rather than guessed.

## Explicit policies and report rules

Default policy is exactly:

```json
{"revision":"ke2-evidence-policy-candidate-1","survey_missing_targets":"unavailable","weather_mapping":"step_floor"}
```

- A missing selected Survey delivery key returns an unavailable-evidence error by default. The **explicit alternative** `survey_missing_targets: "zero_in_present_map"` fills missing selected keys in a private copy for proposal trials. A missing whole map never becomes zero. Negative/fractional counters and contradictory per-target aggregates are rejected. Partial packet MB do not establish complete delivery.
- `weather_mapping: "step_floor"` uses the accepted event's pre-action index and frozen `steps_per_orbit`, never the orbit preset ID as a revolution. This mapping is proposed pending HPC. The alternative `"recorded_orbit_index"` requires each selected accepted Observe event's valid index and does not silently fall back. Default floor mapping rejects a conflicting explicit index.
- Success requires every scored goal; partial requires progress in a scored metric; otherwise failed. Each goal ratio is capped independently and the average is rounded once, halves upward. Survey uses thirds; Imaging, Communication and Weather use halves. Raw counts/MB remain uncapped. These expansion weights remain proposals as instructed by the user.
- Aborts retain actuals and ratios, `run_status: aborted`, `status: failed`, `score: null`. Evidence unavailable on an abort may yield null goal actual/met/ratio; malformed evidence still fails validation.
- Report `schema_version: 2` is independent of config and state versions. State/event version remains 1. Candidate report revision is `mission-report-goals-v2-draft-1`, evaluator revision `ke2-expansion-candidate-1`, stored outside the 19-field report in its execution record. The revision/version selection still needs team ratification.
- Goal rows provide `id`, `actual`, `required`, `unit`, `met`, `completion_ratio`, `evidence_event_ids`. Survey rows are ordered captures, selected targets, returned MB; `by_target` retains each target's actual/required/verdict/ratio and returned MB or null. Parent evidence IDs resolve against the same full execution. Existing observation fields keep captured-observation meaning.

## Frozen record and comparison

Candidate record revision is `ke2-execution-record-candidate-1` with `record_schema_version: 1`. Fields include run/mission IDs; frozen config, final state, events and original readiness; report, report/evaluator revisions and evidence policy; `context` with initial state, full scenario/catalog snapshot, producer versions, operations, samples, credits and display context; execution-key preimage/key; content preimage/digest/algorithm.

The builder's context is demonstrated by `context()` in the new test. `catalogs_snapshot` is the engine's actual full adapted `scenario_snapshot` (parts, targets, launch data, orbits, units and versions), not a new KE1 catalog API. Required `source_versions` keys are engine, adapter, catalogs, scenario, evaluator, report. `verification_scope` must identify `native_modules` or `typed_proxy_fixture`. Missing versions or contradictory initial/catalog/config/readiness/report bindings are rejected. Retained metadata may include additional owner-provided provenance.

`operations` is optional/null when unavailable. When supplied it must contain a versioned `{id, version, parameters}` policy, ordered `manual_requests` and full `requested_actions` matching accepted/blocked event requests. Same policy/manual context permits Design classification even when hardware changes the automatically requested/accepted action history. Different supplied manual/policy context gives Design + operations. Missing context leaves classification null. No causal guarantee is inferred from the label.

The execution key covers typed JSON `[config, final_state, events, readiness]`, using sorted keys and full precision, with original UTF-8 bytes retained. The content digest covers the entire retained record except its own preimage/digest fields. JSON transport preserves original key bytes: verification checks hashes and decoded content before restoring integer/decimal types. Decimal report reproduction permits only parser roundoff (`1e-14` relative tolerance); counts, scores, field sets, strings, nulls, verdicts and ordering remain exact. Digests establish consistency, not authenticity. Never reseal edited history to disguise a changed execution.

Completed success, partial and failed runs are comparable; aborted/unfinished pairs are ineligible. Matching requirements include objective, preset/revision, ordered targets, goals, budget, duration, launch setup and orbit, plus scenario/catalog snapshots, versions, evidence policy, scope and proposed full-battery/empty initialization. Legacy identity uses explicit `exact_requirements_v1_proposal`; cross-version/custom lineage is not guessed.

Core numeric measures are captures, Earth MB, score, cost and mass. Each typed goal also has a signed count/MB delta; raw Survey target detail and both outcomes are retained. Optional resource extrema require `initial_and_each_accepted_poststep_v1_proposal`: initial plus every accepted post-step sample including terminal, numbered 0..N, bounded by capacities and matching initial/final resources and accepted-event resource changes. Unknown, missing or inconsistent sampling yields unavailable extrema. Battery Wh and percent are separate; percent differences use percentage points. HPC must ratify the sampling definition.

## Evidence and expected/actual results

| Check/case | Expected and actual | Evidence level |
| --- | --- | --- |
| Active evaluator | 294 pass, 0 fail, 5 pending | Agreed v1 fixtures/native integration checks |
| Existing KE2 independent / callable v1 / Imaging presets / Results / Debrief | 125 / 34 / 53 / 17 / 57 pass, zero failures | Existing fixtures plus current native modules; actual Imaging card checks |
| New candidate | 702 pass, zero failures | Fresh native v1 replay plus explicitly typed proxy fixtures |
| Repository regression runner | All 43 active check programs pass | Current headless project/modules/UI checks |
| Survey shortfall / complete | Proposed 83 partial / 100 success; 15.466666665600002 / 24 MB; 1 / 2 complete selected targets | Native v1 Survey mechanics, candidate report2; shortfall uses explicit sparse-zero policy |
| Communication historical shortfall / complete | Proposed 75 / 100; 1 / 2 positive steps, 18.466666668 / 24 MB | Native Imaging mechanics; typed Communication fixtures |
| Communication same-contact control | Same config/quota2: shortfall 1 positive send/12 MB/75; complete 2 sends at 7/10, 24 MB/100 | Fresh native high-inclination Imaging surrogate; typed Communication fixtures |
| Weather shortfall / complete | Proposed 75 / 100; 1 / 2 revolutions, both 22.1600000016 MB | Native Imaging mechanics; typed Weather fixtures under proposed mapping |
| Native Imaging A to B | +4.6133333328 MB, +19 score, +60 g, +7 credits | Fresh current native validator/adapter/engine with candidate reports/records |

The ten frozen records in [the candidate packet](evidence/ke2-integration-candidate-records.json) contain configs, reports, full events, initial/final state, samples, policies and keys. These are **new candidate executions**, not replacements for the eight previously verified historical keys. The original packet and preimages remain unchanged; do not ask owners to resend them. [Verification/manifest](evidence/ke2-integration-candidate-verification.json) records exact source hashes. [Local review archive](evidence/ke2-integration-candidate.zip) contains the KE2 implementation, dependencies, tests, docs and packet.

The five still-declared pending cases are T07 controlled retry deltas (SE Save A/runtime wiring), T08 baseline eligibility (SE comparator wiring), T11 actual 1329 g Builder check (KE1/SE), T12 1330/1331 g and profile switching (KE1/SE), and the integration declaration for Results/duplicate publication/retry-reset (SE; real HPC trace portion is exercised by existing tests). These are unchanged declarations, not 5 new failing tests. Headless passes do not close browser/export or actual Save A requirements.

## Exact rerun commands

From `D:\orbitbridge-mission-architect` in PowerShell:

```powershell
$orbitGodot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $orbitGodot --version
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_ke2_expansion_checks.ps1 -GodotExe $orbitGodot
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_all_checks.ps1 -GodotExe $orbitGodot
# Candidate only:
& $orbitGodot --headless --path . --log-file D:/orbitbridge-mission-architect/exports/check-logs/ke2_expansion_candidate_check.log --script res://tests/ke2_expansion_candidate_check.gd
git diff --check
```

Verified executable reports `4.7.2.stable.mono.official.ed1daf0bf`. Both runners exit 0; the final candidate-only rerun reports 702/0 after final additions. Logs are in `exports/check-logs`; generated records are in `exports/check-evidence/ke2-expansion-candidate/records.json`. The known Windows root certificate-store diagnostic recurs; checks pass and require no network. No browser steps or export were performed.

## Tomorrow's owner sync and merge order

1. **KE1 + affected owners:** consolidate/freeze the expansion revision, bounds and custom/preset identity. Confirm the already-received draft-2 schema against live producers. Keep original Imaging/Polar inputs compatible.
2. **HPC:** confirm absent Survey keys in a valid sparse map, positive transmit-step semantics, Weather pre-action mapping/index and resource sampling. Supply/confirm actual config-v2 success/shortfall traces; no resend of the existing packet is needed.
3. **KE2:** reconcile this candidate's pinned revisions/policies with the signed freeze and rerun the same checks. If semantics change, adapt the isolated module/tests before enabling it. Candidate implementation is complete; ratification and real integration remain conditional.
4. **SE:** wire the chosen evaluator/report version, original-readiness/frozen execution binding and retained records. Save A must come from the actually completed active execution, survive Retry/Cancel/B/trace eviction, and clear on New Mission. Use the public expanded comparator; no UI recomputation of scores or ratios.
5. **KE3:** bind/render goal rows, nulls, evidence and expanded comparison against that same execution; retain legacy Imaging fallback and scoped credits. Accept real expanded reports after SE wiring.
6. **SE/KE3/KE2 with KE1/HPC:** verify five actual preset success/shortfall/A-B loops, retry/publication boundaries, Windows/Web and the SE-confirmed deployed revision. SE owns exports/deployment. Record real evidence before closing production checklist parents.

No further user approval is needed for local candidate work. Shared-contract adoption and cross-owner activation are tomorrow's coordinated team decisions; previously supplied approvals and verified packets need not be requested again.
