extends Control

## PvP Queue screen — connects to server, joins matchmaking queue,
## and transitions to PvP battle when matched.

@onready var status_label: Label = $CenterContainer/VBox/StatusLabel
@onready var queue_label: Label = $CenterContainer/VBox/QueueLabel
@onready var cancel_btn: Button = $CenterContainer/VBox/CancelBtn

var _searching := false

func _ready() -> void:
	GameManager.change_state(GameManager.GameState.PAUSED)
	cancel_btn.pressed.connect(_on_cancel)

	# Connect network signals
	NetworkManager.connected.connect(_on_connected)
	NetworkManager.disconnected.connect(_on_disconnected)
	NetworkManager.registered.connect(_on_registered)
	NetworkManager.queue_joined.connect(_on_queue_joined)
	NetworkManager.battle_started.connect(_on_battle_started)
	NetworkManager.error.connect(_on_error)

	# Connect to server
	status_label.text = "Connecting to server..."
	queue_label.text = ""
	NetworkManager.connect_to_server()

func _on_connected() -> void:
	status_label.text = "Connected! Registering..."
	var wallet := ""
	if Web3Manager and Web3Manager.is_wallet_connected():
		wallet = Web3Manager.wallet_address
	NetworkManager.register(wallet)

func _on_registered(player_id: String) -> void:
	status_label.text = "Registered! Joining queue..."
	var party_data := NetworkManager.serialize_party()
	NetworkManager.join_queue(party_data)

func _on_queue_joined(position: int) -> void:
	_searching = true
	status_label.text = "Searching for opponent..."
	queue_label.text = "Queue position: %d" % position
	_animate_dots()

func _on_battle_started(data: Dictionary) -> void:
	_searching = false
	status_label.text = "Opponent found!"
	queue_label.text = ""

	# Store battle data and transition
	GameManager.set_meta("pvp_battle_data", data)
	await get_tree().create_timer(1.0).timeout
	SceneManager.go_to_pvp_battle()

func _on_disconnected() -> void:
	status_label.text = "Disconnected from server."
	_searching = false

func _on_error(message: String) -> void:
	status_label.text = "Error: " + message

func _on_cancel() -> void:
	_searching = false
	if NetworkManager.is_connected_to_server():
		NetworkManager.leave_queue()
		NetworkManager.disconnect_from_server()
	SceneManager.go_to_overworld()

func _animate_dots() -> void:
	var dots := 0
	while _searching:
		dots = (dots + 1) % 4
		queue_label.text = "Searching" + ".".repeat(dots)
		await get_tree().create_timer(0.5).timeout
