extends Control

## Main menu scene with floating particles, creature showcase, and styled buttons.

@onready var start_btn: Button = $CenterContainer/VBoxContainer/StartBtn
@onready var continue_btn: Button = $CenterContainer/VBoxContainer/ContinueBtn
@onready var dex_btn: Button = $CenterContainer/VBoxContainer/DexBtn
@onready var wallet_btn: Button = $CenterContainer/VBoxContainer/WalletBtn
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/QuitBtn
@onready var wallet_label: Label = $CenterContainer/VBoxContainer/WalletLabel

var _dex_screen: Node
var _daily_popup: Node
var _stats_panel: Node
var _stats_btn: Button
var _multiplayer_hub: Node
var _mp_btn: Button
var _particles: CPUParticles2D
var _warm_particles: CPUParticles2D
var _showcase_sprites: Array[ColorRect] = []
var _title_label: Label
var _title_glow_time := 0.0
var _gradient_overlay: ColorRect

func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MENU)
	AudioManager.play_track(AudioManager.MusicTrack.MENU)

	# Style the background
	$Background.color = ThemeManager.COL_BG_DARKEST

	# Style title label with glow pulse
	_title_label = $CenterContainer/VBoxContainer/TitleLabel
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	_title_label.add_theme_constant_override("shadow_offset_x", 2)
	_title_label.add_theme_constant_override("shadow_offset_y", 2)
	_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))

	# Style subtitle
	var subtitle: Label = $CenterContainer/VBoxContainer/SubtitleLabel
	subtitle.text = "A Creature RPG on Monad"
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)

	# Style buttons wider with >> prefix
	_style_menu_button(start_btn, ">> New Game")
	_style_menu_button(continue_btn, ">> Continue")
	_style_menu_button(dex_btn, ">> Pikanadex")
	_style_menu_button(wallet_btn, ">> Connect Wallet")
	_style_menu_button(quit_btn, ">> Quit")

	start_btn.pressed.connect(_on_start)
	continue_btn.pressed.connect(_on_continue)
	dex_btn.pressed.connect(_on_dex)
	wallet_btn.pressed.connect(_on_wallet)
	quit_btn.pressed.connect(_on_quit)
	start_btn.grab_focus()

	# Button hover/press animations
	for btn in [start_btn, continue_btn, dex_btn, wallet_btn, quit_btn]:
		ThemeManager.apply_button_hover_anim(btn)

	# Show/hide Continue and Dex buttons based on save existence
	var has_save := SaveManager.has_save()
	continue_btn.visible = has_save
	dex_btn.visible = has_save

	# Add Stats button dynamically
	_stats_btn = Button.new()
	_stats_btn.text = ">> Stats"
	_stats_btn.custom_minimum_size = Vector2(220, 36)
	_stats_btn.visible = has_save
	_stats_btn.pressed.connect(_on_stats)
	var vbox := $CenterContainer/VBoxContainer
	var dex_idx := dex_btn.get_index()
	vbox.add_child(_stats_btn)
	vbox.move_child(_stats_btn, dex_idx + 1)
	ThemeManager.apply_button_hover_anim(_stats_btn)

	# Add Multiplayer button
	_mp_btn = Button.new()
	_mp_btn.text = ">> Multiplayer"
	_mp_btn.custom_minimum_size = Vector2(220, 36)
	_mp_btn.visible = has_save
	_mp_btn.pressed.connect(_on_multiplayer)
	vbox.add_child(_mp_btn)
	vbox.move_child(_mp_btn, _stats_btn.get_index() + 1)
	ThemeManager.apply_button_hover_anim(_mp_btn)

	# VBox spacing
	vbox.add_theme_constant_override("separation", 6)

	# Floating particle effect (faint blue sparkles)
	_create_particles()

	# Creature showcase — 3 random colored silhouettes
	_create_creature_showcase()

	# Version label (bottom-right)
	_create_version_label()

	# Button stagger animation on appear
	ThemeManager.animate_stagger(vbox)

	# Animated gradient overlay (slow horizontal drift)
	_gradient_overlay = ColorRect.new()
	_gradient_overlay.color = Color(0.15, 0.1, 0.25, 0.08)
	_gradient_overlay.size = Vector2(640, 360)
	_gradient_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gradient_overlay.z_index = -1
	add_child(_gradient_overlay)

	# Show daily reward popup if available
	_check_daily_reward()

	# Show/hide web-specific buttons
	var is_web := OS.has_feature("web")
	wallet_btn.visible = is_web
	quit_btn.visible = not is_web
	wallet_label.visible = is_web

	# Connect Web3 signals
	if Web3Manager:
		Web3Manager.wallet_connected.connect(_on_wallet_connected)
		Web3Manager.wallet_error.connect(_on_wallet_error)
		if Web3Manager.is_wallet_connected():
			wallet_label.text = Web3Manager.short_address()
			wallet_btn.text = ">> Wallet Connected"

func _style_menu_button(btn: Button, text: String) -> void:
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 36)

