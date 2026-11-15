# HPC evidence confirmation received

Recorded on 15 November 2026 in Asia/Rangoon from `features/KE2` at `cb458c7d9c9b3b2484e8111dbbec4ea1468f51b8`. The user relayed HPC's confirmation and publication on `feature/hpc-ke3-goal-evidence-v1`, commit `345e5bdecd41d716ba3f580ae615628edf00f6ca`. That commit was available locally. Its 12 examples, manifest and five verification logs were inspected from an isolated copy under `exports/hpc-goal-evidence-345e5bd`.

## Confirmed evidence semantics

| Evidence | HPC-confirmed meaning |
| --- | --- |
| Returned-data delta | `delta_returned_data_mb` is canonical. Count each distinct positive accepted Transmit step once |
| Weather revolution | `floor(accepted_event.step_index / steps_per_orbit)`, zero-based, using frozen orbit timing |
| Complete delivery | `observations_delivered_by_target[target_id]` counts complete observation packets. Packet completion requires remainder strictly `< 1e-8 MB` |
| Sparse native map | An absent target key in a genuine native map means zero. A missing whole map or unverifiable historical projection is unavailable |
| Resource extrema | Include initialization and every accepted post-clamp state, including terminal. Blocked requests add no physical step |
| Sampling identifier | `initial_and_each_accepted_poststep_v1_proposal` retains its published spelling. HPC confirmed its meaning |

The packet preserves native events, readiness, snapshots, versioned plans, request frames and resource samples. Communication and Weather executions use Imaging mechanics proxies. HPC's expanded-objective scores are null. KE2's expanded scores retain proposal status.

## KE2 implementation

The default evidence policy now uses revision `hpc-goal-evidence-v1.0.0`, `survey_missing_targets: zero_in_present_map` and `weather_mapping: step_floor`. Sparse-key normalization follows validation of the frozen config, native state structure, full same-run history and aggregate accounting. Existing native maps yield zero for absent selected delivery/MB keys. Missing whole maps retain unavailable handling. The raw explicit-counter helper supports legacy/counter-only fixtures through caller normalization.

New records carry evaluator revision `ke2-expansion-candidate-2`. The record validator reproduces all ten previous candidate records using their stored policies. Their original bytes, execution keys and digests verify. A revision-1 record claiming the later HPC policy is rejected. Weather metadata records HPC confirmation, and new-policy feedback uses the confirmed mapping. Historical-policy feedback remains reproducible. Proposed scoring, report revisions and comparison identity rules continue through owner coordination.

The consumer checks retain HPC's actual versioned `action_plan` as policy, including its blocked fallback. A fixed-plan Forest radio pair receives Design classification. Changed supplied plans receive Design + operations. Saved-A runtime binding remains an SE dependency.

## Verification

| Check | Actual result |
| --- | --- |
| Pinned producer hashes against live files | 13 of 13 match |
| Original examples | 12 file hashes match the manifest |
| Recorded verification | Manifest and all five stage log hashes match, with five recorded exit codes 0 |
| Independent native persisted replay | 12 examples, 8,266 checks pass, 0 fail, exit 0 |
| KE2 HPC consumer | 245 pass, 0 fail across all 12 examples, historical records and an additional native empty-map Survey |
| Expanded candidate regression | 703 pass, 0 fail |
| Existing evaluator | 294 pass, 0 fail, five existing pending declarations |
| Independent algorithms / callable v1 / Imaging cards / Results / Debrief | 125 / 34 / 53 / 17 / 57 pass, 0 fail |

Survey's partial-packet and complete cases yield one/two complete targets and proposed scores 83/100. Communication's same-config control yields one positive step/12 MB versus two steps/24 MB and proposed scores 75/100. Weather's one/two revolution cases both return 24 MB and yield proposed scores 75/100. The fixed-plan Forest radio edit improves return by `15.6799999968 MB`. Resource extrema reproduce HPC's published values. Genuine empty maps yield measured zeros, while missing whole maps retain unavailable handling.

Native replay used the original source snapshot. KE2 consumed the published packets against matching live producer bytes. Seven existing KE2 programs were run individually. Sandboxed Godot startup failed to load .NET assemblies. The same verified executable succeeded outside the sandbox. Browser, export and saved-A lifecycle acceptance retain their existing owners.

The receipt records source, packet and log hashes plus current case results. The original candidate archive and its ten records retain their earlier revision. [Machine-readable verification](evidence/hpc-goal-evidence-receipt.json)

## Exact reproduction commands

Run from the repository root in PowerShell with local object `345e5bd` available.

```powershell
$orbitGodot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $orbitGodot --version
git archive --format=zip --output=exports/hpc-goal-evidence-345e5bd-source.zip 345e5bd project.godot core scripts data tests docs/handoffs/hpc-goal-evidence-v1
Expand-Archive -LiteralPath .\exports\hpc-goal-evidence-345e5bd-source.zip -DestinationPath .\exports\hpc-goal-evidence-345e5bd -Force
& $orbitGodot --headless --path D:/orbitbridge-mission-architect/exports/hpc-goal-evidence-345e5bd --log-file D:/orbitbridge-mission-architect/exports/check-logs/hpc-goal-persisted-ke2.log --script res://tests/run_hpc_goal_examples.gd -- --verify-only
& $orbitGodot --headless --path . --log-file D:/orbitbridge-mission-architect/exports/check-logs/ke2_hpc_evidence_check.log --script res://tests/ke2_hpc_evidence_check.gd
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_ke2_expansion_checks.ps1 -GodotExe $orbitGodot
git diff --check
```

The consumer also accepts `-- --evidence-dir res://docs/handoffs/hpc-goal-evidence-v1` once the owner packet is integrated. Generated records are under `exports/check-evidence/ke2-hpc-evidence/records.json`.

## Completed tasks and remaining handoffs

- [x] 00.3 evidence agreement and producer packet review.
- [x] 10.2 native Survey measurement, including sparse keys and partial packets.
- [x] 20.1 Observe payload/positive-step semantics and 20.3 Weather mapping confirmation.
- [x] 40.2 resource-sampling meaning and native extrema verification.
- [x] Historical record compatibility and affected KE2 regression checks.
- [ ] KE1 and affected owners consolidate schema/config identity and report/scoring decisions.
- [ ] KE1/HPC integrate production Communication and Weather objective support.
- [ ] SE binds publication and saved A to the actually completed execution, including readiness and retained evidence.
- [ ] KE3 accepts expanded reports/comparisons through the active presentation path, followed by SE export/browser verification.

Future HPC coordination concerns production objective integration and producer changes. The confirmed measurements and published packet can be reused for that work.
