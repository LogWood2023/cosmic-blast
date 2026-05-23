
#!/usr/bin/env python3
import os
from PIL import Image
from io import BytesIO
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".trae", "skills", "game-asset-generator"))
from postprocess.processor import PostProcessor

def has_transparent_background(image_path):
    """检查图片是否有透明背景"""
    try:
        img = Image.open(image_path)
        if img.mode != 'RGBA':
            return False
        
        # 检查边缘像素，如果大部分是透明的，则认为有透明背景
        w, h = img.size
        edge_pixels = []
        
        # 检查顶部边缘
        for x in range(w):
            edge_pixels.append(img.getpixel((x, 0)))
        
        # 检查底部边缘
        for x in range(w):
            edge_pixels.append(img.getpixel((x, h-1)))
        
        # 检查左侧边缘
        for y in range(h):
            edge_pixels.append(img.getpixel((0, y)))
        
        # 检查右侧边缘
        for y in range(h):
            edge_pixels.append(img.getpixel((w-1, y)))
        
        # 统计透明像素数量
        transparent_count = sum(1 for p in edge_pixels if p[3] < 128)
        total_count = len(edge_pixels)
        
        # 如果超过 30% 的边缘像素是透明的，认为有透明背景
        return transparent_count / total_count > 0.3
    except Exception as e:
        print(f"    检查图片失败: {e}")
        return False

def process_image(image_path, processor):
    """使用 rembg 去除图片背景"""
    try:
        with open(image_path, 'rb') as f:
            image_data = f.read()
        
        # 去除背景
        processed_data = processor.remove_background(image_data)
        
        # 保存
        with open(image_path, 'wb') as f:
            f.write(processed_data)
        
        return True
    except Exception as e:
        print(f"    处理图片失败: {e}")
        return False

def main():
    print("="*60)
    print("检查并抠图工具")
    print("="*60)
    
    assets_dir = os.path.join(os.path.dirname(__file__), "generated_assets", "space_floating_objects", "props")
    
    if not os.path.exists(assets_dir):
        print(f"错误: 素材目录不存在: {assets_dir}")
        return
    
    # 初始化 rembg
    processor = PostProcessor()
    print("\n[初始化] 正在初始化 rembg 抠图模型 (u2netp)...")
    processor.init_cutout(model="u2netp")
    print("[初始化] 抠图模型已就绪！\n")
    
    # 遍历所有素材文件夹
    total_checked = 0
    total_processed = 0
    total_failed = 0
    
    for category in os.listdir(assets_dir):
        category_dir = os.path.join(assets_dir, category)
        if not os.path.isdir(category_dir):
            continue
        
        print(f"[{category}]")
        
        for filename in os.listdir(category_dir):
            if not filename.lower().endswith('.png'):
                continue
            if filename.lower().endswith('.import'):
                continue
            
            file_path = os.path.join(category_dir, filename)
            total_checked += 1
            
            print(f"  检查: {filename}...", end=" ", flush=True)
            
            if has_transparent_background(file_path):
                print("已有透明背景，跳过")
            else:
                print("没有透明背景，开始抠图...")
                success = process_image(file_path, processor)
                if success:
                    print(f"    抠图完成: {filename}")
                    total_processed += 1
                else:
                    total_failed += 1
    
    print("\n" + "="*60)
    print(f"总结:")
    print(f"  检查总数: {total_checked}")
    print(f"  已抠图: {total_processed}")
    print(f"  失败: {total_failed}")
    print(f"  无需处理: {total_checked - total_processed - total_failed}")
    print("="*60)

if __name__ == "__main__":
    main()
