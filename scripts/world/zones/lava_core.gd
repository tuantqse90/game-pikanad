extends "res://scripts/world/zone_base.gd"

const NPC_SCENE := preload("res://scenes/npc/npc_base.tscn")

func _init() -> void:
	bg_color = Color(0.35, 0.08, 0.05)
	zone_name = "Lava Core"
	level_min = 30
	level_max = 40
	spawn_count = 8

func _get_zone_species() -> Array[CreatureData]:
	return [
		load("res://resources/creatures/flamepup.tres"),
		load("res://resources/creatures/blazefox.tres"),
		load("res://resources/creatures/pyrodrake.tres"),
		load("res://resources/creatures/boulderkin.tres"),
	]

func _get_portals() -> Array[Dictionary]:
	return [{
		"pos": Vector2(-300, 0),
		"target": "res://scenes/world/zones/fire_volcano.tscn",
		"spawn_offset": Vector2(280, 0),
		"label": "<< Fire Volcano"
	}]

func _ready() -> void:
	super._ready()
	_create_leader_npc()

func _create_leader_npc() -> void:
	var leader: Area2D = NPC_SCENE.instantiate()
	leader.npc_name = "Leader Obsidian"
	leader.npc_type = leader.NPCType.TRAINER
	leader.npc_color = Color(0.3, 0.2, 0.3)
	leader.trainer_data_path = "res://resources/trainers/leader_obsidian.tres"
	leader.trainer_id = "obsidian"
	leader.position = Vector2(0, -80)
	add_child(leader)
