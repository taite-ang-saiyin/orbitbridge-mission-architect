# OrbitBridge: K20-K31 owner replies

**Current K20 status — user confirmation, 15 November 2026:** All non-HPC agreement items are already agreed. **HPC is the only remaining K20 confirmation.** Do not request SE/KE2/KE3 agreement again for those settled items. This records the user's confirmation; earlier pending-owner notes below describe previous checkpoints. K20 remains unchecked until HPC replies and the matching consolidated revision is recorded. Code implementation, known SE guard/Creator fixes, production evaluator/comparison support and final build/browser tests remain separate unfinished work. New mission launches remain blocked. Reviewed ZIPs and signed v1 contracts remain unchanged.


Prepared: 15 November 2026, Asia/Rangoon. Reply-form revision: `owner-replies-draft-1`.
Status: **REQUEST FOR DECISIONS; NO NEW APPROVAL RECORDED**.

For HPC, KE2 and SE. Please complete your section and return it to KE1. We need one shared K20 agreement, followed by implementation and test evidence for the later tasks; no separate general approval round is needed for every task.

## How to reply

- Enter **AGREE**, **CHANGE** or **BLOCKED** in each Reply cell.
- For CHANGE, give the exact replacement rule, field, value or callable signature.
- For BLOCKED, name the missing field, unsupported schedule or part combination, and its owner.
- Fill required technical details even when you agree with the general direction. A blank or unanswered item remains open.
- Agreement on the contract does not approve an untested build. Record patch/test status separately below.
- You may return your decision IDs and technical details in a message instead of editing the whole file. Previously verified tests need repeating only when relevant code, data or unresolved concerns justify it.

Already recorded: KE2 received draft 2/candidate 2 and supports the config choices and fast-radio starter. SE and KE3 accepted K20 material for planning. Their reported reproductions are on record. The original verified JSON packet and its eight execution keys do **not** need to be requested or supplied again; reference the existing packet and describe only changes.

## 1. Shared proposal to confirm

These are concrete proposals based on the five-mission scope PDF, especially pages 2-3, and the current review materials. They are not additional recorded approvals.

| ID | Proposed decision | Required replies |
| --- | --- | --- |
| D1: config | Explicit config v2 with root preset_id/preset_revision and nested mission.goal; preserve supported v1 inputs. Capture quota, returned MB and goal-specific counts remain separate. Keep existing Imaging behavior. | HPC, KE2, SE |
| D2: Survey | At least one completely returned observation per selected target, plus retained overall capture/data requirements. Missing or partial target delivery cannot count as complete. | HPC, KE2 |
| D3: Communication | Two distinct accepted Transmit steps returning positive MB, and at least 12 MB over three orbits. Two positive steps inside one window count as two. Rejected/zero-data attempts do not count. Capture quota supplies test payloads; it is not redefined as a contact count. UI wording: successful transmission steps. | HPC, KE2, SE |
| D4: Weather | Accepted observations of the selected region in two distinct orbits, plus at least 12 MB over three orbits. A second capture in the same orbit adds no visit. Complete image delivery for every visit is not an extra requirement in this proposal. | HPC, KE2, SE |
| D5: A/B mission | During B, keep the complete mission requirements and orbit fixed while editing agreed design fields. Changing mission requirements starts a new comparison. Match full requirements, scenario/catalog/source versions and operating conditions, not only a title or preset ID. Label changed manual actions as design + operations. | HPC, KE2, SE |
| D6: identity | Preserve the existing Creator before A. For these five authored presets, retain preset identity as template lineage for compatible edits and freeze the full edited mission; switching goal type needs matching preset context. A separate general custom-v2 identity scheme can wait; preserve existing supported v1 behavior. SE/KE2 must confirm or replace this proposal explicitly. | KE2, SE |
| D7: capability source | Use one agreed KE1-owned capability source in the explicit v2 data-loading path, consumed consistently by validation and HPC. Keep supported v1 data/loading compatible. No UI-only or silent Imaging fallback. Exact file/loader details must be supplied below. | HPC, SE, KE1 coordination |

Capture quotas for Communication/Weather remain engine limits/payload supply; the proposed new-objective success checks use their own count plus MB. KE2 should state explicitly if an additional captured-quota success condition is requested. Partial-result and numeric-score rules are not chosen by this form.

Current candidate IDs: `estuary_watch`, `tropical_forest_watch`, `polar_ice_survey`, `communication`, `weather_monitoring`.
Keep the original three preset requirements. Communication revision 2 uses equator/high_inc, two captures, three orbits, 12 MB, two positive steps, basic instrument, fast radio, remaining stock parts and a 100-credit budget: 1120 g / 89 credits. Weather keeps its current basic-radio candidate. No preset or part change is made by this request.

