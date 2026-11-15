extends RefCounted
## Pure agreed config-v2 design/readiness validation. Native launch remains a separate gate.
const Legacy = preload("res://scripts/core/mission_validator_v1.gd")
const Rules = preload("res://scripts/core/mission_config_v2_agreed_rules.gd")
const Context = preload("res://scripts/core/mission_v2_context.gd")

static func validate(config: Variant,catalogs: Variant) -> Dictionary:
	var result: Dictionary={"schema_version":1,"ready_to_launch":false,"metrics":null,"checks":{},"errors":[],"warnings":[]}
	for id in Legacy.CHECK_IDS:
		result.checks[id]={"status":"not_evaluated","passed":null,"message":"Waits for valid inputs and agreed v2 context."}
	result.checks.profile_mass.merge({"total_mass_g":null,"threshold_g":null,"comparator":null,"profile_id":null,"source_id":null})
	Rules._shape(config,result.errors)
	result.checks.input_schema={"status":"pass" if result.errors.is_empty() else "fail","passed":result.errors.is_empty(),"message":"Mission fields are valid." if result.errors.is_empty() else "Correct the listed v2 fields."}
	if not result.errors.is_empty(): return result
	var checked: Dictionary=Context.inspect_context(catalogs.get("mission_v2") if catalogs is Dictionary else null,catalogs)
	if not checked.ok:
		result.errors.append_array(checked.errors.duplicate(true))
		result.checks.catalog_references={"status":"fail","passed":false,"message":"Correct the explicit agreed v2 context and catalogs."}
		return result
	var inspected: Dictionary=Rules.inspect_configuration(config,catalogs,checked.registry,checked.capability_context)
	result.checks=inspected.checks.duplicate(true)
	result.errors=inspected.errors.duplicate(true)
	if not inspected.config_valid: return result
	var totals: Dictionary=Legacy._calculate_metrics(config,inspected.indexes)
	if not totals.ok:
		result.errors.append_array(totals.errors.duplicate(true)); return result
	result.metrics=totals.metrics.duplicate(true)
	Legacy._run_readiness(config,catalogs,inspected.indexes,result)
	result.ready_to_launch=result.errors.is_empty()
	for id in Legacy.CHECK_IDS:
		if result.checks[id].status!="pass": result.ready_to_launch=false
	return result
