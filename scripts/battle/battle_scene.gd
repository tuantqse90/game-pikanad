extends Node2D

## Battle scene — wires BattleManager signals to BattleHUD.

@onready var battle_manager: Node = $BattleManager
@onready var hud = $BattleHUD

func _ready() -> void:
	# Connect manager -> HUD
	battle_manager.battle_message.connect(hud.show_message)
	battle_manager.player_hp_changed.connect(hud.update_player_hp)
	battle_manager.enemy_hp_changed.connect(hud.update_enemy_hp)
	battle_manager.battle_state_changed.connect(_on_state_changed)
	battle_manager.battle_ended.connect(_on_battle_ended)

	# Connect attack effects
	battle_manager.player_attacked.connect(_on_player_attacked)
	battle_manager.enemy_attacked.connect(_on_enemy_attacked)
	battle_manager.effectiveness_text.connect(_on_effectiveness_text)

	# Connect HUD -> manager
	hud.fight_pressed.connect(battle_manager.player_fight)
	hud.catch_pressed.connect(battle_manager.player_catch)
	hud.run_pressed.connect(battle_manager.player_run)

	# Start the battle
	battle_manager.start_battle()

	# Setup HUD display after a frame so creatures are initialized
	await get_tree().process_frame
	if battle_manager.player_creature and battle_manager.enemy_creature:
		hud.setup(battle_manager.player_creature, battle_manager.enemy_creature)

func _on_state_changed(new_state: int) -> void:
	# Show action buttons only during PLAYER_TURN
	var is_player_turn = (new_state == battle_manager.BattleState.PLAYER_TURN)
	hud.show_actions(is_player_turn)

func _on_player_attacked() -> void:
	hud.play_attack_anim(hud.player_sprite)
	hud.shake_enemy()

func _on_enemy_attacked() -> void:
	hud.play_attack_anim(hud.enemy_sprite)
	hud.shake_player()

func _on_effectiveness_text(text: String, effectiveness: float) -> void:
	var color := Color.WHITE
	if effectiveness > 1.2:
		color = Color(1.0, 0.3, 0.1)  # Red-orange for super effective
	elif effectiveness < 0.8:
		color = Color(0.5, 0.5, 0.7)  # Muted blue for not very effective
	hud.show_floating_text(text, color)

func _on_battle_ended(result: String) -> void:
	match result:
		"lose":
			# Heal party and return to menu on loss
			PartyManager.heal_all()
			await get_tree().create_timer(1.0).timeout
			SceneManager.go_to_main_menu()
		_:
			# Win, capture, run -> return to overworld
			await get_tree().create_timer(0.5).timeout
			SceneManager.go_to_overworld()
