extends CanvasLayer

## Badge display overlay — shows 8 badge slots in a row.

signal closed

var _panel: PanelContainer

func _ready() -> void:
	layer = 50

	# Dark backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.7)
	backdrop.anchors_preset = Control.PRESET_FULL_RECT
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	add_child(backdrop)

	# Center panel
	_panel = PanelContainer.new()
	_panel.anchors_preset = Control.PRESET_CENTER
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -200
	_panel.offset_top = -80
	_panel.offset_right = 200
	_panel.offset_bottom = 80
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Badges"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	# Badge row
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	var badge_colors := [
		Color(0.3, 0.8, 0.3),   # Sprout — green
		Color(0.9, 0.3, 0.1),   # Blaze — red-orange
		Color(0.2, 0.5, 0.9),   # Tide — blue
		Color(0.1, 0.6, 0.2),   # Grove — dark green
		Color(0.6, 0.4, 0.2),   # Rumble — brown
		Color(0.7, 0.7, 0.9),   # Tempest — light blue
		Color(0.3, 0.2, 0.3),   # Obsidian — dark purple
		Color(0.9, 0.8, 0.2),   # Champion — gold
	]

	for i in range(8):
		var badge_box := VBoxContainer.new()
		badge_box.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(badge_box)

		var circle := ColorRect.new()
		circle.custom_minimum_size = Vector2(24, 24)
		if BadgeManager.has_badge(i + 1):
			circle.color = badge_colors[i]
		else:
			circle.color = Color(0.3, 0.3, 0.3)  # Gray for unearned
		badge_box.add_child(circle)

		var name_label := Label.new()
		name_label.text = BadgeManager.BADGE_NAMES[i]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 8)
		badge_box.add_child(name_label)

	# Badge count
	var count_label := Label.new()
	count_label.text = "%d / 8 badges earned" % BadgeManager.badge_count()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(count_label)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(80, 28)
	close_btn.pressed.connect(func():
		closed.emit()
		queue_free()
	)
	vbox.add_child(close_btn)
