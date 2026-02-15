extends CanvasLayer

## Party menu overlay — creature cards with sprite thumbnails, mini HP bars,
## element badges, and fainted creature indicators.

@onready var panel: PanelContainer = $Panel
@onready var creature_list: VBoxContainer = $Panel/VBoxContainer/CreatureList
@onready var close_btn: Button = $Panel/VBoxContainer/CloseBtn

var _is_open := false

func _ready() -> void:
	panel.visible = false
	close_btn.pressed.connect(close_menu)

	# Larger panel
	panel.custom_minimum_size = Vector2(480, 320)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_menu") and GameManager.state == GameManager.GameState.OVERWORLD:
		if _is_open:
			close_menu()
		else:
			open_menu()

func open_menu() -> void:
	_is_open = true
	panel.visible = true
	GameManager.change_state(GameManager.GameState.PAUSED)
	_refresh_list()

func close_menu() -> void:
	_is_open = false
	panel.visible = false
	GameManager.change_state(GameManager.GameState.OVERWORLD)

func _refresh_list() -> void:
	for child in creature_list.get_children():
		child.queue_free()

	if PartyManager.party.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No creatures in party."
		creature_list.add_child(empty_label)
		return

	# Quick Heal button
	if _has_damaged_creatures() and _has_healing_items():
		var heal_btn := Button.new()
		heal_btn.text = "Heal All"
		heal_btn.custom_minimum_size = Vector2(0, 30)
		heal_btn.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GREEN)
		heal_btn.pressed.connect(_on_heal_all)
		creature_list.add_child(heal_btn)
		var sep := HSeparator.new()
		creature_list.add_child(sep)

	for creature in PartyManager.party:
		var entry := _create_entry(creature)
		creature_list.add_child(entry)

func _create_entry(creature: CreatureInstance) -> PanelContainer:
	# Wrap in a styled panel card
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = ThemeManager.COL_BG_PANEL_LIGHT if not creature.is_fainted() else Color(0.12, 0.1, 0.16)
	card_style.set_corner_radius_all(4)
	card_style.set_border_width_all(1)
	card_style.border_color = ThemeManager.ELEMENT_COLORS.get(creature.data.element, Color.GRAY) if not creature.is_fainted() else Color(0.3, 0.15, 0.15)
	card_style.content_margin_left = 6.0
	card_style.content_margin_right = 6.0
	card_style.content_margin_top = 4.0
	card_style.content_margin_bottom = 4.0
	card.add_theme_stylebox_override("panel", card_style)

	var container := VBoxContainer.new()
	card.add_child(container)

	# Top row: sprite thumbnail + name + level + element badge + HP
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Sprite thumbnail (colored rect if no texture)
	var thumb := ColorRect.new()
	thumb.custom_minimum_size = Vector2(20, 20)
	thumb.color = ThemeManager.ELEMENT_COLORS.get(creature.data.element, Color.GRAY)
	if creature.is_fainted():
		thumb.modulate = Color(0.4, 0.4, 0.4)
	row.add_child(thumb)

	# Name
	var name_label := Label.new()
	var display := creature.display_name()
	if creature.is_shiny:
		display = "\u2605 " + display
	name_label.text = display
	name_label.custom_minimum_size = Vector2(90, 0)
	if creature.is_fainted():
		name_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.4))
	row.add_child(name_label)

	# Level
	var level_label := Label.new()
	level_label.text = "Lv.%d" % creature.level
	level_label.custom_minimum_size = Vector2(40, 0)
	row.add_child(level_label)

	# Element badge
	var element_badge := ThemeManager.create_element_badge(creature.data.element)
	element_badge.custom_minimum_size = Vector2(35, 0)
	row.add_child(element_badge)

	# Mini HP bar
	var hp_bar := ProgressBar.new()
	hp_bar.max_value = creature.max_hp()
	hp_bar.value = creature.current_hp
	hp_bar.custom_minimum_size = Vector2(60, 8)
	hp_bar.show_percentage = false
	var ratio := float(creature.current_hp) / float(max(1, creature.max_hp()))
	var bar_color := ThemeManager.COL_ACCENT_GREEN if ratio > 0.5 else (Color(0.9, 0.8, 0.1) if ratio > 0.25 else ThemeManager.COL_ACCENT_RED)
	var fill := StyleBoxFlat.new()
	fill.bg_color = bar_color
	fill.set_corner_radius_all(2)
	fill.content_margin_left = 0.0
	fill.content_margin_right = 0.0
	fill.content_margin_top = 0.0
	fill.content_margin_bottom = 0.0
	hp_bar.add_theme_stylebox_override("fill", fill)
	row.add_child(hp_bar)

	# HP numbers
	var hp_label := Label.new()
	hp_label.text = "%d/%d" % [creature.current_hp, creature.max_hp()]
	hp_label.add_theme_font_size_override("font_size", 8)
	hp_label.custom_minimum_size = Vector2(50, 0)
	row.add_child(hp_label)

	container.add_child(row)

	# Fainted label
	if creature.is_fainted():
		var fainted := Label.new()
		fainted.text = "FAINTED"
		fainted.add_theme_font_size_override("font_size", 8)
		fainted.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_RED)
		container.add_child(fainted)

	# Skills row
	var skills_row := HBoxContainer.new()
	var skills_label := Label.new()
	var skill_names: Array[String] = []
	var skills := creature.active_skills if creature.active_skills.size() > 0 else creature.data.skills
	for s in skills:
		var sd: SkillData = s as SkillData
		if sd:
			skill_names.append(sd.skill_name)
	skills_label.text = "  Skills: %s" % ", ".join(skill_names)
	skills_label.add_theme_font_size_override("font_size", 8)
	skills_label.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	skills_row.add_child(skills_label)
	container.add_child(skills_row)

	# Held item row + equip button
	var held_row := HBoxContainer.new()
	var held_label := Label.new()
	if creature.held_item:
		held_label.text = "  Held: %s" % creature.held_item.item_name
	else:
		held_label.text = "  Held: (none)"
	held_label.custom_minimum_size = Vector2(200, 0)
	held_label.add_theme_font_size_override("font_size", 8)
	held_label.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	held_row.add_child(held_label)

	var equip_btn := Button.new()
	equip_btn.text = "Equip" if not creature.held_item else "Unequip"
	equip_btn.custom_minimum_size = Vector2(55, 20)
	equip_btn.add_theme_font_size_override("font_size", 8)
	var creature_ref := creature
	equip_btn.pressed.connect(func(): _toggle_held_item(creature_ref))
	held_row.add_child(equip_btn)
	container.add_child(held_row)

	return card

