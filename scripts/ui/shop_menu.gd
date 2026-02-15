extends CanvasLayer

## Shop menu — item type colored dots, gold-styled price, disabled buy if can't afford.

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

	# Larger panel
	panel.custom_minimum_size = Vector2(340, 280)

	# Style title
	title_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)

func open_shop(items: Array[Resource], on_close: Callable = Callable()) -> void:
	_shop_items = items
	_on_close = on_close
	panel.visible = true
	_refresh()

func _refresh() -> void:
	gold_label.text = "Gold: %d" % InventoryManager.gold
	gold_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)

	for child in item_list.get_children():
		child.queue_free()

	for item_res in _shop_items:
		var item: ItemData = item_res as ItemData
		if not item:
			continue

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		# Item type color dot
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(6, 6)
		match item.item_type:
			ItemData.ItemType.CAPTURE_BALL:
				dot.color = ThemeManager.COL_ACCENT
			ItemData.ItemType.POTION:
				dot.color = ThemeManager.COL_ACCENT_GREEN
			ItemData.ItemType.STATUS_CURE:
				dot.color = Color(0.7, 0.5, 0.9)
			ItemData.ItemType.REVIVE:
				dot.color = Color(0.9, 0.8, 0.2)
			_:
				dot.color = ThemeManager.COL_TEXT_DIM
		row.add_child(dot)

		# Item name
		var name_label := Label.new()
		name_label.text = item.item_name
		name_label.custom_minimum_size = Vector2(120, 0)
		row.add_child(name_label)

		# Price (gold styled)
		var price_label := Label.new()
		price_label.text = "%dG" % item.price
		price_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
		price_label.custom_minimum_size = Vector2(50, 0)
		row.add_child(price_label)

		# Buy button (disabled if can't afford)
		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(50, 26)
		var can_afford := InventoryManager.gold >= item.price
		buy_btn.disabled = not can_afford
		if not can_afford:
			buy_btn.add_theme_color_override("font_color", Color(0.4, 0.35, 0.45))
		var item_ref := item
		buy_btn.pressed.connect(func(): _buy_item(item_ref))
		row.add_child(buy_btn)

		item_list.add_child(row)

func _buy_item(item: ItemData) -> void:
	if InventoryManager.spend_gold(item.price):
		InventoryManager.add_item(item.item_name, 1)
		InventoryManager.register_item(item.item_name, item.resource_path)
		_refresh()
	else:
		gold_label.text = "Gold: %d (Not enough!)" % InventoryManager.gold

func _close() -> void:
	panel.visible = false
	if _on_close.is_valid():
		_on_close.call()
