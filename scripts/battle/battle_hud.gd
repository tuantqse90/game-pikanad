extends CanvasLayer

## Battle HUD — action menu, HP bars, message log, animated battle sprites.

signal fight_pressed(skill_index: int)
signal catch_pressed(ball_name: String)
signal run_pressed
signal item_pressed(item_name: String)

# Bottom panel
@onready var message_label: Label = $Root/BottomPanel/MarginContainer/HBox/MessageLabel
@onready var action_buttons: VBoxContainer = $Root/BottomPanel/MarginContainer/HBox/ActionButtons
@onready var skill_buttons: VBoxContainer = $Root/BottomPanel/MarginContainer/HBox/SkillButtons
@onready var fight_btn: Button = $Root/BottomPanel/MarginContainer/HBox/ActionButtons/FightBtn
@onready var items_btn: Button = $Root/BottomPanel/MarginContainer/HBox/ActionButtons/ItemsBtn
@onready var catch_btn: Button = $Root/BottomPanel/MarginContainer/HBox/ActionButtons/CatchBtn
@onready var run_btn: Button = $Root/BottomPanel/MarginContainer/HBox/ActionButtons/RunBtn

# Item/catch submenus (dynamically created containers)
var _item_menu: VBoxContainer
var _catch_menu: VBoxContainer

# Player info
@onready var player_name_label: Label = $Root/PlayerInfo/VBox/TopRow/NameLabel
@onready var player_hp_bar: ProgressBar = $Root/PlayerInfo/VBox/HPBar
@onready var player_hp_label: Label = $Root/PlayerInfo/VBox/HPLabel
@onready var player_level_label: Label = $Root/PlayerInfo/VBox/TopRow/LevelLabel
@onready var player_status_label: Label = $Root/PlayerInfo/VBox/StatusLabel

# Enemy info
@onready var enemy_name_label: Label = $Root/EnemyInfo/VBox/TopRow/NameLabel
@onready var enemy_hp_bar: ProgressBar = $Root/EnemyInfo/VBox/HPBar
@onready var enemy_hp_label: Label = $Root/EnemyInfo/VBox/HPLabel
@onready var enemy_level_label: Label = $Root/EnemyInfo/VBox/TopRow/LevelLabel
@onready var enemy_status_label: Label = $Root/EnemyInfo/VBox/StatusLabel

# Sprites (now AnimatedSprite2D)
@onready var player_sprite: AnimatedSprite2D = $Root/BattleField/PlayerSprite
@onready var enemy_sprite: AnimatedSprite2D = $Root/BattleField/EnemySprite

# Floating text
@onready var floating_text: Label = $Root/FloatingText

# Original sprite positions for shake effects
var _player_sprite_pos := Vector2.ZERO
var _enemy_sprite_pos := Vector2.ZERO

# Trainer battle state
var _is_trainer_mode := false
var _trainer_party_label: Label

# Speed toggle indicator
var _speed_label: Label

# Screen flash overlay
var _flash_rect: ColorRect

func _ready() -> void:
	fight_btn.pressed.connect(_on_fight_pressed)
	items_btn.pressed.connect(_on_items_pressed)
	catch_btn.pressed.connect(_on_catch_pressed)
	run_btn.pressed.connect(func(): run_pressed.emit())
	skill_buttons.visible = false
	floating_text.visible = false

	# Create submenu containers
	_item_menu = VBoxContainer.new()
	_item_menu.name = "ItemMenu"
	_item_menu.visible = false
	_item_menu.custom_minimum_size = Vector2(140, 0)
	$Root/BottomPanel/MarginContainer/HBox.add_child(_item_menu)

	_catch_menu = VBoxContainer.new()
	_catch_menu.name = "CatchMenu"
	_catch_menu.visible = false
	_catch_menu.custom_minimum_size = Vector2(140, 0)
	$Root/BottomPanel/MarginContainer/HBox.add_child(_catch_menu)

	# Create trainer party count label (hidden by default)
	_trainer_party_label = Label.new()
	_trainer_party_label.name = "TrainerPartyLabel"
	_trainer_party_label.visible = false
	_trainer_party_label.add_theme_font_size_override("font_size", 10)
	$Root/EnemyInfo/VBox.add_child(_trainer_party_label)

	# Speed toggle indicator
	_speed_label = Label.new()
	_speed_label.name = "SpeedLabel"
	_speed_label.text = "2x [B]"
	_speed_label.visible = false
	_speed_label.add_theme_font_size_override("font_size", 12)
	_speed_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	_speed_label.position = Vector2(580, 4)
	$Root.add_child(_speed_label)

	# Screen flash overlay
	_flash_rect = ColorRect.new()
	_flash_rect.name = "FlashRect"
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.anchors_preset = Control.PRESET_FULL_RECT
	_flash_rect.anchor_right = 1.0
	_flash_rect.anchor_bottom = 1.0
	$Root.add_child(_flash_rect)

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

	# Entry slide-in animation
	_animate_entry()

	if not _is_trainer_mode:
		_update_ball_count()
	_build_skill_buttons(player_creature)
	_update_status_labels(player_creature, enemy_creature)

