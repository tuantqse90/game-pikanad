extends Node2D

## Main overworld zone (Starter Meadow). Sets up terrain programmatically,
## spawns wild creatures, and creates portals to other zones.

const WILD_CREATURE_SCENE := preload("res://scenes/creatures/wild_creature.tscn")
const ZONE_PORTAL_SCENE := preload("res://scenes/world/zone_portal.tscn")
const NPC_SCENE := preload("res://scenes/npc/npc_base.tscn")

var species_list: Array[CreatureData] = []
var meadow_species: Array[CreatureData] = []

var _canvas_modulate: CanvasModulate
var _quest_panel: Node

@onready var player: CharacterBody2D = $Player

const MAP_W := 20
const MAP_H := 15

func _ready() -> void:
	GameManager.change_state(GameManager.GameState.OVERWORLD)
	GameManager.set_meta("battle_zone", "Starter Meadow")

	species_list = [
		load("res://resources/creatures/flamepup.tres"),
		load("res://resources/creatures/aquafin.tres"),
		load("res://resources/creatures/thornsprout.tres"),
		load("res://resources/creatures/zephyrix.tres"),
		load("res://resources/creatures/stoneling.tres"),
	]

	meadow_species = [
		species_list[2],
		species_list[3],
		load("res://resources/creatures/vinewhisker.tres"),
		load("res://resources/creatures/breezeling.tres"),
	]

	if PartyManager.party_size() == 0:
		PartyManager.give_starter(species_list[0], 5)

	if GameManager.has_meta("zone_spawn_offset"):
		var offset: Vector2 = GameManager.get_meta("zone_spawn_offset")
		player.position = offset
		GameManager.remove_meta("zone_spawn_offset")

	_build_terrain()
	_spawn_wild_creatures()
	_create_portals()
	_create_npcs()
	_setup_day_night()
	_setup_minimap()

	GameManager.set_meta("zone_weather", WeatherSystem.WeatherType.CLEAR)
	StatsManager.add_zone("Starter Meadow")

	# Tutorial triggers
	_trigger_tutorials()

func _build_terrain() -> void:
	# Ground texture variation: scattered color patches for visual interest
	var base_green := Color(0.22, 0.48, 0.18)
	for i in 18:
		var patch := ColorRect.new()
		var shade := randf_range(-0.04, 0.04)
		patch.color = Color(
			base_green.r + shade,
			base_green.g + randf_range(-0.06, 0.06),
			base_green.b + shade,
			0.3
		)
		patch.size = Vector2(randf_range(30, 80), randf_range(20, 50))
		patch.position = Vector2(randf_range(-300, 280), randf_range(-220, 200))
		patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		patch.z_index = -5
		add_child(patch)

	# Decorative grass tufts
	for i in 25:
		var tuft := ColorRect.new()
		tuft.color = Color(0.18, 0.55, 0.15, 0.35)
		tuft.size = Vector2(randf_range(3, 8), randf_range(2, 5))
		tuft.position = Vector2(randf_range(-300, 290), randf_range(-220, 210))
		tuft.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tuft.z_index = -4
		add_child(tuft)

func _spawn_wild_creatures() -> void:
	var spawn_count := 8
	for i in spawn_count:
		var creature_node: Area2D = WILD_CREATURE_SCENE.instantiate()
		var species_index := randi() % meadow_species.size()
		creature_node.creature_data = meadow_species[species_index]
		creature_node.position = Vector2(
			randf_range(-280, 280),
			randf_range(-200, 200)
		)
		if creature_node.position.distance_to(player.position) < 60:
			creature_node.position = Vector2(150, 100)
		add_child(creature_node)

func _create_portals() -> void:
	_add_portal(Vector2(300, 0), "res://scenes/world/zones/fire_volcano.tscn", Vector2(-280, 0), "Fire Volcano >>")
	_add_portal(Vector2(0, 220), "res://scenes/world/zones/water_coast.tscn", Vector2(0, -200), "Water Coast vv")
	_add_portal(Vector2(-300, 0), "res://scenes/world/zones/forest_grove.tscn", Vector2(280, 0), "<< Forest Grove")
	_add_portal(Vector2(0, -220), "res://scenes/world/zones/earth_caves.tscn", Vector2(0, 200), "^^ Earth Caves")
	_add_portal(Vector2(250, -180), "res://scenes/world/zones/champion_arena.tscn", Vector2(0, 200), "Champion Arena")

