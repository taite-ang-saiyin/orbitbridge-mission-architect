I've opened a Work task to generate your second PDF: OrbitBridge KE2 — Step-by-Step Hackathon Implementation Playbook. It will include the complete development schedule, detailed tasks, acceptance tests, integration checkpoints, NASA verification, and copy-ready Codex prompts.

You can also use the following sequence directly when the hackathon begins on Saturday, November 14, 2026, at 9:00 AM Myanmar time.

## 1. Your development sequence

| Time (Myanmar)        | Task                                        | Codex prompt |
| --------------------- | ------------------------------------------- | ------------ |
| Sat 9:00–10:30 AM     | Inspect project and agree on data contracts | Prompt 1     |
| Sat 10:30–11:00 AM    | Set up evaluation module                    | Prompt 2     |
| Sat 11:00 AM–12:00 PM | Implement mission scoring                   | Prompt 3     |
| Sat 12:00–1:00 PM     | Implement evaluator tests                   | Prompt 4     |
| Sat 1:45–3:30 PM      | Implement explanations and suggestions      | Prompt 5     |
| Sat 3:30–4:30 PM      | Prepare NASA source ledger                  | Prompt 6     |
| Sat 4:30–6:00 PM      | Integrate with HPC                          | Prompt 7     |
| Sat 6:00–7:00 PM      | Integrate with KE3                          | Prompt 8     |
| Sat 7:45–9:15 PM      | Implement retry comparison                  | Prompt 9     |
| Sat 9:15–10:00 PM     | Test and stabilize                          | Prompt 10    |
| Sun morning           | Full integration and acceptance testing     | Prompt 11    |
| Sun afternoon         | Export verification and submission          | Prompt 12    |

These times are working targets, not rigid limits. Prioritize the playable mission-to-results loop over optional features.

## 2. Copy-ready Codex prompts

Use these prompts one at a time. Review Codex's changes and test results before proceeding.

### Prompt 1 — Project inspection and architecture

Saturday · 9:00–10:30 AM

```

I am KE2 of the OrbitBridge NASA Space Apps Challenge 2026 team.

My responsibilities:
- Mission evaluation and scoring
- Success/partial-success/failure classification
- Evidence-based mission explanations
- Corrective-action recommendations
- Retry comparison
- NASA source documentation
- Automated tests

Our game uses Godot 4 and GDScript.

First, inspect the existing project structure, scripts, data models, and integration points.

Identify:
1. Where mission goals are stored.
2. Where HPC simulation results are produced.
3. How mission events and reason codes are represented.
4. How KE3's Results screen receives data.
5. Which evaluation-related files already exist.
6. Existing testing conventions.

Do not modify any files yet.

Propose:
- My owned files and functions.
- Required input/output dictionaries.
- The integration contract with KE1, HPC, and KE3.
- Any missing fields or incompatible interfaces.
- A minimal implementation order.

Respect file ownership. Do not modify other team members' files without coordination.

Report findings before implementation.

```

Expected result: A documented interface agreement and your confirmed file responsibilities.

### Prompt 2 — Evaluation module setup

Saturday · 10:30–11:00 AM

```

Set up the OrbitBridge KE2 evaluation module in Godot 4 using the agreed architecture.

Primary file:
res://scripts/evaluation/mission_evaluator.gd

Requirements:
1. Implement a reusable evaluator callable without a scene.
2. Accept structured Dictionary inputs.
3. Return a structured MissionReport Dictionary.
4. Do not depend on the Results UI.
5. Allow mock data until HPC integration.
6. Use named keys and documented units.
7. Avoid unnecessary global state and Autoloads.

Use existing project conventions where possible.

Only create or modify KE2-owned files.

Verify that the script parses correctly in the project's Godot version.

Show the file changes and explain how the evaluator will be called.

```

### Prompt 3 — Success criteria and scoring

Saturday · 11:00 AM–12:00 PM

```

Implement the mission scoring logic in mission_evaluator.gd.

Inputs:
- Required observations
- Required returned data in MB
- Completed observations
- Data successfully received on Earth in MB
- Simulation terminal status

Proposed verdict rules:
- SUCCESS: both requirements are met.
- PARTIAL_SUCCESS: at least one requirement has progress, but not all requirements are met.
- FAILED: no progress toward either requirement.
- Pre-launch rejection belongs to KE1, not the completed-mission evaluator.

Proposed score:
Score = 100 * average of the two completion ratios, each capped at 1.

Requirements:
1. Reaching a threshold counts as meeting it.
2. Extra progress must not increase the score above 100.
3. Stored data must not count as returned data.
4. Reject or explicitly handle invalid/negative inputs.
5. Define and document handling for zero targets.
6. Treat an aborted run separately according to the team-agreed rule.
7. Keep calculations deterministic.

Return verdict, score, actual values, targets, completion percentages, and relevant status fields.

Use the existing agreed data contract.

Do not implement UI or simulation physics.

Run a minimal Godot verification and report the results.

```

