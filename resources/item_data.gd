class_name ItemData
extends Resource

## Definition for an inventory item.

enum ItemType { CAPTURE_BALL, POTION, KEY_ITEM }

@export var item_name: String = ""
@export var item_type: ItemType = ItemType.CAPTURE_BALL
@export var description: String = ""
@export var price: int = 100
@export var effect_value: int = 0  # Heal amount for potions, etc.
