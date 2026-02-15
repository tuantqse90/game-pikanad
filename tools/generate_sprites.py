#!/usr/bin/env python3
"""Generate 32x32 overworld sprites and 48x48 battle portraits for Game Pikanad.

Creates sprite sheets for:
- Player: 4 directions x (2 idle + 2 walk frames) = 16 frames → 128x32 sheet
- Each creature: overworld 2-frame idle (64x32), battle 4-frame (idle2 + attack2) (192x48)
"""

from PIL import Image, ImageDraw
import os

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "sprites")
os.makedirs(OUT_DIR, exist_ok=True)

# ── Color palettes ──────────────────────────────────────────────────────────

PLAYER_COLORS = {
    "skin": (255, 206, 158),
    "hair": (90, 56, 37),
    "shirt": (52, 119, 235),
    "pants": (50, 50, 80),
    "shoes": (80, 50, 30),
    "eye": (30, 30, 60),
    "outline": (40, 30, 50),
}

CREATURE_PALETTES = {
    "flamepup": {
        "body": (235, 100, 50),
        "belly": (255, 180, 80),
        "eye": (40, 20, 20),
        "nose": (180, 50, 30),
        "outline": (120, 40, 20),
        "highlight": (255, 140, 60),
        "tail": (255, 200, 50),
    },
    "aquafin": {
        "body": (60, 140, 220),
        "belly": (140, 210, 255),
        "eye": (20, 30, 60),
        "fin": (40, 100, 180),
        "outline": (30, 70, 130),
        "highlight": (120, 200, 255),
        "tail": (80, 160, 240),
    },
    "thornsprout": {
        "body": (80, 170, 70),
        "belly": (160, 220, 120),
        "eye": (30, 40, 20),
        "leaf": (50, 140, 40),
        "outline": (40, 100, 30),
        "highlight": (130, 210, 100),
        "thorn": (100, 80, 40),
    },
    "zephyrix": {
        "body": (180, 200, 230),
        "belly": (220, 235, 255),
        "eye": (40, 40, 80),
        "wing": (140, 170, 210),
        "outline": (100, 120, 160),
        "highlight": (210, 225, 250),
        "feather": (160, 185, 220),
    },
    "stoneling": {
        "body": (140, 120, 100),
        "belly": (180, 165, 140),
        "eye": (40, 30, 20),
        "rock": (110, 95, 75),
        "outline": (80, 65, 50),
        "highlight": (170, 155, 130),
        "crystal": (200, 180, 140),
    },
}


def px(draw, x, y, color):
    """Draw a single pixel."""
    draw.point((x, y), fill=color)


def draw_rect(draw, x, y, w, h, color):
    """Draw a filled rectangle."""
    for dy in range(h):
        for dx in range(w):
            px(draw, x + dx, y + dy, color)


# ── Player sprite generation ───────────────────────────────────────────────

def draw_player_frame(img, frame_x, direction, is_walk, walk_phase):
    """Draw one 32x32 player frame at the given x offset.
    direction: 'down', 'up', 'left', 'right'
    is_walk: whether this is a walk frame
    walk_phase: 0 or 1 for leg alternation
    """
    draw = ImageDraw.Draw(img)
    c = PLAYER_COLORS
    ox = frame_x  # x offset

    # Body bounce for walk
    bounce = 0
    if is_walk:
        bounce = -1 if walk_phase == 0 else 0

    # ── Head (8x8 centered at top) ──
    hx, hy = ox + 12, 4 + bounce

    if direction == "down":
        # Hair top
        draw_rect(draw, hx, hy, 8, 3, c["hair"])
        # Face
        draw_rect(draw, hx, hy + 3, 8, 5, c["skin"])
        # Eyes
        px(draw, hx + 2, hy + 4, c["eye"])
        px(draw, hx + 5, hy + 4, c["eye"])
        # Hair sides
        px(draw, hx, hy + 3, c["hair"])
        px(draw, hx + 7, hy + 3, c["hair"])

    elif direction == "up":
        # Hair covers most of head from back
        draw_rect(draw, hx, hy, 8, 7, c["hair"])
        # Small skin strip at bottom
        draw_rect(draw, hx + 1, hy + 6, 6, 2, c["skin"])

    elif direction == "left":
        draw_rect(draw, hx, hy, 7, 3, c["hair"])
        draw_rect(draw, hx, hy + 3, 7, 5, c["skin"])
        px(draw, hx + 1, hy + 4, c["eye"])
        draw_rect(draw, hx, hy + 3, 1, 3, c["hair"])

    elif direction == "right":
        draw_rect(draw, hx + 1, hy, 7, 3, c["hair"])
        draw_rect(draw, hx + 1, hy + 3, 7, 5, c["skin"])
        px(draw, hx + 5, hy + 4, c["eye"])
        draw_rect(draw, hx + 7, hy + 3, 1, 3, c["hair"])

    # ── Body / Shirt (10x7) ──
    bx, by = ox + 11, 12 + bounce
    draw_rect(draw, bx, by, 10, 7, c["shirt"])
    # Outline top
    draw_rect(draw, bx, by, 10, 1, c["outline"])

    # Arms
    if direction in ("down", "up"):
        # Arms at sides
        arm_swing = 0
        if is_walk:
            arm_swing = 1 if walk_phase == 0 else -1
        draw_rect(draw, bx - 2, by + 1 + arm_swing, 2, 5, c["skin"])
        draw_rect(draw, bx + 10, by + 1 - arm_swing, 2, 5, c["skin"])
    elif direction == "left":
        draw_rect(draw, bx - 1, by + 1, 2, 5, c["skin"])
    elif direction == "right":
        draw_rect(draw, bx + 9, by + 1, 2, 5, c["skin"])

    # ── Pants (8x4) ──
    px_, py = ox + 12, 19 + bounce
    draw_rect(draw, px_, py, 8, 4, c["pants"])

    # ── Legs / Shoes ──
    lx, ly = ox + 12, 23 + bounce

    if is_walk:
        if walk_phase == 0:
            # Left leg forward, right back
            draw_rect(draw, lx, ly, 3, 4, c["pants"])
            draw_rect(draw, lx, ly + 4, 3, 2, c["shoes"])
            draw_rect(draw, lx + 5, ly + 1, 3, 3, c["pants"])
            draw_rect(draw, lx + 5, ly + 4, 3, 2, c["shoes"])
        else:
            # Right leg forward, left back
            draw_rect(draw, lx + 5, ly, 3, 4, c["pants"])
            draw_rect(draw, lx + 5, ly + 4, 3, 2, c["shoes"])
            draw_rect(draw, lx, ly + 1, 3, 3, c["pants"])
            draw_rect(draw, lx, ly + 4, 3, 2, c["shoes"])
    else:
        # Standing
        draw_rect(draw, lx, ly, 3, 4, c["pants"])
        draw_rect(draw, lx, ly + 4, 3, 2, c["shoes"])
        draw_rect(draw, lx + 5, ly, 3, 4, c["pants"])
        draw_rect(draw, lx + 5, ly + 4, 3, 2, c["shoes"])


