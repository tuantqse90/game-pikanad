extends Node

## NetworkManager — WebSocket connection to PvP server.

signal connected
signal disconnected
signal registered(player_id: String)
signal queue_joined(position: int)
signal queue_left
signal battle_started(data: Dictionary)
signal turn_result(data: Dictionary)
signal turn_changed(your_turn: bool)
signal battle_ended(data: Dictionary)
signal error(message: String)

const DEFAULT_SERVER_URL := "ws://localhost:8080"

var _ws := WebSocketPeer.new()
var _connected := false
var player_id := ""
var server_url := DEFAULT_SERVER_URL

func _process(_delta: float) -> void:
	_ws.poll()
	var state := _ws.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			if not _connected:
				_connected = true
				connected.emit()
			while _ws.get_available_packet_count() > 0:
				var packet := _ws.get_packet()
				_handle_message(packet.get_string_from_utf8())
		WebSocketPeer.STATE_CLOSED:
			if _connected:
				_connected = false
				disconnected.emit()

func connect_to_server(url: String = "") -> void:
	if url != "":
		server_url = url
	_ws.connect_to_url(server_url)

func disconnect_from_server() -> void:
	_ws.close()
	_connected = false

func is_connected_to_server() -> bool:
	return _connected

func register(wallet_address: String = "") -> void:
	_send({
		"type": "register",
		"walletAddress": wallet_address,
	})

func join_queue(party_data: Array) -> void:
	_send({
		"type": "join_queue",
		"party": party_data,
	})

func leave_queue() -> void:
	_send({"type": "leave_queue"})

func send_battle_action(skill_index: int) -> void:
	_send({
		"type": "battle_action",
		"action": {"skillIndex": skill_index},
	})

func _send(data: Dictionary) -> void:
	if _connected:
		_ws.send_text(JSON.stringify(data))

func _handle_message(text: String) -> void:
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var msg: Dictionary = json.data

	match msg.get("type", ""):
		"registered":
			player_id = msg.get("playerId", "")
			registered.emit(player_id)
		"queue_joined":
			queue_joined.emit(msg.get("position", 0))
		"queue_left":
			queue_left.emit()
		"battle_start":
			battle_started.emit(msg)
		"turn_result":
			turn_result.emit(msg)
		"turn_change":
			turn_changed.emit(msg.get("yourTurn", false))
		"battle_end":
			battle_ended.emit(msg)
		"error":
			error.emit(msg.get("message", "Unknown error"))

## Serialize party for server
func serialize_party() -> Array:
	var result := []
	for creature in PartyManager.party:
		if creature.is_fainted():
			continue
		var skills := []
		for skill_res in creature.data.skills:
			var skill: SkillData = skill_res as SkillData
			if skill:
				skills.append({
					"name": skill.skill_name,
					"element": skill.element,
					"power": skill.power,
					"accuracy": skill.accuracy,
				})
		result.append({
			"speciesName": creature.display_name(),
			"level": creature.level,
			"hp": creature.current_hp,
			"maxHp": creature.max_hp(),
			"attack": creature.attack(),
			"defense": creature.defense(),
			"speed": creature.speed(),
			"skills": skills,
		})
	return result
