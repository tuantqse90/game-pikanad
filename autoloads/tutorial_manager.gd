extends Node

## TutorialManager — tracks tutorial step completion, shows tutorial dialogues
## with gold "TUTORIAL" header and "Skip All" option. State persisted via SaveManager.

# All tutorial step IDs
const STEPS := [
	"welcome",
	"movement",
	"first_creature",
	"first_battle",
	"type_advantage",
	"first_npc",
	"first_portal",
	"shop_hint",
	"dex_hint",
	"quest_hint",
	"first_trade",
	"trade_evolution",
]

# Tutorial step dialogue content
const STEP_TEXT := {
	"welcome": [
		"Welcome to Game Pikanad!",
		"Explore the world, catch creatures, and become the champion!",
	],
	"movement": [
		"Use WASD or arrow keys to move around.",
		"Hold Shift to run faster!",
		"Walk into wild creatures to start a battle.",
	],
	"first_creature": [
		"You received your first creature!",
		"Press TAB to open your party menu and check its stats.",
	],
	"first_battle": [
		"This is a battle! You have four actions:",
		"Fight — choose a skill to attack.",
		"Items — use potions or status cures.",
		"Catch — throw a ball to capture the creature.",
		"Run — try to escape from wild battles.",
	],
	"type_advantage": [
		"Elements matter in battle!",
		"Fire beats Grass, Grass beats Water, Water beats Fire.",
		"Wind beats Earth, but Earth resists Wind.",
		"Use type advantages to deal more damage!",
	],
	"first_npc": [
		"You found an NPC! Press Enter or Space to interact.",
		"Healers (+) restore your party for free.",
		"Shopkeepers ($) sell items.",
		"Trainers (!) will challenge you to battle.",
	],
	"first_portal": [
		"Portals lead to other zones!",
		"Some zones require badges to enter.",
		"Defeat zone leaders to earn badges!",
	],
	"shop_hint": [
		"Tip: Visit the shop to buy Capture Balls and Potions.",
		"You'll need them for catching creatures and healing in battle!",
	],
	"dex_hint": [
		"Tip: Press X to open the Pikanadex!",
		"Track all the creatures you've seen and caught.",
	],
	"quest_hint": [
		"Tip: Press Q to check your daily quests!",
		"Complete quests for gold and item rewards.",
	],
	"first_trade": [
		"You completed your first trade!",
		"Trading lets you get creatures from other elements.",
		"Some creatures only evolve when traded!",
	],
	"trade_evolution": [
		"Your traded creature evolved!",
		"Certain species like Boulderkin and Vinewhisker",
		"only evolve through trading — look for the trade icon!",
	],
}

var _completed_steps: Dictionary = {}
var _showing_tutorial := false

func is_completed(step: String) -> bool:
	return _completed_steps.get(step, false)

func mark_completed(step: String) -> void:
	_completed_steps[step] = true

func skip_all() -> void:
	for step in STEPS:
		_completed_steps[step] = true

func show_tutorial(step: String) -> void:
	if is_completed(step) or _showing_tutorial:
		return
	if not STEP_TEXT.has(step):
		return

	_showing_tutorial = true
	mark_completed(step)

	# Wait for dialogue box to be available
	await get_tree().process_frame

	var dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box:
		# Build tutorial lines with "Skip All" hint on last line
		var lines: Array = STEP_TEXT[step].duplicate()
		lines.append("[Skip All Tutorials: press ESC]")

		dialogue_box.show_dialogue(lines, func():
			_showing_tutorial = false
			GameManager.change_state(GameManager.GameState.OVERWORLD)
		, "TUTORIAL")
		GameManager.change_state(GameManager.GameState.PAUSED)
	else:
		_showing_tutorial = false

## Show tutorial only if in overworld state
func try_show(step: String) -> void:
	if is_completed(step) or _showing_tutorial:
		return
	show_tutorial(step)

# ── Serialization ──────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	return _completed_steps.duplicate()

func deserialize(data: Dictionary) -> void:
	_completed_steps = data.duplicate()

func get_save_data() -> Dictionary:
	return serialize()
