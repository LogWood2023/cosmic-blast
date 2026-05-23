import os
import json
import hashlib
from datetime import datetime
from dataclasses import dataclass
from typing import Optional

from config_schema import PipelineConfig, StyleConfig


@dataclass
class StyleSeedResult:
    image_data: Optional[bytes]
    revised_prompt: str
    filepath: str
    seed_hash: str


class StyleSeedManager:
    def __init__(self, config: PipelineConfig, output_dir: str):
        self.config = config
        self.output_dir = output_dir

    def get_seed_dir(self) -> str:
        d = os.path.join(self.output_dir, "_style_seed")
        os.makedirs(d, exist_ok=True)
        return d

    def save_seed(self, image_data: bytes, revised_prompt: str) -> StyleSeedResult:
        seed_dir = self.get_seed_dir()
        seed_hash = hashlib.md5(revised_prompt.encode()).hexdigest()[:8]
        filename = f"style_seed_{seed_hash}.png"
        filepath = os.path.join(seed_dir, filename)

        with open(filepath, "wb") as f:
            f.write(image_data)

        meta = {
            "project": self.config.project,
            "generated_at": datetime.now().isoformat(),
            "seed_hash": seed_hash,
            "prompt": self.config.style_seed.prompt,
            "revised_prompt": revised_prompt,
            "style_config": {
                "art_style": self.config.style.art_style,
                "quality": self.config.style.quality,
                "color_palette": self.config.style.color_palette,
            },
        }
        meta_path = os.path.join(seed_dir, f"style_seed_{seed_hash}.json")
        with open(meta_path, "w", encoding="utf-8") as f:
            json.dump(meta, f, ensure_ascii=False, indent=2)

        return StyleSeedResult(
            image_data=image_data,
            revised_prompt=revised_prompt,
            filepath=filepath,
            seed_hash=seed_hash,
        )

    @staticmethod
    def extract_style_lock(revised_prompt: str) -> str:
        stop_words = [
            "featuring a ", "depicting a ", "showing a ", "with a ",
            "that shows ", "which includes ", "containing ",
            "featuring ", "depicting ", "showing ",
        ]
        lock = revised_prompt
        for word in stop_words:
            idx = lock.find(word)
            if idx > 20:
                lock = lock[:idx].strip(" ,")
                break
        return lock

    def load_latest_seed(self) -> Optional[StyleSeedResult]:
        seed_dir = self.get_seed_dir()
        if not os.path.isdir(seed_dir):
            return None

        json_files = sorted(
            [f for f in os.listdir(seed_dir) if f.endswith(".json")],
            reverse=True,
        )
        if not json_files:
            return None

        with open(os.path.join(seed_dir, json_files[0]), "r", encoding="utf-8") as f:
            meta = json.load(f)

        png_name = json_files[0].replace(".json", ".png")
        png_path = os.path.join(seed_dir, png_name)

        return StyleSeedResult(
            image_data=None,
            revised_prompt=meta["revised_prompt"],
            filepath=png_path,
            seed_hash=meta["seed_hash"],
        )

    def get_style_lock_from_seed(self) -> Optional[str]:
        result = self.load_latest_seed()
        if result:
            return self.extract_style_lock(result.revised_prompt)
        return None