def generate_player_sheet():
    """Generate player sprite sheet: 4 rows (down, up, left, right) x 4 cols (idle1, idle2, walk1, walk2).
    Total: 128x128 (4x4 frames of 32x32)."""
    sheet = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    directions = ["down", "up", "left", "right"]

    for row, direction in enumerate(directions):
        # Frame 0: idle1
        draw_player_frame(sheet, 0, direction, False, 0)
        frame0 = sheet.crop((0, 0, 32, 32))

        # Frame 1: idle2 (slight bob)
        draw_player_frame(sheet, 32, direction, False, 1)
        frame1 = sheet.crop((32, 0, 64, 32))

        # Frame 2: walk1
        draw_player_frame(sheet, 64, direction, True, 0)
        frame2 = sheet.crop((64, 0, 96, 32))

        # Frame 3: walk2
        draw_player_frame(sheet, 96, direction, True, 1)
        frame3 = sheet.crop((96, 0, 128, 32))

        # Clear and redraw properly per-row
        sheet_row = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
        draw_player_frame(sheet_row, 0, direction, False, 0)
        draw_player_frame(sheet_row, 32, direction, False, 1)
        draw_player_frame(sheet_row, 64, direction, True, 0)
        draw_player_frame(sheet_row, 96, direction, True, 1)

        sheet.paste(sheet_row, (0, row * 32))

    sheet.save(os.path.join(OUT_DIR, "player_sheet.png"))
    print("Created player_sheet.png (128x128)")


# ── Creature sprite generation ──────────────────────────────────────────────

def draw_flamepup_overworld(img, ox, oy, frame):
    """Draw flamepup at 32x32 with flame animation."""
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["flamepup"]

    bounce = -1 if frame == 1 else 0

    # Body (rounded blob)
    draw_rect(draw, ox + 8, oy + 12 + bounce, 16, 12, c["body"])
    draw_rect(draw, ox + 10, oy + 10 + bounce, 12, 2, c["body"])
    draw_rect(draw, ox + 10, oy + 24 + bounce, 12, 2, c["body"])

    # Belly
    draw_rect(draw, ox + 12, oy + 16 + bounce, 8, 6, c["belly"])

    # Head
    draw_rect(draw, ox + 9, oy + 6 + bounce, 14, 8, c["body"])
    draw_rect(draw, ox + 11, oy + 4 + bounce, 10, 3, c["body"])

    # Eyes
    draw_rect(draw, ox + 11, oy + 8 + bounce, 2, 2, (255, 255, 255))
    draw_rect(draw, ox + 17, oy + 8 + bounce, 2, 2, (255, 255, 255))
    px(draw, ox + 12, oy + 9 + bounce, c["eye"])
    px(draw, ox + 18, oy + 9 + bounce, c["eye"])

    # Nose
    px(draw, ox + 15, oy + 11 + bounce, c["nose"])

    # Ears (pointy)
    draw_rect(draw, ox + 9, oy + 3 + bounce, 3, 4, c["body"])
    draw_rect(draw, ox + 20, oy + 3 + bounce, 3, 4, c["body"])

    # Tail flame
    tail_flicker = 1 if frame == 1 else 0
    draw_rect(draw, ox + 24, oy + 14 + bounce, 4, 3, c["tail"])
    draw_rect(draw, ox + 25, oy + 12 + bounce - tail_flicker, 3, 3, (255, 100, 30))
    draw_rect(draw, ox + 26, oy + 10 + bounce - tail_flicker, 2, 3, (255, 220, 80))

    # Feet
    draw_rect(draw, ox + 10, oy + 25 + bounce, 4, 3, c["outline"])
    draw_rect(draw, ox + 18, oy + 25 + bounce, 4, 3, c["outline"])


def draw_aquafin_overworld(img, ox, oy, frame):
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["aquafin"]
    bounce = -1 if frame == 1 else 0

    # Body (fish-like oval)
    draw_rect(draw, ox + 7, oy + 12 + bounce, 18, 10, c["body"])
    draw_rect(draw, ox + 9, oy + 10 + bounce, 14, 2, c["body"])
    draw_rect(draw, ox + 9, oy + 22 + bounce, 14, 2, c["body"])

    # Belly
    draw_rect(draw, ox + 11, oy + 16 + bounce, 10, 5, c["belly"])

    # Head
    draw_rect(draw, ox + 9, oy + 6 + bounce, 14, 8, c["body"])

    # Eyes
    draw_rect(draw, ox + 11, oy + 8 + bounce, 3, 3, (255, 255, 255))
    draw_rect(draw, ox + 18, oy + 8 + bounce, 3, 3, (255, 255, 255))
    px(draw, ox + 12, oy + 9 + bounce, c["eye"])
    px(draw, ox + 19, oy + 9 + bounce, c["eye"])

    # Dorsal fin
    fin_wave = 1 if frame == 1 else 0
    draw_rect(draw, ox + 14, oy + 4 + bounce - fin_wave, 4, 4, c["fin"])
    draw_rect(draw, ox + 15, oy + 2 + bounce - fin_wave, 2, 3, c["fin"])

    # Tail fin
    draw_rect(draw, ox + 3, oy + 14 + bounce, 5, 6, c["tail"])
    draw_rect(draw, ox + 2, oy + 13 + bounce + fin_wave, 3, 3, c["fin"])

    # Side fins
    draw_rect(draw, ox + 24, oy + 14 + bounce, 4, 3, c["fin"])

    # Feet (small)
    draw_rect(draw, ox + 11, oy + 24 + bounce, 3, 3, c["outline"])
    draw_rect(draw, ox + 18, oy + 24 + bounce, 3, 3, c["outline"])