### Prompt 4 — Independent automated tests

Saturday · 12:00–1:00 PM

```

Create independent automated tests for the OrbitBridge mission evaluator.

Use the project's existing Godot 4 testing conventions. If no test framework exists, implement a lightweight test runner using assertions.

Test scenarios with required targets of 3 observations and 30 MB:

T01: 3 observations, 30 MB -> SUCCESS, 100.
T02: 3 observations, 10 MB -> PARTIAL_SUCCESS, about 67.
T03: 3 observations, 0 MB -> PARTIAL_SUCCESS, 50.
T04: 0 observations, 0 MB -> FAILED, 0.
T05: 4 observations, 30 MB -> SUCCESS, 100.
T06: target changed to 4 observations, actual 3, returned 30 MB -> PARTIAL_SUCCESS, about 88.

Also test:
- Invalid negative values.
- Zero requirements.
- Extra observations and returned data.
- Terminal abort behavior.
- Repeated identical inputs producing identical results.

Do not modify other owners' scripts.

Run the tests, report each result, and explain any failures.

```

### Prompt 5 — Explainable feedback engine

Saturday · 1:45–3:30 PM

```

Implement the OrbitBridge KE2 feedback engine.

Use:
res://scripts/evaluation/mission_feedback.gd
or the existing KE2 module if the project has a simpler structure.

The engine must explain:
1. What happened.
2. Why it happened, using recorded evidence.
3. What the player can try on the next attempt.

Proposed simulator reason codes:
- NO_LINK_WINDOW
- LOW_BATTERY
- STORAGE_FULL
- TARGET_NOT_VISIBLE

Confirm actual HPC codes before integration.

For each recognized event, provide:
- Human-readable cause
- Relevant mission segment (launch, space, ground, or user)
- Evidence reference, where available
- Specific corrective action

Rules:
- Never invent a cause.
- Distinguish stored data from returned data.
- Prioritize causes relevant to unmet objectives.
- If evidence is insufficient, provide neutral feedback without asserting an unsupported cause.
- Use deterministic templates, not an LLM.
- Return structured fields suitable for KE3.

Include tests for recognized, unknown, and missing events.

Keep this module independent of frontend scenes.

```

### Prompt 6 — NASA source ledger

Saturday · 3:30–4:30 PM, or earlier if convenient

```

Prepare the NASA source record for the OrbitBridge project.

Primary reference:
NASA CubeSat 101 — Basic Concepts and Processes for First-Time CubeSat Developers.

Source URL:
https://science.nasa.gov/wp-content/uploads/2023/06/nasa_csli_cubesat_101_508.pdf

Relevant section:
Appendix 6 — 1U CubeSat Acceptance Checklist, printed page 79.

Sample mass criterion:
Mass < 1.33 kg, equivalent to mass < 1330 g.

This is a strict threshold:
1329 g passes this mass check.
1330 g fails.

The criterion applies to OrbitBridge's sample 1U educational profile, not universally to all satellites.

Inspect existing source records and create or update the KE2-owned ledger only.

Record:
- Source title
- NASA organization
- Source URL
- Section/page
- Original value and unit
- Converted value and unit
- Applicable profile
- In-game implementation location
- Attribution text
- Verification status

Also record other NASA resources actually used.

Do not claim a source is integrated until the corresponding gameplay feature is verified.

Do not modify KE1's validator or SE's Builder without coordination.

Provide the exact source credit for the submission owner.

```

### Prompt 7 — Integrate actual HPC simulation results

Saturday · 4:30–6:00 PM

```

Integrate KE2's mission evaluator with the actual HPC simulation output.

First inspect the current simulator code, output schema, and existing integration tests.

Compare the actual HPC fields with our agreed evaluator contract.

Implement the smallest required adapter inside KE2-owned code.

Requirements:
1. Read actual completed observations.
2. Read actual data received on Earth.
3. Read relevant stored data for explanation only.
4. Read mission termination status.
5. Read recorded event reasons.
6. Read the player's current mission targets.
7. Pass these inputs to the existing evaluator.
8. Return one complete MissionReport Dictionary.

Do not change HPC simulation physics.
Do not duplicate mission calculations.
Do not rewrite HPC-owned code without team approval.

Test with one real completed simulation and one recorded failed/blocked action.

Report any missing fields or contract mismatch clearly.

```

### Prompt 8 — KE3 Results screen integration

Saturday · 6:00–7:00 PM

```

Prepare the MissionReport output for integration with KE3's Results screen.

Inspect the actual existing Results UI contract before making changes.

The evaluator should expose:
- Verdict
- Overall score
- Actual/required observations
- Actual/required returned MB
- Completion percentages
- Cause code
- Human-readable explanation
- Recommended next action
- Optional retry comparison

Ensure the report uses consistent key names and types.

Do not create or redesign the Results screen.
Do not move scoring rules into frontend code.

Write a short handoff note with:
1. Example MissionReport.
2. Meaning of every field.
3. Which fields can be missing or null.
4. How to call the evaluator.
5. How to display an absent comparison.
6. How to avoid stale results after resetting.

Run an integration test if KE3's scene is available.

Only modify KE2-owned files unless coordinated.

```

