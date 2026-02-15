class_name SkillData
extends Resource

## A single skill / move a creature can use in battle.

@export var skill_name: String = ""
@export var element: CreatureData.Element = CreatureData.Element.FIRE
@export var power: int = 40
@export var accuracy: float = 1.0  # 0.0–1.0
@export var description: String = ""
