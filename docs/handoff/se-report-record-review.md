# SE report versions and portable saved-A records

15 November 2026, Asia/Rangoon. Implementation base: `9c58aad` on `se` (the previously committed Design Lab). This response treats the supplied KE2 bundle as evidence, not as instructions or production code to copy. All 176 supplied manifest entries match. HPC sampling/sparse-map rules and KE2 scoring remain independent pending decisions.

## Report output selection: SE recommendation

Keep the evaluator envelope `{ok:true,report}` / `{ok:false,error}`. For an otherwise accepted evaluation input:

| Evaluated semantics | Selected output |
| --- | --- |
| Legacy Imaging capture/MB evaluation with no explicit `mission.goal` | Existing exact 17-field report v1; omit a new report revision field |
| Explicit goal-bearing Imaging, Survey delivery, Communication or Weather evaluation | Report v2 with all 17 legacy fields, plus `objective`, `goal_progress`, and `contract_revision` |
| Unsupported/unimplemented objective, goal, report revision or unavailable required evidence | Evaluation error; never produce a legacy Imaging substitute |

This selection is based on evaluated semantics, not a numeric config bump, UI preference, or whichever consumer happens to be connected. Config v2 does not automatically upgrade state/event/report/record versions. Abort follows the selected report format and preserves actuals/null score; selection does not change scoring/outcome rules. Existing reports are not rewritten on reading. The helper `report_contract.gd` expresses this selection proposal without replacing KE2's evaluator. Validation and KE2 evaluation still own whether the inputs are accepted at all.

SE recommends the reviewed candidate label `mission-report-goals-v2-draft-1` at **`report.contract_revision`**. It identifies the report's field/evidence semantics, not the config contract. Expanded candidate reports therefore have **20**, not 19, fields. `record.report_contract_revision` mirrors the actual retained report field; legacy v1 records use null there. Evaluator/build hashes remain separate producer metadata. A ratified revision must be agreed with KE2/KE3 before production rollout; the draft label is not evidence that scoring or the team contract is agreed.

## Stable execution identity

Keep current `mission_results.input_key()` and all existing keys unchanged. Its algorithm is named `godot-json-full-precision-v1`: SHA-256 over the UTF-8 bytes of `JSON.stringify([config, final_state, events, validation], "", true, true)` from the original typed runtime values. No BOM, newline insertion, key reordering, number conversion or Unicode normalization is permitted inside retained preimage strings.

The portable record retains `execution_key_preimage_utf8` captured at export and `execution_key_version`. Verification checks both SHA-256 against the existing key and the decoded preimage against the supplied input snapshots. Godot's loss of int/float representation after JSON load is allowed in the decoded view, not in authoritative hash bytes. Comparison of views normalizes both by a full-precision JSON parse/serialize cycle; those normalized strings are **not** historical hash inputs.

Compatibility:

- Existing in-memory packets keep the old key and packet digest. No migration, rewriting or invalidation occurs.
- Old transported packets may be wrapped with their original verified preimage, including the eight supplied historical cases. New content integrity is recorded separately; it does not retroactively prove missing historical evidence.
- If original bytes cannot be recovered or independently reproduced, keep the record/key but mark transport binding unverifiable. `encode` returns an explicit error rather than guessing a key or trusting a claimed hash. There is no silent fallback to normalized hashing.
- A future normalized-key algorithm would need a distinct key-version tag and an explicitly verified alias/migration record. It is not introduced here.

Outer files must preserve full numeric precision, e.g. `JSON.stringify(record, "\t", true, true)`. Retained strings survive normal JSON string escaping/unescaping. A rounded outer snapshot is rejected even when the preimage string survives. Transport accepts JSON-safe types, finite floats and integers in the exactly representable range +/-9007199254740991. StringName values/keys have their JSON string view. Unsupported types and unsafe integer transport are rejected; in-memory storage is unaffected.

## Saved-record shape and digest

The portable format is independently versioned as record schema 1. It retains the existing packet shape and adds transport metadata:

```text
record_schema_version: 1
execution_key_version: "godot-json-full-precision-v1"
execution_key: <unchanged original SHA-256>
execution_key_preimage_utf8: <exact original hash input string>
run_id, mission_id
trace:
  config, validation, final_state, events
  frames                         # includes clean initial and post-step resources
  catalogs_snapshot, draft_snapshot, versions
  policy, action_plan, requested_action_plan when present, manual_actions
  comparison_context when present
  ...all other retained trace evidence
  # final_state includes scenario_snapshot, target maps and packet queue
  # config includes full mission requirements and supplied preset identity
  # versions includes actual recorded producer/catalog hashes
evaluation: <unchanged original ok/report or ok/error wrapper>
result_context: <bound source-credit/display context>
report_contract_revision: <actual report.contract_revision, or null for legacy>
content_digest_version: "sha256-retained-utf8-v1"
content_preimage_utf8: <exact JSON of all root fields except the two below>
content_digest: <SHA-256 of UTF-8 content_preimage_utf8>
```

