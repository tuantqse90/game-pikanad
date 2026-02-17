extends CanvasLayer

## Battle HUD — 2x2 action grid, element badges, EXP bar, status colors,
## damage number pop, and trainer party dots.

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

# Item/catch submenus
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

# Sprites
@onready var player_sprite: AnimatedSprite2D = $Root/BattleField/PlayerSprite
@onready var enemy_sprite: AnimatedSprite2D = $Root/BattleField/EnemySprite

# Floating text
@onready var floating_text: Label = $Root/FloatingText

# Original sprite positions for shake effects
var _player_sprite_pos := Vector2.ZERO
var _enemy_sprite_pos := Vector2.ZERO

# Trainer battle state
var _is_trainer_mode := false
var _trainer_party_dots: HBoxContainer

# Speed toggle indicator
var _speed_label: Label

# Screen flash overlay
var _flash_rect: ColorRect

# HP flash state
var _player_hp_low := false
var _enemy_hp_low := false
var _hp_flash_time := 0.0

# Victory/Defeat banner
var _banner_label: Label

# EXP bar
var _exp_bar: ProgressBar

# Element badges
var _player_element_badge: Label
var _enemy_element_badge: Label

func _ready() -> void:
	# Convert action buttons to 2x2 grid
	_setup_action_grid()

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

	# Trainer party dots (hidden by default)
	_trainer_party_dots = HBoxContainer.new()
	_trainer_party_dots.name = "TrainerPartyDots"
	_trainer_party_dots.visible = false
	_trainer_party_dots.add_theme_constant_override("separation", 3)
	$Root/EnemyInfo/VBox.add_child(_trainer_party_dots)

	# Speed toggle indicator
	_speed_label = Label.new()
	_speed_label.name = "SpeedLabel"
	_speed_label.text = "2x [B]"
	_speed_label.visible = false
	_speed_label.add_theme_font_size_override("font_size", 12)
	_speed_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
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

	# EXP bar (thin blue bar below player HP bar)
	_exp_bar = ProgressBar.new()
	_exp_bar.custom_minimum_size = Vector2(0, 4)
	_exp_bar.show_percentage = false
	_exp_bar.max_value = 100
	_exp_bar.value = 0
	var exp_fill := StyleBoxFlat.new()
	exp_fill.bg_color = ThemeManager.COL_ACCENT
	exp_fill.set_corner_radius_all(1)
	exp_fill.content_margin_left = 0.0
	exp_fill.content_margin_right = 0.0
	exp_fill.content_margin_top = 0.0
	exp_fill.content_margin_bottom = 0.0
	_exp_bar.add_theme_stylebox_override("fill", exp_fill)
	var exp_bg := StyleBoxFlat.new()
	exp_bg.bg_color = Color(0.08, 0.06, 0.14)
	exp_bg.set_corner_radius_all(1)
	exp_bg.content_margin_left = 0.0
	exp_bg.content_margin_right = 0.0
	exp_bg.content_margin_top = 0.0
	exp_bg.content_margin_bottom = 0.0
	_exp_bar.add_theme_stylebox_override("background", exp_bg)
	# Insert below HP bar in player info VBox
	var player_vbox := $Root/PlayerInfo/VBox
	var hp_bar_idx := player_hp_bar.get_index()
	player_vbox.add_child(_exp_bar)
	player_vbox.move_child(_exp_bar, hp_bar_idx + 1)

	# Element badges (inserted below name row)
	_player_element_badge = Label.new()
	_player_element_badge.add_theme_font_size_override("font_size", 8)
	player_vbox.add_child(_player_element_badge)
	player_vbox.move_child(_player_element_badge, 1)

	_enemy_element_badge = Label.new()
	_enemy_element_badge.add_theme_font_size_override("font_size", 8)
	$Root/EnemyInfo/VBox.add_child(_enemy_element_badge)
	$Root/EnemyInfo/VBox.move_child(_enemy_element_badge, 1)

