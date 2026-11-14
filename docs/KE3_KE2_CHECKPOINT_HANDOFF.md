# KE3 and KE2 local checkpoint integration

This candidate combines KE3 `eddedaa13e17ad116c1b1a54f578ad52cb43b221`
with SE `8da3b120409624c9d892a53ade5a74ee13029a8c`, then selectively ports
KE2 `14c0f973c140e9644650e94e769b6b1b3dfb3951`. The evaluator source is
unchanged from KE2 `b23de72dc251ee7cc1d4e3662aa0a8b3de0cfb6e`.
The previous KE3 integration behavior is already committed; do not reapply
the older KE3_LOCAL.diff. No shared integration/release SHA is designated here.

## Preserved owner behavior

SE's current Creator, canonical six-slot Builder, target/Survey extensions,
validated launch, policy playback, predictions, terminal-only evaluation and
editable Retry/Cancel remain. No simulator, validator or scoring algorithm was
rewritten. The fetched main branch has a divergent stable workflow; switching
to it needs a team decision rather than overwriting this SE route.

## KE2 sources and binding

The evaluator, feedback, NASA source ledger and standalone evaluator suite are
ported verbatim from KE2. The trace adapter's input_key/evaluate_trace/context
methods are preserved alongside SE's publish/retry/baseline lifecycle. KE2's
integration test is adapted to delayed terminal publication and current hooks,
without loading a recorded report at Launch. Upstream test bytes are retained
with the local evidence for review.

The input key binds config, full terminal state, complete ordered events and
actual validation. Publishing an already-used ID for a different execution is
rejected. Runtime identities now use KE2's random session namespace plus SE's
monotonic sequence, preserving deterministic physics and policy selection.
Legacy packet IDs are never rewritten.

Results history includes its complete event log so presentation derives the
same key. Feedback credits require an accepted report and matching native
history; readiness attribution remains bound to the executed validation when a
report is rejected. This closes the matching-history/stale-report credit leak.
The scoped ledger metadata stays beside the unchanged evaluator report.

`mission_results.bind_packet(trace, reply, metadata, input_hashes, case_id)` is
an optional boundary for a caller that has verified original input/report file
hashes. It checks case/execution key, supplied input hashes, run/mission identity,
goals and counters and returns an isolated store. Archive/file loading is outside
runtime. `input_hashes` contains config.json, final-state.json, events.json and
readiness.json digests. The external caller must verify report_sha256 before
passing the parsed reply. Packet files are not imported into normal gameplay.

Operations retains full IDs in its tooltip and Results while keeping the compact
step/resource HUD readable. The Recent Events header stacks beside its filter at
small widths. Neither change dispatches an action or changes HPC state.

## Verification

- KE1: 294 + 671 + 470 passing checks.
- HPC: 48 passing checks, plus multi-target prediction/execution parity suite.
- KE2: 207 passing checks, 5 upstream pending items retained.
- Adapted KE2 adapter suite: 17 passing checks.
- Existing controller, integration, Creator/Builder, expanded-mission,
  Operations and prototype suites pass.
- KE3 real route, Retry, stale/missing report and three-viewport accessibility:
  338 passing headless and 338 windowed checks.
- Archived packet UI: 31 passing headless and 31 windowed checks; Python verifies
  123 archive/input/report/supporting-evidence checks.
- Fresh checkpoint cases: 54 passing in each mode. Both-goals-met yields100;
  low_eq_3orbits yields87; return_goal_60mb yields90 from fresh KE2 evaluation.
  Actual Creator→Builder→Readiness→Operations→Results is exercised for each.

The expanded KE2 suite requires docs/hpc-ke3-ops-trace-v0.2.json, imported as
a test-only recorded fixture from main fa1df3e. It is not loaded by gameplay.

## Remaining acceptance boundaries

Manual Observe/Transmit/Power-save dispatch is unavailable on this policy
playback route. Independent no-contact and low-energy probes are not merged
into player histories. The full validated power-limited failure case still
needs owner config/catalog/scenario, action sequence and terminal trace.

Survey simulation works but KE2 returns an explicit unsupported-objective error;
per-target scoring requires KE2. A/B comparison remains optional/null.

The shared revision, release build, served Compatibility Web URL/build ID,
uncoached teammate playtest, approved demo inputs, final submission links,
submitter confirmation and any organizer fallback acceptance remain pending.
Local captures are QA evidence, not release screenshots or official B10.
