# HPC to KE2 evaluation integration

Owner KE2. Verified 14 November 2026 with Godot `4.7.2.stable.mono.official.ed1daf0bf`.

## Producer revision and scope

The current cached `origin/feature/hpc-simulator` resolves to `b9817c35628a4280a899d7fa73ce551d9d4a93ba`. Its `MissionStepEngine` includes KE1 readiness integration, immutable config/scenario snapshots, cumulative event logs, explicit aborts, and v1 counters. The producer handoff identifies KE1 source revision `55d4f336e72a68ff31cf37e44f65a98c1cdcc193`.

This KE2 checkout contains the evaluator and feedback modules. The producer files were loaded unchanged from the pinned Git revision into an isolated project under `tmp/ke2-hpc-prompt7-b9817c3`. Their byte equality and SHA256 values were checked during setup. Runtime verification executed the real catalog loader, readiness validator, scenario adapter, planner, and step engine there.

## Mapping to the agreed evaluator

| Actual HPC field | KE2 input or use | Mapping |
| --- | --- | --- |
| `state.config_snapshot` | `config` | Pass the retained launch-time dictionary |
| `state.config_snapshot.mission.required_observations` | Observation target | Pass the player's launch-time goal |
| `state.config_snapshot.mission.required_returned_data_mb` | Return target | Pass decimal MB unchanged |
| `state.observations_completed` | Actual captures | Pass the successful-capture count |
| `state.returned_data_mb` | Actual Earth reception | Pass decimal MB unchanged |
| `state.stored_data_mb` | Explanation | Describe the remaining onboard amount |
| `state.phase`, `run_status`, `step_index`, `total_steps` | Terminal validation | Existing evaluator validates completion or abort |
| `state.run_id`, `mission_id` | Report identity | Pass both identifiers |
| `state.event_log` | `events` | Pass the complete ordered cumulative log |
| `event.code`, `type`, `action`, `event_id`, `step_index`, deltas | Evidence and correction | Existing feedback templates and relevance checks |
| `state.terminal_reason` | Recorded abort explanation | Prefer a nonempty string, then use the existing `abort_reason` fallback |

`request_action(...).events` contains events from the latest request. Earlier blocked actions remain in `state.event_log`. The adapter uses that cumulative log so terminal evaluation can cite an earlier block.

The v1 counters and units match the agreed evaluator. No counter or unit conversion is required. HPC's existing adapter owns legacy catalog/unit conversion. The legacy whole-run simulator's `returned_kb`, `buffer_kb`, and legacy event format require its documented HPC boundary before KE2 evaluation.

All consumed scoring, status, identity, and event fields are available in the native state. The original feedback boundary's `abort_reason` name differs from the producer's `terminal_reason`; feedback now supports that native field. Readiness provenance lives in the initialization response's `validation_result`. SE needs to retain that result for later source-credit linkage alongside the terminal report.

## Calling the integration

```gdscript
const Evaluator = preload("res://scripts/evaluation/mission_evaluator.gd")

func evaluate_terminal_hpc_state(state: Dictionary) -> Dictionary:
    return Evaluator.evaluate_hpc_state(state)
```

Call this with the native state from a completed action response or `abort_run` response. It reads `config_snapshot` and `event_log`, then delegates to the existing `evaluate_mission(config, final_state, events, comparison_baseline)` entry point. It also accepts the optional baseline as its second argument.

The return value keeps the agreed `{ "ok": true, "report": MissionReport }` or `{ "ok": false, "error": EvaluationError }` wrapper. Missing or incorrectly typed snapshots/logs produce `INVALID_EVALUATION_INPUT` with a field path. An operating state produces `NONTERMINAL_RUN_STATE`. The existing public evaluator remains callable with separate config, state, and event dictionaries.

Recorded trace bundles provide `config`, `final_state`, and `events` separately. Evaluate those through the existing three-input entry point. The runtime test verifies the committed `docs/hpc-ke3-ops-trace-v0.2.json` bundle through that path.

## Executed cases

