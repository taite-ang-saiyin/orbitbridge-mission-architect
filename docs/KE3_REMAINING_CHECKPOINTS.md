# Remaining KE3 checkpoint evidence

Candidate: latest SE `4712bc15440f5a71cb2165f7f7e7acc8fc15484f` merged locally
with prior KE3/KE2 candidate base `f07d24efbdea7aa1c6f08303bf78dd8828f1f06a`.
The previous uncommitted KE2/KE3 diff was applied cleanly in a new worktree.
The clean fetched main `e71aaf8712b9b9438247cb514467bb33bc015989` is a
different workflow and was tested separately, not overlaid on SE.

No exact shared/release SHA or final scope was supplied. Local passes must not
be reported as an approved build, official browser playtest or submission.

## New cases using unchanged stock data

`tests/ke3_power_launcher_check.gd` builds a supported eight-observation mission
through actual KE1/HPC APIs. Its selected parts are bus_basic,
instrument_advanced, solar_standard, battery_standard, radio_fast and
storage_large; illustrative_alternative profile, medium launcher, high_inc,
nine orbits,192MB goal,150-credit budget. Actual readiness passes1490g/128cr.

The explicit API action schedule observes at target slot1 each orbit, transmits
when in contact with stored data, and records one deliberate no-contact request
at step8. Rejected requests are followed by HPC Power-save. There is no energy
injection, custom capability value or replacement physics. HPC reaches90/90
with95 ordered events: three LOW_BATTERY blocks, one NO_LINK_WINDOW block,
7/8 captures and168/192MB. Actual KE2 outcome is partial/88. Its first power
cause resolves evt_073 to step71. This is an evidenced power-limited science
shortfall, not a fabricated failed/zero outcome. Repeat execution matches all
non-identity state, ordered events, actions and report values exactly.

The alternative profile's mass rule is illustrative; no CubeSat1U readiness
credit is attached to it. Feedback credit comes from the actual emitted cause.
This is full validated provider integration plus report display, not a manual
science-action UI journey on the policy-playback candidate.

The stock1810g configuration (advanced instrument, large solar/battery/storage,
fast radio, basic bus, small launcher, high_inc) exceeds the actual1500g launcher
limit. Validator returns LAUNCHER_CAPACITY_EXCEEDED and PROFILE_MASS_EXCEEDED.
Actual Readiness disables Launch and guards direct Operations entry. The earlier
1380g profile-only failure remains separate. Clean-main K14 independently covers
an existing1580g launcher-capacity case.

## Verification scopes

- Patched SE candidate: existing KE1 suites1435checks, HPC48, KE2 evaluator207
  with five retained pending items, route/accessibility338checks per mode,
  fresh science cases54per mode and archived packet UI31per mode all pass.
- New power/capacity suite:425passing headless and425windowed checks.
- New SE Mission Control suite passes on clean SE and local candidate.
- Clean main: existing workflow/screen/K14 suites pass. A separate manual
  check passes21checks per mode: enabled Power-save/Observe/Transmit each
  dispatches once; disabled physical clicks dispatch zero; focus dispatches
  zero; copied-session HPC rejection leaves original history untouched;
  Results receives the report for that exact run.

Clean main's immediate same-design Retry and single-target workflow do not
replace the candidate's editable Retry or extended-target behavior. An owner
must select the route for shared acceptance. Survey on the candidate still
returns the explicit KE2 unsupported-objective response.

## Release and browser limits

No served Web URL/buildID, approved release inputs, timed teammate session,
final demo/submission links, organizer fallback acceptance or submitter receipt
was supplied. Browser control returned “Local browser access is unavailable for
this chat.” Signed-out access is unverified. A capture checklist is prepared
outside the repo from the existing2:30 plan; current PNGs are local QA evidence.

No production algorithm changes were needed in this continuation. Only this
handoff and the new test were added over the preserved candidate changes.
No original checkout/preview/evidence, shared branch or submission was changed.
