extends Node

## Sets up a global RPG-styled UI theme with double-border panels,
## a named color palette, and polished button/HP bar styles.

# ── Named Color Palette ─────────────────────────────────────────────
const COL_BG_DARKEST     := Color(0.06, 0.05, 0.1)
const COL_BG_PANEL       := Color(0.13, 0.11, 0.22)
const COL_BG_PANEL_LIGHT := Color(0.17, 0.15, 0.27)
const COL_BORDER_DARK    := Color(0.08, 0.06, 0.14)
const COL_BORDER_LIGHT   := Color(0.45, 0.42, 0.58)
const COL_ACCENT         := Color(0.35, 0.6, 0.95)
const COL_ACCENT_GOLD    := Color(1.0, 0.85, 0.25)
const COL_ACCENT_GREEN   := Color(0.3, 0.85, 0.35)
const COL_ACCENT_RED     := Color(0.95, 0.25, 0.2)
const COL_TEXT_BRIGHT    := Color(0.98, 0.97, 1.0)
const COL_TEXT_DIM       := Color(0.6, 0.58, 0.68)
const COL_SEPARATOR      := Color(0.3, 0.28, 0.42, 0.5)

const ELEMENT_COLORS := {
	0: Color(0.95, 0.5, 0.15),   # Fire — orange
	1: Color(0.25, 0.55, 0.95),  # Water — blue
	2: Color(0.3, 0.8, 0.3),     # Grass — green
	3: Color(0.6, 0.8, 0.95),    # Wind — pale blue
	4: Color(0.65, 0.45, 0.25),  # Earth — brown
	5: Color(0.6, 0.6, 0.6),     # Neutral — gray
}

const ELEMENT_NAMES := ["Fire", "Water", "Grass", "Wind", "Earth", "Neutral"]

var game_theme: Theme

func _ready() -> void:
	game_theme = _create_theme()
	get_tree().root.theme = game_theme

func _create_theme() -> Theme:
	var theme := Theme.new()
	theme.set_default_font_size(10)

	# ── RPG Window Panel Style (double-border) ──
	var panel_style := _flat_style(COL_BG_PANEL, 5)
	panel_style.border_width_bottom = 2
	panel_style.border_width_top = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = COL_BORDER_LIGHT
	panel_style.shadow_color = COL_BORDER_DARK
	panel_style.shadow_size = 3
	panel_style.content_margin_left = 8.0
	panel_style.content_margin_right = 8.0
	panel_style.content_margin_top = 6.0
	panel_style.content_margin_bottom = 6.0
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	# ── Button Overhaul ──
	var btn_normal := _flat_style(Color(0.14, 0.12, 0.24), 4)
	btn_normal.border_width_bottom = 1
	btn_normal.border_width_top = 1
	btn_normal.border_width_left = 1
	btn_normal.border_width_right = 1
	btn_normal.border_color = Color(0.3, 0.28, 0.42)
	btn_normal.content_margin_left = 10.0
	btn_normal.content_margin_right = 10.0
	btn_normal.content_margin_top = 6.0
	btn_normal.content_margin_bottom = 6.0

	var btn_hover := _flat_style(COL_BG_PANEL_LIGHT, 4)
	btn_hover.border_width_bottom = 1
	btn_hover.border_width_top = 1
	btn_hover.border_width_left = 1
	btn_hover.border_width_right = 1
	btn_hover.border_color = COL_ACCENT
	btn_hover.content_margin_left = 10.0
	btn_hover.content_margin_right = 10.0
	btn_hover.content_margin_top = 6.0
	btn_hover.content_margin_bottom = 6.0

	var btn_pressed := _flat_style(Color(0.08, 0.06, 0.16), 4)
	btn_pressed.border_width_bottom = 1
	btn_pressed.border_width_top = 1
	btn_pressed.border_width_left = 1
	btn_pressed.border_width_right = 1
	btn_pressed.border_color = Color(0.25, 0.22, 0.38)
	btn_pressed.content_margin_left = 10.0
	btn_pressed.content_margin_right = 10.0
	btn_pressed.content_margin_top = 6.0
	btn_pressed.content_margin_bottom = 6.0

	var btn_disabled := _flat_style(Color(0.12, 0.11, 0.18), 4)
	btn_disabled.border_width_bottom = 1
	btn_disabled.border_width_top = 1
	btn_disabled.border_width_left = 1
	btn_disabled.border_width_right = 1
	btn_disabled.border_color = Color(0.2, 0.18, 0.28)
	btn_disabled.content_margin_left = 10.0
	btn_disabled.content_margin_right = 10.0
	btn_disabled.content_margin_top = 6.0
	btn_disabled.content_margin_bottom = 6.0

	var btn_focus := btn_normal.duplicate()
	btn_focus.border_width_bottom = 2
	btn_focus.border_width_top = 2
	btn_focus.border_width_left = 2
	btn_focus.border_width_right = 2
	btn_focus.border_color = COL_ACCENT

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", btn_focus)
	theme.set_color("font_color", "Button", COL_TEXT_BRIGHT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color(0.7, 0.75, 0.9))
	theme.set_color("font_disabled_color", "Button", Color(0.35, 0.33, 0.42))
	theme.set_font_size("font_size", "Button", 10)

	# ── Label ──
	theme.set_color("font_color", "Label", COL_TEXT_BRIGHT)
	theme.set_font_size("font_size", "Label", 10)

	# ── HP Bar Style ──
	var hp_bg := _flat_style(Color(0.08, 0.06, 0.14), 2)
	hp_bg.border_width_bottom = 1
	hp_bg.border_width_top = 1
	hp_bg.border_width_left = 1
	hp_bg.border_width_right = 1
	hp_bg.border_color = Color(0.25, 0.22, 0.36)
	hp_bg.content_margin_left = 0.0
	hp_bg.content_margin_right = 0.0
	hp_bg.content_margin_top = 0.0
	hp_bg.content_margin_bottom = 0.0

	var hp_fill := _flat_style(COL_ACCENT_GREEN, 2)
	hp_fill.content_margin_left = 0.0
	hp_fill.content_margin_right = 0.0
	hp_fill.content_margin_top = 0.0
	hp_fill.content_margin_bottom = 0.0

	theme.set_stylebox("background", "ProgressBar", hp_bg)
	theme.set_stylebox("fill", "ProgressBar", hp_fill)

	# ── Separator ──
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = COL_SEPARATOR
	sep_style.content_margin_top = 4.0
	sep_style.content_margin_bottom = 4.0
	theme.set_stylebox("separator", "HSeparator", sep_style)

	# ── ScrollContainer ──
	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0, 0, 0, 0)
	theme.set_stylebox("panel", "ScrollContainer", scroll_bg)

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

## Helper: create an element-colored label badge (e.g., "FIRE" in orange)
static func create_element_badge(element: int) -> Label:
	var badge := Label.new()
	badge.text = ELEMENT_NAMES[element] if element < ELEMENT_NAMES.size() else "???"
	badge.add_theme_font_size_override("font_size", 8)
	var col: Color = ELEMENT_COLORS.get(element, Color.GRAY)
	badge.add_theme_color_override("font_color", col)
	return badge

## Helper: create a status-colored label
static func get_status_color(status_name: String) -> Color:
	match status_name:
		"Burn": return Color(0.95, 0.55, 0.15)
		"Poison": return Color(0.7, 0.25, 0.85)
		"Sleep": return Color(0.4, 0.5, 0.9)
		"Paralyze": return Color(0.95, 0.85, 0.2)
		"Shield": return Color(0.3, 0.85, 0.9)
	return COL_TEXT_DIM
