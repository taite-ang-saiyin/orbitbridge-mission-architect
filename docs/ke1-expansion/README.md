# KE1 expansion preparation

**Current K23/K24 update:** [Five-mission current report](k23-five-mission-readiness.md) and [Communication current evidence](k24-communication-current.md) contain 1347 newly executed checks. K20 is agreed; old proposed/confirmation-pending labels below are historical. Actual v2 native launch/evaluation remains unfinished. No earlier ZIP or default was changed.


**Latest implementation update:** K20 is agreed and K21 definitions are delivered. [K21/K22 production API and current blockers](k21-k22-live-integration.md) and the [agreed v2 contract](../contracts/expansion-v2.md) supersede earlier pending-confirmation/candidate-only status. The public validator now supports explicit agreed v2 context; native launch integration remains blocked. Existing reviewed ZIPs are unchanged historical snapshots and do not contain these later files.


**Latest HPC status:** [Conditional review received and exact clarifications](hpc-k20-clarifications.md). Final HPC acknowledgment remains pending; non-HPC agreements stay settled. State/event v1 is conditional on implementation compatibility. Current code still rejects v2. Earlier pending-owner statements below are historical. Existing ZIPs remain unchanged; this clarification postdates the current handoff archive.


**Current update, 15 November:** Only HPC confirmation remains. [Consolidated non-HPC decisions](k20-consolidated-non-hpc-decisions.md), [candidate validator](k22-v2-candidate-validator.md), [aligned copy](k29-mission-wording-preparation.md) and [single current handoff](current-implementation-handoff.md) supersede earlier pending-owner labels below. Candidate tests: 2429 passed. Latest SE checks still expose two implementation issues; final integration remains pending.


**Current K20 status — user confirmation, 15 November 2026:** All non-HPC agreement items are already agreed. **HPC is the only remaining K20 confirmation.** Do not request SE/KE2/KE3 agreement again for those settled items. This records the user's confirmation; earlier pending-owner notes below describe previous checkpoints. K20 remains unchecked until HPC replies and the matching consolidated revision is recorded. Code implementation, known SE guard/Creator fixes, production evaluator/comparison support and final build/browser tests remain separate unfinished work. New mission launches remain blocked. Reviewed ZIPs and signed v1 contracts remain unchanged.


Local-copy note: these resources and the updated root AGENTS.md, GEMINI.md and tasks.md are also restored in the original project folder on main. The three personal root files remain ignored by Git. The branch/workspace statements below identify where the preparation was originally created; they do not mean this local main copy was committed or pushed.

The confirmed scope is **five named presets**, not four additions: Estuary Watch, Tropical Forest Watch, Polar Ice Survey, Communication and Weather Monitoring. The first three already exist; append only the last two. There are four goal families because the first two share Imaging. A/B comparison should work for every preset. No multiplayer or multiplayer server is included.

This local working folder starts from main `dce75db845f6c494b8c25c9028dd9c0648aabd91`. It preserves your older KE1 notes and completed task history, with updated assistant instructions and new pending tasks. Main, deploy and the old ke1/ke1-sunday branch tips are not changed by this preparation.

## Owner reply checklist

[HPC, KE2 and SE reply form for K20-K31](k20-k31-owner-replies.md) contains concrete PDF-based proposals, separate owner response fields and later implementation/acceptance milestones. All new replies and approvals are pending; existing review receipts remain recorded.

## Owner review status

[SE/KE3 planning reviews and KE2 receipt/support](k20-owner-review-record.md) are now recorded from user-relayed replies. HPC confirmation, W1/C1, Creator/custom identity, capabilities, report/version decisions and final agreement remain pending. The reviewed ZIPs are preserved unchanged.

## K20/K21 progress

The [review packet and test evidence](k20-k21-progress.md) are ready. [K20](k20-interface-review.md) remains pending owner agreement. K21 has a checked [five-preset candidate catalog](../../data/mission_presets.json) and [safe loader](../../scripts/core/mission_preset_catalog.gd), at candidate 2 with 70 catalog checks passing. Draft 2 incorporates KE2 fast-radio settings; HPC and SE confirmations remain pending. See the [KE2 review package guide](ke2-review-package.md). This registers KE1 definitions; it does not add playable cards or scoring to the UI.

