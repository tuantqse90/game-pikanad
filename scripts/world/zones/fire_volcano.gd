extends "res://scripts/world/zone_base.gd"

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
	return [{
		"pos": Vector2(-300, 0),
		"target": "res://scenes/world/overworld.tscn",
		"spawn_offset": Vector2(280, 0),
		"label": "<< Starter Meadow"
	}]
