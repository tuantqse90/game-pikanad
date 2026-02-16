# Game Pikanad

A 2D pixel-art creature RPG built with Godot 4.4, featuring creature collecting, turn-based battles, trading, and PvP multiplayer.

## Features

### Core Gameplay
- **17 Creatures** across 5 elements (Fire, Water, Grass, Wind, Earth) with 4 rarity tiers
- **36 Skills** — Attack, Status, Heal categories with priority, drain, protect, and buff mechanics
- **Turn-based Battle System** — type advantages, status effects (Burn, Poison, Sleep, Paralyze, Shield), weather bonuses
- **Evolution** — level-up evolution chains + trade evolution (Boulderkin, Vinewhisker)
- **15 Items** — capture balls (4 types), potions (3 types), revive, status cures, held items

### World & Progression
- **8 Zones** — Starter Meadow, Fire Volcano, Water Coast, Forest Grove, Earth Caves, Sky Peaks, Lava Core, Champion Arena
- **8 Gym Leaders** with Smart/Expert AI and badge rewards
- **Badge-gated zones** and level caps (30 base, 50 with badge 5)
- **Day/night cycle** based on real system time
- **Zone-specific weather** (Rain, Snow, Sandstorm, Leaves) with battle damage bonuses

### Multiplayer & Trading
- **NPC Trading** — offline trade with NPC offering comparable creatures, stat comparison, trade evolution trigger
- **Online Trading** — two-player WebSocket trade protocol with offer/accept flow
- **PvP Battles** — matchmaking queue, server-driven turns, ELO rating system
- **Multiplayer Hub** — Trade, PvP, and Leaderboard access from main menu
- **Leaderboard** — local PvP record, ELO, win rate, trades completed

### Meta Systems
- **Creature Dex** — seen/caught tracking, milestone rewards (Master Ball, Shiny Charm, Crown)
- **Shiny System** — 1/200 rate (1/50 with Shiny Charm), gold tint + sparkle particles
- **Daily Login Rewards** — 7-day cycle (Gold, Potion, Balls, Revive, Master Ball)
- **Daily Quests** — 3 random quests from pool of 6 types (catch, battle, explore, evolve, PvP, trade)
- **Player Stats** — battles, catches, evolves, damage, zones, shinies, PvP record, ELO, trades, play time
- **Tutorial System** — 12 contextual tutorials with skip-all option

### Audio & UI
- **Procedural Audio** — 8 music tracks and 23 SFX generated via ToneGenerator (no external audio files)
- **RPG-styled UI** — double-border panels, element-colored badges, themed buttons, floating particles
- **Battle Polish** — slide-in animations, floating damage numbers, screen flash, 2x speed toggle

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrows | Move |
| Shift | Run (1.5x speed) |
| Enter / Space | Interact / Confirm |
| Escape | Cancel / Close menu |
| Tab | Party menu |
| X | Creature Dex |
| Q | Quest panel |
| B | Toggle battle speed (1x/2x) |

## Tech Stack

- **Engine:** Godot 4.4 (GDScript)
- **Architecture:** 16 autoload singletons, resource-driven data (.tres), procedural audio
- **Multiplayer:** WebSocket client (NetworkManager) for PvP and online trading
- **Save System:** JSON-based with versioned migration (v1 through v6)
- **Web3:** Optional MetaMask wallet connection for NFT-eligible creatures (RARE+)

## Project Structure

```
game-pikanad/
├── autoloads/          # 16 singleton managers
├── resources/
│   ├── creature_data.gd, creature_instance.gd, skill_data.gd, item_data.gd, ...
│   ├── creatures/      # 17 creature .tres files
│   ├── skills/         # 36 skill .tres files
│   ├── items/          # 15 item .tres files
│   └── trainers/       # 8 trainer .tres files
├── scripts/
│   ├── audio/          # ToneGenerator, MusicLibrary, SfxLibrary
│   ├── battle/         # BattleManager, BattleHUD, PvP
│   ├── npc/            # NPC base with 5 types
│   ├── ui/             # Menus, dialogs, HUD, trading, leaderboard
│   └── world/          # Zones, portals, weather, overworld
├── scenes/             # .tscn scene files
├── assets/sprites/     # Creature and player sprites
├── web/                # Custom HTML shell for web export
├── build/web/          # Web export output
└── docs/               # Design doc, technical reference, QA test plan
```

## Building

### Prerequisites
- [Godot 4.4+](https://godotengine.org/download) with export templates installed

### Desktop
```bash
godot --headless --export-release "Linux" build/linux/game-pikanad.x86_64
```

### Web
```bash
godot --headless --export-release "Web" build/web/index.html
cd build/web && python3 -m http.server 8000
# Open http://localhost:8000
```

## Development History

| Sprint | Focus | Key Additions |
|--------|-------|---------------|
| 1 | Core Gameplay | 15 creatures, skills, items, evolution, dex |
| 2 | Trainers & Badges | AI system, 8 gym leaders, zone gating |
| 3 | Audio & Polish | Procedural audio, battle animations, day/night, weather |
| 4 | Meta Systems | Shiny, daily rewards, quests, stats |
| 5 | UI Overhaul | RPG theme, styled menus, tutorial system |
| 6 | Multiplayer & Trading | NPC/online trading, trade evolution, PvP rewards, ELO, leaderboard |

## License

All rights reserved.