def draw_thornsprout_overworld(img, ox, oy, frame):
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["thornsprout"]
    bounce = -1 if frame == 1 else 0

    # Body (bulb shape)
    draw_rect(draw, ox + 9, oy + 14 + bounce, 14, 10, c["body"])
    draw_rect(draw, ox + 11, oy + 12 + bounce, 10, 2, c["body"])
    draw_rect(draw, ox + 11, oy + 24 + bounce, 10, 2, c["body"])

    # Belly
    draw_rect(draw, ox + 12, oy + 17 + bounce, 8, 5, c["belly"])

    # Head
    draw_rect(draw, ox + 10, oy + 7 + bounce, 12, 8, c["body"])

    # Eyes
    draw_rect(draw, ox + 12, oy + 9 + bounce, 2, 2, (255, 255, 255))
    draw_rect(draw, ox + 18, oy + 9 + bounce, 2, 2, (255, 255, 255))
    px(draw, ox + 13, oy + 10 + bounce, c["eye"])
    px(draw, ox + 19, oy + 10 + bounce, c["eye"])

    # Leaf on head
    leaf_wave = 1 if frame == 1 else 0
    draw_rect(draw, ox + 13, oy + 3 + bounce - leaf_wave, 6, 5, c["leaf"])
    draw_rect(draw, ox + 14, oy + 1 + bounce - leaf_wave, 4, 3, c["leaf"])
    draw_rect(draw, ox + 15, oy + 0 + bounce - leaf_wave, 2, 2, c["highlight"])

    # Thorns on sides
    draw_rect(draw, ox + 7, oy + 16 + bounce, 3, 2, c["thorn"])
    draw_rect(draw, ox + 22, oy + 16 + bounce, 3, 2, c["thorn"])
    draw_rect(draw, ox + 8, oy + 20 + bounce, 2, 2, c["thorn"])
    draw_rect(draw, ox + 22, oy + 20 + bounce, 2, 2, c["thorn"])

    # Feet
    draw_rect(draw, ox + 11, oy + 25 + bounce, 3, 3, c["outline"])
    draw_rect(draw, ox + 18, oy + 25 + bounce, 3, 3, c["outline"])


def draw_zephyrix_overworld(img, ox, oy, frame):
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["zephyrix"]
    bounce = -1 if frame == 1 else 0

    # Body (bird-like)
    draw_rect(draw, ox + 10, oy + 13 + bounce, 12, 10, c["body"])
    draw_rect(draw, ox + 12, oy + 11 + bounce, 8, 2, c["body"])

    # Belly
    draw_rect(draw, ox + 12, oy + 17 + bounce, 8, 4, c["belly"])

    # Head
    draw_rect(draw, ox + 11, oy + 5 + bounce, 10, 8, c["body"])

    # Eyes
    draw_rect(draw, ox + 13, oy + 7 + bounce, 2, 2, (255, 255, 255))
    draw_rect(draw, ox + 17, oy + 7 + bounce, 2, 2, (255, 255, 255))
    px(draw, ox + 14, oy + 8 + bounce, c["eye"])
    px(draw, ox + 18, oy + 8 + bounce, c["eye"])

    # Beak
    draw_rect(draw, ox + 15, oy + 10 + bounce, 2, 2, (255, 200, 80))

    # Wings
    wing_up = -2 if frame == 1 else 0
    draw_rect(draw, ox + 4, oy + 12 + bounce + wing_up, 7, 5, c["wing"])
    draw_rect(draw, ox + 21, oy + 12 + bounce + wing_up, 7, 5, c["wing"])
    draw_rect(draw, ox + 3, oy + 11 + bounce + wing_up, 4, 3, c["feather"])
    draw_rect(draw, ox + 25, oy + 11 + bounce + wing_up, 4, 3, c["feather"])

    # Tail feathers
    draw_rect(draw, ox + 13, oy + 23 + bounce, 6, 4, c["feather"])
    draw_rect(draw, ox + 14, oy + 26 + bounce, 4, 2, c["wing"])

    # Feet
    draw_rect(draw, ox + 12, oy + 23 + bounce, 2, 3, c["outline"])
    draw_rect(draw, ox + 18, oy + 23 + bounce, 2, 3, c["outline"])


def draw_stoneling_overworld(img, ox, oy, frame):
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["stoneling"]
    bounce = -1 if frame == 1 else 0

    # Body (chunky rock)
    draw_rect(draw, ox + 6, oy + 10 + bounce, 20, 14, c["body"])
    draw_rect(draw, ox + 8, oy + 8 + bounce, 16, 2, c["body"])
    draw_rect(draw, ox + 8, oy + 24 + bounce, 16, 2, c["body"])

    # Rocky texture
    draw_rect(draw, ox + 8, oy + 12 + bounce, 4, 3, c["rock"])
    draw_rect(draw, ox + 18, oy + 18 + bounce, 5, 3, c["rock"])
    draw_rect(draw, ox + 10, oy + 20 + bounce, 3, 3, c["rock"])

    # Crystal on shoulder
    crystal_glow = 1 if frame == 1 else 0
    draw_rect(draw, ox + 20, oy + 7 + bounce - crystal_glow, 4, 5, c["crystal"])
    draw_rect(draw, ox + 21, oy + 5 + bounce - crystal_glow, 2, 3, (230, 210, 170))

    # Head area
    draw_rect(draw, ox + 10, oy + 6 + bounce, 12, 6, c["body"])

    # Eyes
    draw_rect(draw, ox + 12, oy + 8 + bounce, 2, 2, (255, 255, 255))
    draw_rect(draw, ox + 18, oy + 8 + bounce, 2, 2, (255, 255, 255))
    px(draw, ox + 13, oy + 9 + bounce, c["eye"])
    px(draw, ox + 19, oy + 9 + bounce, c["eye"])

    # Mouth line
    draw_rect(draw, ox + 14, oy + 11 + bounce, 4, 1, c["outline"])

    # Feet (sturdy)
    draw_rect(draw, ox + 9, oy + 25 + bounce, 5, 3, c["outline"])
    draw_rect(draw, ox + 18, oy + 25 + bounce, 5, 3, c["outline"])


## ── New creature palettes ─────────────────────────────────────────────────

CREATURE_PALETTES["blazefox"] = {
    "body": (210, 70, 30),
    "belly": (255, 160, 60),
    "eye": (30, 10, 10),
    "outline": (100, 30, 10),
    "highlight": (255, 120, 40),
    "tail": (255, 200, 40),
    "mane": (255, 90, 20),
    "ear_inner": (255, 140, 50),
}

CREATURE_PALETTES["pyrodrake"] = {
    "body": (160, 40, 30),
    "belly": (220, 130, 60),
    "eye": (255, 200, 0),
    "outline": (80, 20, 15),
    "highlight": (200, 80, 40),
    "wing": (180, 60, 30),
    "horn": (100, 70, 40),
    "flame": (255, 160, 30),
}

