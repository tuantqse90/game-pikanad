extends "res://scripts/world/zone_base.gd"

const NPC_SCENE := preload("res://scenes/npc/npc_base.tscn")

func _init() -> void:
	bg_color = Color(0.12, 0.3, 0.12)
	zone_name = "Forest Grove"
	level_min = 3
	level_max = 7

func _get_zone_species() -> Array[CreatureData]:
	return [
		load("res://resources/creatures/thornsprout.tres"),
		load("res://resources/creatures/zephyrix.tres"),
		load("res://resources/creatures/vinewhisker.tres"),
		load("res://resources/creatures/floravine.tres"),
		load("res://resources/creatures/elderoak.tres"),
	]

func _get_portals() -> Array[Dictionary]:
	return [{
		"pos": Vector2(300, 0),
		"target": "res://scenes/world/overworld.tscn",
		"spawn_offset": Vector2(-280, 0),
		"label": "Starter Meadow >>"
	}]

func _ready() -> void:
	super._ready()
	_create_leader_npc()

func _create_leader_npc() -> void:
	var leader: Area2D = NPC_SCENE.instantiate()
	leader.npc_name = "Leader Oakhart"
	leader.npc_type = leader.NPCType.TRAINER
	leader.npc_color = Color(0.4, 0.6, 0.2)
	leader.trainer_data_path = "res://resources/trainers/leader_oakhart.tres"
	leader.trainer_id = "oakhart"
	leader.position = Vector2(-100, 0)
	add_child(leader)