func _setup_action_grid() -> void:
	# Replace the VBox action buttons with a 2x2 GridContainer
	# We keep the existing buttons but rearrange them
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)

	# Remove buttons from their parent and add to grid
	var parent := action_buttons
	var btns := [fight_btn, items_btn, catch_btn, run_btn]
	for btn in btns:
		parent.remove_child(btn)

	# Color-code buttons with left border accent
	_style_action_button(fight_btn, "Fight", Color(0.9, 0.3, 0.2))
	_style_action_button(items_btn, "Items", Color(0.3, 0.8, 0.3))
	_style_action_button(catch_btn, "Catch", Color(0.3, 0.5, 0.9))
	_style_action_button(run_btn, "Run", Color(0.7, 0.7, 0.5))

	grid.add_child(fight_btn)
	grid.add_child(items_btn)
	grid.add_child(catch_btn)
	grid.add_child(run_btn)

	parent.add_child(grid)

	# Hover/press animations on action buttons
	for btn in [fight_btn, items_btn, catch_btn, run_btn]:
		ThemeManager.apply_button_hover_anim(btn)

	# Reconnect signals
	fight_btn.pressed.connect(_on_fight_pressed)
	items_btn.pressed.connect(_on_items_pressed)
	catch_btn.pressed.connect(_on_catch_pressed)
	run_btn.pressed.connect(func(): run_pressed.emit())

func _style_action_button(btn: Button, text: String, accent: Color) -> void:
	btn.text = text
	btn.custom_minimum_size = Vector2(65, 28)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.12, 0.24)
	style.set_corner_radius_all(3)
	style.border_width_left = 3
	style.border_color = accent
	style.content_margin_left = 8.0
	style.content_margin_right = 6.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.18, 0.16, 0.3)
	btn.add_theme_stylebox_override("hover", hover)

func setup(player_creature: CreatureInstance, enemy_creature: CreatureInstance) -> void:
	player_name_label.text = player_creature.display_name()
	player_level_label.text = "Lv.%d" % player_creature.level
	enemy_name_label.text = enemy_creature.display_name()
	enemy_level_label.text = "Lv.%d" % enemy_creature.level

	update_player_hp(player_creature.current_hp, player_creature.max_hp())
	update_enemy_hp(enemy_creature.current_hp, enemy_creature.max_hp())

	# Element badges
	_update_element_badge(_player_element_badge, player_creature.data.element)
	_update_element_badge(_enemy_element_badge, enemy_creature.data.element)

	# EXP bar
	update_exp_bar(player_creature)

	# Setup battle sprites with animation
	_setup_battle_sprite(player_sprite, player_creature.data)
	_setup_battle_sprite(enemy_sprite, enemy_creature.data)

	_player_sprite_pos = player_sprite.position
	_enemy_sprite_pos = enemy_sprite.position

	# Entry slide-in animation
	_animate_entry()

	# Shiny sparkle effect
	if enemy_creature.is_shiny:
		_setup_shiny_sparkle(enemy_sprite)
		enemy_name_label.text = "\u2605 " + enemy_name_label.text
	if player_creature.is_shiny:
		_setup_shiny_sparkle(player_sprite)
		player_name_label.text = "\u2605 " + player_name_label.text

	if not _is_trainer_mode:
		_update_ball_count()
	_build_skill_buttons(player_creature)
	_update_status_labels(player_creature, enemy_creature)

func _update_element_badge(badge: Label, element: int) -> void:
	var names := ThemeManager.ELEMENT_NAMES
	badge.text = names[element] if element < names.size() else "???"
	var col: Color = ThemeManager.ELEMENT_COLORS.get(element, Color.GRAY)
	badge.add_theme_color_override("font_color", col)

func update_exp_bar(creature: CreatureInstance) -> void:
	if not _exp_bar:
		return
	var exp_for_next := creature.exp_to_next_level()
	_exp_bar.max_value = exp_for_next if exp_for_next > 0 else 100
	_exp_bar.value = creature.exp

func setup_trainer(trainer_name: String, party_count: int) -> void:
	_is_trainer_mode = true
	enemy_name_label.text = "Leader %s's %s" % [trainer_name, enemy_name_label.text]
	catch_btn.visible = false
	run_btn.visible = false

	# Show trainer party dots
	for child in _trainer_party_dots.get_children():
		child.queue_free()
	for i in party_count:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(6, 6)
		dot.color = ThemeManager.COL_ACCENT_RED if i == 0 else ThemeManager.COL_ACCENT_GREEN
		_trainer_party_dots.add_child(dot)
	_trainer_party_dots.visible = true

