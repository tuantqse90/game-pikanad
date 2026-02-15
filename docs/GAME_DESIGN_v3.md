# Game Pikanad v3 — Game Design Document

## Vision

Nang cap tu demo RPG thanh **mid-core creature RPG** hoan chinh voi do sau gameplay, retention loop, va social features. Giu nguyen pixel art aesthetic va blockchain integration, nhung bo sung nhieu he thong core ma game hien tai dang thieu.

---

## Phan 1: EVOLUTION SYSTEM

### 1.1 Evolution Chain
Moi creature co 2-3 stage evolution. Khi dat level yeu cau, creature evolve thanh form manh hon voi stat cao hon va unlock skill moi.

**Fire Chain:**
- Flamepup (Lv.1) → Blazefox (Lv.16) → Pyrodrake (Lv.32)

**Water Chain:**
- Aquafin (Lv.1) → Tidecrab (Lv.16) → Tsunariel (Lv.32)

**Grass Chain:**
- Thornsprout (Lv.1) → Vinewhisker (Lv.14) → Floravine (Lv.28) → Elderoak (Lv.40)

**Wind Chain:**
- Breezeling (Lv.1) → Zephyrix (Lv.16) → Stormraptor (Lv.32)

**Earth Chain:**
- Stoneling (Lv.1) → Boulderkin (Lv.18)

### 1.2 Evolution Mechanics
- Khi creature dat level threshold, hien **Evolution Screen** voi animation sparkle
- Player co the **huy evolution** (nhan Cancel) de giu form hien tai
- NFT creatures giu nguyen token ID khi evolve — stats on-chain duoc update
- Evolution thay doi: species_name, sprite, base stats, unlock 1-2 skill moi
- Held item "Everstone" chan evolution

### 1.3 Implementation
- Them vao `CreatureData`: `evolution_level: int`, `evolves_into: CreatureData`
- Tao `scenes/ui/evolution_screen.tscn` — animation + confirm/cancel
- Update `creature_instance.gd`: check evolution sau moi `gain_exp()`

---

## Phan 2: SKILL SYSTEM OVERHAUL

### 2.1 Skill Slots (4 max)
Moi creature co toi da **4 skill slots** (hien tai chi co 2). Creature hoc skill moi khi level up. Khi da co 4 skills, player chon skill nao muon thay the.

### 2.2 Skill Categories
Them **2 loai skill** ngoai damage:

| Category | Mo ta | Vi du |
|----------|-------|-------|
| **Attack** | Gay damage truc tiep | Ember, Hydro Blast |
| **Status** | Gay debuff/buff | Poison Sting, Iron Wall |
| **Heal** | Hoi HP | Regenerate, Drain Life |

### 2.3 Status Effects
Them 5 status effects:

| Status | Effect | Duration |
|--------|--------|----------|
| **Burn** | Mat 1/8 max HP moi turn, -25% ATK | 3 turns |
| **Poison** | Mat 1/8 max HP moi turn | 5 turns |
| **Sleep** | Khong the hanh dong | 1-3 turns |
| **Paralyze** | 25% chance khong hanh dong, -50% SPD | 4 turns |
| **Shield** | Giam 30% damage nhan vao | 3 turns |

### 2.4 New Skills (them 20 skill moi, tong 36)

**Fire:**
- Flame Shield (Status) — Tu buff Shield 3 turn
- Fire Fang (ATK 55, 20% Burn chance)
- Eruption (ATK 100, acc 70%, giam 25% DEF cua minh)

**Water:**
- Aqua Heal (Heal 30% max HP)
- Bubble Trap (ATK 40, 30% Paralyze chance)
- Tsunami (ATK 100, acc 70%, hit all — PvP: hit doi thu)

**Grass:**
- Spore Cloud (Status — 60% Sleep chance)
- Leech Seed (ATK 35, heal 50% damage dealt)
- Nature's Wrath (ATK 100, acc 70%, heal 25% damage dealt)

**Wind:**
- Tailwind (Status — buff SPD +50% 3 turn)
- Air Slash (ATK 55, 20% flinch — skip turn)
- Hurricane (ATK 100, acc 70%, 30% Paralyze)

**Earth:**
- Iron Wall (Status — buff DEF +50% 3 turn)
- Sand Tomb (ATK 40, Poison 3 turn)
- Tectonic Slam (ATK 100, acc 70%, 30% Paralyze)

**Neutral:**
- Quick Attack (ATK 30, luon di truoc — priority)
- Protect (Status — block 1 attack, fail neu dung 2 turn lien tiep)
- Rest (Heal full HP, Sleep 2 turn)
- Roar (Status — trong wild battle: end battle; PvP: giam ATK doi thu 1 stage)