## 2. HPC reply

Name/role: ___
Reviewed contract/form revisions: ___
Shared decisions D1/D2/D3/D4/D5/D7: ___

| Item | Confirm or supply | Reply |
| --- | --- | --- |
| Event timing | Proposed: zero-based pre-action event step_index; derive revolution/orbit index from frozen steps_per_orbit. Accepted actions advance one step; rejected actions retain existing no-advance behavior. | ___ |
| Count evidence | Confirm action_accepted, action, delta_returned_data_mb, target_id and stable same-run event IDs, or provide exact replacements. Preserve complete per-target delivery evidence separately. | ___ |
| Frozen config | State/report consumers retain the full config v2 goals and root identity/revisions in the launch snapshot. No goal stripping. | ___ |
| Resource samples | Proposed: initial state plus state after every accepted step, including terminal state. Supply exact method/trace paths for energy_wh and stored_data_mb so lowest battery and peak storage use the same sample range. Units remain Wh and decimal MB. | ___ |
| Starter and schedules | Confirm the tested Communication fast-radio plan (capture 1/6, transmit 7/10), its one-capture count shortfall, and the Weather repeat-visit plan. Reference existing traces or give exact changed config/schedule. | ___ |
| Survey stock design | Proposal: retain current basic-radio starter as a redesign exercise; the tested fast-radio variant meets 60 MB. If the starter must meet the goal unchanged, propose the exact tested fix/revision. No default has changed. | ___ |
| Versions (required) | State version: ___; event version/identity convention: ___; scenario/catalog version references: ___. These need not automatically become 2 because config is v2. | ___ |
| Capability consumption (required) | Exact agreed source/loader or adapter entry point: ___. Confirm consistency with D7 and supported parts, or identify the required registration change. | ___ |

Remaining blockers and affected owner: ___
Patch branch/commit and callable entry points when available: ___
Evidence already available / additional checks still needed: ___

HPC response scope: **contract decisions agreed / changes requested / blocked**: ___
Implementation status: **not started / in progress / patch ready for integration / integrated and tested**: ___
This reply claims final game integration approval: **yes/no** ___; if yes, give exact build and test evidence: ___

## 3. KE2 reply

Name/role: ___
Reviewed contract/form revisions: ___
Shared decisions D1/D2/D3/D4/D5/D6: ___

Please reference the already verified packet/eight execution keys. Do not resend it. If signatures or report fields changed, identify the exact difference.

| Item | Confirm or supply | Reply |
| --- | --- | --- |
| Success rules | Imaging: captures + MB. Survey: complete delivery per target + overall goals. Communication/Weather: their own agreed count + MB. Confirm how capture quota affects each new objective's outcome. | ___ |
| Partial and failed (required) | Exact rules per Survey/Communication/Weather when only some requirements pass: ___. Preserve existing v1 Imaging behavior. | ___ |
| Numeric scores (required) | Formula/weights/rounding for each new goal type: ___. State unavailable handling and preserve existing abort/no-numeric-score behavior unless an explicit change is agreed. | ___ |
| Reports (required) | Report version: ___; new/changed goal fields and evidence references: ___. Keep reports bound to the exact run/config/events. | ___ |
| Evaluation call (required) | Exact module and callable signature for production Survey/Communication/Weather evaluation: ___. | ___ |
| Comparison call (required) | Exact module/signature: ___; input versions and return/error format: ___. Reference verified packet fields wherever unchanged. | ___ |
| Eligibility | Confirm full mission/version/conditions matching, distinct completed runs, unavailable measurements shown as unavailable, and aborted/incomplete pairs excluded from controlled scored comparison. Specify changed-operation handling. | ___ |
| Prepared evidence | Confirm planned use of K26 complete/missing/partial Survey cases and K27 real Imaging A/B reports. Identify only missing cases or unsupported input fields; do not substitute sample scores. | ___ |

Remaining blockers and affected owner: ___
Patch branch/commit and tests when available: ___

KE2 response scope: **contract decisions agreed / changes requested / blocked**: ___
Implementation status: **not started / in progress / patch ready for integration / integrated and tested**: ___
This reply claims final game integration approval: **yes/no** ___; if yes, give exact build and test evidence: ___

## 4. SE reply

Name/role: ___
Reviewed contract/form revisions: ___
Shared decisions D1/D3/D4/D5/D6/D7: ___

