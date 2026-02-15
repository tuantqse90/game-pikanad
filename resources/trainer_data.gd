class_name TrainerData
extends Resource

## Data template for a trainer / gym leader NPC.

enum AILevel { RANDOM, SMART, EXPERT }

@export var trainer_name: String = ""
@export var ai_level: AILevel = AILevel.RANDOM
@export var party: Array[Dictionary] = []  # [{species_path: String, level: int}]
@export var pre_battle_lines: Array[String] = []
@export var win_lines: Array[String] = []
@export var lose_lines: Array[String] = []
@export var badge_number: int = 0  # 0 = no badge, 1-8 = gym leader
@export var reward_gold: int = 100
@export var reward_items: Array[Dictionary] = []  # [{item_name: String, count: int}]
@export var rematch_allowed: bool = false
