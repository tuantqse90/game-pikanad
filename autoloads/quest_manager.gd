extends Node

## QuestManager — daily quest tracking with 3 randomly selected quests per day.

signal quest_updated(quest_index: int)
signal quest_completed(quest_index: int)

const QUEST_POOL := [
	{"id": "catch_3", "desc": "Catch 3 creatures", "type": "catch", "target": 3, "gold": 200, "item": ""},
	{"id": "win_2", "desc": "Win 2 battles", "type": "win_battle", "target": 2, "gold": 150, "item": "Potion"},
	{"id": "explore_2", "desc": "Explore 2 zones", "type": "explore_zone", "target": 2, "gold": 100, "item": "Capture Ball"},
	{"id": "evolve_1", "desc": "Evolve 1 creature", "type": "evolve", "target": 1, "gold": 300, "item": ""},
]

var active_quests: Array[Dictionary] = []
var quest_date: String = ""

func _ready() -> void:
	check_new_day()

func check_new_day() -> void:
	var today := Time.get_date_string_from_system()
	if today != quest_date:
		_generate_daily_quests(today)

func _generate_daily_quests(date: String) -> void:
	quest_date = date
	active_quests.clear()
	# Use date as seed for consistent daily quests
	var date_seed := date.hash()
	var rng := RandomNumberGenerator.new()
	rng.seed = date_seed
	# Pick 3 unique quests from pool
	var pool := QUEST_POOL.duplicate()
	var count := mini(3, pool.size())
	for i in count:
		var idx := rng.randi() % pool.size()
		var quest_template: Dictionary = pool[idx]
		active_quests.append({
			"id": quest_template["id"],
			"desc": quest_template["desc"],
			"type": quest_template["type"],
			"progress": 0,
			"target": quest_template["target"],
			"completed": false,
			"claimed": false,
			"gold": quest_template["gold"],
			"item": quest_template["item"],
		})
		pool.remove_at(idx)

func increment_quest(type: String) -> void:
	for i in active_quests.size():
		var quest: Dictionary = active_quests[i]
		if quest["type"] == type and not quest["completed"]:
			quest["progress"] = mini(quest["progress"] + 1, quest["target"])
			if quest["progress"] >= quest["target"]:
				quest["completed"] = true
				quest_completed.emit(i)
			quest_updated.emit(i)

func claim_quest(index: int) -> void:
	if index < 0 or index >= active_quests.size():
		return
	var quest: Dictionary = active_quests[index]
	if not quest["completed"] or quest["claimed"]:
		return
	quest["claimed"] = true
	# Grant rewards
	if InventoryManager:
		InventoryManager.add_gold(quest["gold"])
		if quest["item"] != "":
			InventoryManager.add_item(quest["item"])

func get_active_quests() -> Array[Dictionary]:
	return active_quests

func serialize() -> Dictionary:
	return {
		"active_quests": active_quests.duplicate(true),
		"quest_date": quest_date,
	}

func deserialize(data: Dictionary) -> void:
	quest_date = data.get("quest_date", "")
	var quests_data: Array = data.get("active_quests", [])
	active_quests.clear()
	for q in quests_data:
		active_quests.append(q)
	check_new_day()
