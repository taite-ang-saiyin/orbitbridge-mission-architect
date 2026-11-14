# KE2 reply to KE1 — K20–K31

Prepared for the user to send on 15 November 2026, Asia/Rangoon. This is a drafted KE2 response, not a sent message or a consolidated team approval. New scoring/version choices below are KE2 proposals for the shared K20 freeze; they do not change the signed production contract.

Delivery update, 15 November: the user reports they have already replied to KE1. Record the owner-response handoff as user-reported delivered; do not request the same reply again. This file preserves the prepared text and does not independently verify the exact sent wording, teammate receipt or a consolidated freeze. Scoring remains a proposal per the recorded user decision. Next is receipt of KE1's consolidated frozen revision and remaining producer/record decisions.

KE1, received `owner-replies-draft-1`. Here is KE2's section, including the remaining technical decisions and implementation limits.

Name/role: KE2 — evaluation, scoring, evidence and comparison.

Reviewed revisions: `expansion-goals-v2-draft-2`, `five-presets-candidate-2`, Communication revision `2` / other candidates revision `1`, and the supplied `k20-review-additions-1` summary in this reply form. I have not inspected every later preparation file named in that summary.

The existing verified packet is `docs/expansion-plan/evidence/ke2-handoff-current.json`, SHA-256 `a42a1ca3aaa4cbafca548576c14f68578961cef9084fec4275557583a7ceeb7e`. Its eight execution keys and original production replies remain unchanged; no resend or replacement keys are needed.

| Decision | KE2 reply |
| --- | --- |
| D1 | **AGREE.** Explicit config v2, root preset identity/revision and nested `mission.goal`; preserve supported v1 inputs and existing Imaging behavior. Captures, returned MB and objective-specific counts stay separate. |
| D2 | **AGREE.** Survey requires at least one completely returned observation for every selected target, plus its aggregate capture and returned-MB goals. Partial packets do not satisfy a target. This revision supports the proposed per-target minimum of one; higher minima need an explicit extension. |
| D3 | **AGREE.** Two distinct accepted Transmit steps with positive returned MB, plus at least 12 MB within three orbits. Two positive steps in one window count twice; repeated evidence for one step counts once; rejected/zero-data attempts count zero. Use “successful transmission steps” in UI. |
| D4 | **AGREE.** Successful accepted captures of the selected region in two distinct revolutions, plus at least 12 MB within three orbits. Same-revolution repeats add no visit. No additional complete-delivery-per-visit requirement. HPC must confirm the event timing/revolution mapping. |
| D5 | **AGREE.** Freeze complete mission requirements and orbit for B; changing a requirement starts a new comparison. Match scenario, catalogs/source versions and operating conditions. Compare requested policy/manual choices: hardware-dependent accepted-action differences under the same requested policy do not alone mean changed operations. Changed manual choices are “Design + operations.” |
| D6 | **AGREE explicitly.** Keep Creator before A. Compatible edits retain authored preset ID/revision as template lineage, with the complete edited config frozen. Switching objective requires matching preset context and starts a new comparison. Preserve supported v1 behavior; defer a general custom-v2 identity scheme. Titles never establish eligibility. |

No preset or part change is requested. Keep the original three presets, Communication's fast-radio revision 2, and Weather's current basic-radio candidate. Survey's basic-radio starter may remain a redesign exercise; its unchanged starter is not claimed to meet 60 MB.

## Success, partial and failed

**AGREE** with the success rules above. Communication/Weather capture quota is an engine limit and payload supply; I am **not requesting an additional captured-quota success condition** for either objective. Preserve the raw capture actual and quota in reports.

**CHANGE — add these exact partial/failed rules to the frozen contract:**

| Objective | Success | Partial when success is unmet | Failed |
| --- | --- | --- | --- |
| Imaging | Captures and returned MB both meet their targets | Captures > 0 or returned MB > 0 | Both actuals are zero |
| Survey | Aggregate capture and MB targets met, and every selected target has a complete delivery | Captures > 0, returned MB > 0, or at least one selected target has a complete delivery | All three progress measures are zero |
| Communication | Qualifying positive steps and returned MB both meet their targets | Qualifying steps > 0 or returned MB > 0 | Both scoring actuals are zero |
| Weather | Distinct selected-region revolution visits and returned MB both meet their targets | Qualifying visits > 0 or returned MB > 0 | Both scoring actuals are zero |

