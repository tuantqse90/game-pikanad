extends Node

## Core turn-based battle state machine with status effects, items, evolution,
## trainer battles, and AI skill selection.

signal battle_message(text: String)
signal battle_state_changed(new_state: int)
signal battle_ended(result: String)  # "win", "lose", "run", "capture"
signal player_hp_changed(current: int, max_val: int)
signal enemy_hp_changed(current: int, max_val: int)
signal exp_gained(amount: int, leveled_up: bool)
signal player_attacked  # Player's creature attacks enemy
signal enemy_attacked  # Enemy attacks player's creature
signal effectiveness_text(text: String, effectiveness: float)
signal status_inflicted(target_name: String, status_name: String)
signal status_expired(target_name: String, status_name: String)
signal evolution_ready(creature: CreatureInstance)
signal skill_learned(creature: CreatureInstance, skill: Resource)
signal item_used(item_name: String)
signal trainer_defeated(trainer: TrainerData)
signal trainer_creature_switched(new_creature: CreatureInstance, remaining: int)

enum BattleState { START, PLAYER_TURN, PLAYER_ACTION, ENEMY_TURN, CHECK, WIN, LOSE, CAPTURE, RUN }

# Type effectiveness matrix: [attacker_element][defender_element] -> multiplier
# Elements: 0=Fire, 1=Water, 2=Grass, 3=Wind, 4=Earth, 5=Neutral
const TYPE_CHART := {
	0: { 0: 1.0, 1: 0.67, 2: 1.5,  3: 1.0, 4: 1.0, 5: 1.0 },   # Fire
	1: { 0: 1.5, 1: 1.0,  2: 0.67, 3: 1.0, 4: 1.0, 5: 1.0 },   # Water
	2: { 0: 0.67, 1: 1.5, 2: 1.0,  3: 1.0, 4: 1.0, 5: 1.0 },   # Grass
	3: { 0: 1.0, 1: 1.0,  2: 1.0,  3: 1.0, 4: 1.5, 5: 1.0 },   # Wind
	4: { 0: 1.0, 1: 1.0,  2: 1.0,  3: 0.67, 4: 1.0, 5: 1.0 },  # Earth
	5: { 0: 1.0, 1: 1.0,  2: 1.0,  3: 1.0, 4: 1.0, 5: 1.0 },   # Neutral
}

var state: BattleState = BattleState.START
var player_creature: CreatureInstance
var enemy_creature: CreatureInstance
var _enemy_data: CreatureData  # Keep reference for capture
var _pending_new_skills: Array[Resource] = []
var _pending_skill_creature: CreatureInstance

# Battle speed (1.0 = normal, 2.0 = fast)
var battle_speed: float = 1.0
signal speed_changed(speed: float)

# Trainer battle properties
var is_trainer_battle: bool = false
var trainer_data: TrainerData = null
var _trainer_party: Array[CreatureInstance] = []
var _trainer_party_index: int = 0

func start_battle() -> void:
	# Check if this is a trainer battle
	is_trainer_battle = GameManager.has_meta("is_trainer_battle") and GameManager.get_meta("is_trainer_battle")

	if is_trainer_battle:
		trainer_data = GameManager.get_meta("trainer_data") as TrainerData
		start_trainer_battle()
		return

	# Wild battle — retrieve battle data from GameManager
	_enemy_data = GameManager.get_meta("battle_creature_data") as CreatureData
	var enemy_level: int = GameManager.get_meta("battle_creature_level") as int

	enemy_creature = CreatureInstance.new(_enemy_data, enemy_level)
	player_creature = PartyManager.get_first_alive()

	if not player_creature:
		_change_state(BattleState.LOSE)
		return

	# Mark enemy as seen in dex
	if DexManager and _enemy_data:
		DexManager.mark_seen(_enemy_data.species_id)

	_change_state(BattleState.START)
	battle_message.emit("A wild %s (Lv.%d) appeared!" % [enemy_creature.display_name(), enemy_creature.level])
	_emit_hp()

	# Short delay then player turn
	await _delay(1.2)
	_change_state(BattleState.PLAYER_TURN)
	battle_message.emit("What will %s do?" % player_creature.display_name())

