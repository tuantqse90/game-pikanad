class_name CreatureData
extends Resource

## Species template — shared by all instances of a creature species.

enum Element { FIRE, WATER, GRASS, WIND, EARTH, NEUTRAL }
enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

@export var species_name: String = ""
@export var species_id: int = 0  # Unique ID for blockchain reference
@export var element: Element = Element.FIRE
@export var rarity: Rarity = Rarity.COMMON
@export var base_hp: int = 40
@export var base_attack: int = 10
@export var base_defense: int = 8
@export var base_speed: int = 10
@export var skills: Array[Resource] = []  # Array of SkillData
@export var sprite_texture: Texture2D
@export var battle_texture: Texture2D  # 48x48 battle portrait sheet
@export var overworld_texture: Texture2D  # 32x32 overworld animation sheet
@export var capture_rate: float = 0.4  # 0.0-1.0, higher = easier to catch
@export var exp_yield: int = 30  # EXP given when defeated

# Evolution
@export var evolution_level: int = 0  # 0 = does not evolve
@export var evolves_into: CreatureData  # Species to evolve into

# Learn set: skills learned at specific levels [{level: int, skill_path: String}]
@export var learn_set: Array[Dictionary] = []

# Dex number for ordering in the creature dex
@export var dex_number: int = 0

## Only RARE and LEGENDARY creatures can be minted as NFTs
func is_nft_eligible() -> bool:
	return rarity >= Rarity.RARE

## Returns stat at a given level (linear scaling).
func stat_at_level(base: int, level: int) -> int:
	return base + int(base * (level - 1) * 0.12)

func hp_at_level(level: int) -> int:
	return stat_at_level(base_hp, level)

func attack_at_level(level: int) -> int:
	return stat_at_level(base_attack, level)

func defense_at_level(level: int) -> int:
	return stat_at_level(base_defense, level)

func speed_at_level(level: int) -> int:
	return stat_at_level(base_speed, level)
