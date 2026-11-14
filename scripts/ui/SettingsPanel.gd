extends PanelContainer
signal settings_changed
signal closed
const PREFS = preload("res://scripts/settings/PrototypeSettings.gd")
var values: Dictionary = {}
@onready var language: OptionButton = $Margin/Content/Language
@onready var appearance: OptionButton = $Margin/Content/Theme
func _ready() -> void:
	language.add_item("English")
	language.add_item("မြန်မာ")
	appearance.add_item("Midnight")
	appearance.add_item("Ocean")
	language.selected = 1 if values.get("language", "en") == "my" else 0
	appearance.selected = 1 if values.get("theme", "midnight") == "ocean" else 0
	language.item_selected.connect(func(index):
		values.language = "en" if index == 0 else "my"
		refresh()
		settings_changed.emit())
	appearance.item_selected.connect(func(index):
		values.theme = "midnight" if index == 0 else "ocean"
		settings_changed.emit())
	$Margin/Content/Done.pressed.connect(func(): closed.emit())
	refresh()
func refresh() -> void:
	for index in 2: appearance.set_item_text(index, PREFS.TEXT.text(["Midnight", "Ocean"][index], str(values.get("language", "en"))))
	for pair in [["Title", "settings"], ["Heading", "heading"], ["LanguageLabel", "language"], ["ThemeLabel", "theme"], ["Note", "note"], ["Session", "session"], ["Done", "close"]]:
		get_node("Margin/Content/" + pair[0]).text = PREFS.word(values, pair[1])