func start_trainer_battle() -> void:
	if not trainer_data:
		return

	# Build trainer party from TrainerData
	_trainer_party.clear()
	for entry in trainer_data.party:
		var species_path: String = entry.get("species_path", "")
		var lvl: int = entry.get("level", 5)
		var species: CreatureData = load(species_path) as CreatureData
		if species:
			var instance := CreatureInstance.new(species, lvl)
			_trainer_party.append(instance)
			# Mark species as seen in dex
			if DexManager:
				DexManager.mark_seen(species.species_id)

	if _trainer_party.is_empty():
		return

	_trainer_party_index = 0
	enemy_creature = _trainer_party[0]
	_enemy_data = enemy_creature.data
	player_creature = PartyManager.get_first_alive()

	if not player_creature:
		_change_state(BattleState.LOSE)
		return

	_change_state(BattleState.START)
	battle_message.emit("Leader %s wants to battle!" % trainer_data.trainer_name)
	_emit_hp()

	await _delay(1.2)
	battle_message.emit("Leader %s sent out %s (Lv.%d)!" % [trainer_data.trainer_name, enemy_creature.display_name(), enemy_creature.level])
	await _delay(1.0)
	_change_state(BattleState.PLAYER_TURN)
	battle_message.emit("What will %s do?" % player_creature.display_name())

func player_fight(skill_index: int) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	_change_state(BattleState.PLAYER_ACTION)

	var skills := player_creature.active_skills if player_creature.active_skills.size() > 0 else player_creature.data.skills
	if skill_index < 0 or skill_index >= skills.size():
		return
	var skill: SkillData = skills[skill_index] as SkillData

	# Check if player is paralyzed (25% chance to skip)
	if player_creature.status.is_active() and player_creature.status.type == StatusEffect.Type.PARALYZE:
		if randf() < 0.25:
			battle_message.emit("%s is paralyzed and can't move!" % player_creature.display_name())
			await _delay(1.0)
			_enemy_turn()
			return

	# Check if player is asleep
	if player_creature.status.is_active() and player_creature.status.type == StatusEffect.Type.SLEEP:
		var expired := player_creature.status.tick()
		if not expired:
			battle_message.emit("%s is fast asleep!" % player_creature.display_name())
			await _delay(1.0)
			_enemy_turn()
			return
		else:
			battle_message.emit("%s woke up!" % player_creature.display_name())
			status_expired.emit(player_creature.display_name(), "Sleep")
			await _delay(0.6)

	# Handle Protect
	if skill.is_protect:
		player_creature.is_protecting = true
		battle_message.emit("%s braced itself!" % player_creature.display_name())
		await _delay(1.0)
		_enemy_turn()
		return

	# Handle Roar (ends wild battle only)
	if skill.ends_wild_battle:
		if is_trainer_battle:
			battle_message.emit("%s used %s, but it failed against a trainer's creature!" % [player_creature.display_name(), skill.skill_name])
			await _delay(1.0)
			_enemy_turn()
			return
		battle_message.emit("%s used %s! The wild creature fled!" % [player_creature.display_name(), skill.skill_name])
		await _delay(1.0)
		_change_state(BattleState.RUN)
		battle_ended.emit("run")
		return

	# Handle skill by category
	match skill.category:
		SkillData.Category.HEAL:
			_execute_heal(player_creature, skill)
			await _delay(1.0)
			_enemy_turn()
		SkillData.Category.STATUS:
			_execute_status_skill(player_creature, enemy_creature, skill, true)
			await _delay(1.0)
			_enemy_turn()
		_:  # ATTACK
			_execute_attack(player_creature, enemy_creature, skill, true)
			_emit_hp()
			await _delay(1.0)
			_check_battle(true)

