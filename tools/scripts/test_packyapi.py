
#!/usr/bin/env python3
import sys
import os
import time
from dotenv import load_dotenv

# 加载 .env 文件
load_dotenv()

# 导入 PackyAPIGenerator
sys.path.insert(0, os.path.join(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")), ".trae", "skills", "game-asset-generator"))

from generators.packyapi_gen import PackyAPIGenerator
from generators.base import GenerationRequest

# 定义要测试的配置列表
test_configs = [
    # 尝试默认分组
    {"base_url": "https://www.packyapi.com", "model": "gpt-image-2", "name": "default - gpt-image-2"},
    {"base_url": "https://www.packyapi.com", "model": "gpt-image-2-c", "name": "default - gpt-image-2-c"},
    {"base_url": "https://www.packyapi.com", "model": "dall-e-3", "name": "default - dall-e-3"},
    {"base_url": "https://www.packyapi.com", "model": "default/dall-e-3", "name": "default - default/dall-e-3"},
    
    # 尝试不同分组的 base_url
    {"base_url": "https://www.packyapi.com/v1/default", "model": "gpt-image-2", "name": "default group - gpt-image-2"},
    {"base_url": "https://www.packyapi.com/v1/default", "model": "dall-e-3", "name": "default group - dall-e-3"},
    
    {"base_url": "https://www.packyapi.com/v1/cc", "model": "gpt-image-2", "name": "cc group - gpt-image-2"},
    {"base_url": "https://www.packyapi.com/v1/codex", "model": "gpt-image-2", "name": "codex group - gpt-image-2"},
    {"base_url": "https://www.packyapi.com/v1/azure", "model": "gpt-image-2", "name": "azure group - gpt-image-2"},
    
    # 尝试不带自动添加 /v1 的方式（直接使用正确的 base_url）
    {"base_url": "https://www.packyapi.com/v1", "model": "gpt-image-2", "name": "raw v1 - gpt-image-2"},
    {"base_url": "https://www.packyapi.com/v1", "model": "dall-e-3", "name": "raw v1 - dall-e-3"},
]

def test_config(base_url: str, model: str, name: str):
    print(f"\n{'='*60}")
    print(f"Testing: {name}")
    print(f"  base_url: {base_url}")
    print(f"  model: {model}")
    print(f"{'='*60}")
    
    try:
        api_key = os.getenv("PACKY_API_KEY")
        
        # 创建生成器时直接传入 base_url
        generator = PackyAPIGenerator(api_key=api_key, base_url=base_url, default_model=model)
        
        request = GenerationRequest(
            prompt="simple pixel art test item on bright green background",
            n=1,
            size="512x512",
            model=model
        )
        
        result = generator.generate(request, max_retries=1)
        
        if result.success:
            print(f"\nSUCCESS! Working config found!")
            print(f"   base_url: {base_url}")
            print(f"   model: {model}")
            print(f"   name: {name}")
            return True, {"base_url": base_url, "model": model, "name": name}
        else:
            print(f"\nFAILED: {result.error_message}")
            return False, None
            
    except Exception as e:
        print(f"\nERROR: {e}")
        import traceback
        traceback.print_exc()
        return False, None

def main():
    print(f"\n{'='*60}")
    print("PackyAPI multi-config test script")
    print(f"{'='*60}")
    
    for i, config in enumerate(test_configs):
        print(f"\n--- Testing {i+1}/{len(test_configs)} ---")
        
        success, working_config = test_config(
            config["base_url"], 
            config["model"], 
            config["name"]
        )
        
        if success:
            print(f"\n{'='*60}")
            print("Found working config!")
            print(f"{'='*60}")
            print(f"base_url: {working_config['base_url']}")
            print(f"model: {working_config['model']}")
            print(f"name: {working_config['name']}")
            print(f"\nYou can use this config to continue generating assets!")
            return
        
        # 避免请求太快
        if i < len(test_configs) - 1:
            time.sleep(3)
    
    print(f"\n{'='*60}")
    print("All configs failed")
    print(f"{'='*60}")
    print("\nMaybe PackyAPI service is temporarily unavailable, or you need to:")
    print("1. Check PackyAPI Console's Model Square")
    print("2. Verify API key balance")
    print("3. Wait and retry later")
    print("4. Contact PackyAPI support or check status page")

if __name__ == "__main__":
    main()
