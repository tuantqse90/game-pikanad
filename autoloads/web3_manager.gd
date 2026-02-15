extends Node

## Web3Manager — bridges GDScript ↔ JavaScript ↔ Monad blockchain.
## All blockchain features are optional. Game runs offline without MetaMask.

signal wallet_connected(address: String)
signal wallet_disconnected
signal wallet_error(message: String)
signal balance_updated(amount: String)
signal nft_creatures_loaded(creatures: Array)
signal claim_success(tx_hash: String)
signal claim_error(message: String)

var wallet_address: String = ""
var token_balance: String = "0"
var is_web: bool = false
var _js_bridge_ready := false

func _ready() -> void:
	is_web = OS.has_feature("web")
	if is_web:
		_setup_js_callback()

func _setup_js_callback() -> void:
	if not is_web:
		return
	# Register a callback that JavaScript can call with results
	var callback := JavaScriptBridge.create_callback(_on_js_callback)
	JavaScriptBridge.get_interface("window").godotWeb3Callback = callback
	_js_bridge_ready = true

func _on_js_callback(args: Array) -> void:
	if args.is_empty():
		return
	var json_str: String = args[0]
	var json := JSON.new()
	if json.parse(json_str) != OK:
		return
	var result: Dictionary = json.data
	var event_name: String = result.get("event", "")
	var data: Dictionary = result.get("data", {})

	match event_name:
		"wallet_connected":
			wallet_address = data.get("address", "")
			wallet_connected.emit(wallet_address)
		"wallet_disconnected":
			wallet_address = ""
			wallet_disconnected.emit()
		"wallet_changed":
			wallet_address = data.get("address", "")
			wallet_connected.emit(wallet_address)
		"wallet_error":
			wallet_error.emit(data.get("message", "Unknown error"))
		"balance_result":
			token_balance = data.get("balance", "0")
			balance_updated.emit(token_balance)
		"balance_error":
			wallet_error.emit(data.get("message", "Balance error"))
		"nft_creatures_result":
			nft_creatures_loaded.emit(data.get("creatures", []))
		"nft_creatures_error":
			wallet_error.emit(data.get("message", "NFT load error"))
		"claim_success":
			claim_success.emit(data.get("txHash", ""))
		"claim_error":
			claim_error.emit(data.get("message", "Claim error"))

## Connect MetaMask wallet
func connect_wallet() -> void:
	if not is_web:
		wallet_error.emit("Web3 only available in browser")
		return
	JavaScriptBridge.eval("web3_connect_wallet()")

## Get PIKN token balance
func get_token_balance() -> void:
	if not is_web or wallet_address == "":
		return
	JavaScriptBridge.eval("web3_get_token_balance()")

## Get owned NFT creatures
func get_nft_creatures() -> void:
	if not is_web or wallet_address == "":
		return
	JavaScriptBridge.eval("web3_get_nft_creatures()")

## Claim battle reward (called after server provides signature)
func claim_battle_reward(battle_id_hex: String, amount_wei: String, signature_hex: String) -> void:
	if not is_web or wallet_address == "":
		return
	JavaScriptBridge.eval(
		"web3_claim_battle_reward('%s', '%s', '%s')" % [battle_id_hex, amount_wei, signature_hex]
	)

## Check if wallet is connected
func is_connected() -> bool:
	return wallet_address != ""

## Get shortened address for display
func short_address() -> String:
	if wallet_address.length() < 10:
		return wallet_address
	return wallet_address.substr(0, 6) + "..." + wallet_address.substr(-4)
