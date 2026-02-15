extends CanvasLayer

## Party menu overlay — shows creature list with stats.

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

	for creature in PartyManager.party:
		var entry := _create_entry(creature)
		creature_list.add_child(entry)

func _create_entry(creature: CreatureInstance) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 30)

	var name_label := Label.new()
	name_label.text = creature.display_name()
	name_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_label)

	var level_label := Label.new()
	level_label.text = "Lv.%d" % creature.level
	level_label.custom_minimum_size = Vector2(50, 0)
	row.add_child(level_label)

	var hp_label := Label.new()
	hp_label.text = "HP: %d/%d" % [creature.current_hp, creature.max_hp()]
	hp_label.custom_minimum_size = Vector2(100, 0)
	row.add_child(hp_label)

	var element_names := ["Fire", "Water", "Grass", "Wind", "Earth"]
	var type_label := Label.new()
	type_label.text = element_names[creature.data.element]
	type_label.custom_minimum_size = Vector2(60, 0)
	row.add_child(type_label)

	return row
