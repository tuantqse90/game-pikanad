extends Node2D

## Spawns wild creatures in a zone area.

@export var creature_scene: PackedScene
@export var creature_species: Array[CreatureData] = []
@export var spawn_count: int = 5
@export var spawn_area_size := Vector2(500, 500)
@export var level_min: int = 2
@export var level_max: int = 6

func _ready() -> void:
	if creature_scene and creature_species.size() > 0:
		spawn_creatures()

func spawn_creatures() -> void:
	for i in spawn_count:
		var instance: Area2D = creature_scene.instantiate()
		var species_index := randi() % creature_species.size()
		instance.creature_data = creature_species[species_index]
		instance.level_min = level_min
		instance.level_max = level_max
		instance.position = Vector2(
			randf_range(-spawn_area_size.x / 2, spawn_area_size.x / 2),
			randf_range(-spawn_area_size.y / 2, spawn_area_size.y / 2)
		)
		add_child(instance)
