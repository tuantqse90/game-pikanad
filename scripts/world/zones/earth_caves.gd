extends "res://scripts/world/zone_base.gd"

const NPC_SCENE := preload("res://scenes/npc/npc_base.tscn")

func _init() -> void:
	bg_color = Color(0.18, 0.15, 0.12)
	zone_name = "Earth Caves"
	level_min = 5
	level_max = 10

func _get_zone_species() -> Array[CreatureData]:
	return [
		load("res://resources/creatures/stoneling.tres"),
		load("res://resources/creatures/flamepup.tres"),
		load("res://resources/creatures/boulderkin.tres"),
		load("res://resources/creatures/stormraptor.tres"),
	]

func _get_portals() -> Array[Dictionary]:
	return [
		{
			"pos": Vector2(0, 220),
			"target": "res://scenes/world/overworld.tscn",
			"spawn_offset": Vector2(0, -200),
			"label": "vv Starter Meadow"
		},
		{
			"pos": Vector2(0, -220),
			"target": "res://scenes/world/zones/sky_peaks.tscn",
			"spawn_offset": Vector2(0, 200),
			"label": "^^ Sky Peaks"
		},
	]

func _ready() -> void:
	super._ready()
	_create_leader_npc()

func _create_leader_npc() -> void:
	var leader: Area2D = NPC_SCENE.instantiate()
	leader.npc_name = "Leader Rumble"
	leader.npc_type = leader.NPCType.TRAINER
	leader.npc_color = Color(0.6, 0.4, 0.2)
	leader.trainer_data_path = "res://resources/trainers/leader_rumble.tres"
	leader.trainer_id = "rumble"
	leader.position = Vector2(100, 0)
	add_child(leader)