### 2.5 Skill Learning Table
Moi creature co `learn_set: Array[Dictionary]`:
```
learn_set = [
  { "level": 1, "skill": "tackle" },
  { "level": 5, "skill": "ember" },
  { "level": 12, "skill": "fire_fang" },
  { "level": 20, "skill": "flame_burst" },
  { "level": 28, "skill": "flame_shield" },
  { "level": 36, "skill": "inferno" },
]
```

---

## Phan 3: TRAINER BATTLES & STORY CAMPAIGN

### 3.1 Story Structure
Game co **8 Zone Leaders** (gym leaders), moi nguoi chuyen 1 element + 1 element phu. Player phai danh bai tat ca de mo **Champion Battle**.

### 3.2 Zone Leaders

| # | Ten | Zone | Element chinh | Party (3 creatures) |
|---|-----|------|---------------|---------------------|
| 1 | Kai | Starter Meadow | Grass | Thornsprout Lv.8, Breezeling Lv.9, Vinewhisker Lv.10 |
| 2 | Blaze | Fire Volcano | Fire | Flamepup Lv.14, Blazefox Lv.15, Stoneling Lv.14 |
| 3 | Marina | Water Coast | Water | Aquafin Lv.18, Tidecrab Lv.19, Zephyrix Lv.18 |
| 4 | Oakhart | Forest Grove | Grass | Floravine Lv.22, Vinewhisker Lv.23, Elderoak Lv.24 |
| 5 | Rumble | Earth Caves | Earth | Stoneling Lv.26, Boulderkin Lv.27, Flamepup Lv.26 |
| 6 | Tempest | Sky Peaks (moi) | Wind | Breezeling Lv.30, Zephyrix Lv.31, Stormraptor Lv.32 |
| 7 | Obsidian | Lava Core (moi) | Fire+Earth | Pyrodrake Lv.35, Boulderkin Lv.35, Blazefox Lv.36 |
| 8 | Champion Aria | Champion Arena (moi) | Mixed | Tsunariel Lv.40, Stormraptor Lv.40, Elderoak Lv.42, Pyrodrake Lv.45 |

### 3.3 Trainer Battle Mechanics
- Trainer battle = bat buoc, khong the Run hoac Catch
- Trainer co party 2-4 creatures, AI lua chon skill tot nhat (khong random)
- Thua trainer → khong mat gi, co the re-challenge
- Thang trainer → nhan Reward (gold + items + badge)

### 3.4 New Zones (3 zones moi)

**Sky Peaks** — Floating islands tren may
- Vung nui cao, wind creatures manh
- Wild: Breezeling, Zephyrix, Stormraptor
- Level Range: 25-35
- Portal tu Earth Caves

**Lava Core** — Long nui lua
- Cave voi lava pools, fire+earth creatures
- Wild: Flamepup, Blazefox, Pyrodrake, Boulderkin
- Level Range: 30-40
- Portal tu Fire Volcano

**Champion Arena** — Endgame area
- Mo sau khi co 7 badges
- Boss: Champion Aria
- No wild encounters

### 3.5 Badge System
- 8 badges, hien thi tren **Trainer Card** UI
- Moi badge unlock 1 feature:
  1. Badge 1: Unlock Shop sell (ban creature)
  2. Badge 2: Unlock Super Ball mua duoc
  3. Badge 3: Unlock breeding
  4. Badge 4: Unlock PvP
  5. Badge 5: Creatures listen up to Lv.40
  6. Badge 6: Unlock Ultra Ball
  7. Badge 7: Unlock Lava Core zone
  8. All badges: Unlock Champion Arena + Ranked PvP

---

## Phan 4: AI SYSTEM

### 4.1 Enemy AI Levels

| AI Level | Mo ta | Dung cho |
|----------|-------|----------|
| **Random** | Chon skill ngau nhien | Wild creatures |
| **Smart** | Uu tien type advantage, dung heal khi HP thap | Trainers 1-4 |
| **Expert** | Smart + predict doi thu, switch skill, dung status | Trainers 5-8 |

### 4.2 Smart AI Logic
```
1. Neu co skill super effective → dung no (neu acc >= 80%)
2. Neu HP < 30% va co heal skill → heal
3. Neu co status skill chua dung → 40% chance dung
4. Otherwise → dung skill co damage cao nhat
```

### 4.3 Expert AI Logic
```
1. Neu doi thu co type advantage → uu tien buff DEF/Shield
2. Neu doi thu HP thap → dung skill acc cao nhat de finish
3. Neu doi thu vua heal → dung status (poison/burn) de negate
4. Random 20% chance lam dieu bat ngo (mind game)
```

---

## Phan 5: ITEM SYSTEM EXPANSION

### 5.1 New Items (them 12 items, tong 15)

**Capture Balls:**
| Item | Price | Catch Multiplier |
|------|-------|-------------------|
| Capture Ball | 100G | 1.0x |
| Super Ball | 300G | 1.5x |
| Ultra Ball | 800G | 2.0x |
| Master Ball | (reward only) | 100% catch |

