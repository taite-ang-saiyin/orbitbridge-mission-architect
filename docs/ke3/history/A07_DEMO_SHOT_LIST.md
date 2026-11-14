# A07: 2:30 demo plan and capture list

**Accessibility retest update:** D01/D02 are CLOSED. Focus DebriefScroll to use PageDown/Down and PageUp/Up; Operations now scrolls focused actions into view, including the focus outline at900x680. The historical mouse/larger-viewport workarounds below are no longer required for these two defects. Final91-check matrix and regressions pass; release captures and human/browser/live tests remain pending. See `A07_FIX_CHECKS.md`.

Prepared from the KE3 playbook A07 page9; case intentions from pages14/18. **This is preparation. No team-build recording, browser test or B02 pass is claimed.** A01-A06 are SYNTHETIC previews. The KE2 entry is a recorded sample with **launch_approved=false**.

## Timed shot list (150 seconds)

| Time | Shot / narration | Setup and controls | Team-build evidence to capture | Current preparation |
|---|---|---|---|---|
| 0:00-0:20 (20s) | Goal: show objective, selected target, capture goal, returned-data goal, duration and budget. Say capture and returned data are separate requirements. | Open the chosen team revision's Mission Creator. Use the owner-approved demo config; do not substitute the recorded sample for a validated launch. | Creator goal screenshot; record build SHA/config ID. | Preview selected-goal labels exist; **release capture PENDING**. |
| 0:20-0:55 (35s) | Design: show instrument, bus, battery, solar, radio, storage, orbit, launcher and selected launch profile. Point to supplied readiness/cost/mass/source result. | Builder→Readiness. Launch only when actual KE1 result is ready. Rehearse approved selections with SE/KE1. | Builder plus passing readiness/profile/source screenshot. Optionally capture blocked heavy-camera example separately. | Historical15385a4 candidate is BLOCKED. Newer readiness evidence exists separately but its integration must be confirmed. **Release capture PENDING**. |
| 0:55-1:25 (30s) | Decisions: Observe during access; Transmit during contact. Show stored and returned MB, battery Wh, provider-ordered timeline and contact reason. | Use the approved deterministic action script from HPC. Tab/Shift+Tab, Enter/Space in a tested team build. No invented mission clock, generated-data total or physics claim. | Operations screenshots at Observe and contact-on Transmit; one no-contact block showing unchanged data/step if it fits the story. | A03 keyboard fixture and R-H recorded events are available as labeled rehearsal material. **Team capture PENDING**. |
| 1:25-1:55 (30s) | Debrief cause: show supplied outcome/score, raw goals/actuals, one supported cause and same-run event. Say what the record proves, then show the suggested next experiment. | Open Results through SE's actual report-ready route. Show credits without treating missing metadata as a verified source. | Debrief plus resolved evidence screenshot from that same run; capture source panel separately. | Recorded sample can demonstrate partial25,1/4,7.7333333328/30 MB and evt_008/step8. It is an **unapproved recorded sample**, not the live demo result. |
| 1:55-2:30 (35s) | Change one part and rerun: Retry, keep mission/scenario fixed, edit one component, revalidate, start distinct B and show the supplied result. | Obtain an HPC/KE2-approved reproducible second-run sequence. Hold operations fixed where feasible; pre-stage/wait honestly or label any recorded transition. No fake instant simulation. | Retry draft before/after, new run ID/clean counters, second Debrief; original A preserved. | A06 rehearses a radio change and explicit terminal-fixture delivery. B success is authored; it does **not** prove radio causality. **Release capture PENDING**. |

If a real rerun does not fit35 seconds, agree and label a recorded segment from the same pinned team build, or state that B has just started. Never imply the A06 terminal-fixture button ran HPC. Do not mix a goal/config from one run with another run's trace/report. The complete goal→design→operations→debrief→retry capture must use one identified build and matching A/B identities.

## Team-build screenshots still required

