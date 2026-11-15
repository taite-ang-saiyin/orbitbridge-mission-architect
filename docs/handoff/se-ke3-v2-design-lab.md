# SE Design Lab handoff

15 November 2026, Asia/Rangoon. Base: `dce75db845f6c494b8c25c9028dd9c0648aabd91`.
Implementation is local on `se`, uncommitted and unpublished. No new mission data, capability rules, physical values, engine/evaluator behavior or signed contracts are introduced.

## KE3 integration

Use the selected Results model's `execution_key`, never a title, list position or latest run ID.

| Controller method | Purpose |
| --- | --- |
| `offer_design_b(key)` | Explicitly save the selected completed evaluated A and open the continuation popup. Not now leaves A saved. Create Design B delegates to the saved-A entry point. |
| `save_design_a(key)` | Save without opening SE's optional popup, for KE3's own UI. |
| `get_saved_design_a()` | Return a verified deep copy or `{ok:true,execution:null}`. |
| `continue_saved_design_a()` | Create B from saved A regardless of the currently displayed result. Routes directly to Builder. |
| `replace_design_a(new_key, expected_a_key)` | Explicit replacement protected against a stale A selection. |
| `clear_design_a(expected_a_key)` | Clear selection, retain execution history. |
| `get_execution(key)` | Get verified execution evidence. |
| `show_execution_result(key)` | Display the selected run, including one evicted from playback cache. |
| `modify_execution(key)` | General selected-run redesign; KE3's Continue B should use `continue_saved_design_a()` instead. |
| `cancel_design_b(origin_key)` | Discard draft and restore origin Results. |
| `run_design_b(origin_key)` | Validate/launch a fresh B against the frozen source setup. Readiness delegates to the same launch checks. |
| `comparison_inputs(b_key)` | Return bound A/B inputs and operations classification. |
| `compare_executions(b_key)` | Invoke `comparison_provider`; no production comparison is supplied here. |

Every hook returns `{ok:true,...}` or `{ok:false,error:{code,message}}`. Only actually completed, evaluated and fully recorded executions are eligible; completed goal shortfalls are allowed. Aborted/incomplete runs are not eligible.

The controller provides the optional **Design A saved** popup with **Create Design B / Not now**. KE3 must connect its Results Save button to `offer_design_b`, and its later **Continue Design B** button to `continue_saved_design_a`. No new Results Save/Continue/Compare widgets or Operations layout changes are included. The small Results change exposes a selected execution key and selected-execution display entry point.

Builder adds an Editing Design B banner, read-only A component reference, fixed orbit/policy/launcher/profile controls, and Cancel Design B. Navigation into editable Mission Creator/Mission Control is blocked while B is being edited. Readiness identifies B and labels its launch button. Changes to fixed requirements also fail the launch-time comparison guard. New Mission explicitly resets the session; KE3 should explain that session comparison data will be cleared.

## Stored evidence

`evaluation_store.executions[key]` retains independently sealed execution packets beyond the two-trace playback buffer. A stores an execution key into that archive; getters return deep copies and verify content digests. Packets include config, original validation, catalogs, scenario/terminal state, ordered events, initial/post-step resource frames, draft snapshot, requested/actual actions, manual overrides, policy, module/catalog hashes, original evaluation wrapper and source-credit context.

The existing KE2 execution key algorithm is preserved. An additional digest covers retained evidence beyond that key. Saved A remains independent of the legacy automatic `baseline`, which must not be presented as explicit Saved A. B publication, Retry and Cancel preserve A; replacement/clear are explicit.

B replays recorded requests against fresh engine state, not A's resource outcomes. Rejected planned requests are retained and followed by a power-save advance; HPC still needs to agree this runner convention. Requested-policy/manual differences classify comparisons as design plus operations. Matching accepted actions is not required. Source hashes must be supplied at build time if an export strips source files; missing version evidence blocks comparison.

## Config propagation and boundaries

SE maps explicitly supplied `schema_version`, `contract_revision`, `preset_id`, `preset_revision` and nested `goal` into config, mission review and draft snapshots. New fields are never inferred from a title or invented from counts. Legacy drafts without those fields keep the existing v1 shape. Goal/revision edits invalidate mission confirmation; root identity/revisions participate in B launch and pair matching. Retry restores recorded contract fields and removes unrelated draft metadata.

No new preset values/cards or live v2 acceptance are added. Current KE1 validator/HPC launch still rejects unsupported v2 inputs; SE does not strip their goals or convert them to Imaging to launch. KE1/HPC must deliver production acceptance; KE2 supplies expanded evaluation and callable comparison; KE3 supplies dynamic goal rendering and Results widgets. Weather delivery, contact/revolution evidence and resource-sampling contracts remain pending owner agreement.

Connect `controller.comparison_provider` with a callable receiving `{ok,a,b,mode}` and returning `{ok:true,comparison:{a_execution_key:...,b_execution_key:...,...}}`. The adapter checks the pair identities. Until connected, it returns `COMPARISON_PROVIDER_UNAVAILABLE`; test providers do not establish production comparison.

## Verification

Godot 4.7.2: all 44 maintained headless programs passed. Final focused/UI checks were rerun after follow-up changes; see `docs/integration-evidence/se-v2-hook-checks.json`. The hook suite covers Save A popup / Not now / Continue / Cancel / fresh B via Readiness / A retention, cache eviction, snapshots, tamper detection, explicit replacement/clear and v2 propagation without production acceptance.

These are headless signal/control tests. No browser journey, export, deployment or final KE3 widget integration is claimed.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/se_design_lab_hooks.gd
```
