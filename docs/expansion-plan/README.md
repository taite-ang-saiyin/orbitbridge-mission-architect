# Five Missions and A/B Design Lab

Prepared on 14 November 2026 in Asia/Rangoon.

This folder contains Markdown versions of the supplied team scope and KE2 work plan, with task checklists and a shared progress record.

| Document | Use |
| --- | --- |
| [Team scope v2](team-scope-v2.md) | Five presets, team responsibilities, schedule, and release acceptance |
| [KE2 work plan](ke2-work-plan.md) | KE2 tasks and subtasks, original task IDs, and completion criteria |
| [KE1/SE configuration handoff](ke1-se-config-handoff.md) | Task 00.2 draft with proposed IDs, fields, compatibility, examples, and open decisions |
| [KE2 review of KE1 K20](k20-ke2-interface-review.md) | IDs/goal meanings and four interface choices confirmed by KE1 per user report, with artifact receipt and remaining integration tracked separately |
| [KE3 reports and A/B response](ke3-ke2-results-ab-handoff.md) | Current evaluator responses, eight reproducible engine executions, proposed goal reports, exact A/B identities and signed measurements, and remaining owner handoffs |
| [HPC evidence handoff](hpc-evidence-handoff.md) | Task 00.3 field trace, existing run excerpt, Communication payload proposal, and requests for HPC |
| [Progress record](progress.md) | Starting revision, verification evidence, open decisions, handoffs, and completion history |

## Updating task status

- Use `[ ]` for unfinished work and `[x]` for completed, verified work.
- After completing a subtask, tick its checkbox and record the result in the progress record during the same work session.
- Tick a parent task after its subtasks and stated completion criteria are satisfied.
- For work in progress or a dependency, keep the checkbox open and record its status, owner, and next action in the progress record.
- Identify the verification level as source inspection, fixture, integrated Godot modules, local export, or public browser build. A completed fixture subtask can coexist with an open integration subtask.
- If a later check disproves a completed result, reopen the affected checkbox and record the failure and next action.
- Use the KE2 plan for detailed KE2 status. Update the corresponding team checklist when its team-level deliverable is complete.
- Record test commands, revision, expected and actual results, and relevant run/event IDs when completing implementation tasks.

The initial completed items describe baseline inspection and documentation already performed. Expansion implementation and acceptance items start open.

## Planning baseline

The inspected checkout is `features/KE2` at `4c65496`. The last full run on that revision passed all 38 active check programs. Imaging evaluation and the existing Retry/Modify design flow are implemented. Survey delivery counters exist, while Survey evaluation, Communication, Weather Monitoring, and explicit A/B comparison are pending.

Existing behavior follows the [signed team agreement](../team-agreement.md), [technical contracts](../contracts.md), [validation plan](../validation-plan.md), and [source ledger](../sources.md). Proposed expansion fields, score weights, thresholds, and handoff details retain their proposal status until coordinated with the affected owners.

## Sources and conversion notes

The Markdown plans retain the PDFs' mission names, ownership, schedules, acceptance requirements, and provisional thresholds. KE2 task numbers `00.1` through `50.9` are retained. Team checklist IDs were added for tracking. The PDF wording that assigns KE1's role to its reader is represented as KE1 ownership.

The eight-hour schedule is an elapsed planning target. Its clock starts when the team starts the expansion.

Original source files are recorded below.

- [Five Missions + A/B Design Lab Team Scope v2](<C:/Users/Min Sett Paing/Downloads/Telegram Desktop/OrbitBridge_Five_Missions_AB_Design_Lab_Team_Scope_v2.pdf>), six pages, dated 14 November 2026.
- [KE2 Expansion Work Plan](<C:/Users/Min Sett Paing/AppData/Local/Temp/codex-file-preview-s6Hz0M/OrbitBridge_KE2_Expansion_Work_Plan.pdf>), eight pages. Its original copy is in a temporary preview folder. The complete work breakdown is retained here in Markdown.

The following clarifications from the repository review are added explicitly to the checklists.

- Weather counts distinct revolutions using a revolution index or an agreed step mapping. Existing `orbit_id` identifies a preset such as `high_inc`.
- Survey's three-way score weighting and the new count/data weights remain proposed expansion rules. Existing Imaging scoring stays compatible.
- Agree exact config/report fields and update their producers, validators, consumers, examples, and checks together.
- Save A uses the actually completed active execution and its bound report. Runtime can prepare a future terminal policy trace before playback reaches completion.

## Suggested first deliverable

After the initial contract work, produce the Survey case where both aggregate goals are met but one of two selected targets has no complete delivery. The proposed three-way weighting gives `partial` and score `83`. Label fixture evidence and then verify the corresponding real engine run with HPC and KE3.
