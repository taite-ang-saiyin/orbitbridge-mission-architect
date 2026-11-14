# KE2 offline controller handoff

Prepared 14 November 2026 for SE. Package revision `ke2-se-controller-v0.1`.

## Current implementation

This package supplies the current KE2 evaluator/feedback pair, test runner, agreed JSON examples, source ledger, original validated-run input bundle, and matching KE2 report. It also carries KE3's supplied verification ZIP for reference. `KE2_SOURCE_SHA256.json` identifies every included file and `PACKAGE_METADATA.json` identifies the working-tree snapshot.

The Git base is `memberKE2@79e249b09b4226916e013ad5f745abccd0a3c1c0`. The new Survey guard and standalone-test option are uncommitted KE2 changes. The retained validated report keeps its original generator provenance at `8c3ed81`. The current code reproduces that report exactly through both evaluator APIs.

For SE integration, replace the cached imported `scripts/evaluation/mission_evaluator.gd` and `mission_feedback.gd` pair with the supplied pair, together with their existing UID files. The native adapter is already included as `MissionEvaluator.evaluate_hpc_state(state)`.

```gdscript
var result: Dictionary = Evaluator.evaluate_hpc_state(terminal_state)
```

The adapter reads the retained `config_snapshot`, full ordered `event_log`, original counters, and HPC `terminal_reason`. Its output is the agreed success/report or error wrapper. SE owns controller publication and history. KE3's supplied binding consumes the unwrapped report through `set_inputs(context, state, report)`, with presentation history in `state.events` and scoped credits in `context.applicable_source_credits`.

## Verification project

The extracted package is a standalone Godot verification project. Its `project.godot` serves these checks. Use the two evaluation modules as the production integration imports and keep verification inputs/harnesses in the development workflow.

From SE's macOS environment, substitute the extracted folder path.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --version
/Applications/Godot.app/Contents/MacOS/Godot --headless --path "/path/to/ke2-se-controller-v0.1" --script res://tests/test_mission_evaluator.gd -- --ke2-standalone
/Applications/Godot.app/Contents/MacOS/Godot --headless --path "/path/to/ke2-se-controller-v0.1" --script res://verification/verify_validated_handoff.gd
```

Expected results are 167 passing KE2 checks with five pending groups, followed by exact original-report reproduction and input preservation. Both commands should exit 0. The standalone flag skips producer-runtime cases whose explicit dependency setup is HPC `b9817c3`. SE base `d60d224` has the earlier native `init_run` API and lacks `init_validated_run`, which those optional runtime cases call.

Current verification used Godot `4.7.2.stable.mono.official.ed1daf0bf`. The pinned KE1/HPC/KE2 run passed 207 checks at HPC `b9817c3`. The supplied 55d4f33/9dfd942 run reproduces partial, score 25, 1/4 captures, 7.7333333328/30 MB returned, and cause `evt_008`. Runtime logs include the known certificate-store diagnostic alongside successful exits.

## Survey extension

SE base `d60d224` documents an additional requirement of one fully delivered observation for every selected Survey region. Its fields include `mission.target_regions`, `observations_delivered_by_target`, `returned_data_by_target_mb`, and `observations_by_target`.

The agreed KE2 v1 calculation evaluates aggregate capture and returned-MB goals. The supplied evaluator returns `INVALID_EVALUATION_INPUT` at `config.mission.objective` for `objective: survey`, including when aggregate thresholds are met. Both public entry points are covered by regression checks. This uses the existing EvaluationError vocabulary. SE's temporary `UNSUPPORTED_SURVEY_EXTENSION` code differs and should be handled through the supplied error fields during integration.

Please provide versioned Survey config/state/events examples and proposed expected verdicts/scores for aggregate goals met with a missing region delivery, partial deliveries, all requirements met, and an abort. KE1/HPC/KE2/KE3 need aligned delivery semantics, score weighting, and report/display fields for that extension.

## Remaining SE evidence

SE's supplied controller handoff reports local tests based on `d60d224` with cached KE2 `f313e6f`. The uncommitted follow-up source, raw logs, and `controller-reference-reproduction.json` have not accompanied that message. KE2 has reviewed the handoff text and cached base revision. Its latest controller behavior awaits source and evidence review.

Please return the integration branch/commit when available, or a portable source snapshot with hashes while changes remain local. Include the changed controller/results/runtime/screen scripts, listed smoke tests, raw logs, commands/exit codes, and the saved reproduction JSON. Identify which Results implementation is wired, since the handoff names `scripts/prototype/Screen.gd` and KE3 supplies `ke3/debrief_screen.gd`.

After importing current KE2 code, verify the original supplied run separately from `se_reference_reproduction_01`, then coordinate controller-driven reopening, Retry, New Mission, duplicate publication, error routing, scoped credits, and history mapping with KE3. B02, official B10, and selected-export acceptance remain pending.