| Item | Confirm or supply | Reply |
| --- | --- | --- |
| Creator/edit identity | Confirm D6 or give the exact allowed edits, identity rule and comparison reset behavior. Allowed B design fields: ___. Titles alone cannot identify or match a mission. | ___ |
| V2 propagation (required) | Producer/mapping entry point: ___. Goals and versions survive Creator review, Builder, launch, saved records, Retry, Modify/Cancel and Results. Any changed requirement invalidates old mission confirmation. | ___ |
| Capability source (required) | Exact data filename and v2 loader entry point agreed with KE1/HPC: ___. Identify schema/version treatment; preserve supported v1 loading. | ___ |
| Saved-A calls (required) | Exact Save A: ___; Continue B: ___; Cancel-return: ___; open saved Results/comparison: ___. Reference existing design_lab/controller hooks and their branch/commit instead of rebuilding them. | ___ |
| Run storage | Store independent immutable A/B execution records, full config/scenario/catalog snapshots, ordered events and bound reports. B gets fresh readiness, run ID and clean counters. B cannot replace A automatically. | ___ |
| UI ownership (required) | Continuation popup owner: ___; comparison screen owner: ___; Operations/Results handoff with KE3: ___. | ___ |
| Launch gate | The current K22 draft checker always blocks launch. Confirm a coordinated production v2 path is required; keep unsupported new missions unavailable until valid setup, simulation and correct evaluation are connected. | ___ |
| Release behavior | Browser session-only A/B storage with refresh notice. Supply integration branch/commit and public candidate revision when ready; final Netlify acceptance follows actual tests. | ___ |

Remaining blockers and affected owner: ___
Patch branch/commit and tests when available: ___

SE response scope: **contract decisions agreed / changes requested / blocked**: ___
Implementation status: **not started / in progress / patch ready for integration / integrated and tested**: ___
This reply claims final game integration approval: **yes/no** ___; if yes, give exact build and test evidence: ___

## 5. How the replies close K20-K31

| Task | Completion needed after the decisions |
| --- | --- |
| K20 | Resolve conflicting replies, record exact field/value/version decisions and circulate one frozen revision to affected owners. No blank item is treated as agreement. Notify KE3 of final presentation-affecting changes; its earlier planning review remains recorded. |
| K21 | Use the same five agreed preset definitions; preserve existing settings or document an explicitly agreed tested change. |
| K22 | Implement agreed live validation and capability rules; reject invalid configs and preserve supported v1 behavior. Draft preparation is already available. |
| K23 | Verify all five through the live production path; report physical results and intended operating/design limitations. Existing report is preparation evidence. |
| K24 | HPC confirms Communication evidence/feasible schedule; KE2 handles positive, zero-data and rejected steps correctly. |
| K25 | HPC/KE2 agree and implement the chosen Weather visit rule and repeatable action plan. |
| K26 | Evaluate full/missing/partial Survey deliveries correctly using retained overall goals and complete per-target evidence. |
| K27 | Connect comparison and Save A/Continue B/Cancel; rerun B and show A remains unchanged. |
| K28 | Run the integrated mission/A-B and regression checks; record actual passes/failures and fixes. |
| K29 | Make mission descriptions, goal wording, credits and simplifying assumptions match tested behavior. |
| K30 | Confirm receipt/integration of the final matching-version files and outputs; do not request already verified packets again. |
| K31 | Test all five missions and their A/B pairs on the public Netlify build, including fresh visits, shortfalls and Cancel/Retry; record release revision/run evidence. |

## Reference versions and available materials

Base tested main: `dce75db845f6c494b8c25c9028dd9c0648aabd91`.
Config proposal: `expansion-goals-v2-draft-2`; registry: `five-presets-candidate-2`; Communication preset revision: `2`; other candidate preset revisions: `1`; review additions: `k20-review-additions-1`.

Repository paths:

- `docs/ke1-expansion/k20-interface-review.md` and `k20-validation-review.md`: fields, proposed bounds and open decisions.
- `docs/ke1-expansion/k20-parts-review.md`: current IDs and proposed part support.
- `docs/ke1-expansion/k22-draft-checker.md`: separate review-only checker; ready_to_launch is always false.
- `docs/ke1-expansion/k23-five-mission-readiness.md`: all five candidates and their existing evidence/limitations.
- `docs/ke1-expansion/k26-survey-preparation.md`: complete/missing/partial deliveries and stock redesign evidence.
- `docs/ke1-expansion/k27-ab-handoff.md`: tested same-action Imaging radio pair and owner checklist.

The previously shared combined K20/K26/K27 ZIP remains a valid unchanged snapshot. K22/K23 are later local preparations; if your checkout lacks them, name the missing path so KE1 can supply it. No approval is implied by having or passing a preparation packet. Each scope of approval above must be filled by its actual owner.

This reply form changes no game code, preset, signed agreement, task completion or launch approval. KE1 will consolidate actual replies after they arrive.
