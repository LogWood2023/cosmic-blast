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
    load_config, build_sfx_prompt,
    SFXAssetConfig, SFXVariantConfig, SFXPipelineConfig, SFXStyleConfig,
)
from sfx_manager import SFXAssetManager
from model_registry import CATEGORY_MODEL_CHAINS, MODEL_NOTES, describe_model_chain, get_model_chain
from generators.huggingface_gen import HuggingFaceSFXGenerator, SFXGenerationRequest
from generators.openai_tts_gen import OpenAITTSGenerator
from generators.procedural_gen import ProceduralSFXGenerator


def parse_args():
    parser = argparse.ArgumentParser(
        description="AI 音效/语音批量生成管线 - 支持 Hugging Face、OpenAI TTS 与本地程序化合成"
    )
    parser.add_argument(
        "-c", "--config",
        default=None,
        help="音效配置文件路径 (YAML)",
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
        "--hf-token",
        type=str,
        default=None,
        help="Hugging Face Token (优先级高于环境变量)",
    )
    parser.add_argument(
        "--model",
        type=str,
        default=None,
        help="覆盖默认模型；传 auto 表示按音效类别自动选择并 fallback (默认 auto)",
    )
    parser.add_argument(
        "--backend",
        choices=["auto", "hf", "openai-tts", "procedural"],
        default="auto",
        help="生成后端：auto 优先 OpenAI TTS 处理 voice，其余优先 Hugging Face；hf 仅 Hugging Face；openai-tts 仅 GPT TTS；procedural 仅本地合成",
    )
    parser.add_argument(
        "--openai-api-key",
        type=str,
        default=None,
        help="OpenAI API Key (优先级高于环境变量 OPENAI_API_KEY)",
    )
    parser.add_argument(
        "--openai-base-url",
        type=str,
        default=None,
        help="OpenAI 兼容 API Base URL (可选，默认读取 OPENAI_BASE_URL)",
    )
    parser.add_argument(
        "--list-models",
        action="store_true",
        help="列出内置 Hugging Face 线上模型链，不生成音效",
    )
    return parser.parse_args()


def print_model_registry() -> None:
    print("\nHugging Face 线上模型链:")
    print("=" * 60)
    for category, chain in CATEGORY_MODEL_CHAINS.items():
        print(f"[{category}] {' -> '.join(chain)}")
    print("\n模型说明:")
    for model, note in MODEL_NOTES.items():
        print(f"- {model}: {note}")
    print()