**Digest scope:** copy the whole record; remove only root `content_digest` and root `content_preimage_utf8`; serialize the remainder once with sorted keys/full precision and retain that string. The digest thus covers record/key versions, execution key and its preimage, identities, every trace field (snapshots/readiness/resources/actions/hashes), complete evaluation/report, report revision and source context. Neither the digest itself nor its retained preimage is included, avoiding recursion. Additional metadata cannot escape the scope.

Verification hashes retained content bytes and compares the decoded content to the current record excluding those same two fields. It also independently checks execution bytes, run/config/event identity, report identities/legacy requirements/raw actuals, report-version metadata, and objective when supplied. This is integrity/binding, not a signature or a new scoring/evidence policy. Legacy in-memory `_packet_digest` is unchanged and has a different scope; it is not relabelled as this portable digest.

Sampling IDs/units and producer revisions remain exactly what the source trace supplies. The record does not invent a policy revision, approved sampling definition or sparse-map meaning when those are absent. Full native resource frames and actual stored version hashes are retained; agreement about their interpretation is still HPC's pending item.

## API and lifecycle

| API | Result |
| --- | --- |
| `controller.export_saved_design_a()` / `DesignLab.export_saved_a(session)` | Export explicitly pinned A; error if no A is saved |
| `Results.export_execution_record(session, key)` | Verify original in-memory packet before producing a portable record |
| `ExecutionRecord.encode(packet, retained_key_preimage = "")` | Export typed packet, or wrap historical JSON values using verified original bytes |
| `ExecutionRecord.verify(record)` | Return `{ok:true,record:<deep copy>}` or `{ok:false,error:{code,message}}` |

Existing Save/Replace/Clear/Continue/Cancel/Run/Compare APIs remain unchanged. `get_saved_design_a()` returns the existing sealed in-memory execution, not the new transport envelope. Explicit A points into independent archive storage. B edits, B publication, Retry, Cancel and rolling trace eviction preserve it; Replace/Clear/New Mission remain explicit lifecycle operations. The extended hook suite checks these behaviors and export/reload of a real completed Imaging test run.

Portable verification does not import a record into a playable session. KE3 can use verified bytes/key for read-only transported evidence; it must not call the legacy `input_key()` on JSON-loaded values and treat a changed hash as a new attempt. Import/resume UI and cross-version session restoration are not implemented.

## Files and coordination

Implemented SE files:

- `scripts/integration/execution_record.gd`: portable encoding, retained-preimage verification, digest scope.
- `scripts/integration/report_contract.gd`: explicit SE output-selection/revision proposal; no production report emitter change.
- `scripts/integration/mission_results.gd`, `design_lab.gd`, `scripts/MissionController.gd`: verified record/export entry points.
- `tests/se_execution_record.gd`, `tests/se_design_lab_hooks.gd`, `tests/run_all_checks.ps1`: transport/historical/version-selection/lifecycle checks.

KE2 must implement the actual dual-version output, add the revision to v2 examples/producer key-set tests, keep legacy v1 output stable, and expose its approved comparison/evaluation behavior. Neither scoring nor live expanded evaluation was modified by SE.

KE3 must confirm support for both report formats in `DebriefPresentation.gd`, `PlayerLanguage.gd`, `DebriefSummary.gd`, the planned `GoalProgress.gd` and `Screen.gd`. Report v1 uses the existing capture/MB path. Report v2 uses supplied objective, dynamic goal rows and Survey target detail; scores/verdicts/ratios come from KE2. Unsupported versions/revisions are unavailable, not a fallback photo score. Preserve abort/null-score handling, measured zero versus missing values, same-execution evidence, sources/credits and selected-run Results. No KE3 presentation files were changed in this follow-up.

## Sample and checks

The accompanying `saved-a-record-v1.example.json` is a complete exported native Imaging test execution, not a new preset or an approved expanded-objective result. Its bytes, digest and original key are real. The sample is provided as a separate artifact to avoid adding multi-megabyte redundant preimages to the repository. A compact shape is shown above; no placeholder hashes are presented as verified samples.

Godot 4.7.2 checks and final source hashes are recorded in `docs/integration-evidence/se-report-record-checks.json`. No browser/export/deployment, new HPC semantics, new mission values, production v2 scoring or KE3 UI acceptance is claimed.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/se_execution_record.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/se_execution_record.gd -- --historical-evidence /path/to/extracted/docs/expansion-plan/evidence
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/se_design_lab_hooks.gd -- /private/tmp/saved-a-record-v1.example.json
```