Payload capture alone does not create Communication scoring progress. A nonqualifying capture does not create Weather visit progress. Derive status from raw requirements, never from a rounded score.

## Numeric scores and unavailable evidence

**CHANGE — propose these exact weights and rounding:** let each ratio be `min(actual / required, 1.0)`, with valid nonnegative actuals and strictly positive requirements.

| Objective | Score |
| --- | --- |
| Imaging | `round_half_up(100 * (capture_ratio + returned_mb_ratio) / 2)` — unchanged |
| Survey | `round_half_up(100 * (capture_ratio + returned_mb_ratio + delivered_target_ratio) / 3)` |
| Communication | `round_half_up(100 * (positive_step_ratio + returned_mb_ratio) / 2)` |
| Weather | `round_half_up(100 * (distinct_visit_ratio + returned_mb_ratio) / 2)` |

`delivered_target_ratio` is the fraction of selected targets with at least one complete returned observation. Preserve all raw over-target actuals, cap ratios separately, and round only the final score, with .5 upward. The existing Survey worked case is partial/83 under this proposal.

Missing required goal evidence produces the structured evaluation error, not zero progress or an invented score. In particular, an absent entire Survey delivery map cannot prove zero deliveries. Missing keys within a sparse map still need HPC's explicit semantic confirmation; the current helper does not silently turn them into zero. Optional comparison diagnostics use null plus an unavailable reason, with no numeric delta.

Keep abort behavior: valid terminal aborts preserve actuals, use `run_status: aborted`, `status: failed`, `score: null`, even after goals were met. Malformed/nonterminal inputs remain errors.

## Reports and evaluation call

**CHANGE — propose legacy report schema 1 and expanded report schema 2**, using candidate report-contract revision `mission-report-goals-v2-draft-1` for review. Config/state/event/report/record versions remain independent. Coordinate explicit output selection and dual-version consumer support with SE/KE3 before publication; a config bump alone does not migrate consumers.

Retain the 17 report fields and their meanings. Add `objective` and `goal_progress`, as in the existing four v2 candidate examples. Goal entries contain `id`, raw `actual`, positive `required`, `unit`, `met`, capped `completion_ratio`, and same-run `evidence_event_ids`. Survey adds `by_target` detail. Goal IDs are `captures`, `returned_data`, `selected_targets_delivered`, `positive_transmit_steps`, and `selected_target_revolution_visits`. Keep captured-observation fields as captures, including when they are diagnostic rather than scored.

Propose retaining report-contract/evaluator revisions in the saved execution record metadata, without adding further report keys in this revision. SE/KE2 must freeze their exact record paths and digest scope. Bind each report to full frozen config, terminal state, ordered events and original readiness, and validate goal values/evidence against that execution. Run ID alone is insufficient.

Evaluation module: `res://scripts/evaluation/mission_evaluator.gd`.

Callable remains `MissionEvaluator.evaluate_mission(config, final_state, events, comparison_baseline = null) -> Dictionary`, returning `{ok: true, report}` or `{ok: false, error}`. Errors retain `code`, nullable `field_path`, `message`, `suggested_fix`, and nullable `run_id`.

**BLOCKED for production Survey/Communication/Weather evaluation:** there is no production implementation for those objectives yet. The current evaluator rejects them; the Survey score and new count helpers are preparation code. The signature above is the intended unchanged public entry point, not a claim that new objectives are already supported. Comparison remains a separate call; the evaluator baseline parameter is still reserved.

## Comparison call and eligibility

Module: `res://scripts/evaluation/mission_comparison.gd`.

Local callable: `compare_runs(a_record: Variant, b_record: Variant) -> Dictionary`. The current uncommitted implementation accepts SE-style `{report, state, validation, execution_key}` records for completed v1 Imaging executions; optional `key_preimage_utf8` retains historical hash bytes, and optional operations metadata supports classification. It returns `{ok: true, comparison}` with `eligible`, or the existing `{ok: false, error}` structure for malformed inputs. A well-formed unsupported/mismatched pair returns an ineligible comparison with reasons.

**BLOCKED for the final expanded comparison contract.** The local callable is not the complete v2 saved-record/version/conditions contract and is not claimed as final K27 integration. Keep the same proposed callable signature, then agree record-schema version, snapshots, producer/source versions, initialization/sampling and binding metadata with SE/HPC. Existing packet fields/keys remain unchanged. The local callable changes have not been tested in this reply session.

