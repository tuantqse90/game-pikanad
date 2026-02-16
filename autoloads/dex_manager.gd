extends Node

## Creature Dex Manager — tracks seen/caught status for all species.

signal dex_updated(species_id: int)
signal reward_earned(reward_name: String)

enum DexStatus { UNSEEN, SEEN, CAUGHT }

# species_id -> DexStatus
var entries: Dictionary = {}

# Total species count (updated as creatures are discovered)
const TOTAL_SPECIES := 17

func mark_seen(species_id: int) -> void:
	if not entries.has(species_id) or entries[species_id] == DexStatus.UNSEEN:
		entries[species_id] = DexStatus.SEEN
		dex_updated.emit(species_id)

func mark_caught(species_id: int) -> void:
	entries[species_id] = DexStatus.CAUGHT
	dex_updated.emit(species_id)
	check_rewards()

func get_status(species_id: int) -> DexStatus:
	return entries.get(species_id, DexStatus.UNSEEN)

func get_caught_count() -> int:
	var count := 0
	for status in entries.values():
		if status == DexStatus.CAUGHT:
			count += 1
	return count

func get_seen_count() -> int:
	var count := 0
	for status in entries.values():
		if status >= DexStatus.SEEN:
			count += 1
	return count

func get_completion_percent() -> float:
	return float(get_caught_count()) / float(TOTAL_SPECIES) * 100.0

func check_rewards() -> void:
	var caught := get_caught_count()
	var thresholds := {
		int(TOTAL_SPECIES * 0.25): "Master Ball",
		int(TOTAL_SPECIES * 0.50): "Shiny Charm",
		int(TOTAL_SPECIES * 0.75): "EXP Charm",
		TOTAL_SPECIES: "Crown",
	}
	for threshold in thresholds:
		if caught >= threshold:
			var reward_name: String = thresholds[threshold]
			var reward_key := "dex_reward_%d" % threshold
			if not has_meta(reward_key):
				set_meta(reward_key, true)
				reward_earned.emit(reward_name)
				_grant_reward(reward_name)

func _grant_reward(reward_name: String) -> void:
	match reward_name:
		"Master Ball":
			if InventoryManager:
				InventoryManager.add_item("Master Ball", 1)
				InventoryManager.register_item("Master Ball", "res://resources/items/master_ball.tres")
		"Shiny Charm":
			set_meta("has_shiny_charm", true)

func serialize() -> Dictionary:
	var data := {}
	for species_id in entries:
		data[str(species_id)] = entries[species_id]
	# Save granted reward flags
	var rewards := []
	for threshold in [int(TOTAL_SPECIES * 0.25), int(TOTAL_SPECIES * 0.50), int(TOTAL_SPECIES * 0.75), TOTAL_SPECIES]:
		var reward_key := "dex_reward_%d" % threshold
		if has_meta(reward_key):
			rewards.append(threshold)
	data["_granted_rewards"] = rewards
	return data

func deserialize(data: Dictionary) -> void:
	entries.clear()
	var granted_rewards: Array = data.get("_granted_rewards", [])
	for key in data:
		if key == "_granted_rewards":
			continue
		var species_id := int(key)
		entries[species_id] = int(data[key])
	# Restore reward flags
	for threshold in granted_rewards:
		var reward_key := "dex_reward_%d" % int(threshold)
		set_meta(reward_key, true)
	# Restore Shiny Charm flag if 50% reward was earned
	var charm_threshold := int(TOTAL_SPECIES * 0.50)
	if has_meta("dex_reward_%d" % charm_threshold):
		set_meta("has_shiny_charm", true)
