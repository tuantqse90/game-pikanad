extends Node

## StatsManager — tracks local player statistics.

var battles_won: int = 0
var battles_lost: int = 0
var creatures_caught: int = 0
var creatures_evolved: int = 0
var trainers_defeated: int = 0
var total_damage_dealt: int = 0
var zones_explored: Array[String] = []
var play_time_seconds: float = 0.0
var shinies_found: int = 0
var pvp_wins: int = 0
var pvp_losses: int = 0
var trades_completed: int = 0
var elo_rating: int = 1000

func _process(delta: float) -> void:
	if GameManager and GameManager.state != GameManager.GameState.MENU:
		play_time_seconds += delta

func increment(stat_name: String, amount: int = 1) -> void:
	match stat_name:
		"battles_won":
			battles_won += amount
		"battles_lost":
			battles_lost += amount
		"creatures_caught":
			creatures_caught += amount
		"creatures_evolved":
			creatures_evolved += amount
		"trainers_defeated":
			trainers_defeated += amount
		"total_damage_dealt":
			total_damage_dealt += amount
		"shinies_found":
			shinies_found += amount
		"pvp_wins":
			pvp_wins += amount
		"pvp_losses":
			pvp_losses += amount
		"trades_completed":
			trades_completed += amount

func update_elo(won: bool) -> void:
	var k := 32
	var expected := 1.0 / (1.0 + pow(10.0, 0.0 / 400.0))  # Simplified: assume equal opponent
	var actual := 1.0 if won else 0.0
	elo_rating = max(100, elo_rating + int(k * (actual - expected)))

func add_zone(zone_name: String) -> void:
	if zone_name not in zones_explored:
		zones_explored.append(zone_name)

func get_stat(stat_name: String) -> int:
	match stat_name:
		"battles_won":
			return battles_won
		"battles_lost":
			return battles_lost
		"creatures_caught":
			return creatures_caught
		"creatures_evolved":
			return creatures_evolved
		"trainers_defeated":
			return trainers_defeated
		"total_damage_dealt":
			return total_damage_dealt
		"shinies_found":
			return shinies_found
		"zones_explored":
			return zones_explored.size()
		"pvp_wins":
			return pvp_wins
		"pvp_losses":
			return pvp_losses
		"trades_completed":
			return trades_completed
		"elo_rating":
			return elo_rating
	return 0

func get_play_time_string() -> String:
	var total_seconds := int(play_time_seconds)
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	return "%dh %dm" % [hours, minutes]

func serialize() -> Dictionary:
	return {
		"battles_won": battles_won,
		"battles_lost": battles_lost,
		"creatures_caught": creatures_caught,
		"creatures_evolved": creatures_evolved,
		"trainers_defeated": trainers_defeated,
		"total_damage_dealt": total_damage_dealt,
		"zones_explored": zones_explored.duplicate(),
		"play_time_seconds": play_time_seconds,
		"shinies_found": shinies_found,
		"pvp_wins": pvp_wins,
		"pvp_losses": pvp_losses,
		"trades_completed": trades_completed,
		"elo_rating": elo_rating,
	}

func deserialize(data: Dictionary) -> void:
	battles_won = int(data.get("battles_won", 0))
	battles_lost = int(data.get("battles_lost", 0))
	creatures_caught = int(data.get("creatures_caught", 0))
	creatures_evolved = int(data.get("creatures_evolved", 0))
	trainers_defeated = int(data.get("trainers_defeated", 0))
	total_damage_dealt = int(data.get("total_damage_dealt", 0))
	var zones: Array = data.get("zones_explored", [])
	zones_explored.clear()
	for z in zones:
		zones_explored.append(str(z))
	play_time_seconds = float(data.get("play_time_seconds", 0.0))
	shinies_found = int(data.get("shinies_found", 0))
	pvp_wins = int(data.get("pvp_wins", 0))
	pvp_losses = int(data.get("pvp_losses", 0))
	trades_completed = int(data.get("trades_completed", 0))
	elo_rating = int(data.get("elo_rating", 1000))
