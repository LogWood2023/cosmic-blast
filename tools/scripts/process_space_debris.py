
import os
from PIL import Image
from collections import Counter

BASE_DIR = os.path.join(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")), "assets", "images", "explore", "clutter", "space_debris", "props")
OUTPUT_DIR = os.path.join(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")), "assets", "images", "explore", "clutter", "space_debris", "final")

ITEM_CONFIG = {
    "space_debris_1": {
        "name_prefix": "space_debris",
        "variants": 20,
    },
}


def find_green_colors(img: Image.Image) -> set:
    w, h = img.size
    pixels = img.load()
    samples = []
    margin = 4
    for x in range(margin):
        for y in range(h):
            samples.append(pixels[x, y])
    for x in range(w - margin, w):
        for y in range(h):
            samples.append(pixels[x, y])
    for y in range(margin):
        for x in range(w):
            samples.append(pixels[x, y])
    for y in range(h - margin, h):
        for x in range(w):
            samples.append(pixels[x, y])
    color_counts = Counter(samples)
    green_colors = set()
    for (r, g, b, a), count in color_counts.most_common(50):
        if a > 200 and g > r * 1.4 and g > b * 1.4 and g > 60:
            green_colors.add((r, g, b, a))
    return green_colors


def chroma_key_remove(img: Image.Image) -> Image.Image:
    w, h = img.size
    pixels = img.load()
    green_colors = find_green_colors(img)
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a < 50:
                continue
            if g > r * 1.3 and g > b * 1.3 and g > 50:
                pixels[x, y] = (0, 0, 0, 0)
            elif (r, g, b, a) in green_colors:
                pixels[x, y] = (0, 0, 0, 0)
    return img


def process_all():
    for item_name, config in ITEM_CONFIG.items():
        src_dir = os.path.join(BASE_DIR, item_name)
        if not os.path.isdir(src_dir):
            continue
        dst_dir = os.path.join(OUTPUT_DIR, "")
        os.makedirs(dst_dir, exist_ok=True)
        print(f"\n📦 [{item_name}]")

        png_files = sorted([f for f in os.listdir(src_dir) if f.endswith(".png") and not f.endswith(".import.png")])
        for idx, filename in enumerate(png_files, start=1):
            src_path = os.path.join(src_dir, filename)
            img = Image.open(src_path).convert("RGBA")

            img = chroma_key_remove(img)

            dst_name = f"{config['name_prefix']}_{idx:02d}.png"
            dst_path = os.path.join(dst_dir, dst_name)
            img.save(dst_path, "PNG")
            size_kb = os.path.getsize(dst_path) / 1024
            print(f"  {filename}")
            print(f"    → {dst_name}  |  {img.size[0]}x{img.size[1]}  |  {size_kb:.1f} KB")

    print("\n✅ Space debris processing complete!")


if __name__ == "__main__":
    process_all()