func _execute_attack(attacker: CreatureInstance, defender: CreatureInstance, skill: SkillData, is_player: bool) -> void:
	# Check if defender is protecting
	if defender.is_protecting:
		defender.is_protecting = false
		battle_message.emit("%s protected itself!" % defender.display_name())
		if is_player:
			player_attacked.emit()
		else:
			enemy_attacked.emit()
		return

	var damage := _calc_damage(attacker, defender, skill)
	var effectiveness := _get_effectiveness(skill.element, defender.data.element)

	if randf() <= skill.accuracy:
		defender.take_damage(damage)
		AudioManager.play_sound(AudioManager.SFX.ATTACK_HIT)
		if is_player:
			player_attacked.emit()
		else:
			enemy_attacked.emit()
		battle_message.emit("%s used %s! (%d dmg)" % [attacker.display_name(), skill.skill_name, damage])

		# Effectiveness text
		if effectiveness > 1.2:
			AudioManager.play_sound(AudioManager.SFX.SUPER_EFFECTIVE)
			effectiveness_text.emit("SUPER EFFECTIVE!", effectiveness)
			await _delay(0.6)
			battle_message.emit("It's super effective!")
		elif effectiveness < 0.8:
			AudioManager.play_sound(AudioManager.SFX.NOT_EFFECTIVE)
			effectiveness_text.emit("Not very effective...", effectiveness)
			await _delay(0.6)
			battle_message.emit("It's not very effective...")

		# Drain healing
		if skill.drain_percent > 0.0:
			var heal_amount := int(damage * skill.drain_percent)
			attacker.heal(heal_amount)
			battle_message.emit("%s drained %d HP!" % [attacker.display_name(), heal_amount])
			_emit_hp()

		# Status infliction
		if skill.inflicts_status != StatusEffect.Type.NONE and skill.status_chance > 0.0:
			if randf() <= skill.status_chance and not defender.status.is_active():
				defender.status = StatusEffect.new(skill.inflicts_status, skill.status_duration)
				var status_name := defender.status.get_status_name()
				battle_message.emit("%s was inflicted with %s!" % [defender.display_name(), status_name])
				status_inflicted.emit(defender.display_name(), status_name)

		# Self stat penalty
		if skill.self_stat_penalty != 0.0:
			attacker.def_modifier += skill.self_stat_penalty
			battle_message.emit("%s's defense dropped!" % attacker.display_name())

		# Self-inflicted status
		if skill.self_inflicts != StatusEffect.Type.NONE:
			attacker.status = StatusEffect.new(skill.self_inflicts, skill.self_status_duration)
			var status_name := attacker.status.get_status_name()
			battle_message.emit("%s inflicted %s on itself!" % [attacker.display_name(), status_name])
	else:
		AudioManager.play_sound(AudioManager.SFX.MISS)
		battle_message.emit("%s used %s but missed!" % [attacker.display_name(), skill.skill_name])

func _execute_heal(creature: CreatureInstance, skill: SkillData) -> void:
	var heal_amount := int(creature.max_hp() * skill.heal_percent)
	creature.heal(heal_amount)
	battle_message.emit("%s used %s and restored %d HP!" % [creature.display_name(), skill.skill_name, heal_amount])
	_emit_hp()

	# Self-inflicted status (e.g., Rest causes Sleep)
	if skill.self_inflicts != StatusEffect.Type.NONE:
		creature.status = StatusEffect.new(skill.self_inflicts, skill.self_status_duration)
		var status_name := creature.status.get_status_name()
		battle_message.emit("%s fell into %s!" % [creature.display_name(), status_name])

func _execute_status_skill(user: CreatureInstance, target: CreatureInstance, skill: SkillData, is_player: bool) -> void:
	if randf() > skill.accuracy:
		battle_message.emit("%s used %s but it failed!" % [user.display_name(), skill.skill_name])
		return

	battle_message.emit("%s used %s!" % [user.display_name(), skill.skill_name])

	# Buff self
	if skill.buff_stat != "" and skill.buff_duration > 0:
		match skill.buff_stat:
			"atk":
				user.atk_modifier += 0.25
				battle_message.emit("%s's attack rose!" % user.display_name())
			"def":
				user.def_modifier += 0.25
				battle_message.emit("%s's defense rose!" % user.display_name())
			"spd":
				user.spd_modifier += 0.25
				battle_message.emit("%s's speed rose!" % user.display_name())

	# Inflict status on target
	if skill.inflicts_status != StatusEffect.Type.NONE and skill.status_chance > 0.0:
		if randf() <= skill.status_chance and not target.status.is_active():
			target.status = StatusEffect.new(skill.inflicts_status, skill.status_duration)
			var status_name := target.status.get_status_name()
			battle_message.emit("%s was inflicted with %s!" % [target.display_name(), status_name])
			status_inflicted.emit(target.display_name(), status_name)

