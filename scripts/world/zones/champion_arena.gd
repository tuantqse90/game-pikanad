extends "res://scripts/world/zone_base.gd"

const NPC_SCENE := preload("res://scenes/npc/npc_base.tscn")

func _init() -> void:
	bg_color = Color(0.3, 0.15, 0.4)
	zone_name = "Champion Arena"
	level_min = 40
	level_max = 50
	spawn_count = 0  # No wild encounters

func _get_zone_species() -> Array[CreatureData]:
	return []

func _get_portals() -> Array[Dictionary]:
	return [{
		"pos": Vector2(0, 220),
		"target": "res://scenes/world/overworld.tscn",
		"spawn_offset": Vector2(0, -180),
		"label": "vv Starter Meadow"
	}]

func _ready() -> void:
	super._ready()
	_create_leader_npc()

func _create_leader_npc() -> void:
	var leader: Area2D = NPC_SCENE.instantiate()
	leader.npc_name = "Champion Aria"
	leader.npc_type = leader.NPCType.TRAINER
	leader.npc_color = Color(0.9, 0.8, 0.2)
	leader.trainer_data_path = "res://resources/trainers/leader_aria.tres"
	leader.trainer_id = "aria"
	leader.position = Vector2(0, -80)
	add_child(leader)
