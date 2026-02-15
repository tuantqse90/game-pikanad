extends "res://scripts/world/zone_base.gd"

const NPC_SCENE := preload("res://scenes/npc/npc_base.tscn")

func _init() -> void:
	bg_color = Color(0.35, 0.15, 0.1)
	zone_name = "Fire Volcano"
	level_min = 4
	level_max = 8

func _get_zone_species() -> Array[CreatureData]:
	return [
		load("res://resources/creatures/flamepup.tres"),
		load("res://resources/creatures/stoneling.tres"),
		load("res://resources/creatures/blazefox.tres"),
		load("res://resources/creatures/pyrodrake.tres"),
	]

func _get_portals() -> Array[Dictionary]:
	return [
		{
			"pos": Vector2(-300, 0),
			"target": "res://scenes/world/overworld.tscn",
			"spawn_offset": Vector2(280, 0),
			"label": "<< Starter Meadow"
		},
		{
			"pos": Vector2(300, 0),
			"target": "res://scenes/world/zones/lava_core.tscn",
			"spawn_offset": Vector2(-280, 0),
			"label": "Lava Core >>"
		},
	]

func _ready() -> void:
	super._ready()
	_create_leader_npc()

func _create_leader_npc() -> void:
	var leader: Area2D = NPC_SCENE.instantiate()
	leader.npc_name = "Leader Blaze"
	leader.npc_type = leader.NPCType.TRAINER
	leader.npc_color = Color(0.9, 0.3, 0.1)
	leader.trainer_data_path = "res://resources/trainers/leader_blaze.tres"
	leader.trainer_id = "blaze"
	leader.position = Vector2(100, 0)
	add_child(leader)
