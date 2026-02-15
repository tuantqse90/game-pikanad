extends Node

## Handles scene transitions (overworld ↔ battle, menus) with fade effects.

signal scene_changed(scene_name: String)

const OVERWORLD_SCENE := "res://scenes/world/overworld.tscn"
const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"
const PVP_BATTLE_SCENE := "res://scenes/battle/pvp_battle_scene.tscn"
const PVP_QUEUE_SCENE := "res://scenes/ui/pvp_queue.tscn"
const MAIN_MENU_SCENE := "res://scenes/main.tscn"
const FADE_DURATION := 0.4

var current_zone_path := ""

var _transition_layer: CanvasLayer
var _fade_rect: ColorRect
var _is_transitioning := false

func _ready() -> void:
	_setup_transition_overlay()

func _setup_transition_overlay() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 100
	add_child(_transition_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_transition_layer.add_child(_fade_rect)

func go_to_overworld() -> void:
	await _fade_transition(func():
		GameManager.change_state(GameManager.GameState.OVERWORLD)
		get_tree().change_scene_to_file(OVERWORLD_SCENE)
		scene_changed.emit("overworld")
	)

func go_to_battle(wild_creature_data: CreatureData, wild_level: int) -> void:
	# Store battle info on GameManager via metadata
	GameManager.set_meta("battle_creature_data", wild_creature_data)
	GameManager.set_meta("battle_creature_level", wild_level)
	await _fade_transition(func():
		GameManager.change_state(GameManager.GameState.BATTLE)
		get_tree().change_scene_to_file(BATTLE_SCENE)
		scene_changed.emit("battle")
	)

func go_to_zone(zone_path: String) -> void:
	current_zone_path = zone_path
	await _fade_transition(func():
		GameManager.change_state(GameManager.GameState.OVERWORLD)
		get_tree().change_scene_to_file(zone_path)
		scene_changed.emit("zone")
	)

func go_to_pvp_queue() -> void:
	await _fade_transition(func():
		GameManager.change_state(GameManager.GameState.PAUSED)
		get_tree().change_scene_to_file(PVP_QUEUE_SCENE)
		scene_changed.emit("pvp_queue")
	)

func go_to_pvp_battle() -> void:
	await _fade_transition(func():
		GameManager.change_state(GameManager.GameState.BATTLE)
		get_tree().change_scene_to_file(PVP_BATTLE_SCENE)
		scene_changed.emit("pvp_battle")
	)

func go_to_main_menu() -> void:
	await _fade_transition(func():
		GameManager.change_state(GameManager.GameState.MENU)
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		scene_changed.emit("main_menu")
	)

func _fade_transition(scene_change_callback: Callable) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	# Fade to black
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished

	# Change scene
	scene_change_callback.call()

	# Wait a frame for the scene to load
	await get_tree().process_frame

	# Fade from black
	var tween2 := create_tween()
	tween2.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
	await tween2.finished

	_is_transitioning = false
