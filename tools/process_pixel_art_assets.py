from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageFilter

src_dir = Path(r"assets/source_ai/pixel_art")
asteroid_out = Path(r"assets/images/asteroid")
band_out = Path(r"assets/images/isolation_band")
green = (0, 255, 0, 255)
green_rgb = green[:3]


def crisp_pixel(img, size, low_size):
    img = img.convert("RGBA").resize(size, Image.Resampling.LANCZOS)
    img = ImageEnhance.Contrast(img).enhance(1.18)
    img = ImageEnhance.Color(img).enhance(1.08)
    small = img.resize(low_size, Image.Resampling.NEAREST)
    return small.resize(size, Image.Resampling.NEAREST)


def chroma_key_green(img, tolerance=120):
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    alpha = Image.new("L", rgba.size, 255)
    alpha_px = alpha.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            green_distance = abs(r - green_rgb[0]) + abs(g - green_rgb[1]) + abs(b - green_rgb[2])
            green_dominance = g - max(r, b)
            if green_distance < tolerance or green_dominance > 45 or (g > 145 and r < 115 and b < 115):
                alpha_px[x, y] = 0
            else:
                alpha_px[x, y] = a
    alpha = alpha.filter(ImageFilter.MinFilter(3))
    alpha = alpha.filter(ImageFilter.MaxFilter(3))
    rgba.putalpha(alpha)
    pixels = rgba.load()
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a > 0 and g > 140 and g > r + 35 and g > b + 35:
                pixels[x, y] = (r, g, b, 0)
    return rgba


def save_pair(asset, raw_path, cutout_path):
    raw = Image.new("RGBA", asset.size, green)
    raw.alpha_composite(asset)
    raw.save(raw_path)
    asset.save(cutout_path)


asteroids = Image.open(src_dir / "asteroids_pixel_art.png")
tiles = [
    (0, 0, 512, 512),
    (512, 0, 1024, 512),
    (0, 512, 512, 1024),
    (512, 512, 1024, 1024),
    (256, 256, 768, 768),
]
for i, box in enumerate(tiles, 1):
    asset = crisp_pixel(asteroids.crop(box), (1024, 1024), (128, 128))
    asset = chroma_key_green(asset)
    save_pair(asset, asteroid_out / f"space_rock_{i}_raw.png", asteroid_out / f"space_rock_{i}_cutout.png")


bands = Image.open(src_dir / "bands_pixel_art.png")
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
    asset = crisp_pixel(bands.crop(box), (3000, 500), (300, 50))
    asset = chroma_key_green(asset)
    save_pair(asset, band_out / f"{name}.png", band_out / f"{name}_cutout.png")
