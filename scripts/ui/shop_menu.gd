extends CanvasLayer

## Shop menu for buying items with gold.

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var item_list: VBoxContainer = $Panel/VBox/ScrollContainer/ItemList
@onready var close_btn: Button = $Panel/VBox/CloseBtn

var _shop_items: Array[Resource] = []
var _on_close: Callable

func _ready() -> void:
	add_to_group("shop_menu")
	panel.visible = false
	close_btn.pressed.connect(_close)

func open_shop(items: Array[Resource], on_close: Callable = Callable()) -> void:
	_shop_items = items
	_on_close = on_close
	panel.visible = true
	_refresh()

func _refresh() -> void:
	gold_label.text = "Gold: %d" % InventoryManager.gold

	for child in item_list.get_children():
		child.queue_free()

	for item_res in _shop_items:
		var item: ItemData = item_res as ItemData
		if not item:
			continue
		var row := HBoxContainer.new()

		var name_label := Label.new()
		name_label.text = "%s - %dG" % [item.item_name, item.price]
		name_label.custom_minimum_size = Vector2(200, 0)
		row.add_child(name_label)

		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(60, 28)
		var item_ref := item
		buy_btn.pressed.connect(func(): _buy_item(item_ref))
		row.add_child(buy_btn)

		item_list.add_child(row)

func _buy_item(item: ItemData) -> void:
	if InventoryManager.spend_gold(item.price):
		match item.item_type:
			ItemData.ItemType.CAPTURE_BALL:
				GameManager.capture_items += item.effect_value
			ItemData.ItemType.POTION:
				InventoryManager.add_item(item.item_name, 1)
			_:
				InventoryManager.add_item(item.item_name, 1)
		_refresh()
	else:
		gold_label.text = "Gold: %d (Not enough!)" % InventoryManager.gold

func _close() -> void:
	panel.visible = false
	if _on_close.is_valid():
		_on_close.call()