### Prompt 9 — Retry comparison engine

Saturday evening · Optional after P0 stability

```

Implement the OrbitBridge retry comparison logic.

Suggested file:
res://scripts/evaluation/mission_comparison.gd

Inputs:
- Previous MissionReport
- Current MissionReport
- Scenario identifiers and settings
- Relevant design/operation choices, if available

Outputs:
- Observation difference
- Returned-data difference in MB
- Score difference
- Previous and current verdicts
- Changed parameter, if known
- Short learning reflection
- Comparison validity indicator

Requirements:
1. If no previous attempt exists, omit comparison.
2. Use the same mission targets and scenario for controlled comparison.
3. Do not claim causal improvement if several variables changed.
4. Represent improvements and regressions correctly.
5. Preserve the original reports.
6. Do not use random or nondeterministic explanations.

Test 10 MB -> 30 MB and 30 MB -> 10 MB.

Add tests for changed requirements, missing previous reports, and identical attempts.

Do not modify KE3-owned UI files.

```

### Prompt 10 — Saturday stability tests

Saturday · 9:15–10:00 PM

```

Perform a focused stability review of the OrbitBridge KE2 implementation.

Scope:
- Mission evaluation
- Scoring
- Feedback mapping
- MissionReport generation
- Retry comparison, if implemented
- NASA source record

Tasks:
1. Inspect the git diff for KE2-owned files.
2. Run available Godot tests.
3. Check for parse and runtime errors.
4. Confirm dynamic mission targets work.
5. Verify unknown simulator events are handled.
6. Verify identical inputs give identical results.
7. Verify no unintended changes to other owners' files.
8. Identify blockers for the full mission loop.

Do not introduce new features.

Fix critical KE2 defects only.

Produce a concise report with passed tests, failed tests, unresolved issues, and exact integration needs for Sunday.

```

### Prompt 11 — Sunday acceptance testing

Sunday · 8:30 AM–2:00 PM

```

Perform end-to-end acceptance testing for OrbitBridge's mission evaluation and educational feedback.

Follow the actual player journey:
Mission Creator -> Builder -> Validation -> Simulation -> Results -> Retry.

Verify:
1. SUCCESS case.
2. PARTIAL_SUCCESS case.
3. FAILED case.
4. Dynamic mission target changes.
5. Stored data not counted as returned data.
6. Feedback matches simulator event evidence.
7. Retry comparison under unchanged conditions.
8. Mission reset without stale values.
9. NASA 1U boundary at 1329 g and 1330 g.
10. Source credit visible in the game.

Check the actual runtime and UI behavior, not just isolated functions.

Do not modify another owner's files without approval.

Document defects with reproduction steps, expected behavior, actual behavior, and the responsible owner.

Fix KE2 defects only.

Respect the Sunday 2:00 PM feature freeze.

```

### Prompt 12 — Final verification and submission support

Sunday · 2:00–5:00 PM

```

Perform final release verification for OrbitBridge KE2.

Do not add new gameplay features.

Review the exported game and confirm:
- Mission results are correct.
- The verdict matches the underlying progress.
- The explanation matches recorded evidence.
- Retry recommendations are actionable.
- Comparison values are accurate, if present.
- NASA CubeSat 101 mass check is visible.
- NASA source attribution is accurate.
- Educational assumptions are not described as flight-certified physics.

Prepare a submission note containing:
1. What KE2 implemented.
2. How mission scoring works.
3. How feedback relates to simulator evidence.
4. How retries teach engineering trade-offs.
5. Which NASA sources were actually used.
6. Where the CubeSat 101 rule appears.
7. Known limitations.

Run the final available tests and report failures without hiding them.

Provide a concise release checklist for the submission owner.

```

## 3. How to use Codex effectively during the hackathon

The most important practice is to use one bounded development task per Codex prompt. Do not ask Codex to implement the entire KE2 system in one operation.

At each stage, inspect its changes, run the tests, and commit stable work before moving to the next stage. Keep the agreed input/output contract unchanged unless all affected members approve an update.

Your most important milestones are:

- By 1:00 PM Saturday: evaluator and basic tests work with mock data.
- By 4:30 PM Saturday: explanation rules and source record are ready for integration.
- By 10:00 PM Saturday: at least one real simulation produces a correct, visible debrief.
- By 2:00 PM Sunday: evaluation and feedback are tested and feature-frozen.
- Before 5:00 PM Sunday: exported build and NASA attribution are verified.

The full PDF task has been handed off to Work, including these copy-ready prompts and detailed acceptance criteria.