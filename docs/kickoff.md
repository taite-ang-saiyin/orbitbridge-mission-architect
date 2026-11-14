# Kickoff, ownership, and handoffs

Team schedule: Saturday 14 November 2026, 09:00 to Sunday 15 November, 18:00. Planned submission by Sunday 17:00. Times are Asia/Rangoon, following the user-supplied proposal. These are team planning times, not independently verified organizer deadlines.

Preparation status and owner-specific questions: [pre-kickoff review](pre-kickoff-review.md). The user confirmed Godot 4.7.2, successful assistant checks, and the 09:00 kickoff. Final demo format can be selected after the first working slice. v1.0-agreed is signed by all five roles; Compatibility is agreed and SE owns the main/master settings sync. Review [the all-role team agreement](team-agreement.md).

K01-K04 are recorded complete in tasks.md. [kickoff-progress.md](kickoff-progress.md) now records the agreement and technical/example synchronization.

## First hour

1. Confirm the team has started implementation and update workspace phase.
2. Use the already cloned team repository and existing project.godot. Confirm the same exact Godot version on all machines. Standard and .NET editions are compatible for the agreed GDScript-only code. Current repository setup is Windows/Forward Plus. If Web should remain an option, agree compatible rendering/features with SE early; choose final demo packaging after the first working slice.
3. Agree one observation objective family, minimum parts, two launch/profile choices, and two orbit presets if scope needs shrinking.
4. KE1, SE, HPC, and KE2 review contracts.md. Resolve field names, units, profile mapping, essential power, target suitability, and error structure.
5. Record the agreed contract version by 10:30. Start small implementation slices and exchange real examples early.

## Suggested project layout after kickoff

project.godot, the initial icon, Git setup, and preparation documents already exist in the cloned repository. The gameplay folders/scripts below are proposed and not implemented. SE owns project-shell changes.

```text
project.godot                         SE
AGENTS.md                            shared guidance
tasks.md                             KE1 work tracking
docs/                                shared contracts and sources
scenes/                              SE and KE3
scripts/core/mission_state.gd        SE/shared state, confirm owner
scripts/core/mission_validator.gd    KE1
scripts/core/catalog_loader.gd       KE1, if needed
scripts/simulation/                  HPC
scripts/evaluation/                  KE2
data/components.json                KE1
data/launch_profiles.json            KE1, proposed
data/launchers.json                  KE1, proposed
data/orbits.json                     HPC authors; KE1 reads compatibility
data/nasa_sources.json               KE2 maintains; KE1 supplies rule evidence
tests/validation/                    KE1
tests/fixtures/                      KE1 handoff examples
```

## Handoffs

| When | From -> to | Concrete deliverable |
| --- | --- | --- |
| Saturday 10:30 | KE1 + SE + HPC + KE2 | Agreed contract, units, IDs, validation interface |
| Saturday 13:00 | KE1 -> SE + HPC | Valid config, overweight config, callable validator and result shape |
| Saturday 13:00 | KE1 -> KE2 | Source title/URL/locator, threshold and comparator, profile ID, credit wording |
| Saturday 16:30 | All logic + UI owners | Config passes through readiness, simulation, and result screen |
| Saturday 22:00 | KE1 -> team | Stable validation, test evidence, outstanding blockers |
| Sunday 11:00 | All | Acceptance scenarios in the complete player journey |
| Sunday 14:00 | All | Feature freeze |
| Sunday 17:00 | All | Submission verification target |

## Working with both assistants

Use Codex and Antigravity on one task at a time in the same checkout, or give them explicitly disjoint files. Keep task status and a short handoff in this folder. Do not let two assistants rewrite contracts, catalogs, or the validator concurrently. A separate branch alone does not isolate files in the same checkout.

Suggested first request after kickoff:

> Kickoff has started. Read AGENTS.md, tasks.md, and docs/contracts.md. Check the existing team project and confirm the agreed contract. Implement the smallest KE1 schema/catalog/validator slice with a valid fixture and a structured failure. Keep the simulator and UI under their owners. Run the available headless validation tests, update task evidence, and report any contract decisions still needed.

## Decision log

| Decision | Status | Owner |
| --- | --- | --- |
| Team repository and actual Godot project location | CLONED: https://github.com/taite-ang-saiyin/orbitbridge-mission-architect.git; open this repository root | User-selected; SE coordinates |
| Delivery target / renderer | Compatibility/GDScript agreed; SE handles main/master sync and early export check; final packaging may wait | SE + all |
| Exact Godot editor/export-template version | USER CONFIRMED: Godot 4.7.2; matching template installation pending | User; SE coordinates templates |
| Local kickoff time/timezone | USER CONFIRMED: 14 Nov, 09:00 Asia/Rangoon | User confirmation |
| Config v1 field names, units, and ranges | AGREED in v1.0-agreed; contracts.md and examples synchronized | KE1 + SE + HPC + KE2 |
| Separate launcher and launch_profile selections | AGREED: separate IDs | KE1 + SE |
| Essential-power pre-launch rule | AGREED: illustrative positive battery/reserve and solar >= baseline gate | KE1 + HPC |
| Target/orbit feasibility policy | AGREED IDs low_eq/high_inc/equator; actual preset data authored by HPC | KE1 + HPC + KE2 |
| Sample mass source verified and credited | SOURCE VERIFIED: printed p.79 / PDF p.87; implementation and credits pending | KE1 + KE2 |
| Local KE1 kickoff work | K01-K04 COMPLETE per agreement/tasks; K05 next; no production gameplay code yet | User confirmation and signed agreement |
| Interface example pack | ALIGNED TO v1.0-agreed; legacy v1-draft folder name retained for links | KE1 synchronization |

## Reduced-scope fallback

One customizable observation family; two orbit presets; two instruments; one sample 1U profile and one illustrative alternative; minimal observation/downlink loop. Keep source-backed mass readiness, clear feedback, and retry. Drop extra objective types, detailed orbital physics, and visual polish before cutting learning feedback.