| Capture ID | Required screenshot | Metadata to retain | State |
|---|---|---|---|
| DEMO-01 | Full-loop sequence: goal, Builder, passing Readiness, Operations, Results and Retry | Build SHA, config/catalog/validator/HPC/evaluator revisions, scenario/version and run IDs | RELEASE CAPTURE PENDING |
| DEMO-02 | Successful mission Debrief with both raw goals met | Matching terminal state/history and KE2 report; capture/returned distinction | RELEASE CAPTURE PENDING |
| DEMO-03 | Failed mission with supported cause and readable same-run evidence | Failure config/actions and event IDs; valid score0 versus null abort distinguished | RELEASE CAPTURE PENDING |
| DEMO-04 | Retry draft: exactly one part changed, requirements retained | A/B config snapshots and changed field; original A unchanged | RELEASE CAPTURE PENDING |
| DEMO-05 | New B Operations: new ID, clean counters/history/report | Initial B state and original A completion | RELEASE CAPTURE PENDING |
| DEMO-06 | Observe / contact-on Transmit / rejected no-contact request | Step, batteryWh, stored/returned decimalMB and provider reason; no-change rejection evidence | RELEASE CAPTURE PENDING |
| DEMO-07 | Debrief cause and linked timeline event | Run/mission identity, report root_causes reference and exact event message | RELEASE CAPTURE PENDING |
| DEMO-08 | Source/profile/visual credits | Canonical source IDs, resolved title/credit/locator, ledger revision and actual use | RELEASE CAPTURE PENDING |
| DEMO-09 | Small viewport + keyboard focus on essential controls | Viewport, build/platform/renderer, focus, long text/credits and D01/D02 retest | RELEASE CAPTURE PENDING |

Local A07 PNGs under `verification/a07-runs/confirm-*` and `ke2-windowed/` are rehearsal/defect evidence only. Do not relabel these as release screenshots.

## Local setup and controls

Open **`C:\Workspace\OrbitBridge\Event\ke3_outline_preview\project.godot`**, using preserved Godot4.7.2 Standard. Renderer is the preview's own Compatibility setting. Default startup is the empty Operations outline; launch the desired scene explicitly, without changing startup/settings:

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --path 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' --scene res://preview/a06_preview.tscn
```

Use `preview/a03_preview.tscn` for Operations fixture selection, `a05_preview.tscn` for long Debrief/score0/abort examples, `a06_preview.tscn` for redesign and B, or `ke2_recorded_preview.tscn` for the recorded KE2 report. All fixture entries must retain their SYNTHETIC/recorded labels.

- Tab/Shift+Tab: traverse controls. Enter/Space: activate focused buttons; option menus use arrow keys and Enter. Escape dismisses an open option menu and restores focus; **Back/Cancel is the explicit draft-cancel control**.
- A03: select ready_step_2→Observe; select contact_on→Transmit. Fixture selection is rehearsal setup, not an elapsed simulator step. Power-save has its own authored response after Observe.
- A05: select debrief_long; Show credits brings the credit section into view. Mouse wheel/scrollbar is the current workaround for long text. **D01 remains open for keyboard scrolling.**
- A06: initial Retry focus→activate→choose Radio002→Start second SYNTHETIC run→Observe→Deliver B terminal snapshot (fixture)→Request Results route. Back/Cancel restores the originating Debrief. Two fixture runs only; reopen the scene for a fresh rehearsal.
- Recorded KE2: choose full history or missing-linked-event negative fixture. Retry records a presentation intent only; it does not provide SE's live redesign flow.
- Use1280x720 or1024x768 for rehearsal. At900x680, D02 requires mouse scrolling to see contact-on Transmit. Local geometry/key tests are automated engine input, not a human-playtest certification.

## Wording and actual source use

Say **“Illustrative trajectory: a step-mapped diagram, not a physical flight path or coverage prediction.”** Preserve the diagram's on-screen label. HPC's authored windows are educational presets; synthetic results do not validate spacecraft performance.

`A04_SOURCES_FOR_KE2.md` records NASA Mission Viz visual-cue use (central body/path/marker and flat-ellipse cue). The preview does not reuse GMAT trajectories, orbital propagators, NASA code or model assets for this diagram. Preserve its existing visual attribution; ask KE2 to supply final production ledger/credit strings.

NASA CubeSat101's sample1U mass rule belongs to the selected KE1 readiness profile and needs actual executed rule/source metadata. It is not flight certification and is not a general rule for every profile. The recorded KE2 sample has source_ids=[] and no approved launch; selecting cubesat_1u_sample alone is not evidence to invent a NASA report credit. Its UI correctly shows unavailable profile credit. No other NASA reference or source eligibility was independently reverified by A07.

## Readiness to record

Confirm the intended team build, approved cases and run-bound reports with SE/KE1/HPC/KE2. Retest D01/D02, rehearse the150-second sequence and obtain actual team screenshots. Browser/live/export/human results remain **OPEN / NOT TESTED**. Next available integration work is a **B01 follow-up** on the now-available main1a82 controller; **do not start B02 as part of A07**.
