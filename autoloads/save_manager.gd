extends Node

## SaveManager — handles local save/load. Uses user:// which maps to
## IndexedDB on web (persistent across sessions).

const SAVE_PATH := "user://save_data.json"

func save_game() -> void:
	var save_data := {
		"gold": InventoryManager.gold,
		"items": InventoryManager.items.duplicate(),
		"capture_balls": GameManager.capture_items,
		"party": _serialize_party(),
	}

	var json_str := JSON.stringify(save_data)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var json_str := file.get_as_text()
	var json := JSON.new()
	if json.parse(json_str) != OK:
		return false

	if not json.data is Dictionary:
		return false
	var data: Dictionary = json.data

	# Restore gold and items
	InventoryManager.gold = data.get("gold", 0)
	InventoryManager.items = data.get("items", {})
	GameManager.capture_items = data.get("capture_balls", 5)

	# Restore party
	_deserialize_party(data.get("party", []))

	return true

func _serialize_party() -> Array:
	var result := []
	for creature in PartyManager.party:
		result.append({
			"species_path": creature.data.resource_path,
			"nickname": creature.nickname,
			"level": creature.level,
			"current_hp": creature.current_hp,
			"exp": creature.exp,
			"is_nft": creature.is_nft,
			"nft_token_id": creature.nft_token_id,
		})
	return result

func _deserialize_party(party_data: Array) -> void:
	PartyManager.party.clear()
	for entry in party_data:
		var species_data: CreatureData = load(entry.get("species_path", ""))
		if not species_data:
			continue
		var creature := CreatureInstance.new(species_data, entry.get("level", 1))
		creature.nickname = entry.get("nickname", "")
		creature.current_hp = entry.get("current_hp", creature.max_hp())
		creature.exp = entry.get("exp", 0)
		creature.is_nft = entry.get("is_nft", false)
		creature.nft_token_id = entry.get("nft_token_id", -1)
		PartyManager.party.append(creature)
	PartyManager.party_changed.emit()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
