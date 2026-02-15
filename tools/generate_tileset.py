#!/usr/bin/env python3
"""Generate a 32x32 tileset for the overworld zones.

Tileset layout (8 cols x 4 rows = 32 tiles):
Row 0: Grass variants (light, medium, dark, flowers, path_h, path_v, path_cross, tall_grass)
Row 1: Water/Coast (water, water_anim, sand, shore_top, shore_bot, shore_left, shore_right, dock)
Row 2: Fire/Volcano (lava, lava_anim, rock_dark, rock_light, ash, magma_crack, obsidian, ember_ground)
Row 3: Earth/Cave (cave_floor, stalactite, crystal, dirt, stone_wall, stone_brick, cave_dark, mushroom)
"""

from PIL import Image, ImageDraw
import os
import random

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "tilesets")
os.makedirs(OUT_DIR, exist_ok=True)

TILE_SIZE = 32
COLS, ROWS = 8, 4
IMG_W, IMG_H = COLS * TILE_SIZE, ROWS * TILE_SIZE

random.seed(42)  # Reproducible


def fill_tile(draw, ox, oy, color):
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            draw.point((ox + x, oy + y), fill=color)


def noise_fill(draw, ox, oy, base_color, variation=15):
    r, g, b = base_color
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            dr = random.randint(-variation, variation)
            dg = random.randint(-variation, variation)
            db = random.randint(-variation, variation)
            c = (max(0, min(255, r + dr)), max(0, min(255, g + dg)), max(0, min(255, b + db)), 255)
            draw.point((ox + x, oy + y), fill=c)


def draw_rect(draw, x, y, w, h, color):
    for dy in range(h):
        for dx in range(w):
            draw.point((x + dx, y + dy), fill=color)


# ── Row 0: Grass tiles ──

def draw_grass_light(draw, ox, oy):
    noise_fill(draw, ox, oy, (80, 160, 60), 12)

def draw_grass_medium(draw, ox, oy):
    noise_fill(draw, ox, oy, (60, 140, 45), 10)

def draw_grass_dark(draw, ox, oy):
    noise_fill(draw, ox, oy, (45, 110, 35), 8)

def draw_grass_flowers(draw, ox, oy):
    noise_fill(draw, ox, oy, (70, 150, 55), 10)
    # Scatter flowers
    for _ in range(6):
        fx = random.randint(2, 28)
        fy = random.randint(2, 28)
        fc = random.choice([(255, 100, 100), (255, 255, 100), (200, 100, 255), (255, 200, 100)])
        draw.point((ox + fx, oy + fy), fill=fc)
        draw.point((ox + fx + 1, oy + fy), fill=fc)
        draw.point((ox + fx, oy + fy + 1), fill=fc)

def draw_path_h(draw, ox, oy):
    noise_fill(draw, ox, oy, (60, 140, 45), 8)
    # Horizontal dirt path
    draw_rect(draw, ox, oy + 10, 32, 12, (160, 130, 90))
    noise_fill_rect(draw, ox, oy + 10, 32, 12, (160, 130, 90), 10)

def draw_path_v(draw, ox, oy):
    noise_fill(draw, ox, oy, (60, 140, 45), 8)
    # Vertical dirt path
    noise_fill_rect(draw, ox + 10, oy, 12, 32, (160, 130, 90), 10)

def draw_path_cross(draw, ox, oy):
    noise_fill(draw, ox, oy, (60, 140, 45), 8)
    noise_fill_rect(draw, ox, oy + 10, 32, 12, (160, 130, 90), 10)
    noise_fill_rect(draw, ox + 10, oy, 12, 32, (160, 130, 90), 10)

def draw_tall_grass(draw, ox, oy):
    noise_fill(draw, ox, oy, (55, 130, 40), 8)
    # Tall grass blades
    for x in range(0, 32, 4):
        h = random.randint(8, 16)
        c = (40 + random.randint(0, 30), 120 + random.randint(0, 40), 30)
        for y in range(32 - h, 32):
            draw.point((ox + x, oy + y), fill=c)
            if x + 1 < 32:
                draw.point((ox + x + 1, oy + y), fill=c)


def noise_fill_rect(draw, ox, oy, w, h, base_color, variation=10):
    r, g, b = base_color
    for y in range(h):
        for x in range(w):
            dr = random.randint(-variation, variation)
            dg = random.randint(-variation, variation)
            db = random.randint(-variation, variation)
            c = (max(0, min(255, r + dr)), max(0, min(255, g + dg)), max(0, min(255, b + db)), 255)
            draw.point((ox + x, oy + y), fill=c)


# ── Row 1: Water/Coast ──

