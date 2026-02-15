extends Node2D

## Battle scene — wires BattleManager signals to BattleHUD.

@onready var battle_manager: Node = $BattleManager
@onready var hud = $BattleHUD

var _evolution_screen: Node
var _skill_dialog: Node

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

	# Connect status signals
	battle_manager.status_inflicted.connect(_on_status_changed)
	battle_manager.status_expired.connect(_on_status_changed)

	# Connect evolution + skill learning
	battle_manager.evolution_ready.connect(_on_evolution_ready)
	battle_manager.skill_learned.connect(_on_skill_learned)

	# Connect trainer signals
	battle_manager.trainer_defeated.connect(_on_trainer_defeated)
	battle_manager.trainer_creature_switched.connect(_on_trainer_creature_switched)

	# Connect speed toggle
	battle_manager.speed_changed.connect(_on_speed_changed)

	# Set zone-specific background color
	_apply_zone_background()

	# Connect HUD -> manager
	hud.fight_pressed.connect(battle_manager.player_fight)
	hud.catch_pressed.connect(battle_manager.player_catch)
	hud.run_pressed.connect(battle_manager.player_run)
	hud.item_pressed.connect(battle_manager.player_use_item)

	# Play battle music
	if battle_manager.is_trainer_battle and battle_manager.trainer_data:
		if battle_manager.trainer_data.trainer_name == "Champion":
			AudioManager.play_track(AudioManager.MusicTrack.CHAMPION)
		else:
			AudioManager.play_track(AudioManager.MusicTrack.TRAINER_BATTLE)
	else:
		AudioManager.play_track(AudioManager.MusicTrack.BATTLE)

	# Start the battle
	battle_manager.start_battle()

	# Setup HUD display after a frame so creatures are initialized
	await get_tree().process_frame
	if battle_manager.player_creature and battle_manager.enemy_creature:
		hud.setup(battle_manager.player_creature, battle_manager.enemy_creature)
		# Setup trainer HUD mode
		if battle_manager.is_trainer_battle and battle_manager.trainer_data:
			var party_size := battle_manager.trainer_data.party.size()
			hud.setup_trainer(battle_manager.trainer_data.trainer_name, party_size)

func _on_state_changed(new_state: int) -> void:
	# Show action buttons only during PLAYER_TURN
	var is_player_turn = (new_state == battle_manager.BattleState.PLAYER_TURN)
	hud.show_actions(is_player_turn)
	# Update status labels
	if battle_manager.player_creature and battle_manager.enemy_creature:
		hud.update_status(battle_manager.player_creature, battle_manager.enemy_creature)

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
		hud.flash_screen(Color(1.0, 0.5, 0.1), 0.2)
		hud.show_damage_number(0, hud.enemy_sprite.position, true, false)
	elif effectiveness < 0.8:
		color = Color(0.5, 0.5, 0.7)  # Muted blue for not very effective
	hud.show_floating_text(text, color)

func _on_speed_changed(speed: float) -> void:
	hud.set_speed_indicator(speed > 1.0)

func _apply_zone_background() -> void:
	var bg: ColorRect = $Background if has_node("Background") else null
	if not bg:
		return
	var zone_name := ""
	if GameManager.has_meta("battle_zone"):
		zone_name = GameManager.get_meta("battle_zone")
	var zone_colors := {
		"Starter Meadow": Color(0.25, 0.55, 0.2),
		"Fire Volcano": Color(0.45, 0.15, 0.1),
		"Lava Core": Color(0.5, 0.12, 0.08),
		"Water Coast": Color(0.15, 0.3, 0.55),
		"Forest Grove": Color(0.12, 0.35, 0.12),
		"Earth Caves": Color(0.35, 0.25, 0.15),
		"Sky Peaks": Color(0.5, 0.65, 0.85),
		"Champion Arena": Color(0.3, 0.15, 0.45),
	}
	if zone_colors.has(zone_name):
		bg.color = zone_colors[zone_name]

func _on_status_changed(_target_name: String, _status_name: String) -> void:
	if battle_manager.player_creature and battle_manager.enemy_creature:
		hud.update_status(battle_manager.player_creature, battle_manager.enemy_creature)

func _on_evolution_ready(creature: CreatureInstance) -> void:
	# Load and show evolution screen
	var evo_scene := load("res://scenes/ui/evolution_screen.tscn")
	_evolution_screen = evo_scene.instantiate()
	add_child(_evolution_screen)
	_evolution_screen.show_evolution(creature)
	_evolution_screen.evolution_confirmed.connect(_on_evolution_done)
	_evolution_screen.evolution_cancelled.connect(_on_evolution_done)

func _on_evolution_done() -> void:
	if _evolution_screen:
		_evolution_screen.queue_free()
		_evolution_screen = null
	# Update HUD with potentially new creature data
	if battle_manager.player_creature:
		hud.setup(battle_manager.player_creature, battle_manager.enemy_creature)
	await get_tree().create_timer(1.0).timeout
	battle_manager.finish_battle_after_evolution()

func _on_skill_learned(creature: CreatureInstance, skill: Resource) -> void:
	# If creature has 4 skills, show replacement dialog
	if creature.active_skills.size() >= 4:
		var dialog_scene := load("res://scenes/ui/skill_replace_dialog.tscn")
		_skill_dialog = dialog_scene.instantiate()
		add_child(_skill_dialog)
		_skill_dialog.show_dialog(creature, skill)
		_skill_dialog.skill_replaced.connect(func(_idx): _on_skill_dialog_closed())
		_skill_dialog.skill_cancelled.connect(_on_skill_dialog_closed)

func _on_skill_dialog_closed() -> void:
	if _skill_dialog:
		_skill_dialog.queue_free()
		_skill_dialog = null
	# Rebuild skill buttons with new skills
	if battle_manager.player_creature:
		hud._build_skill_buttons(battle_manager.player_creature)

func _on_trainer_defeated(_trainer: TrainerData) -> void:
	# Auto-save after trainer victory
	if SaveManager:
		SaveManager.save_game()

func _on_trainer_creature_switched(new_creature: CreatureInstance, remaining: int) -> void:
	# Update HUD for new enemy creature
	if battle_manager.player_creature:
		hud.setup(battle_manager.player_creature, new_creature)
		if battle_manager.is_trainer_battle and battle_manager.trainer_data:
			hud.setup_trainer(battle_manager.trainer_data.trainer_name, remaining)

func _on_battle_ended(result: String) -> void:
	if result == "win" or result == "capture":
		AudioManager.play_track(AudioManager.MusicTrack.VICTORY)
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
