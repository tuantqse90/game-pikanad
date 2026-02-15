extends Node2D

## Main overworld zone (Starter Meadow). Sets up TileMap terrain programmatically,
## spawns wild creatures, and creates portals to other zones.

const WILD_CREATURE_SCENE := preload("res://scenes/creatures/wild_creature.tscn")
const ZONE_PORTAL_SCENE := preload("res://scenes/world/zone_portal.tscn")
const NPC_SCENE := preload("res://scenes/npc/npc_base.tscn")

# All 5 base species
var species_list: Array[CreatureData] = []

# Zone-specific creature pools
var meadow_species: Array[CreatureData] = []

var _canvas_modulate: CanvasModulate

@onready var player: CharacterBody2D = $Player

const MAP_W := 20  # tiles
const MAP_H := 15

func _ready() -> void:
	GameManager.change_state(GameManager.GameState.OVERWORLD)
	GameManager.set_meta("battle_zone", "Starter Meadow")

	# Load species data
	species_list = [
		load("res://resources/creatures/flamepup.tres"),
		load("res://resources/creatures/aquafin.tres"),
		load("res://resources/creatures/thornsprout.tres"),
		load("res://resources/creatures/zephyrix.tres"),
		load("res://resources/creatures/stoneling.tres"),
	]

	# Meadow has common grass/wind creatures
	meadow_species = [
		species_list[2],  # Thornsprout
		species_list[3],  # Zephyrix
		load("res://resources/creatures/vinewhisker.tres"),
		load("res://resources/creatures/breezeling.tres"),
	]

	# Give starter if party is empty
	if PartyManager.party_size() == 0:
		PartyManager.give_starter(species_list[0], 5)

	# Handle spawn position from portal
	if GameManager.has_meta("zone_spawn_offset"):
		var offset: Vector2 = GameManager.get_meta("zone_spawn_offset")
		player.position = offset
		GameManager.remove_meta("zone_spawn_offset")

	# Build terrain
	_build_terrain()

	# Spawn wild creatures
	_spawn_wild_creatures()

	# Create zone portals
	_create_portals()

	# Spawn NPCs
	_create_npcs()

	# Day/night cycle
	_setup_day_night()

	# Minimap
	_setup_minimap()

	# Weather (meadow = clear)
	GameManager.set_meta("zone_weather", WeatherSystem.WeatherType.CLEAR)

func _build_terrain() -> void:
	# Create a simple colored background based on zone biome
	# The Background ColorRect already exists in the scene
	pass

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
		# Avoid spawning on top of the player
		if creature_node.position.distance_to(player.position) < 60:
			creature_node.position = Vector2(150, 100)
		add_child(creature_node)

func _create_portals() -> void:
	# Portal to Fire Volcano (right side)
	_add_portal(
		Vector2(300, 0),
		"res://scenes/world/zones/fire_volcano.tscn",
		Vector2(-280, 0),
		"Fire Volcano >>"
	)

	# Portal to Water Coast (bottom)
	_add_portal(
		Vector2(0, 220),
		"res://scenes/world/zones/water_coast.tscn",
		Vector2(0, -200),
		"Water Coast vv"
	)

	# Portal to Forest Grove (left side)
	_add_portal(
		Vector2(-300, 0),
		"res://scenes/world/zones/forest_grove.tscn",
		Vector2(280, 0),
		"<< Forest Grove"
	)

	# Portal to Earth Caves (top)
	_add_portal(
		Vector2(0, -220),
		"res://scenes/world/zones/earth_caves.tscn",
		Vector2(0, 200),
		"^^ Earth Caves"
	)

	# Portal to Champion Arena (top-right)
	_add_portal(
		Vector2(250, -180),
		"res://scenes/world/zones/champion_arena.tscn",
		Vector2(0, 200),
		"Champion Arena"
	)

func _create_npcs() -> void:
	# Healer NPC
	var healer: Area2D = NPC_SCENE.instantiate()
	healer.npc_name = "Nurse Joy"
	healer.npc_type = healer.NPCType.HEALER
	healer.npc_color = Color(0.9, 0.5, 0.5)
	healer.dialogue_lines = ["Let me heal your creatures!", "All better now!"]
	healer.position = Vector2(-80, -80)
	add_child(healer)

	# Shopkeeper NPC
	var shopkeeper: Area2D = NPC_SCENE.instantiate()
	shopkeeper.npc_name = "Merchant"
	shopkeeper.npc_type = shopkeeper.NPCType.SHOPKEEPER
	shopkeeper.npc_color = Color(0.3, 0.6, 0.9)
	shopkeeper.dialogue_lines = ["Welcome to my shop!"]
	var shop_list: Array[Resource] = [
		load("res://resources/items/capture_ball.tres"),
		load("res://resources/items/potion.tres"),
	]
	# Badge 2: Super Ball available
	if BadgeManager and BadgeManager.has_badge(2):
		shop_list.append(load("res://resources/items/super_ball.tres"))
	# Badge 6: Ultra Ball available
	if BadgeManager and BadgeManager.has_badge(6):
		shop_list.append(load("res://resources/items/ultra_ball.tres"))
	shopkeeper.shop_items = shop_list
	shopkeeper.position = Vector2(80, -80)
	add_child(shopkeeper)

	# Talker NPC (hint giver)
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

	# Leader Kai (Badge 1)
	var kai: Area2D = NPC_SCENE.instantiate()
	kai.npc_name = "Leader Kai"
	kai.npc_type = kai.NPCType.TRAINER
	kai.npc_color = Color(0.3, 0.8, 0.3)
	kai.trainer_data_path = "res://resources/trainers/leader_kai.tres"
	kai.trainer_id = "kai"
	kai.position = Vector2(-150, 80)
	add_child(kai)

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
	minimap.setup(self)
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
