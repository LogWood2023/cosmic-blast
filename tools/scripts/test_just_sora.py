
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
print("测试 sora 分组的 gpt-image-2")
print(f"{'='*60}\n")
print("配置：")
print("  base_url: https://www.packyapi.com")
print("  model: gpt-image-2")
print("  timeout: 120秒")
print(f"\n正在请求... (请耐心等待)")

try:
    api_key = os.getenv("PACKY_API_KEY")
    generator = PackyAPIGenerator(
        api_key=api_key, 
        base_url="https://www.packyapi.com", 
        default_model="gpt-image-2"
    )
    
    request = GenerationRequest(
        prompt="simple pixel art test",
        n=1,
        size="1024x1024",
        model="gpt-image-2"
    )
    
    result = generator.generate(request, max_retries=1)
    
    if result.success:
        print(f"\n✅ 成功！")
        print(f"  图像 URL: {result.image_url}")
    else:
        print(f"\n❌ 失败: {result.error_message}")
        
except Exception as e:
    print(f"\n❌ 异常: {type(e).__name__}")
    print(f"  异常信息: {str(e)}")
    import traceback
    print(f"  堆栈跟踪: {traceback.format_exc()}")
