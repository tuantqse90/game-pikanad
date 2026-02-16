extends CanvasLayer

## Trade Menu — online trading between two players via NetworkManager.
## Two-player offer flow with confirmation, party swap on complete.

signal trade_completed(offered_index: int, received_creature: CreatureInstance)
signal closed

enum TradeState { IDLE, SELECTING, WAITING, CONFIRMING, COMPLETE }

var _state: TradeState = TradeState.IDLE
var _selected_index: int = -1
var _their_creature_data: Dictionary = {}
var _their_creature: CreatureInstance

# UI refs
var _party_vbox: VBoxContainer
var _their_panel: VBoxContainer
var _confirm_btn: Button
var _status_label: Label

func _ready() -> void:
	layer = 50
	_build_ui()
	_connect_signals()

func _connect_signals() -> void:
	NetworkManager.trade_offer_received.connect(_on_trade_offer_received)
	NetworkManager.trade_accepted.connect(_on_trade_accepted)
	NetworkManager.trade_rejected.connect(_on_trade_rejected)
	NetworkManager.trade_completed.connect(_on_trade_complete)
	NetworkManager.disconnected.connect(func():
		_status_label.text = "Connection lost!"
		_state = TradeState.IDLE
	)

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
	panel.offset_top = -140
	panel.offset_right = 240
	panel.offset_bottom = 140
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Online Trade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	vbox.add_child(title)

	# Two columns: Your Offer | Their Offer
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(columns)

	# Left side: Your Offer
	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 3)
	columns.add_child(left)

	var your_label := Label.new()
	your_label.text = "Your Offer"
	your_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	your_label.add_theme_font_size_override("font_size", 12)
	your_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT)
	left.add_child(your_label)

	_party_vbox = VBoxContainer.new()
	_party_vbox.add_theme_constant_override("separation", 2)
	left.add_child(_party_vbox)

	for i in PartyManager.party.size():
		var creature: CreatureInstance = PartyManager.party[i]
		var btn := Button.new()
		var shiny_star := " *" if creature.is_shiny else ""
		btn.text = "%s Lv.%d%s" % [creature.display_name(), creature.level, shiny_star]
		btn.custom_minimum_size = Vector2(150, 24)
		btn.add_theme_font_size_override("font_size", 9)
		if creature.is_fainted():
			btn.disabled = true
		var idx := i
		btn.pressed.connect(func(): _select_offer(idx))
		_party_vbox.add_child(btn)

	# Right side: Their Offer
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 3)
	right.custom_minimum_size.x = 160
	columns.add_child(right)

	var their_label := Label.new()
	their_label.text = "Their Offer"
	their_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	their_label.add_theme_font_size_override("font_size", 12)
	their_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.9))
	right.add_child(their_label)

	_their_panel = VBoxContainer.new()
	_their_panel.add_theme_constant_override("separation", 2)
	right.add_child(_their_panel)

	var placeholder := Label.new()
	placeholder.text = "Waiting for\ntrade partner..."
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size", 10)
	placeholder.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	_their_panel.add_child(placeholder)

	# Status message
	_status_label = Label.new()
	if NetworkManager.is_connected_to_server():
		_status_label.text = "Connected. Select a creature to offer."
	else:
		_status_label.text = "Not connected to server.\nConnect via Multiplayer Hub first."
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	vbox.add_child(_status_label)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Accept Trade"
	_confirm_btn.custom_minimum_size = Vector2(100, 28)
	_confirm_btn.visible = false
	_confirm_btn.pressed.connect(_on_accept_trade)
	btn_row.add_child(_confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Close"
	cancel_btn.custom_minimum_size = Vector2(80, 28)
	cancel_btn.pressed.connect(func():
		if _state == TradeState.WAITING or _state == TradeState.CONFIRMING:
			NetworkManager.send_trade_reject()
		closed.emit()
		queue_free()
	)
	btn_row.add_child(cancel_btn)
	cancel_btn.grab_focus()

func _select_offer(index: int) -> void:
	if not NetworkManager.is_connected_to_server():
		_status_label.text = "Not connected to server!"
		return
	_selected_index = index
	_state = TradeState.WAITING
	NetworkManager.send_trade_offer(index)
	_status_label.text = "Offer sent! Waiting for response..."
	AudioManager.play_sound(AudioManager.SFX.TRADE_OFFER)

	# Highlight selected
	for i in _party_vbox.get_child_count():
		var btn: Button = _party_vbox.get_child(i) as Button
		if btn:
			if i == index:
				btn.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
			else:
				btn.remove_theme_color_override("font_color")

func _on_trade_offer_received(creature_data: Dictionary) -> void:
	_their_creature_data = creature_data
	_their_creature = NetworkManager.deserialize_trade_creature(creature_data)
	if not _their_creature:
		_status_label.text = "Invalid creature data received."
		return

	# Show their offer
	for child in _their_panel.get_children():
		child.queue_free()

	var name_label := Label.new()
	var shiny_star := " *" if _their_creature.is_shiny else ""
	name_label.text = "%s Lv.%d%s" % [_their_creature.display_name(), _their_creature.level, shiny_star]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	_their_panel.add_child(name_label)

	var el_badge := ThemeManager.create_element_badge(_their_creature.data.element)
	el_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_their_panel.add_child(el_badge)

	# Stats
	var stats_text := "HP:%d ATK:%d DEF:%d SPD:%d" % [
		_their_creature.max_hp(), _their_creature.attack(),
		_their_creature.defense(), _their_creature.speed()
	]
	var stats_label := Label.new()
	stats_label.text = stats_text
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 8)
	stats_label.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	_their_panel.add_child(stats_label)

	_state = TradeState.CONFIRMING
	_confirm_btn.visible = true
	_status_label.text = "Trade offer received! Accept or close."

func _on_accept_trade() -> void:
	NetworkManager.send_trade_accept()
	_state = TradeState.COMPLETE
	_confirm_btn.disabled = true
	_status_label.text = "Accepted! Waiting for trade to complete..."

func _on_trade_accepted() -> void:
	# Other player accepted — proceed with swap
	_complete_trade()

func _on_trade_rejected() -> void:
	_state = TradeState.IDLE
	_confirm_btn.visible = false
	_status_label.text = "Trade rejected. Select another creature."

func _on_trade_complete(received_data: Dictionary) -> void:
	var received := NetworkManager.deserialize_trade_creature(received_data)
	if received:
		_their_creature = received
	_complete_trade()

func _complete_trade() -> void:
	if _selected_index < 0 or not _their_creature:
		return

	AudioManager.play_sound(AudioManager.SFX.TRADE_COMPLETE)

	# Remove offered creature
	PartyManager.party.remove_at(_selected_index)

	# Check for trade evolution
	if _their_creature.can_trade_evolve():
		_their_creature.trade_evolve()
		DexManager.mark_caught(_their_creature.data.species_id)

	# Add received creature
	DexManager.mark_caught(_their_creature.data.species_id)
	PartyManager.add_creature(_their_creature)

	# Track stats
	StatsManager.increment("trades_completed")
	QuestManager.increment_quest("complete_trade")

	trade_completed.emit(_selected_index, _their_creature)
	_status_label.text = "Trade complete! Received %s." % _their_creature.display_name()
	_state = TradeState.COMPLETE
	_confirm_btn.visible = false
