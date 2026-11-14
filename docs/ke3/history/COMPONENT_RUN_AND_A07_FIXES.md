# Pulled SE route, validated KE1-HPC run, and A07 fixes

Completed locally on14 November2026. **Validated component run PASS; A07 D01/D02 CLOSED; B02 NOT TESTED.** No merge, production wiring, push, publication or teammate message. All team execution used separate detached checkouts in this folder; accessibility edits were confined to the KE3 preview.

## 1. SE revision and actual runtime route

- Active checkout: `C:\Workspace\OrbitBridge\orbitbridge-mission-architect`; clean **main@1a82ebd93a019b751947965aa760e8e759d8f45b**, unchanged before/after. Project: `C:\Workspace\OrbitBridge\orbitbridge-mission-architect\project.godot`.
- Explicit renderer is **gl_compatibility**, verified in the isolated windowed execution. config.features still contains Forward Plus and the old d3d12 driver entry remains, but those declarations were not substituted for the actual active renderer. No setting changed.
- No SE handoff confirming a real-module integration SHA was found in the supplied HANDOFF_CHECK, REPORT_CHECK, B01 mapping, current repository handoff/kickoff docs or recent locally named SE handoff files. Intended integration SHA is **UNVERIFIED/not supplied**; no SHA difference can be computed. The user identifying this as pulled SE work establishes provenance of the shell, not completion of the v1 producer wiring.
- Available docs/kickoff.md records the user's09:00 kickoff confirmation and the signed v1.0-agreed baseline. No separate SE-start message was supplied. Earlier preparation statements were not treated as a reason to stop authorized testing.

Actual route inspected at this SHA, including the functions invoked:

| Boundary | Actual files/methods and runtime evidence | Status / owner |
|---|---|---|
| Shell entry | scenes/Main.tscn -> scripts/MissionController.gd; initial state=data/mock/DesignCatalog.gd.DEFAULTS; show_screen(index) instantiates screen, assigns shared current.state and connects navigate | Shell exists; not a canonical config/run owner yet. SE |
| Builder | wrapper scenes/screens/SpacecraftBuilder.tscn -> nested spacecraft_builder scene -> scripts/screens/SpacecraftBuilder.gd::_ready/select_component/refresh; calls SatelliteAdapter.ensure/refresh. Actual UI selection dev_body_2 is retained with dev_wings_1/dev_radio_1. | **First missing/mock boundary:** Body/Wings/Radio development IDs and flat mission fields do not map into canonical MissionConfig/six subsystem catalog IDs. SE + KE1 mapping |
| Readiness | scripts/screens/FlightReadiness.gd::_ready calls data/mock/SatelliteAdapter.gd.refresh; Launch callback calls it again, gates on can_proceed, deep-copies that mock validation into state.run_design and emits navigate4. ReadinessFixture supplies fixed checklist/gauges. Actual label DEVELOPMENT PREVIEW and validation.source=development_mock. | Does not call KE1 MissionValidator. Passing mock ID membership is not ready_to_launch. SE |
| Operations | scripts/screens/MissionOperations.gd::_ready copies run_design to run_configuration; DATA=data/mock/OperationsFixture.gd. seek/step/skip_to_end replay authored snapshots. Actual run has no run_id or canonical availability/state/history boundary. | No HPC init_run/get_available_actions/request_action; no real ordered event accumulation. SE wiring pending |
| Results | scenes/screens/DebriefCompare.tscn -> scripts/prototype/Screen.gd::debrief/show_run -> data/mock/PrototypeData.gd.RUNS. | Authored Run A/B results, no KE2 evaluate_mission/report identity/evidence lookup. SE wiring pending |
| Redesign/reset | Debrief Modify Design emits navigate2; new_mission resets DesignCatalog defaults/routes Creator. Operations playback reset seeks0. | Navigation exists, but no new run ID, frozen canonical config, matching report registry, HPC event reset, asynchronous correlation or real Retry lifecycle is established. SE |

This classification follows actual calls and runtime snapshots, not the mere presence of mock files. The real KE1 loader/validator, HPC adapter/step engine and KE2 evaluator paths are absent on this SE tree (exact path checks: evidence/se-inspection.json).

