# KE2 operator-abort evaluation

Handoff revision `ke2-hpc-abort-v0.1`, verified 14 November 2026.

Run `run_hpc_ke2_abort_3990d3c_01` belongs to mission `mission_hpc_ke2_abort_01` and scenario `high_inc`, version `orbit-presets-v1`.

- [Original supplied bundle](input-bundle.json) retains SHA256 `4283f1dc663736b46462cbbb452f5fd1c5ab91cf0caa892c3e7c21f55c60697b`.
- [Evaluation](evaluation-v0.1.json) contains the current evaluator's complete success/report wrapper.
- [Verification and provenance](verification-v0.1.json) records input/report/module hashes, pinned producer files, replay scope, and results.
- [Verifier](verify_abort.gd) and [execution log](verification.log) provide the run-specific check source and output.

## Observed outcome

The report returns `run_status: aborted`, `status: failed`, and `score: null`. It preserves one captured observation against a target of four, 7.7333333328 MB received against a 30 MB target, and both completion ratios. Another 4.2666666672 MB remain onboard. The abort occurs at step 8 of 60.

The explanation attributes the recorded reason, `Operator requested abort for KE2 and SE/KE3 lifecycle verification.` Root causes are empty. The full input history retains `evt_008`, the earlier blocked no-contact transmission, and `evt_009`, the operator-abort event. The report's source IDs are empty and comparison is null.

## Verified behavior

Godot `4.7.2.stable.mono.official.ed1daf0bf` executed **71 checks with zero failures and exit 0**.

The verification checked the supplied bundle hash, run/mission identity, ten ordered event IDs, complete event-log equality, retained config snapshot, unchanged step/energy/capture/data counters on abort, zero blocked/abort deltas, all 17 report fields, recorded reason, deterministic output, and input preservation. Both KE2 APIs return the identical report for the supplied dictionaries.

An isolated project loaded 13 producer/dependency files from cached HPC commit `3990d3c7aae3b69dcf367d9f0601fc40fd669262`. Every copied file matched its pinned Git bytes. That commit's ancestry from `9dfd942` was checked. The replay recomputed actual KE1 readiness, executed all nine recorded action requests, compared every response, verified the pre-abort state, and called the real `abort_run` method. The actual abort response and report metrics match the supplied bundle.

Replay comparisons allow absolute numeric tolerance `1e-9` for serialized floating-point values. Explanation text is checked separately for the recorded operator reason because JSON-loaded whole numbers and native counters can format differently. The first strict text-equality expectation was corrected before the final passing run. Production evaluation code required no changes for this bundle.

The bundle and generator handoff are owner-reported local/uncommitted artifacts, with the bundle pinned by its supplied SHA256. The independent KE2 replay uses the recorded producer commit. HPC's reported complete regression run covers simulator, 36 HPC cases, and demo. The verification here executes the supplied action/abort path.

## Consumption by SE and KE3

```gdscript
var result: Dictionary = Evaluator.evaluate_mission(
    bundle["launch_config"], bundle["terminal_state"], bundle["ordered_events"]
)
```

`Evaluator.evaluate_hpc_state(bundle["terminal_state"])` returns the same result. Use the unwrapped `result.report` for Results and retain this attempt's run/mission identity. KE3's reviewed presentation seam uses the matching history in `state.events`, projected from the native `event_log`. The actual launch readiness result is available in `bundle.readiness.validation_result` for scoped credit metadata.

SE/KE3 can use this actual aborted attempt for controller-driven null-score display and lifecycle verification. Integrated reopening, Retry, New Mission, duplicate publication, error routing, B02, official B10, and exports remain pending.

## Local reproduction

The supplied verifier runs in an isolated project containing the pinned producer files listed in the verification JSON, current KE2 evaluator/feedback, and `input-bundle.json` at its resource root. The generated local project is under `tmp/ke2-hpc-abort-3990d3c`.

```powershell
$ke2Godot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $ke2Godot --headless --version
& $ke2Godot --headless --log-file './tmp/ke2-hpc-abort-verification.log' --path './tmp/ke2-hpc-abort-3990d3c' --script res://verify_abort.gd
```

The known Windows root-certificate-store diagnostic appeared alongside the passing verification and exit 0. Source/module hashes and original report generation provenance are recorded in the sidecar.
