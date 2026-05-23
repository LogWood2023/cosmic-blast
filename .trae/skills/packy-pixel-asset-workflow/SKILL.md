---
name: "packy-pixel-asset-workflow"
description: "Runs a portable PackyAPI gpt-image-2 pixel-asset workflow. Invoke when generating, pixel-cleaning, cutout, or diagnosing game asset batches."
---

# Packy Pixel Asset Workflow

这是一个精简可移植版技能，用于在任意项目中复用 PackyAPI `gpt-image-2` 像素游戏素材生成流程。

## 复制到新项目时需要带上的文件

推荐把下面这个目录整体复制到新项目：

```text
.trae/skills/packy-pixel-asset-workflow/
```

如果要真正运行生成脚本，还需要同时复制完整生成器目录：

```text
.trae/skills/game-asset-generator/
```

最小运行依赖文件包括：

```text
.trae/skills/game-asset-generator/pipeline.py
.trae/skills/game-asset-generator/config_schema.py
.trae/skills/game-asset-generator/asset_manager.py
.trae/skills/game-asset-generator/style_seed.py
.trae/skills/game-asset-generator/generators/
.trae/skills/game-asset-generator/postprocess/
.trae/skills/game-asset-generator/requirements.txt
```

## 环境变量

在新项目根目录创建 `.env`：

```env
PACKY_API_KEY=你的PackyAPI密钥
```

不要把真实 key 写进技能文件。复制技能时只复制变量名和说明。

默认接口：

```text
https://www.packyapi.com
```

默认模型：

```text
gpt-image-2
```

## 安装依赖

在项目根目录运行：

```powershell
pip install -r .trae\skills\game-asset-generator\requirements.txt
```

## 最小生成命令

```powershell
python .trae\skills\game-asset-generator\pipeline.py -c .trae\skills\packy-pixel-asset-workflow\examples\asset_batch.yaml --pixel-clean --cutout --cutout-model u2netp
```

## 只预览 Prompt

```powershell
python .trae\skills\game-asset-generator\pipeline.py -c .trae\skills\packy-pixel-asset-workflow\examples\asset_batch.yaml --dry-run
```

## 推荐流程

1. 修改 `examples/asset_batch.yaml`
2. 先执行 `--dry-run`
3. 确认 `PACKY_API_KEY` 可用
4. 执行生成命令
5. 检查输出目录
6. 如果背景没抠干净，再用 `--cutout-model birefnet-general` 重试

## 输出目录

由 YAML 中的 `output_dir` 决定，建议统一使用：

```text
./generated_assets/<asset_batch_name>
```

生成完成后会包含：

```text
_generation_log.json
props/
backgrounds/
icons/
```

具体目录取决于素材的 `type`。

## YAML 最小结构

```yaml
project: 示例像素素材
output_dir: ./generated_assets/example_assets
style:
  art_style: pixel art, 16-bit SNES era, crisp square pixels, limited color palette, retro game sprite aesthetic
  quality: high
size: 1024x1024
n: 1
pixel_clean:
  enabled: true
  target_size: 128
  num_colors: 24
  contrast: 1.2
assets:
  - name: 示例道具
    type: prop
    variants:
      - count: 1
        description: colorful sci-fi crate, centered game prop, clean silhouette, pixel art
```

## 常用素材类型

```text
prop        -> props
background  -> backgrounds
icon        -> icons
ui          -> ui
character   -> characters
```

## 推荐 Prompt 关键词

生成像素游戏素材时，优先加入：

```text
pixel art, 16-bit SNES era, crisp square pixels, limited color palette (16-32 colors), retro game sprite aesthetic, centered composition, clean readable silhouette, game asset
```

如果需要透明素材，Prompt 中可以加入：

```text
single isolated object, simple plain background, no text, no UI
```

最终透明背景由 `--cutout` 完成。

## 常用命令

### 生成并抠图

```powershell
python .trae\skills\game-asset-generator\pipeline.py -c .trae\skills\packy-pixel-asset-workflow\examples\asset_batch.yaml --pixel-clean --cutout --cutout-model u2netp
```

### 更强抠图模型

```powershell
python .trae\skills\game-asset-generator\pipeline.py -c .trae\skills\packy-pixel-asset-workflow\examples\asset_batch.yaml --pixel-clean --cutout --cutout-model birefnet-general
```

### 指定 PackyAPI base_url

```powershell
python .trae\skills\game-asset-generator\pipeline.py -c .trae\skills\packy-pixel-asset-workflow\examples\asset_batch.yaml --pixel-clean --cutout --base-url "https://www.packyapi.com"
```

## 故障排查

### 报 PACKY_API_KEY 未设置

确认新项目根目录有 `.env`：

```env
PACKY_API_KEY=你的PackyAPI密钥
```

### 报 sora 分组无可用渠道

说明 PackyAPI 服务端当前模型渠道不可用。处理方式：

1. 等待 PackyAPI 恢复
2. 去控制台确认 `gpt-image-2` 是否可用
3. 尝试其它可用分组或 base_url

### 背景未抠干净

优先重试：

```powershell
--cutout-model birefnet-general
```

### 像素感不够

降低 YAML 中的：

```yaml
pixel_clean:
  target_size: 96
  num_colors: 16
```

### 主体被抠坏

尝试：

```powershell
--cutout-model u2netp
```

并在 Prompt 里强调：

```text
single isolated object, strong outline, clear silhouette
```

## 复制后快速检查清单

- `.env` 中有 `PACKY_API_KEY`
- `game-asset-generator` 完整存在
- `requirements.txt` 已安装
- YAML 的 `output_dir` 指向新项目中的目标路径
- YAML 的 `size` 使用 PackyAPI 支持的尺寸，例如 `1024x1024`
- 先 dry-run，再正式生成
