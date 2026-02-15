extends Control

## Main menu scene with Web3 integration.

@onready var start_btn: Button = $CenterContainer/VBoxContainer/StartBtn
@onready var continue_btn: Button = $CenterContainer/VBoxContainer/ContinueBtn
@onready var dex_btn: Button = $CenterContainer/VBoxContainer/DexBtn
@onready var wallet_btn: Button = $CenterContainer/VBoxContainer/WalletBtn
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/QuitBtn
@onready var wallet_label: Label = $CenterContainer/VBoxContainer/WalletLabel

var _dex_screen: Node

func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MENU)
	start_btn.pressed.connect(_on_start)
	continue_btn.pressed.connect(_on_continue)
	dex_btn.pressed.connect(_on_dex)
	wallet_btn.pressed.connect(_on_wallet)
	quit_btn.pressed.connect(_on_quit)
	start_btn.grab_focus()

	# Show/hide Continue and Dex buttons based on save existence
	var has_save := SaveManager.has_save()
	continue_btn.visible = has_save
	dex_btn.visible = has_save

	# Show/hide web-specific buttons
	var is_web := OS.has_feature("web")
	wallet_btn.visible = is_web
	quit_btn.visible = not is_web
	wallet_label.visible = is_web

	# Connect Web3 signals
	if Web3Manager:
		Web3Manager.wallet_connected.connect(_on_wallet_connected)
		Web3Manager.wallet_error.connect(_on_wallet_error)
		if Web3Manager.is_wallet_connected():
			wallet_label.text = Web3Manager.short_address()
			wallet_btn.text = "Wallet Connected"

func _on_start() -> void:
	SceneManager.go_to_overworld()

func _on_continue() -> void:
	SaveManager.load_game()
	SceneManager.go_to_overworld()

func _on_dex() -> void:
	if _dex_screen:
		return  # Already open
	# Load dex data first if saved
	if SaveManager.has_save():
		SaveManager.load_game()
	var dex_scene := load("res://scenes/ui/creature_dex.tscn")
	_dex_screen = dex_scene.instantiate()
	add_child(_dex_screen)
	_dex_screen.open_dex()
	_dex_screen.close_btn.pressed.connect(func():
		if _dex_screen:
			_dex_screen.queue_free()
			_dex_screen = null
	)

func _on_wallet() -> void:
	if Web3Manager and not Web3Manager.is_wallet_connected():
		wallet_btn.text = "Connecting..."
		wallet_btn.disabled = true
		Web3Manager.connect_wallet()

func _on_quit() -> void:
	get_tree().quit()

func _on_wallet_connected(address: String) -> void:
	wallet_btn.text = "Wallet Connected"
	wallet_btn.disabled = true
	wallet_label.text = Web3Manager.short_address()

func _on_wallet_error(message: String) -> void:
	wallet_btn.text = "Connect Wallet"
	wallet_btn.disabled = false
	wallet_label.text = message
