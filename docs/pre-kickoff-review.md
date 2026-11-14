# KE1 preparation review and team decisions

Historical preparation review, prepared 14 November 2026. Current status: user-authorized local KE1 K01-K04 work is underway; see [kickoff-progress.md](kickoff-progress.md). This is a local review packet; no teammate has signed off through this chat and nothing has been sent to them.

Current update: the user confirms all five roles approved team-agreement.md v1.0-agreed. contracts.md and the examples are now synchronized; K01-K04 are complete. The review observations below are historical, not unresolved approval blockers. Actual renderer branch sync and production catalog/adapter implementation remain separate work.

## Confirmed facts

| Item | Evidence/status |
| --- | --- |
| Editor version | User confirmed team version is Godot 4.7.2 in this chat |
| Local editor | Downloaded Standard 4.7.2; official SHA512 matched; direct executable version check passed |
| Team repository | User selected the cloned orbitbridge-mission-architect repository; initial project.godot already exists |
| Language | Repository plans GDScript; user understands Standard/.NET collaboration works for GDScript-only code |
| Existing renderer | project.godot currently declares Forward Plus and Windows d3d12 |
| Repository target | README currently identifies offline Windows as primary |
| Earlier proposal target | Browser delivery with Compatibility; a team decision is still needed to reconcile this |
| Kickoff | User confirmed 09:00; schedule is 14 November 2026 at 09:00, Asia/Rangoon |
| Assistant checks | User confirmed Codex and Antigravity checks successful |
| NASA sample mass rule | Source verified: CubeSat 101, Appendix C, item 6, printed p.79 / PDF p.87; strictly below 1.33 kg |

Do not treat the passage of scheduled kickoff time as an instruction to start game implementation. The user/team must indicate that kickoff has begun.

## Assistant readiness

Codex, in the current chat, read the actual root AGENTS.md, README.md, tasks.md, contracts, validation plan, kickoff notes, and tool setup. The verified understanding is:

- Phase is PREPARATION; an existing project shell is present and must not be recreated.
- User is KE1: schema, catalog, design metrics, and pre-launch readiness.
- HPC owns operations/simulation, KE2 owns evaluation/feedback, and SE/KE3 own the screens.
- The validator is planned as a deterministic, scene-independent function. The UI reads its result.
- Sample 1U mass is strictly below 1330 g; passing mass alone is insufficient for launch readiness.
- Contract names, power rules, target suitability, and other draft choices still require team review.
- Game implementation, executable fixtures, and tests have not started.

The user subsequently confirmed the assistant checks are successful. Mark the Codex/Antigravity preparation item complete on that user confirmation; this is distinct from an independently observed UI verification by this chat.

Antigravity launched during the earlier check; UI control then stopped with Escape. The user later confirmed both assistant checks are successful, so this is no longer an outstanding preparation task.

For future rechecks after changing instructions or switching workspaces, use this read-only prompt:

> Read the root AGENTS.md and GEMINI.md where applicable, README.md, tasks.md, docs/contracts.md, and docs/kickoff.md. Do not edit files or implement the game. State the current phase from AGENTS.md/tasks.md, my role, existing project status, confirmed editor version, open team decisions, and who owns simulation and evaluation. Confirm that the sample 1U mass check rejects exactly 1330 g. List the instruction files you actually read. Distinguish automatically discovered instructions from files explicitly requested by this prompt.

Accept the response only if it accurately states the current phase from AGENTS.md/tasks.md, KE1 scope, existing project shell, Godot 4.7.2, and the unresolved delivery/power/contract decisions. Record the result in tasks.md. A general claim that the app works is not an instruction-discovery test.

## Local contract review completed

The draft was reviewed against the current repository overview, team proposal, validation plan, source ledger, and ownership boundaries. This is a technical preparation review by Codex, not team approval or runtime validation.

