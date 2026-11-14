# Callable comparison and KE3 production request

Recorded on 15 November 2026 at `features/KE2`, HEAD `0e77c488a121dbaa63898d01cfea5d07cf340b73` plus local changes. KE3 requested production Survey/Communication/Weather evaluation and a callable comparison, and confirmed the original source packet/eight execution keys are already verified. Those artifacts were reused; no new request for them was made.

## Scoring decision and delivered scope

When asked whether to confirm the proposed Survey equal-thirds and Communication/Weather equal-halves rules for production, the user explicitly chose **Keep scoring as a proposal**. That decision is recorded, not pending a repeat question. KE3's producer request does not ratify scoring or HPC's sparse-map/revolution rules. Production expanded-objective scores and report-v2 publication therefore remain unenabled.

Delivered the independently supportable callable **v1 Imaging analytical comparison** and an explicit unsupported-objective guard. Previously, v1 Communication/Weather/unknown objective strings could fall through to Imaging arithmetic if a caller bypassed or extended validation. All non-Imaging objectives now return the existing structured input error at `config.mission.objective`; none can receive a misleading Imaging score. Existing Imaging behavior is preserved.

## Callable interface for SE and KE3

```gdscript
const Comparison = preload("res://scripts/evaluation/mission_comparison.gd")
var reply: Dictionary = Comparison.compare_runs(a_record, b_record)
if reply.ok and reply.comparison.eligible:
    # Bind the result using BOTH execution keys and run/mission identities.
    var rows: Array = reply.comparison.measures
```

Inputs use SE's existing evaluated-history record: `{report, state, validation, execution_key}`. The `final_state` alias is also accepted for the earlier normalized fixtures; an additional `config`, if present, must match the state's launch snapshot. New expansion-normalization context fields are not prerequisites for this v1 analytical path. The internal `_eligibility`/`_deltas` expansion prototypes remain explicitly separate proposals.

Valid completed records with matching requirements/setup and full frozen scenario snapshots return `{ok: true, comparison: ...}`. The comparison includes both run IDs, mission IDs and execution keys; supplied outcomes; changed components; and signed B-minus-A capture/MB/score/mass/cost rows. Initial/terminal resource sampling remains unratified, so optional extrema/deltas stay null with a reason in this callable path. Root legacy capture fields keep captured-observation meaning.

For each input, the method verifies execution-key binding, readiness approval, same-run ordered event evidence and reproduction of all existing report fields except the earlier comparison payload through the approved evaluator. It preserves inputs. Aborted/unfinished attempts, differing requirements/scenarios and unsupported report/objective contracts return an ineligible comparison with reasons. Malformed/unbound reports return the existing structured error shape with code, field path, message, suggested fix and nullable run ID.

Absent operations context leaves classification null; this does not claim a controlled Design experiment. Optional `operations` contains versioned `policy: {id, version, parameters}`, `manual_requests` and complete ordered `requested_actions`. Requests must match the actual accepted/blocked event history, and manual requests must occur in it. Matching policy/manual context permits Design; a differing valid manual plan permits Design + operations. Contradictory context remains unclassified. No single-component causal guarantee or full producer-version/initialization guarantee is asserted.

This is a callable KE2 producer interface ready for SE/KE3 integration review. It does not change the signed shared contracts or silently settle the final expansion record/digest/eligibility schema. SE still owns Save A lifecycle, calling the comparison and wiring the result to KE3. `MissionEvaluator`'s optional baseline argument and current `report.comparison: null` path are not falsely presented as wired.

## Historical JSON records

The existing JSON transport issue is not silently normalized away. A live typed SE record can verify its key directly. A transported record that cannot reproduce its original key requires optional `key_preimage_utf8`: the exact original hashed bytes already reconstructed/verified for the source packet.

The API verifies that string's SHA-256 and parsed execution values. Only then it uses Variant parsing of the already validated JSON to retain the original integer/float spellings for reproducible historical feedback text. It does not invoke object-enabled deserialization or accept a replacement key. The native/public API tests demonstrate rejection without the retained bytes and successful comparison with them. This is a supported import path for the existing evidence, not ratification of SE's future complete-record digest/normalization strategy.

## Verification

Confirmed `4.7.2.stable.mono.official.ed1daf0bf`. New `tests/ke2_comparison_api_check.gd`: **34 passed / 0 failed**. It launches native basic/fast-radio runs, publishes their actual SE records, compares them, verifies +4.6133333328 MB, +19 points, +60 g and +7 credits, checks zero/negative deltas, an actual changed-goal run, bindings, operation classifications, abort/unfinished/errors and retained-byte historical input. Manual-context classification cases are labeled fixtures; this is not a UI Save A/B test.

Existing final reruns: evaluator 294 passed / 0 failed / 5 original pending; independent algorithms 125; Imaging cards 53; Results 17; Debrief summary 57, all zero failures/exits 0. T07/T08 pending wording now identifies missing SE runtime/baseline wiring instead of implying no callable module exists. The five declarations remain open. Certificate-store diagnostic persists; `git diff --check` passes.

```powershell
$godot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $godot --version
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_comparison_api_check.log' --script res://tests/ke2_comparison_api_check.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/test_mission_evaluator.log' --script res://tests/test_mission_evaluator.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_independent_work_check.log' --script res://tests/ke2_independent_work_check.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_imaging_presets_check.log' --script res://tests/ke2_imaging_presets_check.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/ke2_results_integration.log' --script res://tests/ke2_results_integration.gd
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/debrief_summary_check.log' --script res://tests/debrief_summary_check.gd
git diff --check
```

The [verification record](evidence/callable-comparison-checks.json) retains source/log hashes. No full-runner, renderer/export or browser acceptance was performed. No SE/KE1/HPC/KE3 implementation files were changed; no remote action occurred.

## Reply prepared for KE3

> Received. The original JSON packet and eight keys remain verified; no resend is needed. KE2 has delivered callable `Comparison.compare_runs(a_record, b_record)` for bound existing v1 Imaging records, with actual native/publication tests and explicit unavailable/error handling. SE/KE3 can review the attached API handoff for wiring. Production Survey/Communication/Weather scoring remains deliberately unenabled because the user chose to keep those scoring rules as proposals. HPC evidence semantics and coordinated v2 config/report support are also still needed. Those objectives now reject unsupported production evaluation explicitly instead of falling through to Imaging scoring.
