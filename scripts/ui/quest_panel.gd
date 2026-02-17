extends CanvasLayer

## Quest Panel — shows 3 active daily quests with progress and claim buttons.

signal closed

func _ready() -> void:
	layer = 50
	_build_ui()

func _build_ui() -> void:
	# Dark backdrop with fade-in
	var backdrop := ThemeManager.create_vignette_backdrop(self)

	# Center panel
	var panel := PanelContainer.new()
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -200
	panel.offset_top = -120
	panel.offset_right = 200
	panel.offset_bottom = 120
	add_child(panel)
	ThemeManager.animate_panel_open(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Daily Quests"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(title)

	# Quest list
	var quests := QuestManager.get_active_quests()
	if quests.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No quests available today."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty_label)
	else:
		for i in quests.size():
			var quest: Dictionary = quests[i]
			_add_quest_row(vbox, quest, i)

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
	ThemeManager.apply_button_hover_anim(close_btn)

func _add_quest_row(parent: VBoxContainer, quest: Dictionary, index: int) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	parent.add_child(hbox)

	# Quest description and progress
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var desc := Label.new()
	desc.text = quest["desc"]
	desc.add_theme_font_size_override("font_size", 11)
	info_vbox.add_child(desc)

	# Progress bar
	var progress_hbox := HBoxContainer.new()
	progress_hbox.add_theme_constant_override("separation", 4)
	info_vbox.add_child(progress_hbox)

	var bar := ProgressBar.new()
	bar.max_value = quest["target"]
	bar.value = quest["progress"]
	bar.custom_minimum_size = Vector2(150, 12)
	bar.show_percentage = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.7, 0.3) if quest["completed"] else Color(0.3, 0.5, 0.8)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", style)
	progress_hbox.add_child(bar)

	var progress_label := Label.new()
	progress_label.text = "%d/%d" % [quest["progress"], quest["target"]]
	progress_label.add_theme_font_size_override("font_size", 10)
	progress_hbox.add_child(progress_label)

	# Reward info
	var reward_text := "%dG" % quest["gold"]
	if quest["item"] != "":
		reward_text += " + %s" % quest["item"]
	var reward_label := Label.new()
	reward_label.text = reward_text
	reward_label.add_theme_font_size_override("font_size", 9)
	reward_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	info_vbox.add_child(reward_label)

	# Claim button or status
	if quest["claimed"]:
		var done_label := Label.new()
		done_label.text = "Done"
		done_label.add_theme_font_size_override("font_size", 10)
		done_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		hbox.add_child(done_label)
	elif quest["completed"]:
		var claim_btn := Button.new()
		claim_btn.text = "Claim"
		claim_btn.custom_minimum_size = Vector2(60, 24)
		var idx := index
		claim_btn.pressed.connect(func():
			QuestManager.claim_quest(idx)
			# Rebuild UI to reflect changes
			for child in get_children():
				child.queue_free()
			_build_ui()
		)
		hbox.add_child(claim_btn)
		ThemeManager.apply_button_hover_anim(claim_btn)
	else:
		var pending_label := Label.new()
		pending_label.text = "..."
		pending_label.add_theme_font_size_override("font_size", 10)
		hbox.add_child(pending_label)
