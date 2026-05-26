
import sys
import os
import time
import base64
from datetime import datetime
from dotenv import load_dotenv

# 加载 .env 文件
load_dotenv()

# 导入 PackyAPIGenerator
sys.path.insert(0, os.path.join(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")), ".trae", "skills", "game-asset-generator"))

from generators.packyapi_gen import PackyAPIGenerator
from generators.base import GenerationRequest

# 定义要测试的配置列表
test_configs = [
    {"base_url": "https://www.packyapi.com", "model": "gpt-image-2"},
    {"base_url": "https://www.packyapi.com", "model": "default/gpt-image-2"},
    {"base_url": "https://www.packyapi.com", "model": "gpt-image2"},
    {"base_url": "https://www.packyapi.com", "model": "dall-e-3"},
    {"base_url": "https://www.packyapi.com", "model": "default/dall-e-3"},
    {"base_url": "https://www.packyapi.com/v1/default", "model": "gpt-image-2"},
    {"base_url": "https://www.packyapi.com/v1", "model": "gpt-image-2"},
]

def test_config(base_url: str, model: str):
    print(f"  Testing: base_url={base_url}, model={model}")
    try:
        api_key = os.getenv("PACKY_API_KEY")
        generator = PackyAPIGenerator(api_key=api_key, base_url=base_url, default_model=model)
        request = GenerationRequest(
            prompt="simple pixel art test item on bright green background",
            n=1,
            size="512x512",
            model=model
        )
        result = generator.generate(request, max_retries=1)
        
        if result.success:
            print(f"  ✓ SUCCESS! Working config found.")
            return True, {"base_url": base_url, "model": model}
        else:
            print(f"  ✗ FAILED: {result.error_message}")
            return False, None
    except Exception as e:
        print(f"  ✗ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False, None

def test_api_once():
    print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Testing API availability...")
    
    for config in test_configs:
        success, working_config = test_config(config["base_url"], config["model"])
        if success:
            return True, working_config
    
    return False, None

def main():
    print("="*60)
    print("Starting PackyAPI availability polling...")
    print("="*60)
    
    poll_interval = 60  # 每60秒检测一次
    attempt = 0
    
    while True:
        attempt +=1
        success, working_config = test_api_once()
        if success:
            print("\n" + "="*60)
            print("SUCCESS: API is available!")
            print(f"Working config: {working_config}")
            print("="*60)
            break
        print(f"\nWaiting {poll_interval} seconds...")
        time.sleep(poll_interval)

if __name__ == "__main__":
    main()
