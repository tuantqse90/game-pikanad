class_name ItemData
extends Resource

## Definition for an inventory item.

enum ItemType { CAPTURE_BALL, POTION, KEY_ITEM, STATUS_CURE, REVIVE, HELD_ITEM }
enum HeldEffect { NONE, PREVENT_EVOLUTION, BOOST_ATK, BOOST_DEF, BOOST_SPD }

@export var item_name: String = ""
@export var item_type: ItemType = ItemType.CAPTURE_BALL
@export var description: String = ""
@export var price: int = 100
@export var effect_value: int = 0  # Heal amount for potions, etc.

# Capture ball multiplier (1.0 = standard, 2.0 = ultra, 100.0 = master)
@export var catch_multiplier: float = 1.0

# Status cure: which statuses this item cures
@export var cures_statuses: Array[StatusEffect.Type] = []

# Held item properties
@export var held_effect: HeldEffect = HeldEffect.NONE
@export var held_boost_percent: float = 0.0  # e.g. 0.1 = +10%

# Usage flags
@export var usable_in_battle: bool = false
@export var usable_in_overworld: bool = false
