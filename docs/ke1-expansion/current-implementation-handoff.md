# Current KE1 handoff — candidate validator and aligned copy

**Latest implementation update:** K20 is agreed and K21 definitions are delivered. [K21/K22 production API and current blockers](k21-k22-live-integration.md) and the [agreed v2 contract](../contracts/expansion-v2.md) supersede earlier pending-confirmation/candidate-only status. The public validator now supports explicit agreed v2 context; native launch integration remains blocked. Existing reviewed ZIPs are unchanged historical snapshots and do not contain these later files.


**Latest HPC status:** [Conditional review received and exact clarifications](hpc-k20-clarifications.md). Final HPC acknowledgment remains pending; non-HPC agreements stay settled. State/event v1 is conditional on implementation compatibility. Current code still rejects v2. Earlier pending-owner statements below are historical. Existing ZIPs remain unchanged; this clarification postdates the current handoff archive.


Prepared in order: K22 candidate validation, K29 wording, K30 combined handoff, then K28 verification of any available SE fixes. HPC is the only remaining K20 confirmation. This is an integration package, not a final working five-mission release.

Start with [consolidated decisions](k20-consolidated-non-hpc-decisions.md), [candidate API](k22-v2-candidate-validator.md), [wording](k29-mission-wording-preparation.md), then [SE check status](k28-se-integration-preparation.md). K20/K26/K27, the previously missing K22/K23 docs, candidate registry, capability declaration/loader, new candidate validator/tests, real outputs and preserved owner reply are included at their matching project paths. The original already-verified KE2 JSON packet/eight execution keys do not need resending.

The single current package is `OrbitBridge-KE1-Current-Implementation-Handoff.zip`. It supersedes the older two-ZIP delivery for these KE1 resources; older reviewed archives remain unchanged for their hashes/history. The root README and manifest identify exact versions, entry points, test commands and prerequisites. Review/extract separately, then compare paths before copying into a teammate checkout. Preserve their own production code and runner.

Candidate checks: 327 passed; total eight focused programs: 2429 passed, zero failures. Supported v1 behavior and live v2 rejection remain. New copy is content-audited but not installed in screens. No final public browser or all-five-mission acceptance is claimed.

K28 verified published SE `0d9e275fc270630c74324f29c11281f9883909a2`: saved-A 76 passed; saved-record fixtures 19 passed; new guard/Creator checks 31 passed / 7 failed (two issue groups). Fixes are not yet present. See the SE handoff for exact owner paths and repeatable steps. Actual member receipt remains unconfirmed. No commit, push, deployment or teammate message was performed.
