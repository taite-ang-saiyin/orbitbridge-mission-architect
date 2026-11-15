# K20 examples: proposed expectations, not launch inputs

Review revision `k20-review-additions-1`; config contract remains `expansion-goals-v2-draft-2`. All new rules/capabilities await owner agreement. The production validator still rejects v2, including candidate-valid files. No example is an official mission success or score.

See [validation rules](../../k20-validation-review.md), [parts review](../../k20-parts-review.md), [machine-readable rule proposal](rules.proposed.json), [part context](parts.proposed.json), [manifest](manifest.json) and [open gameplay examples](open-decision-examples.json).

| Example | Expected under proposed rules |
| --- | --- |
| [estuary_watch](candidate-valid/estuary_watch.json) | Candidate-valid; capability adoption and outcome decisions pending |
| [tropical_forest_watch](candidate-valid/tropical_forest_watch.json) | Candidate-valid; capability adoption and outcome decisions pending |
| [polar_ice_survey](candidate-valid/polar_ice_survey.json) | Candidate-valid; capability adoption and outcome decisions pending |
| [communication](candidate-valid/communication.json) | Candidate-valid; capability adoption and outcome decisions pending |
| [weather_monitoring](candidate-valid/weather_monitoring.json) | Candidate-valid; capability adoption and outcome decisions pending |
| [survey_two_targets](candidate-valid/survey_two_targets.json) | Candidate-valid; capability adoption and outcome decisions pending |
| [advanced_imaging](candidate-valid/advanced_imaging.json) | Candidate-valid; capability adoption and outcome decisions pending |
| [missing_goal](invalid/missing_goal.json) | INVALID_SCHEMA at mission.goal |
| [missing_contact_count](invalid/missing_contact_count.json) | INVALID_SCHEMA at mission.goal.required_positive_contact_steps |
| [wrong_goal_kind](invalid/wrong_goal_kind.json) | INVALID_VALUE at mission.goal.kind |
| [wrong_goal_counter](invalid/wrong_goal_counter.json) | INVALID_SCHEMA at mission.goal.required_distinct_orbits |
| [duplicate_mb](invalid/duplicate_mb.json) | INVALID_SCHEMA at mission.goal.required_returned_data_mb |
| [contact_count_zero](invalid/contact_count_zero.json) | INVALID_VALUE at mission.goal.required_positive_contact_steps |
| [contact_count_boolean](invalid/contact_count_boolean.json) | INVALID_VALUE at mission.goal.required_positive_contact_steps |
| [contact_count_string](invalid/contact_count_string.json) | INVALID_VALUE at mission.goal.required_positive_contact_steps |
| [contact_count_fraction](invalid/contact_count_fraction.json) | INVALID_VALUE at mission.goal.required_positive_contact_steps |
| [contact_count_negative](invalid/contact_count_negative.json) | INVALID_VALUE at mission.goal.required_positive_contact_steps |
| [captures_over_limit](invalid/captures_over_limit.json) | INVALID_VALUE at mission.required_observations |
| [duration_over_limit](invalid/duration_over_limit.json) | INVALID_VALUE at mission.duration_orbits |
| [budget_zero](invalid/budget_zero.json) | INVALID_VALUE at mission.budget_credits |
| [mb_zero](invalid/mb_zero.json) | INVALID_VALUE at mission.required_returned_data_mb |
| [weather_visits_over_duration](invalid/weather_visits_over_duration.json) | INVALID_VALUE at mission.goal.required_distinct_orbits |
| [weather_visits_over_capture_quota](invalid/weather_visits_over_capture_quota.json) | INVALID_VALUE at mission.goal.required_distinct_orbits |
| [contacts_over_total_steps](invalid/contacts_over_total_steps.json) | INVALID_VALUE at mission.goal.required_positive_contact_steps |
| [survey_delivery_over_quota](invalid/survey_delivery_over_quota.json) | INVALID_VALUE at mission.goal.minimum_complete_observations_per_target |
| [unknown_root_key](invalid/unknown_root_key.json) | INVALID_SCHEMA at extra_goal |
| [unknown_preset](invalid/unknown_preset.json) | INVALID_VALUE at preset_id |
| [old_preset_revision](invalid/old_preset_revision.json) | INVALID_VALUE at preset_revision |
| [unknown_part](invalid/unknown_part.json) | UNKNOWN_COMPONENT at design.radio_id |
| [wrong_part_slot](invalid/wrong_part_slot.json) | WRONG_COMPONENT_CATEGORY at design.radio_id |
| [missing_radio](invalid/missing_radio.json) | MISSING_COMPONENT at design.radio_id |
| [duplicate_targets](invalid/duplicate_targets.json) | INVALID_VALUE at mission.target_regions |
| [primary_target_mismatch](invalid/primary_target_mismatch.json) | INVALID_VALUE at mission.target_region |
| [new_goal_two_targets](invalid/new_goal_two_targets.json) | INVALID_VALUE at mission.target_regions |
| [preset_objective_mismatch](invalid/preset_objective_mismatch.json) | INVALID_VALUE at mission.objective |
| [unknown_objective](invalid/unknown_objective.json) | INVALID_VALUE at mission.objective |
| [title_whitespace](invalid/title_whitespace.json) | INVALID_VALUE at mission.title |
| [heavy_part_combination](invalid/heavy_part_combination.json) | PROFILE_MASS_EXCEEDED at design.launch_profile_id |
| [budget_shortfall](invalid/budget_shortfall.json) | BUDGET_EXCEEDED at mission.budget_credits |
| [withdrawn_instrument_capability](invalid/withdrawn_instrument_capability.json) | INSTRUMENT_OBJECTIVE_UNSUPPORTED at design.instrument_id |

`withdrawn_instrument_capability` uses the manifest's changed capability context with an otherwise unchanged config. `heavy_part_combination` and `budget_shortfall` are shape-valid readiness failures. A known part being selectable does not make all combinations feasible.

Weather's config is shape-valid under either interpretation, but its qualifying delivered-visit rule is unresolved. The contact-window example is synthetic and does not claim the current HPC scenario has consecutive contact steps. Whole-number JSON values like 2.0 are acceptable; invalid fixtures with booleans/strings/fractions are not. Nonfinite in-memory cases are described separately because legal fixture files should not encode NaN or Infinity.

The documentation audit checks proposal consistency and current physical readiness separately. It does not add config v2 to the game, register new instrument support, choose W1/C1, or ratify any team decision.
