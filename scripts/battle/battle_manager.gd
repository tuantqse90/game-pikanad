extends Node

## Core turn-based battle state machine with status effects, items, and evolution.

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

func start_battle() -> void:
	# Retrieve battle data from GameManager
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
	await get_tree().create_timer(1.2).timeout
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

	# Check for priority: if player has priority and enemy doesn't, player goes first (already does)
	# If enemy would go first by speed but player has priority, we still process player first here
	# Priority is handled in turn order determination

	# Check if player is paralyzed (25% chance to skip)
	if player_creature.status.is_active() and player_creature.status.type == StatusEffect.Type.PARALYZE:
		if randf() < 0.25:
			battle_message.emit("%s is paralyzed and can't move!" % player_creature.display_name())
			await get_tree().create_timer(1.0).timeout
			_enemy_turn()
			return

	# Check if player is asleep
	if player_creature.status.is_active() and player_creature.status.type == StatusEffect.Type.SLEEP:
		var expired := player_creature.status.tick()
		if not expired:
			battle_message.emit("%s is fast asleep!" % player_creature.display_name())
			await get_tree().create_timer(1.0).timeout
			_enemy_turn()
			return
		else:
			battle_message.emit("%s woke up!" % player_creature.display_name())
			status_expired.emit(player_creature.display_name(), "Sleep")
			await get_tree().create_timer(0.6).timeout

	# Handle Protect
	if skill.is_protect:
		player_creature.is_protecting = true
		battle_message.emit("%s braced itself!" % player_creature.display_name())
		await get_tree().create_timer(1.0).timeout
		_enemy_turn()
		return

	# Handle Roar (ends wild battle)
	if skill.ends_wild_battle:
		battle_message.emit("%s used %s! The wild creature fled!" % [player_creature.display_name(), skill.skill_name])
		await get_tree().create_timer(1.0).timeout
		_change_state(BattleState.RUN)
		battle_ended.emit("run")
		return

	# Handle skill by category
	match skill.category:
		SkillData.Category.HEAL:
			_execute_heal(player_creature, skill)
			await get_tree().create_timer(1.0).timeout
			_enemy_turn()
		SkillData.Category.STATUS:
			_execute_status_skill(player_creature, enemy_creature, skill, true)
			await get_tree().create_timer(1.0).timeout
			_enemy_turn()
		_:  # ATTACK
			_execute_attack(player_creature, enemy_creature, skill, true)
			_emit_hp()
			await get_tree().create_timer(1.0).timeout
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
		if is_player:
			player_attacked.emit()
		else:
			enemy_attacked.emit()
		battle_message.emit("%s used %s! (%d dmg)" % [attacker.display_name(), skill.skill_name, damage])

		# Effectiveness text
		if effectiveness > 1.2:
			effectiveness_text.emit("SUPER EFFECTIVE!", effectiveness)
			await get_tree().create_timer(0.6).timeout
			battle_message.emit("It's super effective!")
		elif effectiveness < 0.8:
			effectiveness_text.emit("Not very effective...", effectiveness)
			await get_tree().create_timer(0.6).timeout
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
		await get_tree().create_timer(0.8).timeout
		_change_state(BattleState.PLAYER_TURN)
		return

	var target := target_creature if target_creature else player_creature
	item_used.emit(item_name)

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
	await get_tree().create_timer(1.0).timeout
	_enemy_turn()

func player_catch(ball_name: String = "Capture Ball") -> void:
	if state != BattleState.PLAYER_TURN:
		return
	_change_state(BattleState.PLAYER_ACTION)

	if not InventoryManager.remove_item(ball_name):
		battle_message.emit("No %s left!" % ball_name)
		await get_tree().create_timer(0.8).timeout
		_change_state(BattleState.PLAYER_TURN)
		return

	var ball_data := InventoryManager.get_item_data(ball_name)
	var multiplier := ball_data.catch_multiplier if ball_data else 1.0

	battle_message.emit("You threw a %s!" % ball_name)
	await get_tree().create_timer(1.0).timeout

	# Capture formula: base_rate * multiplier * (1 + (1 - hp_ratio) * 1.5)
	var hp_ratio := float(enemy_creature.current_hp) / float(enemy_creature.max_hp())
	var catch_chance := _enemy_data.capture_rate * multiplier * (1.0 + (1.0 - hp_ratio) * 1.5)
	catch_chance = clamp(catch_chance, 0.05, 0.99)
	# Master Ball always catches
	if multiplier >= 100.0:
		catch_chance = 1.0

	if randf() <= catch_chance:
		_change_state(BattleState.CAPTURE)
		battle_message.emit("Gotcha! %s was captured!" % enemy_creature.display_name())
		var caught := CreatureInstance.new(_enemy_data, enemy_creature.level)
		caught.current_hp = enemy_creature.current_hp
		# Mark caught in dex
		if DexManager:
			DexManager.mark_caught(_enemy_data.species_id)
		if PartyManager.add_creature(caught):
			await get_tree().create_timer(0.8).timeout
			battle_message.emit("%s was added to your party!" % caught.display_name())
		else:
			await get_tree().create_timer(0.8).timeout
			battle_message.emit("Party is full! %s was released." % caught.display_name())
		await get_tree().create_timer(1.5).timeout
		_end_battle("capture")
	else:
		battle_message.emit("It broke free!")
		await get_tree().create_timer(1.0).timeout
		_enemy_turn()