CREATURE_PALETTES["tidecrab"] = {
    "body": (200, 80, 70),
    "belly": (240, 180, 160),
    "eye": (10, 10, 30),
    "outline": (120, 40, 30),
    "claw": (220, 100, 80),
    "shell": (180, 60, 50),
    "highlight": (240, 140, 120),
    "leg": (160, 60, 50),
}

CREATURE_PALETTES["tsunariel"] = {
    "body": (80, 160, 230),
    "belly": (180, 220, 255),
    "eye": (20, 20, 80),
    "outline": (40, 90, 160),
    "highlight": (160, 210, 255),
    "fin": (60, 130, 200),
    "glow": (200, 240, 255),
    "hair": (100, 180, 240),
}

CREATURE_PALETTES["vinewhisker"] = {
    "body": (100, 160, 80),
    "belly": (180, 220, 150),
    "eye": (40, 60, 20),
    "outline": (50, 90, 40),
    "whisker": (60, 130, 40),
    "highlight": (150, 200, 120),
    "ear": (80, 140, 60),
    "nose": (60, 100, 50),
}

CREATURE_PALETTES["floravine"] = {
    "body": (70, 150, 60),
    "belly": (140, 210, 110),
    "eye": (30, 50, 20),
    "outline": (35, 80, 30),
    "vine": (50, 120, 40),
    "flower": (240, 120, 160),
    "flower_center": (255, 220, 80),
    "highlight": (120, 190, 90),
}

CREATURE_PALETTES["elderoak"] = {
    "body": (100, 75, 50),
    "belly": (140, 110, 80),
    "eye": (200, 255, 100),
    "outline": (60, 40, 25),
    "bark": (80, 55, 35),
    "leaf": (50, 140, 40),
    "leaf_light": (100, 180, 60),
    "moss": (60, 110, 50),
}

CREATURE_PALETTES["breezeling"] = {
    "body": (200, 220, 240),
    "belly": (230, 240, 255),
    "eye": (50, 50, 100),
    "outline": (120, 140, 170),
    "wing": (170, 200, 235),
    "highlight": (220, 235, 255),
    "trail": (180, 210, 245),
    "cheek": (240, 200, 210),
}

CREATURE_PALETTES["stormraptor"] = {
    "body": (60, 60, 90),
    "belly": (100, 100, 140),
    "eye": (255, 255, 100),
    "outline": (30, 30, 50),
    "wing": (50, 50, 80),
    "highlight": (90, 90, 130),
    "lightning": (255, 255, 150),
    "beak": (200, 180, 80),
}

CREATURE_PALETTES["boulderkin"] = {
    "body": (160, 140, 110),
    "belly": (190, 175, 150),
    "eye": (60, 40, 20),
    "outline": (90, 75, 55),
    "rock": (130, 110, 85),
    "crystal": (180, 220, 200),
    "highlight": (180, 165, 135),
    "moss": (80, 120, 60),
}


# ── New creature draw functions ────────────────────────────────────────────

def draw_blazefox_overworld(img, ox, oy, frame):
    """Blazefox: sleek fiery fox with flaming mane."""
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["blazefox"]
    bounce = -1 if frame == 1 else 0

    # Body (slim fox shape)
    draw_rect(draw, ox + 7, oy + 14 + bounce, 18, 10, c["body"])
    draw_rect(draw, ox + 9, oy + 12 + bounce, 14, 2, c["body"])

    # Belly
    draw_rect(draw, ox + 11, oy + 17 + bounce, 10, 5, c["belly"])

    # Head (narrower, fox-like)
    draw_rect(draw, ox + 10, oy + 6 + bounce, 12, 8, c["body"])
    draw_rect(draw, ox + 12, oy + 4 + bounce, 8, 3, c["body"])

    # Pointed ears
    draw_rect(draw, ox + 10, oy + 2 + bounce, 3, 5, c["body"])
    draw_rect(draw, ox + 19, oy + 2 + bounce, 3, 5, c["body"])
    draw_rect(draw, ox + 11, oy + 3 + bounce, 1, 3, c["ear_inner"])
    draw_rect(draw, ox + 20, oy + 3 + bounce, 1, 3, c["ear_inner"])

    # Eyes (fierce)
    draw_rect(draw, ox + 12, oy + 8 + bounce, 2, 2, (255, 255, 200))
    draw_rect(draw, ox + 18, oy + 8 + bounce, 2, 2, (255, 255, 200))
    px(draw, ox + 13, oy + 9 + bounce, c["eye"])
    px(draw, ox + 19, oy + 9 + bounce, c["eye"])

    # Nose
    px(draw, ox + 15, oy + 11 + bounce, c["outline"])
    px(draw, ox + 16, oy + 11 + bounce, c["outline"])

    # Flaming mane behind head
    flicker = 1 if frame == 1 else 0
    draw_rect(draw, ox + 8, oy + 5 + bounce - flicker, 3, 4, c["mane"])
    draw_rect(draw, ox + 21, oy + 5 + bounce + flicker, 3, 4, c["mane"])
    draw_rect(draw, ox + 13, oy + 2 + bounce - flicker, 6, 3, c["tail"])

    # Bushy tail with flames
    draw_rect(draw, ox + 24, oy + 12 + bounce, 5, 4, c["tail"])
    draw_rect(draw, ox + 25, oy + 10 + bounce - flicker, 4, 3, (255, 120, 30))
    draw_rect(draw, ox + 26, oy + 8 + bounce - flicker, 3, 3, (255, 200, 60))

    # Slim legs
    draw_rect(draw, ox + 9, oy + 24 + bounce, 3, 4, c["outline"])
    draw_rect(draw, ox + 20, oy + 24 + bounce, 3, 4, c["outline"])


