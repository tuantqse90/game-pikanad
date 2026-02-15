extends CanvasLayer

## Trade Menu — client-side trading framework (local mock for now).

signal trade_completed(offered_index: int, received_creature: CreatureInstance)
signal closed

enum TradeState { IDLE, SELECTING, WAITING, CONFIRMING, COMPLETE }

var _state: TradeState = TradeState.IDLE
var _selected_index: int = -1

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
	panel.offset_left = -240
	panel.offset_top = -120
	panel.offset_right = 240
	panel.offset_bottom = 120
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Trade Center"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(title)

	# Two columns: Your Offer | Their Offer
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(columns)

	# Left side: Your Offer
	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_child(left)

	var your_label := Label.new()
	your_label.text = "Your Offer"
	your_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	your_label.add_theme_font_size_override("font_size", 12)
	left.add_child(your_label)

	for i in PartyManager.party.size():
		var creature: CreatureInstance = PartyManager.party[i]
		var btn := Button.new()
		var shiny_star := " *" if creature.is_shiny else ""
		btn.text = "%s Lv.%d%s" % [creature.display_name(), creature.level, shiny_star]
		btn.custom_minimum_size = Vector2(140, 24)
		var idx := i
		btn.pressed.connect(func(): _select_offer(idx, btn))
		left.add_child(btn)

	# Right side: Their Offer (placeholder)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_child(right)

	var their_label := Label.new()
	their_label.text = "Their Offer"
	their_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	their_label.add_theme_font_size_override("font_size", 12)
	right.add_child(their_label)

	var placeholder := Label.new()
	placeholder.text = "Waiting for\ntrade partner..."
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size", 10)
	placeholder.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	right.add_child(placeholder)

	# Status message
	var status := Label.new()
	status.name = "StatusLabel"
	status.text = "Trading requires a network connection.\nComing soon!"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 10)
	status.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	vbox.add_child(status)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var cancel_btn := Button.new()
	cancel_btn.text = "Close"
	cancel_btn.custom_minimum_size = Vector2(80, 28)
	cancel_btn.pressed.connect(func():
		closed.emit()
		queue_free()
	)
	btn_row.add_child(cancel_btn)
	cancel_btn.grab_focus()

func _select_offer(index: int, btn: Button) -> void:
	_selected_index = index
	_state = TradeState.SELECTING
	# Visual feedback — highlight selected
	btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