func player_use_item(item_name: String, target_creature: CreatureInstance = null) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	_change_state(BattleState.PLAYER_ACTION)

	var item_data := InventoryManager.get_item_data(item_name)
	if not item_data:
		_change_state(BattleState.PLAYER_TURN)
		return

	if not InventoryManager.remove_item(item_name):
		battle_message.emit("No %s left!" % item_name)
		await _delay(0.8)
		_change_state(BattleState.PLAYER_TURN)
		return

	var target := target_creature if target_creature else player_creature
	item_used.emit(item_name)

	AudioManager.play_sound(AudioManager.SFX.USE_POTION)

	match item_data.item_type:
		ItemData.ItemType.POTION:
			var heal_amount := item_data.effect_value
			if heal_amount >= 999:
				heal_amount = target.max_hp()
			target.heal(heal_amount)
			battle_message.emit("Used %s! %s recovered %d HP!" % [item_name, target.display_name(), heal_amount])
		ItemData.ItemType.STATUS_CURE:
			if target.status.is_active():
				var old_status := target.status.get_status_name()
				target.status = StatusEffect.new()
				battle_message.emit("Used %s! %s's %s was cured!" % [item_name, target.display_name(), old_status])
				status_expired.emit(target.display_name(), old_status)
			else:
				battle_message.emit("Used %s, but it had no effect." % item_name)
		ItemData.ItemType.REVIVE:
			if target.is_fainted():
				var revive_hp := int(target.max_hp() * item_data.effect_value / 100.0)
				target.current_hp = max(1, revive_hp)
				battle_message.emit("Used %s! %s was revived!" % [item_name, target.display_name()])
			else:
				battle_message.emit("Used %s, but it had no effect." % item_name)
				InventoryManager.add_item(item_name)  # Refund

	_emit_hp()
	await _delay(1.0)
	_enemy_turn()

func player_catch(ball_name: String = "Capture Ball") -> void:
	if state != BattleState.PLAYER_TURN:
		return

	# Can't catch trainer's creatures
	if is_trainer_battle:
		battle_message.emit("You can't catch a trainer's creature!")
		await _delay(1.0)
		return

	_change_state(BattleState.PLAYER_ACTION)

	if not InventoryManager.remove_item(ball_name):
		battle_message.emit("No %s left!" % ball_name)
		await _delay(0.8)
		_change_state(BattleState.PLAYER_TURN)
		return

	var ball_data := InventoryManager.get_item_data(ball_name)
	var multiplier := ball_data.catch_multiplier if ball_data else 1.0

	battle_message.emit("You threw a %s!" % ball_name)
	await _delay(1.0)

	# Capture formula: base_rate * multiplier * (1 + (1 - hp_ratio) * 1.5)
	var hp_ratio := float(enemy_creature.current_hp) / float(enemy_creature.max_hp())
	var catch_chance := _enemy_data.capture_rate * multiplier * (1.0 + (1.0 - hp_ratio) * 1.5)
	catch_chance = clamp(catch_chance, 0.05, 0.99)
	# Master Ball always catches
	if multiplier >= 100.0:
		catch_chance = 1.0

	AudioManager.play_sound(AudioManager.SFX.BALL_THROW)

	if randf() <= catch_chance:
		AudioManager.play_sound(AudioManager.SFX.CAPTURE_SUCCESS)
		_change_state(BattleState.CAPTURE)
		battle_message.emit("Gotcha! %s was captured!" % enemy_creature.display_name())
		var caught := CreatureInstance.new(_enemy_data, enemy_creature.level)
		caught.current_hp = enemy_creature.current_hp
		# Mark caught in dex
		if DexManager:
			DexManager.mark_caught(_enemy_data.species_id)
		if PartyManager.add_creature(caught):
			await _delay(0.8)
			battle_message.emit("%s was added to your party!" % caught.display_name())
		else:
			await _delay(0.8)
			battle_message.emit("Party is full! %s was released." % caught.display_name())
		await _delay(1.5)
		_end_battle("capture")
	else:
		AudioManager.play_sound(AudioManager.SFX.CAPTURE_FAIL)
		battle_message.emit("It broke free!")
		await _delay(1.0)
		_enemy_turn()

func player_run() -> void:
	if state != BattleState.PLAYER_TURN:
		return

	# Can't run from trainer battles
	if is_trainer_battle:
		battle_message.emit("You can't run from a trainer battle!")
		await _delay(1.0)
		return

	_change_state(BattleState.RUN)

	# 70% chance to run, modified by speed
	var run_chance := 0.7 + (player_creature.speed() - enemy_creature.speed()) * 0.02
	run_chance = clamp(run_chance, 0.3, 0.95)

	if randf() <= run_chance:
		battle_message.emit("Got away safely!")
		await _delay(1.0)
		_end_battle("run")
	else:
		battle_message.emit("Couldn't escape!")
		await _delay(1.0)
		_enemy_turn()

