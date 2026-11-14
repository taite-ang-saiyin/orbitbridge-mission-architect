# KE2 documentation

Owner KE2. Updated 14 November 2026 against `v1.0-agreed`.

KE2 owns mission evaluation, scoring, evidence-based explanations, corrective experiments, optional retry comparison, NASA source records, and evaluator tests.

## Documents

| Document | Contents |
| --- | --- |
| [Evaluation and feedback](evaluation-and-feedback.md) | Public methods, input requirements, scoring, aborts, reason codes, and evidence selection |
| [Integration handoff](integration-handoff.md) | KE1/HPC/SE/KE3 responsibilities, invocation, every report/error field, display guidance, and a recorded report |
| [HPC runtime integration](hpc-integration.md) | Native-state adapter, actual field mapping, pinned producer revision, completed/blocked/aborted checks, and reproduction commands |
| [Testing](testing.md) | Headless commands, recorded results, acceptance cases, and pending integration checks |
| [NASA sources and credits](nasa-sources.md) | Human-readable source records, strict sample mass criterion, attribution, and verification status |
| [Member replies and requests](team-requests.md) | Copy-ready SE, KE3, KE1, and HPC messages with required handoff evidence |
| [Offline SE controller handoff](../handoffs/ke2-se-controller-v0.1/README.md) | Current source/trace package, working-tree hashes, Survey guard, and standalone verification |
| [Actual operator-abort handoff](../handoffs/ke2-hpc-abort-v0.1/README.md) | Verified input, report, 71 current-evaluator/pinned-replay checks, and SE/KE3 consumption |
| [KE2 checklist](../ke2-todo.md) | Completed work, subtasks, dependencies, and remaining acceptance work |

## Implementation status

| Area | Available evidence | Remaining work |
| --- | --- | --- |
| Evaluator | Scene-independent module, deterministic scoring, validation, abort handling, candidate integrated invocation | Selected-release acceptance and Survey extension agreement |
| Feedback | Four recognized blocked-action codes, event references, corrective templates, neutral fallback, verified `terminal_reason` mapping, reviewed KE3 preview display | Original partial/abort packets through the selected-release Results route |
| Automated checks | 167 standalone, 207 pinned combined, 71 abort replay, and 57 candidate Results/lifecycle checks pass | Comparison/readiness cases and final release acceptance; standalone runner retains five pending labels |
| HPC integration | Native-state adapter, actual readiness-approved run/block/abort, candidate Results publication and retry/reset checks | Manual action controls and selected-release verification |
| NASA documentation | JSON ledger, verified PDF/conversion, independently rerun 470-check readiness fixture suite, preview and candidate scoped-credit binding | Builder boundaries/profile switching and export credits |
| Retry comparison | Reserved baseline parameter and `comparison: null` | Optional P1 implementation and eligibility tests |

The detailed verification history is in the testing document and the existing report handoff. [Testing](testing.md), [recorded HPC report](../handoffs/ke2-hpc-report-v0.1.md).

The latest Results evidence belongs to the isolated candidate `tmp/se-ke2-integration` at `14c0f97`, with implementation `b23de72`. Its KE2 module/test bytes match the root at `c1ce6de`. Prompt 10 is complete with zero failing checks and no critical KE2 defect found. The review reran the existing suites and updated the ledger's independent validator evidence. Prompt 9 remains optional comparison work. Manual actions, Survey scoring, Builder boundary checks, official B10 and exported-build acceptance remain pending. [Stability report](testing.md#prompt-10-stability-review).

## Owned implementation files

| File | Responsibility |
| --- | --- |
| [mission_evaluator.gd](../../scripts/evaluation/mission_evaluator.gd) | `evaluate_mission`, native `evaluate_hpc_state` adapter, and explicit mock-report helper |
| [mission_feedback.gd](../../scripts/evaluation/mission_feedback.gd) | `MissionFeedback.build_feedback` and `explain_event` |
| [test_mission_evaluator.gd](../../tests/test_mission_evaluator.gd) | Independent headless assertions and pending-case reporting |
| [nasa_sources.json](../../data/nasa_sources.json) | Source metadata, attribution, implementation evidence, and verification status |

The optional `scripts/evaluation/mission_comparison.gd` remains a planned KE2 path.

## Contract references

The signed agreement and technical contract govern shared fields, units, ownership, and lifecycle. The example directory retains its `v1-draft` name and contains the synchronized v1 reference dictionaries. [Team agreement](../team-agreement.md), [contracts](../contracts.md), [reference dictionaries](../contracts/v1-draft/README.md), [validation plan](../validation-plan.md).
