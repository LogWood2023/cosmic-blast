import random
from pathlib import Path

from PIL import Image, ImageDraw

out = Path(r"assets/images/isolation_band_tiles")
asteroid_dir = Path(r"assets/images/asteroid")
out.mkdir(parents=True, exist_ok=True)

green = (0, 255, 0, 255)
size = 512
low = 256


def load_asteroid_palette():
    colors = []
    for path in sorted(asteroid_dir.glob("space_rock_*_cutout.png")):
        image = Image.open(path).convert("RGBA").resize((128, 128), Image.Resampling.NEAREST)
        for r, g, b, a in image.getdata():
            if a > 200 and not (g > 140 and g > r + 35 and g > b + 35):
                colors.append((r, g, b, 255))
    if not colors:
        colors = [(44, 42, 40, 255), (84, 76, 66, 255), (136, 112, 84, 255), (218, 188, 128, 255)]
    colors.sort(key=lambda c: c[0] + c[1] + c[2])
    step = max(1, len(colors) // 8)
    sampled = [colors[min(len(colors) - 1, i * step)] for i in range(8)]
    return {
        "dark": sampled[0],
        "base": sampled[2],
        "mid": sampled[4],
        "light": sampled[7],
        "accent": sampled[5],
        "all": sampled,
    }


palette = load_asteroid_palette()


def rect(draw, x, y, w, h, color):
    draw.rectangle((x, y, x + w - 1, y + h - 1), fill=color)


def draw_rubble_core(draw, rng, density, band_height):
    mid = low // 2
    rect(draw, 0, mid - band_height // 2, low, band_height, palette["dark"])
    for _ in range(density):
        x = rng.randrange(-12, low + 12)
        y = int(rng.gauss(mid, band_height * 0.28))
        s = rng.choice([4, 6, 8, 10, 12, 14, 16, 20, 24])
        col = rng.choice(palette["all"])
        rect(draw, x, y, s, s, col)
        rect(draw, x, y, max(2, s // 2), 2, palette["light"])
        if s >= 10:
            rect(draw, x + s - 4, y + s - 4, 4, 4, palette["dark"])
        if rng.random() < 0.28:
            rect(draw, x + s // 2, y + 2, 2, max(2, s - 4), palette["accent"])


def draw_bridge_chunks(draw, rng, variant):
    mid = low // 2
    for x in range(-16 + variant * 5, low + 16, 36):
        w = rng.choice([22, 28, 34, 40])
        h = rng.choice([28, 34, 42])
        y = mid - h // 2 + rng.randrange(-10, 11)
        rect(draw, x, y, w, h, palette["base"])
        rect(draw, x, y, w, 4, palette["light"])
        rect(draw, x + w - 5, y + h - 5, 5, 5, palette["dark"])
        if rng.random() < 0.55:
            rect(draw, x + 6, y + 8, w - 12, 4, palette["accent"])


def draw_scattered_rocks(draw, rng):
    mid = low // 2
    for _ in range(90):
        x = rng.randrange(-8, low + 8)
        y = int(rng.gauss(mid, 42))
        w = rng.choice([6, 8, 10, 12, 16])
        h = rng.choice([4, 6, 8, 10, 12])
        col = rng.choice([palette["dark"], palette["base"], palette["mid"], palette["accent"]])
        rect(draw, x, y, w, h, col)
        rect(draw, x, y, max(2, w // 2), 2, palette["light"])


def save_tile(kind, variant):
    rng = random.Random(8000 + variant + ["space_elevator", "metal_debris", "asteroid_rubble"].index(kind) * 100)
    img = Image.new("RGBA", (low, low), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    if kind == "space_elevator":
        draw_rubble_core(draw, rng, 145, 112)
        draw_bridge_chunks(draw, rng, variant)
    elif kind == "metal_debris":
        draw_rubble_core(draw, rng, 210, 96)
        draw_scattered_rocks(draw, rng)
    else:
        draw_rubble_core(draw, rng, 260, 124)
        draw_scattered_rocks(draw, rng)
    for x in range(0, low, 16):
        rect(draw, x, low // 2 - 60, 6, 6, palette["light"] if (x // 16 + variant) % 4 == 0 else palette["mid"])
    cutout = img.resize((size, size), Image.Resampling.NEAREST)
    raw = Image.new("RGBA", (size, size), green)
    raw.alpha_composite(cutout)
    raw.save(out / f"{kind}_{variant}.png")
    cutout.save(out / f"{kind}_{variant}_cutout.png")


for kind in ["space_elevator", "metal_debris", "asteroid_rubble"]:
    for variant in range(1, 4):
        save_tile(kind, variant)