func _setup_battle_sprite(sprite: AnimatedSprite2D, data: CreatureData) -> void:
	var tex: Texture2D = data.battle_texture if data.battle_texture else data.sprite_texture
	if not tex:
		return

	var frames := SpriteFrames.new()

	if data.battle_texture:
		var frame_w := 48
		var frame_count := tex.get_width() / frame_w

		frames.add_animation("idle")
		frames.set_animation_speed("idle", 3.0)
		frames.set_animation_loop("idle", true)
		for i in min(2, frame_count):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * frame_w, 0, frame_w, 48)
			frames.add_frame("idle", atlas)

		frames.add_animation("attack")
		frames.set_animation_speed("attack", 8.0)
		frames.set_animation_loop("attack", false)
		for i in range(2, min(4, frame_count)):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * frame_w, 0, frame_w, 48)
			frames.add_frame("attack", atlas)
	else:
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

	# 2x2 grid for skills
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)

	var skills := creature.active_skills if creature.active_skills.size() > 0 else creature.data.skills
	for i in skills.size():
		var skill: SkillData = skills[i] as SkillData
		if not skill:
			continue
		var btn := Button.new()
		# Element dot prefix + name + power + accuracy
		var element_col: Color = ThemeManager.ELEMENT_COLORS.get(skill.element, Color.GRAY)
		btn.text = "\u25cf %s P:%d A:%d%%" % [skill.skill_name, skill.power, int(skill.accuracy * 100)]
		btn.custom_minimum_size = Vector2(130, 26)
		btn.add_theme_font_size_override("font_size", 8)

		# Color-code by category
		match skill.category:
			SkillData.Category.STATUS:
				btn.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
			SkillData.Category.HEAL:
				btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
			_:
				btn.add_theme_color_override("font_color", element_col)

		# Left border color matching element
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.14, 0.12, 0.24)
		style.set_corner_radius_all(3)
		style.border_width_left = 3
		style.border_color = element_col
		style.content_margin_left = 6.0
		style.content_margin_right = 4.0
		style.content_margin_top = 3.0
		style.content_margin_bottom = 3.0
		btn.add_theme_stylebox_override("normal", style)

		var idx := i
		btn.pressed.connect(func(): _on_skill_selected(idx))
		grid.add_child(btn)
		ThemeManager.apply_button_hover_anim(btn)

	skill_buttons.add_child(grid)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(60, 24)
	back_btn.pressed.connect(_on_back_pressed)
	skill_buttons.add_child(back_btn)
	ThemeManager.apply_button_hover_anim(back_btn)

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
	_player_hp_low = float(current) / float(max(1, max_val)) <= 0.25 and current > 0

func update_enemy_hp(current: int, max_val: int) -> void:
	_animate_hp_bar(enemy_hp_bar, current, max_val)
	enemy_hp_label.text = "%d / %d" % [current, max_val]
	_enemy_hp_low = float(current) / float(max(1, max_val)) <= 0.25 and current > 0

func update_status(player_creature: CreatureInstance, enemy_creature: CreatureInstance) -> void:
	_update_status_labels(player_creature, enemy_creature)

func _update_status_labels(player_creature: CreatureInstance, enemy_creature: CreatureInstance) -> void:
	if player_creature and player_creature.status.is_active():
		var status_name := player_creature.status.get_status_name()
		player_status_label.text = "[%s]" % status_name
		player_status_label.add_theme_color_override("font_color", ThemeManager.get_status_color(status_name))
		player_status_label.visible = true
	else:
		player_status_label.text = ""
		player_status_label.visible = false

	if enemy_creature and enemy_creature.status.is_active():
		var status_name := enemy_creature.status.get_status_name()
		enemy_status_label.text = "[%s]" % status_name
		enemy_status_label.add_theme_color_override("font_color", ThemeManager.get_status_color(status_name))
		enemy_status_label.visible = true
	else:
		enemy_status_label.text = ""
		enemy_status_label.visible = false

