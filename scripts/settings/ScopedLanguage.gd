extends Node
## Localizes only SE presentation surfaces. No global TranslationServer locale.
const COPY = preload("res://scripts/settings/MyanmarText.gd")
var controller: Control

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if not is_instance_valid(controller.current): return
	var excluded: bool = controller.current.screen_id in ["MissionOperations", "DebriefCompare"]
	var language: String = "en" if excluded else str(controller.preferences.get("language", "en"))
	# The shell must also return to English on the two excluded pages.
	walk(controller.shell, language, controller.host)
	if not excluded:
		walk(controller.current, language)
		if is_instance_valid(controller.flow_error): walk(controller.flow_error, language)

func property_text(node: Object, property: String, language: String) -> void:
	var value: String = node.get(property)
	var key: String = "se_copy_" + property
	var previous: Dictionary = node.get_meta(key, {})
	if value == previous.get("rendered") and previous.get("language") == language: return
	var source: String = previous.get("source", value) if value == previous.get("rendered") else value
	var rendered: String = COPY.text(source, language)
	if value != rendered: node.set(property, rendered)
	node.set_meta(key, {"source":source, "rendered":rendered, "language":language})

func walk(node: Node, language: String, skip: Node = null) -> void:
	if node == skip: return
	if node is Control:
		if node.get_meta("se_font_language", "en") != language:
			if language == "my":
				if not node.has_meta("se_language_font"):
					node.set_meta("se_language_font", {"font":node.get_theme_font("font") if node.has_theme_font_override("font") else null})
				node.add_theme_font_override("font", COPY.myanmar_font())
			elif node.has_meta("se_language_font"):
				if node.get_meta("se_language_font").font != null: node.add_theme_font_override("font", node.get_meta("se_language_font").font)
				else: node.remove_theme_font_override("font")
			node.set_meta("se_font_language", language)
		property_text(node, "tooltip_text", language)
	if node is Label or node is Button:
		# OptionButton text is derived from its selected item; translate items below.
		if not node is OptionButton: property_text(node, "text", language)
	if node is LineEdit or node is TextEdit: property_text(node, "placeholder_text", language)
	if node is AcceptDialog:
		property_text(node, "title", language)
		property_text(node, "dialog_text", language)
	if node is OptionButton:
		for index in node.item_count:
			var key: String = "se_item_" + str(index)
			var value: String = node.get_item_text(index)
			var previous: Dictionary = node.get_meta(key, {})
			var source: String = previous.get("source", value) if value == previous.get("rendered") else value
			var rendered: String = COPY.text(source, language)
			if value != rendered: node.set_item_text(index, rendered)
			node.set_meta(key, {"source":source, "rendered":rendered})
	# These SE-only controls draw their own captions instead of using Label nodes.
	var script: Script = node.get_script()
	if script != null and script.resource_path in ["res://ui/components/ResourceGauge.gd", "res://ui/components/MissionFlow.gd"]:
		if node.get_meta("se_language", "en") != language:
			node.set_meta("se_language", language)
			node.queue_redraw()
	for child in node.get_children(): walk(child, language, skip)
	# Choice cards use anchored label containers inside buttons. Grow their height
	# for Myanmar line wrapping, then restore the authored size in English.
	if node is Button:
		for child in node.get_children():
			if child is MarginContainer:
				if language == "my":
					if not node.has_meta("se_card_size"): node.set_meta("se_card_size", node.custom_minimum_size)
					var original: Vector2 = node.get_meta("se_card_size")
					node.custom_minimum_size.y = maxf(original.y, child.get_combined_minimum_size().y)
				elif node.has_meta("se_card_size"): node.custom_minimum_size = node.get_meta("se_card_size")
