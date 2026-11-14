# Agreed v1 fields and statuses

Status: ALIGNED TO v1.0-agreed. Read [the full technical contract](../../contracts.md) for exact required fields, unit conversions, API signatures, state/event/report schemas and ownership. This sheet adds no new public fields.

## Configuration and readiness

MissionConfig requires schema_version=1, mission and design. Required mission fields are title, objective, target_region, required_observations, required_returned_data_mb, duration_orbits and budget_credits. Required design IDs are bus, instrument, solar, battery, radio, storage, launch_profile, launcher and orbit, each with the _id suffix. Targets and duration are positive; captures and returned MB are separate goals. Current agreed preset IDs are low_eq/high_inc and target equator.

ValidationResult requires schema_version, ready_to_launch, metrics, checks, errors and warnings. Its metrics are total_mass_g, total_cost_credits, baseline_power_w, solar_generation_power_w, battery_capacity_wh, initial_energy_wh, storage_capacity_mb, data_per_observation_mb and downlink_mb_per_hour. Units are grams, credits, watts, Wh and decimal MB; derive step radio capacity in HPC using explicit scenario hours per step.

checks is an object keyed by the eight check_ids in reference-ids.json. Each check has status, passed and message. pass/true, fail/false and not_evaluated/null must agree. The profile_mass record also supplies mass, threshold, comparator, profile_id and source_id. Malformed inputs use null metrics and not_evaluated dependent checks; an unavailable check does not pass.

Issues have code, field_path, message, suggested_fix and optional source_id. A ready result requires every required check to pass with available metrics and no blocking errors. Warnings alone do not block launch. See the exact sample payloads and vocabulary registry.

## Operations, events and evaluation

MissionStepEngine exposes init_run(config, scenario, run_id, mission_id), get_available_actions(state), and request_action(state, action), with the wrappers documented in contracts.md. Run state carries run_id, mission_id, scenario_id, counters in public units, opportunities and action availability. Operating run_status is null; finished statuses are completed or aborted. Natural completion occurs exactly at step_index == total_steps.

Events have event_id, step_index, action, type, code, message and named unit deltas. A rejected request has zero changes and no step advancement. Accepted power_save advances a step and clamps low energy at zero while continuing the run.

evaluate_mission(config, final_state, events, comparison_baseline=null) returns ok/report or ok/error. Valid abort evaluation returns ok=true, report.status=failed, score=null; ok is not the mission-success flag. EvaluationError includes nullable field_path and run_id plus code, message and suggested_fix. Invalid/nonterminal inputs do not become completed failed missions.

Completed-run score is the half-up rounded equal-weight average of the two capped goal ratios. Mission status uses actual goals, so rounding to 100 does not establish success. Abort overrides success/score. Reports always include explanation and evidence-based root_causes (possibly empty); unsupported causes must not be invented.

See the signed report examples for all required report fields. Raw actual counters are preserved, comparison is null when unavailable, and SE publishes one report per run_id while owning immutable snapshots, routing and retry/reset.
