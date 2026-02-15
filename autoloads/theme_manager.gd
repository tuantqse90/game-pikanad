extends Node

## Sets up a global pixel-art UI theme applied to the viewport.

var game_theme: Theme

func _ready() -> void:
	game_theme = _create_theme()
	# Apply theme globally to the default viewport
	get_tree().root.theme = game_theme

func _create_theme() -> Theme:
	var theme := Theme.new()

	# Default font size for pixel art
	theme.set_default_font_size(10)

	# ── Colors ──
	var bg_dark := Color(0.12, 0.11, 0.18, 0.9)
	var bg_panel := Color(0.15, 0.14, 0.22, 0.95)
	var accent := Color(0.3, 0.55, 0.9)
	var accent_hover := Color(0.4, 0.65, 1.0)
	var accent_pressed := Color(0.2, 0.4, 0.7)
	var text_color := Color(0.95, 0.95, 0.95)
	var text_dim := Color(0.65, 0.62, 0.7)

	# ── Button styles ──
	var btn_normal := _flat_style(Color(0.2, 0.22, 0.35), 3)
	var btn_hover := _flat_style(accent_hover * 0.7, 3)
	var btn_pressed := _flat_style(accent_pressed, 3)
	var btn_focus := _flat_style(Color(0.2, 0.22, 0.35), 3)
	btn_focus.border_width_bottom = 2
	btn_focus.border_width_top = 2
	btn_focus.border_width_left = 2
	btn_focus.border_width_right = 2
	btn_focus.border_color = accent

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("focus", "Button", btn_focus)
	theme.set_color("font_color", "Button", text_color)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color(0.8, 0.85, 1.0))
	theme.set_font_size("font_size", "Button", 10)

	# ── Panel styles ──
	var panel_style := _flat_style(bg_panel, 4)
	panel_style.border_width_bottom = 2
	panel_style.border_width_top = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = Color(0.3, 0.28, 0.4)
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	# ── Label ──
	theme.set_color("font_color", "Label", text_color)
	theme.set_font_size("font_size", "Label", 10)

	# ── ProgressBar (HP bars) ──
	var hp_bg := _flat_style(Color(0.15, 0.12, 0.2), 2)
	var hp_fill := _flat_style(Color(0.2, 0.8, 0.2), 2)
	theme.set_stylebox("background", "ProgressBar", hp_bg)
	theme.set_stylebox("fill", "ProgressBar", hp_fill)

	return theme

func _flat_style(color: Color, corner_radius: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style
