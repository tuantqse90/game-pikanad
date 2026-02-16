extends Node2D

## PvP Battle scene — wires PvP BattleManager to BattleHUD.
## Same structure as battle_scene.gd but uses server-driven state.
## Includes gold rewards, ELO update, win/loss stats, and post-battle summary.

@onready var battle_manager = $PvPBattleManager
@onready var hud = $BattleHUD

const PVP_WIN_GOLD := 300
const PVP_LOSE_GOLD := 50

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
	var won := result == "win"

	# Update stats
	if won:
		StatsManager.increment("pvp_wins")
		QuestManager.increment_quest("win_pvp")
		AudioManager.play_sound(AudioManager.SFX.PVP_WIN)
	else:
		StatsManager.increment("pvp_losses")
		AudioManager.play_sound(AudioManager.SFX.PVP_LOSE)

	# Update ELO
	StatsManager.update_elo(won)

	# Gold reward
	var gold_reward := PVP_WIN_GOLD if won else PVP_LOSE_GOLD
	if InventoryManager:
		InventoryManager.add_gold(gold_reward)

	# Show post-battle summary
	_show_summary(won, gold_reward)

func _show_summary(won: bool, gold: int) -> void:
	var summary_layer := CanvasLayer.new()
	summary_layer.layer = 60
	add_child(summary_layer)

	# Dark backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.75)
	backdrop.anchors_preset = Control.PRESET_FULL_RECT
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	summary_layer.add_child(backdrop)

	# Summary panel
	var panel := PanelContainer.new()
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -140
	panel.offset_top = -100
	panel.offset_right = 140
	panel.offset_bottom = 100
	summary_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Result title
	var title := Label.new()
	title.text = "VICTORY!" if won else "DEFEAT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	if won:
		title.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	else:
		title.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_RED)
	vbox.add_child(title)

	# Gold reward
	var gold_label := Label.new()
	gold_label.text = "+%d Gold" % gold
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 12)
	gold_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	vbox.add_child(gold_label)

	# ELO
	var elo_label := Label.new()
	elo_label.text = "ELO: %d" % StatsManager.elo_rating
	elo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elo_label.add_theme_font_size_override("font_size", 11)
	elo_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT)
	vbox.add_child(elo_label)

	# Record
	var record_label := Label.new()
	record_label.text = "Record: %dW / %dL" % [StatsManager.pvp_wins, StatsManager.pvp_losses]
	record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record_label.add_theme_font_size_override("font_size", 10)
	record_label.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	vbox.add_child(record_label)

	# Continue button
	var continue_btn := Button.new()
	continue_btn.text = "Continue"
	continue_btn.custom_minimum_size = Vector2(100, 30)
	continue_btn.pressed.connect(func():
		SceneManager.go_to_overworld()
	)
	vbox.add_child(continue_btn)
	continue_btn.grab_focus()
