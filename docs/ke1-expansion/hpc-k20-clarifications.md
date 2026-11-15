# HPC K20 review and consolidated clarifications

Recorded 15 November 2026, Asia/Rangoon, from HPC's message relayed by the user. **Conditional design-direction confirmation received; final HPC signoff is explicitly pending.** The user's prior confirmation that all non-HPC agreements are settled remains in force. No request to repeat those approvals is introduced.

## What HPC confirms

- Explicit MissionConfig v2 while preserving supported v1 behavior.
- Separate capture quota, positive transmission-step and distinct-revolution requirements.
- Positive transmissions use `delta_returned_data_mb > 0`.
- Zero-based revolution indexing uses the accepted event's pre-action step and frozen `steps_per_orbit`.
- Survey complete deliveries use `observations_delivered_by_target`.
- Frozen launch inputs, ordered events and distinct A/B run IDs.

## Exact clarification wording carried forward

| Item | Consolidated wording | Status |
| --- | --- | --- |
| Weather evidence | A qualifying visit requires an accepted Observe event, `delta_observations > 0`, and the selected target. Derive the zero-based revolution from that event's pre-action step and frozen `steps_per_orbit`; deduplicate visits per selected target/revolution. Success also requires the returned-MB goal. No complete-delivery-per-visit requirement. | Positive-observation condition added explicitly in this documentation; consolidated wording awaits HPC final acknowledgment |
| Capture quota | Communication/Weather `required_observations` is a payload-generation/capture quota, not an additional success condition. Communication success uses qualifying positive transmission steps plus returned MB; Weather uses qualifying distinct-revolution visits plus returned MB. Preserve raw capture actual/quota as diagnostics. | Matches the already agreed KE2 rule and HPC's recommendation; no new non-HPC approval needed |
| Resource samples | Use initialization plus every accepted post-clamp state, including terminal, for lowest battery and peak storage. Rejected attempts are not extra accepted-step samples. Missing required samples/maps remain unavailable, not zero. Use one consistent sample range. | HPC clarification recorded; actual producer paths/completeness must be verified in integration |
| State/event versions | Retain state/event envelopes at v1 only if their structures and meanings remain compatible while retaining the full v2 config snapshot. Config/report versions remain independent. | HPC proposal is conditional; compatibility review during implementation is required, not already passed |

An absent entire Survey delivery map cannot establish zero. This reply does not explicitly define whether a missing selected-target key inside a supplied sparse map means zero or unknown; retain unavailable/error handling until that producer meaning is explicit. No missing numeric sample or count is invented. Evidence must remain bound to the same frozen execution.

## K20 and implementation status

K20 stays unchecked: fold this exact wording into the matching revision and obtain HPC's final acknowledgment. This is a narrow HPC follow-up, not a fresh SE/KE2/KE3 agreement round. HPC expressly says the current code rejects v2. Its direction review does not approve launch, claim a working typed-v2 adapter, ratify every unaddressed loader/version path or replace official mission traces.

Implementation still includes the coordinated v2 validator/adapter/runtime, expanded evaluator/comparator, SE guard/Creator fixes and final merged/public-browser acceptance. State/event compatibility and actual sample/evidence paths are implementation checks. Do not mark those tasks done based on the review message.

No game code, presets, capability JSON, signed contract, reviewed ZIP or existing evidence was changed for this documentation update. No tests were rerun. The current handoff ZIP remains its earlier immutable snapshot; share this clarification alongside it until a later package refresh is requested.

## Source message preserved as relayed

> I agree with the proposed direction, with a few details to clarify before final signoff. It matches our published HPC evidence semantics.
>
> HPC confirms
> - Explicit MissionConfig v2 while preserving v1 behavior.
> - Separate capture, positive-transmit-step, and distinct-orbit requirements.
> - Positive transmissions counted using delta_returned_data_mb > 0.
> - Zero-based orbit indexing from the accepted event’s pre-action step and frozen steps_per_orbit.
> - Survey completion measured by observations_delivered_by_target.
> - Frozen launch inputs, ordered events, and separate run IDs for A/B comparisons.
>
> Clarifications needed
> 1. Weather: explicitly require delta_observations > 0 alongside an accepted Observe event matching the selected target.
> 2. Capture quota versus success: state whether Communication/Weather must also achieve required_observations. I recommend treating it as their payload-generation quota; success requires their goal-specific count plus returned MB.
> 3. Resource sampling: add initialization plus every accepted post-clamp state, including terminal. Missing samples/maps remain unavailable.
> 4. Versions: HPC proposes keeping state/event envelopes at v1 if their structures and meanings remain compatible, while retaining the complete v2 config snapshot. This requires compatibility review during implementation.
>
> Current code still rejects config v2. This review approves the design direction; implementation and team-wide agreement remain pending.
