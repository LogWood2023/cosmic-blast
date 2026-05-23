from pathlib import Path

import math
import random

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

src_dir = Path(r"assets/source_ai/realistic")
asteroid_out = Path(r"assets/images/asteroid")
band_out = Path(r"assets/images/isolation_band")
asteroid_out.mkdir(parents=True, exist_ok=True)
band_out.mkdir(parents=True, exist_ok=True)

green = (0, 255, 0, 255)


def pixelate(img, size, low_size):
    img = img.convert("RGBA").resize(size, Image.Resampling.LANCZOS)
    img = ImageEnhance.Contrast(img).enhance(1.28)
    img = ImageEnhance.Sharpness(img).enhance(1.8)
    small = img.resize(low_size, Image.Resampling.BICUBIC)
    small = ImageEnhance.Color(small).enhance(1.12)
    return small.resize(size, Image.Resampling.NEAREST)


def green_cutout(img, threshold=86):
    rgba = img.convert("RGBA")
    bg = Image.new("RGBA", rgba.size, green)
    diff = ImageChops.difference(rgba, bg).convert("L")
    alpha = diff.point(lambda v: 0 if v < threshold else 255).filter(ImageFilter.MinFilter(3))
    out = rgba.copy()
    out.putalpha(alpha)
    return out


def save_green_and_cutout(img, green_path, cutout_path):
    bg = Image.new("RGBA", img.size, green)
    cutout = green_cutout(img)
    bg.alpha_composite(cutout)
    bg.save(green_path)
    cutout.save(cutout_path)


def asteroid_mask(size, seed):
    random.seed(seed)
    low = 128
    mask = Image.new("L", (low, low), 0)
    draw = ImageDraw.Draw(mask)
    center = low * 0.5
    points = []
    for i in range(112):
        a = math.tau * i / 112
        r = random.uniform(42, 58) * (1 + 0.09 * math.sin(a * random.uniform(2, 7) + seed))
        points.append((center + math.cos(a) * r, center + math.sin(a) * r))
    draw.polygon(points, fill=255)
    for _ in range(26):
        a = random.random() * math.tau
        r = random.uniform(42, 58)
        x = center + math.cos(a) * r
        y = center + math.sin(a) * r
        rr = random.uniform(3, 8)
        draw.ellipse((x - rr, y - rr, x + rr, y + rr), fill=0)
    return mask.resize(size, Image.Resampling.NEAREST).filter(ImageFilter.GaussianBlur(0.4))


asteroids = Image.open(src_dir / "asteroids_realistic.png").convert("RGBA")
tiles = [
    (0, 0, 512, 512),
    (512, 0, 1024, 512),
    (0, 512, 512, 1024),
    (512, 512, 1024, 1024),
    (256, 256, 768, 768),
]
for i, box in enumerate(tiles, 1):
    tile = asteroids.crop(box)
    asset = pixelate(tile, (1024, 1024), (128, 128))
    cutout = asset.copy()
    cutout.putalpha(asteroid_mask((1024, 1024), i * 991))
    raw = Image.new("RGBA", (1024, 1024), green)
    raw.alpha_composite(cutout)
    raw.save(asteroid_out / f"space_rock_{i}_raw.png")
    cutout.save(asteroid_out / f"space_rock_{i}_cutout.png")


bands = Image.open(src_dir / "bands_realistic.png").convert("RGBA")
names = [
    "damaged_walkway_1",
    "damaged_walkway_2",
    "damaged_walkway_3",
    "mechanical_debris_1",
    "mechanical_debris_2",
    "mechanical_debris_3",
    "small_asteroid_band_1",
    "small_asteroid_band_2",
    "small_asteroid_band_3",
]
for i, name in enumerate(names):
    row = i // 3
    col = i % 3
    box = (col * 341, row * 341, min(1024, (col + 1) * 341), min(1024, (row + 1) * 341))
    tile = bands.crop(box)
    strip = pixelate(tile, (3000, 500), (300, 50))
    save_green_and_cutout(strip, band_out / f"{name}.png", band_out / f"{name}_cutout.png")
