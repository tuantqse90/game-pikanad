extends CanvasLayer

## Stats Panel — displays player statistics.

signal closed

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
	panel.offset_left = -180
	panel.offset_top = -140
	panel.offset_right = 180
	panel.offset_bottom = 140
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Player Stats"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(title)

	# Stats list
	var stats := [
		["Battles Won", str(StatsManager.battles_won)],
		["Battles Lost", str(StatsManager.battles_lost)],
		["Creatures Caught", str(StatsManager.creatures_caught)],
		["Creatures Evolved", str(StatsManager.creatures_evolved)],
		["Trainers Defeated", str(StatsManager.trainers_defeated)],
		["Total Damage Dealt", str(StatsManager.total_damage_dealt)],
		["Zones Explored", str(StatsManager.zones_explored.size())],
		["Shinies Found", str(StatsManager.shinies_found)],
		["Play Time", StatsManager.get_play_time_string()],
	]

	for stat_entry in stats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)

		var name_label := Label.new()
		name_label.text = stat_entry[0]
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var value_label := Label.new()
		value_label.text = stat_entry[1]
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(80, 28)
	close_btn.pressed.connect(func():
		closed.emit()
		queue_free()
	)
	vbox.add_child(close_btn)
	close_btn.grab_focus()