An isolated windowed **existing-UI keyboard probe** selected a Builder part, activated Continue, Launch, Skip to End, View Debrief and Modify Design through existing controls. It reached Readiness, authored Operations, mock DebriefCompare and returned to Builder; exit0, no script errors. Capture/values: evidence/se-prototype/route-results.json and builder/readiness/operations-fixture-end/mock-results PNGs. Runtime Compatibility confirmed. This is **prototype route evidence only**. No real-module B02 was attempted because the route fails the required source boundary before launch. B02 remains NOT TESTED, not a full-test FAIL or PASS.

## 2. Exact validated KE1-to-HPC execution

KE1 **55d4f336e72a68ff31cf37e44f65a98c1cdcc193**, fixture **tests/fixtures/valid_1u_feasible.json**, actual CatalogLoader/MissionValidator and all catalogs from that same commit. Applicable KE1 AGENTS.md, README/tasks/kickoff/handoff were read; no other applicable AGENTS was found in the preview/HPC/SE workspaces or ancestors. Owner instructions were used as guidance, not permission to implement KE1/SE production changes.

Actual readiness (ke2_bundle/readiness.json, unmodified result): **ready_to_launch=true, all8 checks pass,1060g,82credits**, errors/warnings empty. Checks: input_schema, catalog_references, profile_mass, launcher_capacity, budget, launch_orbit, target_orbit, essential_power. Profile **cubesat_1u_sample**, source **cubesat_101_1u_sample**, mass comparator `<`, threshold1330g. Actual expected fields all match; input/catalog copies unchanged; repeated validation deterministic. Full nine metrics and selected profile/source metadata are preserved. No historical false result or documentation-ready example was substituted.

HPC pin **9dfd942e6fccf230d03dfdf8bf097bf65d8f143f**, the previously supplied/inspected operational handoff. It is chosen as an exact available revision, not claimed to be today's unverified latest remote. Core engine/adapter/planner and orbit data are unchanged relative to older ce478f9; the handoff/sample labeling changed. KE1 and HPC orbit-source documents match byte for byte.

Documented boundary executed: build_scenario(actual loaded catalog bundle, HPC orbit document), validate_config(unchanged config, scenario), then init_run(config, scenario, fresh run_id, mission_id), get_available_actions and request_action. **ValidationResult is not an engine/adapter parameter**; the isolated coordinator checks/stores the real result before init_run, exactly as docs/hpc-integration.md requires. It is not modified, converted to an ok wrapper or bypassed. Adapter/config resolution return ok=true; no field/ID/unit mismatch found.

Fresh run **ke3_validated_1u_55d4f33_9dfd942_20261114_01**, mission **ke3_validated_1u_feasible_20261114**. Scenario **high_inc / orbit-presets-v1**;6 orbits,10 steps/orbit,0.1611111111 hours/step. Units **Wh and decimalMB**, radio rate decimalMB/hour. Uses the supplied sample schedule with the new exact fixture: Power-save0, Observe1, Power-save2-6, Transmit7, deliberately rejected Transmit8, Power-save8-59. Full action availability and all61 requests are saved; no physics was reimplemented.

| Actual event | Evidence |
|---|---|
| Accepted Observe |evt_001 at step1 with target access; captures1 and stores12MB|
| Accepted Transmit |evt_007 at step7 with ground contact; returns7.7333333328MB|
| Rejected Transmit |evt_008 at step8; action_blocked, NO_LINK_WINDOW, supplied nonempty reason. Every state field except event_log/next_event_sequence is unchanged; exactly one blocked event appended.|
| Terminal |evt_061 mission_finished; completed60/60,1 captured,7.7333333328MB returned,4.2666666672MB stored,21.9388888890999Wh|

Complete62-event provider order is evt_000..evt_061, with the new run/mission identity throughout. Collected reply deltas exactly equal final event_log; no sorting, renumbering or synthesized history. The deliberate action schedule is not intended to meet4-capture/30MB goals. KE3 has **not assigned a new score or outcome**; matching KE2 report is pending.

Bundle: **C:\Workspace\OrbitBridge\Event\ke3_validated_run_a07_fixes\ke2_bundle**, attachable **C:\Workspace\OrbitBridge\Event\ke3_validated_run_a07_fixes\ke2_bundle.zip**. Contains byte-preserved original config, actual readiness, catalogs/profile/source, exact scenario/orbit document, initial/final states, action sequence, selected raw replies, full events, identity/SHAs and file hashes. ZIP CRC and every archived file's bytes verified. See evidence/bundle-integrity.json and ke2_bundle/provenance.json.

