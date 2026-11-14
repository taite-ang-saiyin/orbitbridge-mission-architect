# Mission Operations

Operations plays or steps through simulator states generated from the validated mission and selected operating policy. It uses actual resource counters and ordered events, not the removed prototype snapshot fixtures.

## Presentation

The page shows the interactive Earth/orbit view, telemetry, target progress and event history. Play, Pause, Step and Skip to End control the playhead. The sidebar and pinned footer handle page navigation; there is no shared progress strip.

`MissionOperations.gd` projects recorded states through `scripts/integration/mission_playback.gd`. Orbital graphics illustrate the scenario and do not compute real visibility or propagation. `ui/components/GroundTrack.gd` draws the map and animated illustrative path.

Terminal states are published through `MissionController.gd` and `scripts/integration/mission_results.gd`. Reports and retry history are retained by run ID. Survey-scoring limitations are shown as readable messages without inventing a score.

## Verification

Run `tests/operations_smoke.gd` for playback, telemetry, event filtering and responsive bounds. Run `tests/controller_evaluation_smoke.gd` for terminal publication, duplicate notifications, Results, Retry, Abort, baseline handling and New Mission.
