import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

out = Path(r"assets/images/explore")
out.mkdir(parents=True, exist_ok=True)

size = 1080
tile = 6
low = size // tile
random.seed(52021)

img = Image.new("RGB", (low, low), (5, 9, 28))
px = img.load()

for y in range(low):
    for x in range(low):
        nx = min(x, low - 1 - x) / (low * 0.5)
        ny = min(y, low - 1 - y) / (low * 0.5)
        edge_soft = min(nx, ny)
        wave = int(8 * edge_soft + 5 * random.random())
        px[x, y] = (4 + wave // 4, 8 + wave // 3, 28 + wave)

draw = ImageDraw.Draw(img, "RGBA")
for _ in range(520):
    x = random.randrange(low)
    y = random.randrange(low)
    b = random.randint(110, 245)
    color = (b - random.randint(0, 25), b - random.randint(0, 10), 255, random.randint(120, 255))
    if random.random() < 0.82:
        draw.point((x, y), fill=color)
    else:
        draw.rectangle((x, y, min(low - 1, x + 1), y), fill=color)

for _ in range(28):
    x = random.randrange(low)
    y = random.randrange(low)
    r = random.randint(2, 7)
    c = random.choice([(18, 42, 88, 50), (35, 28, 80, 45), (12, 70, 95, 35)])
    draw.ellipse((x - r, y - r, x + r, y + r), fill=c)

for _ in range(16):
    x = random.randrange(low)
    y = random.randrange(low)
    length = random.randint(5, 16)
    color = random.choice([(28, 70, 128, 65), (40, 34, 115, 55), (18, 95, 120, 50)])
    draw.line((x, y, x + length, y + random.randint(-2, 2)), fill=color, width=1)

big = img.resize((size, size), Image.Resampling.NEAREST)
big.save(out / "pixel_starfield_tile.png")
