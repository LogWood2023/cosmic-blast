import yaml
from dataclasses import dataclass, field
from typing import Optional


VALID_SFX_CATEGORIES = {"weapon", "impact", "explosion", "environment", "ui", "voice", "vehicle", "creature", "ambient", "other"}


@dataclass
class SFXVariantConfig:
    description: str
    count: int = 1
    duration: float = 5.0
    text: str = ""
    voice: str = ""
    instructions: str = ""
    speed: float = 1.0


@dataclass
class SFXAssetConfig:
    name: str
    category: str = "other"
    variants: list[SFXVariantConfig] = field(default_factory=list)
    model: str = "auto"
    extra_prompt: str = ""
    loop_mode: int = 0


@dataclass
class SFXStyleConfig:
    quality: str = "high quality sound effect, clean audio"
    negative: str = ""
    audio_style: str = ""


@dataclass
class SFXPipelineConfig:
    project: str = "game_sfx"
    output_dir: str = "assets/audio"
    style: SFXStyleConfig = field(default_factory=SFXStyleConfig)
    assets: list[SFXAssetConfig] = field(default_factory=list)


def load_config(config_path: str) -> SFXPipelineConfig:
    with open(config_path, "r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)

    if not raw:
        raise ValueError("配置文件为空")

    style_raw = raw.get("style", {})
    style = SFXStyleConfig(
        quality=style_raw.get("quality", "high quality sound effect, clean audio"),
        negative=style_raw.get("negative", ""),
        audio_style=style_raw.get("audio_style", ""),
    )

    assets = []
    for item in raw.get("assets", []):
        category = item.get("category", "other")
        if category not in VALID_SFX_CATEGORIES:
            raise ValueError(
                f"无效的音效类别 '{category}'，有效类别: {VALID_SFX_CATEGORIES}"
            )

        variants = []
        for v in item.get("variants", []):
            variants.append(SFXVariantConfig(
                description=v.get("description", ""),
                count=v.get("count", 1),
                duration=v.get("duration", 5.0),
                text=v.get("text", ""),
                voice=v.get("voice", ""),
                instructions=v.get("instructions", ""),
                speed=v.get("speed", 1.0),
            ))

        if not variants:
            variants.append(SFXVariantConfig(description="default", count=1, duration=5.0))

        assets.append(SFXAssetConfig(
            name=item.get("name", "unnamed_sfx"),
            category=category,
            variants=variants,
            model=item.get("model", "auto"),
            extra_prompt=item.get("extra_prompt", ""),
            loop_mode=item.get("loop_mode", 0),
        ))

    config = SFXPipelineConfig(
        project=raw.get("project", "game_sfx"),
        output_dir=raw.get("output_dir", "assets/audio"),
        style=style,
        assets=assets,
    )

    return config


def build_sfx_prompt(
    asset: SFXAssetConfig,
    style: SFXStyleConfig,
    variant_desc: str,
) -> str:
    category_hints = {
        "weapon": "weapon sound effect, gunshot, laser",
        "impact": "impact sound effect, hit, collision",
        "explosion": "explosion sound effect, blast, boom",
        "environment": "environmental sound effect, ambient",
        "ui": "UI sound effect, interface, click",
        "voice": "voice sound, vocal, speech",
        "vehicle": "vehicle sound effect, engine, motor",
        "creature": "creature sound effect, monster, animal",
        "ambient": "ambient sound, atmosphere, background",
        "other": "sound effect, foley",
    }

    category_hint = category_hints.get(asset.category, "sound effect")
    parts = [variant_desc, category_hint]

    if style.audio_style:
        parts.append(style.audio_style)
    if style.quality:
        parts.append(style.quality)
    if asset.extra_prompt:
        parts.append(asset.extra_prompt)

    return ", ".join(parts)
