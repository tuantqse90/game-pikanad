extends CanvasLayer

## Multiplayer Hub — overlay with Trade / PvP Battle / Leaderboard buttons.

signal closed

var _trade_menu: Node
var _leaderboard: Node

func _ready() -> void:
	layer = 50
	_build_ui()

func _build_ui() -> void:
	# Dark backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.7)
	backdrop.anchors_preset = Control.PRESET_FULL_RECT
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	add_child(backdrop)

	# Center panel
	var panel := PanelContainer.new()
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -150
	panel.offset_top = -120
	panel.offset_right = 150
	panel.offset_bottom = 120
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Multiplayer Hub"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	vbox.add_child(title)

	# Connection status
	var status := Label.new()
	if NetworkManager.is_connected_to_server():
		status.text = "Connected"
		status.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GREEN)
	else:
		status.text = "Offline"
		status.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 9)
	vbox.add_child(status)

	# Trade button
	var trade_btn := Button.new()
	trade_btn.text = ">> Online Trade"
	trade_btn.custom_minimum_size = Vector2(200, 34)
	trade_btn.pressed.connect(_on_trade)
	vbox.add_child(trade_btn)
	trade_btn.grab_focus()

	# PvP Battle button
	var pvp_btn := Button.new()
	pvp_btn.text = ">> PvP Battle"
	pvp_btn.custom_minimum_size = Vector2(200, 34)
	pvp_btn.pressed.connect(_on_pvp)
	vbox.add_child(pvp_btn)

	# Leaderboard button
	var lb_btn := Button.new()
	lb_btn.text = ">> Leaderboard"
	lb_btn.custom_minimum_size = Vector2(200, 34)
	lb_btn.pressed.connect(_on_leaderboard)
	vbox.add_child(lb_btn)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(100, 28)
	close_btn.pressed.connect(func():
		closed.emit()
		queue_free()
	)
	vbox.add_child(close_btn)

func _on_trade() -> void:
	if _trade_menu:
		return
	_trade_menu = load("res://scripts/ui/trade_menu.gd").new()
	get_tree().current_scene.add_child(_trade_menu)
	_trade_menu.closed.connect(func():
		_trade_menu = null
	)

func _on_pvp() -> void:
	closed.emit()
	queue_free()
	SceneManager.go_to_pvp_queue()

func _on_leaderboard() -> void:
	if _leaderboard:
		return
	_leaderboard = load("res://scripts/ui/leaderboard_panel.gd").new()
	get_tree().current_scene.add_child(_leaderboard)
	_leaderboard.closed.connect(func():
		_leaderboard = null
	)
