# Six-checkpoint candidate audit and KE3 publication

The archived audit tested `integration/ke2-se-results-d60d224@14c0f973c140e9644650e94e769b6b1b3dfb3951` as-is, then with a local Results identity/credit correction. It does not designate a shared release or verify a served Web build.

Read the [full six-checkpoint report](KE3_FINAL_STATUS.md), or download and extract [the complete candidate audit](candidate-audit.zip). The archive contains the original report with working relative evidence links, exact commands/exits, clean and corrected logs, run snapshots, screenshots, probes, preservation hashes, and a per-file SHA-256 manifest. All demonstrations are educational/synthetic scenario data.

| Checkpoint | Candidate audit result |
|---|---|
| B01 — Contracts and context | PARTIAL: real local route verified; shared-release designation/scope confirmation missing. |
| B03 — Operations and Debrief | PASS only with the recorded local correction and the candidate's policy-playback scope. |
| B10 — Served Web and timed human playtest | NOT TESTED: exact served team URL/build and teammate session missing. |
| B11 — Demo evidence | PARTIAL: candidate QA captures and shot-list preparation; approved release footage pending. |
| B12 — Public links and submission | PARTIAL: signed-out repository/README/source ledger access; final playable/demo/receipt pending. |
| B13 — Closeout | NOT TESTED: replacement release or submitter no-correction confirmation pending. |

Passed **1/6 (16.67%)**; partial **3/6 (50%)**; failed **0/6**; not tested **2/6 (33.33%)**. A local software check does not close the missing release, browser, human, submission, or organizer-acceptance evidence.

## Port onto KE3

Publication starts from the newer `KE3@a663da96309049d2ee0cffef7690d41e0c67295f`. It preserves that branch's existing controller, catalog controls, editable Retry and credit wording. It does not replace them with the older candidate implementation.

Only `ke3/debrief_screen.gd` changes production behavior: a report must match its supplied mission identity, goals and terminal counters as well as run ID. An inconsistent same-run report is unavailable as a trusted result and cannot Retry or expose report-scoped credits. Independently executed readiness credit remains available for a same-run identity mismatch; the existing rule that a foreign-run report hides all scoped credit metadata is preserved. Missing optional fields retain their existing display handling. No simulation or evaluator algorithm changed.

`tests/ke3_report_binding_check.gd` adds 32 checks using actual validated/HPC/evaluator component snapshots, including mismatch rejection, credit scopes, recovery and input immutability. It does not claim a new live team/browser run.

## Publication verification

Godot `4.7.2.stable.official.ed1daf0bf`. Commands, exits and scanned logs are in [publish-retest/commands.json](publish-retest/commands.json). All final executions exit 0 with no script/parser/runtime error:

- New report binding: **32 passing**.
- Existing KE2 adapted Results: **17 passing**.
- Controller evaluation: Launch/terminal/Results/Retry/Abort/New Mission passed (suite does not print an assertion total).
- A03: **256 passing**; A05: **139 passing**; A06 P0: **100 passing**.
- Validated recorded KE2 Debrief: **63 passing**.
- KE3 team flow: **338 passing headless**, **338 passing windowed Compatibility** (same cases in two modes).
- A07 at 900×680: **80 passing**.
- Headless project import passes.

The initial port exposed one existing foreign-run scoped-credit regression. Its failing 63-check run is retained in [publish/ke2_validated_debrief_check.log](publish/ke2_validated_debrief_check.log); the correction and passing rerun are retained separately. The archived older candidate's two original failures are also preserved. Neither failure was concealed or relabelled as a clean pass.

Run the new focused check from this repository using the installed Godot executable:

```text
godot --headless --path . --script res://tests/ke3_report_binding_check.gd
```

SE's integration branch, the user's active checkout and original preview were not changed by publication. See [draft owner requests](OWNER_REQUESTS.txt); no teammate message was sent.
