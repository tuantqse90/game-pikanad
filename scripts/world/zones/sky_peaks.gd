extends "res://scripts/world/zone_base.gd"

const NPC_SCENE := preload("res://scenes/npc/npc_base.tscn")

func _init() -> void:
	bg_color = Color(0.6, 0.75, 0.9)
	zone_name = "Sky Peaks"
	level_min = 25
	level_max = 35
	spawn_count = 8

func _get_zone_species() -> Array[CreatureData]:
	return [
		load("res://resources/creatures/breezeling.tres"),
		load("res://resources/creatures/zephyrix.tres"),
		load("res://resources/creatures/stormraptor.tres"),
	]

func _get_portals() -> Array[Dictionary]:
	return [{
		"pos": Vector2(0, 220),
		"target": "res://scenes/world/zones/earth_caves.tscn",
		"spawn_offset": Vector2(0, -180),
		"label": "vv Earth Caves"
	}]

func _ready() -> void:
	super._ready()
	_create_leader_npc()

func _create_leader_npc() -> void:
	var leader: Area2D = NPC_SCENE.instantiate()
	leader.npc_name = "Leader Tempest"
	leader.npc_type = leader.NPCType.TRAINER
	leader.npc_color = Color(0.7, 0.7, 0.95)
	leader.trainer_data_path = "res://resources/trainers/leader_tempest.tres"
	leader.trainer_id = "tempest"
	leader.position = Vector2(0, -80)
	add_child(leader)
