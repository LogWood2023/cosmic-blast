import os
import hashlib
import json
from datetime import datetime
from typing import Optional
from dataclasses import asdict

from config_schema import AssetConfig, PipelineConfig, VariantConfig


def sanitize_filename(name: str) -> str:
    """Remove or replace illegal characters for filenames and directory names"""
    illegal_chars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|', '\0']
    for char in illegal_chars:
        name = name.replace(char, '_')
    return name


TYPE_DIR_MAP = {
    "character": "characters",
    "background": "backgrounds",
    "ui": "ui",
    "prop": "props",
    "icon": "icons",
}


class AssetManager:
    def __init__(self, config: PipelineConfig):
        self.config = config
        self.log_entries: list[dict] = []
        self._ensure_output_dir()

    def _ensure_output_dir(self):
        os.makedirs(self.config.output_dir, exist_ok=True)

    def get_asset_dir(self, asset: AssetConfig) -> str:
        type_dir = TYPE_DIR_MAP.get(asset.type, "other")
        safe_name = sanitize_filename(asset.name)
        dir_path = os.path.join(self.config.output_dir, type_dir, safe_name)
        os.makedirs(dir_path, exist_ok=True)
        return dir_path

    def generate_filename(self, asset: AssetConfig, variant: VariantConfig, index: int) -> str:
        safe_name = sanitize_filename(asset.name)
        prompt_hash = hashlib.md5(variant.description.encode()).hexdigest()[:4]
        size_str = asset.size.replace("x", "x")
        return f"{safe_name}_{index:02d}_{size_str}_{prompt_hash}.png"

    def save_asset(
        self,
        asset: AssetConfig,
        variant: VariantConfig,
        index: int,
        image_data: bytes,
    ) -> str:
        asset_dir = self.get_asset_dir(asset)
        filename = self.generate_filename(asset, variant, index)
        filepath = os.path.join(asset_dir, filename)

        with open(filepath, "wb") as f:
            f.write(image_data)

        self.log_entries.append({
            "filepath": filepath,
            "type": asset.type,
            "name": asset.name,
            "variant_description": variant.description,
            "size": asset.size,
            "timestamp": datetime.now().isoformat(),
        })

        return filepath

    def save_log(self):
        log_path = os.path.join(self.config.output_dir, "_generation_log.json")
        log_data = {
            "project": self.config.project,
            "generated_at": datetime.now().isoformat(),
            "total_assets": len(self.log_entries),
            "entries": self.log_entries,
        }
        with open(log_path, "w", encoding="utf-8") as f:
            json.dump(log_data, f, ensure_ascii=False, indent=2)

    def build_file_summary(self) -> str:
        lines = [f"项目: {self.config.project}"]
        lines.append(f"输出目录: {self.config.output_dir}")
        lines.append(f"总素材数: {len(self.log_entries)}")
        lines.append("-" * 40)
        for entry in self.log_entries:
            lines.append(f"  [{entry['type']}] {entry['filepath']}")
        return "\n".join(lines)