func setup_trainer(trainer_name: String, party_count: int) -> void:
	_is_trainer_mode = true
	# Show trainer name prefix
	enemy_name_label.text = "Leader %s's %s" % [trainer_name, enemy_name_label.text]
	# Hide Catch and Run buttons
	catch_btn.visible = false
	run_btn.visible = false
	# Show party count
	_trainer_party_label.text = "Party: %d remaining" % party_count
	_trainer_party_label.visible = true

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

	var skills := creature.active_skills if creature.active_skills.size() > 0 else creature.data.skills
	for i in skills.size():
		var skill: SkillData = skills[i] as SkillData
		if not skill:
			continue
		var btn := Button.new()
		btn.text = "%s (Pow:%d)" % [skill.skill_name, skill.power]
		btn.custom_minimum_size = Vector2(0, 28)
		# Color-code by category
		match skill.category:
			SkillData.Category.STATUS:
				btn.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
			SkillData.Category.HEAL:
				btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
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
		_item_menu.visible = false
		_catch_menu.visible = false
		if not _is_trainer_mode:
			_update_ball_count()

func _update_ball_count() -> void:
	var total_balls := InventoryManager.get_total_ball_count() if InventoryManager else 0
	catch_btn.text = "Catch (%d)" % total_balls

func update_player_hp(current: int, max_val: int) -> void:
	_animate_hp_bar(player_hp_bar, current, max_val)
	player_hp_label.text = "%d / %d" % [current, max_val]

func update_enemy_hp(current: int, max_val: int) -> void:
	_animate_hp_bar(enemy_hp_bar, current, max_val)
	enemy_hp_label.text = "%d / %d" % [current, max_val]

func update_status(player_creature: CreatureInstance, enemy_creature: CreatureInstance) -> void:
	_update_status_labels(player_creature, enemy_creature)

func _update_status_labels(player_creature: CreatureInstance, enemy_creature: CreatureInstance) -> void:
	if player_creature and player_creature.status.is_active():
		player_status_label.text = "[%s]" % player_creature.status.get_status_name()
		player_status_label.visible = true
	else:
		player_status_label.text = ""
		player_status_label.visible = false

	if enemy_creature and enemy_creature.status.is_active():
		enemy_status_label.text = "[%s]" % enemy_creature.status.get_status_name()
		enemy_status_label.visible = true
	else:
		enemy_status_label.text = ""
		enemy_status_label.visible = false

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

func _animate_entry() -> void:
	# Slide sprites in from off-screen
	var player_start := Vector2(_player_sprite_pos.x - 200, _player_sprite_pos.y)
	var enemy_start := Vector2(_enemy_sprite_pos.x + 200, _enemy_sprite_pos.y)
	player_sprite.position = player_start
	enemy_sprite.position = enemy_start
	var tween := create_tween()
	tween.tween_property(enemy_sprite, "position", _enemy_sprite_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(player_sprite, "position", _player_sprite_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func show_damage_number(amount: int, target_pos: Vector2, is_super: bool = false, is_weak: bool = false) -> void:
	var dmg_label := Label.new()
	dmg_label.text = str(amount)
	dmg_label.add_theme_font_size_override("font_size", 16 if is_super else (10 if is_weak else 13))
	if is_super:
		dmg_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))
	elif is_weak:
		dmg_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	else:
		dmg_label.add_theme_color_override("font_color", Color.WHITE)
	dmg_label.position = target_pos + Vector2(-10, -20)
	$Root.add_child(dmg_label)
	var tween := create_tween()
	tween.tween_property(dmg_label, "position:y", dmg_label.position.y - 30, 0.6)
	tween.parallel().tween_property(dmg_label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): dmg_label.queue_free())

func flash_screen(color: Color = Color.WHITE, duration: float = 0.15) -> void:
	_flash_rect.color = Color(color.r, color.g, color.b, 0.6)
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 0.0, duration)

func set_speed_indicator(fast: bool) -> void:
	_speed_label.visible = fast

func _on_fight_pressed() -> void:
	action_buttons.visible = false
	skill_buttons.visible = true

func _on_items_pressed() -> void:
	action_buttons.visible = false
	_build_item_menu()
	_item_menu.visible = true

func _on_catch_pressed() -> void:
	action_buttons.visible = false
	_build_catch_menu()
	_catch_menu.visible = true

func _build_item_menu() -> void:
	for child in _item_menu.get_children():
		child.queue_free()

	var usable := InventoryManager.get_usable_battle_items() if InventoryManager else []
	if usable.is_empty():
		var lbl := Label.new()
		lbl.text = "No items!"
		_item_menu.add_child(lbl)
	else:
		for entry in usable:
			var btn := Button.new()
			btn.text = "%s x%d" % [entry["name"], entry["count"]]
			btn.custom_minimum_size = Vector2(0, 28)
			var item_name: String = entry["name"]
			btn.pressed.connect(func():
				_item_menu.visible = false
				item_pressed.emit(item_name)
			)
			_item_menu.add_child(btn)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 28)
	back.pressed.connect(func():
		_item_menu.visible = false
		action_buttons.visible = true
	)
	_item_menu.add_child(back)

func _build_catch_menu() -> void:
	for child in _catch_menu.get_children():
		child.queue_free()

	var balls := InventoryManager.get_capture_balls() if InventoryManager else []
	if balls.is_empty():
		var lbl := Label.new()
		lbl.text = "No balls!"
		_catch_menu.add_child(lbl)
	else:
		for entry in balls:
			var btn := Button.new()
			btn.text = "%s x%d" % [entry["name"], entry["count"]]
			btn.custom_minimum_size = Vector2(0, 28)
			var ball_name: String = entry["name"]
			btn.pressed.connect(func():
				_catch_menu.visible = false
				catch_pressed.emit(ball_name)
			)
			_catch_menu.add_child(btn)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 28)
	back.pressed.connect(func():
		_catch_menu.visible = false
		action_buttons.visible = true
	)
	_catch_menu.add_child(back)

func _on_skill_selected(index: int) -> void:
	skill_buttons.visible = false
	fight_pressed.emit(index)

func _on_back_pressed() -> void:
	skill_buttons.visible = false
	action_buttons.visible = true
