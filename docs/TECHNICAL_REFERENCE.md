# Game Pikanad — Technical Reference

> Developer guide for extending and modifying the game

---

## Table of Contents

1. [Adding a New Creature](#1-adding-a-new-creature)
2. [Adding a New Skill](#2-adding-a-new-skill)
3. [Adding a New Item](#3-adding-a-new-item)
4. [Adding a New Zone](#4-adding-a-new-zone)
5. [Adding a New Trainer](#5-adding-a-new-trainer)
6. [Resource Script Reference](#6-resource-script-reference)
7. [Autoload API Reference](#7-autoload-api-reference)
8. [Battle Engine Internals](#8-battle-engine-internals)
9. [Save System & Migration](#9-save-system--migration)
10. [Audio System](#10-audio-system)
11. [Common Gotchas](#11-common-gotchas)

---

## 1. Adding a New Creature

### Step 1: Create .tres file

Create `resources/creatures/my_creature.tres`:

```ini
[gd_resource type="Resource" script_class="CreatureData" load_steps=7 format=3]

[ext_resource type="Script" path="res://resources/creature_data.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/sprites/my_creature.png" id="2"]
[ext_resource type="Texture2D" path="res://assets/sprites/my_creature_battle.png" id="3"]
[ext_resource type="Texture2D" path="res://assets/sprites/my_creature_overworld.png" id="4"]
[ext_resource type="Resource" path="res://resources/skills/tackle.tres" id="5"]
[ext_resource type="Resource" path="res://resources/skills/ember.tres" id="6"]

[resource]
script = ExtResource("1")
species_name = "MyCreature"
species_id = 16
element = 0
rarity = 0
base_hp = 50
base_attack = 15
base_defense = 10
base_speed = 12
skills = [ExtResource("5"), ExtResource("6")]
sprite_texture = ExtResource("2")
battle_texture = ExtResource("3")
overworld_texture = ExtResource("4")
capture_rate = 0.5
exp_yield = 45
evolution_level = 0
dex_number = 16
learn_set = [{"level": 6, "skill_path": "res://resources/skills/fire_fang.tres"}]
```

### Step 2: Add evolution (optional)

If this creature evolves, add an ext_resource for the evolution target:

```ini
[gd_resource type="Resource" script_class="CreatureData" load_steps=8 format=3]
# ... (add ext_resource id="7" for evolution target)
[ext_resource type="Resource" path="res://resources/creatures/evolved_form.tres" id="7"]

[resource]
# ...
evolution_level = 20
evolves_into = ExtResource("7")
```

> **Important:** `load_steps` = number of ext_resources + 1

### Step 3: Add to zone

In the zone script (e.g., `scripts/world/zones/forest_grove.gd`), add to species pool:

```gdscript
func _get_zone_species() -> Array:
    return [
        preload("res://resources/creatures/my_creature.tres"),
        # ... other species
    ]
```

### Step 4: Add sprites

Place sprite files in `assets/sprites/`:
- `my_creature.png` — Menu/UI sprite
- `my_creature_battle.png` — 48×48 battle portrait
- `my_creature_overworld.png` — 32×32 overworld (4-frame walk sheet)

---

## 2. Adding a New Skill

Create `resources/skills/my_skill.tres`:

```ini
[gd_resource type="Resource" script_class="SkillData" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/skill_data.gd" id="1"]

[resource]
script = ExtResource("1")
skill_name = "My Skill"
element = 0
power = 70
accuracy = 0.9
description = "A powerful attack"
category = 0
```

### Skill Properties

| Property | Type | Description |
|---|---|---|
| `category` | 0/1/2 | ATTACK=0, STATUS=1, HEAL=2 |
| `element` | 0-5 | FIRE=0, WATER=1, GRASS=2, WIND=3, EARTH=4, NEUTRAL=5 |
| `inflicts_status` | 0-5 | NONE=0, BURN=1, POISON=2, SLEEP=3, PARALYZE=4, SHIELD=5 |
| `status_chance` | float | Probability of status (0.0-1.0) |
| `is_priority` | bool | Always acts first |
| `drain_percent` | float | Heal % of damage dealt |
| `heal_percent` | float | Heal % of max HP (HEAL category) |
| `is_protect` | bool | Blocks all damage this turn |
| `ends_wild_battle` | bool | Forces wild creature to flee |

---

## 3. Adding a New Item

Create `resources/items/my_item.tres`:

```ini
[gd_resource type="Resource" script_class="ItemData" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/item_data.gd" id="1"]

[resource]
script = ExtResource("1")
item_name = "My Item"
item_type = 1
description = "Restores 50 HP"
price = 100
effect_value = 50
usable_in_battle = true
usable_in_overworld = true
```

### Item Type Values

| Value | Type | Key Properties |
|---|---|---|
| 0 | CAPTURE_BALL | `catch_multiplier` |
| 1 | POTION | `effect_value` (HP restored) |
| 2 | KEY_ITEM | — |
| 3 | STATUS_CURE | `cures_statuses` array |
| 4 | REVIVE | `effect_value` (% HP restored) |
| 5 | HELD_ITEM | `held_effect`, `held_boost_percent` |

---

## 4. Adding a New Zone

### Step 1: Create zone script

Create `scripts/world/zones/my_zone.gd`:

```gdscript
extends "res://scripts/world/zone_base.gd"

const NPC_SCENE := preload("res://scenes/npc/npc.tscn")

func _ready() -> void:
    zone_name = "My Zone"
    zone_color = Color(0.2, 0.3, 0.5)
    min_level = 10
    max_level = 20
    super._ready()  # IMPORTANT: must call super

func _get_zone_species() -> Array:
    return [
        preload("res://resources/creatures/stoneling.tres"),
        preload("res://resources/creatures/boulderkin.tres"),
    ]

func _get_portals() -> Array:
    return [
        {"zone_path": "res://scenes/world/zones/forest_grove.tscn", "label": "Forest Grove"},
    ]
```

### Step 2: Create zone scene

Create `scenes/world/zones/my_zone.tscn` with the script attached to root Node2D.

### Step 3: Link portals

Add portal entries in connected zones pointing to your new zone.

### Step 4: Add badge gating (optional)

In `scripts/world/zone_portal.gd`, add badge requirements:

```gdscript
var zone_badge_requirements := {
    "res://scenes/world/zones/my_zone.tscn": 4,  # Requires badge 4
}
```

---

## 5. Adding a New Trainer

### Step 1: Create .tres file

Create `resources/trainers/trainer_name.tres`:

```ini
[gd_resource type="Resource" script_class="TrainerData" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/trainer_data.gd" id="1"]

[resource]
script = ExtResource("1")
trainer_name = "Trainer Name"
ai_level = 1
party = [{"species_path": "res://resources/creatures/blazefox.tres", "level": 20}]
badge_number = 0
reward_gold = 500
pre_battle_lines = ["Ready for a battle?"]
win_lines = ["Good fight!"]
lose_lines = ["I'll be back!"]
rematch_allowed = false
```

### Step 2: Place in zone

In the zone's `_ready()`, add a TRAINER NPC:

```gdscript
var npc = NPC_SCENE.instantiate()
npc.npc_name = "Trainer Name"
npc.npc_type = "TRAINER"
npc.position = Vector2(200, 150)
npc.trainer_data = preload("res://resources/trainers/trainer_name.tres")
add_child(npc)
```

### AI Level Values

| Value | Enum | Description |
|---|---|---|
| 0 | RANDOM | Random skill selection |
| 1 | SMART | Type advantage, heals at <30%, uses status |
| 2 | EXPERT | Smart + defensive play, combo finishers |

---

## 6. Resource Script Reference

### CreatureData (`resources/creature_data.gd`)

```
Properties:
  species_name: String       # Display name
  species_id: int            # Blockchain ID (immutable)
  dex_number: int            # Dex display order
  element: Element           # FIRE/WATER/GRASS/WIND/EARTH/NEUTRAL
  rarity: Rarity             # COMMON/UNCOMMON/RARE/LEGENDARY
  base_hp/atk/def/spd: int   # Base stats (scaled by level)
  skills: Array[Resource]    # Starting skills (max 4)
  learn_set: Array[Dict]     # Skills learned at levels
  evolution_level: int       # 0 = no evolution
  evolves_into: CreatureData # Target species
  capture_rate: float        # 0.0-1.0 base catch chance
  exp_yield: int             # EXP given to victor
  sprite_texture: Texture2D  # Menu sprite
  battle_texture: Texture2D  # Battle sprite (48x48)
  overworld_texture: Texture2D # Overworld sprite (32x32)

Methods:
  stat_at_level(base, level) -> int
  hp_at_level(level) -> int
  attack_at_level(level) -> int
  defense_at_level(level) -> int
  speed_at_level(level) -> int
```

### CreatureInstance (`resources/creature_instance.gd`)

```
Properties:
  data: CreatureData         # Species template
  nickname: String
  level: int
  current_hp: int
  exp: int
  is_nft: bool
  nft_token_id: int
  is_shiny: bool

  # Battle-only (not saved):
  status: StatusEffect
  atk_modifier: float
  def_modifier: float
  spd_modifier: float
  is_protecting: bool

Methods:
  display_name() -> String
  max_hp() -> int
  attack() -> int            # With modifiers + held items
  defense() -> int
  speed() -> int
  is_fainted() -> bool
  heal_full() -> void
  take_damage(amount) -> void
  gain_exp(amount) -> bool   # Returns true if leveled
  can_evolve() -> bool
  evolve() -> void
  roll_shiny() -> void
  reset_battle_modifiers() -> void
  get_pending_new_skills() -> Array
  try_learn_skill(skill) -> bool
  replace_skill(index, new_skill) -> void
```

### SkillData (`resources/skill_data.gd`)

```
Properties:
  skill_name: String
  element: CreatureData.Element
  power: int
  accuracy: float            # 0.0-1.0
  description: String
  category: Category         # ATTACK/STATUS/HEAL
  inflicts_status: StatusEffect.Type
  status_chance: float
  status_duration: int
  is_priority: bool
  drain_percent: float
  heal_percent: float
  self_stat_penalty: float
  is_protect: bool
  self_inflicts: StatusEffect.Type
  self_status_duration: int
  buff_stat: String          # "atk"/"def"/"spd"
  buff_duration: int
  ends_wild_battle: bool
```

---

## 7. Autoload API Reference

### GameManager

```gdscript
GameManager.state                      # Current GameState enum
GameManager.change_state(new_state)    # MENU, OVERWORLD, BATTLE, PAUSED
```

### PartyManager

```gdscript
PartyManager.party                     # Array[CreatureInstance]
PartyManager.add_creature(creature)    # -> bool (false if full)
PartyManager.remove_creature(index)
PartyManager.get_first_alive()         # -> CreatureInstance or null
PartyManager.has_alive_creature()      # -> bool
PartyManager.party_size()              # -> int
PartyManager.heal_all()
PartyManager.give_starter(data, level)
# Signal: party_changed
```

### InventoryManager

```gdscript
InventoryManager.gold                  # int
InventoryManager.add_gold(amount)
InventoryManager.spend_gold(amount)    # -> bool
InventoryManager.add_item(item_name, count)
InventoryManager.remove_item(item_name)
InventoryManager.get_item_count(item_name) # -> int
InventoryManager.get_all_items()       # -> Dictionary
```

### BadgeManager

```gdscript
BadgeManager.has_badge(number)         # -> bool
BadgeManager.earn_badge(number)
BadgeManager.badge_count()             # -> int
BadgeManager.is_trainer_defeated(id)   # -> bool
BadgeManager.mark_trainer_defeated(id)
BadgeManager.get_level_cap()           # -> int (30 or 50)
```

### DexManager

```gdscript
DexManager.mark_seen(species_id)
DexManager.mark_caught(species_id)
DexManager.is_seen(species_id)         # -> bool
DexManager.is_caught(species_id)       # -> bool
DexManager.seen_count()                # -> int
DexManager.caught_count()              # -> int
DexManager.check_milestones()          # Awards rewards at thresholds
```

### SaveManager

```gdscript
SaveManager.save_game()
SaveManager.load_game()                # -> bool
SaveManager.has_save()                 # -> bool
SaveManager.delete_save()
```

### AudioManager

```gdscript
AudioManager.play_music(MusicTrack)    # With crossfade
AudioManager.stop_music()
AudioManager.play_sfx(SFX)            # 4-channel pool
AudioManager.set_music_volume(db)
AudioManager.set_sfx_volume(db)
```

### StatsManager

```gdscript
StatsManager.record_battle_win()
StatsManager.record_catch()
StatsManager.record_evolve()
StatsManager.record_damage(amount)
StatsManager.record_zone_visit(zone)
StatsManager.record_shiny()
StatsManager.get_stats()               # -> Dictionary
```

### QuestManager

```gdscript
QuestManager.get_daily_quests()        # -> Array[Dictionary]
QuestManager.progress_quest(type, amount)
QuestManager.is_quest_complete(index)  # -> bool
QuestManager.claim_reward(index)
```

---

## 8. Battle Engine Internals

### BattleManager Signals

```gdscript
battle_message(text: String)
battle_state_changed(new_state: int)
battle_ended(result: String)            # "win"/"lose"/"run"/"capture"
player_hp_changed(current, max_val)
enemy_hp_changed(current, max_val)
player_attacked / enemy_attacked
effectiveness_text(text, effectiveness)
status_inflicted(target_name, status_name)
status_expired(target_name, status_name)
evolution_ready(creature)
skill_learned(creature, skill)
trainer_defeated(trainer)
trainer_creature_switched(new_creature, remaining)
speed_changed(speed)
```

### Battle States

```
START → PLAYER_TURN → PLAYER_ACTION → ENEMY_TURN → CHECK
                                                      ↓
                                          WIN / LOSE / CAPTURE / RUN
```

### Type Effectiveness Chart

```
Attacker →  FIRE  WATER GRASS WIND  EARTH NEUTRAL
Defender ↓
FIRE        1.0   1.5   0.67  1.0   1.0   1.0
WATER       0.67  1.0   1.5   1.0   1.0   1.0
GRASS       1.5   0.67  1.0   1.0   1.0   1.0
WIND        1.0   1.0   1.0   1.0   1.5   1.0
EARTH       1.0   1.0   1.0   0.67  1.0   1.0
NEUTRAL     1.0   1.0   1.0   1.0   1.0   1.0
```

---

## 9. Save System & Migration

### Save File Location
`user://save_data.json` (OS-specific user data folder)

### Migration Chain
```
v1 (party, gold, items)
 → v2 (+creature_dex)
 → v3 (+badges, defeated_trainers)
 → v4 (+daily_rewards, quests, stats)
 → v5 (+tutorial_progress)
```

Each migration adds missing fields with sensible defaults.

---

## 10. Audio System

### Adding Music

In `scripts/audio/music_library.gd`, add a new enum value and generate tones:

```gdscript
enum MusicTrack { MENU, OVERWORLD, BATTLE, TRAINER_BATTLE, CHAMPION, VICTORY, MY_TRACK }
```

### Adding SFX

In `scripts/audio/sfx_library.gd`, add enum and tone pattern:

```gdscript
enum SFX { ..., MY_SFX }
```

All audio is procedurally generated using `ToneGenerator` — no audio files needed.

---

## 11. Common Gotchas

| Issue | Solution |
|---|---|
| "File has not been read yet" | Always `Read` before `Edit` |
| `.tres` load fails | Check `load_steps` = ext_resources + 1 |
| Dex close breaks state | `close_dex()` must restore previous GameState |
| Zone NPCs missing | Zone script needs `const NPC_SCENE := preload(...)` and `super._ready()` |
| Trainer ID mismatch | Defeated ID = `trainer_name.to_lower().replace(" ", "_")` |
| Main menu dex leak | Dex created as child must `queue_free()` on close |
| Evolution not triggering | Check `evolution_level > 0` and `evolves_into != null` |
| Skills not learning | Verify `learn_set` format: `[{"level": X, "skill_path": "res://..."}]` |
| Badge gate not working | Check `zone_badge_requirements` dict in `zone_portal.gd` |

---

*Last updated: February 2026*
