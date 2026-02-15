extends Node

## Manages gym badges, defeated trainers, and zone access gating.

signal badge_earned(badge_number: int)

const BADGE_NAMES := ["Sprout", "Blaze", "Tide", "Grove", "Rumble", "Tempest", "Obsidian", "Champion"]

var badges: Array[bool] = [false, false, false, false, false, false, false, false]
var defeated_trainers: Dictionary = {}  # trainer_id -> true

func earn_badge(number: int) -> void:
	if number < 1 or number > 8:
		return
	badges[number - 1] = true
	badge_earned.emit(number)

func has_badge(number: int) -> bool:
	if number < 1 or number > 8:
		return false
	return badges[number - 1]

func badge_count() -> int:
	var count := 0
	for b in badges:
		if b:
			count += 1
	return count

func can_access_zone(zone_name: String) -> bool:
	match zone_name:
		"Sky Peaks":
			return has_badge(5)
		"Lava Core":
			return has_badge(6)
		"Champion Arena":
			return badge_count() >= 7
	return true

func mark_defeated(trainer_id: String) -> void:
	defeated_trainers[trainer_id] = true

func is_defeated(trainer_id: String) -> bool:
	return defeated_trainers.has(trainer_id)

func serialize() -> Dictionary:
	return {
		"badges": badges.duplicate(),
		"defeated_trainers": defeated_trainers.duplicate(),
	}

func deserialize(data: Dictionary) -> void:
	var saved_badges: Array = data.get("badges", [])
	for i in range(min(saved_badges.size(), 8)):
		badges[i] = bool(saved_badges[i])
	defeated_trainers = data.get("defeated_trainers", {})

func reset() -> void:
	badges = [false, false, false, false, false, false, false, false]
	defeated_trainers.clear()
