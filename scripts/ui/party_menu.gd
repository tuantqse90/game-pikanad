extends CanvasLayer

## Party menu overlay — shows creature list with stats, held items, and skills.

@onready var panel: PanelContainer = $Panel
@onready var creature_list: VBoxContainer = $Panel/VBoxContainer/CreatureList
@onready var close_btn: Button = $Panel/VBoxContainer/CloseBtn

var _is_open := false

func _ready() -> void:
	panel.visible = false
	close_btn.pressed.connect(close_menu)

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
	# Clear existing entries
	for child in creature_list.get_children():
		child.queue_free()

	if PartyManager.party.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No creatures in party."
		creature_list.add_child(empty_label)
		return

	# Quick Heal button — only show if party is damaged and has healing items
	if _has_damaged_creatures() and _has_healing_items():
		var heal_btn := Button.new()
		heal_btn.text = "Heal All"
		heal_btn.custom_minimum_size = Vector2(0, 30)
		heal_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		heal_btn.pressed.connect(_on_heal_all)
		creature_list.add_child(heal_btn)
		var sep := HSeparator.new()
		creature_list.add_child(sep)

	for creature in PartyManager.party:
		var entry := _create_entry(creature)
		creature_list.add_child(entry)

func _create_entry(creature: CreatureInstance) -> VBoxContainer:
	var container := VBoxContainer.new()

	# Top row: name, level, HP, element
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 24)

	var name_label := Label.new()
	name_label.text = creature.display_name()
	name_label.custom_minimum_size = Vector2(100, 0)
	row.add_child(name_label)

	var level_label := Label.new()
	level_label.text = "Lv.%d" % creature.level
	level_label.custom_minimum_size = Vector2(45, 0)
	row.add_child(level_label)

	var hp_label := Label.new()
	hp_label.text = "HP: %d/%d" % [creature.current_hp, creature.max_hp()]
	hp_label.custom_minimum_size = Vector2(85, 0)
	row.add_child(hp_label)

	var element_names := ["Fire", "Water", "Grass", "Wind", "Earth", "Neutral"]
	var type_label := Label.new()
	type_label.text = element_names[creature.data.element]
	type_label.custom_minimum_size = Vector2(50, 0)
	row.add_child(type_label)

	container.add_child(row)

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
	skills_label.add_theme_font_size_override("font_size", 10)
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
	held_label.add_theme_font_size_override("font_size", 10)
	held_row.add_child(held_label)

	var equip_btn := Button.new()
	equip_btn.text = "Equip" if not creature.held_item else "Unequip"
	equip_btn.custom_minimum_size = Vector2(60, 22)
	var creature_ref := creature
	equip_btn.pressed.connect(func(): _toggle_held_item(creature_ref))
	held_row.add_child(equip_btn)
	container.add_child(held_row)

	# Separator
	var sep := HSeparator.new()
	container.add_child(sep)

	return container

func _toggle_held_item(creature: CreatureInstance) -> void:
	if creature.held_item:
		# Unequip: return item to inventory
		InventoryManager.add_item(creature.held_item.item_name)
		creature.held_item = null
		_refresh_list()
	else:
		# Show held item selection
		_show_held_item_selection(creature)

func _show_held_item_selection(creature: CreatureInstance) -> void:
	# Clear and show available held items from inventory
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
			# Return old held item if any
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
	# Check for potions and revives
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
		# Revive fainted creatures first
		if creature.is_fainted():
			if InventoryManager.remove_item("Revive"):
				creature.current_hp = max(1, int(creature.max_hp() * 0.5))
				revives_used += 1

		# Heal damaged creatures with best available potion
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
	# Show summary then refresh
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

	# Auto-refresh after a moment
	await get_tree().create_timer(1.5).timeout
	if _is_open:
		_refresh_list()