def draw_pyrodrake_overworld(img, ox, oy, frame):
    """Pyrodrake: small fierce dragon with wings and horns."""
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["pyrodrake"]
    bounce = -1 if frame == 1 else 0

    # Body (stocky dragon)
    draw_rect(draw, ox + 8, oy + 14 + bounce, 16, 10, c["body"])
    draw_rect(draw, ox + 10, oy + 12 + bounce, 12, 2, c["body"])

    # Belly plates
    draw_rect(draw, ox + 11, oy + 16 + bounce, 10, 6, c["belly"])
    # Belly segments
    draw_rect(draw, ox + 11, oy + 18 + bounce, 10, 1, c["highlight"])
    draw_rect(draw, ox + 11, oy + 20 + bounce, 10, 1, c["highlight"])

    # Head
    draw_rect(draw, ox + 10, oy + 6 + bounce, 12, 8, c["body"])

    # Horns
    draw_rect(draw, ox + 10, oy + 3 + bounce, 2, 4, c["horn"])
    draw_rect(draw, ox + 20, oy + 3 + bounce, 2, 4, c["horn"])
    px(draw, ox + 10, oy + 2 + bounce, c["horn"])
    px(draw, ox + 21, oy + 2 + bounce, c["horn"])

    # Eyes (glowing)
    draw_rect(draw, ox + 12, oy + 8 + bounce, 2, 2, c["eye"])
    draw_rect(draw, ox + 18, oy + 8 + bounce, 2, 2, c["eye"])

    # Jaw
    draw_rect(draw, ox + 13, oy + 12 + bounce, 6, 2, c["highlight"])

    # Small wings
    wing_flap = -2 if frame == 1 else 0
    draw_rect(draw, ox + 3, oy + 10 + bounce + wing_flap, 6, 6, c["wing"])
    draw_rect(draw, ox + 23, oy + 10 + bounce + wing_flap, 6, 6, c["wing"])
    draw_rect(draw, ox + 2, oy + 9 + bounce + wing_flap, 4, 3, c["highlight"])
    draw_rect(draw, ox + 26, oy + 9 + bounce + wing_flap, 4, 3, c["highlight"])

    # Tail
    draw_rect(draw, ox + 23, oy + 20 + bounce, 5, 3, c["body"])
    draw_rect(draw, ox + 27, oy + 19 + bounce, 3, 3, c["flame"])

    # Feet (clawed)
    draw_rect(draw, ox + 10, oy + 24 + bounce, 4, 4, c["outline"])
    draw_rect(draw, ox + 18, oy + 24 + bounce, 4, 4, c["outline"])


def draw_tidecrab_overworld(img, ox, oy, frame):
    """Tidecrab: wide crab with big claws."""
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["tidecrab"]
    bounce = -1 if frame == 1 else 0

    # Shell body (wide and flat)
    draw_rect(draw, ox + 6, oy + 12 + bounce, 20, 10, c["body"])
    draw_rect(draw, ox + 8, oy + 10 + bounce, 16, 2, c["body"])
    draw_rect(draw, ox + 8, oy + 22 + bounce, 16, 2, c["body"])

    # Shell pattern
    draw_rect(draw, ox + 10, oy + 13 + bounce, 12, 3, c["shell"])
    draw_rect(draw, ox + 12, oy + 11 + bounce, 8, 2, c["highlight"])

    # Belly
    draw_rect(draw, ox + 10, oy + 17 + bounce, 12, 4, c["belly"])

    # Eyes on stalks
    draw_rect(draw, ox + 12, oy + 6 + bounce, 2, 5, c["body"])
    draw_rect(draw, ox + 18, oy + 6 + bounce, 2, 5, c["body"])
    draw_rect(draw, ox + 11, oy + 5 + bounce, 3, 3, (255, 255, 255))
    draw_rect(draw, ox + 18, oy + 5 + bounce, 3, 3, (255, 255, 255))
    px(draw, ox + 12, oy + 6 + bounce, c["eye"])
    px(draw, ox + 19, oy + 6 + bounce, c["eye"])

    # Claws
    claw_open = 1 if frame == 1 else 0
    # Left claw
    draw_rect(draw, ox + 1, oy + 12 + bounce, 6, 5, c["claw"])
    draw_rect(draw, ox + 0, oy + 11 + bounce - claw_open, 3, 3, c["claw"])
    draw_rect(draw, ox + 0, oy + 16 + bounce + claw_open, 3, 3, c["claw"])
    # Right claw
    draw_rect(draw, ox + 25, oy + 12 + bounce, 6, 5, c["claw"])
    draw_rect(draw, ox + 29, oy + 11 + bounce - claw_open, 3, 3, c["claw"])
    draw_rect(draw, ox + 29, oy + 16 + bounce + claw_open, 3, 3, c["claw"])

    # Legs (4 pairs)
    draw_rect(draw, ox + 8, oy + 23 + bounce, 2, 4, c["leg"])
    draw_rect(draw, ox + 12, oy + 24 + bounce, 2, 3, c["leg"])
    draw_rect(draw, ox + 18, oy + 24 + bounce, 2, 3, c["leg"])
    draw_rect(draw, ox + 22, oy + 23 + bounce, 2, 4, c["leg"])


def draw_tsunariel_overworld(img, ox, oy, frame):
    """Tsunariel: ethereal water spirit with flowing hair."""
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["tsunariel"]
    bounce = -1 if frame == 1 else 0

    # Flowing body (tapers down)
    draw_rect(draw, ox + 10, oy + 12 + bounce, 12, 12, c["body"])
    draw_rect(draw, ox + 12, oy + 10 + bounce, 8, 2, c["body"])
    # Tapered bottom (water tail)
    draw_rect(draw, ox + 12, oy + 24 + bounce, 8, 3, c["highlight"])
    draw_rect(draw, ox + 13, oy + 27 + bounce, 6, 2, c["glow"])

    # Belly glow
    draw_rect(draw, ox + 12, oy + 15 + bounce, 8, 6, c["belly"])

    # Head
    draw_rect(draw, ox + 10, oy + 5 + bounce, 12, 8, c["body"])

    # Flowing hair
    wave = 1 if frame == 1 else 0
    draw_rect(draw, ox + 8, oy + 4 + bounce - wave, 4, 8, c["hair"])
    draw_rect(draw, ox + 20, oy + 4 + bounce + wave, 4, 8, c["hair"])
    draw_rect(draw, ox + 7, oy + 2 + bounce - wave, 3, 4, c["highlight"])
    draw_rect(draw, ox + 22, oy + 2 + bounce + wave, 3, 4, c["highlight"])

    # Eyes (luminous)
    draw_rect(draw, ox + 12, oy + 7 + bounce, 2, 2, (255, 255, 255))
    draw_rect(draw, ox + 18, oy + 7 + bounce, 2, 2, (255, 255, 255))
    px(draw, ox + 13, oy + 8 + bounce, c["eye"])
    px(draw, ox + 19, oy + 8 + bounce, c["eye"])

    # Glow spots
    px(draw, ox + 15, oy + 3 + bounce, c["glow"])
    px(draw, ox + 16, oy + 2 + bounce, c["glow"])

    # Fin arms
    draw_rect(draw, ox + 6, oy + 13 + bounce + wave, 5, 4, c["fin"])
    draw_rect(draw, ox + 21, oy + 13 + bounce - wave, 5, 4, c["fin"])


