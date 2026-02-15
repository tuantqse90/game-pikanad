extends CanvasLayer

## Battle HUD — action menu, HP bars, message log, animated battle sprites.

signal fight_pressed(skill_index: int)
signal catch_pressed
signal run_pressed

# Bottom panel
@onready var message_label: Label = $Root/BottomPanel/MarginContainer/HBox/MessageLabel
@onready var action_buttons: VBoxContainer = $Root/BottomPanel/MarginContainer/HBox/ActionButtons
@onready var skill_buttons: VBoxContainer = $Root/BottomPanel/MarginContainer/HBox/SkillButtons
@onready var fight_btn: Button = $Root/BottomPanel/MarginContainer/HBox/ActionButtons/FightBtn
@onready var catch_btn: Button = $Root/BottomPanel/MarginContainer/HBox/ActionButtons/CatchBtn
@onready var run_btn: Button = $Root/BottomPanel/MarginContainer/HBox/ActionButtons/RunBtn

# Player info
@onready var player_name_label: Label = $Root/PlayerInfo/VBox/TopRow/NameLabel
@onready var player_hp_bar: ProgressBar = $Root/PlayerInfo/VBox/HPBar
@onready var player_hp_label: Label = $Root/PlayerInfo/VBox/HPLabel
@onready var player_level_label: Label = $Root/PlayerInfo/VBox/TopRow/LevelLabel

# Enemy info
@onready var enemy_name_label: Label = $Root/EnemyInfo/VBox/TopRow/NameLabel
@onready var enemy_hp_bar: ProgressBar = $Root/EnemyInfo/VBox/HPBar
@onready var enemy_hp_label: Label = $Root/EnemyInfo/VBox/HPLabel
@onready var enemy_level_label: Label = $Root/EnemyInfo/VBox/TopRow/LevelLabel

# Sprites (now AnimatedSprite2D)
@onready var player_sprite: AnimatedSprite2D = $Root/BattleField/PlayerSprite
@onready var enemy_sprite: AnimatedSprite2D = $Root/BattleField/EnemySprite

# Floating text
@onready var floating_text: Label = $Root/FloatingText

# Original sprite positions for shake effects
var _player_sprite_pos := Vector2.ZERO
var _enemy_sprite_pos := Vector2.ZERO

func _ready() -> void:
	fight_btn.pressed.connect(_on_fight_pressed)
	catch_btn.pressed.connect(func(): catch_pressed.emit())
	run_btn.pressed.connect(func(): run_pressed.emit())
	skill_buttons.visible = false
	floating_text.visible = false

func setup(player_creature: CreatureInstance, enemy_creature: CreatureInstance) -> void:
	player_name_label.text = player_creature.display_name()
	player_level_label.text = "Lv.%d" % player_creature.level
	enemy_name_label.text = enemy_creature.display_name()
	enemy_level_label.text = "Lv.%d" % enemy_creature.level

	update_player_hp(player_creature.current_hp, player_creature.max_hp())
	update_enemy_hp(enemy_creature.current_hp, enemy_creature.max_hp())

	# Setup battle sprites with animation
	_setup_battle_sprite(player_sprite, player_creature.data)
	_setup_battle_sprite(enemy_sprite, enemy_creature.data)

	_player_sprite_pos = player_sprite.position
	_enemy_sprite_pos = enemy_sprite.position

	catch_btn.text = "Catch (%d)" % GameManager.capture_items
	_build_skill_buttons(player_creature)

func _setup_battle_sprite(sprite: AnimatedSprite2D, data: CreatureData) -> void:
	var tex: Texture2D = data.battle_texture if data.battle_texture else data.sprite_texture
	if not tex:
		return

	var frames := SpriteFrames.new()

	if data.battle_texture:
		# Battle sheet: 4 frames of 48x48 (idle0, idle1, attack0, attack1)
		var frame_w := 48
		var frame_count := tex.get_width() / frame_w

		# Idle animation
		frames.add_animation("idle")
		frames.set_animation_speed("idle", 3.0)
		frames.set_animation_loop("idle", true)
		for i in min(2, frame_count):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * frame_w, 0, frame_w, 48)
			frames.add_frame("idle", atlas)

		# Attack animation
		frames.add_animation("attack")
		frames.set_animation_speed("attack", 8.0)
		frames.set_animation_loop("attack", false)
		for i in range(2, min(4, frame_count)):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * frame_w, 0, frame_w, 48)
			frames.add_frame("attack", atlas)
	else:
		# Fallback: single texture
		frames.add_animation("idle")
		frames.add_frame("idle", tex)

	if frames.has_animation("default"):
		frames.remove_animation("default")

	sprite.sprite_frames = frames
	sprite.play("idle")

