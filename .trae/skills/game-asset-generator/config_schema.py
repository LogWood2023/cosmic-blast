import yaml
from dataclasses import dataclass, field
from typing import Optional


VALID_TYPES = {"character", "background", "ui", "prop", "icon"}
VALID_SIZES = {"256x256", "512x512", "1024x1024", "1792x1024", "1024x1792", "1024x576", "576x1024"}
API_SUPPORTED_SIZES = {"256x256", "512x512", "1024x1024", "1792x1024", "1024x1792"}


def resolve_generate_size(size: str, explicit_generate_size: str | None = None) -> str:
    if explicit_generate_size:
        return explicit_generate_size
    if size in API_SUPPORTED_SIZES:
        return size
    if size == "1024x576":
        return "1792x1024"
    if size == "576x1024":
        return "1024x1792"
    return size


@dataclass
class VariantConfig:
    description: str
    count: int = 1


@dataclass
class AssetConfig:
    type: str
    name: str
    variants: list[VariantConfig] = field(default_factory=list)
    size: str = "1024x1024"
    generate_size: str = "1024x1024"
    model: str = "gpt-image-2"
    extra_prompt: str = ""


@dataclass
class StyleConfig:
    art_style: str = ""
    quality: str = "high detail, game asset"
    negative: str = "blurry, low quality, deformed, watermark"
    style_lock: str = ""
    color_palette: str = ""


@dataclass
class StyleSeedConfig:
    enabled: bool = False
    prompt: str = ""
    size: str = "1024x1024"
    model: str = "gpt-image-2"


@dataclass
class PixelCleanConfig:
    enabled: bool = False
    target_size: int = 256
    num_colors: int = 32
    contrast: float = 1.0
    dither: bool = False


@dataclass
class PipelineConfig:
    project: str = "game_assets"
    output_dir: str = "./generated_assets"
    size: str = "1024x1024"
    style: StyleConfig = field(default_factory=StyleConfig)
    style_seed: StyleSeedConfig = field(default_factory=StyleSeedConfig)
    pixel_clean: PixelCleanConfig = field(default_factory=PixelCleanConfig)
    assets: list[AssetConfig] = field(default_factory=list)


def load_config(config_path: str) -> PipelineConfig:
    with open(config_path, "r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)

    if not raw:
        raise ValueError("配置文件为空")

    style_raw = raw.get("style", {})
    style = StyleConfig(
        art_style=style_raw.get("art_style", ""),
        quality=style_raw.get("quality", "high detail, game asset"),
        negative=style_raw.get("negative", ""),
        style_lock=style_raw.get("style_lock", ""),
        color_palette=style_raw.get("color_palette", ""),
    )

    seed_raw = raw.get("style_seed", {})
    style_seed = StyleSeedConfig(
        enabled=seed_raw.get("enabled", False),
        prompt=seed_raw.get("prompt", ""),
        size=seed_raw.get("size", "1024x1024"),
        model=seed_raw.get("model", "gpt-image-2"),
    )

    clean_raw = raw.get("pixel_clean", {})
    pixel_clean = PixelCleanConfig(
        enabled=clean_raw.get("enabled", False),
        target_size=clean_raw.get("target_size", 256),
        num_colors=clean_raw.get("num_colors", 32),
        contrast=clean_raw.get("contrast", 1.0),
        dither=clean_raw.get("dither", False),
    )

    assets = []
    for item in raw.get("assets", []):
        asset_type = item.get("type", "prop")
        if asset_type not in VALID_TYPES:
            raise ValueError(
                f"无效的素材类型 '{asset_type}'，有效类型: {VALID_TYPES}"
            )

        size = item.get("size", raw.get("size", "1024x1024"))
        if size not in VALID_SIZES:
            raise ValueError(
                f"无效的尺寸 '{size}'，有效尺寸: {VALID_SIZES}"
            )

        generate_size = resolve_generate_size(size, item.get("generate_size"))
        if generate_size not in API_SUPPORTED_SIZES:
            raise ValueError(
                f"无效的 API 生成尺寸 '{generate_size}'，有效尺寸: {API_SUPPORTED_SIZES}"
            )

        variants = []
        for v in item.get("variants", []):
            variants.append(VariantConfig(
                description=v.get("description", ""),
                count=v.get("count", 1),
            ))

        if not variants:
            variants.append(VariantConfig(description="default", count=1))

        assets.append(AssetConfig(
            type=asset_type,
            name=item.get("name", "unnamed"),
            variants=variants,
            size=size,
            generate_size=generate_size,
            model=item.get("model", "gpt-image-2"),
            extra_prompt=item.get("extra_prompt", ""),
        ))

    config = PipelineConfig(
        project=raw.get("project", "game_assets"),
        output_dir=raw.get("output_dir", "./generated_assets"),
        size=raw.get("size", "1024x1024"),
        style=style,
        style_seed=style_seed,
        pixel_clean=pixel_clean,
        assets=assets,
    )

    return config


def build_style_lock(style: StyleConfig) -> str:
    parts = []
    if style.style_lock:
        parts.append(style.style_lock)
    if style.color_palette:
        parts.append(f"color palette: {style.color_palette}")
    if style.art_style:
        parts.append(style.art_style)
    if style.quality:
        parts.append(style.quality)
    if not parts:
        parts.append("game asset")
    return ", ".join(parts)


def build_prompt(
    asset: AssetConfig,
    style: StyleConfig,
    variant_desc: str,
    use_style_lock: bool = True,
) -> str:
    if use_style_lock and style.style_lock:
        lock = build_style_lock(style)
        if asset.extra_prompt:
            return f"{lock} -- {variant_desc}, {asset.extra_prompt}"
        return f"{lock} -- {variant_desc}"

    TYPE_TEMPLATES = {
        "character": f"A full-body {asset.name} character, {variant_desc}, character design, game sprite",
        "background": f"A game background scene of {asset.name}, {variant_desc}, environment art",
        "ui": f"A game UI element of {asset.name}, {variant_desc}, user interface design, game icon style",
        "prop": f"A game prop of {asset.name}, {variant_desc}, item design, game asset",
        "icon": f"A game icon of {asset.name}, {variant_desc}, icon design, clean and simple",
    }

    base = TYPE_TEMPLATES.get(asset.type, f"A game asset of {asset.name}, {variant_desc}")

    parts = [base]
    if style.art_style:
        parts.append(style.art_style)
    if style.quality:
        parts.append(style.quality)
    if style.color_palette:
        parts.append(style.color_palette)
    if asset.extra_prompt:
        parts.append(asset.extra_prompt)

    return ", ".join(parts)
