extends Node2D

## Base class for all zone scenes. Handles player setup, creature spawning,
## and portal creation. Subclasses set zone_species, bg_color, portals, etc.

const WILD_CREATURE_SCENE := preload("res://scenes/creatures/wild_creature.tscn")
const ZONE_PORTAL_SCENE := preload("res://scenes/world/zone_portal.tscn")

@export var bg_color := Color(0.2, 0.55, 0.2)
@export var spawn_count := 8
@export var level_min := 2
@export var level_max := 6
@export var zone_name := "Unknown Zone"

var zone_species: Array[CreatureData] = []
var _canvas_modulate: CanvasModulate
var _quest_panel: Node

@onready var player: CharacterBody2D = $Player
@onready var background: ColorRect = $Background

# Override in subclass to define zone-specific creature pool
func _get_zone_species() -> Array[CreatureData]:
	return []

# Override to define portals: [{pos, target, spawn_offset, label}]
func _get_portals() -> Array[Dictionary]:
	return []

func _ready() -> void:
	GameManager.change_state(GameManager.GameState.OVERWORLD)
	GameManager.set_meta("battle_zone", zone_name)

	zone_species = _get_zone_species()

	if background:
		background.color = bg_color

	# Handle spawn position from portal
	if GameManager.has_meta("zone_spawn_offset"):
		var offset: Vector2 = GameManager.get_meta("zone_spawn_offset")
		player.position = offset
		GameManager.remove_meta("zone_spawn_offset")

	_spawn_wild_creatures()
	_create_portals()
	_setup_day_night()
	_setup_weather()
	_setup_minimap()

	# Track zone visit for stats
	StatsManager.add_zone(zone_name)

func _spawn_wild_creatures() -> void:
	if zone_species.is_empty():
		return
	for i in spawn_count:
		var creature_node: Area2D = WILD_CREATURE_SCENE.instantiate()
		var species_index := randi() % zone_species.size()
		creature_node.creature_data = zone_species[species_index]
		creature_node.level_min = level_min
		creature_node.level_max = level_max
		creature_node.position = Vector2(
			randf_range(-280, 280),
			randf_range(-200, 200)
		)
		if creature_node.position.distance_to(player.position) < 60:
			creature_node.position = Vector2(150, 100)
		add_child(creature_node)

func _create_portals() -> void:
	for portal_data in _get_portals():
		var portal: Area2D = ZONE_PORTAL_SCENE.instantiate()
		portal.position = portal_data["pos"]
		portal.target_zone_path = portal_data["target"]
		portal.spawn_offset = portal_data["spawn_offset"]
		portal.portal_label = portal_data["label"]
		add_child(portal)

func _setup_day_night() -> void:
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.color = TimeManager.get_tint_color()
	add_child(_canvas_modulate)
	TimeManager.phase_changed.connect(_on_time_phase_changed)

func _on_time_phase_changed(_new_phase: int) -> void:
	if _canvas_modulate:
		var tween := create_tween()
		tween.tween_property(_canvas_modulate, "color", TimeManager.get_tint_color(), 2.0)

func _setup_minimap() -> void:
	var minimap_layer := CanvasLayer.new()
	minimap_layer.layer = 90
	add_child(minimap_layer)
	var minimap := preload("res://scripts/ui/minimap.gd").new()
	minimap.setup(self, zone_name)
	minimap_layer.add_child(minimap)

func _setup_weather() -> void:
	var weather := WeatherSystem.get_zone_weather(zone_name)
	if weather != WeatherSystem.WeatherType.CLEAR:
		WeatherSystem.create_weather_particles(self, weather)
		GameManager.set_meta("zone_weather", weather)
	else:
		GameManager.set_meta("zone_weather", WeatherSystem.WeatherType.CLEAR)

func _input(event: InputEvent) -> void:
	if GameManager.state != GameManager.GameState.OVERWORLD:
		return
	if event.is_action_pressed("open_quests") and not _quest_panel:
		_quest_panel = load("res://scripts/ui/quest_panel.gd").new()
		add_child(_quest_panel)
		_quest_panel.closed.connect(func():
			_quest_panel = null
		)
