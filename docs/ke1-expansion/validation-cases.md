# Expansion validation and acceptance matrix

Proposed cases for K28 and the other owners. Only examples whose audit is recorded in verification.md have been executed during preparation; this matrix is not a claim that future scoring/UI exists.

| Case | Owner | Expected result |
| --- | --- | --- |
| Three existing presets and current v1 fixtures | KE1 + SE | Same valid settings and original Imaging behavior; Survey limitation remains explicit until KE2 implements it |
| Two new preset IDs, duplicate/missing/unknown preset IDs | KE1 + SE | Exactly five unique cards; invalid metadata cannot silently select a different mission |
| Empty goal, unsupported goal kind or unknown new field | KE1 | Structured schema issue and no launch approval until accepted extension exists |
| Required count 0, negative, fractional, string, boolean, nonfinite or beyond duration/window opportunities | KE1 + HPC | Reject invalid inputs; distinguish numeric bounds from proven schedule feasibility |
| Returned MB 0, negative, nonfinite or wrong type | KE1 | Reject; captured/stored data do not replace returned MB |
| Unknown/missing component or target; invalid category | KE1 | Fail closed; no fake zero metrics |
| Mass 1329/1330/1331 g on sample profile | KE1 | Only 1329 passes sample mass check; other required checks remain independent |
| Alternate profile, budget equal/exceeded and insufficient power | KE1 | Correct profile threshold; budget equality passes, excess fails; power checked independently |
| Original config/catalog hash before and after validation | KE1 | Inputs unchanged; repeated output deterministic |
| One Survey target captured but not fully delivered | HPC + KE2 | Target requirement unmet even when pooled MB is high |
| Survey partial packet versus complete packet | HPC + KE2 | Only complete delivered observation counts for that target |
| Communication zero-MB, off-window, rejected or duplicate transmit | HPC + KE2 | No extra successful contact count |
| Communication two positive transmissions in distinct accepted steps | HPC + KE2 | Count 2; success additionally requires returned-MB goal |
| Weather two captures within one orbit | HPC + KE2 | One visit; goal not met |
| Weather same region observed in two orbits | HPC + KE2 | Two visits; success additionally requires returned MB |
| Weather images of different regions in different orbits | HPC + KE2 | Must not meet a two-visit goal for one selected region |
| Existing Observe First stops after two same-orbit captures | HPC + KE2 | Imaging totals may pass while Weather visit goal fails; do not mislabel success |
| A versus identical A with fixed environment/policy | HPC + KE2 | Matching measured results; new run IDs |
| Radio-only A/B pair | KE1 + HPC + KE2 | Valid physical setups; exactly one declared design change; derive actual trade-offs from runs |
| Changed preset/target/goals/orbit/duration/version | KE1 + SE + KE2 | Controlled comparison blocked or explicitly separated |
| Changed manual actions | HPC + KE2 + KE3 | Label design + operations; no hardware-only causal claim |
| Save A then B, Retry, Modify/Cancel and New Mission | SE + KE3 | A unchanged; new IDs; Cancel restores original; deliberate comparison reset |
| New goal changed after mission review | SE + KE1 | Invalidate old acknowledgement and revalidate at launch |
| Live-run edit or early Results request | SE + KE3 | Preserve main guard behavior |
| Fresh public Netlify visit: all five presets + A/B per preset | All | Actual browser flow, matching reports and source labels; record URL/revision/device/browser |

Retain the maintained tests rather than replacing them with example-only checks. Add focused future cases to their owner's suite, and run the full 43-program baseline when an integrated gameplay candidate is ready.
