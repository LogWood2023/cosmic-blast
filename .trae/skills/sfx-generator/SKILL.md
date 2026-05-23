---
name: "sfx-generator"
description: "AI sound effects generation pipeline using Hugging Face text-to-audio models. Invoke when user asks to generate sound effects, SFX, or game audio."
---

# AI 音效生成管线 (SFX Generator)

基于 Hugging Face 线上 text-to-audio 模型与本地 procedural 合成器，批量生成游戏音效。管线默认使用 `auto` 后端：优先尝试 Hugging Face 线上模型，不可用时自动 fallback 到本地程序化合成。

## 何时使用

**在用户请求以下内容时必须调用：**
- "生成音效" / "generate sound effects" / "generate SFX"
- "AI 做音效" / "AI audio"
- 需要为游戏批量生成武器、爆炸、UI 等音效

## 前置条件

### 1. 安装依赖

```powershell
pip install -r .trae/skills/sfx-generator/requirements.txt
```

### 2. 设置 Hugging Face Token

在项目根目录 `.env` 中添加：

```
HF_TOKEN=hf_your_huggingface_token_here
```

或在命令行中通过 `--hf-token` 参数传入。

获取 Token: https://huggingface.co/settings/tokens

## 使用方式

### 预览配置（不调用 API）

```powershell
python .trae/skills/sfx-generator/pipeline.py -c .trae/skills/sfx-generator/examples/sfx.yaml --dry-run
```

### 实际生成（自动后端）

默认 `--backend auto`：优先 Hugging Face，失败后本地 procedural 合成。

```powershell
python .trae/skills/sfx-generator/pipeline.py -c .trae/skills/sfx-generator/examples/sfx.yaml
```

### 离线本地生成（无需 Hugging Face / Token / 网络）

```powershell
python .trae/skills/sfx-generator/pipeline.py -c .trae/skills/sfx-generator/examples/sfx.yaml --backend procedural
```

### 使用不同模型或自动策略

默认不需要手动指定模型，管线会自动按类别选择模型链。

```powershell
python .trae/skills/sfx-generator/pipeline.py -c .trae/skills/sfx-generator/examples/sfx.yaml --model auto
```

如果需要强制使用某个线上模型：

```powershell
python .trae/skills/sfx-generator/pipeline.py -c .trae/skills/sfx-generator/examples/sfx.yaml --model facebook/audiogen-medium
```

### 自定义配置

```powershell
python .trae/skills/sfx-generator/pipeline.py -c my_sfx.yaml --hf-token hf_xxx --max-retries 5
```

## 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-c, --config` | **必填** YAML 配置文件路径 | - |
| `--dry-run` | 预览模式，不调用 API | false |
| `--max-retries` | API 调用失败重试次数 | 3 |
| `--hf-token` | HuggingFace Token | 从环境变量读取 |
| `--backend` | 生成后端：`auto` / `hf` / `procedural` | auto |
| `--model` | 覆盖 Hugging Face 模型选择；`auto` 表示按类别自动选择并 fallback | auto |

## YAML 配置格式

```yaml
project: "我的游戏_SFX"
output_dir: "assets/audio"           # Godot 项目音频目录

style:
  audio_style: "game sound effect, clean, high quality"
  quality: "professional foley, crisp, punchy"

assets:
  - name: "shoot"                    # 输出文件名（不含扩展名）
    category: "weapon"               # 类别: weapon/impact/explosion/environment/ui/voice/vehicle/creature/ambient/other
    model: "auto"                    # 可选，默认 auto；也可指定 facebook/audiogen-medium 等
    loop_mode: 0                     # Godot 循环模式 (0=不循环)
    variants:
      - description: "A single laser gun shot, sci-fi blaster"
        count: 3                     # 生成数量
        duration: 2.0                # 时长（秒）
```

### 音效类别

| 类别 | 说明 | 自动附加的提示词 |
|------|------|------------------|
| `weapon` | 武器 | "weapon sound effect, gunshot, laser" |
| `impact` | 受击/碰撞 | "impact sound effect, hit, collision" |
| `explosion` | 爆炸 | "explosion sound effect, blast, boom" |
| `environment` | 环境音 | "environmental sound effect, ambient" |
| `ui` | UI 音效 | "UI sound effect, interface, click" |
| `voice` | 人声 | "voice sound, vocal, speech" |
| `vehicle` | 载具 | "vehicle sound effect, engine, motor" |
| `creature` | 生物 | "creature sound effect, monster, animal" |
| `ambient` | 氛围 | "ambient sound, atmosphere, background" |
| `other` | 其他 | "sound effect, foley" |

## 输出

- **音频文件**: WAV 格式，输出到 `assets/audio/` 目录
- **导入文件**: 自动生成 Godot 4 `.import` 文件
- **生成日志**: `assets/audio/_sfx_generation_log.json`

生成后在 Godot 编辑器中刷新项目即可使用新音效。

## 推荐线上模型

| 模型 | 推荐用途 | 说明 |
|------|----------|------|
| `facebook/audiogen-medium` | 武器、爆炸、碰撞、生物、机械 | AudioGen 更偏真实音效，作为多数 SFX 类别首选 |
| `declare-lab/tango2` | 复杂 text-to-audio 描述 | Tango 2 适合较复杂的声音组合描述 |
| `declare-lab/tango-full-ft-audiocaps` | 自然声/人工声/AudioCaps 风格音效 | AudioCaps 微调版，适合常见现实声效 |
| `cvssp/audioldm2` | 环境声、氛围、人声、真实音效 | AudioLDM2 可生成声效、人声和音乐 |
| `facebook/musicgen-small` | 兜底备用 | 在线可用性较好，但更偏音乐，不作为音效首选 |

默认 `auto` 策略会按类别生成模型链，例如爆炸音效优先尝试 `facebook/audiogen-medium`，失败后自动尝试 `cvssp/audioldm2`、Tango 系列和 MusicGen 备用模型。

## 管线架构

```
sfx-generator/
├── SKILL.md                 # 本文档
├── requirements.txt         # Python 依赖
├── pipeline.py              # 主管线脚本 (命令行入口)
├── config_schema.py         # YAML 配置数据模型 + prompt 构建
├── model_registry.py        # Hugging Face 线上模型推荐表 + auto fallback 策略
├── sfx_manager.py           # 音频文件管理 + Godot .import 生成
├── generators/
│   ├── __init__.py
│   ├── base.py              # 生成器抽象基类
│   ├── huggingface_gen.py   # Hugging Face Inference API 生成器
│   └── procedural_gen.py    # 本地程序化音效合成器，无需网络/Token
└── examples/
    └── sfx.yaml              # 示例配置
```