**Potions:**
| Item | Price | Effect |
|------|-------|--------|
| Potion | 50G | Heal 20 HP |
| Super Potion | 150G | Heal 50 HP |
| Max Potion | 500G | Heal full HP |
| Revive | 300G | Revive fainted creature, 50% HP |

**Status Items:**
| Item | Price | Effect |
|------|-------|--------|
| Antidote | 80G | Cure Poison/Burn |
| Awakening | 80G | Cure Sleep/Paralyze |
| Full Heal | 200G | Cure all status |

**Held Items (passive, 1 per creature):**
| Item | Price | Effect |
|------|-------|--------|
| Everstone | 500G | Prevent evolution |
| Power Band | 1000G | +15% ATK |
| Guard Charm | 1000G | +15% DEF |
| Swift Feather | 1000G | +15% SPD |

### 5.2 Usable Items in Battle
- Them **Items** button trong battle (Fight / Items / Catch / Run)
- Su dung item = mat 1 turn
- Items tu bag, khong phai capture_items counter

### 5.3 Held Items
- Moi creature co 1 slot held item
- Held item effect ap dung tu dong trong battle
- Equip/unequip tu Party Menu

---

## Phan 6: CREATURE DEX (Encyclopedia)

### 6.1 Pikanadex
- Track moi creature da **gap** (seen) va **bat** (caught)
- Hien thi: sprite, stats, element, rarity, evolution chain, skill learn set
- Progress: "42/50 caught" — dong luc collect

### 6.2 UI Design
- Accessible tu Main Menu va Overworld (Tab → Dex tab)
- Grid view: moi creature la 1 icon (grayscale neu chua gap, color neu da gap, star neu da bat)
- Detail view: tap vao creature → full info page

### 6.3 Rewards
- 25% dex → nhan Master Ball
- 50% dex → nhan Shiny Charm (tang shiny rate)
- 75% dex → nhan EXP Charm (2x EXP)
- 100% dex → nhan Crown item (cosmetic flex)

---

## Phan 7: SHINY SYSTEM

### 7.1 Shiny Creatures
- Moi wild encounter co **1/200** chance la **Shiny** variant
- Shiny = palette swap (mau khac biet), sparkle effect khi xuat hien
- Stats giong het creature thuong
- Shiny creatures luon NFT-eligible (bat ke rarity)

### 7.2 Shiny Charm
- Held item hoac passive buff
- Tang shiny rate tu 1/200 → 1/50
- Earn tu Dex 50% completion

---

## Phan 8: SOUND & MUSIC

### 8.1 Music Tracks (8 tracks)
| Track | Dung cho |
|-------|----------|
| Main Menu Theme | Title screen |
| Overworld Theme | Starter Meadow, zone exploration |
| Battle Theme | Wild creature battles |
| Trainer Battle Theme | Trainer/Leader battles |
| Victory Fanfare | Win battle |
| Evolution Theme | Evolution screen |
| Shop Theme | Shop menu |
| Champion Theme | Final boss battle |

### 8.2 Sound Effects (15+ SFX)
- UI: button click, menu open/close, text typewriter
- Battle: attack hit, super effective, not effective, miss, faint
- Overworld: step, portal enter, NPC interact
- Items: use potion, capture ball throw, capture success/fail
- Evolution: sparkle, evolve complete

### 8.3 Implementation
- Dung Godot AudioStreamPlayer / AudioStreamPlayer2D
- AudioManager autoload da co san, can implement play functions
- Music: OGG format, loop-able
- SFX: WAV format, short clips
- Generate bang AI music tools hoac free asset packs

---

## Phan 9: IMPROVED GRAPHICS

### 9.1 Animated TileMap
- Thay ColorRect background bang **TileMap** thuc su voi terrain tiles
- Moi zone co tileset rieng:
  - Meadow: co, hoa, duong di, ao nuoc
  - Volcano: da, lava, tro, cave walls
  - Coast: cat, nuoc, san ho, dock
  - Forest: cay, bui, nam, suong mu
  - Cave: da, crystal, stalactite, torch

### 9.2 Day/Night Cycle
- CanvasModulate doi mau theo thoi gian thuc (hoac in-game time)
- 4 phases: Morning (6-12), Afternoon (12-18), Evening (18-22), Night (22-6)
- Mot so creature chi xuat hien vao ban dem

### 9.3 Weather Effects
- Particle effects: mua, tuyet, bao cat, la roi
- Moi zone co weather pattern rieng
- Weather anh huong battle: Rain +20% Water damage, Sun +20% Fire damage

### 9.4 Battle Scene Polish
- Background thay doi theo zone (khong chi mau phang)
- Creature entry animation (slide in tu ngoai man hinh)
- Damage numbers float len khi hit
- Screen flash khi critical hit
- Particle effects cho moi element (lua bay, nuoc ban, la roi...)

