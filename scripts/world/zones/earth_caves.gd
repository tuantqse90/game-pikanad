extends "res://scripts/world/zone_base.gd"

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
	return [{
		"pos": Vector2(0, 220),
		"target": "res://scenes/world/overworld.tscn",
		"spawn_offset": Vector2(0, -200),
		"label": "vv Starter Meadow"
	}]
