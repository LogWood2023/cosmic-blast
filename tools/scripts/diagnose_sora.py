
#!/usr/bin/env python3
import sys
import os
from dotenv import load_dotenv

# 加载 .env 文件
load_dotenv()

# 导入 PackyAPIGenerator
sys.path.insert(0, os.path.join(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")), ".trae", "skills", "game-asset-generator"))

from generators.packyapi_gen import PackyAPIGenerator
from generators.base import GenerationRequest

print(f"\n{'='*60}")
print("PackyAPI sora 分组诊断脚本")
print(f"{'='*60}\n")

# 尝试不同的 base_url 和模型组合
test_cases = [
    # 标准方式 - 使用默认分组
    {
        "name": "标准方式 (sora)",
        "base_url": "https://www.packyapi.com",
        "model": "gpt-image-2",
    },
    # 尝试在模型名前显式加分组
    {
        "name": "显式分组 (sora/gpt-image-2)",
        "base_url": "https://www.packyapi.com",
        "model": "sora/gpt-image-2",
    },
    # 尝试通过 base_url 指定分组
    {
        "name": "base_url 指定分组 (/v1/sora)",
        "base_url": "https://www.packyapi.com/v1/sora",
        "model": "gpt-image-2",
    },
    # 尝试 gpt-image-2-c
    {
        "name": "gpt-image-2-c",
        "base_url": "https://www.packyapi.com",
        "model": "gpt-image-2-c",
    },
    # 尝试 dall-e-3
    {
        "name": "dall-e-3",
        "base_url": "https://www.packyapi.com",
        "model": "dall-e-3",
    },
]

for i, test_case in enumerate(test_cases, 1):
    print(f"\n--- 测试 {i}: {test_case['name']} ---")
    print(f"  base_url: {test_case['base_url']}")
    print(f"  model: {test_case['model']}")
    
    try:
        api_key = os.getenv("PACKY_API_KEY")
        generator = PackyAPIGenerator(
            api_key=api_key, 
            base_url=test_case["base_url"], 
            default_model=test_case["model"]
        )
        
        request = GenerationRequest(
            prompt="simple pixel art test",
            n=1,
            size="1024x1024",
            model=test_case["model"]
        )
        
        result = generator.generate(request, max_retries=1)
        
        if result.success:
            print("  ✅ 成功！")
            print(f"  图像 URL: {result.image_url}")
        else:
            print(f"  ❌ 失败: {result.error_message}")
            
    except Exception as e:
        print(f"  ❌ 异常: {type(e).__name__}")
        print(f"  异常信息: {str(e)}")
        import traceback
        print(f"  堆栈跟踪: {traceback.format_exc()[:200]}...")

print(f"\n{'='*60}")
print("诊断完成")
print(f"{'='*60}")
print("\n总结：")
print("- 如果所有测试都失败，说明 PackyAPI 的 sora 分组下确实暂时没有可用的图像模型")
print("- 建议检查 PackyAPI 控制台的模型广场，看看哪些分组和模型当前可用")