func _toggle_held_item(creature: CreatureInstance) -> void:
	if creature.held_item:
		InventoryManager.add_item(creature.held_item.item_name)
		creature.held_item = null
		_refresh_list()
	else:
		_show_held_item_selection(creature)

func _show_held_item_selection(creature: CreatureInstance) -> void:
	for child in creature_list.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "Select held item for %s:" % creature.display_name()
	creature_list.add_child(title)

	var found_any := false
	for item_name in InventoryManager.items:
		var data := InventoryManager.get_item_data(item_name)
		if data and data.item_type == ItemData.ItemType.HELD_ITEM and InventoryManager.items[item_name] > 0:
			found_any = true
			var btn := Button.new()
			btn.text = "%s - %s" % [item_name, data.description]
			btn.custom_minimum_size = Vector2(0, 28)
			var item_ref := item_name
			var creature_ref := creature
			btn.pressed.connect(func(): _equip_item(creature_ref, item_ref))
			creature_list.add_child(btn)

	if not found_any:
		var lbl := Label.new()
		lbl.text = "No held items in inventory."
		creature_list.add_child(lbl)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 28)
	back_btn.pressed.connect(func(): _refresh_list())
	creature_list.add_child(back_btn)

func _equip_item(creature: CreatureInstance, item_name: String) -> void:
	if InventoryManager.remove_item(item_name):
		var data := InventoryManager.get_item_data(item_name)
		if data:
			if creature.held_item:
				InventoryManager.add_item(creature.held_item.item_name)
			creature.held_item = data
	_refresh_list()

func _has_damaged_creatures() -> bool:
	for creature in PartyManager.party:
		if creature.current_hp < creature.max_hp() or creature.is_fainted():
			return true
	return false

func _has_healing_items() -> bool:
	if not InventoryManager:
		return false
	for item_name in InventoryManager.items:
		if InventoryManager.items[item_name] <= 0:
			continue
		var data := InventoryManager.get_item_data(item_name)
		if data and (data.item_type == ItemData.ItemType.POTION or data.item_type == ItemData.ItemType.REVIVE):
			return true
	return false

func _on_heal_all() -> void:
	var potions_used := 0
	var revives_used := 0

	for creature in PartyManager.party:
		if creature.is_fainted():
			if InventoryManager.remove_item("Revive"):
				creature.current_hp = max(1, int(creature.max_hp() * 0.5))
				revives_used += 1

		while creature.current_hp < creature.max_hp() and not creature.is_fainted():
			var healed := false
			for potion_name in ["Max Potion", "Super Potion", "Potion"]:
				var data := InventoryManager.get_item_data(potion_name)
				if data and InventoryManager.remove_item(potion_name):
					var heal_amount := data.effect_value
					if heal_amount >= 999:
						heal_amount = creature.max_hp()
					creature.heal(heal_amount)
					potions_used += 1
					healed = true
					break
			if not healed:
				break

	AudioManager.play_sound(AudioManager.SFX.USE_POTION)
	for child in creature_list.get_children():
		child.queue_free()
	var summary := Label.new()
	var parts: Array[String] = []
	if potions_used > 0:
		parts.append("Used %d Potion(s)" % potions_used)
	if revives_used > 0:
		parts.append("Used %d Revive(s)" % revives_used)
	if parts.is_empty():
		summary.text = "No healing needed!"
	else:
		summary.text = "%s. All creatures healed!" % ". ".join(parts)
	creature_list.add_child(summary)

	await get_tree().create_timer(1.5).timeout
	if _is_open:
		_refresh_list()