The old **run_ke2_handoff_v01** report remains attached to its original **ce478f9** recorded trace with launch_approved=false. Similar counters do not make it a matching report for this run. The new validated component run has actual passing readiness; it still is not an SE integrated player journey or scientific spacecraft validation. KE2_REQUEST_DRAFT.md requests this exact run's report/evidence/credits; not sent.

## 3. Accessibility fixes and retests

Original failures and captures archived before editing under `C:\Workspace\OrbitBridge\Event\ke3_outline_preview\verification\a07-fix-before`; fresh original900x680 reproduction:78 checks,2 failures,exit1. Both original assertions remain active. Fixes only in preview ke3/debrief_screen.gd, ke3/operations_screen.gd; test extensions in tests/a07_local_qa_check.gd. Details/current closure: A07_DEFECTS.md / A07_FIX_CHECKS.md. Original A07_CHECKS/QA/demo reports retain dated history plus current-status addenda.

- **D01 CLOSED:** focused report-region key handling scrolls PageDown/Down and PageUp/Up, clamps pixel position and consumes handled keys without moving footer focus. At900x680:0→362→394→362→0. Tab/Shift+Tab, visible focus, Credits, Retry, outside-region key handling and raw report/state/labels are preserved.
- **D02 CLOSED:** native follow_focus plus4px vertical focus-outline padding. At900x680 Transmit moves from y665..696 outside clip y144..656 to y621..652; complete3px outline fits. Observe/Power-save visibility also pass. Focus emits0; enabled Space Transmit exactly1; disabled Transmit0. Provider legality/telemetry unchanged.

Final91-check windowed matrix: **1280x720,1024x768,900x680 and independent1024x768 repeat all91 passed,0 failed,exit0**. Semantic repeat outputs match (only diagnostic ObjectIDs normalized). No remaining failure in the requested local matrix. After screenshots reviewed, including complete Transmit outline. Before/after evidence and exact reproduction/closure records remain separate.

Regressions, headless/windowed: A03 **256/259**, A04 **206/210**, A04 separate restart **9/10 each process**, A05 **139/156**, A06 **100/104**, recorded KE2 Debrief **49/52**, all0 failures/exits0. Reused the full A07 runner execution, which also passed A01, A02 **254/255**, import, all9 existing scene startups and parser check. Latest canonical after command set **36 PASS /0 FAIL**. Source settings/session/providers/fixtures remain untouched.

## 4. Commands, preservation and pending owners

Exact component/SE argv, cwd, exit/error scans and logs: **COMMANDS.md**, evidence/commands.json. Readiness, HPC run, SE import and existing mock-UI probe all exit0. Local clone/fetch/detached preparations all exit0, recorded in prepare-commands.json. Accessibility original reproduction exits1 as expected; final runner after exits0; every child command and old failing attempt retained in **C:\Workspace\OrbitBridge\Event\ke3_outline_preview\A07_FIX_COMMANDS.md** and its fix manifest. No tests were inferred from source inspection alone.

Active team branch/HEAD/status/refs and **247 tracked file hashes** are unchanged. Preview startup hash unchanged; only allowed preview code/test/docs changes, no concurrent changes overwritten. Source/runtime hashes and bundle integrity recorded. Godot-generated cache/import files exist only in test copies/preview. No branch merge, production adapter wiring, message, publish or push.

Remaining owners: **SE** must supply/confirm and connect a real v1 producer-wired integration revision; first missing boundary is canonical Builder/config/readiness mapping. **KE2** must evaluate the new exact run and return matching report/evidence/source credits. No new KE1 or HPC component defect/blocker was found, so no duplicate requests to those owners. Copy-ready unsent requests: SE_REQUEST_DRAFT.md and KE2_REQUEST_DRAFT.md.

**B02 NOT TESTED** until the actual Builder→Readiness→Operations→Results route runs on SE's confirmed integration SHA with that integrated run's matching KE2 report. Human/browser/export/submission checks remain NOT TESTED. Stop after these checks/fixes.