func _enemy_turn() -> void:
	_change_state(BattleState.ENEMY_TURN)

	# Process status DOT on enemy at start of their turn
	await _process_status_dot(enemy_creature)
	if enemy_creature.is_fainted():
		_emit_hp()
		_check_battle(false)
		return

	# Reset protect
	enemy_creature.is_protecting = false

	# Guard against empty skills
	var enemy_skills := enemy_creature.active_skills if enemy_creature.active_skills.size() > 0 else enemy_creature.data.skills
	if enemy_skills.is_empty():
		var prefix := "Leader %s's" % trainer_data.trainer_name if is_trainer_battle else "Wild"
		battle_message.emit("%s %s has no moves!" % [prefix, enemy_creature.display_name()])
		await _delay(1.0)
		_check_battle(false)
		return

	# Check if enemy is paralyzed
	if enemy_creature.status.is_active() and enemy_creature.status.type == StatusEffect.Type.PARALYZE:
		if randf() < 0.25:
			battle_message.emit("%s is paralyzed and can't move!" % enemy_creature.display_name())
			await _delay(1.0)
			_process_end_of_turn()
			return

	# Check if enemy is asleep
	if enemy_creature.status.is_active() and enemy_creature.status.type == StatusEffect.Type.SLEEP:
		var expired := enemy_creature.status.tick()
		if not expired:
			battle_message.emit("%s is fast asleep!" % enemy_creature.display_name())
			await _delay(1.0)
			_process_end_of_turn()
			return
		else:
			battle_message.emit("%s woke up!" % enemy_creature.display_name())
			status_expired.emit(enemy_creature.display_name(), "Sleep")
			await _delay(0.6)

	# AI skill selection based on trainer level
	var skill: SkillData = _select_enemy_skill(enemy_skills)

	match skill.category:
		SkillData.Category.HEAL:
			_execute_heal(enemy_creature, skill)
		SkillData.Category.STATUS:
			_execute_status_skill(enemy_creature, player_creature, skill, false)
		_:
			_execute_attack(enemy_creature, player_creature, skill, false)

	_emit_hp()
	await _delay(1.0)
	_check_battle(false)

# ── AI Skill Selection ──────────────────────────────────────────────────────

func _select_enemy_skill(skills: Array) -> SkillData:
	if is_trainer_battle and trainer_data:
		match trainer_data.ai_level:
			TrainerData.AILevel.SMART:
				return _ai_smart_select_skill(skills)
			TrainerData.AILevel.EXPERT:
				return _ai_expert_select_skill(skills)
	# RANDOM: default for wild creatures
	return skills[randi() % skills.size()] as SkillData

func _ai_smart_select_skill(skills: Array) -> SkillData:
	var hp_ratio := float(enemy_creature.current_hp) / float(max(1, enemy_creature.max_hp()))

	# 1. If has super-effective ATTACK skill with accuracy >= 0.8, use it
	for s in skills:
		var skill: SkillData = s as SkillData
		if skill.category == SkillData.Category.ATTACK and skill.accuracy >= 0.8:
			var eff := _get_effectiveness(skill.element, player_creature.data.element)
			if eff > 1.2:
				return skill

	# 2. If HP < 30% and has HEAL skill, heal
	if hp_ratio < 0.3:
		for s in skills:
			var skill: SkillData = s as SkillData
			if skill.category == SkillData.Category.HEAL:
				return skill

	# 3. If has STATUS skill not yet used and random < 0.4, use it
	if randf() < 0.4:
		for s in skills:
			var skill: SkillData = s as SkillData
			if skill.category == SkillData.Category.STATUS:
				# Check if status already active on player
				if skill.inflicts_status != StatusEffect.Type.NONE and player_creature.status.is_active():
					continue
				return skill

	# 4. Use highest-power ATTACK skill
	var best_attack: SkillData = null
	for s in skills:
		var skill: SkillData = s as SkillData
		if skill.category == SkillData.Category.ATTACK:
			if not best_attack or skill.power > best_attack.power:
				best_attack = skill
	if best_attack:
		return best_attack

	# Fallback: random
	return skills[randi() % skills.size()] as SkillData

