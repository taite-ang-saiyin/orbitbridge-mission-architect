extends RefCounted
## Pure, separate K22 review checker. Never called by production launch code.
## A passing review is not owner approval: ready_to_launch is ALWAYS false.
const Support = preload("res://scripts/core/validation_support.gd")
const Loader = preload("res://scripts/core/catalog_loader.gd")
const V1 = preload("res://scripts/core/mission_validator.gd")
const Rules = preload("res://scripts/core/mission_config_v2_rules.gd")
const ROOT_FIELDS = Rules.ROOT_FIELDS

static func check(config: Variant, catalogs: Variant, registry: Variant, capability_proposal: Variant) -> Dictionary:
	var result: Dictionary = {
		"checker_revision":"k22-v2-review-1", "draft_only":true,
		"config_valid":false, "review_valid":false, "physical_setup_ready":false,
		"ready_to_launch":false, "metrics":null, "checks":{}, "errors":[], "warnings":[],
		"launch_blockers":[
			Support.issue("V2_DRAFT_ONLY", "schema_version", "This separate checker cannot approve launch.", "Use the agreed production validation/launch path after integration."),
			Support.issue("K20_DECISIONS_PENDING", "mission.goal", "HPC confirmation and coordinated live v2 integration remain pending.", "Obtain HPC confirmation and complete coordinated production integration.")],
		"pending_decisions":["HPC technical confirmation", "coordinated live v2 integration"]}
	var inspected: Dictionary = Rules.inspect_configuration(config, catalogs, registry, capability_proposal)
	result.checks = inspected.checks
	result.errors = inspected.errors
	if not inspected.config_valid: return result
	result.config_valid = true
	# Private local physical surrogate only; never returned, registered or launched.
	# Proposed new objectives are NOT inserted into the shared catalog.
	var physical: Dictionary = config.duplicate(true)
	for key in ["contract_revision", "preset_id", "preset_revision"]: physical.erase(key)
	physical.schema_version = 1
	physical.mission.erase("goal")
	if physical.mission.objective in ["communication", "weather_monitoring"]: physical.mission.objective = "imaging"
	var verdict: Dictionary = V1.validate(physical, catalogs)
	result.metrics = verdict.metrics.duplicate(true) if verdict.metrics is Dictionary else null
	result.checks = verdict.checks.duplicate(true)
	result.errors = verdict.errors.duplicate(true)
	result.warnings = verdict.warnings.duplicate(true)
	result.physical_setup_ready = verdict.ready_to_launch
	result.review_valid = verdict.ready_to_launch
	return result
