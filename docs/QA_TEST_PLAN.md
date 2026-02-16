# Game Pikanad — QA Test Plan

> Version: v0.6.0 | Save Version: 6 | Engine: Godot 4.4
> Last Updated: 2026-02-16

---

## Table of Contents

1. [Core Creature System](#1-core-creature-system)
2. [Skill System](#2-skill-system)
3. [Item System](#3-item-system)
4. [Status Effects](#4-status-effects)
5. [Battle System — Wild](#5-battle-system--wild)
6. [Battle System — Trainer](#6-battle-system--trainer)
7. [Battle System — PvP](#7-battle-system--pvp)
8. [Evolution System](#8-evolution-system)
9. [World & Zone System](#9-world--zone-system)
10. [NPC System](#10-npc-system)
11. [NPC Trading System](#11-npc-trading-system)
12. [Online Trading System](#12-online-trading-system)
13. [Economy — Shop & Inventory](#13-economy--shop--inventory)
14. [Progression — Badges & Level Cap](#14-progression--badges--level-cap)
15. [Creature Dex](#15-creature-dex)
16. [Daily Login Rewards](#16-daily-login-rewards)
17. [Daily Quests](#17-daily-quests)
18. [Player Stats](#18-player-stats)
19. [Shiny System](#19-shiny-system)
20. [Day/Night Cycle](#20-daynight-cycle)
21. [Weather System](#21-weather-system)
22. [Save & Load System](#22-save--load-system)
23. [Audio System](#23-audio-system)
24. [UI/UX](#24-uiux)
25. [Tutorial System](#25-tutorial-system)
26. [Multiplayer Hub & Leaderboard](#26-multiplayer-hub--leaderboard)
27. [Web3 / Wallet](#27-web3--wallet)
28. [Input & Controls](#28-input--controls)
29. [Performance & Edge Cases](#29-performance--edge-cases)

---

## 1. Core Creature System

### 1.1 Species Data (17 creatures)

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 1.1.1 | Load all 17 creature .tres files | All load without error, species_name non-empty | |
| 1.1.2 | Verify species_id uniqueness | IDs 1-17, no duplicates | |
| 1.1.3 | Verify dex_number ordering | Numbers 1-17, no gaps or duplicates | |
| 1.1.4 | Check element assignment (0-5) | Each creature has valid Element enum value | |
| 1.1.5 | Check rarity assignment (0-3) | Each creature has valid Rarity enum value | |
| 1.1.6 | Verify base stats > 0 | All base_hp, base_attack, base_defense, base_speed > 0 | |
| 1.1.7 | Verify sprite textures assigned | sprite_texture, battle_texture, overworld_texture all non-null | |
| 1.1.8 | Verify capture_rate in range 0.0-1.0 | No creature has rate < 0 or > 1 | |
| 1.1.9 | Verify exp_yield > 0 | All creatures give positive EXP | |
| 1.1.10 | Stat scaling at level 1 | stat_at_level(40, 1) = 40 (no scaling) | |
| 1.1.11 | Stat scaling at level 50 | stat_at_level(40, 50) = 40 + 40*49*0.12 = 275 | |
| 1.1.12 | is_nft_eligible() | Only RARE and LEGENDARY return true | |

### 1.2 Creature Instances

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 1.2.1 | Create instance with data + level | HP = max_hp, nickname = species_name, skills initialized | |
| 1.2.2 | display_name() with default nickname | Returns species_name | |
| 1.2.3 | display_name() with custom nickname | Returns custom nickname | |
| 1.2.4 | take_damage() reduces HP | HP decreases by exact amount | |
| 1.2.5 | take_damage() doesn't go below 0 | HP floors at 0 | |
| 1.2.6 | heal() restores HP | HP increases, capped at max_hp | |
| 1.2.7 | heal_full() resets HP + status | HP = max_hp, status cleared | |
| 1.2.8 | is_fainted() when HP = 0 | Returns true | |
| 1.2.9 | is_fainted() when HP > 0 | Returns false | |
| 1.2.10 | exp_to_next_level formula | level * 25 | |
| 1.2.11 | gain_exp() triggers level up | When exp >= threshold, level increments | |
| 1.2.12 | gain_exp() respects level cap 30 | Without badge 5, stops at level 30 | |
| 1.2.13 | gain_exp() respects level cap 50 | With badge 5, stops at level 50 | |
| 1.2.14 | Level-up heals 30% of old max HP | HP increases proportionally | |
| 1.2.15 | _init_skills_for_level() | Assigns last 4 learned skills from learn_set | |
| 1.2.16 | get_pending_new_skills() | Returns skills for current level not yet known | |
| 1.2.17 | try_learn_skill() with <4 skills | Auto-learns, returns true | |
| 1.2.18 | try_learn_skill() with 4 skills | Returns false (needs replacement) | |
| 1.2.19 | replace_skill(index, skill) | Swaps skill at given index | |
| 1.2.20 | reset_battle_modifiers() | All modifiers/status reset to default | |
| 1.2.21 | Held item ATK boost | attack() returns boosted value | |
| 1.2.22 | Held item DEF boost | defense() returns boosted value | |
| 1.2.23 | Held item SPD boost | speed() returns boosted value | |
| 1.2.24 | Shield status +50% DEF | defense() returns 1.5x base during Shield | |

### 1.3 Evolution Chains

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 1.3.1 | Fire chain: Flamepup→Blazefox (Lv12)→Pyrodrake (Lv24) | Evolves at correct levels | |
| 1.3.2 | Water chain: Aquafin→Tidecrab→Tsunariel | Evolves at correct levels | |
| 1.3.3 | Grass chain: Thornsprout→Floravine→Elderoak | Evolves at correct levels | |
| 1.3.4 | Wind chain: Breezeling→Zephyrix→Stormraptor | Evolves at correct levels | |
| 1.3.5 | Earth chain: Stoneling→Boulderkin (level-evo)→Titanrock (trade) | Mixed evo types | |
| 1.3.6 | Grass trade: Vinewhisker→Thornlord (trade only) | Only evolves via trade | |
| 1.3.7 | Creatures without evolution | can_evolve() = false, can_trade_evolve() = false | |

---

## 2. Skill System

### 2.1 Skill Data Integrity (36 skills)

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 2.1.1 | Load all 36 skill .tres files | All load without error | |
| 2.1.2 | All ATTACK skills have power > 0 | No zero-power attack skills | |
| 2.1.3 | All skills have accuracy 0.0-1.0 | Valid range | |
| 2.1.4 | All skills have valid element enum | Element 0-5 | |
| 2.1.5 | STATUS skills have status_chance > 0 | Can actually inflict status | |
| 2.1.6 | HEAL skills have heal_percent > 0 | Actually heals | |
| 2.1.7 | Priority skills (quick_attack) | is_priority = true, acts first | |
| 2.1.8 | Drain skills (drain_life, leech_seed) | drain_percent > 0, heals attacker | |
| 2.1.9 | Protect skill | is_protect = true, blocks damage for 1 turn | |
| 2.1.10 | Roar skill | ends_wild_battle = true, forces wild battle end | |
| 2.1.11 | Self-buff skills (iron_wall, tailwind) | buff_stat set, buff_duration > 0 | |
| 2.1.12 | Self-penalty skills (eruption) | self_stat_penalty > 0 after use | |

### 2.2 Learn Sets

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 2.2.1 | All 17 creatures have learn_set | learn_set.size() > 0 | |
| 2.2.2 | Learn set entries have valid skill_path | All paths resolve to SkillData | |
| 2.2.3 | Learn set levels are ascending | Sorted from low to high | |
| 2.2.4 | Level 1 skills | Every creature has at least 1 level-1 skill | |
| 2.2.5 | New skill notification | Level-up shows "learned X!" when new skill available | |

---

## 3. Item System

### 3.1 Item Data Integrity (15 items)

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 3.1.1 | Load all 15 item .tres files | All load without error | |
| 3.1.2 | Capture Ball catch_multiplier = 1.0 | Standard rate | |
| 3.1.3 | Super Ball catch_multiplier = 1.5 | Enhanced rate | |
| 3.1.4 | Ultra Ball catch_multiplier = 2.0 | High rate | |
| 3.1.5 | Master Ball catch_multiplier = 100.0 | Guaranteed catch | |
| 3.1.6 | Potion effect_value = 20 | Heals 20 HP | |
| 3.1.7 | Super Potion effect_value = 50 | Heals 50 HP | |
| 3.1.8 | Max Potion effect_value = 9999 | Full heal | |
| 3.1.9 | Revive restores fainted creature | Sets HP to 50% max | |
| 3.1.10 | Antidote cures Burn/Poison | cures_statuses includes BURN, POISON | |
| 3.1.11 | Awakening cures Sleep/Paralyze | cures_statuses includes SLEEP, PARALYZE | |
| 3.1.12 | Full Heal cures all statuses | cures_statuses includes all 5 types | |
| 3.1.13 | Everstone prevents evolution | held_effect = PREVENT_EVOLUTION | |
| 3.1.14 | Power Band boosts ATK | held_effect = BOOST_ATK, held_boost_percent = 0.1 | |
| 3.1.15 | Guard Charm boosts DEF | held_effect = BOOST_DEF, held_boost_percent = 0.1 | |
| 3.1.16 | Swift Feather boosts SPD | held_effect = BOOST_SPD, held_boost_percent = 0.1 | |
| 3.1.17 | All items have valid prices | price > 0 for purchasable items | |

### 3.2 Inventory Manager

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 3.2.1 | add_gold(100) | gold increases by 100, gold_changed signal emitted | |
| 3.2.2 | spend_gold(50) with 100 gold | gold = 50, returns true | |
| 3.2.3 | spend_gold(200) with 100 gold | gold unchanged, returns false | |
| 3.2.4 | add_item("Potion", 3) | items["Potion"] = 3, inventory_changed signal | |
| 3.2.5 | remove_item("Potion", 1) | Count decreases by 1 | |
| 3.2.6 | remove_item with count 0 | Item key removed from dict | |
| 3.2.7 | get_capture_balls() | Returns array of ball items with counts | |
| 3.2.8 | get_usable_battle_items() | Returns potions, status cures, revives | |
| 3.2.9 | has_item() check | Returns true only if count >= requested | |

---

## 4. Status Effects

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 4.1 | Burn: damage per turn | Deals % HP damage each turn | |
| 4.2 | Poison: damage per turn | Deals % HP damage each turn | |
| 4.3 | Sleep: skip turn | Cannot attack while asleep | |
| 4.4 | Paralyze: chance to skip turn | 25% chance to fail action | |
| 4.5 | Shield: +50% DEF | Defense stat increases while active | |
| 4.6 | Status duration tick-down | remaining_turns decreases each turn, expires at 0 | |
| 4.7 | Status cure items clear status | Antidote clears Burn/Poison, etc. | |
| 4.8 | heal_full() clears status | Status reset to NONE | |
| 4.9 | Status stacking | New status replaces existing (no stacking) | |
| 4.10 | Status display in battle HUD | Status name shown with correct color | |

---

## 5. Battle System — Wild

### 5.1 Battle Flow

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 5.1.1 | Walk into wild creature triggers battle | Scene transitions to battle_scene | |
| 5.1.2 | Battle starts with player's first alive creature | Correct creature shown | |
| 5.1.3 | Enemy creature level within zone range | Level matches zone configuration | |
| 5.1.4 | Entry slide-in animation plays | Both sprites animate into position | |
| 5.1.5 | Player gets 4 action buttons | Fight, Items, Catch, Run visible | |
| 5.1.6 | Fight opens skill selection | 1-4 skills shown with element colors | |

### 5.2 Damage Calculation

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 5.2.1 | Base damage formula | ATK * power / DEF * modifiers | |
| 5.2.2 | Type advantage (1.5x) | Fire vs Grass = super effective | |
| 5.2.3 | Type disadvantage (0.67x) | Fire vs Water = not effective | |
| 5.2.4 | Neutral matchup (1.0x) | Fire vs Wind = normal damage | |
| 5.2.5 | STAB bonus | Same element skill + creature bonus | |
| 5.2.6 | Accuracy miss | Skill with <1.0 accuracy can miss | |
| 5.2.7 | Critical hit chance | Random extra damage | |
| 5.2.8 | Floating damage numbers appear | Numbers pop up over target | |
| 5.2.9 | Screen flash on hit | Brief white flash | |
| 5.2.10 | Effectiveness text shown | "Super effective!" / "Not very effective..." | |
| 5.2.11 | Weather damage bonus | Rain: +20% Water, -20% Fire; Sandstorm: +10% Earth | |

### 5.3 Turn Order

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 5.3.1 | Faster creature goes first | Higher speed acts first | |
| 5.3.2 | Priority skill goes first regardless | quick_attack always acts first | |
| 5.3.3 | Speed tie resolved randomly | Both outcomes possible | |

### 5.4 Catch System

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 5.4.1 | Capture Ball throw | Animation plays, catch attempt made | |
| 5.4.2 | Catch success | Creature added to party, ball consumed | |
| 5.4.3 | Catch fail | Ball consumed, battle continues | |
| 5.4.4 | Catch rate scales with HP | Lower HP = higher catch chance | |
| 5.4.5 | Master Ball guaranteed catch | Always succeeds | |
| 5.4.6 | Party full (6 creatures) | Catch still works (creature stored?) or blocked | |
| 5.4.7 | Caught creature marked in Dex | DexManager.mark_caught() called | |
| 5.4.8 | Capture Ball SFX | throw + success/fail sounds play | |
| 5.4.9 | Quest tracking | "catch" quest incremented on success | |
| 5.4.10 | Stats tracking | creatures_caught incremented | |

### 5.5 Run System

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 5.5.1 | Run from wild battle | Returns to overworld | |
| 5.5.2 | Run fail chance | Sometimes fails based on speed comparison | |
| 5.5.3 | Roar skill forces run | Battle ends immediately for wild encounters | |

### 5.6 Battle Items

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 5.6.1 | Use Potion in battle | HP restored, item consumed, turn used | |
| 5.6.2 | Use status cure in battle | Status cleared, item consumed | |
| 5.6.3 | Use Revive in battle | Fainted party member revived | |
| 5.6.4 | Item used SFX | use_potion sound plays | |

### 5.7 Battle End

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 5.7.1 | Win: enemy HP = 0 | EXP gained, return to overworld | |
| 5.7.2 | Lose: all party fainted | Return to overworld, party healed? | |
| 5.7.3 | EXP distribution | Winning creature gains exp_yield of defeated | |
| 5.7.4 | Level up notification | "Level Up!" message shown | |
| 5.7.5 | New skill learned on level up | Skill learn dialog appears | |
| 5.7.6 | Evolution check after level up | If can_evolve(), evolution screen shows | |
| 5.7.7 | Enemy marked as "seen" in Dex | DexManager.mark_seen() called on battle start | |
| 5.7.8 | battles_won stat incremented | StatsManager tracks wins | |
| 5.7.9 | battles_lost stat incremented | StatsManager tracks losses | |
| 5.7.10 | total_damage_dealt tracked | All player damage accumulated | |
| 5.7.11 | Battle speed toggle (B key) | Toggles between 1x and 2x speed | |

---

## 6. Battle System — Trainer

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 6.1 | Trainer pre-battle dialogue | Lines shown before battle starts | |
| 6.2 | Catch button hidden | Cannot catch trainer's creatures | |
| 6.3 | Run button hidden | Cannot run from trainer battles | |
| 6.4 | AI RANDOM: picks random skill | Skill selection is random | |
| 6.5 | AI SMART: uses type advantage | Prefers super-effective skills | |
| 6.6 | AI SMART: heals when low HP | Uses potions when creature HP < 30% | |
| 6.7 | AI SMART: uses status skills | Applies status effects strategically | |
| 6.8 | AI EXPERT: defensive play | Uses protect/shield when advantageous | |
| 6.9 | AI EXPERT: finisher priority | Targets low-HP creatures aggressively | |
| 6.10 | AI EXPERT: uses DOT | Applies Burn/Poison strategically | |
| 6.11 | Trainer switches on faint | Next creature sent out automatically | |
| 6.12 | Trainer party dots shown | HUD shows remaining opponent creatures | |
| 6.13 | Defeat all trainer creatures | Win condition met, reward given | |
| 6.14 | Trainer gold reward | Gold added to inventory | |
| 6.15 | Trainer item rewards | Items added to inventory | |
| 6.16 | Badge earned on gym leader defeat | BadgeManager.earn_badge() called | |
| 6.17 | Badge earn SFX plays | badge_earn sound | |
| 6.18 | Trainer marked as defeated | BadgeManager.mark_defeated(trainer_id) | |
| 6.19 | Re-interact defeated trainer | Shows "already beaten" dialogue | |
| 6.20 | trainers_defeated stat | StatsManager incremented | |
| 6.21 | Trainer battle music | TRAINER_BATTLE track plays | |

---

## 7. Battle System — PvP

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 7.1 | PvP queue join | Queue position shown | |
| 7.2 | PvP match found | battle_started signal, scene transitions | |
| 7.3 | Catch/Run buttons hidden | Only Fight available | |
| 7.4 | Server-driven turn flow | Turns alternate via NetworkManager signals | |
| 7.5 | PvP win: gold reward (300G) | InventoryManager.add_gold(300) | |
| 7.6 | PvP lose: gold reward (50G) | InventoryManager.add_gold(50) | |
| 7.7 | PvP win: ELO increases | StatsManager.elo_rating goes up | |
| 7.8 | PvP lose: ELO decreases | StatsManager.elo_rating goes down (min 100) | |
| 7.9 | PvP win: pvp_wins stat | StatsManager incremented | |
| 7.10 | PvP lose: pvp_losses stat | StatsManager incremented | |
| 7.11 | PvP win: quest tracking | "win_pvp" quest incremented | |
| 7.12 | Post-battle summary screen | Shows VICTORY/DEFEAT, gold, ELO, record | |
| 7.13 | Summary "Continue" button | Returns to overworld | |
| 7.14 | PVP_WIN SFX on win | Sound plays | |
| 7.15 | PVP_LOSE SFX on loss | Sound plays | |
| 7.16 | Disconnect during PvP | Handles gracefully, no crash | |

---

## 8. Evolution System

### 8.1 Level-Up Evolution

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 8.1.1 | can_evolve() at evolution_level | Returns true | |
| 8.1.2 | can_evolve() below evolution_level | Returns false | |
| 8.1.3 | can_evolve() with Everstone held | Returns false | |
| 8.1.4 | can_evolve() for trade-evo species | Returns false (guarded) | |
| 8.1.5 | evolve() swaps data to evolved species | data = evolves_into | |
| 8.1.6 | evolve() preserves HP ratio | HP proportion maintained | |
| 8.1.7 | evolve() preserves NFT info | is_nft, nft_token_id unchanged | |
| 8.1.8 | evolve() updates nickname if default | Nickname changes to new species name | |
| 8.1.9 | evolve() keeps custom nickname | Custom nickname unchanged | |
| 8.1.10 | evolve() re-inits skills | New species learn_set applied | |
| 8.1.11 | Evolution screen shows | Particle burst + stat comparison | |
| 8.1.12 | EVOLVE_SPARKLE SFX | Plays during evolution | |
| 8.1.13 | EVOLVE_COMPLETE SFX | Plays when done | |
| 8.1.14 | creatures_evolved stat | StatsManager incremented | |
| 8.1.15 | "evolve" quest tracking | QuestManager incremented | |

### 8.2 Trade Evolution

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 8.2.1 | can_trade_evolve() for Boulderkin | Returns true (trade_evolution = true) | |
| 8.2.2 | can_trade_evolve() for Vinewhisker | Returns true | |
| 8.2.3 | can_trade_evolve() for normal species | Returns false | |
| 8.2.4 | can_trade_evolve() with Everstone | Returns false | |
| 8.2.5 | trade_evolve() swaps to evolved species | Boulderkin → Titanrock | |
| 8.2.6 | trade_evolve() swaps to evolved species | Vinewhisker → Thornlord | |
| 8.2.7 | Trade evo triggers after NPC trade | Auto-evolves during trade completion | |
| 8.2.8 | Trade evo triggers after online trade | Auto-evolves during trade completion | |
| 8.2.9 | Evolved creature marked in Dex | Both pre and post evo species caught | |
| 8.2.10 | "trade_evolution" tutorial triggers | Shows on first trade evo | |
| 8.2.11 | NPC trade menu shows evo hint | ">> Will evolve after trade!" label | |

---

## 9. World & Zone System

### 9.1 Overworld (Starter Meadow)

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 9.1.1 | Spawn with starter creature | Party gets Flamepup Lv5 if empty | |
| 9.1.2 | 8 wild creatures spawn | Random meadow species, non-overlapping player | |
| 9.1.3 | 5 portals created | Fire Volcano, Water Coast, Forest Grove, Earth Caves, Champion Arena | |
| 9.1.4 | 5 NPCs created | Nurse Joy, Merchant, Old Man, Leader Kai, Trader | |
| 9.1.5 | Terrain patches render | 18 color patches, 25 grass tufts visible | |
| 9.1.6 | Minimap visible | Top-right, shows player/portals/NPCs as dots | |
| 9.1.7 | Day/night tint applied | CanvasModulate matches current time phase | |
| 9.1.8 | Weather set to CLEAR | No particles in Starter Meadow | |
| 9.1.9 | zone_weather meta set | GameManager.get_meta("battle_zone") = "Starter Meadow" | |
| 9.1.10 | Starter Meadow added to zones_explored | StatsManager tracks zone | |
| 9.1.11 | Tutorial triggers on first visit | Welcome + movement tutorials fire | |
| 9.1.12 | Quest panel opens with Q key | Quest overlay shows | |

### 9.2 Zone Portals

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 9.2.1 | Portal visual (gold archway + glow) | Animated pulsing glow effect | |
| 9.2.2 | Enter portal transitions zone | Scene changes with fade effect | |
| 9.2.3 | Auto-save on zone transition | SaveManager.save_game() called | |
| 9.2.4 | Spawn offset applied | Player spawns at correct position in target zone | |
| 9.2.5 | Portal enter SFX | portal_enter sound plays | |
| 9.2.6 | "first_portal" tutorial | Shows on first portal use | |

### 9.3 Zone Access Gating

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 9.3.1 | Sky Peaks requires badge 5 | Blocked without badge, dialogue shown | |
| 9.3.2 | Lava Core requires badge 6 | Blocked without badge | |
| 9.3.3 | Champion Arena requires 7+ badges | Blocked with < 7 badges | |
| 9.3.4 | Access granted with correct badges | Portal works normally | |

### 9.4 Zone-Specific Features

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 9.4.1 | Each zone has unique wild species | Different creatures per zone | |
| 9.4.2 | Each zone has return portal to Meadow | Can always go back | |
| 9.4.3 | Each zone has gym leader NPC | Trainer with badge reward | |
| 9.4.4 | Zone-specific weather | Water Coast: Rain, Sky Peaks: Snow, Earth Caves: Sandstorm, Forest Grove: Leaves | |
| 9.4.5 | Zone-specific battle backgrounds | Different sky/ground/decorations per zone | |
| 9.4.6 | Zone name shown on minimap | Label matches current zone | |

---

## 10. NPC System

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 10.1 | NPC visual: head + body + name label | Multi-part body renders correctly | |
| 10.2 | Floating "!" when interactable | Shows when player in range, bobs up/down | |
| 10.3 | Name label shows "[E]" suffix in range | Indicates interaction possible | |
| 10.4 | TALKER icon "..." (dim) | Correct icon + color | |
| 10.5 | HEALER icon "+" (green) | Correct icon + color | |
| 10.6 | SHOPKEEPER icon "$" (gold) | Correct icon + color | |
| 10.7 | TRAINER icon "!" (red) | Correct icon + color | |
| 10.8 | TRADER icon "<>" (cyan) | Correct icon + color | |
| 10.9 | TALKER interaction | Dialogue box opens with lines | |
| 10.10 | HEALER interaction | Party fully healed, dialogue confirms | |
| 10.11 | SHOPKEEPER interaction | Shop menu opens with correct items | |
| 10.12 | TRAINER interaction (undefeated) | Pre-battle dialogue, then trainer battle | |
| 10.13 | TRAINER interaction (defeated) | "Already beaten" dialogue | |
| 10.14 | TRADER interaction | NPC trade menu opens | |
| 10.15 | TRADER with empty party | "No creatures to trade" message | |
| 10.16 | NPC interact SFX | npc_interact sound plays | |
| 10.17 | "first_npc" tutorial trigger | Shows on first NPC interaction | |

---

## 11. NPC Trading System

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 11.1 | Trade menu opens | Party list shown on left, NPC offer on right | |
| 11.2 | Fainted creatures disabled | Can't select fainted creatures to trade | |
| 11.3 | Last alive creature blocked | Can't trade if only 1 non-fainted creature | |
| 11.4 | Select creature shows NPC offer | NPC generates comparable creature | |
| 11.5 | NPC offer rarity ±1 | Offered creature within 1 rarity of player's | |
| 11.6 | NPC prioritizes unowned species | Prefers species player hasn't caught | |
| 11.7 | NPC avoids same species | Won't offer same species back | |
| 11.8 | NPC avoids same element (when possible) | Prefers different element | |
| 11.9 | Offered level ±2 of player's | Level within reasonable range | |
| 11.10 | Stat comparison panel | Shows HP/ATK/DEF/SPD yours vs theirs | |
| 11.11 | Green/red color coding | Green = stat better, Red = stat worse | |
| 11.12 | Confirm trade executes swap | Player creature removed, NPC creature added | |
| 11.13 | Trade-evo creature shows hint | ">> Will evolve after trade!" label | |
| 11.14 | Trade evo triggers on confirm | Boulderkin→Titanrock / Vinewhisker→Thornlord | |
| 11.15 | Received creature marked in Dex | DexManager.mark_caught() called | |
| 11.16 | trades_completed stat | StatsManager incremented | |
| 11.17 | "complete_trade" quest | QuestManager incremented | |
| 11.18 | "first_trade" tutorial | Shows on first successful trade | |
| 11.19 | TRADE_COMPLETE SFX | Sound plays on confirm | |
| 11.20 | Cancel closes menu | Returns to overworld state | |
| 11.21 | NPC offer includes shiny roll | _offered_creature.roll_shiny() called | |
| 11.22 | Party list updates after trade | New creature visible, old removed | |

---

## 12. Online Trading System

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 12.1 | Trade menu shows connection status | "Connected" or "Not connected" message | |
| 12.2 | Select creature sends offer | NetworkManager.send_trade_offer() called | |
| 12.3 | TRADE_OFFER SFX on send | Sound plays | |
| 12.4 | Receive trade offer | Their creature shown with stats | |
| 12.5 | Accept trade | send_trade_accept() called | |
| 12.6 | Trade rejected by other | "Trade rejected" message, state reset | |
| 12.7 | Trade completed | Creatures swapped in party | |
| 12.8 | Trade-evo triggers on receive | Auto-evolves if applicable | |
| 12.9 | Disconnection handling | "Connection lost!" message, no crash | |
| 12.10 | Close during active trade | send_trade_reject() called before closing | |
| 12.11 | Creature serialization | All fields preserved (level, skills, shiny, items) | |
| 12.12 | Creature deserialization | Reconstructed creature matches original | |

---

## 13. Economy — Shop & Inventory

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 13.1 | Shop opens with correct items | Items from NPC's shop_items array | |
| 13.2 | Buy item with sufficient gold | Gold deducted, item added, count updated | |
| 13.3 | Buy item with insufficient gold | Button disabled, purchase blocked | |
| 13.4 | Item prices displayed correctly | Gold amount shown next to each item | |
| 13.5 | Badge-gated shop items | Super Ball requires badge 2, Ultra Ball requires badge 6 | |
| 13.6 | Item type color dots | Different colors for ball/potion/cure/held items | |
| 13.7 | "shop_hint" tutorial | Shows on first shop visit | |
| 13.8 | Shop SFX | MENU_OPEN on open, BUTTON_CLICK on buy | |

---

## 14. Progression — Badges & Level Cap

### 14.1 Badge System

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 14.1.1 | 8 badges total | Sprout, Blaze, Tide, Grove, Rumble, Tempest, Obsidian, Champion | |
| 14.1.2 | Badge earned on gym leader defeat | BadgeManager.earn_badge(N) called | |
| 14.1.3 | Badge display: shimmer on earned | Visual effect on badge panel | |
| 14.1.4 | Badge display: dark outline unearned | Distinguishes earned vs locked | |
| 14.1.5 | Badge count tracks correctly | badge_count() matches actual earned | |
| 14.1.6 | badge_earned signal emitted | Signal fires on earn | |

### 14.2 Level Cap

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 14.2.1 | Default level cap = 30 | Can't gain EXP past 30 without badges | |
| 14.2.2 | Badge 5 raises cap to 50 | Can now level to 50 | |
| 14.2.3 | EXP stops at cap | gain_exp() returns false at cap | |

---

## 15. Creature Dex

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 15.1 | Dex shows 17 total entries | Grid displays all species slots | |
| 15.2 | UNSEEN: dark card | No info visible | |
| 15.3 | SEEN: silver indicator | Species visible but marked as seen only | |
| 15.4 | CAUGHT: gold star | Full info with caught indicator | |
| 15.5 | Completion percentage | Accurate: caught_count / 17 * 100 | |
| 15.6 | Element border colors | Card borders match creature element color | |
| 15.7 | Dex milestone: 25% (4) → Master Ball | Item granted once | |
| 15.8 | Dex milestone: 50% (8) → Shiny Charm | has_shiny_charm meta set | |
| 15.9 | Dex milestone: 75% (12) → EXP Charm | Reward granted | |
| 15.10 | Dex milestone: 100% (17) → Crown | Reward granted | |
| 15.11 | Milestone only granted once | Re-earning threshold doesn't duplicate reward | |
| 15.12 | Open Dex with X key | Opens from overworld | |
| 15.13 | Open Dex from main menu | Loads save data first, then opens | |
| 15.14 | Close Dex restores game state | Returns to previous state, not hardcoded OVERWORLD | |
| 15.15 | "dex_hint" tutorial | Shows first time | |

---

## 16. Daily Login Rewards

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 16.1 | First login shows reward popup | Day 0: 100G reward displayed | |
| 16.2 | Day cycle: 0→1→2→3→4→5→6→0 | 7-day rotation | |
| 16.3 | Day 0: 100 Gold | Gold added | |
| 16.4 | Day 1: Potion | Item added | |
| 16.5 | Day 2: Capture Ball | Item added | |
| 16.6 | Day 3: Super Ball | Item added | |
| 16.7 | Day 4: 500 Gold | Gold added | |
| 16.8 | Day 5: Revive | Item added | |
| 16.9 | Day 6: Master Ball | Item added | |
| 16.10 | Same-day re-login | No duplicate reward | |
| 16.11 | Streak resets after gap | Missing a day resets streak | |
| 16.12 | Claim button works | Reward granted, popup closes | |
| 16.13 | Persists across sessions | Saved/loaded correctly | |

---

## 17. Daily Quests

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 17.1 | 3 quests generated per day | active_quests.size() == 3 | |
| 17.2 | Quests are date-seeded | Same quests for same date | |
| 17.3 | Different quests on different days | New set generated | |
| 17.4 | 6 quest types in pool | catch, win_battle, explore_zone, evolve, win_pvp, complete_trade | |
| 17.5 | "catch" increments on creature catch | Progress updates | |
| 17.6 | "win_battle" increments on battle win | Progress updates | |
| 17.7 | "explore_zone" increments on zone entry | Progress updates | |
| 17.8 | "evolve" increments on evolution | Progress updates | |
| 17.9 | "win_pvp" increments on PvP win | Progress updates | |
| 17.10 | "complete_trade" increments on trade | Progress updates | |
| 17.11 | Quest completed signal | Fires when progress >= target | |
| 17.12 | Claim quest: gold reward | Gold added to inventory | |
| 17.13 | Claim quest: item reward | Item added if specified | |
| 17.14 | Can't double-claim | claimed flag prevents re-claim | |
| 17.15 | Quest panel UI (Q key) | Shows progress bars, claim buttons | |
| 17.16 | "quest_hint" tutorial | Shows first time Q pressed | |
| 17.17 | Persists across sessions | Saved/loaded correctly, date check on load | |

---

## 18. Player Stats

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 18.1 | battles_won increments | On wild/trainer battle win | |
| 18.2 | battles_lost increments | On battle loss | |
| 18.3 | pvp_wins increments | On PvP victory | |
| 18.4 | pvp_losses increments | On PvP defeat | |
| 18.5 | elo_rating updates | Increases on win, decreases on loss, min 100 | |
| 18.6 | trades_completed increments | On any trade (NPC or online) | |
| 18.7 | creatures_caught increments | On successful catch | |
| 18.8 | creatures_evolved increments | On any evolution (level or trade) | |
| 18.9 | trainers_defeated increments | On trainer battle win | |
| 18.10 | total_damage_dealt accumulates | All player damage in battles | |
| 18.11 | zones_explored tracks unique zones | No duplicates, count matches | |
| 18.12 | shinies_found increments | On shiny catch | |
| 18.13 | play_time_seconds ticks | Increases during gameplay (not in MENU) | |
| 18.14 | Stats panel shows all stats | 13 rows displayed correctly | |
| 18.15 | Stats panel from main menu | Loads save first, displays correctly | |
| 18.16 | get_play_time_string() format | "Xh Ym" format | |
| 18.17 | Persists across sessions | All stats saved/loaded | |

---

## 19. Shiny System

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 19.1 | Shiny rate 1/200 (0.5%) default | roll_shiny() uses SHINY_RATE | |
| 19.2 | Shiny rate 1/50 (2%) with charm | roll_shiny() uses SHINY_CHARM_RATE | |
| 19.3 | Shiny overworld: gold tint | Gold modulate on overworld sprite | |
| 19.4 | Shiny battle: sparkle particles | CPUParticles2D effect in battle | |
| 19.5 | Shiny indicator: star icon | Star shown in party menu, battle HUD | |
| 19.6 | Shiny persists in save | is_shiny saved/loaded correctly | |
| 19.7 | Shiny in NPC trade offers | roll_shiny() called on NPC offer | |
| 19.8 | shinies_found stat | Incremented on shiny catch | |

---

## 20. Day/Night Cycle

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 20.1 | Morning (6-12): warm white tint | Color(1.0, 0.95, 0.9) | |
| 20.2 | Afternoon (12-18): neutral tint | Color(1.0, 1.0, 1.0) | |
| 20.3 | Evening (18-22): orange tint | Color(0.9, 0.7, 0.5) | |
| 20.4 | Night (22-6): blue tint | Color(0.4, 0.4, 0.7) | |
| 20.5 | Phase transition tween | Smooth 2-second color transition | |
| 20.6 | phase_changed signal | Emitted when time phase changes | |
| 20.7 | Uses real system time | Matches device clock | |

---

## 21. Weather System

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 21.1 | Starter Meadow: CLEAR | No weather particles | |
| 21.2 | Water Coast: RAIN (60% chance) | Rain particles when active | |
| 21.3 | Sky Peaks: SNOW (50% chance) | Snow particles when active | |
| 21.4 | Earth Caves: SANDSTORM (40% chance) | Sand particles when active | |
| 21.5 | Forest Grove: LEAVES (70% chance) | Leaf particles when active | |
| 21.6 | Rain battle bonus: +20% Water damage | Water skills boosted | |
| 21.7 | Rain battle penalty: -20% Fire damage | Fire skills weakened | |
| 21.8 | Sandstorm battle bonus: +10% Earth damage | Earth skills boosted | |
| 21.9 | Weather particles visual quality | No flickering, appropriate density | |

---

## 22. Save & Load System

### 22.1 Basic Save/Load

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 22.1.1 | Save creates file | user://save_data.json exists | |
| 22.1.2 | Save format is valid JSON | Can be parsed without errors | |
| 22.1.3 | Save version = 6 | save_version field present | |
| 22.1.4 | Load restores gold | Exact gold amount | |
| 22.1.5 | Load restores items | All items with correct counts | |
| 22.1.6 | Load restores party | All creatures with stats, skills, items | |
| 22.1.7 | Load restores dex | Seen/caught status for all species | |
| 22.1.8 | Load restores badges | All 8 badge states + defeated_trainers | |
| 22.1.9 | Load restores daily rewards | Streak, last login date | |
| 22.1.10 | Load restores quests | Active quests with progress | |
| 22.1.11 | Load restores stats | All 13+ stat values | |
| 22.1.12 | Load restores tutorial | Completed step tracking | |
| 22.1.13 | Auto-save on zone transition | Triggered automatically | |
| 22.1.14 | has_save() check | True only when file exists | |

### 22.2 Party Serialization

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 22.2.1 | Species path saved | Correct .tres path | |
| 22.2.2 | Nickname preserved | Custom + default names | |
| 22.2.3 | Level + HP + EXP preserved | Exact values | |
| 22.2.4 | Active skills saved | Skill resource paths array | |
| 22.2.5 | Held item saved | Item resource path if equipped | |
| 22.2.6 | NFT info saved | is_nft + nft_token_id | |
| 22.2.7 | Shiny flag saved | is_shiny preserved | |

### 22.3 Save Migration

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 22.3.1 | v1 → v6 migration | Balls→inventory, dex seeded, badges/quests/stats/tutorial/pvp initialized | |
| 22.3.2 | v2 → v6 migration | Badges added, rest initialized | |
| 22.3.3 | v3 → v6 migration | Daily/quests/stats/tutorial/pvp initialized | |
| 22.3.4 | v4 → v6 migration | Tutorial/pvp initialized | |
| 22.3.5 | v5 → v6 migration | PvP stats initialized (wins=0, losses=0, elo=1000, trades=0) | |
| 22.3.6 | v6 → v6 (no migration) | Data loaded as-is | |
| 22.3.7 | No data loss on migration | All existing fields preserved | |
| 22.3.8 | Corrupted save handling | load_game() returns false, no crash | |
| 22.3.9 | Empty save file | load_game() returns false, no crash | |

---

## 23. Audio System

### 23.1 Music

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 23.1.1 | MENU track on main menu | Plays on scene load | |
| 23.1.2 | OVERWORLD track in overworld/zones | Plays and loops | |
| 23.1.3 | BATTLE track in wild battles | Switches on battle start | |
| 23.1.4 | TRAINER_BATTLE track | Different track for trainer battles | |
| 23.1.5 | VICTORY track on win | Plays after battle victory | |
| 23.1.6 | EVOLUTION track | Plays during evolution screen | |
| 23.1.7 | SHOP track in shop | Plays when shop opens | |
| 23.1.8 | CHAMPION track in Champion Arena | Unique track for final zone | |
| 23.1.9 | Crossfade between tracks | Smooth 0.8s fade transition | |
| 23.1.10 | Same track doesn't restart | play_track() skips if already playing | |
| 23.1.11 | Volume control | music_volume 0.0-1.0 affects playback | |

### 23.2 Sound Effects (23 total)

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 23.2.1 | BUTTON_CLICK | Fires on button press | |
| 23.2.2 | MENU_OPEN / MENU_CLOSE | On menu open/close | |
| 23.2.3 | ATTACK_HIT | On damage dealt | |
| 23.2.4 | SUPER_EFFECTIVE | On 1.5x type matchup | |
| 23.2.5 | NOT_EFFECTIVE | On 0.67x type matchup | |
| 23.2.6 | MISS | On attack miss | |
| 23.2.7 | FAINT | On creature faint | |
| 23.2.8 | STEP | On player movement | |
| 23.2.9 | PORTAL_ENTER | On zone transition | |
| 23.2.10 | NPC_INTERACT | On NPC interaction | |
| 23.2.11 | USE_POTION | On item use in battle | |
| 23.2.12 | BALL_THROW | On capture attempt | |
| 23.2.13 | CAPTURE_SUCCESS / FAIL | On catch result | |
| 23.2.14 | EVOLVE_SPARKLE / COMPLETE | During evolution | |
| 23.2.15 | LEVEL_UP | On level gain | |
| 23.2.16 | BADGE_EARN | On badge acquisition | |
| 23.2.17 | TRADE_OFFER | On trade selection | |
| 23.2.18 | TRADE_COMPLETE | On trade confirmation | |
| 23.2.19 | PVP_WIN | On PvP victory | |
| 23.2.20 | PVP_LOSE | On PvP defeat | |
| 23.2.21 | 4-channel SFX pool | Multiple SFX can overlap without cutting | |
| 23.2.22 | SFX volume control | sfx_volume 0.0-1.0 | |

---

## 24. UI/UX

### 24.1 Main Menu

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 24.1.1 | Title "Game Pikanad" in gold | Correct font size 24, shadow | |
| 24.1.2 | Subtitle text | "A Creature RPG on Monad" | |
| 24.1.3 | ">> New Game" button | Starts new game, transitions to overworld | |
| 24.1.4 | ">> Continue" button | Loads save, visible only with save file | |
| 24.1.5 | ">> Pikanadex" button | Opens dex, visible only with save | |
| 24.1.6 | ">> Stats" button | Opens stats panel, visible only with save | |
| 24.1.7 | ">> Multiplayer" button | Opens multiplayer hub, visible only with save | |
| 24.1.8 | ">> Connect Wallet" (web only) | Triggers MetaMask/wallet connection | |
| 24.1.9 | ">> Quit" (desktop only) | Closes application | |
| 24.1.10 | Floating blue particles | 20 particles, faint blue, continuous | |
| 24.1.11 | Creature showcase (3 silhouettes) | Breathing animation, 3 element colors | |
| 24.1.12 | Version label "v0.6.0" | Bottom-right corner | |
| 24.1.13 | Daily reward popup | Shows on launch if reward available | |
| 24.1.14 | Dark background | COL_BG_DARKEST color | |
| 24.1.15 | Focus on first button | Keyboard navigation works | |

### 24.2 Battle HUD

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 24.2.1 | 2x2 action grid | Fight / Items / Catch / Run layout | |
| 24.2.2 | Creature names + levels | Both sides displayed | |
| 24.2.3 | HP bars with color | Green→Yellow→Red gradient | |
| 24.2.4 | Element badges | Element name in colored text | |
| 24.2.5 | EXP bar | Shows progress to next level | |
| 24.2.6 | Skill grid with element borders | 4 skills, colored by element | |
| 24.2.7 | Status effect color display | Burn=orange, Poison=purple, etc. | |
| 24.2.8 | Damage pop tween | Numbers float up and fade | |
| 24.2.9 | Trainer party dots | Shows remaining opponent creatures | |
| 24.2.10 | Battle speed indicator | Shows 2x when toggled | |

### 24.3 Party Menu

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 24.3.1 | Opens with TAB key | Overlay appears | |
| 24.3.2 | 6 creature cards max | Element borders, sprite thumbnails | |
| 24.3.3 | HP bars on each card | Mini bars with current/max | |
| 24.3.4 | FAINTED label | Shows on fainted creatures | |
| 24.3.5 | Shiny star indicator | Star on shiny creatures | |
| 24.3.6 | Quick heal button | Visible when damaged + has potions | |
| 24.3.7 | Close returns to previous state | Doesn't disrupt game flow | |

### 24.4 Dialogue Box

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 24.4.1 | Speaker name tab | Shows NPC name | |
| 24.4.2 | Text displays sequentially | Press accept to advance | |
| 24.4.3 | Blinking triangle indicator | Shows when more text available | |
| 24.4.4 | Closes on last line | Callback fires | |
| 24.4.5 | Game state PAUSED during dialogue | Player can't move | |

### 24.5 Shop Menu

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 24.5.1 | Item type color dots | Visual distinction between types | |
| 24.5.2 | Gold prices displayed | Correct amounts | |
| 24.5.3 | Disabled buy when can't afford | Button grayed out | |
| 24.5.4 | Gold balance shown | Current gold in header | |

### 24.6 Theme Consistency

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 24.6.1 | RPG double-border panels | All panels use consistent style | |
| 24.6.2 | Button states | Normal/hover/pressed/disabled/focus all styled | |
| 24.6.3 | Font sizes consistent | 8-16px range, hierarchy clear | |
| 24.6.4 | Color palette adherence | All UI uses ThemeManager constants | |

---

## 25. Tutorial System

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 25.1 | "welcome" on first overworld | Fires after 0.5s delay | |
| 25.2 | "movement" chains after welcome | Fires 1.0s after welcome closes | |
| 25.3 | "first_creature" when party=1 | Fires after 1.5s | |
| 25.4 | "first_battle" on first battle | Shows battle instructions | |
| 25.5 | "type_advantage" on first super effective | Explains elements | |
| 25.6 | "first_npc" on first NPC interact | Explains NPC types | |
| 25.7 | "first_portal" on first portal use | Explains zone system | |
| 25.8 | "shop_hint" on first shop | Tip about buying items | |
| 25.9 | "dex_hint" on first dex open | Tip about creature tracking | |
| 25.10 | "quest_hint" on first quest view | Tip about daily quests | |
| 25.11 | "first_trade" on first trade completion | Explains trading | |
| 25.12 | "trade_evolution" on first trade evo | Explains trade evolution mechanic | |
| 25.13 | Gold "TUTORIAL" header | Distinct visual from normal dialogue | |
| 25.14 | "[Skip All Tutorials: press ESC]" | Shows on last line of each tutorial | |
| 25.15 | skip_all() marks all complete | No more tutorials show | |
| 25.16 | Completed tutorials don't repeat | Once shown, never again | |
| 25.17 | Tutorial state persists | Saved/loaded in save v5+ | |

---

## 26. Multiplayer Hub & Leaderboard

### 26.1 Multiplayer Hub

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 26.1.1 | Opens from main menu | ">> Multiplayer" button works | |
| 26.1.2 | Connection status shown | "Connected" or "Offline" label | |
| 26.1.3 | ">> Online Trade" button | Opens trade_menu.gd | |
| 26.1.4 | ">> PvP Battle" button | Transitions to PvP queue scene | |
| 26.1.5 | ">> Leaderboard" button | Opens leaderboard panel | |
| 26.1.6 | Close button | Returns to main menu | |

### 26.2 Leaderboard Panel

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 26.2.1 | ELO Rating featured (large) | Prominent display | |
| 26.2.2 | PvP Wins (green) | Correct count + color | |
| 26.2.3 | PvP Losses (red) | Correct count + color | |
| 26.2.4 | Win Rate percentage | Accurate calculation (0 div safe) | |
| 26.2.5 | Total PvP count | wins + losses | |
| 26.2.6 | Trades Done (cyan) | Correct count | |
| 26.2.7 | 0 PvP games: 0.0% win rate | No division by zero crash | |
| 26.2.8 | Close button | Returns to hub | |

---

## 27. Web3 / Wallet

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 27.1 | Wallet button visible only on web | Hidden on desktop | |
| 27.2 | Connect wallet triggers MetaMask | JavaScriptBridge call | |
| 27.3 | wallet_connected signal | Address displayed, button updates | |
| 27.4 | wallet_error signal | Error message shown | |
| 27.5 | short_address() format | "0xABCD...1234" truncated | |
| 27.6 | NFT eligibility check | Only RARE+ creatures | |
| 27.7 | Quit button hidden on web | Only visible on desktop | |

---

## 28. Input & Controls

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 28.1 | WASD movement | 8-directional movement | |
| 28.2 | Arrow key movement | Same as WASD | |
| 28.3 | Shift to run (1.5x speed) | Speed increases while held | |
| 28.4 | TAB opens party menu | Works in overworld | |
| 28.5 | X opens Dex | Works in overworld | |
| 28.6 | Q opens quest panel | Works in overworld | |
| 28.7 | B toggles battle speed | 1x ↔ 2x in battle | |
| 28.8 | Enter/Space to interact | NPC interaction, dialogue advance | |
| 28.9 | Escape to cancel | Close menus, skip tutorial | |
| 28.10 | Input blocked during PAUSED | No movement, no menu opening | |
| 28.11 | Input blocked during BATTLE | Overworld controls inactive | |
| 28.12 | Input blocked during MENU | Only menu-relevant input works | |

---

## 29. Performance & Edge Cases

### 29.1 Edge Cases

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 29.1.1 | Party full (6) + catch attempt | Catch should be blocked or creature stored | |
| 29.1.2 | All party fainted in overworld | Heal prompt or return to healer | |
| 29.1.3 | 0 gold + try to buy | Purchase blocked gracefully | |
| 29.1.4 | 0 items + try to use | Item menu empty, no crash | |
| 29.1.5 | Level cap creature gains EXP | No level change, no error | |
| 29.1.6 | Trade last non-fainted creature | Should be blocked (NPC trade) | |
| 29.1.7 | Rapid NPC interaction | No double-open menus | |
| 29.1.8 | Open Dex from main menu without save | Button hidden, no crash | |
| 29.1.9 | Multiple zone transitions quickly | _is_transitioning guard prevents overlap | |
| 29.1.10 | Kill app during save | Save file not corrupted (atomic write?) | |
| 29.1.11 | Very long play session (>24h) | play_time_seconds doesn't overflow | |
| 29.1.12 | All 17 dex entries filled | 100% completion, Crown reward | |
| 29.1.13 | ELO rating minimum 100 | Cannot drop below 100 | |
| 29.1.14 | Disconnect during online trade | "Connection lost!" message, no crash | |
| 29.1.15 | Disconnect during PvP battle | Handles gracefully | |

### 29.2 Performance

| # | Test Case | Expected Result | Status |
|---|-----------|-----------------|--------|
| 29.2.1 | Overworld FPS | Stable 60 FPS | |
| 29.2.2 | Battle scene FPS | Stable 60 FPS with animations | |
| 29.2.3 | Weather particles FPS | No significant drop with 80 particles | |
| 29.2.4 | Audio crossfade smooth | No pops or clicks | |
| 29.2.5 | Scene transition fade | Smooth 0.4s, no flicker | |
| 29.2.6 | Save/load speed | < 100ms for typical save | |
| 29.2.7 | Multiple SFX simultaneous | 4-channel pool handles overlap | |
| 29.2.8 | Large inventory (100+ items) | No performance degradation | |
| 29.2.9 | Web export performance | Playable in browser | |
| 29.2.10 | Memory usage stable | No leaks after repeated zone transitions | |

---

## Test Summary

| Category | Test Cases | Priority |
|----------|-----------|----------|
| Core Creature System | 24 | Critical |
| Skill System | 17 | Critical |
| Item System | 26 | High |
| Status Effects | 10 | High |
| Battle — Wild | 28 | Critical |
| Battle — Trainer | 21 | Critical |
| Battle — PvP | 16 | High |
| Evolution System | 22 | Critical |
| World & Zones | 22 | High |
| NPC System | 17 | High |
| NPC Trading | 22 | High |
| Online Trading | 12 | Medium |
| Economy / Shop | 8 | High |
| Badges & Level Cap | 8 | High |
| Creature Dex | 15 | Medium |
| Daily Rewards | 13 | Medium |
| Daily Quests | 17 | Medium |
| Player Stats | 17 | Medium |
| Shiny System | 8 | Low |
| Day/Night Cycle | 7 | Low |
| Weather System | 9 | Low |
| Save & Load | 22 | Critical |
| Audio System | 22 | Medium |
| UI/UX | 28 | High |
| Tutorial System | 17 | Medium |
| Multiplayer Hub | 14 | Medium |
| Web3 / Wallet | 7 | Low |
| Input & Controls | 12 | High |
| Performance & Edge Cases | 25 | High |
| **TOTAL** | **~468** | |

---

## Regression Test Checklist (Quick Smoke Test)

Run this after every sprint/major change:

- [ ] New Game → overworld loads, starter creature received
- [ ] Walk around, encounter wild creature, battle starts
- [ ] Win battle, gain EXP, return to overworld
- [ ] Visit Healer NPC, party healed
- [ ] Visit Shop NPC, buy item
- [ ] Visit Trainer NPC, trainer battle works
- [ ] Visit Trader NPC, NPC trade works
- [ ] Open party menu (TAB), dex (X), quests (Q)
- [ ] Portal to another zone, badge check works
- [ ] Save game, quit, continue → all data restored
- [ ] Main menu: all buttons visible/functional
- [ ] Multiplayer Hub opens, leaderboard shows stats
- [ ] Audio: music plays, SFX triggers on actions
- [ ] Day/night tint matches system time
