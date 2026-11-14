# SE report review and version proposal

Recorded on 15 November 2026, Asia/Rangoon, at `features/KE2`, `f04ab662e19c3ada6fdbd2240e355f27541a9e46` plus local documentation changes. Source: the user relayed SE's review of the [handoff](ke3-se-hpc-report-handoff.md) and [four original examples](evidence/report-examples-proposal.json).

## Owner response and scope

SE accepts the report structure in principle: preserve `{ok, report}` / `{ok, error}`, all 17 existing report fields and captured-observation meaning, while adding `objective` and `goal_progress`. SE independently checked the four examples' fields and top-level goal ratios/verdicts. SE had not received the underlying source packet and therefore did not verify event references or execution hashes. SE reports no implementation changes or sent messages.

SE recommends existing reports remain report schema 1 and expanded reports use report schema 2, with an independently agreed report-contract revision and explicit consumer support for both. This is a recommendation with version/evidence details still open, not a completed production migration or full agreement on the revision. Config, state/event, report and record versions remain independent.

SE requires execution binding to frozen config, terminal state, complete ordered events and original readiness, using agreed deterministic serialization. Validate report identities, objective, requirements, actuals and evidence against that execution, and bind the report/evaluator revision to it. Run ID alone is insufficient. Communication/Weather examples remain labeled Imaging proxies; their proposed reports cannot be published as actual new-objective reports against those Imaging inputs.

## Concrete version candidate

Prepared [four separate report-v2 examples](evidence/report-examples-v2-proposal.json), keeping the original examples unchanged. Each candidate retains the same 19 report keys: the 17 existing fields plus `objective` and `goal_progress`; only its report `schema_version` changes to 2. Actual `production_reply` envelopes, original source identities and proxy labels remain unchanged.

The candidate report-contract label `mission-report-goals-v2-draft-1` appears only in review-file metadata. Its final spelling, location in reports/records, ratification and compatibility/output-selection rules remain to agree. It has not been added to a production contract or report. A config version must not implicitly select or redefine report/state versions.

KE3 agreed the goal schema but has not explicitly confirmed this subsequent dual-report-version recommendation. Ask KE3 to confirm consumer support for both formats during its planned implementation. KE2/SE must agree the exact revision and output selection. Survey/new-goal scoring and partial-result rules remain separate open decisions.

## Saved-A proposal received from SE

| Proposed retained content | Required purpose |
| --- | --- |
| `record_schema_version`, `execution_key`, `run_id`, `mission_id` | Record identity and format |
| `config_snapshot`, including full requirements/preset identity/revision | Immutable requirements |
| `validation_snapshot`, `initial_state`, `final_state` | Readiness and execution states |
| `events`, `resource_samples`, sampling definition/units | Ordered evidence and resource analysis |
| `catalogs_snapshot`, `scenario_snapshot`, producer versions/hashes | Reproduction and comparison context |
| Versioned requested policy/action plan and ordered manual requests/overrides | Operation classification |
| `report`, report-contract/evaluator revision, source-credit/display context | Bound authoritative result and reopening |
| Content digest covering retained record | Integrity |

Save A explicitly from an actually completed execution, independently of the rolling trace buffer. B edits, Retry and Cancel must preserve A. Completed partial/failed outcomes remain candidates; aborted/unfinished runs are excluded. Other mission/context compatibility checks still apply. Exact optional fields, version/fingerprint conventions, null handling and digest scope/encoding remain to agree. In particular, define how the digest excludes its own digest property. SE owns implementation and lifecycle evidence; no saved-record API was added here.

## Evidence gap addressed and serialization finding

Prepared the [SE evidence bundle](evidence/se-report-review-evidence.zip) with the full source packet, original and v2 candidate examples, probe/checker, reconstructed historical hash preimages, review notes, historical source snapshots and a file-hash manifest. This is ready for the user to share; it has not been sent.