func _ai_expert_select_skill(skills: Array) -> SkillData:
	var hp_ratio := float(enemy_creature.current_hp) / float(max(1, enemy_creature.max_hp()))
	var player_hp_ratio := float(player_creature.current_hp) / float(max(1, player_creature.max_hp()))

	# 1. If player has type advantage, prioritize DEF buff or Shield/Protect skill
	var player_has_advantage := false
	var player_skills := player_creature.active_skills if player_creature.active_skills.size() > 0 else player_creature.data.skills
	for s in player_skills:
		var skill: SkillData = s as SkillData
		if skill and skill.category == SkillData.Category.ATTACK:
			var eff := _get_effectiveness(skill.element, enemy_creature.data.element)
			if eff > 1.2:
				player_has_advantage = true
				break
	if player_has_advantage:
		for s in skills:
			var skill: SkillData = s as SkillData
			if skill.is_protect:
				return skill
			if skill.category == SkillData.Category.STATUS and skill.buff_stat == "def":
				return skill

	# 2. If player HP < 25%, use highest-accuracy ATTACK to finish
	if player_hp_ratio < 0.25:
		var best_acc_attack: SkillData = null
		for s in skills:
			var skill: SkillData = s as SkillData
			if skill.category == SkillData.Category.ATTACK:
				if not best_acc_attack or skill.accuracy > best_acc_attack.accuracy:
					best_acc_attack = skill
		if best_acc_attack:
			return best_acc_attack

	# 3. If player creature has no status, try Poison/Burn status skill
	if not player_creature.status.is_active():
		for s in skills:
			var skill: SkillData = s as SkillData
			if skill.inflicts_status == StatusEffect.Type.POISON or skill.inflicts_status == StatusEffect.Type.BURN:
				if skill.status_chance > 0.0:
					return skill

	# 4. Smart AI fallback with 20% random deviation
	if randf() < 0.2:
		return skills[randi() % skills.size()] as SkillData

	return _ai_smart_select_skill(skills)

# ── Trainer Party Switching ──────────────────────────────────────────────────

func _trainer_alive_count() -> int:
	var count := 0
	for c in _trainer_party:
		if not c.is_fainted():
			count += 1
	return count

func _trainer_next_alive() -> CreatureInstance:
	for i in range(_trainer_party.size()):
		if not _trainer_party[i].is_fainted():
			_trainer_party_index = i
			return _trainer_party[i]
	return null

# ── Status DOT & Turn Management ────────────────────────────────────────────

func _process_status_dot(creature: CreatureInstance) -> void:
	if not creature.status.is_active():
		return

	match creature.status.type:
		StatusEffect.Type.BURN:
			var dot_damage := max(1, int(creature.max_hp() * 0.06))
			creature.take_damage(dot_damage)
			battle_message.emit("%s is hurt by its burn! (-%d HP)" % [creature.display_name(), dot_damage])
			_emit_hp()
			var expired := creature.status.tick()
			if expired:
				battle_message.emit("%s's burn wore off!" % creature.display_name())
				status_expired.emit(creature.display_name(), "Burn")
			await _delay(0.6)
		StatusEffect.Type.POISON:
			var dot_damage := max(1, int(creature.max_hp() * 0.08))
			creature.take_damage(dot_damage)
			battle_message.emit("%s is hurt by poison! (-%d HP)" % [creature.display_name(), dot_damage])
			_emit_hp()
			var expired := creature.status.tick()
			if expired:
				battle_message.emit("%s's poison wore off!" % creature.display_name())
				status_expired.emit(creature.display_name(), "Poison")
			await _delay(0.6)
		StatusEffect.Type.SHIELD:
			var expired := creature.status.tick()
			if expired:
				battle_message.emit("%s's shield faded!" % creature.display_name())
				status_expired.emit(creature.display_name(), "Shield")

func _process_end_of_turn() -> void:
	# Process player status DOT at end of turn
	await _process_status_dot(player_creature)
	_emit_hp()
	if player_creature.is_fainted():
		_check_battle(false)
		return

	# Reset protect flag
	player_creature.is_protecting = false

	_change_state(BattleState.PLAYER_TURN)
	battle_message.emit("What will %s do?" % player_creature.display_name())

