extends Node2D

## PvP Battle scene — wires PvP BattleManager to BattleHUD.
## Same structure as battle_scene.gd but uses server-driven state.

@onready var battle_manager = $PvPBattleManager
@onready var hud = $BattleHUD

func _ready() -> void:
	# Connect manager -> HUD (same signals as regular battle)
	battle_manager.battle_message.connect(hud.show_message)
	battle_manager.player_hp_changed.connect(hud.update_player_hp)
	battle_manager.enemy_hp_changed.connect(hud.update_enemy_hp)
	battle_manager.battle_state_changed.connect(_on_state_changed)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.player_attacked.connect(func(): hud.play_attack_anim(hud.player_sprite); hud.shake_enemy())
	battle_manager.enemy_attacked.connect(func(): hud.play_attack_anim(hud.enemy_sprite); hud.shake_player())
	battle_manager.effectiveness_text.connect(func(text, eff):
		var color := Color.WHITE
		if eff > 1.2: color = Color(1.0, 0.3, 0.1)
		elif eff < 0.8: color = Color(0.5, 0.5, 0.7)
		hud.show_floating_text(text, color)
	)

	# Connect HUD -> manager (only fight, hide catch/run for PvP)
	hud.fight_pressed.connect(battle_manager.player_fight)

	# Connect network signals
	NetworkManager.turn_result.connect(battle_manager.on_turn_result)
	NetworkManager.turn_changed.connect(battle_manager.on_turn_change)
	NetworkManager.battle_ended.connect(battle_manager.on_battle_end)

	# Get battle data from GameManager
	var battle_data: Dictionary = GameManager.get_meta("pvp_battle_data") as Dictionary
	if battle_data:
		battle_manager.start_pvp_battle(battle_data)
		await get_tree().process_frame
		if battle_manager.player_creature and battle_manager.enemy_creature:
			hud.setup(battle_manager.player_creature, battle_manager.enemy_creature)
			# Hide Catch and Run buttons in PvP
			hud.catch_btn.visible = false
			hud.run_btn.visible = false

func _on_state_changed(new_state: int) -> void:
	var is_player_turn = (new_state == battle_manager.BattleState.PLAYER_TURN)
	hud.show_actions(is_player_turn)
	if is_player_turn:
		hud.catch_btn.visible = false
		hud.run_btn.visible = false

func _on_battle_ended(result: String) -> void:
	await get_tree().create_timer(1.0).timeout
	SceneManager.go_to_overworld()
