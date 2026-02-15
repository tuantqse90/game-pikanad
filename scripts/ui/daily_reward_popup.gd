extends CanvasLayer

## Daily Reward Popup — shows 7-day reward cycle with claim button.

signal reward_claimed

var _current_day: int = 0
var _reward_text: String = ""

func _ready() -> void:
	layer = 50

func show_reward(day: int, reward_text: String) -> void:
	_current_day = day
	_reward_text = reward_text
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
	panel.offset_left = -220
	panel.offset_top = -100
	panel.offset_right = 220
	panel.offset_bottom = 100
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Day %d Reward!" % (_current_day + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(title)

	# 7-day boxes row
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)

	for i in DailyRewardManager.REWARDS.size():
		var day_box := VBoxContainer.new()
		day_box.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(day_box)

		var rect := ColorRect.new()
		rect.custom_minimum_size = Vector2(48, 36)
		if i == _current_day:
			rect.color = Color(1.0, 0.85, 0.2)  # Highlighted gold
		elif i < _current_day:
			rect.color = Color(0.3, 0.6, 0.3)  # Claimed green
		else:
			rect.color = Color(0.3, 0.3, 0.3)  # Upcoming gray
		day_box.add_child(rect)

		var day_label := Label.new()
		day_label.text = "D%d" % (i + 1)
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_label.add_theme_font_size_override("font_size", 8)
		day_box.add_child(day_label)

		var reward_label := Label.new()
		reward_label.text = DailyRewardManager.REWARDS[i]["text"]
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.add_theme_font_size_override("font_size", 7)
		day_box.add_child(reward_label)

	# Reward description
	var desc := Label.new()
	desc.text = "Today's reward: %s" % _reward_text
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc)

	# Claim button
	var claim_btn := Button.new()
	claim_btn.text = "Claim!"
	claim_btn.custom_minimum_size = Vector2(100, 32)
	claim_btn.pressed.connect(func():
		DailyRewardManager.claim_daily_reward()
		reward_claimed.emit()
	)
	vbox.add_child(claim_btn)
	claim_btn.grab_focus()
