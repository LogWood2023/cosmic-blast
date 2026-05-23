#!/usr/bin/env python3
import argparse
import sys
import os
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".env"))
    load_dotenv()
except ImportError:
    pass

from config_schema import (
    load_config, build_prompt, build_style_lock,
    AssetConfig, VariantConfig, PipelineConfig, StyleConfig,
)
from asset_manager import AssetManager
from generators.packyapi_gen import PackyAPIGenerator, GenerationRequest
from postprocess.processor import PostProcessor
from style_seed import StyleSeedManager


def parse_args():
    parser = argparse.ArgumentParser(
        description="Pixel Art 游戏素材批量生成管线 - 基于 PackyAPI gpt-image-2"
    )
    parser.add_argument(
        "-c", "--config",
        required=True,
        help="素材配置文件路径 (YAML)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="预览模式，不实际调用 API",
    )
    parser.add_argument(
        "--max-retries",
        type=int,
        default=3,
        help="API 调用失败重试次数 (默认 3)",
    )
    parser.add_argument(
        "--api-key",
        type=str,
        default=None,
        help="Packy API Key (优先级高于环境变量)",
    )
    parser.add_argument(
        "--no-style-lock",
        action="store_true",
        help="禁用 style_lock，使用传统 prompt 拼接",
    )
    parser.add_argument(
        "--style-seed-only",
        action="store_true",
        help="仅生成 style seed 参考图，不生成素材",
    )
    parser.add_argument(
        "--resume-seed",
        type=str,
        default=None,
        help="从已有 seed 恢复风格锁（传入 seed hash 或自动使用最新）",
    )
    parser.add_argument(
        "--cutout",
        action="store_true",
        help="启用 rembg 背景去除，输出透明 PNG",
    )
    parser.add_argument(
        "--cutout-model",
        type=str,
        default="u2netp",
        choices=["u2net", "u2netp", "isnet-anime", "birefnet-general", "bria-rmbg"],
        help="rembg 抠图模型 (默认 u2netp，快速通用)",
    )
    parser.add_argument(
        "--pixel-clean",
        action="store_true",
        help="启用像素清理：降采样→色板量化→近邻放大，去除抗锯齿/脏像素",
    )
    parser.add_argument(
        "--pixel-grid",
        type=int,
        default=256,
        help="像素清理的中间降采样尺寸 (默认 256，越小越像素化)",
    )
    parser.add_argument(
        "--pixel-colors",
        type=int,
        default=32,
        help="像素清理后的色板颜色数 (默认 32)",
    )
    parser.add_argument(
        "--pixel-contrast",
        type=float,
        default=1.0,
        help="像素清理前的对比度增强 (默认 1.0 不增强)",
    )
    return parser.parse_args()


def generate_style_seed(
    seed_manager: StyleSeedManager,
    generator: PackyAPIGenerator,
    config: PipelineConfig,
    max_retries: int = 3,
) -> str | None:
    seed_cfg = config.style_seed
    prompt = seed_cfg.prompt or config.style.art_style or "game art style reference, concept art"

    print(f"\n🎨 生成 Style Seed 参考图...")
    print(f"   prompt: {prompt[:100]}...")

    request = GenerationRequest(
        prompt=prompt,
        size=seed_cfg.size,
        model=seed_cfg.model,
        n=1,
    )

    result = generator.generate(request, max_retries=max_retries)
    if not (result.success and result.image_data):
        print(f"   ❌ Style Seed 生成失败: {result.error_message}")
        return None

    revised = result.metadata.get("revised_prompt", prompt)
    seed_result = seed_manager.save_seed(result.image_data, revised)

    print(f"   ✅ 已保存: {seed_result.filepath}")
    print(f"   revised_prompt: {revised[:120]}...")

    style_lock = seed_manager.extract_style_lock(revised)
    print(f"   🔒 style_lock: {style_lock[:120]}...")

    return style_lock


def build_effective_style_lock(style: StyleConfig, seed_manager: StyleSeedManager, resume_seed: str | None) -> tuple[str, bool]:
    if style.style_lock:
        return build_style_lock(style), True

    if resume_seed is not None:
        result = seed_manager.load_latest_seed()
        if result:
            lock = seed_manager.extract_style_lock(result.revised_prompt)
            return lock, True

    return "", False


