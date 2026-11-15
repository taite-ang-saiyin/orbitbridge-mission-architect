extends RefCounted
## Display-only text catalog. Never translates saved mission values or engine IDs.
static var entries: Dictionary = {}
static var lookup: Dictionary = {}
static var pattern: RegEx
static var font: Font
static var dynamic_rules: Array = []

static func prepare() -> void:
	if pattern != null: return
	for rule in JSON.parse_string(FileAccess.get_file_as_string("res://data/localization/myanmar_patterns.json")):
		var regex = RegEx.new()
		regex.compile(rule[0])
		dynamic_rules.append([regex, rule[1]])
	entries = JSON.parse_string(FileAccess.get_file_as_string("res://data/localization/myanmar.json"))
	# KE3 extends the same display catalog and font, without replacing SE wording.
	var ke3: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/localization/myanmar_ke3.json"))
	entries.merge(ke3, false)
	var keys: Array = entries.keys()
	keys.sort_custom(func(a, b): return a.length() > b.length())
	var escaped = PackedStringArray()
	for key in keys:
		lookup[key.to_lower()] = entries[key]
		var literal: String = ""
		for character in key:
			if character in "\\.^$|?*+()[]{}": literal += "\\"
			literal += character
		escaped.append(literal)
	pattern = RegEx.new()
	pattern.compile("(?i)(?<![A-Za-z_])(?:" + "|".join(escaped) + ")(?![A-Za-z_])")

static func text(source: String, language: String) -> String:
	if language != "my": return source
	prepare()
	if lookup.has(source.to_lower()): return lookup[source.to_lower()]
	for rule in dynamic_rules: source = rule[0].sub(source, rule[1], true)
	var result = ""
	var offset = 0
	for found in pattern.search_all(source):
		result += source.substr(offset, found.get_start() - offset) + str(lookup[found.get_string().to_lower()])
		offset = found.get_end()
	return result + source.substr(offset)

static func myanmar_font() -> Font:
	if font == null:
		# Bundled Unicode font keeps Myanmar shaping available in exported builds.
		if ResourceLoader.exists("res://assets/fonts/myanmar/NotoSansMyanmar.ttf"):
			font = load("res://assets/fonts/myanmar/NotoSansMyanmar.ttf")
		else:
			var fallback = SystemFont.new()
			fallback.font_names = PackedStringArray(["Noto Sans Myanmar", "Myanmar Sangam MN", "Myanmar Text"])
			font = fallback
	return font

# Translate templates before inserting data. Producer prose, IDs, units and numeric
# strings must never pass through dictionary substitutions as part of a message.
static func format_copy(template: String, values: Array, language: String) -> String:
	var source: String = text(template, language)
	var tokens = RegEx.new()
	tokens.compile("\\{([0-9]+)\\}")
	var result = ""
	var offset = 0
	for token in tokens.search_all(source):
		result += source.substr(offset, token.get_start() - offset)
		var index: int = int(token.get_string(1))
		if index >= values.size(): result += token.get_string()
		elif values[index] is Dictionary and values[index].has("copy"): result += text(str(values[index].copy), language)
		else: result += str(values[index])
		offset = token.get_end()
	return result + source.substr(offset)

static func bind(node: Node, property: String, template: String, values: Array) -> void:
	node.set_meta("ke3_copy_" + property, {"template":template, "values":values.duplicate(true)})
	node.set(property, format_copy(template, values, "en"))

static func raw(node: Node, property: String, value: String) -> void:
	bind(node, property, "{0}", [value])

static func pieces(node: Node, property: String, parts: Array) -> void:
	var template = ""
	var values: Array = []
	for part in parts:
		if part is String: template += part
		else:
			template += "{" + str(values.size()) + "}"
			values.append(part.raw if part is Dictionary and part.has("raw") else part)
	bind(node, property, template, values)

static func code_label(code: String) -> String:
	return {"COMPARISON_METADATA_MISSING": "Comparison metadata unavailable", "EXECUTION_INCOMPLETE": "Completed flights only", "RUN_NOT_COMPLETED": "Completed flights only", "INCOMPATIBLE_PRESET": "Preset identities differ.", "INCOMPATIBLE_START": "Starting resources differ.", "INVALID_COMPARISON": "Invalid comparison response", "MISSION_CHANGED": "Mission requirements changed", "OPERATIONS_CHANGED": "Action policy changed", "SAME_EXECUTION": "Choose a different flight for B.", "DRAFT_ACTIVE": "Cancel the current draft first.", "A_ALREADY_SAVED": "Replace A deliberately to change the baseline.", "REVIEW_REQUIRED": "Review mission requirements before launch.", "EVALUATION_UNAVAILABLE": "Scoring is unavailable for this goal.", "EXECUTION_NOT_FOUND": "Execution unavailable", "ACTION_ACCEPTED":"Action accepted", "OK":"Action accepted", "OBSERVATION_CAPTURED":"Photo taken", "DATA_TRANSMITTED":"Data sent", "POWER_SAVE":"Saving power", "TARGET_NOT_VISIBLE":"Target not visible", "NO_LINK_WINDOW":"No contact window", "NO_DATA":"No onboard data to send", "NO_SUNLIGHT":"Sunlight required", "STORAGE_FULL":"Onboard storage full", "LOW_BATTERY":"Battery too low", "OBSERVATION_LIMIT_REACHED":"Capture goal already reached", "MISSION_FINISHED":"Flight finished", "COMPARISON_PROVIDER_UNAVAILABLE":"Comparison scoring has not been connected yet.", "A_CHANGED":"Saved A changed; review before confirming.", "EXECUTION_MISMATCH":"Comparison identifiers do not match these executions.", "A_NOT_SAVED":"Save Design A before creating B.", "INCOMPATIBLE_MISSION":"Mission requirements differ.", "INCOMPATIBLE_SCENARIO":"Scenarios differ.", "INCOMPATIBLE_VERSIONS":"Simulation versions differ.", "RUN_ACTIVE":"A flight is still running.", "INVALID_EVALUATION_INPUT":"Scoring is unavailable for this goal."}.get(code, "Details supplied by the mission system")
