extends RefCounted

const MAX_SAFE_INTEGER: int = 9007199254740991


static func is_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))


static func is_whole(value: Variant) -> bool:
	return is_number(value) and absf(float(value)) <= float(MAX_SAFE_INTEGER) and floorf(float(value)) == float(value)


static func is_text(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and not value.strip_edges().is_empty()


static func issue(code: String, field_path: String, message: String, suggested_fix: String) -> Dictionary:
	return {"code": code, "field_path": field_path, "message": message, "suggested_fix": suggested_fix}
