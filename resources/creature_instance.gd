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
@export var is_shiny: bool = false

const SHINY_RATE := 1.0 / 200.0
const SHINY_CHARM_RATE := 1.0 / 50.0

# Active skills (up to 4 slots)
@export var active_skills: Array[Resource] = []

# Held item
@export var held_item: ItemData

# Runtime battle modifiers (not saved)
var status: StatusEffect = StatusEffect.new()
var atk_modifier: float = 0.0
var def_modifier: float = 0.0
var spd_modifier: float = 0.0
var is_protecting: bool = false

func _init(p_data: CreatureData = null, p_level: int = 1) -> void:
	if p_data:
		data = p_data
		level = p_level
		current_hp = max_hp()
		nickname = p_data.species_name
		_init_skills_for_level()

func display_name() -> String:
	if not data:
		return nickname if nickname != "" else "???"
	return nickname if nickname != "" else data.species_name

func max_hp() -> int:
	if not data:
		return 1
	return data.hp_at_level(level)

func attack() -> int:
	if not data:
		return 1
	var base := data.attack_at_level(level)
	var modified := base * (1.0 + atk_modifier)
	# Apply held item bonus
	if held_item and held_item.held_effect == ItemData.HeldEffect.BOOST_ATK:
		modified *= (1.0 + held_item.held_boost_percent)
	return max(1, int(modified))

func defense() -> int:
	if not data:
		return 1
	var base := data.defense_at_level(level)
	var modified := base * (1.0 + def_modifier)
	# Shield status gives +50% DEF
	if status.is_active() and status.type == StatusEffect.Type.SHIELD:
		modified *= 1.5
	# Apply held item bonus
	if held_item and held_item.held_effect == ItemData.HeldEffect.BOOST_DEF:
		modified *= (1.0 + held_item.held_boost_percent)
	return max(1, int(modified))

func speed() -> int:
	if not data:
		return 1
	var base := data.speed_at_level(level)
	var modified := base * (1.0 + spd_modifier)
	# Apply held item bonus
	if held_item and held_item.held_effect == ItemData.HeldEffect.BOOST_SPD:
		modified *= (1.0 + held_item.held_boost_percent)
	return max(1, int(modified))

func is_fainted() -> bool:
	return current_hp <= 0

func heal_full() -> void:
	current_hp = max_hp()
	status = StatusEffect.new()

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)

func heal(amount: int) -> void:
	current_hp = min(max_hp(), current_hp + amount)

## EXP needed to reach next level (simple formula).
func exp_to_next_level() -> int:
	return level * 25

## Get the current level cap based on badge progress.
func _get_level_cap() -> int:
	if BadgeManager and BadgeManager.has_badge(5):
		return 50
	return 30

## Gain EXP. Returns true if leveled up.
func gain_exp(amount: int) -> bool:
	var cap := _get_level_cap()
	if level >= cap:
		return false
	exp += amount
	var leveled_up := false
	while exp >= exp_to_next_level() and level < cap:
		exp -= exp_to_next_level()
		var old_max := max_hp()  # Capture BEFORE level up
		level += 1
		# Heal proportionally on level up
		current_hp = min(current_hp + int(old_max * 0.3), max_hp())
		leveled_up = true
	return leveled_up

## Initialize active_skills from learn_set up to current level, fallback to data.skills.
func _init_skills_for_level() -> void:
	if not data:
		return

	# Gather all skills from learn_set at or below current level
	var learned: Array[Resource] = []
	if data.learn_set.size() > 0:
		# Sort learn_set by level
		var sorted_set := data.learn_set.duplicate()
		sorted_set.sort_custom(func(a, b): return a.get("level", 0) < b.get("level", 0))
		for entry in sorted_set:
			var req_level: int = entry.get("level", 1)
			if req_level <= level:
				var skill_path: String = entry.get("skill_path", "")
				if skill_path != "":
					var skill := load(skill_path)
					if skill:
						learned.append(skill)

	if learned.size() > 0:
		# Take the last 4 skills (most recently learned)
		var start: int = max(0, learned.size() - 4)
		active_skills = learned.slice(start)
	else:
		# Fallback to data.skills
		active_skills = data.skills.duplicate()

