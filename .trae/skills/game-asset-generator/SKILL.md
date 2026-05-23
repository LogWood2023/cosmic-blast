---
name: "game-asset-generator"
description: "Generates and post-processes pixel-art game assets with PackyAPI gpt-image-2. Invoke when you need batch asset generation, cutout, pixel cleaning, or PackyAPI workflow setup."
---

# Game Asset Generator

这个技能用于批量生成像素风游戏素材，并完成像素清理、抠图、日志记录、风格锁定和输出整理。

## 适用场景

在以下场景使用本技能：

- 生成像素风游戏素材、道具、背景、图标、碎片、炮塔部件、陨石、漂浮物等
- 需要使用 PackyAPI 的 `gpt-image-2` 模型批量出图
- 需要对生成结果做像素清理、抠图或透明 PNG 处理
- 需要根据 YAML 配置批量生成多变体素材
- 需要检查 PackyAPI 的 sora 分组或其它分组是否恢复
- 需要把一套工作流整理成可复制、可复用的生成流程

## 项目结构

核心文件位于：

- [pipeline.py](file:///e:/GoDot%20Project/%E6%89%93%E9%A3%9E%E6%9C%BA%E6%B8%B8%E6%88%8F/.trae/skills/game-asset-generator/pipeline.py)
- [asset_manager.py](file:///e:/GoDot%20Project/%E6%89%93%E9%A3%9E%E6%9C%BA%E6%B8%B8%E6%88%8F/.trae/skills/game-asset-generator/asset_manager.py)
- [packyapi_gen.py](file:///e:/GoDot%20Project/%E6%89%93%E9%A3%9E%E6%9C%BA%E6%B8%B8%E6%88%8F/.trae/skills/game-asset-generator/generators/packyapi_gen.py)
- [processor.py](file:///e:/GoDot%20Project/%E6%89%93%E9%A3%9E%E6%9C%BA%E6%B8%B8%E6%88%8F/.trae/skills/game-asset-generator/postprocess/processor.py)
- [config_schema.py](file:///e:/GoDot%20Project/%E6%89%93%E9%A3%9E%E6%9C%BA%E6%B8%B8%E6%88%8F/.trae/skills/game-asset-generator/config_schema.py)
- 示例配置目录：[examples](file:///e:/GoDot%20Project/%E6%89%93%E9%A3%9E%E6%9C%BA%E6%B8%B8%E6%88%8F/.trae/skills/game-asset-generator/examples)

## 必备环境

### 1. Python 依赖

在技能目录下安装依赖：

```powershell
pip install -r .trae\skills\game-asset-generator\requirements.txt
```

如果你在项目根目录运行，也可以直接使用技能目录中的脚本。

### 2. API Key

必须配置 PackyAPI 密钥。

推荐放在项目根目录的 `.env` 文件中：

```env
PACKY_API_KEY=你的PackyAPI密钥
```

说明：

- 只保存环境变量名，不要把真实密钥写进技能文件
- 运行时优先读取 `--api-key`，其次读取 `PACKY_API_KEY`
- 如果需要更换账号，只需替换 `.env` 中的值

### 3. PackyAPI base_url

默认：

```text
https://www.packyapi.com
```

如果服务端要求指定分组，可尝试：

```text
https://www.packyapi.com/v1
https://www.packyapi.com/v1/sora
```

实际可用分组以 PackyAPI 控制台为准。

## 标准工作流

### A. 编写配置文件

所有素材通过 YAML 配置驱动。常见示例可参考 [examples](file:///e:/GoDot%20Project/%E6%89%93%E9%A3%9E%E6%9C%BA%E6%B8%B8%E6%88%8F/.trae/skills/game-asset-generator/examples)。

配置里通常包含：

- project
- output_dir
- style
- style_seed
- pixel_clean
- assets

### B. 先预览

先确认 prompt 拼接是否正确：

```powershell
python .trae\skills\game-asset-generator\pipeline.py -c .trae\skills\game-asset-generator\examples\space_floating_objects.yaml --dry-run
```

### C. 正式生成

常规生成命令：

```powershell
python .trae\skills\game-asset-generator\pipeline.py -c .trae\skills\game-asset-generator\examples\space_floating_objects.yaml --pixel-clean --cutout
```

推荐参数：

- `--pixel-clean`：启用降采样、色板量化、近邻放大
- `--cutout`：启用 rembg 抠图
- `--cutout-model u2netp`：默认通用抠图模型
- `--max-retries 3`：失败自动重试

### D. 输出结果

默认输出到配置文件指定的目录，例如：

- `generated_assets/<project>/`

每个素材通常包含：

- 原始 PNG
- 抠图后 PNG
- 生成日志 `_generation_log.json`

### E. 检查抠图结果

如果用户要求检查是否真的抠图，运行：

```powershell
python check_and_cutout.py
```

这个脚本会：

- 遍历 `generated_assets/space_floating_objects/props`
- 检查图片边缘是否透明
- 对未抠图的图片使用 rembg 重新处理
- 统计已处理、失败、无需处理的数量

## 现有辅助脚本

### 1. PackyAPI 可用性诊断

当 sora 分组或 gpt-image-2 模型不可用时，用来诊断：

```powershell
python diagnose_sora.py
```

用途：

- 测试不同 base_url 和 model 组合
- 判断 sora 分组是否恢复
- 识别 503、model_not_found、无可用渠道等错误

### 2. PackyAPI 轮询脚本

当需要持续等待服务恢复时：

```powershell
python poll_packyapi.py
```

用途：

- 每隔一段时间检查 PackyAPI 是否恢复
- 一旦可用就自动结束并提示继续生成

### 3. 单次连通性测试

如果你只想快速确认是否能生成：

```powershell
python test_just_sora.py
```

## 当前实现特点

### 1. 路径与文件名安全

`asset_manager.py` 已做文件名清理，会自动替换非法字符，避免出现：

- `/`
- `\`
- `:`
- `*`
- `?`
- `"`
- `<`
- `>`
- `|`

因此像“废弃推进器/引擎”这类名称也能安全输出。

### 2. Windows 控制台兼容

`pipeline.py` 已处理 Windows 编码问题，避免中文和特殊字符输出时报错。

### 3. 像素清理流程

`PostProcessor.clean_pixel_art()` 的逻辑是：

- 读取原图
- 可选增强对比度
- 降采样到中间尺寸
- 量化色板
- 再用最近邻放大回原始尺寸

这适合把 AI 图转成更像游戏资源的像素风图。

### 4. 抠图流程

`PostProcessor.init_cutout()` 会初始化 rembg session。

`--cutout` 开启后，流程会：

- 先进行像素清理
- 再执行背景去除
- 最后保存透明 PNG

## 推荐的完整命令组合

### 生成像素素材并抠图

```powershell
python .trae\skills\game-asset-generator\pipeline.py -c .trae\skills\game-asset-generator\examples\space_floating_objects.yaml --pixel-clean --cutout --cutout-model u2netp
```

### 只检查配置

```powershell
python .trae\skills\game-asset-generator\pipeline.py -c .trae\skills\game-asset-generator\examples\space_floating_objects.yaml --dry-run
```

### 检查并补抠图

```powershell
python check_and_cutout.py
```

### 诊断 PackyAPI 状态

```powershell
python diagnose_sora.py
```

### 持续轮询服务恢复

```powershell
python poll_packyapi.py
```

## 生成规范建议

### 像素风提示词

建议加入：

- `pixel art`
- `16-bit SNES era`
- `crisp square pixels`
- `limited color palette (16-32 colors)`
- `retro game sprite aesthetic`
- `clean readable silhouette`
- `centered composition`

### 游戏素材目标

适合本工作流的素材类型：

- 瓦片地图素材
- 宇宙背景
- 宇宙残骸隔离带
- 存储箱
- 水晶
- Icon
- 碎片
- 炮塔底座
- 炮管
- 陨石
- 避雷针
- 太空漂浮物

## 故障排查

### 1. PackyAPI 报“分组无可用渠道”

处理步骤：

1. 检查 PackyAPI 控制台
2. 确认 sora 分组是否恢复
3. 尝试其他 base_url 或分组
4. 用 `diagnose_sora.py` 做快速诊断
5. 必要时用 `poll_packyapi.py` 持续轮询

### 2. 图片过小或主体丢失

处理步骤：

- 提高 prompt 中主体描述清晰度
- 保持单个主体居中
- 使用 `--pixel-clean` 但不要过度压缩色板
- 对需要抠图的图启用 `--cutout`

### 3. 生成文件名异常

已通过 `sanitize_filename()` 修复。若新素材名仍有特殊字符，工具会自动替换。

### 4. 抠图后主体受损

处理步骤：

- 尝试不同 rembg 模型
- 当前默认推荐 `u2netp`
- 如需更高质量，可尝试 `birefnet-general`

## 使用建议

当用户要求“继续生成素材”时，优先按这个顺序执行：

1. 读取配置
2. dry-run 预览
3. 确认 PackyAPI 可用
4. 执行生成
5. 像素清理
6. 抠图
7. 检查输出目录
8. 回传生成路径

## 输出路径约定

建议把最终素材统一保存在：

- `generated_assets/<项目名>/`

如果需要给用户展示路径，优先返回完整可访问路径，并按类别分目录说明。

## 说明

这个技能已经将当前工作流整理成可复制、可复用的形式。

如果你复制整个技能目录，至少要保留：

- `SKILL.md`
- `pipeline.py`
- `asset_manager.py`
- `generators/packyapi_gen.py`
- `postprocess/processor.py`
- `config_schema.py`
- `examples/`

如果你要在新环境中直接运行，还要提供：

- `PACKY_API_KEY`
- Python 依赖
- 可用的 PackyAPI 分组/模型
