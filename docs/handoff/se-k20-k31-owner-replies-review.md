# SE review of K20–K31 owner replies

Date: 15 November 2026, Asia/Rangoon.
Reviewed branch: `se`.
Reviewed commit: `5abc659c2649ed030b10322bb4cab67461132f47`.
Source: `OrbitBridge-K20-K31-Owner-Replies.md`, revision `owner-replies-draft-1`.

## Conclusion

The proposals broadly fit the SE implementation, but the form cannot be marked fully implemented. It contains blank owner replies and explicitly records no new approvals. The document's requests were reviewed as proposals, not treated as authorization to change code or approve another owner's work.

SE storage/controller hooks are implemented. Production v2 integration, Creator lineage transitions, capability loading and KE3 presentation wiring remain incomplete. No final game integration approval is established.

## Proposal versus current SE code

| Item | Current status |
| --- | --- |
| D1: v2 propagation | Explicitly supplied goals, preset IDs and revisions are mapped, reviewed and snapshotted. Legacy drafts retain v1 behavior. Live v2 validation/launch remains blocked. |
| D2: Survey | Existing simulation retains per-target delivery evidence. Production Survey scoring is not integrated. This decision belongs to HPC/KE2. |
| D3: Communication | Proposed count fields and successful-transmission-step review wording are supported. Positive-step/window semantics and production evaluation remain pending HPC/KE2 agreement and implementation. |
| D4: Weather | Proposed distinct-orbit fields and review wording are supported. Capture-plus-pooled-MB semantics are a proposal in the form, not newly recorded owner agreement or production behavior. |
| D5: fixed B mission | Full mission/orbit checks and saved-A preservation exist. Launcher/profile restrictions are enforced in Builder UI but have an API guard gap described below. |
| D6: Creator/edit identity | Incomplete. Creator can change objective without updating preset lineage and the corresponding goal. Compatible edits and goal-type transitions need an explicit rule. |
| D7: capability source | Unresolved. No agreed explicit v2 capability source/loader exists in this checkout. Current runtime adds Survey support to instruments in memory. |
| Saved A/API | Save/Replace/Clear, Continue B, Cancel-return, selected Results, portable export and comparison-provider hooks are implemented. |
| Run storage | Independent archived execution packets retain snapshots, readiness, events, resource frames, reports and versions. B gets fresh initialization and cannot automatically overwrite saved A. |
| UI ownership | SE provides an optional continuation popup and Builder/Readiness integration. KE3 still needs to wire Results Save/Continue/Compare controls and comparison presentation. |
| Launch/release | Unsupported v2 inputs remain blocked. No public-build, browser, Netlify or five-mission acceptance is established by these hooks. |

## Confirmed guard gap: launcher/profile changes during B

Builder disables orbit, policy, launcher and launch-profile selectors during B. Its reset operation also preserves the selected launcher/profile.

However, `design_lab.gd::launch_b()` and `comparison_inputs()` compare mission requirements and orbit without enforcing unchanged `design.launcher_id` and `design.launch_profile_id`.

A targeted headless reproduction used an ordinary Imaging fixture with a 200-credit budget, saved A, then changed B to `medium` launcher and `illustrative_alternative` profile through the draft/API:

```text
Changed launcher/profile accepted by launch_b: true
Changed launcher/profile accepted by comparison_inputs: true
```

If the intended B scope is spacecraft components only, add launcher/profile equality checks at both boundaries. If these fields are intentionally editable, agree that scope explicitly and update the UI/contract consistently. UI disabling alone does not enforce the API contract.

Relevant code:

- `scripts/screens/SpacecraftBuilder.gd`: B setup controls, reset and read-only A reference.
- `scripts/integration/design_lab.gd::launch_b()`.
- `scripts/integration/design_lab.gd::comparison_inputs()`.

## Other remaining integration work

### Creator identity transitions

`scripts/screens/MissionCreator.gd::build_objectives()` updates `state.objective` directly. It does not select a matching preset context or update `mission.goal`.

Before enabling v2 cards, define compatible edits that retain authored lineage and an explicit transition when the goal type changes. Freeze the full edited requirements and invalidate mission review. Titles must not supply identity.

### Capability source and production launch

`scripts/integration/mission_runtime.gd::load_game_catalogs()` currently extends v1 catalogs in memory with Survey support. It has no separate agreed v2 capability loader.

KE1/HPC/SE must agree the exact source filename, schema/revision and loader/adapter entry points. Preserve supported v1 loading. Do not register new objectives solely in UI code or strip goals to make v1 validation pass.

The current production validator and HPC adapter remain v1 boundaries. SE field propagation is not production v2 acceptance.

### Evaluation, reports and comparison

`MissionController.comparison_provider` remains an unconnected callable seam. Test-provider success does not establish production KE2 comparison.

KE2 must supply live expanded evaluation and the comparison callable. KE3 must support both report versions and connect selected-run Results to the existing controller APIs. The SE report-selection helper remains a proposal rather than a production evaluator migration.

### Resource sampling

Runtime traces retain the initial state and post-action frames, including terminal state. They can also contain a frame for a rejected request before the fallback accepted power-save step.

HPC must confirm the agreed sample definition and whether the initial-plus-accepted-step view filters these rejected-request frames. Existing retention does not settle sampling IDs, sparse-map semantics or evaluator interpretation.

## Existing controller calls to reference

| Purpose | Controller callable |
| --- | --- |
| Save A | `save_design_a(execution_key)` |
| Save A and show optional continuation popup | `offer_design_b(execution_key)` |
| Read saved A | `get_saved_design_a()` |
| Replace A explicitly | `replace_design_a(new_key, expected_a_key)` |
| Clear saved selection | `clear_design_a(expected_a_key)` |
| Continue B from saved A | `continue_saved_design_a()` |
| Cancel B and return to origin Results | `cancel_design_b(origin_execution_key)` |
| Run B | `run_design_b(origin_execution_key)`; Readiness also delegates to the guarded B path |
| Open selected saved Results | `show_execution_result(execution_key)` |
| Obtain comparison inputs | `comparison_inputs(b_execution_key)` |
| Call connected comparator | `compare_executions(b_execution_key)` |
| Export portable saved-A record | `export_saved_design_a()` |

Continue B must use `continue_saved_design_a()`, rather than redesigning whichever result is currently selected. All hooks use execution keys rather than titles or list positions.

## Referenced preparation files missing from this checkout

- `docs/ke1-expansion/k22-draft-checker.md`
- `docs/ke1-expansion/k23-five-mission-readiness.md`
- `docs/ke1-expansion/k26-survey-preparation.md`
- `docs/ke1-expansion/k27-ab-handoff.md`

These are missing local paths, not evidence that KE1 has not prepared the materials. Reference the existing verified JSON packet and eight keys; they do not need resupplying.

## Verification and limits

This review inspected the current SE sources and ran the targeted launcher/profile reproduction with Godot 4.7.2. No game source was changed during the review. The reproduction was headless and does not establish browser behavior or release acceptance.

Previously recorded checks at the reviewed implementation include 45 passing regression programs, 36 transport/historical-key checks and 76 saved-A lifecycle/export checks. Those suites were not rerun for this read-only review. The newly reproduced guard gap is outside the previously asserted launcher/profile restrictions and should receive a focused regression check when fixed.

## Recommended SE response

> Hooks and storage are implemented and tested; v2 production integration is in progress. Capability loading, Creator identity transitions, KE3 wiring and launcher/profile guards remain open. Exact v2 loader details and shared gameplay semantics still need owner coordination. No final game integration approval is claimed.

This is an SE code review and proposed response, not a completed owner approval form or a reply sent to teammates.
