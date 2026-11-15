extends RefCounted
## Session-only UI preferences. No file persistence or OS settings changes.
const DEFAULTS = {"language": "en", "theme": "midnight"}
const TEXT = preload("res://scripts/settings/MyanmarText.gd")
const COPY = {"start":"Start Mission", "settings":"Settings", "quit":"Quit", "tagline":"Design  ·  Plan  ·  Execute", "language":"Language", "theme":"Theme", "close":"Done", "note":"Language applies to mission setup, Operations, Results and Design Lab. Producer text may remain in English.", "heading":"Make space your own.", "session":"Changes apply immediately for this session.", "footer":"MISSION DESIGN SANDBOX", "hint":"A new perspective starts with a mission."}
static func word(settings: Dictionary, key: String) -> String:
	return TEXT.text(COPY.get(key, key), str(settings.get("language", "en")))
