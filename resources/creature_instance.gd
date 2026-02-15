class_name CreatureInstance
extends Resource

## A specific caught/active creature with its own level, HP, nickname, etc.

@export var data: CreatureData  # Reference to species template
@export var nickname: String = ""
@export var level: int = 1
@export var current_hp: int = 1
@export var exp: int = 0
@export var is_nft: bool = false
@export var nft_token_id: int = -1

func _init(p_data: CreatureData = null, p_level: int = 1) -> void:
	if p_data:
		data = p_data
		level = p_level
		current_hp = max_hp()
		nickname = p_data.species_name

func display_name() -> String:
	return nickname if nickname != "" else data.species_name

func max_hp() -> int:
	return data.hp_at_level(level)

func attack() -> int:
	return data.attack_at_level(level)

func defense() -> int:
	return data.defense_at_level(level)

func speed() -> int:
	return data.speed_at_level(level)

func is_fainted() -> bool:
	return current_hp <= 0

func heal_full() -> void:
	current_hp = max_hp()

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)

## EXP needed to reach next level (simple formula).
func exp_to_next_level() -> int:
	return level * 25

## Gain EXP. Returns true if leveled up.
func gain_exp(amount: int) -> bool:
	exp += amount
	var leveled_up := false
	while exp >= exp_to_next_level():
		exp -= exp_to_next_level()
		level += 1
		var old_max := max_hp()
		# Heal proportionally on level up
		current_hp = min(current_hp + int(old_max * 0.3), max_hp())
		leveled_up = true
	return leveled_up
