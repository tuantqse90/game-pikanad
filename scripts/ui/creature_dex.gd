extends CanvasLayer

## Creature Dex — grid view of all species with seen/caught status.

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

func _load_all_creatures() -> void:
	# Load all creature data resources, sorted by dex_number
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
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(100, 36)

		match status:
			DexManager.DexStatus.UNSEEN:
				btn.text = "#%d ???" % creature.dex_number
				btn.modulate = Color(0.4, 0.4, 0.4)
			DexManager.DexStatus.SEEN:
				btn.text = "#%d %s" % [creature.dex_number, creature.species_name]
				btn.modulate = Color(0.8, 0.8, 0.8)
			DexManager.DexStatus.CAUGHT:
				btn.text = "#%d %s *" % [creature.dex_number, creature.species_name]
				btn.modulate = Color(1.0, 1.0, 1.0)

		var creature_ref := creature
		var status_ref := status
		btn.pressed.connect(func(): _show_detail(creature_ref, status_ref))
		grid.add_child(btn)

func _show_detail(creature: CreatureData, status: int) -> void:
	if status == DexManager.DexStatus.UNSEEN:
		detail_panel.visible = true
		detail_sprite.texture = null
		detail_info.text = "???\nNot yet discovered."
		detail_stats.text = ""
		return

	detail_panel.visible = true
	detail_sprite.texture = creature.sprite_texture

	var element_names := ["Fire", "Water", "Grass", "Wind", "Earth", "Neutral"]
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
