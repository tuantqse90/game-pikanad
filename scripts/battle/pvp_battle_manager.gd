extends Node

## PvP Battle Manager — receives battle state from the server.
## Uses the same signals as BattleManager for HUD compatibility.

signal battle_message(text: String)
signal battle_state_changed(new_state: int)
signal battle_ended(result: String)
signal player_hp_changed(current: int, max_val: int)
signal enemy_hp_changed(current: int, max_val: int)
signal player_attacked
signal enemy_attacked
signal effectiveness_text(text: String, effectiveness: float)

enum BattleState { START, PLAYER_TURN, PLAYER_ACTION, ENEMY_TURN, CHECK, WIN, LOSE }

var state: BattleState = BattleState.START
var player_creature: CreatureInstance
var enemy_creature: CreatureInstance
var _your_turn := false
var _room_data: Dictionary = {}

func start_pvp_battle(data: Dictionary) -> void:
	_room_data = data
	_your_turn = data.get("yourTurn", false)

	# Create creatures from server data
	var your_data: Dictionary = data.get("yourCreature", {})
	var opp_data: Dictionary = data.get("opponentCreature", {})

	player_creature = _make_creature(your_data)
	enemy_creature = _make_creature(opp_data)

	_change_state(BattleState.START)
	battle_message.emit("PvP Battle! vs %s" % opp_data.get("speciesName", "???"))
	_emit_hp()

	await get_tree().create_timer(1.5).timeout

	if _your_turn:
		_change_state(BattleState.PLAYER_TURN)
		battle_message.emit("Your turn! Choose an action.")
	else:
		_change_state(BattleState.ENEMY_TURN)
		battle_message.emit("Waiting for opponent...")

func player_fight(skill_index: int) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	_change_state(BattleState.PLAYER_ACTION)
	battle_message.emit("Attacking...")
	NetworkManager.send_battle_action(skill_index)

func on_turn_result(data: Dictionary) -> void:
	var attacker_id: String = data.get("attacker", "")
	var skill_name: String = data.get("skillName", "")
	var damage: int = data.get("damage", 0)
	var effectiveness: float = data.get("effectiveness", 1.0)
	var hit: bool = data.get("hit", true)
	var attacker_hp: int = data.get("attackerHp", 0)
	var defender_hp: int = data.get("defenderHp", 0)

	var is_our_attack := (attacker_id == NetworkManager.player_id)

	if is_our_attack:
		if hit:
			player_attacked.emit()
			battle_message.emit("%s used %s! (%d dmg)" % [player_creature.display_name(), skill_name, damage])
			enemy_creature.current_hp = defender_hp
		else:
			battle_message.emit("%s used %s but missed!" % [player_creature.display_name(), skill_name])
		player_creature.current_hp = attacker_hp
	else:
		if hit:
			enemy_attacked.emit()
			battle_message.emit("Opponent used %s! (%d dmg)" % [skill_name, damage])
			player_creature.current_hp = defender_hp
		else:
			battle_message.emit("Opponent used %s but missed!" % [skill_name])
		enemy_creature.current_hp = attacker_hp

	if hit and effectiveness > 1.2:
		effectiveness_text.emit("SUPER EFFECTIVE!", effectiveness)
	elif hit and effectiveness < 0.8:
		effectiveness_text.emit("Not very effective...", effectiveness)

	_emit_hp()

func on_turn_change(your_turn: bool) -> void:
	_your_turn = your_turn
	if your_turn:
		_change_state(BattleState.PLAYER_TURN)
		battle_message.emit("Your turn!")
	else:
		_change_state(BattleState.ENEMY_TURN)
		battle_message.emit("Waiting for opponent...")

func on_battle_end(data: Dictionary) -> void:
	var winner: String = data.get("winner", "")
	if winner == NetworkManager.player_id:
		_change_state(BattleState.WIN)
		battle_message.emit("You won the PvP battle!")
		await get_tree().create_timer(2.0).timeout
		battle_ended.emit("win")
	else:
		_change_state(BattleState.LOSE)
		battle_message.emit("You lost the PvP battle...")
		await get_tree().create_timer(2.0).timeout
		battle_ended.emit("lose")

func _make_creature(data: Dictionary) -> CreatureInstance:
	# Create a temporary creature from server data
	var creature_data := CreatureData.new()
	creature_data.species_name = data.get("speciesName", "???")
	creature_data.base_hp = data.get("maxHp", 44)
	creature_data.base_attack = data.get("attack", 14)
	creature_data.base_defense = data.get("defense", 8)
	creature_data.base_speed = data.get("speed", 12)

	# Populate skills from server data
	var skills_array: Array = data.get("skills", [])
	for skill_entry in skills_array:
		var skill := SkillData.new()
		skill.skill_name = skill_entry.get("name", "Attack")
		skill.power = skill_entry.get("power", 10)
		skill.accuracy = skill_entry.get("accuracy", 0.9)
		skill.element = skill_entry.get("element", 0)
		creature_data.skills.append(skill)

	# Fallback: ensure at least one skill so UI doesn't break
	if creature_data.skills.is_empty():
		var default_skill := SkillData.new()
		default_skill.skill_name = "Tackle"
		default_skill.power = 10
		default_skill.accuracy = 0.95
		default_skill.element = 0
		creature_data.skills.append(default_skill)

	var instance := CreatureInstance.new(creature_data, data.get("level", 5))
	instance.current_hp = data.get("hp", instance.max_hp())
	return instance

func _change_state(new_state: BattleState) -> void:
	state = new_state
	battle_state_changed.emit(new_state)

func _emit_hp() -> void:
	if player_creature:
		player_hp_changed.emit(player_creature.current_hp, player_creature.max_hp())
	if enemy_creature:
		enemy_hp_changed.emit(enemy_creature.current_hp, enemy_creature.max_hp())
