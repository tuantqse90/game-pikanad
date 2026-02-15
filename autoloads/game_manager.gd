extends Node

## Global game state singleton.

enum GameState { MENU, OVERWORLD, BATTLE, PAUSED }

var state: GameState = GameState.MENU
var capture_items: int = 5  # DEPRECATED — kept for save migration only

func _ready() -> void:
	_setup_input_actions()
	# Migrate starting capture balls to inventory
	_migrate_starting_balls()

func _setup_input_actions() -> void:
	_add_key_action("move_up", KEY_W, KEY_UP)
	_add_key_action("move_down", KEY_S, KEY_DOWN)
	_add_key_action("move_left", KEY_A, KEY_LEFT)
	_add_key_action("move_right", KEY_D, KEY_RIGHT)
	_add_key_action("ui_accept", KEY_ENTER, KEY_SPACE)
	_add_key_action("ui_cancel", KEY_ESCAPE)
	_add_key_action("open_menu", KEY_TAB)
	_add_key_action("run", KEY_SHIFT)
	_add_key_action("toggle_battle_speed", KEY_B)
	_add_key_action("open_dex", KEY_X)

func _add_key_action(action_name: String, key1: Key, key2: Key = KEY_NONE) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev1 := InputEventKey.new()
	ev1.keycode = key1
	if not InputMap.action_has_event(action_name, ev1):
		InputMap.action_add_event(action_name, ev1)
	if key2 != KEY_NONE:
		var ev2 := InputEventKey.new()
		ev2.keycode = key2
		if not InputMap.action_has_event(action_name, ev2):
			InputMap.action_add_event(action_name, ev2)

func change_state(new_state: GameState) -> void:
	state = new_state

func _migrate_starting_balls() -> void:
	# On new game, give starting capture balls via inventory instead
	if capture_items > 0 and InventoryManager:
		InventoryManager.add_item("Capture Ball", capture_items)
		capture_items = 0
