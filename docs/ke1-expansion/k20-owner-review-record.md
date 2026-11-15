# K20 owner-review record

**Latest HPC status:** [Conditional review received and exact clarifications](hpc-k20-clarifications.md). Final HPC acknowledgment remains pending; non-HPC agreements stay settled. State/event v1 is conditional on implementation compatibility. Current code still rejects v2. Earlier pending-owner statements below are historical. Existing ZIPs remain unchanged; this clarification postdates the current handoff archive.


**Current K20 status — user confirmation, 15 November 2026:** All non-HPC agreement items are already agreed. **HPC is the only remaining K20 confirmation.** Do not request SE/KE2/KE3 agreement again for those settled items. This records the user's confirmation; earlier pending-owner notes below describe previous checkpoints. K20 remains unchecked until HPC replies and the matching consolidated revision is recorded. Code implementation, known SE guard/Creator fixes, production evaluator/comparison support and final build/browser tests remain separate unfinished work. New mission launches remain blocked. Reviewed ZIPs and signed v1 contracts remain unchanged.


Recorded 15 November 2026, Asia/Rangoon, from teammate messages relayed by the user. Applies to config `expansion-goals-v2-draft-2`, registry `five-presets-candidate-2`, Communication preset revision `2`, and review additions `k20-review-additions-1` where explicitly reported. **Review receipt/support is recorded; final agreement and integration approval remain pending.**

## Received feedback

| Owner | Reported review and verification | Scope of confirmation | Still pending |
| --- | --- | --- | --- |
| SE | Reviewed additions package; reported all 69 payload hashes matching, 110 physical/Weather checks and 70 catalog checks passing against the stated main in a temporary copy | Accepts the package as the basis for coordinated implementation planning; earlier gaps addressed | W1/C1, Creator/custom identity, capability source, evidence/scoring/envelope versions and final SE acceptance/integration |
| KE3 | Reviewed Additions 1; reported hashes matching and 110 physical checks reproduced | Confirms review material for presentation planning | Updated definitions/capabilities/versions, KE2 scoring and final integration; no approval to enable cards |
| KE2 | Confirmed receipt of draft 2, candidate 2 and Communication revision 2; reported hashes matching, 629 checks reproduced and an additional same-config Communication control passing | Supports config choices and the fast-radio starter; original preset requirements preserved | Production v2 validation/bounds/unknown fields, custom identity, HPC/SE confirmation, scoring/report/comparison agreement |
| HPC | No confirmation has been supplied in this chat | Not recorded | Event/index/packet evidence, policy/starter confirmation, own envelope versions and final acceptance |

The test counts above are **teammate-reported reproductions**, not new local engine runs in this status-update task. The extra KE2 control's detailed trace was not supplied, so no new count or trace is invented for it. SE's 69 hashes refer to payload entries; the supplied Additions ZIP has 70 files including its manifest. The local evidence records retain their original executed checks.

These messages do not confirm receipt/review of the separate K26 Survey packet (95 checks/five traces). K26 acceptance and scoring remain pending independently.

## Decisions to settle before ratification

1. **W1 — Weather visits:** accepted captures in different orbits plus pooled MB, or a fully delivered image from every qualifying visit. Agree packet/orbit evidence and any explicit goal/revision change before implementation.
2. **C1 — Communication meaning:** confirm distinct positive Transmit steps, including multiple steps in one window, or choose a separately named distinct-window rule. Use clear player-facing wording.
3. **Creator/edit identity:** identify editable mission requirements and how custom/edited missions retain or change preset identity; A/B matches full requirements, not only titles/IDs.
4. **Capabilities:** choose the authoritative base-catalog/runtime registration path and accepted instrument support for new objectives. Neither new objective is production-enabled yet.
5. **Evidence/reports/versions:** HPC confirms native event/packet/timing meanings; KE2 confirms outcomes, partial scores and comparison/report rules; every affected owner confirms its envelope version separately. Final acceptance of the proposed field bounds/strict unknown-field rules is not inferred from direction review.

UI mockups, display-copy drafts and field mapping can be planned by their owners while these decisions remain open. This record does not authorize K22, enable new cards, change module ownership or approve integration.

## Package link check

SE suggested changing root-data/script/test links in `docs/ke1-expansion/ke2-review-package.md` from `../../` to `../../../`. Local inspection of **both actual supplied ZIPs** confirms that `../../data/mission_presets.json`, `../../scripts/core/mission_preset_catalog.gd` and `../../tests/validation/test_mission_presets.gd` resolve to existing package entries. `../../../data/...` resolves outside the package and is absent. The existing links are retained. A differently nested copy of the guide would need paths appropriate to its new location.

Previously shared archives remain unchanged so their reviewed manifests stay valid. Local status notes now reflect the messages above; they do not retrospectively alter or reissue the reviewed packets.

K20 remains unchecked. Shared signed agreements, candidate values, game code, personal instruction files and exports are unchanged. No commit, push, deployment or teammate message was performed.


## Latest confirmation — waiting only for HPC

After supplying `ke2-k20-k31-owner-reply.md`, the user confirmed: “the other things are agreed alr . let's just wait only on HPC”. This supersedes earlier non-HPC pending-agreement labels. No new SE/KE2/KE3 confirmation request is needed. Detailed source reply: [KE2 owner reply](owner-replies/ke2-k20-k31-owner-reply.md), preserved as received; its internal draft labels are historical source content and are not rewritten.

HPC still needs to confirm its config-v2 acceptance, event timing/revolution mapping, positive-step and complete-delivery evidence (including Survey sparse-map semantics), resource sample range/paths, version/source identities, shared capability consumption and actual Communication/Weather traces. See its section of [the reply form](k20-k31-owner-replies.md).

This update records agreement status, not completed implementation or passed release acceptance. The tested SE guard/Creator issues and KE2 production evaluation/comparison work remain implementation tasks. No tests were run for this documentation-only update. No reviewed ZIP, signed contract, game code, commit, push or deployment changed.