func _create_npcs() -> void:
	var healer: Area2D = NPC_SCENE.instantiate()
	healer.npc_name = "Nurse Joy"
	healer.npc_type = healer.NPCType.HEALER
	healer.npc_color = Color(0.9, 0.5, 0.5)
	healer.dialogue_lines = ["Let me heal your creatures!", "All better now!"]
	healer.position = Vector2(-80, -80)
	add_child(healer)

	var shopkeeper: Area2D = NPC_SCENE.instantiate()
	shopkeeper.npc_name = "Merchant"
	shopkeeper.npc_type = shopkeeper.NPCType.SHOPKEEPER
	shopkeeper.npc_color = Color(0.3, 0.6, 0.9)
	shopkeeper.dialogue_lines = ["Welcome to my shop!"]
	var shop_list: Array[Resource] = [
		load("res://resources/items/capture_ball.tres"),
		load("res://resources/items/potion.tres"),
	]
	if BadgeManager and BadgeManager.has_badge(2):
		shop_list.append(load("res://resources/items/super_ball.tres"))
	if BadgeManager and BadgeManager.has_badge(6):
		shop_list.append(load("res://resources/items/ultra_ball.tres"))
	shopkeeper.shop_items = shop_list
	shopkeeper.position = Vector2(80, -80)
	add_child(shopkeeper)

	var talker: Area2D = NPC_SCENE.instantiate()
	talker.npc_name = "Old Man"
	talker.npc_type = talker.NPCType.TALKER
	talker.npc_color = Color(0.7, 0.65, 0.5)
	talker.dialogue_lines = [
		"Welcome to Game Pikanad!",
		"Explore different zones to find rare creatures.",
		"Defeat zone leaders to earn badges!",
		"Collect all 8 badges to challenge the Champion!",
	]
	talker.position = Vector2(0, -120)
	add_child(talker)

	var kai: Area2D = NPC_SCENE.instantiate()
	kai.npc_name = "Leader Kai"
	kai.npc_type = kai.NPCType.TRAINER
	kai.npc_color = Color(0.3, 0.8, 0.3)
	kai.trainer_data_path = "res://resources/trainers/leader_kai.tres"
	kai.trainer_id = "kai"
	kai.position = Vector2(-150, 80)
	add_child(kai)

	var trader: Area2D = NPC_SCENE.instantiate()
	trader.npc_name = "Trader"
	trader.npc_type = trader.NPCType.TALKER
	trader.npc_color = Color(0.8, 0.6, 0.2)
	trader.dialogue_lines = [
		"Trading is coming soon! Stay tuned.",
		"Soon you'll be able to trade creatures with other players!",
	]
	trader.position = Vector2(120, 80)
	add_child(trader)

func _add_portal(pos: Vector2, target: String, spawn_offset: Vector2, label: String) -> void:
	var portal: Area2D = ZONE_PORTAL_SCENE.instantiate()
	portal.position = pos
	portal.target_zone_path = target
	portal.spawn_offset = spawn_offset
	portal.portal_label = label
	add_child(portal)

func _setup_minimap() -> void:
	var minimap_layer := CanvasLayer.new()
	minimap_layer.layer = 90
	add_child(minimap_layer)
	var minimap := preload("res://scripts/ui/minimap.gd").new()
	minimap.setup(self, "Starter Meadow")
	minimap_layer.add_child(minimap)

func _setup_day_night() -> void:
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.color = TimeManager.get_tint_color()
	add_child(_canvas_modulate)
	TimeManager.phase_changed.connect(_on_time_phase_changed)

func _on_time_phase_changed(_new_phase: int) -> void:
	if _canvas_modulate:
		var tween := create_tween()
		tween.tween_property(_canvas_modulate, "color", TimeManager.get_tint_color(), 2.0)

func _trigger_tutorials() -> void:
	if not TutorialManager:
		return
	# Welcome + movement on first overworld entry
	if not TutorialManager.is_completed("welcome"):
		await get_tree().create_timer(0.5).timeout
		TutorialManager.show_tutorial("welcome")
		# Chain movement tutorial after welcome
		await get_tree().create_timer(1.0).timeout
		if not TutorialManager.is_completed("movement"):
			TutorialManager.show_tutorial("movement")
	# First creature tutorial when party size == 1
	if PartyManager.party_size() == 1 and not TutorialManager.is_completed("first_creature"):
		await get_tree().create_timer(1.5).timeout
		TutorialManager.show_tutorial("first_creature")

func _input(event: InputEvent) -> void:
	if GameManager.state != GameManager.GameState.OVERWORLD:
		return
	if event.is_action_pressed("open_quests") and not _quest_panel:
		_quest_panel = load("res://scripts/ui/quest_panel.gd").new()
		add_child(_quest_panel)
		_quest_panel.closed.connect(func():
			_quest_panel = null
		)