func player_run() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	_change_state(BattleState.RUN)

	# 70% chance to run, modified by speed
	var run_chance := 0.7 + (player_creature.speed() - enemy_creature.speed()) * 0.02
	run_chance = clamp(run_chance, 0.3, 0.95)

	if randf() <= run_chance:
		battle_message.emit("Got away safely!")
		await get_tree().create_timer(1.0).timeout
		_end_battle("run")
	else:
		battle_message.emit("Couldn't escape!")
		await get_tree().create_timer(1.0).timeout
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
		battle_message.emit("Wild %s has no moves!" % enemy_creature.display_name())
		await get_tree().create_timer(1.0).timeout
		_check_battle(false)
		return

	# Check if enemy is paralyzed
	if enemy_creature.status.is_active() and enemy_creature.status.type == StatusEffect.Type.PARALYZE:
		if randf() < 0.25:
			battle_message.emit("Wild %s is paralyzed and can't move!" % enemy_creature.display_name())
			await get_tree().create_timer(1.0).timeout
			_process_end_of_turn()
			return

	# Check if enemy is asleep
	if enemy_creature.status.is_active() and enemy_creature.status.type == StatusEffect.Type.SLEEP:
		var expired := enemy_creature.status.tick()
		if not expired:
			battle_message.emit("Wild %s is fast asleep!" % enemy_creature.display_name())
			await get_tree().create_timer(1.0).timeout
			_process_end_of_turn()
			return
		else:
			battle_message.emit("Wild %s woke up!" % enemy_creature.display_name())
			status_expired.emit(enemy_creature.display_name(), "Sleep")
			await get_tree().create_timer(0.6).timeout

	# Enemy picks a random skill (preferring ATTACK)
	var skill_index := randi() % enemy_skills.size()
	var skill: SkillData = enemy_skills[skill_index] as SkillData

	match skill.category:
		SkillData.Category.HEAL:
			_execute_heal(enemy_creature, skill)
		SkillData.Category.STATUS:
			_execute_status_skill(enemy_creature, player_creature, skill, false)
		_:
			_execute_attack(enemy_creature, player_creature, skill, false)

	_emit_hp()
	await get_tree().create_timer(1.0).timeout
	_check_battle(false)

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
			await get_tree().create_timer(0.6).timeout
		StatusEffect.Type.POISON:
			var dot_damage := max(1, int(creature.max_hp() * 0.08))
			creature.take_damage(dot_damage)
			battle_message.emit("%s is hurt by poison! (-%d HP)" % [creature.display_name(), dot_damage])
			_emit_hp()
			var expired := creature.status.tick()
			if expired:
				battle_message.emit("%s's poison wore off!" % creature.display_name())
				status_expired.emit(creature.display_name(), "Poison")
			await get_tree().create_timer(0.6).timeout
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
		_change_state(BattleState.WIN)
		battle_message.emit("Wild %s fainted!" % enemy_creature.display_name())

		# Award EXP and gold
		var exp_amount := _enemy_data.exp_yield + enemy_creature.level * 3
		var gold_amount := 10 + enemy_creature.level * 5
		await get_tree().create_timer(1.0).timeout
		var old_level := player_creature.level
		var leveled := player_creature.gain_exp(exp_amount)
		if InventoryManager:
			InventoryManager.add_gold(gold_amount)
		battle_message.emit("%s gained %d EXP and %dG!" % [player_creature.display_name(), exp_amount, gold_amount])
		exp_gained.emit(exp_amount, leveled)

		if leveled:
			await get_tree().create_timer(0.8).timeout
			battle_message.emit("%s grew to Lv.%d!" % [player_creature.display_name(), player_creature.level])

			# Check for new skills learned at each level gained
			for lv in range(old_level + 1, player_creature.level + 1):
				await _check_skills_at_level(player_creature, lv)

			# Check for evolution
			if player_creature.can_evolve():
				await get_tree().create_timer(0.5).timeout
				evolution_ready.emit(player_creature)
				return  # Battle scene will handle evolution screen, then end battle

		await get_tree().create_timer(1.5).timeout
		_end_battle("win")
		return

	if player_creature.is_fainted():
		# Try to switch to next alive creature
		var next := PartyManager.get_first_alive()
		if next:
			battle_message.emit("%s fainted! Go, %s!" % [player_creature.display_name(), next.display_name()])
			player_creature = next
			_emit_hp()
			await get_tree().create_timer(1.5).timeout
			_change_state(BattleState.PLAYER_TURN)
			battle_message.emit("What will %s do?" % player_creature.display_name())
		else:
			_change_state(BattleState.LOSE)
			battle_message.emit("All your creatures fainted...")
			await get_tree().create_timer(1.5).timeout
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
			await get_tree().create_timer(1.0).timeout
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
	battle_ended.emit(result)

func _calc_damage(attacker: CreatureInstance, defender: CreatureInstance, skill: SkillData) -> int:
	var base := float(skill.power) * (float(attacker.attack()) / float(max(1, defender.defense())))
	var effectiveness := _get_effectiveness(skill.element, defender.data.element)
	var variance := randf_range(0.85, 1.15)
	var damage := int(base * effectiveness * variance * 0.5)
	return max(1, damage)

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
