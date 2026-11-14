# KE2 receipt and review of KE1 K20 draft 2

Reviewed on 15 November 2026 at `features/KE2`, `8b76b5df4f0b327d8d4293be22ed984b610f8647`. Source folder: `C:\Users\Min Sett Paing\Downloads\Telegram Desktop\KE1-KE2-K20-Review-draft-2`. This completes the artifact-receipt/review subtask of 00.2. Production migration and shared integration acceptance remain open.

## Received interface and status

The package targets main `dce75db845f6c494b8c25c9028dd9c0648aabd91`, an ancestor of this checkout. Reviewed contract: `expansion-goals-v2-draft-2`; registry: `five-presets-candidate-2`; Communication preset revision: `2`; other preset revisions: `1`. Draft 2 supersedes draft 1 for current review. The signed `v1.0-agreed` agreement and production contract remain unchanged.

Received the five-preset registry, catalog API, catalog tests and UID sidecars, Communication diagnostic, K20/package documentation, measured JSON evidence, final logs and hash manifest. All 16 manifest-listed file hashes and four executed-input hashes match; the manifest is the seventeenth supplied file. There are no unlisted files. A [review-only archive](evidence/ke1-k20-draft2-review-package.zip) preserves the exact received contents. It is not installed into production paths.

The existing four KE1-confirmed choices are reflected correctly: config v2, nested `mission.goal`, root preset identity/revision, and the high_inc/basic-instrument/fast-radio Communication starter. Config, registry, state/event, report and saved-record versions remain separate.

| Preset | Objective / goal | Captures / MB / orbits | Review result |
| --- | --- | --- | --- |
| `estuary_watch` | `imaging` / `imaging` | 5 / 60 / 6 | Legacy config equals the actual measured card config; target `coastal_region`, orbit `high_inc` |
| `tropical_forest_watch` | `imaging` / `imaging` | 5 / 60 / 6 | Legacy config equals the actual measured card config; target `tropical_forest`, orbit `low_eq` |
| `polar_ice_survey` | `survey` / `survey_delivery`, minimum complete observations per target 1 | 5 / 60 / 6 | Supplied tests preserve Runtime-generated legacy setup, `arctic_ice` / `high_inc`; scoring remains unavailable |
| `communication` | `communication` / `communication_contacts`, positive contact steps 2 | 2 / 12 / 3 | Basic instrument, fast radio, `equator` / `high_inc`, 1120 g / 89 credits under a 100-credit budget |
| `weather_monitoring` | `weather_monitoring` / `weather_revisit`, distinct revolutions 2 | 2 / 12 / 3 | Basic radio, `equator` / `high_inc`; actual Weather success/shortfall evidence still needed |

The sole returned-data threshold remains `mission.required_returned_data_mb`; `required_observations` retains capture/quota meaning. Candidate authored configs use root `preset_id` and positive matching `preset_revision`. `existing_v1_config()` deliberately returns `GOAL_EXTENSION_PENDING` without a config for the new objectives. No Imaging fallback is exposed by the API. Current production validation rejects all candidate config-v2 objects.

## Independent rerun and same-config control

Copied only baseline dependencies into ignored `exports/k20-draft2-review`, then added the supplied overlay there after collision checks. Live producer, validator, runtime, evaluator, controller and UI files were unchanged. Confirmed Godot `4.7.2.stable.mono.official.ed1daf0bf` before execution.

| Program | Expected / actual passed | Failed | Exit |
| --- | --- | --- | --- |
| Supplied preset catalog checks | 70 / 70 | 0 | 0 |
| Supplied Communication starter diagnostic | 265 / 265 | 0 | 0 |
| Existing baseline validator checks | 294 / 294 | 0 | 0 |
| Additional KE2 same-config diagnostic | 265 / 265 | 0 | 0 |

The supplied three-program baseline reproduces all 629 passes. Rerun catalog and Communication JSON exactly equal KE1's supplied JSON as parsed data. All eight production source hashes from the preceding KE2 packet still match this checkout. The Windows certificate-store diagnostic persists without failed checks.

KE1's original shortfall trial changes `required_observations` from 2 to 1. That is a valid mechanics diagnostic, but a stronger comparison keeps the intended capture quota at 2. KE2 created a labeled isolated derivative with that one configuration change held constant and repeated the trials. No original supplied script was edited.

| Same-config trial | Requested Observe steps | Positive Transmit steps / returned MB | Result against proposed Communication requirements |
| --- | --- | --- | --- |
| Complete | 1, 6 | 7: `19.333333332`; 10: `4.666666668`; total 24 | Count 2 and 12-MB data requirement met |
| Count shortfall | 1 | 7: 12; step 10 rejected `NO_DATA`; total 12 | Count 1 misses requirement 2; data requirement met |

