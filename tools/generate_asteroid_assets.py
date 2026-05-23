import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

out = Path(r"assets/images/asteroid")
out.mkdir(parents=True, exist_ok=True)

palettes = [
    ((74, 72, 68), (205, 202, 186), (18, 18, 20), (122, 118, 108)),
    ((104, 72, 48), (232, 174, 98), (30, 18, 14), (156, 98, 58)),
    ((58, 82, 98), (168, 218, 226), (14, 22, 28), (92, 134, 152)),
    ((82, 62, 100), (206, 162, 236), (20, 14, 28), (132, 94, 164)),
    ((86, 92, 68), (220, 224, 150), (24, 28, 18), (132, 146, 92)),
]

green_bg = (0, 255, 0, 255)

def quantize(v, step):
    return int(max(0, min(255, round(v / step) * step)))


for idx, (base, high, dark, mid) in enumerate(palettes, 1):
    random.seed(idx * 1009)
    size = 1024
    pixel = 6
    low = size // pixel
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = Image.new("L", (low, low), 0)
    draw_mask = ImageDraw.Draw(mask)
    pts = []
    center = low / 2
    for i in range(96):
        a = math.tau * i / 96
        r = random.uniform(68, 82) * (1 + 0.07 * math.sin(a * random.uniform(2, 7) + idx))
        pts.append((center + math.cos(a) * r, center + math.sin(a) * r))
    draw_mask.polygon(pts, fill=255)
    low_img = Image.new("RGBA", (low, low), (0, 0, 0, 0))
    px = low_img.load()
    for y in range(low):
        for x in range(low):
            a = mask.getpixel((x, y))
            if a <= 0:
                continue
            dx = (x - center) / 82
            dy = (y - center) / 82
            dist = min(1, math.sqrt(dx * dx + dy * dy))
            light = max(0, 1 - ((dx + 0.48) ** 2 + (dy + 0.52) ** 2) ** 0.5)
            rng = random.Random(x * 928371 + y * 1237 + idx * 777)
            noise = rng.random()
            grain = rng.choice([-16, -8, 0, 8, 16])
            vignette = max(0, (dx * 0.55 + dy * 0.72))
            shade = 0.42 + light * 0.72 - dist * 0.40 - vignette * 0.18 + (noise - 0.5) * 0.18
            band = high if shade > 0.88 else mid if shade > 0.62 else base if shade > 0.42 else dark
            warmth = max(0, light - 0.45)
            col = tuple(quantize(band[c] * (0.68 + shade * 0.42) + (18 if c == 0 else 10 if c == 1 else 0) * warmth + grain, 8) for c in range(3))
            px[x, y] = (*col, a)
    draw = ImageDraw.Draw(low_img, "RGBA")
    for _ in range(110):
        a = random.random() * math.tau
        r = random.uniform(0, 70)
        x = center + math.cos(a) * r
        y = center + math.sin(a) * r
        rr = random.uniform(2, 8)
        draw.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(*dark, random.randint(130, 220)))
        draw.arc((x - rr, y - rr, x + rr, y + rr), 195, 35, fill=(*high, random.randint(150, 235)), width=1)
        if random.random() < 0.35:
            draw.point((x - rr * 0.35, y - rr * 0.35), fill=(*high, 230))
    for _ in range(72):
        a = random.random() * math.tau
        r = random.uniform(0, 72)
        x = center + math.cos(a) * r
        y = center + math.sin(a) * r
        length = random.uniform(10, 34)
        angle = random.random() * math.tau
        color = high if idx in (3, 4, 5) else dark
        draw.line((x, y, x + math.cos(angle) * length, y + math.sin(angle) * length), fill=(*color, random.randint(155, 240)), width=random.randint(1, 2))
    for _ in range(95):
        x = random.randrange(low)
        y = random.randrange(low)
        if mask.getpixel((x, y)) > 0:
            c = high if random.random() < 0.45 else dark
            draw.point((x, y), fill=(*c, random.randint(180, 255)))
    img = low_img.resize((size, size), Image.Resampling.NEAREST)
    alpha = img.getchannel("A").filter(ImageFilter.GaussianBlur(0.4))
    img.putalpha(alpha)
    rim_mask = alpha.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.GaussianBlur(0.8))
    rim = Image.new("RGBA", (size, size), (*high, 0))
    rim.putalpha(rim_mask.point(lambda a: min(a, 95)))
    img = Image.alpha_composite(rim, img)
    img.putalpha(alpha)
    img.save(out / f"space_rock_{idx}_cutout.png")
    bg = Image.new("RGBA", (size, size), green_bg)
    bg.alpha_composite(img)
    bg.save(out / f"space_rock_{idx}_raw.png")