| Case | Observed result |
| --- | --- |
| KE1 readiness and HPC initialization | Approved `tests/fixtures/valid_1u_feasible.json` with actual catalogs |
| Completed simulation | 60/60 steps, 62 events, `partial`, score 25 |
| Progress | 1/4 observations, approximately 7.7333333328/30 MB received, approximately 4.2666666672 MB onboard |
| Blocked transmission | `evt_008`, step 8, `NO_LINK_WINDOW`, unchanged step/energy/data/capture counters |
| Cumulative evidence | The completed report cites the earlier `evt_008` |
| Launch snapshot | Post-launch caller edits to goals leave the retained 4-observation/30-MB targets intact |
| Actual abort | Aborted after capture, `failed`, null score, one capture and zero returned MB preserved |
| Abort explanation | Contains HPC's recorded `Operator requested stop after capture.` reason |
| Input preservation | Terminal state, nested snapshots, and events remain equal to their original values |
| Determinism | Repeated terminal evaluation returns equal reports |

The first integrated run exposed an exact floating-point expectation mismatch, `7.7333333328` versus `7.733333332800001`. The corrected test uses absolute tolerance `1e-9` for the reference value and checks exact equality between the native returned-data counter and report actual separately.

## Verification results

| Command scope | Result |
| --- | --- |
| Evaluator runner parsing in local and isolated projects | Exit 0 |
| Current KE2 checkout | 165 passed, 0 failed, 5 pending groups, exit 0 |
| Combined pinned KE1/HPC plus current KE2 | 205 passed, 0 failed, 5 pending groups, exit 0 |
| Unchanged HPC `tests/test_hpc.gd` | 31 passed, exit 0 |

Logs are `tmp/ke2-prompt7-parse.log`, `tmp/ke2-prompt7-integrated-parse.log`, `tmp/ke2-prompt7-local-tests.log`, `tmp/ke2-prompt7-integrated-tests.log`, and `tmp/ke2-prompt7-producer-tests.log`. The existing Windows certificate-store startup diagnostic appeared in successful runtime checks. Version verification, script parsing, and each suite completed with exit 0.

## Reproduce the isolated integration

Run from the repository root. This setup reads the pinned Git objects and current KE2 files, and writes the verification project under ignored `tmp/`.

```powershell
@'
from pathlib import Path
import hashlib
import json
import subprocess

root = Path.cwd()
revision = 'b9817c35628a4280a899d7fa73ce551d9d4a93ba'
project = root / 'tmp/ke2-hpc-prompt7-b9817c3'
files = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision], text=True).splitlines()
producer_files = [path for path in files if (
    path.startswith(('core/', 'scripts/core/')) and path.endswith('.gd')
    or path.startswith(('data/', 'tests/fixtures/')) and path.endswith('.json')
    or path in ('tests/test_hpc.gd', 'docs/hpc-ke3-ops-trace-v0.2.json')
)]
manifest = {'hpc_commit': revision, 'files': {}}
for path in producer_files:
    content = subprocess.check_output(['git', 'show', revision + ':' + path])
    destination = project / path
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(content)
    assert destination.read_bytes() == content
    manifest['files'][path] = hashlib.sha256(content).hexdigest()
owned = list((root / 'scripts/evaluation').glob('*.gd'))
owned += [root / 'tests/test_mission_evaluator.gd']
owned += list((root / 'docs/contracts/v1-draft').glob('*.json'))
for source in owned:
    destination = project / source.relative_to(root)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(source.read_bytes())
(project / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="KE2 HPC integration verification"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
(project / 'source-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print(project)
'@ | python -B -

$ke2Godot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $ke2Godot --headless --version
& $ke2Godot --headless --path './tmp/ke2-hpc-prompt7-b9817c3' --script res://tests/test_mission_evaluator.gd
& $ke2Godot --headless --path './tmp/ke2-hpc-prompt7-b9817c3' --script res://tests/test_hpc.gd
```

The same KE2 runner executes runtime cases automatically when the real producer modules and fixture are available in an integrated checkout. In the current KE2 checkout, its 165 standalone checks run and the combined lifecycle group remains pending.

## Remaining owner integration

SE's controller must invoke the adapter at terminal state and publish one report per run. KE3's Results, event navigation, retry/reset, and exported build still need their runtime walkthrough. T07/T08 comparison and T11/T12 mass boundaries remain pending. The current report's `source_ids` remains empty while source-credit linkage awaits its integration work. [Team handoff](integration-handoff.md), [checklist](../ke2-todo.md).
