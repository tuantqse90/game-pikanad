extends "res://scripts/world/zone_base.gd"

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
