# K29 wording aligned to the agreed rules

Updated copy: `five-mission-copy-candidate-2`, in [mission-copy.draft.json](examples/mission-copy.draft.json). All non-HPC agreement items are settled, as confirmed by the user. HPC is the only remaining K20 confirmation. These strings are ready for SE/KE3 integration, not yet installed in game screens.

| Goal | Wording now used |
| --- | --- |
| Imaging | Required captures and returned data |
| Survey | Overall captures/data plus one fully returned observation for every selected target; partial images do not complete a target |
| Communication | **Successful transmission steps**; two positive accepted steps in one window count twice, duplicates count once, rejected/zero-data steps count zero |
| Weather | Accepted selected-region captures on different revolutions plus pooled returned MB; complete delivery per visit is not required |

Communication/Weather capture quota supplies/limits captures. Meeting it is not an extra scoring requirement. Numeric targets still come from the complete frozen config, never duplicated in this copy file. HPC confirms event timing and revolution mapping.

The copy distinguishes the same requested operating plan from the actual accepted action sequence. Hardware can change action acceptance under the same plan. Changed requested policy/manual choices receive **Design + operations**; unknown operations remain unclassified. Keep mission/orbit/launcher/profile restrictions consistent with the agreed B UI and runtime guards.

Missing required evidence produces an evaluation error, not zero progress or an invented score. Optional missing measurements display **Unavailable**. Aborted runs show no score. Session-only Save A storage has a refresh/new-mission notice and does not promise persistence.

The five cards retain their registered IDs/titles, purpose and scope limits. [Part explanations](examples/mission-copy.draft.json) identify illustrative training parameters. Existing [source credit](../sources.md) and profile-specific limits remain. Weather is repeat observation, not forecasting; Communication is data return, not real RF analysis.

Content audit passed for five unique matching registry IDs/titles, nonempty strings, selected Weather wording and unavailable labels. See [audit](evidence/v2-candidate-1/copy-audit.json). Final rendered UI/browser acceptance belongs to the later integration checks.