---

## Phan 10: QUALITY OF LIFE

### 10.1 Auto-Save
- Auto-save moi khi chuyen zone
- Auto-save sau moi tran battle thang
- Manual save van co tu menu

### 10.2 Speed Toggle
- Nhan phim (B) de toggle **2x battle speed**
- Giam timer delays 50%, animation speed 2x
- Luu preference

### 10.3 Run Button
- Hold Shift de chay nhanh hon trong overworld (1.5x speed)

### 10.4 Quick Heal
- Tu Party Menu, nhan "Heal All" button su dung potions tu bag
- Khong can vao shop/healer

### 10.5 Minimap
- Goc man hinh hien minimap nho cua zone hien tai
- Hien thi: player position, portals, NPCs, wild creature clusters

---

## Phan 11: SOCIAL & RETENTION

### 11.1 Daily Login Rewards
- 7-day cycle: Gold → Potion → Capture Ball → Super Ball → 500G → Revive → Master Ball
- Reset moi tuan

### 11.2 Daily Quests (3/ngay)
| Quest | Reward |
|-------|--------|
| "Catch 3 creatures" | 200G |
| "Win 2 battles" | 150G + Potion |
| "Explore 2 zones" | 100G + Capture Ball |
| "Evolve 1 creature" | 300G |
| "Win 1 PvP battle" | 500G + 5 PIKN |

### 11.3 Leaderboard
- **PvP Ranking**: ELO-based (start 1000)
- **Dex Completion**: % creatures caught
- **Total Level**: sum of all party creature levels
- Hien thi Top 100 tren web + in-game

### 11.4 Trading System
- Trade creatures giua 2 players qua server
- Trade request → accept/decline
- NFT creatures trade on-chain (transfer ERC-721)
- Non-NFT creatures trade off-chain qua server

---

## Phan 12: BLOCKCHAIN V2

### 12.1 Seasonal Battle Pass
- Moi season (30 ngay), co Battle Pass voi 30 tiers
- Earn XP tu daily quests + PvP wins
- Free tier: gold, potions, capture balls
- Premium tier (50 PIKN): exclusive shiny creatures, cosmetics, held items

### 12.2 Marketplace
- Web marketplace (ngoai game) de mua/ban NFT creatures
- List creature → set price in PIKN → buyer purchases
- 5% marketplace fee → treasury

### 12.3 Guild/Clan System
- Tao guild voi 10-50 members
- Guild treasury (pool PIKN tokens)
- Guild wars: 5v5 PvP tournament, guild vs guild
- Weekly guild leaderboard → top guilds nhan PIKN rewards

### 12.4 Tournament System
- Weekly tournament: 16-player single elimination
- Entry: 20 PIKN
- Prize pool: 80% distributed (1st: 40%, 2nd: 25%, 3rd-4th: 15%)
- 20% protocol fee

---

## THU TU IMPLEMENTATION

### Sprint 1 (1-2 tuan): Core Gameplay Depth
- [ ] Evolution system
- [ ] Skill system overhaul (4 slots, status effects, 20 new skills)
- [ ] Item expansion (15 items, held items, battle items)
- [ ] Creature Dex

### Sprint 2 (1-2 tuan): Story & AI
- [ ] Trainer battle system
- [ ] 8 Zone Leaders + 3 new zones
- [ ] Badge system
- [ ] AI levels (Smart, Expert)

### Sprint 3 (1-2 tuan): Polish
- [ ] Sound & Music (8 tracks + 15 SFX)
- [ ] TileMap terrain
- [ ] Battle scene polish
- [ ] QoL (auto-save, speed toggle, minimap)

### Sprint 4 (1-2 tuan): Social & Blockchain
- [ ] Shiny system
- [ ] Trading system
- [ ] Leaderboard
- [ ] Daily quests & login rewards
- [ ] Marketplace + Tournament contracts

---

## SUCCESS METRICS

| Metric | Target |
|--------|--------|
| Average session length | 15+ min |
| Day 7 retention | 30%+ |
| Creatures caught per player | 10+ |
| PvP battles per week per player | 5+ |
| NFT mint rate | 10% of Rare+ catches |
| Dex completion rate | 20% players reach 50%+ |

---

## SUMMARY

Game Pikanad v3 chuyen tu "demo chay duoc" thanh "game co do sau" bang cach them:
1. **Evolution** — creature progression dai han
2. **36 skills + status effects** — chieu sau chien thuat
3. **Story campaign + 8 leaders** — muc tieu ro rang
4. **Shiny + Dex** — collector motivation
5. **Sound + Graphics** — immersion
6. **Daily quests + Leaderboard** — retention
7. **Trading + Tournament** — social + competitive
