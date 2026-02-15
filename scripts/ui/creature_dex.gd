extends CanvasLayer

## Creature Dex — grid cards with element-colored borders,
## gold stars for caught, silver for seen, dark "?" for unseen.

@onready var panel: PanelContainer = $Panel
@onready var header_label: Label = $Panel/VBox/HeaderLabel
@onready var grid: GridContainer = $Panel/VBox/ScrollContainer/Grid
@onready var detail_panel: PanelContainer = $Panel/VBox/DetailPanel
@onready var detail_sprite: TextureRect = $Panel/VBox/DetailPanel/DetailVBox/DetailTop/DetailSprite
@onready var detail_info: Label = $Panel/VBox/DetailPanel/DetailVBox/DetailTop/DetailInfo
@onready var detail_stats: Label = $Panel/VBox/DetailPanel/DetailVBox/DetailStats
@onready var close_btn: Button = $Panel/VBox/CloseBtn

var _is_open := false
var _all_creatures: Array[CreatureData] = []
var _previous_state: int = GameManager.GameState.OVERWORLD

func _ready() -> void:
	panel.visible = false
	detail_panel.visible = false
	close_btn.pressed.connect(close_dex)
	_load_all_creatures()

	# Style header
	header_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)

func _load_all_creatures() -> void:
	var creature_paths := [
		"res://resources/creatures/flamepup.tres",
		"res://resources/creatures/blazefox.tres",
		"res://resources/creatures/pyrodrake.tres",
		"res://resources/creatures/aquafin.tres",
		"res://resources/creatures/tidecrab.tres",
		"res://resources/creatures/tsunariel.tres",
		"res://resources/creatures/thornsprout.tres",
		"res://resources/creatures/floravine.tres",
		"res://resources/creatures/elderoak.tres",
		"res://resources/creatures/vinewhisker.tres",
		"res://resources/creatures/breezeling.tres",
		"res://resources/creatures/zephyrix.tres",
		"res://resources/creatures/stormraptor.tres",
		"res://resources/creatures/stoneling.tres",
		"res://resources/creatures/boulderkin.tres",
	]
	for path in creature_paths:
		var data := load(path) as CreatureData
		if data:
			_all_creatures.append(data)

func open_dex() -> void:
	_is_open = true
	_previous_state = GameManager.state
	panel.visible = true
	detail_panel.visible = false
	_refresh_grid()

func close_dex() -> void:
	_is_open = false
	panel.visible = false
	GameManager.change_state(_previous_state)

func _refresh_grid() -> void:
	var caught_count := DexManager.get_caught_count() if DexManager else 0
	header_label.text = "Pikanadex - %d/%d caught" % [caught_count, DexManager.TOTAL_SPECIES]

	for child in grid.get_children():
		child.queue_free()

	for creature in _all_creatures:
		var status := DexManager.get_status(creature.species_id) if DexManager else DexManager.DexStatus.UNSEEN
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(100, 40)

		# Element-colored border for caught, silver for seen, dark for unseen
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = ThemeManager.COL_BG_PANEL_LIGHT
		card_style.set_corner_radius_all(3)
		card_style.set_border_width_all(1)
		card_style.content_margin_left = 4.0
		card_style.content_margin_right = 4.0
		card_style.content_margin_top = 3.0
		card_style.content_margin_bottom = 3.0

		var label_text := ""
		match status:
			DexManager.DexStatus.UNSEEN:
				card_style.border_color = Color(0.2, 0.18, 0.28)
				card_style.bg_color = Color(0.08, 0.06, 0.12)
				label_text = "#%d ?" % creature.dex_number
			DexManager.DexStatus.SEEN:
				card_style.border_color = Color(0.5, 0.5, 0.55)
				label_text = "#%d %s" % [creature.dex_number, creature.species_name]
			DexManager.DexStatus.CAUGHT:
				var el_col: Color = ThemeManager.ELEMENT_COLORS.get(creature.element, Color.GRAY)
				card_style.border_color = el_col
				label_text = "#%d %s \u2605" % [creature.dex_number, creature.species_name]

		card.add_theme_stylebox_override("panel", card_style)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		card.add_child(hbox)

		# Sprite thumbnail (colored rect)
		if status != DexManager.DexStatus.UNSEEN:
			var thumb := ColorRect.new()
			thumb.custom_minimum_size = Vector2(14, 14)
			thumb.color = ThemeManager.ELEMENT_COLORS.get(creature.element, Color.GRAY)
			if status == DexManager.DexStatus.SEEN:
				thumb.modulate = Color(0.6, 0.6, 0.6)
			hbox.add_child(thumb)

		var lbl := Label.new()
		lbl.text = label_text
		lbl.add_theme_font_size_override("font_size", 9)
		if status == DexManager.DexStatus.UNSEEN:
			lbl.add_theme_color_override("font_color", Color(0.35, 0.32, 0.42))
		elif status == DexManager.DexStatus.CAUGHT:
			lbl.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
		hbox.add_child(lbl)

		var creature_ref := creature
		var status_ref := status
		# Make the card clickable via input
		var btn_overlay := Button.new()
		btn_overlay.flat = true
		btn_overlay.anchors_preset = Control.PRESET_FULL_RECT
		btn_overlay.anchor_right = 1.0
		btn_overlay.anchor_bottom = 1.0
		btn_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		btn_overlay.pressed.connect(func(): _show_detail(creature_ref, status_ref))
		card.add_child(btn_overlay)

		grid.add_child(card)

func _show_detail(creature: CreatureData, status: int) -> void:
	if status == DexManager.DexStatus.UNSEEN:
		detail_panel.visible = true
		detail_sprite.texture = null
		detail_info.text = "???\nNot yet discovered."
		detail_stats.text = ""
		return

	detail_panel.visible = true
	detail_sprite.texture = creature.sprite_texture

	var element_names := ThemeManager.ELEMENT_NAMES
	var rarity_names := ["Common", "Uncommon", "Rare", "Legendary"]

	detail_info.text = "%s\n%s | %s" % [
		creature.species_name,
		element_names[creature.element],
		rarity_names[creature.rarity]
	]

	if status == DexManager.DexStatus.CAUGHT:
		var evo_text := ""
		if creature.evolves_into:
			evo_text = "\nEvolves at Lv.%d" % creature.evolution_level
		detail_stats.text = "HP:%d ATK:%d DEF:%d SPD:%d%s" % [
			creature.base_hp, creature.base_attack,
			creature.base_defense, creature.base_speed,
			evo_text
		]
	else:
		detail_stats.text = "Catch to see full stats!"