func _create_particles() -> void:
	var particles_holder := Node2D.new()
	particles_holder.z_index = -1
	add_child(particles_holder)

	# Blue sparkles (35 particles)
	_particles = CPUParticles2D.new()
	_particles.emitting = true
	_particles.amount = 35
	_particles.lifetime = 4.0
	_particles.one_shot = false
	_particles.explosiveness = 0.0
	_particles.direction = Vector2(0, -1)
	_particles.spread = 180.0
	_particles.gravity = Vector2(0, -5)
	_particles.initial_velocity_min = 5.0
	_particles.initial_velocity_max = 15.0
	_particles.scale_amount_min = 0.5
	_particles.scale_amount_max = 1.5
	_particles.color = Color(0.3, 0.5, 0.9, 0.15)
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(320, 180)
	_particles.position = Vector2(320, 180)
	particles_holder.add_child(_particles)

	# Warm gold sparkles (10 particles)
	_warm_particles = CPUParticles2D.new()
	_warm_particles.emitting = true
	_warm_particles.amount = 10
	_warm_particles.lifetime = 5.0
	_warm_particles.one_shot = false
	_warm_particles.explosiveness = 0.0
	_warm_particles.direction = Vector2(0, -1)
	_warm_particles.spread = 180.0
	_warm_particles.gravity = Vector2(0, -3)
	_warm_particles.initial_velocity_min = 3.0
	_warm_particles.initial_velocity_max = 10.0
	_warm_particles.scale_amount_min = 0.8
	_warm_particles.scale_amount_max = 2.0
	_warm_particles.color = Color(1.0, 0.85, 0.25, 0.1)
	_warm_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_warm_particles.emission_rect_extents = Vector2(320, 180)
	_warm_particles.position = Vector2(320, 180)
	particles_holder.add_child(_warm_particles)

func _create_creature_showcase() -> void:
	var colors := [
		Color(0.95, 0.4, 0.2, 0.12),   # Fiery
		Color(0.2, 0.6, 0.95, 0.12),   # Watery
		Color(0.3, 0.8, 0.3, 0.12),    # Grassy
	]
	for i in 3:
		var rect := ColorRect.new()
		rect.color = colors[i]
		rect.custom_minimum_size = Vector2(28, 28)
		rect.size = Vector2(28, 28)
		rect.position = Vector2(240 + i * 50, 260)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_showcase_sprites.append(rect)

var _breathe_time := 0.0

func _process(delta: float) -> void:
	# Breathing animation for creature showcase
	_breathe_time += delta * 1.5
	for i in _showcase_sprites.size():
		var offset_y := sin(_breathe_time + i * 1.2) * 3.0
		_showcase_sprites[i].position.y = 260 + offset_y

	# Title glow pulse (gold warmth oscillation)
	_title_glow_time += delta * 2.0
	if _title_label:
		var glow := 0.85 + sin(_title_glow_time) * 0.15
		_title_label.modulate = Color(1.0, glow, glow * 0.8, 1.0)

	# Gradient overlay slow horizontal drift
	if _gradient_overlay:
		_gradient_overlay.position.x = sin(_breathe_time * 0.3) * 20.0

func _create_version_label() -> void:
	var ver := Label.new()
	ver.text = "v0.6.0"
	ver.add_theme_font_size_override("font_size", 8)
	ver.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	ver.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	ver.anchor_left = 1.0
	ver.anchor_top = 1.0
	ver.anchor_right = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left = -50
	ver.offset_top = -18
	ver.offset_right = -4
	ver.offset_bottom = -4
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)

func _on_start() -> void:
	SceneManager.go_to_overworld()

func _on_continue() -> void:
	SaveManager.load_game()
	SceneManager.go_to_overworld()

func _on_dex() -> void:
	if _dex_screen:
		return
	if SaveManager.has_save():
		SaveManager.load_game()
	var dex_scene := load("res://scenes/ui/creature_dex.tscn")
	_dex_screen = dex_scene.instantiate()
	add_child(_dex_screen)
	_dex_screen.open_dex()
	_dex_screen.close_btn.pressed.connect(func():
		if _dex_screen:
			_dex_screen.queue_free()
			_dex_screen = null
	)

func _on_stats() -> void:
	if _stats_panel:
		return
	if SaveManager.has_save():
		SaveManager.load_game()
	_stats_panel = load("res://scripts/ui/stats_panel.gd").new()
	add_child(_stats_panel)
	_stats_panel.closed.connect(func():
		_stats_panel = null
	)

func _on_multiplayer() -> void:
	if _multiplayer_hub:
		return
	if SaveManager.has_save():
		SaveManager.load_game()
	_multiplayer_hub = load("res://scripts/ui/multiplayer_hub.gd").new()
	add_child(_multiplayer_hub)
	_multiplayer_hub.closed.connect(func():
		_multiplayer_hub = null
	)

func _on_wallet() -> void:
	if Web3Manager and not Web3Manager.is_wallet_connected():
		wallet_btn.text = ">> Connecting..."
		wallet_btn.disabled = true
		Web3Manager.connect_wallet()

func _on_quit() -> void:
	get_tree().quit()

func _on_wallet_connected(address: String) -> void:
	wallet_btn.text = ">> Wallet Connected"
	wallet_btn.disabled = true
	wallet_label.text = Web3Manager.short_address()

func _on_wallet_error(message: String) -> void:
	wallet_btn.text = ">> Connect Wallet"
	wallet_btn.disabled = false
	wallet_label.text = message

func _check_daily_reward() -> void:
	var reward_info := DailyRewardManager.check_daily_reward()
	if reward_info["available"]:
		_daily_popup = load("res://scripts/ui/daily_reward_popup.gd").new()
		add_child(_daily_popup)
		_daily_popup.show_reward(reward_info["day"], reward_info["reward"])
		_daily_popup.reward_claimed.connect(func():
			if _daily_popup:
				_daily_popup.queue_free()
				_daily_popup = null
		)
