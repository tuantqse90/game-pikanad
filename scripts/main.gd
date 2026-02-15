extends Control

## Main menu scene with Web3 integration.

@onready var start_btn: Button = $CenterContainer/VBoxContainer/StartBtn
@onready var continue_btn: Button = $CenterContainer/VBoxContainer/ContinueBtn
@onready var wallet_btn: Button = $CenterContainer/VBoxContainer/WalletBtn
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/QuitBtn
@onready var wallet_label: Label = $CenterContainer/VBoxContainer/WalletLabel

func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MENU)
	start_btn.pressed.connect(_on_start)
	continue_btn.pressed.connect(_on_continue)
	wallet_btn.pressed.connect(_on_wallet)
	quit_btn.pressed.connect(_on_quit)
	start_btn.grab_focus()

	# Show/hide Continue button based on save existence
	continue_btn.visible = SaveManager.has_save()

	# Show/hide web-specific buttons
	var is_web := OS.has_feature("web")
	wallet_btn.visible = is_web
	quit_btn.visible = not is_web
	wallet_label.visible = is_web

	# Connect Web3 signals
	if Web3Manager:
		Web3Manager.wallet_connected.connect(_on_wallet_connected)
		Web3Manager.wallet_error.connect(_on_wallet_error)
		if Web3Manager.is_connected():
			wallet_label.text = Web3Manager.short_address()
			wallet_btn.text = "Wallet Connected"

func _on_start() -> void:
	SceneManager.go_to_overworld()

func _on_continue() -> void:
	SaveManager.load_game()
	SceneManager.go_to_overworld()

func _on_wallet() -> void:
	if Web3Manager and not Web3Manager.is_connected():
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