def draw_vinewhisker_overworld(img, ox, oy, frame):
    """Vinewhisker: cat-like creature with vine whiskers."""
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["vinewhisker"]
    bounce = -1 if frame == 1 else 0

    # Body (cat-like)
    draw_rect(draw, ox + 9, oy + 14 + bounce, 14, 10, c["body"])
    draw_rect(draw, ox + 11, oy + 12 + bounce, 10, 2, c["body"])

    # Belly
    draw_rect(draw, ox + 12, oy + 17 + bounce, 8, 5, c["belly"])

    # Head (round cat face)
    draw_rect(draw, ox + 10, oy + 6 + bounce, 12, 8, c["body"])
    draw_rect(draw, ox + 12, oy + 5 + bounce, 8, 2, c["body"])

    # Cat ears
    draw_rect(draw, ox + 10, oy + 2 + bounce, 3, 5, c["body"])
    draw_rect(draw, ox + 19, oy + 2 + bounce, 3, 5, c["body"])
    px(draw, ox + 11, oy + 3 + bounce, c["ear"])
    px(draw, ox + 20, oy + 3 + bounce, c["ear"])

    # Eyes (cat-like)
    draw_rect(draw, ox + 12, oy + 8 + bounce, 2, 2, (220, 255, 180))
    draw_rect(draw, ox + 18, oy + 8 + bounce, 2, 2, (220, 255, 180))
    px(draw, ox + 12, oy + 9 + bounce, c["eye"])
    px(draw, ox + 18, oy + 9 + bounce, c["eye"])

    # Nose
    px(draw, ox + 15, oy + 10 + bounce, c["nose"])

    # Vine whiskers (animated)
    whisk = 1 if frame == 1 else 0
    draw_rect(draw, ox + 5, oy + 9 + bounce - whisk, 6, 1, c["whisker"])
    draw_rect(draw, ox + 5, oy + 11 + bounce + whisk, 6, 1, c["whisker"])
    draw_rect(draw, ox + 21, oy + 9 + bounce + whisk, 6, 1, c["whisker"])
    draw_rect(draw, ox + 21, oy + 11 + bounce - whisk, 6, 1, c["whisker"])

    # Vine tail
    draw_rect(draw, ox + 22, oy + 16 + bounce, 5, 2, c["whisker"])
    draw_rect(draw, ox + 26, oy + 14 + bounce + whisk, 3, 3, c["highlight"])

    # Feet
    draw_rect(draw, ox + 10, oy + 24 + bounce, 3, 3, c["outline"])
    draw_rect(draw, ox + 19, oy + 24 + bounce, 3, 3, c["outline"])


def draw_floravine_overworld(img, ox, oy, frame):
    """Floravine: vine creature with a flower on its head."""
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["floravine"]
    bounce = -1 if frame == 1 else 0

    # Body (vine/plant stalk)
    draw_rect(draw, ox + 10, oy + 12 + bounce, 12, 12, c["body"])
    draw_rect(draw, ox + 12, oy + 10 + bounce, 8, 2, c["body"])

    # Belly
    draw_rect(draw, ox + 12, oy + 16 + bounce, 8, 6, c["belly"])

    # Head
    draw_rect(draw, ox + 11, oy + 6 + bounce, 10, 7, c["body"])

    # Flower on head
    sway = 1 if frame == 1 else 0
    draw_rect(draw, ox + 12, oy + 0 + bounce - sway, 8, 3, c["flower"])
    draw_rect(draw, ox + 10, oy + 1 + bounce - sway, 3, 3, c["flower"])
    draw_rect(draw, ox + 19, oy + 1 + bounce - sway, 3, 3, c["flower"])
    draw_rect(draw, ox + 14, oy + 1 + bounce - sway, 4, 3, c["flower_center"])

    # Eyes
    draw_rect(draw, ox + 13, oy + 8 + bounce, 2, 2, (255, 255, 255))
    draw_rect(draw, ox + 17, oy + 8 + bounce, 2, 2, (255, 255, 255))
    px(draw, ox + 14, oy + 9 + bounce, c["eye"])
    px(draw, ox + 18, oy + 9 + bounce, c["eye"])

    # Mouth (smile)
    draw_rect(draw, ox + 14, oy + 11 + bounce, 4, 1, c["outline"])

    # Vine arms
    draw_rect(draw, ox + 5, oy + 13 + bounce + sway, 6, 2, c["vine"])
    draw_rect(draw, ox + 3, oy + 12 + bounce + sway, 3, 2, c["highlight"])
    draw_rect(draw, ox + 21, oy + 13 + bounce - sway, 6, 2, c["vine"])
    draw_rect(draw, ox + 26, oy + 12 + bounce - sway, 3, 2, c["highlight"])

    # Root feet
    draw_rect(draw, ox + 10, oy + 24 + bounce, 4, 4, c["outline"])
    draw_rect(draw, ox + 18, oy + 24 + bounce, 4, 4, c["outline"])
    draw_rect(draw, ox + 8, oy + 26 + bounce, 3, 2, c["vine"])
    draw_rect(draw, ox + 21, oy + 26 + bounce, 3, 2, c["vine"])


def draw_elderoak_overworld(img, ox, oy, frame):
    """Elderoak: majestic tree creature (legendary). Larger presence."""
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["elderoak"]
    bounce = -1 if frame == 1 else 0

    # Trunk body (wide, tall)
    draw_rect(draw, ox + 7, oy + 10 + bounce, 18, 16, c["body"])
    draw_rect(draw, ox + 9, oy + 8 + bounce, 14, 2, c["body"])

    # Bark texture
    draw_rect(draw, ox + 9, oy + 12 + bounce, 3, 4, c["bark"])
    draw_rect(draw, ox + 16, oy + 16 + bounce, 4, 3, c["bark"])
    draw_rect(draw, ox + 20, oy + 12 + bounce, 3, 5, c["bark"])

    # Belly (hollow face area)
    draw_rect(draw, ox + 11, oy + 14 + bounce, 10, 8, c["belly"])

    # Face in trunk
    draw_rect(draw, ox + 12, oy + 15 + bounce, 3, 2, c["eye"])
    draw_rect(draw, ox + 17, oy + 15 + bounce, 3, 2, c["eye"])
    draw_rect(draw, ox + 14, oy + 18 + bounce, 4, 2, c["outline"])

    # Leafy crown
    sway = 1 if frame == 1 else 0
    draw_rect(draw, ox + 4, oy + 2 + bounce - sway, 24, 8, c["leaf"])
    draw_rect(draw, ox + 6, oy + 0 + bounce - sway, 20, 3, c["leaf"])
    draw_rect(draw, ox + 8, oy + 1 + bounce - sway, 6, 3, c["leaf_light"])
    draw_rect(draw, ox + 18, oy + 3 + bounce - sway, 5, 3, c["leaf_light"])
    draw_rect(draw, ox + 10, oy + 5 + bounce - sway, 4, 2, c["leaf_light"])

    # Moss patches
    draw_rect(draw, ox + 7, oy + 22 + bounce, 4, 2, c["moss"])
    draw_rect(draw, ox + 20, oy + 20 + bounce, 3, 2, c["moss"])

    # Branch arms
    draw_rect(draw, ox + 2, oy + 10 + bounce + sway, 6, 3, c["body"])
    draw_rect(draw, ox + 0, oy + 9 + bounce + sway, 4, 3, c["leaf"])
    draw_rect(draw, ox + 24, oy + 10 + bounce - sway, 6, 3, c["body"])
    draw_rect(draw, ox + 28, oy + 9 + bounce - sway, 4, 3, c["leaf"])

    # Root feet
    draw_rect(draw, ox + 7, oy + 26 + bounce, 6, 4, c["outline"])
    draw_rect(draw, ox + 19, oy + 26 + bounce, 6, 4, c["outline"])
    draw_rect(draw, ox + 5, oy + 28 + bounce, 4, 2, c["bark"])
    draw_rect(draw, ox + 23, oy + 28 + bounce, 4, 2, c["bark"])