def draw_water(draw, ox, oy):
    noise_fill(draw, ox, oy, (40, 80, 180), 15)
    # Wave lines
    for y in range(4, 32, 8):
        for x in range(0, 32, 2):
            draw.point((ox + x, oy + y), fill=(70, 120, 220, 255))

def draw_water_anim(draw, ox, oy):
    noise_fill(draw, ox, oy, (45, 85, 185), 15)
    for y in range(2, 32, 8):
        for x in range(1, 32, 2):
            draw.point((ox + x, oy + y), fill=(80, 130, 230, 255))

def draw_sand(draw, ox, oy):
    noise_fill(draw, ox, oy, (220, 200, 150), 12)

def draw_shore_top(draw, ox, oy):
    # Top half water, bottom half sand
    for y in range(16):
        for x in range(32):
            v = random.randint(-10, 10)
            draw.point((ox + x, oy + y), fill=(40 + v, 80 + v, 180 + v, 255))
    for y in range(16, 32):
        for x in range(32):
            v = random.randint(-10, 10)
            draw.point((ox + x, oy + y), fill=(220 + v, 200 + v, 150 + v, 255))

def draw_shore_bot(draw, ox, oy):
    for y in range(16):
        for x in range(32):
            v = random.randint(-10, 10)
            draw.point((ox + x, oy + y), fill=(220 + v, 200 + v, 150 + v, 255))
    for y in range(16, 32):
        for x in range(32):
            v = random.randint(-10, 10)
            draw.point((ox + x, oy + y), fill=(40 + v, 80 + v, 180 + v, 255))

def draw_shore_left(draw, ox, oy):
    for y in range(32):
        for x in range(16):
            v = random.randint(-10, 10)
            draw.point((ox + x, oy + y), fill=(40 + v, 80 + v, 180 + v, 255))
        for x in range(16, 32):
            v = random.randint(-10, 10)
            draw.point((ox + x, oy + y), fill=(220 + v, 200 + v, 150 + v, 255))

def draw_shore_right(draw, ox, oy):
    for y in range(32):
        for x in range(16):
            v = random.randint(-10, 10)
            draw.point((ox + x, oy + y), fill=(220 + v, 200 + v, 150 + v, 255))
        for x in range(16, 32):
            v = random.randint(-10, 10)
            draw.point((ox + x, oy + y), fill=(40 + v, 80 + v, 180 + v, 255))

def draw_dock(draw, ox, oy):
    noise_fill(draw, ox, oy, (40, 80, 180), 10)
    # Wooden planks
    for y in range(8, 24):
        for x in range(4, 28):
            v = random.randint(-8, 8)
            draw.point((ox + x, oy + y), fill=(140 + v, 100 + v, 60 + v, 255))
    # Plank gaps
    for x_gap in [12, 20]:
        for y in range(8, 24):
            draw.point((ox + x_gap, oy + y), fill=(80, 55, 30, 255))


# ── Row 2: Fire/Volcano ──

def draw_lava(draw, ox, oy):
    noise_fill(draw, ox, oy, (200, 60, 20), 20)
    # Bright spots
    for _ in range(5):
        lx = random.randint(2, 28)
        ly = random.randint(2, 28)
        draw_rect(draw, ox + lx, oy + ly, 3, 3, (255, 200, 50))

def draw_lava_anim(draw, ox, oy):
    noise_fill(draw, ox, oy, (210, 70, 25), 20)
    for _ in range(5):
        lx = random.randint(2, 28)
        ly = random.randint(1, 27)
        draw_rect(draw, ox + lx, oy + ly, 2, 4, (255, 220, 60))

def draw_rock_dark(draw, ox, oy):
    noise_fill(draw, ox, oy, (60, 50, 45), 8)

def draw_rock_light(draw, ox, oy):
    noise_fill(draw, ox, oy, (100, 85, 70), 10)

def draw_ash(draw, ox, oy):
    noise_fill(draw, ox, oy, (80, 75, 70), 6)

def draw_magma_crack(draw, ox, oy):
    noise_fill(draw, ox, oy, (70, 55, 50), 8)
    # Glowing cracks
    for y in range(4, 28, 6):
        for x in range(32):
            if random.random() < 0.3:
                draw.point((ox + x, oy + y), fill=(255, 120, 30, 255))
                draw.point((ox + x, oy + y + 1), fill=(200, 80, 20, 255))

def draw_obsidian(draw, ox, oy):
    noise_fill(draw, ox, oy, (30, 25, 35), 5)
    # Reflective highlights
    for _ in range(3):
        hx = random.randint(4, 26)
        hy = random.randint(4, 26)
        draw.point((ox + hx, oy + hy), fill=(80, 70, 100, 255))

