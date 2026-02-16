# Game Pikanad — Game Design Document

> 2D Pixel Art Creature RPG | Godot 4.4 | GDScript

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Creatures](#3-creatures)
4. [Skills & Combat](#4-skills--combat)
5. [Items](#5-items)
6. [Trainers & Badges](#6-trainers--badges)
7. [World & Zones](#7-world--zones)
8. [Systems](#8-systems)
9. [UI & Menus](#9-ui--menus)
10. [Controls](#10-controls)
11. [Save System](#11-save-system)
12. [Feature Roadmap](#12-feature-roadmap)

---

## 1. Overview

**Game Pikanad** is a 2D pixel art creature RPG where players explore zones, capture creatures, battle trainers, and collect badges. Inspired by classic monster-taming RPGs with modern features like daily quests, shiny hunting, and Web3 integration.

| Property | Value |
|---|---|
| Engine | Godot 4.4 |
| Resolution | 640x360 (scaled 2x → 1280x720) |
| Rendering | Pixel art (nearest-neighbor filtering) |
| Language | GDScript |
| Save Format | JSON with versioned migration (v1→v5) |

---

## 2. Architecture

### Project Structure

```
game-pikanad/
├── autoloads/          # 16 global singletons
├── resources/          # Data classes + .tres data files
│   ├── creatures/      # 15 CreatureData
│   ├── skills/         # 36 SkillData
│   ├── items/          # 15 ItemData
│   └── trainers/       # 8 TrainerData
├── scripts/            # Game logic
│   ├── battle/         # Battle engine (4 scripts)
│   ├── ui/             # UI controllers (14 scripts)
│   └── world/          # Overworld & zones (10 scripts)
├── scenes/             # .tscn scene files
├── assets/             # Sprites, fonts, tilesets
└── project.godot       # Project config & input map
```

### Autoload Singletons (16)

| Name | Purpose |
|---|---|
| `GameManager` | Game state machine (MENU/OVERWORLD/BATTLE/PAUSED) |
| `PartyManager` | Player party (max 6 creatures) |
| `SceneManager` | Scene transitions & navigation |
| `AudioManager` | Music crossfade, 4-channel SFX pool, volume |
| `ThemeManager` | RPG gold theme, color palette, styled panels |
| `InventoryManager` | Gold, items, equipped held items |
| `Web3Manager` | Blockchain wallet (Monad network) |
| `SaveManager` | JSON save/load with v1→v5 migration |
| `NetworkManager` | PVP & multiplayer (framework) |
| `DexManager` | Creature Dex: seen/caught tracking, milestones |
| `BadgeManager` | 8 badges, defeated trainers, zone gating |
| `TimeManager` | Day/night cycle (4 phases, real system time) |
| `DailyRewardManager` | 7-day login reward cycle |
| `QuestManager` | 3 daily quests from pool of 4 types |
| `StatsManager` | Lifetime stats (battles, catches, evolves, etc.) |
| `TutorialManager` | 10-step guided tutorial |

### Resource Class Hierarchy

```
Resource
├── CreatureData      # Species template (base stats, element, evolution)
├── CreatureInstance   # Live creature (level, HP, EXP, skills, shiny)
├── SkillData         # Skill definition (power, accuracy, effects)
├── ItemData          # Item definition (type, price, effects)
├── TrainerData       # Trainer definition (party, AI, dialogue)
└── StatusEffect      # Status condition (type, duration)
```

---

## 3. Creatures

### Elements (6)

| Element | Strong vs | Weak vs | Color |
|---|---|---|---|
| Fire | Grass (1.5x) | Water (0.67x) | Red |
| Water | Fire (1.5x) | Grass (0.67x) | Blue |
| Grass | Water (1.5x) | Fire (0.67x) | Green |
| Wind | Earth (1.5x) | — | Cyan |
| Earth | — | Wind (0.67x) | Brown |
| Neutral | — | — | Gray |

### All 15 Creatures

| # | Name | Element | HP | ATK | DEF | SPD | Rarity | Evolves |
|---|---|---|---|---|---|---|---|---|
| 1 | Flamepup | Fire | 44 | 14 | 8 | 12 | Common | → Blazefox (Lv12) |
| 2 | Blazefox | Fire | 62 | 20 | 12 | 18 | Uncommon | — |
| 3 | Tidecrab | Water | 48 | 12 | 14 | 8 | Common | → Aquafin (Lv14) |
| 4 | Aquafin | Water | 66 | 18 | 18 | 14 | Uncommon | — |
| 5 | Thornsprout | Grass | 42 | 10 | 10 | 14 | Common | → Floravine (Lv10) |
| 6 | Floravine | Grass | 58 | 16 | 14 | 16 | Uncommon | → Elderoak (Lv24) |
| 7 | Elderoak | Grass | 80 | 22 | 22 | 10 | Rare | — |
| 8 | Breezeling | Wind | 38 | 12 | 6 | 18 | Common | → Zephyrix (Lv16) |
| 9 | Zephyrix | Wind | 56 | 18 | 10 | 24 | Uncommon | → Stormraptor (Lv28) |
| 10 | Stormraptor | Wind | 72 | 24 | 16 | 28 | Rare | — |
| 11 | Stoneling | Earth | 52 | 16 | 18 | 6 | Common | → Boulderkin (Lv18) |
| 12 | Boulderkin | Earth | 74 | 22 | 26 | 8 | Uncommon | — |
| 13 | Pyrodrake | Fire | 70 | 24 | 14 | 16 | Rare | — |
| 14 | Tsunariel | Water | 68 | 20 | 16 | 20 | Rare | — |
| 15 | Vinewhisker | Grass | 46 | 14 | 12 | 10 | Common | — |

### Evolution Chains

```
Flamepup (Lv12) → Blazefox
Tidecrab (Lv14) → Aquafin
Thornsprout (Lv10) → Floravine (Lv24) → Elderoak
Breezeling (Lv16) → Zephyrix (Lv28) → Stormraptor
Stoneling (Lv18) → Boulderkin
```

### Stat Formulas

```
stat_at_level(base, level) = base + (level * base / 10)
EXP to next level = level * 25
Level-up heals +30% of old max HP
```

### Shiny System

- Base rate: **1/200** per encounter
- With Shiny Charm: **1/50**
- Visual: Gold tint (overworld), sparkle particles (battle), star icon

---

## 4. Skills & Combat

### Skill Categories

| Category | Description |
|---|---|
| **ATTACK** | Deals damage based on power, element, type matchup |
| **STATUS** | Inflicts status effects (burn, poison, sleep, etc.) |
| **HEAL** | Restores HP by percentage |

### All 36 Skills

#### Attack Skills
| Skill | Element | Power | Accuracy | Special |
|---|---|---|---|---|
| Tackle | Neutral | 40 | 95% | — |
| Quick Attack | Neutral | 40 | 100% | Priority |
| Ember | Fire | 45 | 100% | 20% Burn |
| Fire Fang | Fire | 65 | 95% | 10% Burn |
| Inferno | Fire | 100 | 75% | 30% Burn |
| Eruption | Fire | 90 | 85% | -25% DEF self |
| Vine Whip | Grass | 45 | 100% | — |
| Razor Leaf | Grass | 55 | 95% | — |
| Solar Beam | Grass | 90 | 90% | — |
| Nature's Wrath | Grass | 85 | 85% | — |
| Hydro Blast | Water | 60 | 100% | — |
| Tidal Wave | Water | 80 | 85% | — |
| Tsunami | Water | 95 | 80% | — |
| Gust | Wind | 40 | 100% | — |
| Air Slash | Wind | 60 | 95% | — |
| Cyclone | Wind | 65 | 90% | — |
| Hurricane | Wind | 90 | 80% | — |
| Tempest | Wind | 100 | 75% | — |
| Wind Fury | Wind | 75 | 90% | — |
| Rock Toss | Earth | 50 | 90% | — |
| Boulder Crush | Earth | 75 | 85% | — |
| Earthquake | Earth | 85 | 90% | — |
| Tectonic Slam | Earth | 95 | 80% | — |

#### Status Skills
| Skill | Element | Effect | Accuracy | Duration |
|---|---|---|---|---|
| Spore Cloud | Grass | Sleep | 75% | 3 turns |
| Bubble Trap | Water | Paralyze | 80% | 3 turns |
| Sand Tomb | Earth | —  | 85% | — |
| Flame Shield | Fire | Shield (self) | 100% | 1 turn |
| Iron Wall | Neutral | +DEF buff | 100% | 3 turns |
| Tailwind | Wind | +SPD buff | 100% | 3 turns |
| Protect | Neutral | Blocks damage | 100% | 1 turn |
| Roar | Neutral | Ends wild battle | 100% | — |

#### Heal & Drain Skills
| Skill | Element | Effect |
|---|---|---|
| Aqua Heal | Water | Heals 40% max HP |
| Rest | Neutral | Heals 50% max HP, inflicts Sleep 2 turns |
| Drain Life | Grass | Damage + heals 50% dealt |
| Leech Seed | Grass | Damage + heals 25% dealt |
| Splash | Water | Does nothing (joke skill) |

### Status Effects

| Status | Effect | Duration |
|---|---|---|
| **Burn** | Damage each turn, -25% ATK | 3 turns |
| **Poison** | Damage each turn | 3 turns |
| **Sleep** | Cannot act | 1-3 turns |
| **Paralyze** | 25% chance can't act, -50% SPD | 3 turns |
| **Shield** | Blocks all damage | 1 turn |

### Damage Formula

```
base_damage = (2 * level / 5 + 2) * power * (attacker_atk / defender_def) / 50 + 2
STAB = 1.25 if skill.element == user.element
type_mult = 1.5 (super effective) / 0.67 (not effective) / 1.0 (neutral)
weather_bonus = ±20% for Rain/Fire, +10% for Sandstorm/Earth
random = randf_range(0.85, 1.0)
final_damage = base_damage * STAB * type_mult * weather_bonus * random
```

### Battle Flow

```
START → slide-in animations, show creatures
PLAYER_TURN → choose: Fight / Catch / Item / Run
  Fight → select skill from 4 slots
  Catch → use capture ball (wild only)
  Item → use from inventory
  Run → attempt escape (wild only)
RESOLUTION → speed determines order, apply damage/effects
CHECK → faint check, level up, evolution, trainer switch
WIN/LOSE/CAPTURE/RUN → end battle
```

### AI Levels

| Level | Behavior |
|---|---|
| **RANDOM** | Picks random skill |
| **SMART** | Prefers type advantage, heals at <30% HP, uses status moves |
| **EXPERT** | Smart + defensive at <50% HP, finisher combos, DOT preference, 20% random |

---

## 5. Items

### All 15 Items

#### Capture Balls
| Item | Price | Catch Rate | Badge Required |
|---|---|---|---|
| Capture Ball | 100g | 1.0x | — |
| Super Ball | 300g | 1.5x | Badge 2 |
| Ultra Ball | 800g | 2.0x | Badge 6 |
| Master Ball | — | 100x | Day 7 reward only |

#### Healing
| Item | Price | Effect |
|---|---|---|
| Potion | 50g | Restores 30 HP |
| Super Potion | 150g | Restores 60 HP |
| Max Potion | 400g | Restores all HP |
| Revive | 500g | Revives fainted + 50% HP |

#### Status Cures
| Item | Price | Cures |
|---|---|---|
| Antidote | 75g | Poison |
| Awakening | 75g | Sleep |
| Full Heal | 200g | All statuses |

#### Held Items
| Item | Price | Effect |
|---|---|---|
| Power Band | 300g | +15% ATK |
| Swift Feather | 300g | +15% SPD |
| Guard Charm | 300g | +15% DEF |
| Everstone | 200g | Prevents evolution |

---

## 6. Trainers & Badges

### 8 Gym Leaders

| Badge | Leader | Zone | Element | AI | Party Levels |
|---|---|---|---|---|---|
| 1 | Oakhart | Forest Grove | Grass | Smart | ~8-10 |
| 2 | Marina | Water Coast | Water | Smart | ~12-15 |
| 3 | Blaze | Fire Volcano | Fire | Smart | ~16-20 |
| 4 | Rumble | Earth Caves | Earth | Smart | ~20-24 |
| 5 | Kai | — | Mixed | Expert | ~25-28 |
| 6 | Aria | — | Mixed | Expert | ~30-35 |
| 7 | Tempest | Sky Peaks | Wind | Expert | ~35-40 |
| 8 | Obsidian | Lava Core | Fire/Earth | Expert | ~42-48 |

### Badge Perks

| Badge | Unlock |
|---|---|
| Badge 2 | Super Ball in shop |
| Badge 5 | Level cap raised 30→50 |
| Badge 6 | Ultra Ball in shop |
| Badges 1-8 | Zone access gating |

---

## 7. World & Zones

### Zone Map

```
                    [Champion Arena] (Badge 8)
                          ↑
         [Sky Peaks] ←→ [Lava Core]
         (Badge 7)      (Badge 8)
              ↑
       [Earth Caves]
       (Badge 4)
              ↑
    [Fire Volcano] ←→ [Water Coast]
    (Badge 3)          (Badge 2)
              ↑
       [Forest Grove]
       (Badge 1)
              ↑
     [Starter Meadow]
       (No badge)
              ↑
       [Overworld Hub]
```

### Zone Details

| Zone | Wild Levels | Species | Weather |
|---|---|---|---|
| Starter Meadow | 2-5 | Flamepup, Tidecrab, Thornsprout | Leaves |
| Forest Grove | 3-7 | Thornsprout, Zephyrix, Vinewhisker, Floravine, Elderoak | Leaves |
| Water Coast | 5-10 | Tidecrab, Aquafin, Tsunariel | Rain |
| Fire Volcano | 8-14 | Flamepup, Blazefox, Pyrodrake | — |
| Earth Caves | 10-18 | Stoneling, Boulderkin | Sandstorm |
| Sky Peaks | 15-25 | Breezeling, Zephyrix, Stormraptor | Snow |
| Lava Core | 20-30 | Pyrodrake, Blazefox, Boulderkin | Sandstorm |
| Champion Arena | 30+ | — (trainers only) | — |

### Day/Night Cycle

| Phase | Time | Tint |
|---|---|---|
| Morning | 6:00-12:00 | Warm light |
| Afternoon | 12:00-18:00 | Neutral |
| Evening | 18:00-21:00 | Orange |
| Night | 21:00-6:00 | Dark blue |

### Weather Effects

| Weather | Damage Bonus |
|---|---|
| Rain | +20% Water, -20% Fire |
| Sandstorm | +10% Earth |
| Snow | Visual only |
| Leaves | Visual only |

---

## 8. Systems

### Daily Login Rewards (7-Day Cycle)

| Day | Reward |
|---|---|
| 1 | 100 Gold |
| 2 | Potion |
| 3 | Capture Ball |
| 4 | Super Ball |
| 5 | 500 Gold |
| 6 | Revive |
| 7 | Master Ball |

### Daily Quests (3 per day)

| Type | Example | Reward |
|---|---|---|
| Catch | Catch 3 creatures | Gold + items |
| Win | Win 2 battles | Gold + items |
| Explore | Visit 2 zones | Gold + items |
| Evolve | Evolve 1 creature | Gold + items |

### Player Stats Tracked

- Total battles won/lost
- Creatures caught / evolved
- Total damage dealt
- Zones visited
- Shinies found
- Play time

### Tutorial (10 Steps)

1. Welcome & movement
2. First wild encounter
3. Catching creatures
4. Using items
5. Party management
6. First trainer battle
7. Gym badges
8. Evolution
9. Shop & economy
10. Advanced tips

---

## 9. UI & Menus

### Main Menu
- Gold title with breathing creature showcase
- Floating blue particle effects
- Buttons: New Game, Continue, Dex, Stats
- Version label

### Battle HUD
- 2×2 action grid: Fight / Catch / Item / Run
- Skill grid (4 slots) with element-colored borders
- HP bars with status icons
- EXP bar
- Trainer party dots (remaining creatures)
- Floating damage numbers with effectiveness text

### Overworld HUD
- Top shelf: Gold, Party count, Zone name
- Quick-access buttons: P (Party), D (Dex), Q (Quests)
- Minimap: 100×75px, top-right, zone name label

### Theme
- RPG gold double-border panels
- Named color palette (GOLD, CREAM, DARK_BROWN, etc.)
- Styled buttons with hover/pressed/disabled states
- Element-specific border colors on creature cards

---

## 10. Controls

| Key | Action |
|---|---|
| W/A/S/D or Arrows | Move |
| Enter / Space | Confirm / Interact |
| Escape | Cancel / Back |
| Tab | Open menu |
| Shift | Run (1.5x speed) |
| P | Party menu |
| X | Creature Dex |
| Q | Quest panel |
| B | Toggle battle speed (2x) |

---

## 11. Save System

### Save Version History

| Version | Added |
|---|---|
| v1 | Party, gold, items |
| v2 | Creature Dex (seen/caught) |
| v3 | Badges, defeated trainers |
| v4 | Daily rewards, quests, stats |
| v5 | Tutorial progress |

### Auto-Migration
Each save version includes migration logic: when loading an older save, it automatically adds new fields with default values and increments the version number.

### Auto-Save Triggers
- Zone transitions
- After battles
- On game exit

---

## 12. Feature Roadmap

### Sprint 6 — Multiplayer & Trading (Proposed)

| Feature | Description | Priority |
|---|---|---|
| **Local Trading** | Trade creatures between save files | High |
| **PVP Battles** | Real-time 1v1 battles via WebSocket | High |
| **Online Matchmaking** | Queue system for PVP battles | Medium |
| **Trade Evolution** | Some creatures evolve only via trade | Medium |
| **Leaderboard** | Global stats ranking | Low |

### Sprint 7 — Content Expansion (Proposed)

| Feature | Description | Priority |
|---|---|---|
| **10 New Creatures** | Expand to 25 total with new elements | High |
| **Dual Elements** | Creatures with two element types | High |
| **Abilities** | Passive creature abilities (e.g. Intimidate, Rain Dance) | High |
| **Breeding** | Creature breeding with egg mechanics | Medium |
| **Mega Evolution** | Temporary battle transformation | Medium |
| **20 New Skills** | Expand to 56 total | Medium |
| **New Zones** | Ice Cavern, Desert Oasis, Mystic Forest | Medium |

### Sprint 8 — Endgame & Polish (Proposed)

| Feature | Description | Priority |
|---|---|---|
| **Battle Tower** | Infinite floor challenge mode | High |
| **Achievement System** | 50+ achievements with rewards | High |
| **Difficulty Modes** | Easy / Normal / Hard | Medium |
| **New Game+** | Restart with bonus items/creatures | Medium |
| **Legendary Encounters** | Unique one-time battles for legendary creatures | High |
| **Side Quests** | NPC story quests with unique rewards | Medium |
| **Mini-games** | Fishing, mining, berry growing | Low |

### Sprint 9 — Web3 & NFT (Proposed)

| Feature | Description | Priority |
|---|---|---|
| **NFT Minting** | Mint creatures as NFTs on Monad | High |
| **Marketplace** | Buy/sell creature NFTs | High |
| **Tournament Mode** | NFT-only competitive events | Medium |
| **Cross-game Assets** | Use NFT creatures in partner games | Low |

---

*Last updated: February 2026*
