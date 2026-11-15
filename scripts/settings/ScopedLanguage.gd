extends Node
## Session-only display localization. Never mutates configs, reports or evidence.
const COPY = preload("res://scripts/settings/MyanmarText.gd")
var controller: Control

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if not is_instance_valid(controller.current): return
	var language: String = str(controller.preferences.get("language", "en"))
	walk(controller.shell, language, controller.host)
	walk(controller.current, language)
	# Save-A offers and language settings belong to the controller, not the page.
	for child in controller.get_children():
		if child is Window: walk(child, language)

func property_text(node: Object, property: String, language: String) -> void:
	var value: String = node.get(property)
	var key: String = "se_copy_" + property
	var previous: Dictionary = node.get_meta(key, {})
	if value == previous.get("rendered") and previous.get("language") == language: return
	var source: String = previous.get("source", value) if value == previous.get("rendered") else value
	var binding: Dictionary = node.get_meta("ke3_copy_" + property, {})
	var rendered: String = COPY.text(source, language) if binding.is_empty() else COPY.format_copy(binding.template, binding.values, language)
	if value != rendered: node.set(property, rendered)
	node.set_meta(key, {"source":source, "rendered":rendered, "language":language})

func walk(node: Node, language: String, skip: Node = null) -> void:
	if node == skip: return
	if node is Control or node is Window:
		if node.get_meta("se_font_language", "en") != language:
			if language == "my":
				if not node.has_meta("se_language_font"):
					node.set_meta("se_language_font", {"font":node.get_theme_font("font") if node.has_theme_font_override("font") else null})
				node.add_theme_font_override("font", COPY.myanmar_font())
			elif node.has_meta("se_language_font"):
				if node.get_meta("se_language_font").font != null: node.add_theme_font_override("font", node.get_meta("se_language_font").font)
				else: node.remove_theme_font_override("font")
			node.set_meta("se_font_language", language)
		if node is Control: property_text(node, "tooltip_text", language)
	if node is Label or node is Button:
		# OptionButton text is derived from its selected item; translate items below.
		if not node is OptionButton: property_text(node, "text", language)
	if node is LineEdit or node is TextEdit: property_text(node, "placeholder_text", language)
	if node is AcceptDialog:
		property_text(node, "title", language)
		property_text(node, "dialog_text", language)
		property_text(node, "ok_button_text", language)
		if node is ConfirmationDialog: property_text(node, "cancel_button_text", language)
		# AcceptDialog mirrors its text in an internal Label. Retain the same
		# protected template there rather than translating its raw arguments again.
		if node.has_meta("ke3_copy_dialog_text"):
			node.get_label().set_meta("ke3_copy_text", node.get_meta("ke3_copy_dialog_text"))
	if node is OptionButton:
		for index in node.item_count:
			var key: String = "se_item_" + str(index)
			var value: String = node.get_item_text(index)
			var previous: Dictionary = node.get_meta(key, {})
			var source: String = previous.get("source", value) if value == previous.get("rendered") else value
			var rendered: String = COPY.text(source, language)
			if value != rendered: node.set_item_text(index, rendered)
			node.set_meta(key, {"source":source, "rendered":rendered})
	# Translate captions in place: indices, checked state, selected history and IDs
	# remain unchanged. Original captions restore on English and dynamic rebuilds.
	if node is TabBar or node is ItemList or node is PopupMenu:
		var count: int = node.tab_count if node is TabBar else node.item_count
		for index in count:
			var value: String = node.get_tab_title(index) if node is TabBar else node.get_item_text(index)
			var key: String = "ke3_item_" + str(index)
			var previous: Dictionary = node.get_meta(key, {})
			var source: String = previous.get("source", value) if value == previous.get("rendered") else value
			var rendered: String = COPY.text(source, language)
			if value != rendered:
				if node is TabBar: node.set_tab_title(index, rendered)
				else: node.set_item_text(index, rendered)
			node.set_meta(key, {"source":source,"rendered":rendered})
	# These SE-only controls draw their own captions instead of using Label nodes.
	var script: Script = node.get_script()
	if script != null and script.resource_path in ["res://ui/components/ResourceGauge.gd", "res://ui/components/MissionFlow.gd"]:
		if node.get_meta("se_language", "en") != language:
			node.set_meta("se_language", language)
			node.queue_redraw()
	for child in node.get_children(true): walk(child, language, skip)
	if node is TabBar: node.scrolling_enabled = true
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