def draw_ember_ground(draw, ox, oy):
    noise_fill(draw, ox, oy, (90, 60, 40), 10)
    # Embers
    for _ in range(4):
        ex = random.randint(2, 28)
        ey = random.randint(2, 28)
        draw.point((ox + ex, oy + ey), fill=(255, 160, 40, 255))


# ── Row 3: Earth/Cave ──

def draw_cave_floor(draw, ox, oy):
    noise_fill(draw, ox, oy, (90, 80, 70), 8)

def draw_stalactite(draw, ox, oy):
    noise_fill(draw, ox, oy, (70, 60, 55), 6)
    # Stalactites hanging
    for x in range(4, 28, 8):
        h = random.randint(6, 14)
        for y in range(h):
            w = max(1, 4 - y // 3)
            for dx in range(w):
                draw.point((ox + x + dx, oy + y), fill=(100, 90, 80, 255))

def draw_crystal(draw, ox, oy):
    noise_fill(draw, ox, oy, (80, 70, 65), 6)
    # Purple/blue crystals
    crystal_colors = [(120, 80, 200), (80, 120, 200), (140, 100, 220)]
    for _ in range(3):
        cx = random.randint(4, 24)
        cy = random.randint(8, 24)
        cc = random.choice(crystal_colors)
        for dy in range(6):
            w = max(1, 3 - abs(dy - 2))
            for dx in range(w):
                draw.point((ox + cx + dx, oy + cy + dy), fill=cc)

def draw_dirt(draw, ox, oy):
    noise_fill(draw, ox, oy, (130, 100, 70), 12)

def draw_stone_wall(draw, ox, oy):
    fill_tile(draw, ox, oy, (80, 75, 70))
    # Brick pattern
    for by in range(0, 32, 8):
        offset = 8 if (by // 8) % 2 else 0
        for bx in range(offset, 32, 16):
            draw_rect(draw, ox + bx, oy + by, 15, 7, (90, 85, 80))
            # Mortar lines
            for x in range(16):
                draw.point((ox + bx + x, oy + by), fill=(60, 55, 50, 255))
            for y in range(8):
                draw.point((ox + bx, oy + by + y), fill=(60, 55, 50, 255))

def draw_stone_brick(draw, ox, oy):
    fill_tile(draw, ox, oy, (110, 100, 90))
    for by in range(0, 32, 8):
        offset = 8 if (by // 8) % 2 else 0
        for bx in range(offset, 32, 16):
            noise_fill_rect(draw, ox + max(0, bx) + 1, oy + by + 1, min(14, 31 - bx), 6, (120, 110, 100), 8)

def draw_cave_dark(draw, ox, oy):
    noise_fill(draw, ox, oy, (30, 25, 25), 5)

def draw_mushroom(draw, ox, oy):
    noise_fill(draw, ox, oy, (80, 70, 65), 6)
    # Mushroom cluster
    for mx, ms in [(8, 4), (18, 6), (24, 3)]:
        # Stem
        draw_rect(draw, ox + mx, oy + 20, 2, 8, (200, 190, 160))
        # Cap
        draw_rect(draw, ox + mx - ms // 2, oy + 18, ms, 4, (180, 60, 60))
        # Spots
        if ms > 3:
            draw.point((ox + mx, oy + 19), fill=(255, 255, 200, 255))


# ── Generate ──

TILE_DRAWERS = [
    # Row 0: Grass
    [draw_grass_light, draw_grass_medium, draw_grass_dark, draw_grass_flowers,
     draw_path_h, draw_path_v, draw_path_cross, draw_tall_grass],
    # Row 1: Water/Coast
    [draw_water, draw_water_anim, draw_sand, draw_shore_top,
     draw_shore_bot, draw_shore_left, draw_shore_right, draw_dock],
    # Row 2: Fire/Volcano
    [draw_lava, draw_lava_anim, draw_rock_dark, draw_rock_light,
     draw_ash, draw_magma_crack, draw_obsidian, draw_ember_ground],
    # Row 3: Earth/Cave
    [draw_cave_floor, draw_stalactite, draw_crystal, draw_dirt,
     draw_stone_wall, draw_stone_brick, draw_cave_dark, draw_mushroom],
]


def main():
    img = Image.new("RGBA", (IMG_W, IMG_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    for row_idx, row_drawers in enumerate(TILE_DRAWERS):
        for col_idx, drawer in enumerate(row_drawers):
            ox = col_idx * TILE_SIZE
            oy = row_idx * TILE_SIZE
            drawer(draw, ox, oy)

    path = os.path.join(OUT_DIR, "terrain_tileset.png")
    img.save(path)
    print(f"Created terrain_tileset.png ({IMG_W}x{IMG_H})")


if __name__ == "__main__":
    main()