| Finding | Draft recommendation | Team owner |
| --- | --- | --- |
| Proposal's config example omits several selected subsystems and a returned-data target | Keep every required component slot, profile selection, and returned-data threshold explicit | KE1 + SE + HPC + KE2 |
| Naming varies between camera/instrument and budget/budget_credits | Choose one name per field before coding; draft proposes instrument_id and budget_credits | KE1 + SE |
| Profile and launcher have different meanings | Keep separate IDs unless SE chooses a documented mapping; a launcher capacity check does not replace the profile rule | KE1 + SE |
| Partial designs can lack valid arithmetic inputs | Report null/unavailable metrics and not_evaluated dependent checks, rather than zero mass or a successful check | KE1 + SE |
| Mass boundary is strict while capacity/budget need separate comparisons | Use <1330 g for the sample profile; proposed <= for budget and launcher payload capability | KE1 + SE |
| Wrong profile can accidentally inherit the sample limit | Resolve the selected profile's own rule and source/assumption ID | KE1 |
| Integer fields can be parsed as floating-point JSON numbers | Accept finite whole numeric values for integer semantics; reject fractions, booleans, strings, null, negative/zero values where invalid | KE1 + HPC |
| Per-step radio rate depends on simulator time | Agree steps per orbit and step_duration_hours; keep MB/step consistent with HPC's accounting | KE1 + HPC |
| A positive sunlit power margin does not prove energy sufficiency | Define the static launch-blocking power rule separately from dynamic energy depletion; keep shortcuts labeled as assumptions | KE1 + HPC |
| Captured observations and fully delivered observations can mean different success metrics | Define required_observations precisely with KE2; returned-data MB remains an explicit independent requirement | KE1 + HPC + KE2 |
| Requested targets need both static suitability and runtime access windows | KE1 reads agreed compatibility metadata; HPC owns the actual observation/contact windows | KE1 + HPC |
| IDs and metadata can diverge across owners | Freeze shared IDs and source/assumption fields in the contract; HPC authors orbit metadata, KE1 reads it | KE1 + HPC + KE2 |
| Score/status and readiness are separate concepts | KE1 returns feasibility; KE2 evaluates successful, partial, and failed runs | KE1 + KE2 |

The proposed agreement for all five members is [team-agreement.md](team-agreement.md). It includes concrete proposals and blank approval records. Final demo packaging may wait until the first working slice; early renderer/features review is still needed if browser support should remain possible.

## Team review checklist

Each line is a proposed decision requiring an actual response. Leave Confirmed by and Decision blank until the named teammate or user supplies the answer.

| ID | Decision needed | Owner | Proposed starting point | Confirmed by / decision |
| --- | --- | --- | --- | --- |
| D01 | Exact editor version | Team/user | 4.7.2 | User confirmed 4.7.2 |
| D02 | Local kickoff time and timezone | Team/user | 14 Nov, 09:00 Asia/Rangoon | User confirmed 09:00 |
| D03 | Delivery target and renderer | SE + team | Current repo: Windows / Forward Plus; decide whether Web is required | PENDING |
| D04 | All config names, required slots, version, ranges, and IDs | KE1 + SE + HPC + KE2 | contracts.md v1 draft | PENDING |
| D05 | Separate launch_profile_id and launcher_id | KE1 + SE | Keep separate | PENDING |
| D06 | Step duration, steps/orbit, radio rates, and orbit table ownership | KE1 + HPC | Explicit hours per step; shared orbit IDs | PENDING |
| D07 | Essential-power readiness rule and dynamic energy ownership | KE1 + HPC | Static readiness defined explicitly; simulation owns time evolution | PENDING |
| D08 | Meaning of required_observations and returned-data goal | KE1 + HPC + KE2 | Separate captured/returned metrics; document the success requirement | PENDING |
| D09 | Target/orbit static feasibility versus runtime opportunities | KE1 + HPC + KE2 | Shared suitability table; HPC window lookup | PENDING |
| D10 | UI error shape, ordering, and unavailable metrics | KE1 + SE | Structured issues and null/not_evaluated where calculation cannot proceed | PENDING |
| D11 | NASA source record and visible credit | KE1 + KE2 + SE | Sample rule <1330 g, source ID, profile label, actual source locator | PENDING |

## First-hour review agenda

1. SE confirms D02-D03 and that everyone uses 4.7.2. Avoid spending coding time reconciling editor or target differences.
2. KE1 walks the team through required config fields and one hypothetical passing/over-mass design. Create real fixture files after kickoff.
3. HPC resolves D06-D09 and confirms the validator output it will consume.
4. KE2 resolves observation/data semantics and confirms the source/feedback handoff.
5. SE confirms required UI metrics and issue formatting. Record every agreed change in contracts.md and the decision log.
6. Freeze the actual agreed contract by the proposal's 10:30 milestone. No draft is automatically accepted just because the document exists.

## Ready versus pending

Local readiness: verified editor, confirmed 4.7.2 version, prepared instructions, local contract review, test plan, source evidence, and this review packet.

Assistant checks and 09:00 kickoff are now user-confirmed. Pending: delivery/renderer decision, actual SE/HPC/KE2 contract review, graphical Godot check, and matching export templates. No messages have been sent to teammates and no game tests have been claimed as passing.
