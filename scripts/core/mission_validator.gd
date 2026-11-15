class_name MissionValidator
extends RefCounted
## Stable public boundary: v1 unchanged, v2 requires explicit agreed context.
const Legacy = preload("res://scripts/core/mission_validator_v1.gd")
const V2 = preload("res://scripts/core/mission_validator_v2.gd")
const Support = preload("res://scripts/core/validation_support.gd")
const CHECK_IDS = Legacy.CHECK_IDS
const MISSION_FIELDS = Legacy.MISSION_FIELDS
const DESIGN_FIELDS = Legacy.DESIGN_FIELDS

static func validate(config: Variant, catalogs: Variant) -> Dictionary:
	if config is Dictionary and Support.is_whole(config.get("schema_version")) and config.schema_version == 2:
		return V2.validate(config, catalogs)
	return Legacy.validate(config, catalogs)

# Compatibility seams used by the earlier isolated candidate. Physics remains
# defined once in the unchanged v1 implementation, not copied into v2.
static func _calculate_metrics(config: Dictionary, indexes: Dictionary) -> Dictionary:
	return Legacy._calculate_metrics(config, indexes)
static func _run_readiness(config: Dictionary, catalogs: Dictionary, indexes: Dictionary, result: Dictionary) -> void:
	Legacy._run_readiness(config, catalogs, indexes, result)
