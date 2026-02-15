extends "res://scripts/world/zone_base.gd"

const NPC_SCENE := preload("res://scenes/npc/npc_base.tscn")

func _init() -> void:
	bg_color = Color(0.15, 0.25, 0.45)
	zone_name = "Water Coast"
	level_min = 3
	level_max = 7

func _get_zone_species() -> Array[CreatureData]:
	return [
		load("res://resources/creatures/aquafin.tres"),
		load("res://resources/creatures/zephyrix.tres"),
		load("res://resources/creatures/tidecrab.tres"),
		load("res://resources/creatures/tsunariel.tres"),
	]

func _get_portals() -> Array[Dictionary]:
	return [{
		"pos": Vector2(0, -220),
		"target": "res://scenes/world/overworld.tscn",
		"spawn_offset": Vector2(0, 200),
		"label": "^^ Starter Meadow"
	}]

func _ready() -> void:
	super._ready()
	_create_leader_npc()

func _create_leader_npc() -> void:
	var leader: Area2D = NPC_SCENE.instantiate()
	leader.npc_name = "Leader Marina"
	leader.npc_type = leader.NPCType.TRAINER
	leader.npc_color = Color(0.2, 0.5, 0.9)
	leader.trainer_data_path = "res://resources/trainers/leader_marina.tres"
	leader.trainer_id = "marina"
	leader.position = Vector2(100, 0)
	add_child(leader)
