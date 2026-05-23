import os
import hashlib
import json
import uuid
import base64
from datetime import datetime
from typing import Optional

from config_schema import SFXAssetConfig, SFXVariantConfig, SFXPipelineConfig


CATEGORY_DIR_MAP = {
    "weapon": "weapons",
    "impact": "impacts",
    "explosion": "explosions",
    "environment": "environment",
    "ui": "ui",
    "voice": "voices",
    "vehicle": "vehicles",
    "creature": "creatures",
    "ambient": "ambient",
    "other": "other",
}

GODOT_UID_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"


def _generate_godot_uid() -> str:
    raw = uuid.uuid4().bytes[:8]
    num = int.from_bytes(raw, "big")
    chars = []
    for _ in range(13):
        chars.append(GODOT_UID_ALPHABET[num % 64])
        num //= 64
    return "uid://" + "".join(reversed(chars))


def _generate_import_hash(source_path: str) -> str:
    return hashlib.md5(source_path.encode()).hexdigest()


def _generate_wav_import(source_file: str) -> str:
    uid = _generate_godot_uid()
    basename = os.path.basename(source_file)
    name_without_ext = os.path.splitext(basename)[0]
    hash_val = hashlib.md5(f"res://assets/audio/{basename}".encode()).hexdigest()

    return f"""[remap]

importer="wav"
type="AudioStreamWAV"
uid="{uid}"
path="res://.godot/imported/{basename}-{hash_val}.sample"

[deps]

source_file="res://assets/audio/{basename}"
dest_files=["res://.godot/imported/{basename}-{hash_val}.sample"]

[params]

force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode=0
edit/loop_begin=0
edit/loop_end=-1
compress/mode=2
"""


class SFXAssetManager:
    def __init__(self, config: SFXPipelineConfig):
        self.config = config
        self.log_entries: list[dict] = []
        self._ensure_output_dir()

    def _ensure_output_dir(self):
        os.makedirs(self.config.output_dir, exist_ok=True)

    def get_output_dir(self) -> str:
        return os.path.abspath(self.config.output_dir)

    def generate_filename(
        self,
        asset: SFXAssetConfig,
        variant: SFXVariantConfig,
        index: int,
    ) -> str:
        prompt_hash = hashlib.md5(variant.description.encode()).hexdigest()[:4]
        return f"{asset.name}_{index:02d}_{prompt_hash}.wav"

    def save_asset(
        self,
        asset: SFXAssetConfig,
        variant: SFXVariantConfig,
        index: int,
        audio_data: bytes,
    ) -> str:
        filename = self.generate_filename(asset, variant, index)
        filepath = os.path.join(self.config.output_dir, filename)

        with open(filepath, "wb") as f:
            f.write(audio_data)

        import_path = filepath + ".import"
        import_content = _generate_wav_import(filepath)
        with open(import_path, "w", encoding="utf-8", newline="\n") as f:
            f.write(import_content)

        self.log_entries.append({
            "filepath": filepath,
            "import_file": import_path,
            "category": asset.category,
            "name": asset.name,
            "variant_description": variant.description,
            "duration": variant.duration,
            "timestamp": datetime.now().isoformat(),
        })

        return filepath

    def save_log(self):
        log_path = os.path.join(self.config.output_dir, "_sfx_generation_log.json")
        log_data = {
            "project": self.config.project,
            "generated_at": datetime.now().isoformat(),
            "total_sfx": len(self.log_entries),
            "entries": self.log_entries,
        }
        with open(log_path, "w", encoding="utf-8") as f:
            json.dump(log_data, f, ensure_ascii=False, indent=2)

    def build_file_summary(self) -> str:
        lines = [f"项目: {self.config.project}"]
        lines.append(f"输出目录: {self.config.output_dir}")
        lines.append(f"总音效数: {len(self.log_entries)}")
        lines.append("-" * 40)
        for entry in self.log_entries:
            lines.append(f"  [{entry['category']}] {os.path.basename(entry['filepath'])}")
        return "\n".join(lines)