## K20 review additions

[Exact proposed validation](k20-validation-review.md), [parts/capabilities](k20-parts-review.md) and [40 examples](examples/k20-review/README.md) address SE review. [Recorded checks](evidence/k20-review-additions/checks.json) distinguish proposal-only QA from current-engine physical tests. Weather delivery (W1), transmission steps versus windows (C1), capability registration and team confirmations are pending; no game validator changed.

## K24/K25 progress

[Communication and Weather feasibility](k24-k25-feasibility.md) is measured in eleven current-engine traces, with 1,740 audit checks passing. Both KE1 and KE2 Communication starter designs can meet the proposed goal. Weather needs an explicit wait between visits; both current automatic policies miss it. HPC acceptance and K20 agreement remain pending. These diagnostics do not enable new objectives.

## K26 Survey preparation

[Survey examples and handoff](k26-survey-preparation.md) include complete, unreturned and partial target delivery, plus original-stock and fast-radio design examples. Five real Survey traces passed 95 checks. The stock design shortfall is documented without changing defaults. HPC acceptance, KE2 scoring and K20 agreement remain pending.

## K27 A/B handoff

[The supported Imaging radio pair and member handoff](k27-ab-handoff.md) are ready: 36 checks passed, with identical mission/actions and only one radio change. Actual reports show partial/82 versus success/100 alongside mass/cost/energy trade-offs. SE/KE2/KE3 can use the examples for one Imaging loop while K20 and expanded comparison remain pending. No live UI/storage/comparator changed.

## K22 draft checker preparation

[Separate checker, API and evidence](k22-draft-checker.md) are ready: 466 draft tests and 2019 checks across six programs passed. The checker always blocks launch; existing v1 behavior and production launch code are preserved. K20 rules/owner decisions and live v2 integration remain pending.

## K23 five-mission report

[The consolidated readiness report](k23-five-mission-readiness.md) reuses existing K22 results for all five exact candidates: draft/physical checks pass, but all v2 launch approvals remain pending. It includes preserved settings, eight gates, mass/cost and runtime/goal limitations. No game tests were rerun or source changed.

## Start here

1. Read [tasks](../../tasks.md), starting with K20.
2. Review [current code findings and implementation order](implementation-plan.md).
3. Discuss [the proposed extension contract](contract-proposal.md) with the other owners. The signed v1 agreement remains unchanged.
4. Use [example inputs and action plans](examples/README.md), [resources](resources.md) and [validation cases](validation-cases.md).
5. Read [verification and preservation](verification.md) before claiming anything passes.

## Scope source

The user supplied [the five-mission v2 scope PDF](references/five-mission-scope-v2.pdf) and confirmed five missions in this chat. The PDF supplies planning goals and task division, not independent approval of new field names or scientific accuracy. Its proposed Communication and Weather targets are two qualifying steps/visits and 12 MB over three orbits. Validate them with HPC before freezing production settings.

## Prepared resources

- [Five short mission briefs](mission-briefs.md).
- [Proposed preset registry](examples/mission-presets.proposed.json): reference material, not currently loadable as a production catalog.
- [Current v1 config examples](examples/legacy-configs/): physical/setup inputs, including training-only inputs for the two proposed new goals.
- [A/B pair](examples/comparison-pair.proposed.json): one radio change and proposed matching fields; no invented performance results.
- [Repeat-visit action plan](examples/action-plans.proposed.json): current engine schedule for checking a possible Weather goal.
- [Reusable example checker](tools/audit_examples.gd) and [recorded audit](evidence/example-audit.json).
- [Preservation manifest](preservation-manifest.json): exact source-file hashes and backup entries.

Browser gameplay remains local to the page on the existing Netlify site. Local test evidence is different from testing the public site. Production work stays pending until the task is actually implemented and tested.


## Ordered preparation update

See [handoff index](ordered-preparation-handoff.md), [draft capability API](k22-capability-loader.md), [SE regression handoff](k28-se-integration-preparation.md), and [five-mission copy](k29-mission-wording-preparation.md). Main focused checks: 2102 passed. SE saved-A: 73 passed. New SE contract probes: 31 passed / 7 open failures; these are not main/browser acceptance. All owner decisions and live launch approvals remain pending.
