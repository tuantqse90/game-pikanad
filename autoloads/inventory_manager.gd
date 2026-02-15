extends Node

## Manages the player's inventory: gold and items.

signal gold_changed(new_amount: int)
signal inventory_changed

var gold: int = 0
var items: Dictionary = {}  # item_name -> count

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func add_item(item_name: String, count: int = 1) -> void:
	if items.has(item_name):
		items[item_name] += count
	else:
		items[item_name] = count
	inventory_changed.emit()

func remove_item(item_name: String, count: int = 1) -> bool:
	if not items.has(item_name) or items[item_name] < count:
		return false
	items[item_name] -= count
	if items[item_name] <= 0:
		items.erase(item_name)
	inventory_changed.emit()
	return true

func get_item_count(item_name: String) -> int:
	return items.get(item_name, 0)

func has_item(item_name: String, count: int = 1) -> bool:
	return get_item_count(item_name) >= count
