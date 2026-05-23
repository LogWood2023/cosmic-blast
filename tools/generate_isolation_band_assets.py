import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

out = Path(r"assets/images/isolation_band")
out.mkdir(parents=True, exist_ok=True)

size = (3000, 500)
low = (750, 125)
green_bg = (0, 255, 0, 255)


def save_pixel_band(name, seed, mode):
    random.seed(seed)
    img = Image.new("RGBA", low, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    mid = low[1] // 2
    if mode == "walkway":
        base = random.choice([(82, 78, 70), (92, 84, 72), (72, 82, 92)])
        draw.rectangle((0, mid - 35, low[0], mid + 35), fill=(*base, 235))
        draw.rectangle((0, mid - 55, low[0], mid - 43), fill=(210, 175, 118, 95))
        draw.rectangle((0, mid + 43, low[0], mid + 55), fill=(12, 14, 18, 150))
        for x in range(-20, low[0], 28):
            shade = random.randint(-18, 24)
            col = tuple(max(0, min(255, c + shade)) for c in base)
            draw.rectangle((x, mid - 42, x + random.randint(12, 24), mid + 42), fill=(*col, 245))
            if random.random() < 0.45:
                draw.rectangle((x + 2, mid - 39, x + 5, mid + 39), fill=(215, 188, 132, 80))
        for _ in range(310):
            x = random.randrange(low[0])
            y = random.randint(mid - 55, mid + 55)
            draw.rectangle((x, y, x + random.randint(2, 8), y + random.randint(1, 4)), fill=(25, 28, 35, random.randint(140, 230)))
        for _ in range(120):
            x = random.randrange(low[0])
            draw.line((x, mid - random.randint(12, 42), x + random.randint(12, 35), mid + random.randint(12, 42)), fill=(218, 188, 132, 130), width=1)
    elif mode == "debris":
        for _ in range(760):
            x = random.randrange(low[0])
            y = int(random.gauss(mid, 28))
            w = random.randint(3, 18)
            h = random.randint(2, 8)
            col = random.choice([(112, 112, 108), (56, 58, 66), (170, 120, 70), (92, 104, 112), (205, 170, 118)])
            draw.rectangle((x, y, x + w, y + h), fill=(*col, random.randint(150, 240)))
            if random.random() < 0.35:
                draw.line((x, y, x + w + random.randint(5, 18), y + random.randint(-5, 5)), fill=(220, 184, 120, 105), width=1)
    else:
        for _ in range(920):
            x = random.randrange(low[0])
            y = int(random.gauss(mid, 30))
            r = random.randint(1, 5)
            col = random.choice([(58, 54, 49), (78, 61, 45), (50, 62, 70), (70, 72, 58), (116, 98, 72)])
            draw.ellipse((x - r, y - r, x + r, y + r), fill=(*col, random.randint(160, 245)))
            if random.random() < 0.2:
                draw.point((x - 1, y - 1), fill=(226, 190, 132, 185))
    glow = Image.new("RGBA", low, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow, "RGBA")
    glow_draw.rectangle((0, mid - 60, low[0], mid - 48), fill=(230, 188, 118, 45))
    img = Image.alpha_composite(glow, img)
    alpha = img.getchannel("A").filter(ImageFilter.GaussianBlur(0.45))
    img.putalpha(alpha)
    big_cutout = img.resize(size, Image.Resampling.NEAREST)
    bg = Image.new("RGBA", size, green_bg)
    bg.alpha_composite(big_cutout)
    bg.save(out / name)
    big_cutout.save(out / name.replace(".png", "_cutout.png"))


for i in range(3):
    save_pixel_band(f"damaged_walkway_{i + 1}.png", 1000 + i, "walkway")
    save_pixel_band(f"mechanical_debris_{i + 1}.png", 2000 + i, "debris")
    save_pixel_band(f"small_asteroid_band_{i + 1}.png", 3000 + i, "asteroid")
