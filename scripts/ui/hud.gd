extends CanvasLayer

## Overworld HUD — panel-backed stats with icon dots and quick-access buttons.

@onready var party_label: Label = $HBoxContainer/PartyLabel
@onready var capture_label: Label = $HBoxContainer/CaptureLabel
var gold_label: Label

var _hud_panel: PanelContainer
var _stats_hbox: HBoxContainer
var _quick_bar: HBoxContainer

func _ready() -> void:
	PartyManager.party_changed.connect(_update_display)
	gold_label = get_node_or_null("HBoxContainer/GoldLabel")
	if InventoryManager:
		InventoryManager.gold_changed.connect(_update_gold)
		InventoryManager.inventory_changed.connect(_update_display)
	# PvP button
	var pvp_btn := get_node_or_null("PvPButton") as Button
	if pvp_btn:
		pvp_btn.pressed.connect(func(): SceneManager.go_to_pvp_queue())

	# Wrap existing HBox in a semi-transparent panel shelf
	_style_hud()
	_create_quick_bar()
	_update_display()

	# Delayed tutorial hints
	_show_delayed_tutorials()

func _style_hud() -> void:
	# Add icon dots before stat labels
	var hbox := $HBoxContainer
	hbox.add_theme_constant_override("separation", 10)

	# Reparent the HBox into a PanelContainer for shelf look
	_hud_panel = PanelContainer.new()
	_hud_panel.anchors_preset = Control.PRESET_TOP_LEFT
	_hud_panel.position = Vector2(4, 4)
	_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Semi-transparent panel style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.75)
	style.border_color = Color(0.35, 0.32, 0.48)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	_hud_panel.add_theme_stylebox_override("panel", style)

	# Move HBox into the panel
	hbox.get_parent().remove_child(hbox)
	_hud_panel.add_child(hbox)
	add_child(_hud_panel)

func _create_quick_bar() -> void:
	# Quick-access buttons top-right
	_quick_bar = HBoxContainer.new()
	_quick_bar.anchors_preset = Control.PRESET_TOP_RIGHT
	_quick_bar.anchor_left = 1.0
	_quick_bar.anchor_right = 1.0
	_quick_bar.offset_left = -110
	_quick_bar.offset_top = 4
	_quick_bar.offset_right = -4
	_quick_bar.add_theme_constant_override("separation", 4)
	_quick_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var buttons := [
		{"label": "P", "hint": "TAB", "action": "open_menu"},
		{"label": "D", "hint": "X", "action": "open_dex"},
		{"label": "Q", "hint": "Q", "action": "open_quests"},
	]
	for info in buttons:
		var btn := Button.new()
		btn.text = info["label"]
		btn.tooltip_text = info["hint"]
		btn.custom_minimum_size = Vector2(24, 24)
		var action: String = info["action"]
		btn.pressed.connect(func():
			Input.action_press(action)
			await get_tree().process_frame
			Input.action_release(action)
		)
		_quick_bar.add_child(btn)

	add_child(_quick_bar)

func _update_display() -> void:
	party_label.text = "Party: %d/6" % PartyManager.party_size()
	var total_balls := InventoryManager.get_total_ball_count() if InventoryManager else 0
	capture_label.text = "Balls: %d" % total_balls
	_update_gold(InventoryManager.gold if InventoryManager else 0)

	# Color code icon dots via label prefixes
	party_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GREEN)
	capture_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT)

func _show_delayed_tutorials() -> void:
	if not TutorialManager:
		return
	# Show shop/dex/quest hints after a delay (only if welcome is done)
	if not TutorialManager.is_completed("welcome"):
		return
	await get_tree().create_timer(30.0).timeout
	if TutorialManager and not TutorialManager.is_completed("shop_hint"):
		TutorialManager.try_show("shop_hint")
		await get_tree().create_timer(20.0).timeout
	if TutorialManager and not TutorialManager.is_completed("dex_hint"):
		TutorialManager.try_show("dex_hint")
		await get_tree().create_timer(20.0).timeout
	if TutorialManager and not TutorialManager.is_completed("quest_hint"):
		TutorialManager.try_show("quest_hint")

func _update_gold(amount: int) -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % amount
		gold_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
