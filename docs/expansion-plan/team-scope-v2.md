# Five Missions and A/B Design Lab Team Scope v2

Source date is 14 November 2026. This is the Markdown tracking version of the six-page team scope. Final goal values and handoff details remain proposals for team review.

Use the [progress record](progress.md) for evidence and handoffs. Detailed KE2 completion status lives in the [KE2 work plan](ke2-work-plan.md).

- [x] **KE2 independent candidate, 15 November:** implement and verify callable expanded evaluation, goal reports/feedback, immutable execution-record helpers and analytical comparison. [Delivery, exact checks and owner dependencies](ke2-integration-candidate.md). This completes KE2's isolated candidate; team production promises below remain open pending ratification and real producer/runtime/presentation integration.

## Product promise and delivery

Players design a spacecraft, run a mission, understand the result, change one design choice, and measure what improved.

The player flow is Choose mission -> Build A -> Check readiness -> Run -> Save A -> Modify design -> Run B -> Compare -> Improve again.

- [ ] TEAM.1 Deliver five mission presets using four goal types.
  - [ ] Preserve Estuary Watch, Tropical Forest Watch, and Polar Ice Survey.
  - [ ] Add Communication and Weather Monitoring.
- [ ] TEAM.2 Connect an A/B Design Lab for every preset.
  - [ ] Save a completed run as A.
  - [ ] Create and run modified design B.
  - [ ] Compare actual reports, evidence, resource measures, cost, and mass.
- [ ] TEAM.3 Present useful explanations.
  - [ ] Identify missed goals and relevant mission events.
  - [ ] Suggest a feasible next experiment supported by the run.
- [ ] TEAM.4 Release the single-player browser game through the existing Netlify site.
  - [ ] Confirm the actual site URL and deployed revision with SE.
  - [ ] Verify missions and comparison through the public browser build.

The scope contains five named presets across Imaging, Survey/Mapping, Communication, and Weather Monitoring. Additional Earth Observation or Mapping presets, accounts, online rooms, multiplayer, AI chat, live forecasts, and full GMAT integration are outside this delivery. This v2 supersedes the earlier four-mission and multiplayer proposals.

## Five presets and their goals

| Preset | Goal | Evaluation |
| --- | --- | --- |
| Estuary Watch | Preserve coastal Imaging setup and configured capture/data goals | Existing Imaging evaluation with its own target and schedule |
| Tropical Forest Watch | Preserve forest Imaging setup and configured capture/data goals | Existing Imaging evaluation with its own target and schedule |
| Polar Ice Survey | Meet overall capture/data goals and deliver at least one complete observation from every selected target | Complete per-target delivery scoring |
| Communication | Proposed three-orbit mission returning at least 12 MB over at least two distinct successful contact steps | Count accepted Transmit steps with positive returned MB |
| Weather Monitoring | Proposed three-orbit mission observing the selected region during two distinct revolutions and returning at least 12 MB | Count distinct qualifying revolution visits for the selected region |

Keep existing preset settings unless a tested correction is needed. Polar Ice Survey currently selects Arctic Ice. Every selected Survey target needs a complete delivered observation. KE1 and HPC must demonstrate feasible runs before freezing the new three-orbit, two-count, and 12-MB thresholds.

Results show actual versus required progress, returned MB, outcome, supporting event IDs, and one useful suggestion. Agree partial-result and score rules with KE2.

Use supported orbits and authored access windows. Survey is a regional teaching exercise. Communication uses Observe to generate test payloads. Weather Monitoring teaches repeat observation of a region. Its results describe the simulation's authored observations and data return.

## A/B Design Lab behavior

- [ ] AB.1 Save Design A after the player reaches completed Results.
  - [ ] Save design, goals, full result, required resource measures, and supporting events independently of the recent-trace buffer.
  - [ ] Accept completed runs that missed their goals.
  - [ ] Check the reached active execution and bound report before saving.
- [ ] AB.2 Open Builder with A's parts copied into a new design.
  - [ ] Keep the mission setup fixed for a controlled comparison.
  - [ ] Cancel returns to A's result and preserves its stored record.
- [ ] AB.3 Revalidate and run B with a fresh run ID.
  - [ ] Use the same scenario and requested action plan or policy.
  - [ ] Preserve A while B runs.
- [ ] AB.4 Display A, B, and measured differences.
  - [ ] Show outcomes, qualifying count and goal, returned MB, lowest battery, highest storage use, total cost, total mass, and changed parts.
  - [ ] Display unavailable measurements explicitly.
  - [ ] Calculate signed numeric differences as B minus A.
- [ ] AB.5 Support another experiment and explicit replacement of A.
  - [ ] Require a deliberate player action to replace saved A.
  - [ ] Reset the comparison when the mission setup changes.
  - [ ] Keep the pair in the current browser session and display that refresh clears it.