## Check if creature can evolve at current level (excludes trade-evolution creatures).
func can_evolve() -> bool:
	if not data:
		return false
	if data.trade_evolution:
		return false  # Trade-evo creatures only evolve via trading
	if data.evolution_level <= 0 or not data.evolves_into:
		return false
	if level < data.evolution_level:
		return false
	# Check for Everstone
	if held_item and held_item.held_effect == ItemData.HeldEffect.PREVENT_EVOLUTION:
		return false
	return true

## Check if creature can evolve via trade.
func can_trade_evolve() -> bool:
	if not data:
		return false
	if not data.trade_evolution or not data.evolves_into:
		return false
	# Check for Everstone
	if held_item and held_item.held_effect == ItemData.HeldEffect.PREVENT_EVOLUTION:
		return false
	return true

## Perform evolution. Swaps data to evolved species, preserves HP ratio and NFT info.
func evolve() -> void:
	if not can_evolve():
		return
	var hp_ratio := float(current_hp) / float(max(1, max_hp()))
	var old_nft := is_nft
	var old_token := nft_token_id
	var old_nickname := nickname
	var was_default_name := (nickname == data.species_name)

	data = data.evolves_into
	current_hp = max(1, int(max_hp() * hp_ratio))
	is_nft = old_nft
	nft_token_id = old_token
	if was_default_name:
		nickname = data.species_name
	# Re-init skills for new species
	_init_skills_for_level()
	# Track quest/stats
	QuestManager.increment_quest("evolve")
	StatsManager.increment("creatures_evolved")

## Perform trade evolution. Same as evolve() but for trade-evo species.
func trade_evolve() -> void:
	if not can_trade_evolve():
		return
	var hp_ratio := float(current_hp) / float(max(1, max_hp()))
	var old_nft := is_nft
	var old_token := nft_token_id
	var old_nickname := nickname
	var was_default_name := (nickname == data.species_name)

	data = data.evolves_into
	current_hp = max(1, int(max_hp() * hp_ratio))
	is_nft = old_nft
	nft_token_id = old_token
	if was_default_name:
		nickname = data.species_name
	_init_skills_for_level()
	QuestManager.increment_quest("evolve")
	StatsManager.increment("creatures_evolved")

## Get skills the creature should learn at its current level (not yet in active_skills).
func get_pending_new_skills() -> Array[Resource]:
	if not data:
		return []
	var pending: Array[Resource] = []
	for entry in data.learn_set:
		var req_level: int = entry.get("level", 0)
		if req_level == level:
			var skill_path: String = entry.get("skill_path", "")
			if skill_path == "":
				continue
			var skill := load(skill_path)
			if not skill:
				continue
			# Check if already known
			var already_known := false
			for s in active_skills:
				if s and s.resource_path == skill.resource_path:
					already_known = true
					break
			if not already_known:
				pending.append(skill)
	return pending

## Try to learn a new skill. Returns true if auto-learned (had empty slot).
func try_learn_skill(skill: Resource) -> bool:
	if active_skills.size() < 4:
		active_skills.append(skill)
		return true
	return false  # Must choose a slot to replace

## Replace skill at given index with new skill.
func replace_skill(index: int, new_skill: Resource) -> void:
	if index >= 0 and index < active_skills.size():
		active_skills[index] = new_skill

## Roll whether this creature is shiny. Uses Shiny Charm rate if unlocked.
func roll_shiny() -> void:
	var rate := SHINY_RATE
	if DexManager and DexManager.has_meta("has_shiny_charm"):
		rate = SHINY_CHARM_RATE
	is_shiny = randf() < rate

## Reset battle-only modifiers (call after battle ends).
func reset_battle_modifiers() -> void:
	status = StatusEffect.new()
	atk_modifier = 0.0
	def_modifier = 0.0
	spd_modifier = 0.0
	is_protecting = false
