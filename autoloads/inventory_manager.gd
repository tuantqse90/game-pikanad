extends Node

## Manages the player's inventory: gold and items.

signal gold_changed(new_amount: int)
signal inventory_changed

var gold: int = 0
var items: Dictionary = {}  # item_name -> count

# Item registry: item_name -> resource_path for looking up ItemData
var item_registry: Dictionary = {}

func _ready() -> void:
	# Register built-in items
	register_item("Capture Ball", "res://resources/items/capture_ball.tres")
	register_item("Super Ball", "res://resources/items/super_ball.tres")
	register_item("Ultra Ball", "res://resources/items/ultra_ball.tres")
	register_item("Master Ball", "res://resources/items/master_ball.tres")
	register_item("Potion", "res://resources/items/potion.tres")
	register_item("Super Potion", "res://resources/items/super_potion.tres")
	register_item("Max Potion", "res://resources/items/max_potion.tres")
	register_item("Revive", "res://resources/items/revive.tres")
	register_item("Antidote", "res://resources/items/antidote.tres")
	register_item("Awakening", "res://resources/items/awakening.tres")
	register_item("Full Heal", "res://resources/items/full_heal.tres")
	register_item("Everstone", "res://resources/items/everstone.tres")
	register_item("Power Band", "res://resources/items/power_band.tres")
	register_item("Guard Charm", "res://resources/items/guard_charm.tres")
	register_item("Swift Feather", "res://resources/items/swift_feather.tres")

func register_item(item_name: String, resource_path: String) -> void:
	item_registry[item_name] = resource_path

func get_item_data(item_name: String) -> ItemData:
	if item_registry.has(item_name):
		return load(item_registry[item_name]) as ItemData
	return null

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

## Get all capture balls in inventory with their data.
func get_capture_balls() -> Array[Dictionary]:
	var balls: Array[Dictionary] = []
	for item_name in items:
		var data := get_item_data(item_name)
		if data and data.item_type == ItemData.ItemType.CAPTURE_BALL and items[item_name] > 0:
			balls.append({"name": item_name, "count": items[item_name], "data": data})
	return balls

## Get all items usable in battle (potions, status cures, revives).
func get_usable_battle_items() -> Array[Dictionary]:
	var usable: Array[Dictionary] = []
	for item_name in items:
		var data := get_item_data(item_name)
		if data and data.usable_in_battle and data.item_type != ItemData.ItemType.CAPTURE_BALL and items[item_name] > 0:
			usable.append({"name": item_name, "count": items[item_name], "data": data})
	return usable

## Get total capture ball count (all types).
func get_total_ball_count() -> int:
	var total := 0
	for item_name in items:
		var data := get_item_data(item_name)
		if data and data.item_type == ItemData.ItemType.CAPTURE_BALL:
			total += items[item_name]
	return total
