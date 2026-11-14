# KE2 reply: additional requested display and error cases

This addendum answers KE2's follow-up message using the validated report verification already completed. It does not re-run HPC, regenerate evaluation, commit source or connect SE production routes.

Reused evidence:48 packet checks, focused validated Debrief63 headless/67 windowed, older sample49/52, A05 Debrief139/156, A06 Retry100/104 and A07 no-capture900x68080; all0 failures/exits0, described in REPORT_CHECK.md. KE2's32 run-specific/165 evaluator assertions are supplied producer claims, not KE3 reruns.

Fresh follow-up script `ke2_reply_edges.gd` reuses existing recorded-test helper methods and Results/session implementation, without production source changes. It executed24 headless/29 windowed assertions,0 failures, both exit0. Commands/logs are appended to evidence/commands.json and regenerated COMMANDS.md. All error fixtures below are the unchanged v1.0-agreed contract examples copied from clean team main1a82ebd; display variants are labeled SYNTHETIC and do not overwrite the validated report resource.

| KE2 request | Actual evidence / disposition |
|---|---|
| Show4.2666666672MB onboard |Exact string “4.2666666672 MB remain onboard” is present in the supplied summary shown by Debrief. No stored-plus-returned calculation in UI. |
| comparison:null |Preserved as raw null; no A/B interpretation/panel manufactured. Verified in original focused check and empty-causes variant. |
| Empty causes |Direct independent display copy with root_causes=[] shows “No root causes supplied.” and retains supplied summary; screenshot reply-empty-causes.png. |
| Aborted/null score |Labeled synthetic display copy shows failed/aborted, scoreUnavailable; raw score remains null, raw actuals unchanged. Not a KE2-evaluated abort for the original completed run. screenshot reply-aborted-null.png. |
| ok:false contract errors |Both original NONTERMINAL_RUN_STATE/run_001 and INVALID_EVALUATION_INPUT/null-ID wrappers pass through the preview session error boundary, clear report, disable Retry, preserve visible code/correction and do not become a failed/scored mission. Wrapper identities unchanged. |
| Structured known-run EvaluationError |Direct existing set_inputs surface displays the contract's known-run error as Evaluation error, with correction. The null-ID example is **not assigned to the validated run**. Controller presentation/routing of null-ID errors remains SE's boundary. |
| Reopen Results |Original focused test re-enters3 times with identical labels and62 events, no duplicate causes/credits and no action/route/Retry intents. |
| Retry |A06 synthetic pending/cancel/edit/B/reset/stale-reply tests100/104 pass. Real validated-run Retry with SE is NOT TESTED. |
| New Mission |No production KE3 owner/reset wiring added. SE-integrated New Mission, baseline clearing and new run history must be tested on its confirmed integration SHA; NOT TESTED. |
| Credits |context.applicable_source_credits contains KE2's exact separately supplied readiness and feedback_vocabulary records. debrief_screen._credits_text formats them as scoped metadata; report.source_ids=[]/comparison=null stay identical. URL display passed; opening source links/export credit access is not tested. |

Revision evidence: the active team checkout remains clean main@1a82ebd93a019b751947965aa760e8e759d8f45b. It is still a mock shell, not a v1 integration commit. The isolated preview is **not a Git repository** and the KE3 changes have not been committed/pushed; no KE3 branch/SHA is invented. `ke3-results-verification.zip` provides a portable review snapshot and SOURCE_SHA256.json identifies each included file's exact bytes. KE2's returned report declares evaluator commit8c3ed816f5122a6645c0517aecd83880876a0cd7; that is producer provenance, not a KE3 implementation revision.

Binding: `ke3/results_control.tscn` -> `ke3/debrief_screen.gd` extends `ke3/outline_control.gd`. Existing `set_inputs(context:Dictionary,state:Dictionary,report:Dictionary)` copies inputs. The explicit `preview/ke2_validated_preview.tscn` extends the existing recorded entry/provider path, unwrapping only wrapper.report and placing original ordered history into the preview state.events seam. The production SE history envelope still needs integration agreement.

No new required KE2 field or display mismatch was found. report.failed_constraint is absent and displaysUnavailable; it is not silently inferred. Profile source/credit generic labels also remainUnavailable while the separately scoped supplied readiness credit is fully displayed below. Do not ask KE2 to insert either into source_ids without a shared contract change.

Before/after source and original report/metadata/archive hashes remain valid. All new follow-up work is under this verification folder; no production code/settings, original fixtures or previous test evidence changed. **B02 and official B10 NOT TESTED.**