def draw_breezeling_overworld(img, ox, oy, frame):
    """Breezeling: tiny wind sprite, light and floaty."""
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["breezeling"]
    bounce = -2 if frame == 1 else 0  # more floaty bounce

    # Body (small, round)
    draw_rect(draw, ox + 11, oy + 14 + bounce, 10, 8, c["body"])
    draw_rect(draw, ox + 13, oy + 12 + bounce, 6, 2, c["body"])

    # Belly
    draw_rect(draw, ox + 13, oy + 16 + bounce, 6, 4, c["belly"])

    # Head (big relative to body)
    draw_rect(draw, ox + 10, oy + 6 + bounce, 12, 8, c["body"])
    draw_rect(draw, ox + 12, oy + 4 + bounce, 8, 3, c["body"])

    # Eyes (large, cute)
    draw_rect(draw, ox + 12, oy + 7 + bounce, 3, 3, (255, 255, 255))
    draw_rect(draw, ox + 17, oy + 7 + bounce, 3, 3, (255, 255, 255))
    px(draw, ox + 13, oy + 8 + bounce, c["eye"])
    px(draw, ox + 18, oy + 8 + bounce, c["eye"])
    # Shine
    px(draw, ox + 12, oy + 7 + bounce, c["highlight"])
    px(draw, ox + 17, oy + 7 + bounce, c["highlight"])

    # Cheeks
    draw_rect(draw, ox + 11, oy + 10 + bounce, 2, 1, c["cheek"])
    draw_rect(draw, ox + 19, oy + 10 + bounce, 2, 1, c["cheek"])

    # Tiny mouth
    px(draw, ox + 15, oy + 11 + bounce, c["outline"])

    # Wispy wings
    wing_up = -2 if frame == 1 else 0
    draw_rect(draw, ox + 5, oy + 10 + bounce + wing_up, 6, 4, c["wing"])
    draw_rect(draw, ox + 21, oy + 10 + bounce + wing_up, 6, 4, c["wing"])
    draw_rect(draw, ox + 4, oy + 9 + bounce + wing_up, 3, 2, c["trail"])
    draw_rect(draw, ox + 25, oy + 9 + bounce + wing_up, 3, 2, c["trail"])

    # Wind trail
    trail_shift = 1 if frame == 1 else 0
    draw_rect(draw, ox + 13, oy + 22 + bounce + trail_shift, 6, 2, c["trail"])
    draw_rect(draw, ox + 14, oy + 24 + bounce + trail_shift, 4, 2, c["highlight"])
    draw_rect(draw, ox + 15, oy + 26 + bounce + trail_shift, 2, 2, c["belly"])


def draw_stormraptor_overworld(img, ox, oy, frame):
    """Stormraptor: fierce storm bird with lightning markings."""
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["stormraptor"]
    bounce = -1 if frame == 1 else 0

    # Body (bird of prey)
    draw_rect(draw, ox + 9, oy + 13 + bounce, 14, 10, c["body"])
    draw_rect(draw, ox + 11, oy + 11 + bounce, 10, 2, c["body"])

    # Belly with lightning pattern
    draw_rect(draw, ox + 11, oy + 16 + bounce, 10, 5, c["belly"])
    # Lightning zigzag on belly
    px(draw, ox + 14, oy + 17 + bounce, c["lightning"])
    px(draw, ox + 15, oy + 18 + bounce, c["lightning"])
    px(draw, ox + 14, oy + 19 + bounce, c["lightning"])

    # Head (angular, fierce)
    draw_rect(draw, ox + 10, oy + 5 + bounce, 12, 8, c["body"])
    draw_rect(draw, ox + 12, oy + 3 + bounce, 8, 3, c["body"])

    # Crown feathers
    draw_rect(draw, ox + 13, oy + 1 + bounce, 2, 3, c["highlight"])
    draw_rect(draw, ox + 17, oy + 1 + bounce, 2, 3, c["highlight"])

    # Fierce eyes (glowing yellow)
    draw_rect(draw, ox + 12, oy + 7 + bounce, 2, 2, c["eye"])
    draw_rect(draw, ox + 18, oy + 7 + bounce, 2, 2, c["eye"])

    # Sharp beak
    draw_rect(draw, ox + 15, oy + 10 + bounce, 2, 3, c["beak"])
    px(draw, ox + 15, oy + 12 + bounce, c["beak"])

    # Large wings
    wing_flap = -3 if frame == 1 else 0
    draw_rect(draw, ox + 1, oy + 10 + bounce + wing_flap, 9, 6, c["wing"])
    draw_rect(draw, ox + 22, oy + 10 + bounce + wing_flap, 9, 6, c["wing"])
    # Wing lightning
    px(draw, ox + 3, oy + 12 + bounce + wing_flap, c["lightning"])
    px(draw, ox + 5, oy + 13 + bounce + wing_flap, c["lightning"])
    px(draw, ox + 26, oy + 12 + bounce + wing_flap, c["lightning"])
    px(draw, ox + 28, oy + 13 + bounce + wing_flap, c["lightning"])

    # Tail feathers
    draw_rect(draw, ox + 12, oy + 23 + bounce, 8, 4, c["wing"])
    draw_rect(draw, ox + 13, oy + 26 + bounce, 6, 2, c["highlight"])

    # Talons
    draw_rect(draw, ox + 11, oy + 23 + bounce, 3, 4, c["outline"])
    draw_rect(draw, ox + 18, oy + 23 + bounce, 3, 4, c["outline"])


