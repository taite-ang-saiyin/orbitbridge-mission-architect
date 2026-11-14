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