Match preset ID, objective, targets, goals, orbit, duration, observation/contact schedule, simulation/catalog versions, and starting conditions except effects of intended design changes. Match requested action policy and a random seed if randomness is introduced. Accepted actions may differ when the same policy encounters different hardware limits. Different manual decisions receive the Design + operations label when the remaining matching rules hold. Completed attempts qualify for comparison. Abort and incomplete attempts receive an ineligible result with an explanation.

For a radio change, show measured returned-data improvement together with extra mass and cost. Explain trade-offs when a cheaper design already meets its goal. Every specific causal explanation references relevant evidence. Basic measures precede optional charts, file export, and persistent saved history.

## Shared agreement

- [ ] CONTRACT.1 KE1, HPC, and KE2 agree mission setup.
  - [x] Record the inspected baseline as `features/KE2` at `4c65496`. See the [baseline record](progress.md#baseline-and-verification).
  - [ ] Agree exact preset IDs, objective IDs, targets, goal fields, orbit, duration, and versions.
  - [ ] Provide compatible older-input examples and invalid-input examples.
- [ ] CONTRACT.2 HPC and KE2 agree run evidence.
  - [ ] Specify run identity, configuration snapshot, completed status, ordered events, and resource samples.
  - [ ] Keep complete target deliveries, positive contact-step counts, and revolution-visit counts distinct.
  - [ ] Define accepted-event semantics and the Weather revolution index or step mapping.
- [ ] CONTRACT.3 KE1, HPC, and SE agree comparison matching.
  - [ ] Name matching fields, allowed design changes, and action-plan labels.
  - [ ] Specify how saved A survives recent-trace turnover.
  - [ ] Confirm all five owners and the first handoffs.

Target the shared agreement for H+00:30. Each handoff includes agreed field names, one real example, and its expected outcome. A dependency record names the missing field, unsupported schedule, or invalid part combination, its owner, and the next check.

## KE1 mission setup and validation

Coordinate preset UI edits with the existing SE/KE3 owners.

- [ ] KE1.1 Preserve the three existing presets and add Communication and Weather Monitoring.
  - [ ] Supply valid IDs, goals, duration, and budget for all five.
- [ ] KE1.2 Check stock designs and attainable goals.
  - [ ] Validate a stock design for every preset.
  - [ ] Agree Survey delivery goals and feasible new thresholds with HPC.
- [ ] KE1.3 Extend setup validation.
  - [ ] Validate new goal fields and reject invalid inputs with clear corrections.
- [ ] KE1.4 Define comparison setup.
  - [ ] Specify fixed fields and a sensible A/B pair within mass and budget limits.
- [ ] KE1.5 Write mission briefs.
  - [ ] Explain who needs the data, why the goal matters, and the simulation assumptions for each preset.

By H+02:00, deliver five checked configs, stock designs, goal notes, and invalid examples. By H+04:00, deliver comparison setup rules and a candidate design pair. KE1 owns final setup checks.

## HPC simulation and repeatable evidence

- [ ] HPC.1 Verify each preset's observation and ground-contact windows.
- [ ] HPC.2 Supply the agreed evidence.
  - [ ] Emit action, step, target identity, revolution identity or mapping, returned MB, complete per-target deliveries, and stable event IDs.
- [ ] HPC.3 Provide reproducible A/B runs.
  - [ ] Use matching scenarios and requested action policy.
  - [ ] Reset mission state between runs.
- [ ] HPC.4 Expose resource extrema.
  - [ ] Supply lowest battery and highest storage, or samples with agreed boundaries for calculating them.
- [ ] HPC.5 Supply success and shortfall traces for all five presets.
  - [ ] Verify storage and packet accounting, including complete and incomplete Survey deliveries.

By H+02:00, deliver evidence field definitions and a feasible run plan for every preset. By H+04:00, deliver five preset traces and repeatable A/B runs.

## KE2 evaluation and comparison

Use the [KE2 checklist](ke2-work-plan.md) for its individual work packages.

- [ ] KE2.1 Preserve Imaging, complete Survey delivery evaluation, and add positive-contact and distinct-revolution checks.
- [ ] KE2.2 Define success, partial, failed, and scoring rules for each objective.
- [ ] KE2.3 Calculate A/B differences and reject incompatible or incomplete pairs.
- [ ] KE2.4 Generate explanations and next experiments supported by actual goals/events.
- [ ] KE2.5 Verify edge cases and immutable stored reports through A replacement.

By H+02:00, deliver agreed report/comparison fields and worked examples. By H+04:00, deliver real reports for five presets and one tested A/B comparison.

## KE3 player flow and presentation

- [ ] KE3.1 Preserve the three existing cards and add Communication and Weather cards.
  - [ ] Display their actual goals and Survey delivery progress.
- [ ] KE3.2 Add Save as A, Modify design, Run B, and Compare.
  - [ ] Provide readable empty and incompatible states.
- [ ] KE3.3 Display A/B measures, changed parts, and supported explanations.
- [ ] KE3.4 Preserve Retry same mission and Modify design / Cancel.
  - [ ] Keep A accessible after B.
- [ ] KE3.5 Show session-only retention and verify usability.
  - [ ] Check keyboard navigation, text readability, and browser layouts.

By H+02:00, deliver layout and field agreement. By H+04:00, connect one A/B flow. By H+06:00, connect all five presets and verify the browser journey.

## SE integration, storage, and release

- [ ] SE.1 Connect setup, simulation, evaluation, and presentation.
- [ ] SE.2 Retain independent A/B records and fresh run IDs.
  - [ ] Implement deliberate comparison reset and A replacement.
- [ ] SE.3 Keep replay/display activity independent of stored execution evidence.
- [ ] SE.4 Integrate owner changes and preserve the working single-player flow.
  - [ ] Resolve schema and interface mismatches with affected owners.
- [ ] SE.5 Export and verify the browser build on Netlify.
  - [ ] Record the public URL, deployed revision, run IDs, known issues, and launch instructions.

By H+02:00, connect one mission path. By H+04:00, complete one A/B loop. By H+07:00, deliver a tested browser candidate and launch guide. SE owns final integration checks.

## Eight-hour schedule

Elapsed milestones are shared across the five roles.

| Elapsed target | Checkpoint |
| --- | --- |
| H+00:00-00:30 | Pin revision and agree mission IDs, goals, evidence, report fields, comparison matching, and owners |
| H+00:30-02:00 | Validate five setups and schedules, share events/reports, and connect one Save A / copied B design path |
| H+02:00-04:00 | Complete one real A/B loop and four objective evaluation paths using actual engine evidence |
| H+04:00-06:00 | Verify all five presets and A/B pairs in the browser, including shortfalls and Cancel/Retry |
| H+06:00-07:00 | Fix failures, deploy a candidate, test the public URL, and rehearse one improvement story |
| H+07:00-08:00 | Freeze changes, repeat relevant checks, and record revision, run records, A/B evidence, and open issues |

## Acceptance checklist

- [ ] ACCEPT.1 Verify each preset through its actual player journey.
  - [ ] Estuary Watch launches, completes, and displays its own correct report.
  - [ ] Tropical Forest Watch launches, completes, and displays its own correct report.
  - [ ] Polar Ice Survey launches, completes, and displays its own correct report.
  - [ ] Communication launches, completes, and displays its own correct report.
  - [ ] Weather Monitoring launches, completes, and displays its own correct report.
- [ ] ACCEPT.2 Verify success, shortfall, and mission-specific boundaries.
  - [ ] Success and shortfall for Estuary Watch.
  - [ ] Success and shortfall for Tropical Forest Watch.
  - [ ] Success and shortfall for Polar Ice Survey, including incomplete and missing selected-target deliveries.
  - [ ] Success and shortfall for Communication, including zero-MB and off-window Transmit attempts.
  - [ ] Success and shortfall for Weather Monitoring, including repeated captures in one revolution.
- [ ] ACCEPT.3 Preserve A and independent identities.
  - [ ] A survives B, Retry, and Cancel.
  - [ ] Every fresh execution has a new run ID.
- [ ] ACCEPT.4 Identical designs and decisions under matching conditions reproduce measured results.
- [ ] ACCEPT.5 Verify matching and action labels.
  - [ ] Changed mission/scenario settings block controlled comparison.
  - [ ] Different manual actions receive the combined design/operations label.
- [ ] ACCEPT.6 Comparison values and explanations resolve to actual reports/events.
- [ ] ACCEPT.7 Verify public Netlify journeys from a fresh visit.
  - [ ] Estuary Watch and its A/B pair.
  - [ ] Tropical Forest Watch and its A/B pair.
  - [ ] Polar Ice Survey and its A/B pair.
  - [ ] Communication and its A/B pair.
  - [ ] Weather Monitoring and its A/B pair.
- [ ] ACCEPT.8 Rerun existing single-player checks on the expanded revision.

If time slips, cut charts, animations, extra advice rules, file export, and persistent saved history first. Preserve the five checked presets, Survey evaluation, basic A/B measures, and one supported explanation. Record unfinished core items with owners.

## Source basis

The original PDF cites the following planning sources. Resource links are carried over from its annotations.

1. Supplied `NASA Space Apps Challenge-1.pdf`, pages 1-4, for NASA resources and learning-game examples.
2. Earlier eight-hour plan, page 2, for provisional Communication and Weather targets.
3. NASA Mission Design Lab for alternative designs and resource trade studies. [Mission Design Lab](https://etd.gsfc.nasa.gov/capabilities/integrated-design-center/mission-design-lab/)
4. NASA Build It Yourself for goals guiding engineering choices. [Build It Yourself](https://science.nasa.gov/mission/webb/game-build-it-yourself/)
