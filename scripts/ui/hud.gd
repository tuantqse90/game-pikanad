extends CanvasLayer

## Overworld HUD — shows party count, capture items, and gold.

@onready var party_label: Label = $HBoxContainer/PartyLabel
@onready var capture_label: Label = $HBoxContainer/CaptureLabel
var gold_label: Label

func _ready() -> void:
	PartyManager.party_changed.connect(_update_display)
	# Gold label may or may not exist depending on the scene
	gold_label = get_node_or_null("HBoxContainer/GoldLabel")
	if InventoryManager:
		InventoryManager.gold_changed.connect(_update_gold)
	# PvP button
	var pvp_btn := get_node_or_null("PvPButton") as Button
	if pvp_btn:
		pvp_btn.pressed.connect(func(): SceneManager.go_to_pvp_queue())
	_update_display()

func _process(_delta: float) -> void:
	capture_label.text = "Balls: %d" % GameManager.capture_items

func _update_display() -> void:
	party_label.text = "Party: %d/6" % PartyManager.party_size()
	capture_label.text = "Balls: %d" % GameManager.capture_items
	_update_gold(InventoryManager.gold if InventoryManager else 0)

func _update_gold(amount: int) -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % amount
