extends Node

## Manages the player's creature party (max 6).

signal party_changed

const MAX_PARTY_SIZE := 6
var party: Array[CreatureInstance] = []

func add_creature(creature: CreatureInstance) -> bool:
	if party.size() >= MAX_PARTY_SIZE:
		return false
	party.append(creature)
	party_changed.emit()
	return true

func remove_creature(index: int) -> void:
	if index >= 0 and index < party.size():
		party.remove_at(index)
		party_changed.emit()

func get_first_alive() -> CreatureInstance:
	for c in party:
		if not c.is_fainted():
			return c
	return null

func has_alive_creature() -> bool:
	return get_first_alive() != null

func party_size() -> int:
	return party.size()

func heal_all() -> void:
	for c in party:
		c.heal_full()
	party_changed.emit()

## Give the player a starter creature.
func give_starter(creature_data: CreatureData, level: int = 5) -> void:
	var starter := CreatureInstance.new(creature_data, level)
	add_creature(starter)