func _check_battle(after_player_action: bool = true) -> void:
	_change_state(BattleState.CHECK)

	if enemy_creature.is_fainted():
		if is_trainer_battle:
			_handle_trainer_creature_fainted()
			return

		# Wild battle win
		AudioManager.play_sound(AudioManager.SFX.FAINT)
		_change_state(BattleState.WIN)
		battle_message.emit("Wild %s fainted!" % enemy_creature.display_name())
		await _award_exp_and_gold()
		return

	if player_creature.is_fainted():
		# Try to switch to next alive creature
		var next := PartyManager.get_first_alive()
		if next:
			battle_message.emit("%s fainted! Go, %s!" % [player_creature.display_name(), next.display_name()])
			player_creature = next
			_emit_hp()
			await _delay(1.5)
			_change_state(BattleState.PLAYER_TURN)
			battle_message.emit("What will %s do?" % player_creature.display_name())
		else:
			_change_state(BattleState.LOSE)
			battle_message.emit("All your creatures fainted...")
			await _delay(1.5)
			_end_battle("lose")
		return

	# Neither fainted — alternate turns
	if after_player_action:
		# Process player status DOT before enemy turn
		await _process_status_dot(player_creature)
		_emit_hp()
		if player_creature.is_fainted():
			_check_battle(false)
			return
		player_creature.is_protecting = false
		_enemy_turn()
	else:
		_process_end_of_turn()

func _handle_trainer_creature_fainted() -> void:
	AudioManager.play_sound(AudioManager.SFX.FAINT)
	battle_message.emit("%s fainted!" % enemy_creature.display_name())

	# Award EXP for each trainer creature defeated
	var exp_amount := _enemy_data.exp_yield + enemy_creature.level * 3
	await _delay(1.0)
	var old_level := player_creature.level
	var leveled := player_creature.gain_exp(exp_amount)
	battle_message.emit("%s gained %d EXP!" % [player_creature.display_name(), exp_amount])
	exp_gained.emit(exp_amount, leveled)

	if leveled:
		await _delay(0.8)
		battle_message.emit("%s grew to Lv.%d!" % [player_creature.display_name(), player_creature.level])
		for lv in range(old_level + 1, player_creature.level + 1):
			await _check_skills_at_level(player_creature, lv)

	# Check if trainer has more creatures
	var next_creature := _trainer_next_alive()
	if next_creature:
		enemy_creature = next_creature
		_enemy_data = enemy_creature.data
		var remaining := _trainer_alive_count()
		await _delay(1.0)
		battle_message.emit("Leader %s sent out %s! (%d remaining)" % [trainer_data.trainer_name, enemy_creature.display_name(), remaining])
		trainer_creature_switched.emit(enemy_creature, remaining)
		_emit_hp()
		await _delay(1.2)

		# Check evolution after defeating each trainer creature
		if leveled and player_creature.can_evolve():
			evolution_ready.emit(player_creature)
			return

		_change_state(BattleState.PLAYER_TURN)
		battle_message.emit("What will %s do?" % player_creature.display_name())
	else:
		# All trainer creatures fainted — trainer defeated!
		_change_state(BattleState.WIN)
		await _delay(1.0)
		battle_message.emit("You defeated Leader %s!" % trainer_data.trainer_name)

		# Award trainer gold
		if InventoryManager:
			InventoryManager.add_gold(trainer_data.reward_gold)
		await _delay(0.8)
		battle_message.emit("Received %dG!" % trainer_data.reward_gold)

		# Award trainer items
		for item_entry in trainer_data.reward_items:
			var item_name: String = item_entry.get("item_name", "")
			var count: int = item_entry.get("count", 1)
			if item_name != "" and InventoryManager:
				for _i in count:
					InventoryManager.add_item(item_name)
				await _delay(0.6)
				battle_message.emit("Received %s x%d!" % [item_name, count])

		# Badge and defeated tracking
		if trainer_data.badge_number > 0 and BadgeManager:
			BadgeManager.earn_badge(trainer_data.badge_number)
			AudioManager.play_sound(AudioManager.SFX.BADGE_EARN)
			var badge_name: String = BadgeManager.BADGE_NAMES[trainer_data.badge_number - 1]
			await _delay(0.8)
			battle_message.emit("You earned the %s Badge!" % badge_name)

		# Mark trainer as defeated
		var trainer_id := trainer_data.trainer_name.to_lower().replace(" ", "_")
		if BadgeManager:
			BadgeManager.mark_defeated(trainer_id)

		# Check evolution after final trainer creature
		if leveled and player_creature.can_evolve():
			await _delay(0.5)
			evolution_ready.emit(player_creature)
			return

		trainer_defeated.emit(trainer_data)
		await _delay(1.5)
		_end_battle("win")