func _animate_hp_bar(bar: ProgressBar, target: int, max_val: int) -> void:
	bar.max_value = max_val
	var tween := create_tween()
	tween.tween_property(bar, "value", float(target), 0.4).set_ease(Tween.EASE_OUT)

	var ratio := float(target) / float(max_val) if max_val > 0 else 0.0
	var color: Color
	if ratio > 0.5:
		color = ThemeManager.COL_ACCENT_GREEN
	elif ratio > 0.25:
		color = Color(0.9, 0.8, 0.1)
	else:
		color = ThemeManager.COL_ACCENT_RED

	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	bar.add_theme_stylebox_override("fill", style)

func _animate_entry() -> void:
	var player_start := Vector2(_player_sprite_pos.x - 200, _player_sprite_pos.y)
	var enemy_start := Vector2(_enemy_sprite_pos.x + 200, _enemy_sprite_pos.y)
	player_sprite.position = player_start
	enemy_sprite.position = enemy_start
	var tween := create_tween()
	tween.tween_property(enemy_sprite, "position", _enemy_sprite_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(player_sprite, "position", _player_sprite_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func show_damage_number(amount: int, target_pos: Vector2, is_super: bool = false, is_weak: bool = false) -> void:
	var dmg_label := Label.new()
	if amount == 0 and is_super:
		dmg_label.text = "!!"
	elif amount < 0:
		dmg_label.text = "+%d" % abs(amount)  # Heal prefix
	else:
		dmg_label.text = str(amount)

	dmg_label.add_theme_font_size_override("font_size", 16 if is_super else (10 if is_weak else 13))
	if is_super:
		dmg_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_RED)
	elif is_weak:
		dmg_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	elif amount < 0:
		dmg_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GREEN)
	else:
		dmg_label.add_theme_color_override("font_color", Color.WHITE)
	dmg_label.position = target_pos + Vector2(-10, -20)
	$Root.add_child(dmg_label)

	# Scale-up pop tween (1.0 -> 1.3 -> 1.0)
	dmg_label.scale = Vector2(1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(dmg_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(dmg_label, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(dmg_label, "position:y", dmg_label.position.y - 30, 0.5)
	tween.parallel().tween_property(dmg_label, "modulate:a", 0.0, 0.5)
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

func _setup_shiny_sparkle(target_sprite: AnimatedSprite2D) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 6
	particles.lifetime = 1.5
	particles.one_shot = false
	particles.explosiveness = 0.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 20)
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 25.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = Color(1.0, 0.95, 0.3, 0.8)
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(16, 16)
	target_sprite.add_child(particles)

func _process(delta: float) -> void:
	# HP bar low-health flash (red pulse when <=25%)
	_hp_flash_time += delta * 4.0
	if _player_hp_low:
		var pulse := 0.6 + sin(_hp_flash_time) * 0.4
		player_hp_bar.modulate = Color(1.0, pulse, pulse)
	else:
		player_hp_bar.modulate = Color.WHITE
	if _enemy_hp_low:
		var pulse := 0.6 + sin(_hp_flash_time + 1.0) * 0.4
		enemy_hp_bar.modulate = Color(1.0, pulse, pulse)
	else:
		enemy_hp_bar.modulate = Color.WHITE

func show_battle_banner(text: String, color: Color) -> void:
	if _banner_label:
		_banner_label.queue_free()
	_banner_label = Label.new()
	_banner_label.text = text
	_banner_label.add_theme_font_size_override("font_size", 28)
	_banner_label.add_theme_color_override("font_color", color)
	_banner_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_banner_label.add_theme_constant_override("shadow_offset_x", 2)
	_banner_label.add_theme_constant_override("shadow_offset_y", 2)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.anchors_preset = Control.PRESET_CENTER
	_banner_label.anchor_left = 0.5
	_banner_label.anchor_top = 0.5
	_banner_label.anchor_right = 0.5
	_banner_label.anchor_bottom = 0.5
	_banner_label.offset_left = -160
	_banner_label.offset_top = -30
	_banner_label.offset_right = 160
	_banner_label.offset_bottom = 30
	_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root.add_child(_banner_label)
	# Scale-in animation
	_banner_label.pivot_offset = Vector2(160, 30)
	_banner_label.scale = Vector2(0.3, 0.3)
	_banner_label.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_banner_label, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_banner_label, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

func _on_skill_selected(index: int) -> void:
	skill_buttons.visible = false
	fight_pressed.emit(index)

func _on_back_pressed() -> void:
	skill_buttons.visible = false
	action_buttons.visible = true
