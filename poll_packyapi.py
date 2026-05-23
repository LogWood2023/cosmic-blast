
#!/usr/bin/env python3
import sys
import os
import time
from datetime import datetime
from dotenv import load_dotenv

# 加载 .env 文件
load_dotenv()

# 导入 PackyAPIGenerator
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".trae", "skills", "game-asset-generator"))

from generators.packyapi_gen import PackyAPIGenerator
from generators.base import GenerationRequest

# 尝试的配置
poll_configs = [
    {"base_url": "https://www.packyapi.com", "model": "gpt-image-2", "name": "default - gpt-image-2"},
    {"base_url": "https://www.packyapi.com", "model": "dall-e-3", "name": "default - dall-e-3"},
    {"base_url": "https://www.packyapi.com/v1", "model": "gpt-image-2", "name": "raw v1 - gpt-image-2"},
]

def test_config(base_url: str, model: str, name: str):
    try:
        print(f"  尝试: {name}...")
        api_key = os.getenv("PACKY_API_KEY")
        generator = PackyAPIGenerator(api_key=api_key, base_url=base_url, default_model=model)
        
        request = GenerationRequest(
            prompt="simple pixel art test item",
            n=1,
            size="1024x1024",
            model=model
        )
        
        result = generator.generate(request, max_retries=1)
        if result.success:
            print(f"  ✅ 成功！")
            return True
        else:
            print(f"  ❌ 失败: {result.error_message[:80]}...")
            return False
        
    except Exception as e:
        print(f"  ❌ 异常: {type(e).__name__}: {str(e)[:80]}...")
        return False

def main():
    print(f"\n{'='*60}")
    print("PackyAPI 可用性轮询脚本")
    print(f"{'='*60}")
    print(f"启动时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"\n正在定期检查 PackyAPI 图像模型服务是否恢复...")
    print(f"检查间隔: 60 秒\n")
    
    poll_interval = 60  # 60秒
    attempt = 0
    
    while True:
        attempt += 1
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 第 {attempt} 次检查...")
        
        # 尝试所有配置
        success = False
        for config in poll_configs:
            if test_config(config["base_url"], config["model"], config["name"]):
                success = True
                print(f"\n{'='*60}")
                print("🎉 PackyAPI 服务已恢复！")
                print(f"{'='*60}")
                print(f"成功的配置:")
                print(f"  base_url: {config['base_url']}")
                print(f"  model: {config['model']}")
                print(f"  name: {config['name']}")
                print(f"\n现在可以继续生成素材了！")
                return
        
        if not success:
            print(f"\n  服务仍然不可用，{poll_interval} 秒后重试...")
            time.sleep(poll_interval)

if __name__ == "__main__":
    main()
