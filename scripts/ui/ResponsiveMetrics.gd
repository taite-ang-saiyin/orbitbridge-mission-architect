extends RefCounted
## Preserve authored sizes, then apply a bounded desktop density without compounding.
static func apply(root: Node, factor: float) -> void:
	if root is Control:
		if root is Label or root is BaseButton or root is LineEdit or root is TextEdit or root is SpinBox:
			if not root.has_meta("desktop_font"):
				root.set_meta("desktop_font", root.get_theme_font_size("font_size"))
			var base = int(root.get_meta("desktop_font"))
			root.add_theme_font_size_override("font_size", roundi(maxi(base, 12) * factor))
		if root is BaseButton or root is LineEdit or root is SpinBox:
			if not root.has_meta("desktop_minimum"):
				root.set_meta("desktop_minimum", root.custom_minimum_size)
			var minimum: Vector2 = root.get_meta("desktop_minimum")
			root.custom_minimum_size = Vector2(minimum.x, maxf(44, minimum.y) * factor)
			root.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if root is BaseButton else Control.CURSOR_IBEAM
	for child in root.get_children():
		apply(child, factor)
