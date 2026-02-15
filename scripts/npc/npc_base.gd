extends Area2D

## Base NPC class. NPCs can talk, heal, or sell items.

enum NPCType { TALKER, HEALER, SHOPKEEPER }

@export var npc_name: String = "NPC"
@export var npc_type: NPCType = NPCType.TALKER
@export var dialogue_lines: Array[String] = ["Hello!"]
@export var npc_color := Color(0.8, 0.6, 0.3)

# Shop items (only used by SHOPKEEPER type)
@export var shop_items: Array[Resource] = []  # Array of ItemData

var _interactable := false
var _label: Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Visual: colored rectangle as NPC sprite
	var rect := ColorRect.new()
	rect.color = npc_color
	rect.size = Vector2(24, 24)
	rect.position = Vector2(-12, -12)
	add_child(rect)

	# Name label above
	_label = Label.new()
	_label.text = npc_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-30, -28)
	add_child(_label)

func _unhandled_input(event: InputEvent) -> void:
	if _interactable and event.is_action_pressed("ui_accept"):
		if GameManager.state == GameManager.GameState.OVERWORLD:
			interact()

func interact() -> void:
	match npc_type:
		NPCType.TALKER:
			_show_dialogue()
		NPCType.HEALER:
			_heal_party()
		NPCType.SHOPKEEPER:
			_open_shop()

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
		# Fallback: just show dialogue
		var dialogue_box = _get_dialogue_box()
		if dialogue_box:
			dialogue_box.show_dialogue(
				["Welcome to my shop!", "Sorry, shop is under construction."],
				func(): GameManager.change_state(GameManager.GameState.OVERWORLD)
			)

func _get_dialogue_box():
	return get_tree().get_first_node_in_group("dialogue_box")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_interactable = true
		_label.text = npc_name + " [E]"

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_interactable = false
		_label.text = npc_name
