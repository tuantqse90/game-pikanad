extends Area2D

## Base NPC class with multi-part body visual, floating "!" indicator,
## and type icon. NPCs can talk, heal, sell items, or challenge as trainers.

enum NPCType { TALKER, HEALER, SHOPKEEPER, TRAINER, TRADER }

@export var npc_name: String = "NPC"
@export var npc_type: NPCType = NPCType.TALKER
@export var dialogue_lines: Array[String] = ["Hello!"]
@export var npc_color := Color(0.8, 0.6, 0.3)

# Shop items (only used by SHOPKEEPER type)
@export var shop_items: Array[Resource] = []

# Trainer fields (only used by TRAINER type)
@export var trainer_data_path: String = ""
@export var trainer_id: String = ""

var _interactable := false
var _label: Label
var _indicator: Label
var _bob_time := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Multi-part body: head (12x12) + body (16x20)
	var body_rect := ColorRect.new()
	body_rect.color = npc_color
	body_rect.size = Vector2(16, 20)
	body_rect.position = Vector2(-8, -8)
	add_child(body_rect)

	var head_rect := ColorRect.new()
	head_rect.color = npc_color.lightened(0.2)
	head_rect.size = Vector2(12, 12)
	head_rect.position = Vector2(-6, -22)
	add_child(head_rect)

	# Name label with panel background
	var name_panel := PanelContainer.new()
	var name_style := StyleBoxFlat.new()
	name_style.bg_color = Color(0.06, 0.05, 0.1, 0.7)
	name_style.set_corner_radius_all(2)
	name_style.content_margin_left = 4.0
	name_style.content_margin_right = 4.0
	name_style.content_margin_top = 1.0
	name_style.content_margin_bottom = 1.0
	name_panel.add_theme_stylebox_override("panel", name_style)
	name_panel.position = Vector2(-36, -38)
	add_child(name_panel)

	_label = Label.new()
	_label.text = npc_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 8)
	name_panel.add_child(_label)

	# Type icon below name
	var type_icon := Label.new()
	type_icon.add_theme_font_size_override("font_size", 8)
	type_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_icon.position = Vector2(-4, 14)
	match npc_type:
		NPCType.HEALER:
			type_icon.text = "+"
			type_icon.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GREEN)
		NPCType.SHOPKEEPER:
			type_icon.text = "$"
			type_icon.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
		NPCType.TRAINER:
			type_icon.text = "!"
			type_icon.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_RED)
		NPCType.TALKER:
			type_icon.text = "..."
			type_icon.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
		NPCType.TRADER:
			type_icon.text = "<>"
			type_icon.add_theme_color_override("font_color", Color(0.3, 0.85, 0.9))
	add_child(type_icon)

	# Floating "!" indicator (hidden until interactable)
	_indicator = Label.new()
	_indicator.text = "!"
	_indicator.add_theme_font_size_override("font_size", 12)
	_indicator.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	_indicator.position = Vector2(-3, -50)
	_indicator.visible = false
	add_child(_indicator)

func _process(delta: float) -> void:
	if _interactable and _indicator:
		_bob_time += delta * 3.0
		_indicator.position.y = -50 + sin(_bob_time) * 3.0

func _unhandled_input(event: InputEvent) -> void:
	if _interactable and event.is_action_pressed("ui_accept"):
		if GameManager.state == GameManager.GameState.OVERWORLD:
			interact()

func interact() -> void:
	AudioManager.play_sound(AudioManager.SFX.NPC_INTERACT)
	# Tutorial: first NPC interaction
	if TutorialManager and not TutorialManager.is_completed("first_npc"):
		TutorialManager.show_tutorial("first_npc")
		return
	match npc_type:
		NPCType.TALKER:
			_show_dialogue()
		NPCType.HEALER:
			_heal_party()
		NPCType.SHOPKEEPER:
			_open_shop()
		NPCType.TRAINER:
			_challenge_trainer()
		NPCType.TRADER:
			_open_trade()

func _open_trade() -> void:
	GameManager.change_state(GameManager.GameState.PAUSED)
	if PartyManager.party_size() == 0:
		var dialogue_box = _get_dialogue_box()
		if dialogue_box:
			dialogue_box.show_dialogue(
				["You don't have any creatures to trade!"],
				func(): GameManager.change_state(GameManager.GameState.OVERWORLD)
			)
		return
	var trade_scene := load("res://scripts/ui/npc_trade_menu.gd")
	var trade_menu := trade_scene.new()
	get_tree().current_scene.add_child(trade_menu)
	trade_menu.trade_completed.connect(func(_idx, _creature):
		# Tutorial: first trade
		if TutorialManager and not TutorialManager.is_completed("first_trade"):
			TutorialManager.show_tutorial("first_trade")
	)
	trade_menu.closed.connect(func():
		GameManager.change_state(GameManager.GameState.OVERWORLD)
	)

func _show_dialogue() -> void:
	GameManager.change_state(GameManager.GameState.PAUSED)
	var dialogue_box = _get_dialogue_box()
	if dialogue_box:
		dialogue_box.show_dialogue(dialogue_lines, func():
			GameManager.change_state(GameManager.GameState.OVERWORLD)
		)

func _heal_party() -> void:
	GameManager.change_state(GameManager.GameState.PAUSED)
	PartyManager.heal_all()
	var dialogue_box = _get_dialogue_box()
	if dialogue_box:
		dialogue_box.show_dialogue(
			["Your creatures have been fully healed!", "Come back anytime!"],
			func(): GameManager.change_state(GameManager.GameState.OVERWORLD)
		)

func _open_shop() -> void:
	GameManager.change_state(GameManager.GameState.PAUSED)
	var shop_menu = get_tree().get_first_node_in_group("shop_menu")
	if shop_menu:
		shop_menu.open_shop(shop_items, func():
			GameManager.change_state(GameManager.GameState.OVERWORLD)
		)
	else:
		var dialogue_box = _get_dialogue_box()
		if dialogue_box:
			dialogue_box.show_dialogue(
				["Welcome to my shop!", "Sorry, shop is under construction."],
				func(): GameManager.change_state(GameManager.GameState.OVERWORLD)
			)

func _challenge_trainer() -> void:
	if trainer_data_path == "":
		_show_dialogue()
		return

	var tid := trainer_id if trainer_id != "" else npc_name.to_lower().replace(" ", "_")
	if BadgeManager and BadgeManager.is_defeated(tid):
		GameManager.change_state(GameManager.GameState.PAUSED)
		var dialogue_box = _get_dialogue_box()
		if dialogue_box:
			dialogue_box.show_dialogue(
				["You've already beaten me!", "Keep pushing forward!"],
				func(): GameManager.change_state(GameManager.GameState.OVERWORLD)
			)
		return

	var t_data: TrainerData = load(trainer_data_path) as TrainerData
	if not t_data:
		_show_dialogue()
		return

	GameManager.change_state(GameManager.GameState.PAUSED)
	var dialogue_box = _get_dialogue_box()
	if dialogue_box and t_data.pre_battle_lines.size() > 0:
		dialogue_box.show_dialogue(t_data.pre_battle_lines, func():
			SceneManager.go_to_trainer_battle(t_data)
		)
	else:
		SceneManager.go_to_trainer_battle(t_data)

func _get_dialogue_box():
	return get_tree().get_first_node_in_group("dialogue_box")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_interactable = true
		_label.text = npc_name + " [E]"
		_indicator.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_interactable = false
		_label.text = npc_name
		_indicator.visible = false
