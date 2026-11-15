extends RefCounted
## Candidate validation boundary. Never imported by the live runtime/adapter.
## Supported v1 is delegated unchanged; every v2 result remains launch-blocked.
const V1 = preload("res://scripts/core/mission_validator.gd")
const Rules = preload("res://scripts/core/mission_config_v2_rules.gd")
const Capabilities = preload("res://scripts/core/mission_capability_draft_loader.gd")
const Support = preload("res://scripts/core/validation_support.gd")
const REVISION = "k22-v2-validator-candidate-1"

static func validate(config: Variant, catalogs: Variant, registry: Variant = null, capability_document: Variant = null) -> Dictionary:
	if config is Dictionary and Support.is_whole(config.get("schema_version")) and config.schema_version == 1:
		return V1.validate(config, catalogs)
	var result: Dictionary = {
		"schema_version":1, "candidate_revision":REVISION, "candidate_only":true,
		"config_valid":false, "physical_setup_ready":false, "ready_to_launch":false,
		"metrics":null, "checks":{}, "errors":[], "warnings":[], "config_snapshot":null,
		"pending_confirmation_owners":["HPC"],
		"launch_blockers":[
			Support.issue("HPC_CONFIRMATION_PENDING", "schema_version", "HPC confirmation of the v2 simulator/evidence contract is pending.", "Keep v2 launches blocked until HPC confirms the contract."),
			Support.issue("V2_INTEGRATION_PENDING", "schema_version", "This candidate is not connected to live validation, simulation, evaluation or UI.", "Integrate and test the coordinated v2 path before enabling launch.")]
	}
	var capability: Dictionary = Capabilities.inspect_review(capability_document, catalogs)
	var inspected: Dictionary = Rules.inspect_configuration(config, catalogs, registry, capability.checker_context if capability.ok else null)
	result.checks = inspected.checks
	result.errors = inspected.errors
	if not capability.ok:
		# Preserve concrete declaration errors, rather than inferring support.
		result.errors.append_array(capability.errors.duplicate(true))
		result.checks.catalog_references = {"status":"fail", "passed":false, "message":"Correct the explicit capability document and catalog context."}
	if not result.errors.is_empty(): return result
	result.config_valid = true
	result.config_snapshot = config.duplicate(true)
	# These existing pure KE1 routines only read design/mission values and use
	# validated catalog indexes. No config rewriting, objective substitution,
	# catalog registration or simulator call occurs in this candidate.
	var totals: Dictionary = V1._calculate_metrics(config, inspected.indexes)
	if not totals.ok:
		result.errors.append_array(totals.errors.duplicate(true))
		return result
	result.metrics = totals.metrics.duplicate(true)
	V1._run_readiness(config, catalogs, inspected.indexes, result)
	result.physical_setup_ready = result.errors.is_empty()
	for id in V1.CHECK_IDS:
		if result.checks[id].status != "pass": result.physical_setup_ready = false
	# Deliberately never derive launch permission from physical readiness.
	return result
