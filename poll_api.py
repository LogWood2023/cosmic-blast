
import time
import subprocess
import sys
from datetime import datetime

print("=" * 60)
print("开始轮询检测 PackyAPI 可用性...")
print("=" * 60)

attempt = 0
success = False
poll_interval = 30  # 每30秒检测一次

while not success:
    attempt += 1
    print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 尝试检测 API (第 {attempt} 次)...")
    
    try:
        result = subprocess.run(
            [
                sys.executable,
                ".trae/skills/game-asset-generator/pipeline.py",
                "--config",
                ".trae/skills/game-asset-generator/examples/test_api.yaml",
                "--pixel-clean",
                "--max-retries",
                "1"
            ],
            capture_output=True,
            text=True,
            timeout=120
        )
        
        if "成功: 1" in result.stdout:
            print("✅ API 检测成功！")
            success = True
            break
        else:
            print(f"❌ API 检测失败，输出:\n{result.stdout}\n{result.stderr}")
            print(f"⏳ 等待 {poll_interval} 秒后重试...")
            time.sleep(poll_interval)
            
    except subprocess.TimeoutExpired:
        print("❌ 检测超时（2分钟），继续等待...")
        time.sleep(poll_interval)
    except Exception as e:
        print(f"❌ 检测过程出错: {e}")
        time.sleep(poll_interval)

print("\n" + "=" * 60)
print("✅ API 已恢复可用！现在可以生成太空漂浮物素材了！")
print("=" * 60)