def run_pipeline(
    config_path: str,
    dry_run: bool = False,
    max_retries: int = 3,
    hf_token: str | None = None,
    override_model: str | None = None,
    backend: str = "auto",
    openai_api_key: str | None = None,
    openai_base_url: str | None = None,
):
    config = load_config(config_path)

    total_count = sum(v.count for a in config.assets for v in a.variants)

    effective_override_model = override_model or "auto"

    print(f"\n{'='*60}")
    print(f"  项目: {config.project}")
    print(f"  输出目录: {os.path.abspath(config.output_dir)}")
    print(f"  音效类型: {len(config.assets)} 种")
    print(f"  总生成数: {total_count} 个")
    if config.style.audio_style:
        print(f"  风格: {config.style.audio_style}")
    print(f"  模型策略: {effective_override_model}")
    print(f"  生成后端: {backend}")
    if dry_run:
        print(f"  预览模式 - 不会实际调用 API")
    print(f"{'='*60}\n")

    if dry_run:
        for asset in config.assets:
            selected_model = effective_override_model if effective_override_model != "auto" else asset.model
            print(f"[{asset.category}] {asset.name} (时长 {asset.variants[0].duration if asset.variants else 5.0}s)")
            print(f"  model_chain: {describe_model_chain(asset.category, selected_model)}")
            for variant in asset.variants:
                prompt = build_sfx_prompt(asset, config.style, variant.description)
                print(f"  - [{variant.count}x] {variant.description}")
                if asset.category == "voice" and variant.text:
                    print(f"    tts_text: {variant.text}")
                    print(f"    tts_voice: {variant.voice or 'alloy'}")
                print(f"    prompt: {prompt[:140]}...")
            print()
        return

    hf_generator = None
    openai_tts_generator = None
    procedural_generator = ProceduralSFXGenerator()
    if backend in {"auto", "openai-tts"}:
        try:
            openai_tts_generator = OpenAITTSGenerator(
                api_key=openai_api_key,
                base_url=openai_base_url,
            )
        except Exception as e:
            if backend == "openai-tts":
                raise
            print(f"OpenAI TTS 后端不可用，voice 将回退到其他后端: {e}")
    if backend in {"auto", "hf"}:
        try:
            hf_generator = HuggingFaceSFXGenerator(
                hf_token=hf_token,
                default_model="facebook/audiogen-medium",
            )
        except Exception as e:
            if backend == "hf":
                raise
            print(f"Hugging Face 后端不可用，将使用本地 procedural 后端: {e}")
    manager = SFXAssetManager(config)

    total = 0
    success = 0
    failed = 0

    for asset in config.assets:
        print(f"\n[{asset.category}] {asset.name}")

        for variant in asset.variants:
            prompt = build_sfx_prompt(asset, config.style, variant.description)
            selected_model = effective_override_model if effective_override_model != "auto" else asset.model
            model_chain = get_model_chain(asset.category, selected_model)
            print(f"  变体: {variant.description}")
            print(f"  model_chain: {' -> '.join(model_chain)}")
            print(f"  prompt: {prompt[:100]}...")

            for i in range(variant.count):
                total += 1
                print(f"  生成 {i+1}/{variant.count}...", end=" ", flush=True)

                request = SFXGenerationRequest(
                    prompt=prompt,
                    duration=variant.duration,
                    model=model_chain[0],
                    extra_params={
                        "category": asset.category,
                        "text": variant.text,
                        "voice": variant.voice,
                        "instructions": variant.instructions or prompt,
                        "speed": variant.speed,
                    },
                )

                if backend == "openai-tts" or (backend == "auto" and asset.category == "voice" and openai_tts_generator is not None):
                    result = openai_tts_generator.generate(request, max_retries=max_retries)
                elif backend == "procedural" or hf_generator is None:
                    result = procedural_generator.generate(request, max_retries=max_retries)
                else:
                    result = hf_generator.generate_with_fallback(request, model_chain, max_retries=max_retries)
                    if backend == "auto" and not result.success:
                        print("HF_FAILED_USE_PROCEDURAL", end=" ", flush=True)
                        result = procedural_generator.generate(request, max_retries=max_retries)

                if result.success and result.audio_data:
                    filepath = manager.save_asset(asset, variant, i, result.audio_data)
                    success += 1
                    selected = result.metadata.get("selected_model") or result.metadata.get("backend") or model_chain[0]
                    print(f"OK {os.path.basename(filepath)} ({result.sample_rate}Hz, {selected})")
                else:
                    failed += 1
                    print(f"FAILED {result.error_message}")

    manager.save_log()

    print(f"\n{'='*60}")
    print(f"  完成！")
    print(f"  总数: {total}  |  成功: {success}  |  失败: {failed}")
    print(f"  输出: {os.path.abspath(config.output_dir)}")
    print(f"{'='*60}\n")

    if success > 0:
        print("提示: 在 Godot 编辑器中刷新项目以加载新生成的音效文件。")


def main():
    args = parse_args()

    if args.list_models:
        print_model_registry()
        return

    if not args.config:
        print("错误: 请通过 -c/--config 指定音效配置文件，或使用 --list-models 查看模型链")
        sys.exit(1)

    config_path = os.path.abspath(args.config)
    if not os.path.exists(config_path):
        print(f"错误: 配置文件不存在: {config_path}")
        sys.exit(1)

    run_pipeline(
        config_path=config_path,
        dry_run=args.dry_run,
        max_retries=args.max_retries,
        hf_token=args.hf_token,
        override_model=args.model,
        backend=args.backend,
        openai_api_key=args.openai_api_key,
        openai_base_url=args.openai_base_url,
    )


if __name__ == "__main__":
    main()
