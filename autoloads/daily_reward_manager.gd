extends Node

## DailyRewardManager — 7-day login reward cycle.

signal reward_available(day: int, reward_text: String)

const REWARDS := [
	{"type": "gold", "value": 100, "text": "100G"},
	{"type": "item", "value": "Potion", "text": "Potion"},
	{"type": "item", "value": "Capture Ball", "text": "Capture Ball"},
	{"type": "item", "value": "Super Ball", "text": "Super Ball"},
	{"type": "gold", "value": 500, "text": "500G"},
	{"type": "item", "value": "Revive", "text": "Revive"},
	{"type": "item", "value": "Master Ball", "text": "Master Ball"},
]

var last_login_date: String = ""
var login_streak: int = 0

func check_daily_reward() -> Dictionary:
	var today := Time.get_date_string_from_system()
	if today == last_login_date:
		return {"available": false, "day": login_streak, "reward": ""}
	# Check if streak continues or resets
	if last_login_date != "":
		var yesterday := _get_yesterday()
		if last_login_date != yesterday:
			login_streak = 0  # Missed a day, reset streak
	var day := login_streak % REWARDS.size()
	return {"available": true, "day": day, "reward": REWARDS[day]["text"]}

func claim_daily_reward() -> void:
	var day := login_streak % REWARDS.size()
	var reward: Dictionary = REWARDS[day]
	match reward["type"]:
		"gold":
			if InventoryManager:
				InventoryManager.add_gold(int(reward["value"]))
		"item":
			if InventoryManager:
				InventoryManager.add_item(str(reward["value"]))
	last_login_date = Time.get_date_string_from_system()
	login_streak = (login_streak + 1) % REWARDS.size()

func _get_yesterday() -> String:
	var unix := Time.get_unix_time_from_system() - 86400
	var date := Time.get_date_dict_from_unix_time(int(unix))
	return "%04d-%02d-%02d" % [date["year"], date["month"], date["day"]]

func serialize() -> Dictionary:
	return {
		"last_login_date": last_login_date,
		"login_streak": login_streak,
	}

func deserialize(data: Dictionary) -> void:
	last_login_date = data.get("last_login_date", "")
	login_streak = int(data.get("login_streak", 0))
