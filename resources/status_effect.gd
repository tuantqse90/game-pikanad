class_name StatusEffect
extends Resource

## Runtime status effect applied to a creature during battle.

enum Type { NONE, BURN, POISON, SLEEP, PARALYZE, SHIELD }

@export var type: Type = Type.NONE
@export var remaining_turns: int = 0

func _init(p_type: Type = Type.NONE, p_duration: int = 0) -> void:
	type = p_type
	remaining_turns = p_duration

## Decrement remaining turns. Returns true if expired.
func tick() -> bool:
	if type == Type.NONE:
		return true
	remaining_turns -= 1
	if remaining_turns <= 0:
		type = Type.NONE
		remaining_turns = 0
		return true
	return false

func is_active() -> bool:
	return type != Type.NONE

func get_status_name() -> String:
	match type:
		Type.BURN: return "Burn"
		Type.POISON: return "Poison"
		Type.SLEEP: return "Sleep"
		Type.PARALYZE: return "Paralyze"
		Type.SHIELD: return "Shield"
		_: return ""