def draw_boulderkin_overworld(img, ox, oy, frame):
    """Boulderkin: living boulder golem with mossy patches."""
    draw = ImageDraw.Draw(img)
    c = CREATURE_PALETTES["boulderkin"]
    bounce = -1 if frame == 1 else 0

    # Body (big chunky boulder)
    draw_rect(draw, ox + 5, oy + 10 + bounce, 22, 14, c["body"])
    draw_rect(draw, ox + 7, oy + 8 + bounce, 18, 2, c["body"])
    draw_rect(draw, ox + 7, oy + 24 + bounce, 18, 2, c["body"])

    # Rocky texture
    draw_rect(draw, ox + 7, oy + 12 + bounce, 5, 4, c["rock"])
    draw_rect(draw, ox + 18, oy + 18 + bounce, 6, 3, c["rock"])
    draw_rect(draw, ox + 10, oy + 20 + bounce, 4, 3, c["rock"])
    draw_rect(draw, ox + 20, oy + 11 + bounce, 4, 4, c["rock"])

    # Face area
    draw_rect(draw, ox + 9, oy + 6 + bounce, 14, 6, c["body"])

    # Eyes
    draw_rect(draw, ox + 11, oy + 8 + bounce, 3, 2, (255, 255, 255))
    draw_rect(draw, ox + 18, oy + 8 + bounce, 3, 2, (255, 255, 255))
    px(draw, ox + 12, oy + 9 + bounce, c["eye"])
    px(draw, ox + 19, oy + 9 + bounce, c["eye"])

    # Mouth
    draw_rect(draw, ox + 13, oy + 11 + bounce, 6, 1, c["outline"])

    # Crystal formation on shoulder
    crystal_glow = 1 if frame == 1 else 0
    draw_rect(draw, ox + 21, oy + 5 + bounce - crystal_glow, 5, 6, c["crystal"])
    draw_rect(draw, ox + 22, oy + 3 + bounce - crystal_glow, 3, 3, (200, 240, 220))
    draw_rect(draw, ox + 23, oy + 1 + bounce - crystal_glow, 2, 3, (220, 255, 240))

    # Moss patches
    draw_rect(draw, ox + 6, oy + 14 + bounce, 4, 2, c["moss"])
    draw_rect(draw, ox + 14, oy + 22 + bounce, 5, 2, c["moss"])

    # Thick arms/fists
    draw_rect(draw, ox + 1, oy + 14 + bounce, 5, 6, c["body"])
    draw_rect(draw, ox + 0, oy + 18 + bounce, 4, 4, c["rock"])
    draw_rect(draw, ox + 26, oy + 14 + bounce, 5, 6, c["body"])
    draw_rect(draw, ox + 28, oy + 18 + bounce, 4, 4, c["rock"])

    # Feet (very sturdy)
    draw_rect(draw, ox + 8, oy + 25 + bounce, 6, 4, c["outline"])
    draw_rect(draw, ox + 18, oy + 25 + bounce, 6, 4, c["outline"])


CREATURE_DRAWERS = {
    "flamepup": draw_flamepup_overworld,
    "aquafin": draw_aquafin_overworld,
    "thornsprout": draw_thornsprout_overworld,
    "zephyrix": draw_zephyrix_overworld,
    "stoneling": draw_stoneling_overworld,
    "blazefox": draw_blazefox_overworld,
    "pyrodrake": draw_pyrodrake_overworld,
    "tidecrab": draw_tidecrab_overworld,
    "tsunariel": draw_tsunariel_overworld,
    "vinewhisker": draw_vinewhisker_overworld,
    "floravine": draw_floravine_overworld,
    "elderoak": draw_elderoak_overworld,
    "breezeling": draw_breezeling_overworld,
    "stormraptor": draw_stormraptor_overworld,
    "boulderkin": draw_boulderkin_overworld,
}


def generate_creature_overworld_sheets():
    """Generate 2-frame idle sheets for each creature (64x32)."""
    for name, drawer in CREATURE_DRAWERS.items():
        sheet = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
        drawer(sheet, 0, 0, 0)   # frame 0
        drawer(sheet, 32, 0, 1)  # frame 1
        path = os.path.join(OUT_DIR, f"{name}_overworld.png")
        sheet.save(path)
        print(f"Created {name}_overworld.png (64x32)")


# ── Battle portraits (48x48) ───────────────────────────────────────────────

def scale_draw(draw_func, img, ox, oy, frame, scale=1.5):
    """Draw at 32x32 then scale up to 48x48."""
    temp = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw_func(temp, 0, 0, frame)
    scaled = temp.resize((48, 48), Image.NEAREST)
    img.paste(scaled, (ox, oy), scaled)


def draw_attack_frame(draw_func, img, ox, oy, phase):
    """Draw an attack frame: creature lunges forward."""
    temp = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw_func(temp, 0, 0, 0)
    # Shift creature right (lunge) and add a slight squash
    scaled = temp.resize((48, 44), Image.NEAREST)
    lunge = 4 if phase == 0 else 8
    img.paste(scaled, (ox + lunge, oy + 2), scaled)


def generate_creature_battle_sheets():
    """Generate 4-frame battle sheets (idle1, idle2, attack1, attack2) at 48x48.
    Sheet size: 192x48."""
    for name, drawer in CREATURE_DRAWERS.items():
        sheet = Image.new("RGBA", (192, 48), (0, 0, 0, 0))

        # Idle frame 1
        scale_draw(drawer, sheet, 0, 0, 0)
        # Idle frame 2
        scale_draw(drawer, sheet, 48, 0, 1)
        # Attack frame 1 (lunge)
        draw_attack_frame(drawer, sheet, 96, 0, 0)
        # Attack frame 2 (full lunge)
        draw_attack_frame(drawer, sheet, 144, 0, 1)

        path = os.path.join(OUT_DIR, f"{name}_battle.png")
        sheet.save(path)
        print(f"Created {name}_battle.png (192x48)")


# ── Main ────────────────────────────────────────────────────────────────────

def generate_creature_single_sprites():
    """Generate standalone 32x32 single-frame sprites for each creature."""
    for name, drawer in CREATURE_DRAWERS.items():
        sprite = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        drawer(sprite, 0, 0, 0)
        path = os.path.join(OUT_DIR, f"{name}.png")
        sprite.save(path)
        print(f"Created {name}.png (32x32)")


if __name__ == "__main__":
    generate_player_sheet()
    generate_creature_single_sprites()
    generate_creature_overworld_sheets()
    generate_creature_battle_sheets()
    print("\nAll sprites generated!")