The initial direct JSON reload check found **8 execution-key mismatches**: archived typed Godot dictionaries lose integer-versus-float representation when JSON is parsed, and the current full-precision hash input distinguishes `[1]` from `[1.0]`. The [original failing check log](evidence/se-report-json-roundtrip.log) is preserved. This is an observed transport issue, not a report-shape defect or evidence of changed native physics. Current in-memory binding is not shown to fail by this test.

In an isolated copy whose eight recorded producer/data hashes exactly match the original packet, KE2 reran the original eight native cases and captured their hash input strings. Every historical execution key was reproduced; parsed traces and actual evaluator replies equal the originals. The [preimage record](evidence/execution-key-preimages-review.json) retains the exact UTF-8 strings whose SHA-256 equals each stored key and whose decoded inputs equal the source packet. Historical files and keys were not rewritten.

The [review checker](evidence/se-report-evidence-check.gd) now verifies those historical bytes, source-value equality, event identities/references, source packet hashes, actual-reply retention and goal ratios for both example sets: **85 passed / 0 failed**, exit 0. It also prints the unresolved 8-of-8 JSON reserialization mismatch and the minimal `[1] -> [1.0]` example. Passing historical-byte verification does not establish a portable serialization contract.

SE/KE2 still need to choose a versioned numeric/type normalization or retained-byte strategy for future transported records, with ordering, finite numbers, encoding, hash algorithm and content-digest scope specified. Preserve current runtime keys until a coordinated implementation and compatibility checks are ready; no SE-owned hashing function was changed.

## Verification commands and limits

```powershell
$godot = 'D:\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $godot --version
& $godot --headless --path . --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/se_report_evidence.log' --script res://docs/expansion-plan/evidence/se-report-evidence-check.gd
& $godot --headless --path 'D:/orbitbridge-mission-architect/exports/k20-draft2-review' --log-file 'D:/orbitbridge-mission-architect/exports/check-logs/se_binding_reconstruction.log' --script res://se-binding-reconstruction.gd
git diff --check
```

Godot `4.7.2.stable.mono.official.ed1daf0bf` confirmed. Reconstruction ends `Handoff probe failures: 0`; the review checker passes 85 checks while preserving the transport caveat. Certificate-store diagnostic persists. Python verified historical Git blobs against all eight packet hashes, SHA-256 preimages, native replay equality, candidate-only version changes, bundle manifest and local links. No new production evaluator output, UI/storage integration, full regression suite, browser or exported build was exercised. Original production replies and signed contracts remain unchanged.

The isolated reconstruction script copies the original probe, changes its output destination to `res://se-binding-reconstruction.json`, and retains `JSON.stringify([trace.config, trace.final_state, trace.events, trace.validation], "", true, true)` alongside each typed trace's original key. It runs on the eight matching baseline files; it is an evidence reconstruction, not a v2 engine migration.

The bundle was also extracted into fresh ignored `exports/se-report-review-unpack` and both programs rerun against its included minimal historical project: 85 checks passed, native probe failures 0, exits 0. Its manifest covers all 176 payload files (177 archive members including the manifest). `README-SE-REVIEW.md` inside the ZIP gives the two runnable commands for that extraction. The included historical project is for these headless evidence checks and is not a complete playable/exported game.

## Prepared reply to SE

> Received SE's conditional report review. KE2 supports the proposed direction: preserve the envelope and captured-observation fields, retain legacy report v1, and review report v2 for expanded goals independently of config/state versions. Separate v2 candidate examples are prepared; original examples and production output remain unchanged. Please review candidate report revision `mission-report-goals-v2-draft-1` and agree its placement/output-selection rules with KE2/KE3 before adoption. The evidence bundle now includes the full packet and reproducible event/key checks. An isolated native replay reproduces all eight original keys. Direct JSON reserialization changes integer/float representation and mismatches all eight keys; please settle a versioned normalization or retained-byte strategy with KE2 before transported-record hashing. Saved-A fields are recorded as your proposal; sampling, producer versions, custom identity, scoring and actual expanded integration remain open.