Both trials use identical physical configs with capture quota 2, finish at step 30, retain ordered stable IDs and matching run/mission identities, and reconcile all returned MB with accepted Transmit events. A Power Save request advances after the rejected empty-buffer request. The [verification packet](evidence/k20-draft2-ke2-verification.json) preserves the manifest, exact revisions/hashes, rerun results, same-config inputs and ordered events.

These are actual native-engine executions of test-only v1 Imaging surrogates. They establish feasibility and an isolated count shortfall. They do not establish production config-v2 acceptance, an official Communication verdict/score, HPC sign-off, saved-A integration or browser behavior. Official new-goal scores remain null. No exported build was run.

## Remaining production decisions

- KE1: implement coordinated v2 validation, settle custom/edited-preset identity, Survey minimum bounds, and common/goal-specific bounds and error behavior. The review inspector checks positive counts and rejects unknown `goal` keys, but does not enforce a complete root/mission/design unknown-field allowlist, existing upper bounds or Weather count-versus-duration/quota consistency. It is a registry review API, not a production MissionConfig validator.
- HPC: confirm typed v2 acceptance, pre-action step semantics, packet completion and sparse-map behavior, derived revolution identity, resource sampling and the exact Communication trial. Provide actual Weather success and isolated-shortfall traces. KE1's measured native traces reduce the missing evidence; they do not replace owner confirmation.
- SE: propagate goal and root identity through Creator/review invalidation, launch snapshots, Retry/Modify/Cancel, report binding and independent saved A. Keep the new cards disabled until their full path is supported. Independent storage/navigation can continue under SE's recorded response.
- KE2/KE3/SE: settle expansion scoring/partial rules, report version and additive goal-progress output, migrate consumers and agree comparator inputs. Previously proposed Survey 83 and Communication/Weather 75 examples remain proposals.

One A/B wording difference needs alignment: draft 2 says changed action histories mean Design + operations. KE2's existing proposal distinguishes the requested plan/policy from accepted actions, because hardware limits can change accepted actions under the same requested policy. Use requested-policy/plan evidence for classification and avoid hardware-only causal claims when manual requests differ. This remains a shared comparison decision.

## Reproduction

The prepared isolated review is under ignored `exports/k20-draft2-review`. To rebuild it elsewhere, extract the archived package separately and overlay it onto copies of the current `core`, `scripts/core`, `scripts/integration`, `scripts/evaluation`, `data`, `tests/validation`, `tests/fixtures` and `project.godot`; preserve originals and require all supplied destinations to be absent before adding them. The prior eight module/data hashes bind those dependencies. No renderer or export-setting change was made.

Exact test invocations, from the live repository root:

```powershell
$godot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
$review = 'D:/orbitbridge-mission-architect/exports/k20-draft2-review'
& $godot --version
& $godot --headless --path $review --log-file "$review/presets-ke2.log" --script res://tests/validation/test_mission_presets.gd -- "$review/ke2-output"
& $godot --headless --path $review --log-file "$review/starter-ke2.log" --script res://docs/ke1-expansion/tools/check_communication_starter.gd -- "$review/ke2-output"
& $godot --headless --path $review --log-file "$review/validator-ke2.log" --script res://tests/validation/test_mission_validator.gd -- "$review/ke2-output"
& $godot --headless --path $review --log-file "$review/same-config-ke2.log" --script res://docs/ke1-expansion/tools/check_communication_same_config.gd -- "$review/ke2-same-config-output"
git diff --check
```

The same-config derivative copies the supplied diagnostic, changes `config.mission.required_observations = captures` to `config.mission.required_observations = 2`, and labels its provenance/status as KE2's surrogate review with HPC review pending. Its source hash is in the verification packet. Outputs/logs remain in the isolated folder. Production regression suites were not rerun for these documentation/isolated-review changes.

## Prepared reply to KE1

> Received and reviewed `expansion-goals-v2-draft-2`, registry `five-presets-candidate-2`, Communication preset revision 2 at KE2 checkout `8b76b5d`. All supplied hashes match. Isolated reruns reproduce 70 + 265 + 294 = 629 passes, and the supplied JSON results match. The original three presets retain their v1 configs; the two measured Imaging cards match exactly. The fast-radio starter produces 24 MB over steps 7/10. An additional same-config control retains capture quota 2, returns 12 MB at step 7 and rejects step 10 with NO_DATA, isolating the proposed contact-count shortfall. These remain v1 Imaging surrogate executions with no official Communication score. Please carry forward the bounds/unknown-field/custom-identity decisions into coordinated v2 validation, and align A/B wording around requested policy versus hardware-dependent accepted actions with SE/HPC. HPC/SE confirmation and scoring/report agreement remain pending.

This reply is prepared locally. No message, commit, push or publication was performed.
