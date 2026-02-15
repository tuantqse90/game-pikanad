extends Node

## Core turn-based battle state machine.

signal battle_message(text: String)
signal battle_state_changed(new_state: int)
signal battle_ended(result: String)  # "win", "lose", "run", "capture"
signal player_hp_changed(current: int, max_val: int)
signal enemy_hp_changed(current: int, max_val: int)
signal exp_gained(amount: int, leveled_up: bool)
signal player_attacked  # Player's creature attacks enemy
signal enemy_attacked  # Enemy attacks player's creature
signal effectiveness_text(text: String, effectiveness: float)

enum BattleState { START, PLAYER_TURN, PLAYER_ACTION, ENEMY_TURN, CHECK, WIN, LOSE, CAPTURE, RUN }

# Type effectiveness matrix: [attacker_element][defender_element] → multiplier
# Elements: 0=Fire, 1=Water, 2=Grass, 3=Wind, 4=Earth
const TYPE_CHART := {
	0: { 0: 1.0, 1: 0.67, 2: 1.5,  3: 1.0, 4: 1.0 },   # Fire
	1: { 0: 1.5, 1: 1.0,  2: 0.67, 3: 1.0, 4: 1.0 },   # Water
	2: { 0: 0.67, 1: 1.5, 2: 1.0,  3: 1.0, 4: 1.0 },   # Grass
	3: { 0: 1.0, 1: 1.0,  2: 1.0,  3: 1.0, 4: 1.5 },   # Wind
	4: { 0: 1.0, 1: 1.0,  2: 1.0,  3: 0.67, 4: 1.0 },  # Earth
}

var state: BattleState = BattleState.START
var player_creature: CreatureInstance
var enemy_creature: CreatureInstance
var _enemy_data: CreatureData  # Keep reference for capture

func start_battle() -> void:
	# Retrieve battle data from GameManager
	_enemy_data = GameManager.get_meta("battle_creature_data") as CreatureData
	var enemy_level: int = GameManager.get_meta("battle_creature_level") as int

	enemy_creature = CreatureInstance.new(_enemy_data, enemy_level)
	player_creature = PartyManager.get_first_alive()

	if not player_creature:
		_change_state(BattleState.LOSE)
		return

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

	var skill: SkillData = player_creature.data.skills[skill_index] as SkillData

	# Player attacks
	var damage := _calc_damage(player_creature, enemy_creature, skill)
	var effectiveness := _get_effectiveness(skill.element, enemy_creature.data.element)

	if randf() <= skill.accuracy:
		enemy_creature.take_damage(damage)
		player_attacked.emit()
		battle_message.emit("%s used %s! (%d dmg)" % [player_creature.display_name(), skill.skill_name, damage])
		if effectiveness > 1.2:
			effectiveness_text.emit("SUPER EFFECTIVE!", effectiveness)
			await get_tree().create_timer(0.6).timeout
			battle_message.emit("It's super effective!")
		elif effectiveness < 0.8:
			effectiveness_text.emit("Not very effective...", effectiveness)
			await get_tree().create_timer(0.6).timeout
			battle_message.emit("It's not very effective...")
	else:
		battle_message.emit("%s used %s but missed!" % [player_creature.display_name(), skill.skill_name])

	_emit_hp()
	await get_tree().create_timer(1.0).timeout
	_check_battle(true)

func player_catch() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	_change_state(BattleState.PLAYER_ACTION)

	if GameManager.capture_items <= 0:
		battle_message.emit("No capture balls left!")
		await get_tree().create_timer(0.8).timeout
		_change_state(BattleState.PLAYER_TURN)
		return

	GameManager.capture_items -= 1
	battle_message.emit("You threw a capture ball!")
	await get_tree().create_timer(1.0).timeout

	# Capture formula: base_rate * (1 + (1 - hp_ratio) * 1.5)
	var hp_ratio := float(enemy_creature.current_hp) / float(enemy_creature.max_hp())
	var catch_chance := _enemy_data.capture_rate * (1.0 + (1.0 - hp_ratio) * 1.5)
	catch_chance = clamp(catch_chance, 0.05, 0.95)

	if randf() <= catch_chance:
		_change_state(BattleState.CAPTURE)
		battle_message.emit("Gotcha! %s was captured!" % enemy_creature.display_name())
		var caught := CreatureInstance.new(_enemy_data, enemy_creature.level)
		caught.current_hp = enemy_creature.current_hp
		if PartyManager.add_creature(caught):
			await get_tree().create_timer(0.8).timeout
			battle_message.emit("%s was added to your party!" % caught.display_name())
		else:
			await get_tree().create_timer(0.8).timeout
			battle_message.emit("Party is full! %s was released." % caught.display_name())
		await get_tree().create_timer(1.5).timeout
		battle_ended.emit("capture")
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
		battle_ended.emit("run")
	else:
		battle_message.emit("Couldn't escape!")
		await get_tree().create_timer(1.0).timeout
		_enemy_turn()

func _enemy_turn() -> void:
	_change_state(BattleState.ENEMY_TURN)

	# Guard against empty skills
	if enemy_creature.data.skills.is_empty():
		battle_message.emit("Wild %s has no moves!" % enemy_creature.display_name())
		await get_tree().create_timer(1.0).timeout
		_check_battle(false)
		return

	# Enemy picks a random skill
	var skill_count := enemy_creature.data.skills.size()
	var skill_index := randi() % skill_count
	var skill: SkillData = enemy_creature.data.skills[skill_index] as SkillData

	var damage := _calc_damage(enemy_creature, player_creature, skill)

	if randf() <= skill.accuracy:
		player_creature.take_damage(damage)
		enemy_attacked.emit()
		battle_message.emit("Wild %s used %s! (%d dmg)" % [enemy_creature.display_name(), skill.skill_name, damage])
	else:
		battle_message.emit("Wild %s used %s but missed!" % [enemy_creature.display_name(), skill.skill_name])

	_emit_hp()
	await get_tree().create_timer(1.0).timeout
	_check_battle(false)

func _check_battle(after_player_action: bool = true) -> void:
	_change_state(BattleState.CHECK)

	if enemy_creature.is_fainted():
		_change_state(BattleState.WIN)
		battle_message.emit("Wild %s fainted!" % enemy_creature.display_name())

		# Award EXP and gold
		var exp_amount := _enemy_data.exp_yield + enemy_creature.level * 3
		var gold_amount := 10 + enemy_creature.level * 5
		await get_tree().create_timer(1.0).timeout
		var leveled := player_creature.gain_exp(exp_amount)
		if InventoryManager:
			InventoryManager.add_gold(gold_amount)
		battle_message.emit("%s gained %d EXP and %dG!" % [player_creature.display_name(), exp_amount, gold_amount])
		exp_gained.emit(exp_amount, leveled)

		if leveled:
			await get_tree().create_timer(0.8).timeout
			battle_message.emit("%s grew to Lv.%d!" % [player_creature.display_name(), player_creature.level])

		await get_tree().create_timer(1.5).timeout
		battle_ended.emit("win")
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
			battle_ended.emit("lose")
		return

	# Neither fainted — alternate turns
	if after_player_action:
		_enemy_turn()
	else:
		_change_state(BattleState.PLAYER_TURN)
		battle_message.emit("What will %s do?" % player_creature.display_name())

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