func play_attack_anim(sprite: AnimatedSprite2D) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		await sprite.animation_finished
		sprite.play("idle")

func shake_sprite(sprite: AnimatedSprite2D, original_pos: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "position", original_pos + Vector2(4, 0), 0.05)
	tween.tween_property(sprite, "position", original_pos + Vector2(-4, 0), 0.05)
	tween.tween_property(sprite, "position", original_pos + Vector2(3, 0), 0.05)
	tween.tween_property(sprite, "position", original_pos + Vector2(-3, 0), 0.05)
	tween.tween_property(sprite, "position", original_pos, 0.05)

func shake_enemy() -> void:
	shake_sprite(enemy_sprite, _enemy_sprite_pos)

func shake_player() -> void:
	shake_sprite(player_sprite, _player_sprite_pos)

func show_floating_text(text: String, color: Color = Color.WHITE) -> void:
	floating_text.text = text
	floating_text.add_theme_color_override("font_color", color)
	floating_text.visible = true
	floating_text.modulate.a = 1.0
	var start_pos := floating_text.position
	var tween := create_tween()
	tween.tween_property(floating_text, "position:y", start_pos.y - 30, 0.8)
	tween.parallel().tween_property(floating_text, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func():
		floating_text.visible = false
		floating_text.position = start_pos
		floating_text.modulate.a = 1.0
	)

func _build_skill_buttons(creature: CreatureInstance) -> void:
	for child in skill_buttons.get_children():
		child.queue_free()

	for i in creature.data.skills.size():
		var skill: SkillData = creature.data.skills[i] as SkillData
		var btn := Button.new()
		btn.text = "%s (Pow:%d)" % [skill.skill_name, skill.power]
		btn.custom_minimum_size = Vector2(0, 28)
		var idx := i
		btn.pressed.connect(func(): _on_skill_selected(idx))
		skill_buttons.add_child(btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 28)
	back_btn.pressed.connect(_on_back_pressed)
	skill_buttons.add_child(back_btn)

func show_message(text: String) -> void:
	message_label.text = text

func show_actions(visible_flag: bool) -> void:
	action_buttons.visible = visible_flag
	if visible_flag:
		skill_buttons.visible = false
		catch_btn.text = "Catch (%d)" % GameManager.capture_items

func update_player_hp(current: int, max_val: int) -> void:
	_animate_hp_bar(player_hp_bar, current, max_val)
	player_hp_label.text = "%d / %d" % [current, max_val]

func update_enemy_hp(current: int, max_val: int) -> void:
	_animate_hp_bar(enemy_hp_bar, current, max_val)
	enemy_hp_label.text = "%d / %d" % [current, max_val]

func _animate_hp_bar(bar: ProgressBar, target: int, max_val: int) -> void:
	bar.max_value = max_val
	var tween := create_tween()
	tween.tween_property(bar, "value", float(target), 0.4).set_ease(Tween.EASE_OUT)

	# Color the bar based on HP ratio
	var ratio := float(target) / float(max_val) if max_val > 0 else 0.0
	var color: Color
	if ratio > 0.5:
		color = Color(0.2, 0.8, 0.2)  # Green
	elif ratio > 0.25:
		color = Color(0.9, 0.8, 0.1)  # Yellow
	else:
		color = Color(0.9, 0.2, 0.1)  # Red

	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", style)

func _on_fight_pressed() -> void:
	action_buttons.visible = false
	skill_buttons.visible = true

func _on_skill_selected(index: int) -> void:
	skill_buttons.visible = false
	fight_pressed.emit(index)

func _on_back_pressed() -> void:
	skill_buttons.visible = false
	action_buttons.visible = true
