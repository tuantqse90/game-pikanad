extends Node

## SaveManager — handles local save/load. Uses user:// which maps to
## IndexedDB on web (persistent across sessions).

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 3

func save_game() -> void:
	var save_data := {
		"save_version": SAVE_VERSION,
		"gold": InventoryManager.gold,
		"items": InventoryManager.items.duplicate(),
		"party": _serialize_party(),
		"dex": DexManager.serialize(),
		"badges": BadgeManager.serialize(),
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

	var version := int(data.get("save_version", 1))
	if version < SAVE_VERSION:
		data = _migrate_save(data, version)

	# Restore gold and items
	InventoryManager.gold = data.get("gold", 0)
	InventoryManager.items = data.get("items", {})

	# Restore party
	_deserialize_party(data.get("party", []))

	# Restore dex
	if data.has("dex") and DexManager:
		DexManager.deserialize(data["dex"])

	# Restore badges
	if data.has("badges") and BadgeManager:
		BadgeManager.deserialize(data["badges"])

	return true

func _serialize_party() -> Array:
	var result := []
	for creature in PartyManager.party:
		var entry := {
			"species_path": creature.data.resource_path,
			"nickname": creature.nickname,
			"level": creature.level,
			"current_hp": creature.current_hp,
			"exp": creature.exp,
			"is_nft": creature.is_nft,
			"nft_token_id": creature.nft_token_id,
		}
		# Save active skills
		var skill_paths: Array = []
		for skill in creature.active_skills:
			if skill:
				skill_paths.append(skill.resource_path)
		entry["active_skills"] = skill_paths
		# Save held item
		if creature.held_item:
			entry["held_item_path"] = creature.held_item.resource_path
		result.append(entry)
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

		# Restore active skills
		var skill_paths: Array = entry.get("active_skills", [])
		if skill_paths.size() > 0:
			creature.active_skills.clear()
			for path in skill_paths:
				var skill := load(path)
				if skill:
					creature.active_skills.append(skill)

		# Restore held item
		var held_path: String = entry.get("held_item_path", "")
		if held_path != "":
			creature.held_item = load(held_path) as ItemData

		PartyManager.party.append(creature)
	PartyManager.party_changed.emit()

## Migrate old save format to current version.
func _migrate_save(data: Dictionary, from_version: int) -> Dictionary:
	if from_version < 2:
		# v1 -> v2: Convert capture_balls counter to inventory items
		var old_balls := int(data.get("capture_balls", 0))
		var items: Dictionary = data.get("items", {})
		if old_balls > 0:
			items["Capture Ball"] = items.get("Capture Ball", 0) + old_balls
		data["items"] = items
		data.erase("capture_balls")

		# Seed dex from party creatures
		var dex_data := {}
		var party: Array = data.get("party", [])
		for entry in party:
			var species_path: String = entry.get("species_path", "")
			if species_path != "":
				var species := load(species_path) as CreatureData
				if species:
					dex_data[str(species.species_id)] = DexManager.DexStatus.CAUGHT
		data["dex"] = dex_data
		data["save_version"] = 2

	if from_version < 3:
		# v2 -> v3: Add empty badges and defeated_trainers
		data["badges"] = {
			"badges": [false, false, false, false, false, false, false, false],
			"defeated_trainers": {},
		}
		data["save_version"] = 3

	return data

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
