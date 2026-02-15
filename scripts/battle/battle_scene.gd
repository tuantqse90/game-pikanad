extends Node2D

## Battle scene — wires BattleManager signals to BattleHUD.
## Features two-layer backgrounds with zone-specific decorations.

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

	# Connect EXP gain
	battle_manager.exp_gained.connect(_on_exp_gained)

	# Set zone-specific two-layer background
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
		if battle_manager.is_trainer_battle and battle_manager.trainer_data:
			var party_size := battle_manager.trainer_data.party.size()
			hud.setup_trainer(battle_manager.trainer_data.trainer_name, party_size)

	# Tutorial: first battle
	if TutorialManager and not TutorialManager.is_completed("first_battle"):
		await get_tree().create_timer(2.0).timeout
		TutorialManager.show_tutorial("first_battle")

func _on_state_changed(new_state: int) -> void:
	var is_player_turn = (new_state == battle_manager.BattleState.PLAYER_TURN)
	hud.show_actions(is_player_turn)
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
		color = Color(1.0, 0.3, 0.1)
		hud.flash_screen(Color(1.0, 0.5, 0.1), 0.2)
		hud.show_damage_number(0, hud.enemy_sprite.position, true, false)
	elif effectiveness < 0.8:
		color = Color(0.5, 0.5, 0.7)
	hud.show_floating_text(text, color)

func _on_speed_changed(speed: float) -> void:
	hud.set_speed_indicator(speed > 1.0)

func _on_exp_gained(amount: int, _leveled_up: bool) -> void:
	if battle_manager.player_creature:
		hud.update_exp_bar(battle_manager.player_creature)

func _apply_zone_background() -> void:
	var bg: ColorRect = $Background if has_node("Background") else null
	if not bg:
		return
	var zone_name := ""
	if GameManager.has_meta("battle_zone"):
		zone_name = GameManager.get_meta("battle_zone")

	# Two-layer background: sky top 60% + ground bottom 40%
	var zone_themes := {
		"Starter Meadow": {"sky": Color(0.45, 0.7, 0.9), "ground": Color(0.25, 0.55, 0.2), "horizon": Color(0.35, 0.6, 0.4)},
		"Fire Volcano":   {"sky": Color(0.35, 0.12, 0.08), "ground": Color(0.45, 0.15, 0.1), "horizon": Color(0.55, 0.2, 0.1)},
		"Lava Core":      {"sky": Color(0.25, 0.06, 0.04), "ground": Color(0.5, 0.12, 0.08), "horizon": Color(0.6, 0.15, 0.05)},
		"Water Coast":    {"sky": Color(0.35, 0.55, 0.8), "ground": Color(0.15, 0.3, 0.55), "horizon": Color(0.25, 0.45, 0.7)},
		"Forest Grove":   {"sky": Color(0.2, 0.4, 0.25), "ground": Color(0.12, 0.35, 0.12), "horizon": Color(0.15, 0.38, 0.18)},
		"Earth Caves":    {"sky": Color(0.2, 0.15, 0.1), "ground": Color(0.35, 0.25, 0.15), "horizon": Color(0.28, 0.2, 0.12)},
		"Sky Peaks":      {"sky": Color(0.6, 0.75, 0.95), "ground": Color(0.7, 0.75, 0.85), "horizon": Color(0.65, 0.7, 0.9)},
		"Champion Arena": {"sky": Color(0.15, 0.08, 0.3), "ground": Color(0.3, 0.15, 0.45), "horizon": Color(0.22, 0.12, 0.38)},
	}

	var theme_data: Dictionary = zone_themes.get(zone_name, {"sky": Color(0.3, 0.5, 0.3), "ground": Color(0.2, 0.4, 0.2), "horizon": Color(0.25, 0.45, 0.25)})

	# Sky (top 60%)
	bg.color = theme_data["sky"]

	# Ground layer (bottom 40%)
	var ground := ColorRect.new()
	ground.color = theme_data["ground"]
	ground.anchors_preset = Control.PRESET_FULL_RECT
	ground.anchor_right = 1.0
	ground.anchor_bottom = 1.0
	ground.anchor_top = 0.6
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(ground)

	# Horizon line
	var horizon := ColorRect.new()
	horizon.color = theme_data["horizon"]
	horizon.anchors_preset = Control.PRESET_TOP_WIDE
	horizon.anchor_right = 1.0
	horizon.offset_top = bg.size.y * 0.58
	horizon.offset_bottom = bg.size.y * 0.62
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(horizon)

	# Zone-specific decorations
	_add_zone_decorations(bg, zone_name)