func _award_exp_and_gold() -> void:
	var exp_amount := _enemy_data.exp_yield + enemy_creature.level * 3
	var gold_amount := 10 + enemy_creature.level * 5
	await _delay(1.0)
	var old_level := player_creature.level
	var leveled := player_creature.gain_exp(exp_amount)
	if InventoryManager:
		InventoryManager.add_gold(gold_amount)
	battle_message.emit("%s gained %d EXP and %dG!" % [player_creature.display_name(), exp_amount, gold_amount])
	exp_gained.emit(exp_amount, leveled)

	if leveled:
		AudioManager.play_sound(AudioManager.SFX.LEVEL_UP)
		await _delay(0.8)
		battle_message.emit("%s grew to Lv.%d!" % [player_creature.display_name(), player_creature.level])

		# Check for new skills learned at each level gained
		for lv in range(old_level + 1, player_creature.level + 1):
			await _check_skills_at_level(player_creature, lv)

		# Check for evolution
		if player_creature.can_evolve():
			await _delay(0.5)
			evolution_ready.emit(player_creature)
			return  # Battle scene will handle evolution screen, then end battle

	await _delay(1.5)
	_end_battle("win")

func _check_skills_at_level(creature: CreatureInstance, at_level: int) -> void:
	if not creature.data:
		return
	for entry in creature.data.learn_set:
		var req_level: int = entry.get("level", 0)
		if req_level != at_level:
			continue
		var skill_path: String = entry.get("skill_path", "")
		if skill_path == "":
			continue
		var skill := load(skill_path)
		if not skill:
			continue
		# Check if already known
		var already_known := false
		for s in creature.active_skills:
			if s and s.resource_path == skill.resource_path:
				already_known = true
				break
		if already_known:
			continue

		if creature.try_learn_skill(skill):
			var skill_data: SkillData = skill as SkillData
			battle_message.emit("%s learned %s!" % [creature.display_name(), skill_data.skill_name if skill_data else "a new skill"])
			skill_learned.emit(creature, skill)
			await _delay(1.0)
		else:
			# Needs replacement dialog — emit signal for UI
			skill_learned.emit(creature, skill)
			# Store pending for the UI to handle
			_pending_new_skills.append(skill)
			_pending_skill_creature = creature

func finish_battle_after_evolution() -> void:
	_end_battle("win")

func _end_battle(result: String) -> void:
	# Reset battle modifiers on all party creatures
	for creature in PartyManager.party:
		creature.reset_battle_modifiers()
	# Clean up trainer meta
	if GameManager.has_meta("is_trainer_battle"):
		GameManager.remove_meta("is_trainer_battle")
	if GameManager.has_meta("trainer_data"):
		GameManager.remove_meta("trainer_data")
	battle_ended.emit(result)

func _calc_damage(attacker: CreatureInstance, defender: CreatureInstance, skill: SkillData) -> int:
	var base := float(skill.power) * (float(attacker.attack()) / float(max(1, defender.defense())))
	var effectiveness := _get_effectiveness(skill.element, defender.data.element)
	var variance := randf_range(0.85, 1.15)
	var weather_mult := _get_weather_multiplier(skill.element)
	var damage := int(base * effectiveness * variance * weather_mult * 0.5)
	return max(1, damage)

func _get_weather_multiplier(skill_element: int) -> float:
	if not GameManager.has_meta("zone_weather"):
		return 1.0
	var weather: int = GameManager.get_meta("zone_weather")
	match weather:
		WeatherSystem.WeatherType.RAIN:
			if skill_element == 1:  # Water
				return 1.2
			elif skill_element == 0:  # Fire
				return 0.8
		WeatherSystem.WeatherType.SANDSTORM:
			if skill_element == 4:  # Earth
				return 1.1
	return 1.0

func _get_effectiveness(atk_element: int, def_element: int) -> float:
	if TYPE_CHART.has(atk_element) and TYPE_CHART[atk_element].has(def_element):
		return TYPE_CHART[atk_element][def_element]
	return 1.0

func _change_state(new_state: BattleState) -> void:
	state = new_state
	battle_state_changed.emit(new_state)

func _emit_hp() -> void:
	if player_creature:
		player_hp_changed.emit(player_creature.current_hp, player_creature.max_hp())
	if enemy_creature:
		enemy_hp_changed.emit(enemy_creature.current_hp, enemy_creature.max_hp())

func _delay(seconds: float) -> void:
	await get_tree().create_timer(seconds / battle_speed).timeout

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_battle_speed"):
		battle_speed = 1.0 if battle_speed > 1.0 else 2.0
		speed_changed.emit(battle_speed)
