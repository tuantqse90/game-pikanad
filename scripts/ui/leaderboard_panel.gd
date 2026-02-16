extends CanvasLayer

## Leaderboard Panel — shows local PvP stats: record, ELO, trades, win rate.

signal closed

func _ready() -> void:
	layer = 55
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
	panel.offset_left = -160
	panel.offset_top = -120
	panel.offset_right = 160
	panel.offset_bottom = 120
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Leaderboard"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	vbox.add_child(title)

	# ELO rating (featured)
	var elo_label := Label.new()
	elo_label.text = "ELO Rating: %d" % StatsManager.elo_rating
	elo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elo_label.add_theme_font_size_override("font_size", 14)
	elo_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT)
	vbox.add_child(elo_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Stats rows
	var total_pvp := StatsManager.pvp_wins + StatsManager.pvp_losses
	var win_rate := 0.0
	if total_pvp > 0:
		win_rate = float(StatsManager.pvp_wins) / float(total_pvp) * 100.0

	var stats := [
		["PvP Wins", str(StatsManager.pvp_wins), ThemeManager.COL_ACCENT_GREEN],
		["PvP Losses", str(StatsManager.pvp_losses), ThemeManager.COL_ACCENT_RED],
		["Win Rate", "%.1f%%" % win_rate, ThemeManager.COL_ACCENT],
		["Total PvP", str(total_pvp), ThemeManager.COL_TEXT_BRIGHT],
		["Trades Done", str(StatsManager.trades_completed), Color(0.3, 0.85, 0.9)],
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
		value_label.add_theme_color_override("font_color", stat_entry[2])
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
