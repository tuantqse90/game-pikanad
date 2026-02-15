class_name SkillData
extends Resource

## A single skill / move a creature can use in battle.

enum Category { ATTACK, STATUS, HEAL }

@export var skill_name: String = ""
@export var element: CreatureData.Element = CreatureData.Element.FIRE
@export var power: int = 40
@export var accuracy: float = 1.0  # 0.0-1.0
@export var description: String = ""
@export var category: Category = Category.ATTACK

# Status effect infliction
@export var inflicts_status: StatusEffect.Type = StatusEffect.Type.NONE
@export var status_chance: float = 0.0  # 0.0-1.0
@export var status_duration: int = 3

# Priority move (goes first regardless of speed)
@export var is_priority: bool = false

# Drain: healer gets drain_percent of damage dealt back as HP
@export var drain_percent: float = 0.0

# Heal: restore heal_percent of max HP (for HEAL category)
@export var heal_percent: float = 0.0

# Self stat penalty after use (e.g. Eruption: -0.25 DEF)
@export var self_stat_penalty: float = 0.0

# Protect: blocks all damage for one turn
@export var is_protect: bool = false

# Self-inflicted status (e.g. Rest puts self to sleep)
@export var self_inflicts: StatusEffect.Type = StatusEffect.Type.NONE
@export var self_status_duration: int = 0

# Stat buff (for STATUS category)
@export var buff_stat: String = ""  # "atk", "def", "spd"
@export var buff_duration: int = 0

# Ends wild battle (e.g. Roar)
@export var ends_wild_battle: bool = false