**AGREE** to require distinct completed run IDs, full frozen requirements, preset lineage, orbit/duration, scenario/schedule, catalog/source and producer versions, and equivalent initialization policy/operating conditions apart from intended design effects. Completed partial/failed outcomes can be compared; aborted/incomplete runs cannot enter the controlled scored comparison. Missing required compatibility context makes the pair unavailable. Unknown operations remain unclassified; they do not receive a “Design” label. Matching requested policy permits hardware-induced acceptance differences; changed requested policy/manual choices receive “Design + operations” and limited causal interpretation.

Use initial state plus every accepted post-step state, including terminal state, for resource extrema if HPC agrees that sample contract. Until then, lowest battery/peak storage remain unavailable in the public comparison rather than mixing sample ranges.

For historical JSON transport, preserve original execution-key preimage bytes or agree a versioned normalization before changing hashing. All eight historical keys reproduce from the retained bytes/native replay; direct JSON reserialization changes numeric representation and mismatches all eight. No historical keys should be regenerated to hide that difference.

## Prepared evidence, blockers and implementation status

**AGREE** to use K26 complete/missing/partial Survey delivery cases and K27's measured Imaging A/B reports. Do not substitute illustrative scores for production output. The already verified packet supplies real Imaging reports and recorded Survey/proxy measurements. Communication/Weather Imaging proxies remain proxies until their typed production paths exist.

Existing recorded evidence, not new executions for this reply:

- Draft-2 isolated checks: 629 passes, plus 265 same-config control checks. Fast-radio Communication surrogate: capture steps 1/6, transmit steps 7/10, 24 MB; same-config one-capture control: 12 MB at step 7, empty-buffer rejection at step 10, only one qualifying transmission.
- Independent KE2 suite: 125 passed / 0 failed; evaluator 294 passed / 0 failed / 5 existing pending; Imaging 53, Results 17, Debrief summary 57, all zero failures. These combine fixtures, retained native traces and headless module checks, not full expanded-game acceptance.
- Historical packet/report review checker: 85 passed / 0 failed, retaining the JSON transport caveat.

Remaining handoffs:

- **HPC:** typed-v2 acceptance, accepted-event timing/revolution mapping, explicit Survey sparse-map semantics, resource sample paths/versions, and official Weather success/isolated-shortfall traces; confirm Communication evidence under its real objective.
- **KE1 + HPC + SE:** exact common capability source/loader, coordinated live v2 validation/config propagation, and matching scenario/catalog/source identities. I do not nominate an unconfirmed source filename on their behalf.
- **KE2:** implement the agreed new-objective evaluator/report migration and finish the expanded comparator after the contract freeze; rerun affected checks against actual producer inputs.
- **SE + KE3:** immutable saved-A/B record contract, Save A/Continue B/Cancel wiring, report v1/v2 binding/presentation, and actual lifecycle/public-build verification.
- The later `docs/ke1-expansion/k22-draft-checker.md` and `k23-five-mission-readiness.md` are absent here; please supply those later preparation documents. The K26/K27 named Markdown paths are also absent from the live tree, but I am referencing the existing shared snapshot rather than requesting the unchanged combined packet again.

Patch status: `features/KE2`, inspected HEAD `0e77c488a121dbaa63898d01cfea5d07cf340b73`, plus existing uncommitted evaluator/comparator changes and `tests/ke2_comparison_api_check.gd`. HEAD is not a frozen expanded-integration patch. No commit/push or gameplay code change was made for this reply.

**KE2 response scope:** contract direction agreed as D1–D6 above; exact scoring/report additions proposed for consolidation; producer/record details remain blocked as identified.

**Implementation status:** in progress. Preparation helpers/fixtures and supported Imaging evidence exist; new-objective production publication and full A/B integration remain open.

**Final game integration approval: NO.** No all-five-mission, saved-A/B UI, exported-build or public Netlify acceptance is claimed.

# Local implementation update — 15 November

The earlier owner reply remains the historical delivered response. KE2's [complete isolated integration candidate](ke2-integration-candidate.md) is now implemented and packaged for tomorrow's team sync: four-objective evaluation/report2, feedback, frozen record validation and expanded callable comparison; 702 candidate assertions and all 43 repository programs pass. This does not adopt the proposed scoring or replace the consolidated owner freeze. Use the linked API/evidence and owner merge order; the original verified packet need not be resent.