func _add_zone_decorations(bg: ColorRect, zone_name: String) -> void:
	match zone_name:
		"Starter Meadow":
			# Green grass tufts on ground
			for i in 8:
				var tuft := ColorRect.new()
				tuft.color = Color(0.2, 0.6, 0.15, 0.4)
				tuft.size = Vector2(randf_range(10, 25), randf_range(3, 6))
				tuft.position = Vector2(randf_range(20, 600), randf_range(220, 340))
				tuft.mouse_filter = Control.MOUSE_FILTER_IGNORE
				bg.add_child(tuft)
		"Fire Volcano", "Lava Core":
			# Ember particles rising from bottom
			var embers := CPUParticles2D.new()
			embers.emitting = true
			embers.amount = 12
			embers.lifetime = 2.5
			embers.direction = Vector2(0, -1)
			embers.spread = 30.0
			embers.gravity = Vector2(0, -30)
			embers.initial_velocity_min = 15.0
			embers.initial_velocity_max = 40.0
			embers.scale_amount_min = 0.5
			embers.scale_amount_max = 1.5
			embers.color = Color(1.0, 0.4, 0.1, 0.6)
			embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			embers.emission_rect_extents = Vector2(300, 10)
			embers.position = Vector2(320, 350)
			# Add to a Node2D wrapper since bg is ColorRect
			var holder := Node2D.new()
			bg.add_child(holder)
			holder.add_child(embers)
		"Water Coast":
			# Blue wave lines on ground
			for i in 4:
				var wave := ColorRect.new()
				wave.color = Color(0.3, 0.55, 0.9, 0.25)
				wave.size = Vector2(randf_range(80, 160), 2)
				wave.position = Vector2(randf_range(20, 400), 240 + i * 25)
				wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
				bg.add_child(wave)
		"Forest Grove":
			# Dark tree silhouettes at edges
			for side in [30, 560]:
				var tree := ColorRect.new()
				tree.color = Color(0.06, 0.18, 0.06, 0.5)
				tree.size = Vector2(40, 120)
				tree.position = Vector2(side, 100)
				tree.mouse_filter = Control.MOUSE_FILTER_IGNORE
				bg.add_child(tree)
		"Earth Caves":
			# Stalactite rects from top
			for i in 6:
				var stalactite := ColorRect.new()
				stalactite.color = Color(0.25, 0.18, 0.1, 0.6)
				stalactite.size = Vector2(randf_range(6, 14), randf_range(20, 50))
				stalactite.position = Vector2(randf_range(40, 580), 0)
				stalactite.mouse_filter = Control.MOUSE_FILTER_IGNORE
				bg.add_child(stalactite)
		"Sky Peaks":
			# Snow/mist particles
			var snow := CPUParticles2D.new()
			snow.emitting = true
			snow.amount = 15
			snow.lifetime = 3.0
			snow.direction = Vector2(0.3, 1)
			snow.spread = 20.0
			snow.gravity = Vector2(0, 15)
			snow.initial_velocity_min = 5.0
			snow.initial_velocity_max = 15.0
			snow.scale_amount_min = 0.5
			snow.scale_amount_max = 1.0
			snow.color = Color(0.9, 0.92, 1.0, 0.4)
			snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			snow.emission_rect_extents = Vector2(320, 5)
			snow.position = Vector2(320, 0)
			var holder := Node2D.new()
			bg.add_child(holder)
			holder.add_child(snow)
		"Champion Arena":
			# Purple/gold decorative lines
			for i in 3:
				var line := ColorRect.new()
				line.color = Color(0.6, 0.45, 0.15, 0.3)
				line.size = Vector2(640, 1)
				line.position = Vector2(0, 80 + i * 60)
				line.mouse_filter = Control.MOUSE_FILTER_IGNORE
				bg.add_child(line)
			for i in 3:
				var line := ColorRect.new()
				line.color = Color(0.4, 0.2, 0.6, 0.2)
				line.size = Vector2(1, 360)
				line.position = Vector2(100 + i * 180, 0)
				line.mouse_filter = Control.MOUSE_FILTER_IGNORE
				bg.add_child(line)

func _on_status_changed(_target_name: String, _status_name: String) -> void:
	if battle_manager.player_creature and battle_manager.enemy_creature:
		hud.update_status(battle_manager.player_creature, battle_manager.enemy_creature)

func _on_evolution_ready(creature: CreatureInstance) -> void:
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
	if battle_manager.player_creature:
		hud.setup(battle_manager.player_creature, battle_manager.enemy_creature)
	await get_tree().create_timer(1.0).timeout
	battle_manager.finish_battle_after_evolution()

func _on_skill_learned(creature: CreatureInstance, skill: Resource) -> void:
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
	if battle_manager.player_creature:
		hud._build_skill_buttons(battle_manager.player_creature)

func _on_trainer_defeated(_trainer: TrainerData) -> void:
	if SaveManager:
		SaveManager.save_game()

func _on_trainer_creature_switched(new_creature: CreatureInstance, remaining: int) -> void:
	if battle_manager.player_creature:
		hud.setup(battle_manager.player_creature, new_creature)
		if battle_manager.is_trainer_battle and battle_manager.trainer_data:
			hud.setup_trainer(battle_manager.trainer_data.trainer_name, remaining)

func _on_battle_ended(result: String) -> void:
	if result == "win" or result == "capture":
		AudioManager.play_track(AudioManager.MusicTrack.VICTORY)
	match result:
		"lose":
			PartyManager.heal_all()
			await get_tree().create_timer(1.0).timeout
			SceneManager.go_to_main_menu()
		_:
			await get_tree().create_timer(0.5).timeout
			SceneManager.go_to_overworld()
