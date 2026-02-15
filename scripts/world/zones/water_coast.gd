extends "res://scripts/world/zone_base.gd"

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