def run_pipeline(
    config_path,
    dry_run=False,
    max_retries=3,
    api_key=None,
    no_style_lock=False,
    style_seed_only=False,
    resume_seed=None,
    cutout=False,
    cutout_model="isnet-anime",
    pixel_clean=False,
    pixel_grid=256,
    pixel_colors=32,
    pixel_contrast=1.0,
):
    config = load_config(config_path)
    use_lock = not no_style_lock

    if pixel_clean or config.pixel_clean.enabled:
        pixel_clean = True
    if pixel_clean:
        from config_schema import PixelCleanConfig
        pc = config.pixel_clean
        if pc.enabled:
            pixel_grid = pixel_grid if pixel_grid != 256 else pc.target_size
            pixel_colors = pixel_colors if pixel_colors != 32 else pc.num_colors
            pixel_contrast = pixel_contrast if pixel_contrast != 1.0 else pc.contrast

    total_count = sum(v.count for a in config.assets for v in a.variants)

    print(f"\n{'='*60}")
    print(f"  项目: {config.project}")
    print(f"  输出目录: {config.output_dir}")
    print(f"  素材类型: {len(config.assets)} 种")
    print(f"  总生成数: {total_count} 张")
    if config.style.style_lock:
        print(f"  🔒 Style Lock: 已配置（YAML 内直接指定）")
    elif config.style_seed.enabled:
        print(f"  🌱 Style Seed: 已启用（自动锚定风格）")
    if cutout:
        print(f"  ✂️  抠图: 已启用 (模型: {cutout_model})")
    if pixel_clean:
        print(f"  🧹 像素清理: 已启用 (网格 {pixel_grid}px, {pixel_colors}色)")
    if dry_run:
        print(f"  🔍 预览模式 - 不会实际调用 API")
    print(f"{'='*60}\n")

    if dry_run:
        for asset in config.assets:
            print(f"[{asset.type}] {asset.name} ({asset.size})")
            for variant in asset.variants:
                prompt = build_prompt(asset, config.style, variant.description, use_style_lock=use_lock)
                print(f"  ├─ [{variant.count}x] {variant.description}")
                print(f"  │  prompt: {prompt[:140]}...")
            print()
        return

    generator = PackyAPIGenerator(api_key=api_key)
    manager = AssetManager(config)
    processor = PostProcessor()
    seed_manager = StyleSeedManager(config, config.output_dir)

    if cutout:
        print(f"✂️  初始化 rembg (模型: {cutout_model})...", end=" ", flush=True)
        processor.init_cutout(model=cutout_model)
        print("就绪")

    effective_lock, has_lock = build_effective_style_lock(config.style, seed_manager, resume_seed)

    if has_lock:
        print(f"🔒 Style Lock 已激活:")
        print(f"   {effective_lock[:150]}...")
    else:
        print(f"⚠️  未启用 Style Lock，各素材 prompt 独立拼接")

    if style_seed_only:
        if not config.style_seed.enabled:
            print("❌ style_seed 未在配置中启用，请设置 style_seed.enabled: true")
            return
        generate_style_seed(seed_manager, generator, config, max_retries)
        return

    if config.style_seed.enabled and effective_lock:
        if config.style.style_lock:
            pass
        else:
            print(f"\n🌱 正在自动生成 Style Seed 作为风格锚点...")
            seed_lock = generate_style_seed(seed_manager, generator, config, max_retries)
            if seed_lock:
                effective_lock = seed_lock
                config.style.style_lock = effective_lock

    total = 0
    success = 0
    failed = 0

    for asset in config.assets:
        print(f"\n📦 [{asset.type}] {asset.name} ({asset.size})")

        for variant in asset.variants:
            prompt = build_prompt(asset, config.style, variant.description, use_style_lock=use_lock and bool(effective_lock))
            print(f"  ├─ 变体: {variant.description}")
            print(f"  │  prompt: {prompt[:120]}...")

            for i in range(variant.count):
                total += 1
                print(f"  │  生成 {i+1}/{variant.count}...", end=" ", flush=True)

                request = GenerationRequest(
                    prompt=prompt,
                    size=asset.size,
                    model=asset.model,
                    n=1,
                )

                result = generator.generate(request, max_retries=max_retries)

                if result.success and result.image_data:
                    processed = processor.strip_metadata(result.image_data)

                    if pixel_clean:
                        processed = processor.clean_pixel_art(
                            processed,
                            target_size=pixel_grid,
                            num_colors=pixel_colors,
                            contrast=pixel_contrast,
                        )

                    if cutout:
                        processed = processor.remove_background(processed)

                    filepath = manager.save_asset(asset, variant, i, processed)
                    success += 1
                    icons = []
                    if pixel_clean:
                        icons.append("🧹")
                    if cutout:
                        icons.append("✂️")
                    icon = "".join(icons) if icons else "✅"
                    print(f"{icon} {os.path.basename(filepath)}")
                elif result.success and result.image_url:
                    print(f"⚠️  仅返回URL，跳过: {result.image_url[:80]}")
                    failed += 1
                else:
                    failed += 1
                    print(f"❌ {result.error_message}")

    manager.save_log()

    print(f"\n{'='*60}")
    print(f"  完成！")
    print(f"  总数: {total}  |  成功: {success}  |  失败: {failed}")
    print(f"  输出: {os.path.abspath(config.output_dir)}")
    if effective_lock:
        print(f"  🔒 风格锁定: 已生效")
    if pixel_clean:
        print(f"  🧹 像素清理: 已完成 (网格 {pixel_grid}px, {pixel_colors}色)")
    if cutout:
        print(f"  ✂️  抠图处理: 已完成 (模型: {cutout_model})")
    print(f"{'='*60}\n")


def main():
    args = parse_args()
    config_path = os.path.abspath(args.config)
    if not os.path.exists(config_path):
        print(f"错误: 配置文件不存在: {config_path}")
        sys.exit(1)

    run_pipeline(
        config_path=config_path,
        dry_run=args.dry_run,
        max_retries=args.max_retries,
        api_key=args.api_key,
        no_style_lock=args.no_style_lock,
        style_seed_only=args.style_seed_only,
        resume_seed=args.resume_seed,
        cutout=args.cutout,
        cutout_model=args.cutout_model,
        pixel_clean=args.pixel_clean,
        pixel_grid=args.pixel_grid,
        pixel_colors=args.pixel_colors,
        pixel_contrast=args.pixel_contrast,
    )


if __name__ == "__main__":
    main()
