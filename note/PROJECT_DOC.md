# 高能宇宙大爆炸 —— 项目概述文档

> Godot 4.6 · 2D 弹幕射击 · 960×720 · Windows
> 文档版本：v2.23 · 生成时间：2026-05-13

---

## 一、项目概述

一款纵向卷轴 2D 弹幕射击游戏（STG），玩家操控星际战机对抗宇宙敌军及巨型 Boss。支持正常关卡模式和 Boss 挑战模式（当前共 13 个 Boss）。

### 核心参数

| 项目 | 值 |
|------|-----|
| 引擎 | Godot 4.6 (Forward+) |
| 主场景 | `MainMenu.tscn` |
| 分辨率 | 960 × 720 |
| 渲染驱动 | D3D12 |
| 物理引擎 | Jolt |
| 自动加载 | `GameManager.gd` |

### 输入映射

| 动作 | 按键 |
|------|------|
| 移动 | WASD / 方向键 |
| 射击 | 鼠标左键（按住连射） |

---

## 二、目录结构

```
打飞机游戏/
├── project.godot              # 引擎配置
├── PROJECT_DOC.md              # 本文档
├── METHOD_REFERENCE.md         # 方法参考（代码级 API 文档）
├── HANDOVER.md                 # 完整交接文档
├── FEATURE_REFERENCE.md        # 功能实现参考手册
├── BOSS_DESIGN_SPEC.md         # Boss 设计规范
├── scripts/                    # GDScript 脚本
│   ├── GameManager.gd          # 全局状态（Autoload）
│   ├── Player.gd               # 玩家控制
│   ├── BaseEnemy.gd            # 敌人基类（9 种子类）
│   ├── Bullet.gd/EnemyBullet.gd/Bomb.gd/PowerUp.gd  # 弹幕/道具
│   ├── BossBase.gd             # Boss 组件基类
│   ├── StarColossusController.gd     # 星间巨构主控（999行）
│   ├── StarColossusBody.gd/Arm.gd   # 星间巨构部件
│   ├── StarColossusFrontier.gd      # 亚种：星海前锋
│   ├── StarColossusHeavy.gd         # 亚种：星尘重兵
│   ├── StarColossusNebula.gd        # 亚种：星云巨构
│   ├── ParadiseController.gd        # 天堂号主控（1337行）
│   ├── ParadiseCannon.gd            # 天堂号机炮组件
│   ├── ParadisePeachBlossom.gd      # 亚种：桃源乡
│   ├── ParadiseUtopia.gd            # 亚种：乌托邦
│   ├── ParadiseEden.gd              # 亚种：伊甸园
│   ├── WarpedCoreController.gd     # 扭曲星核主控（1689行）
│   ├── VariantSource.gd            # 亚种：异变源石
│   ├── VariantSpore.gd             # 亚种：诡异菌孢
│   ├── VariantAnti.gd              # 亚种：反物质核
│   ├── HellEyeController.gd        # ★NEW★ 地狱之眼主控（334行）
│   ├── BossSelect.gd               # Boss 选择界面
│   ├── BossHUD.gd/HUD.gd           # UI 系统
│   ├── Explosion.gd/Debris.gd      # 特效/碎片
│   └── ScrollingBackground.gd      # 星空卷动背景
├── scenes/                    # 场景文件 (.tscn)
│   ├── MainMenu.tscn          # 主菜单
│   ├── BossSelect.tscn        # Boss 选择
│   ├── Main.tscn              # 正常关卡
│   ├── BossBattle*.tscn       # 13 个 Boss 战斗场景
│   ├── StarColossus*.tscn     # 4 个星间巨构系场景
│   ├── Paradise*.tscn         # 4 个天堂号系场景
│   ├── WarpedCore.tscn + Variant*.tscn  # 4 个扭曲星核系场景
│   ├── HellEye.tscn           # ★NEW★ 地狱之眼场景
│   └── BossBattle_HellEye.tscn# ★NEW★ 地狱之眼战斗场景
└── assets/
    ├── images/
    │   ├── boss/              # Boss 贴图
    │   ├── enemy/              # 敌人贴图
    │   ├── fx/                 # 特效
    │   ├── paradise/           # 天堂号/亚种材质
    │   ├── player/             # 玩家
    │   ├── powerup/            # 道具
    │   ├── warpedcore/         # 扭曲星核/亚种材质
    │   └── helleye/            # ★NEW★ 地狱之眼材质+Shader
    └── audio/
        ├── bgm.mp3             # 普通关卡 BGM
        ├── colossus_bgm.mp3    # 星间巨构 BGM
        ├── paradise_bgm.mp3    # 天堂号 BGM
        ├── warpedcore_bgm.mp3  # 扭曲星核 BGM
        ├── hell_eye_boss_bgm.mp3  # ★NEW★ 地狱之眼 BGM
        └── *.wav              # 10 个音效文件
```

---

## 三、核心系统

### 3.1 GameManager（自动加载单例）

```gdscript
score: int           # 得分
player_hp: int       # 玩家 HP（最大 100）
elapsed: float       # 游戏计时
difficulty()         # 返回 0~1，基于 elapsed/180s
bgm_player           # 循环 BGM，Boss 出场时暂停
```

### 3.2 玩家 (Player.gd)

- **移动**：WASD，300px/s，限制屏幕内
- **瞄准**：射击时朝鼠标方向旋转
- **射击**：按住左键 0.25s/发
- **受伤**：三种方式：
  - `take_damage_from(area)`：通用敌人碰撞
  - `take_damage_from_boss(dmg)`：Boss 技能伤害
  - `take_knockback_damage(dmg, speed, duration)`：Boss 碰撞击飞
- **无敌**：受伤后 1s 闪烁，击飞时额外 0.7s
- **碰撞层**：layer=1（玩家），mask=2（检测Boss）

### 3.3 敌人系统 (BaseEnemy.gd)

所有敌人继承自 `BaseEnemy`（Area2D），使用状态机：

```
WARNING(2s) → MOVING → COOLDOWN → WARNING → ... → LEAVING
```

9 种子类敌人：Shooter（射击机）、Rammer（碰撞机）、Bomber（轰炸机）、Scatter（散射机）、Suicide（自爆机）、Healer（治疗机）、Chain（连射机）、Missile（导弹机）、Thrower（抛投机）

### 3.4 碰撞层级

| 层 | 归属 |
|----|------|
| 1 | 玩家、玩家子弹 |
| 2 | Boss 部件 |

玩家 mask=2 检测 Boss，Boss mask=1 检测玩家。

---

## 四、Boss 系统总览

### 4.1 四大家族（13 个 Boss）

| 家族 | 族长 | 亚种数 | 脚本行数 | 特点 |
|------|------|--------|---------|------|
| **星间巨构** | 星间巨构 | 3 | ~999 | 双臂身体 + 6技能 |
| **天堂号** | 天堂号 | 3 | ~1337 | 4机炮 + 停泊位 + 6技能 |
| **扭曲星核** | 扭曲星核 | 3 | ~1689 | 环绕小球 + 布朗运动 + 6技能 |
| **地狱之眼** | 地狱之眼 | 0 | ~334 | ★NEW★ Shader裁剪 + 眼睛动画 |

### 4.2 架构模式

```
[Controller] (Node2D)          ← 技能主控、HP 管理
├── [Body] (Area2D)            ← 身体碰撞体
├── [Part] (Area2D)            ← 部件碰撞体
└── ...更多部件
```

- 所有 Boss 控制器提供统一接口：`boss_hp`, `max_hp`, `boss_name`, `active`, `apply_damage()`
- BossHUD 通过鸭子类型自动发现 Boss
- 技能通过 `has_skill_N` 开关控制，冷却后从已启用技能中随机选取
- 所有 Boss 共享相同的死亡动画模式：5s 爆炸序列 → 2.5s 回主菜单

### 4.3 Boss AI（v2.22 新增）

所有 Boss 共享技能调度 AI：
- 记录 `_last_skill`（上次执行的技能编号）
- 场上敌机数量 ≤ 3 且上次不是技能 3 → 强制释放技能 3（召唤敌机）
- 否则从已启用技能中均匀随机选取

### 4.4 伤害传递链

```
玩家子弹 (atk) → Boss 部件 _on_area_entered()
  → if area.atk != null: controller.apply_damage(area.atk); area.queue_free()

Boss 技能 → player.take_damage_from_boss(dmg) — 直接伤害
Boss 碰撞 → player.take_knockback_damage(20, 1000, 0.5) — 击飞
```

---

## 五、Boss「地狱之眼」★NEW★ (v2.23)

### 5.1 概述

地狱之眼是继承自 `WarpedCoreController` 的特殊 Boss。取消了所有环绕小球和现有技能（待重做），专注于独特的 Shader 裁剪视觉效果和眼睛动画系统。

**脚本：** `scripts/HellEyeController.gd` (334行)  
**材质：** `assets/images/helleye/` 目录  
**BGM：** `assets/audio/hell_eye_boss_bgm.mp3`  
**场景：** `scenes/HellEye.tscn` → `BossBattle_HellEye.tscn`

### 5.2 视觉层级

三层叠加渲染（z_index 从低到高）：

| 层 | 节点 | z_index | 说明 |
|----|------|---------|------|
| 描边 | `_stroke_sprite` | 43 | 黑色抖动轮廓（眼形 mask 贴图），持续形变 |
| 星云 | `_nebula_sprite` | 44 | 红色星云底图，经 `eye_clip.gdshader` 裁剪 |
| 眼珠 | `body_sprite` | 45 | 眼球贴图，经 `eye_clip.gdshader` 裁剪 |

### 5.3 Shader 裁剪系统

**文件：** `assets/images/helleye/eye_clip.gdshader`

核心原理：使用 `mask_alpha.png`（眼形遮罩）的 alpha 通道裁剪星云和眼珠的渲染。

```gdshader
shader_type canvas_item;
uniform sampler2D mask_tex;        // 眼形遮罩贴图
uniform vec2 mask_scale;           // 遮罩缩放（控制眼形大小）
uniform float mask_rotation;       // 遮罩旋转
uniform vec2 mask_offset_uv;       // 遮罩 UV 偏移（眼珠位置偏移用）
uniform vec2 content_scale;        // 内容缩放（独立于遮罩，用于眼球缩放）
uniform vec2 content_offset;       // 内容 UV 偏移（眼球追踪玩家用）

void fragment() {
    // 1. 计算遮罩 UV（旋转+缩放+偏移）
    vec2 centered = UV - 0.5;
    vec2 rotated = ...;
    vec2 scaled = rotated * mask_scale;
    vec2 mask_uv = scaled + 0.5 + mask_offset_uv;
    float mask_a = texture(mask_tex, mask_uv).a;

    // 2. 计算内容 UV（独立 content_scale + offset）
    vec2 tex_uv = (UV - 0.5) * content_scale + 0.5 + content_offset;
    vec4 c = texture(TEXTURE, tex_uv);

    // 3. 用 mask alpha 裁剪 content alpha
    COLOR = vec4(c.rgb, c.a * mask_a);
}
```

`mask_scale` 值越大，遮罩越小（UV 空间中的反向关系）。使用乘法使得数值越大 = 遮罩越小。

### 5.4 眼睛动画状态机

三种主要动作，每种执行后回归正常状态（0.6s 过渡），然后进入下一个动作循环：

| 动作 | 时长 | 遮罩Y缩放 | 眼珠Content缩放 | 其他效果 |
|------|------|-----------|----------------|---------|
| **睁大** (WIDE) | 2.5s | 2.0x | 1.4286x (70%) | 眼珠剧烈颤动（±15px），眼珠追踪玩家 |
| **眯眼** (SQUINT) | 1.8s | 0.3x | 1.0x (正常) | 无 |
| **眨眼** (BLINK) | 0.35s | 0→0.04→1.0 | 1.0x (正常) | 前半段闭合，后半段张开 |
| **正常** (NORMAL) | 0.6s | 1.0x | 1.0x (正常) | 回归过渡 |

循环顺序：WIDE → NORMAL → SQUINT → NORMAL → BLINK → NORMAL → WIDE → ...

### 5.5 呼吸动画（待机）

待机状态下眼睛遮罩 Y 轴缩放呈正弦波呼吸效果：
- 周期：3.0s
- 幅度：75% ~ 125%
- 进场动画结束后开始

### 5.6 进场动画（7 阶段，~6.5s）

| 阶段 | 时间 | 效果 |
|------|------|------|
| 0 | 0-1.5s | 从顶部 (-100px) ease-out 滑入至 `spawn_y_ratio` |
| 0b | 0.5s | BGM 切换 |
| 1 | 1.8-1.9s | 瞪大眼（0.1s 快速扩大到 2.0x）+ 咆哮 SFX + 画面轻颤 |
| 1b | 1.9-2.5s | 保持瞪大 + 轻微颤动 |
| 2 | 2.5-4.5s | 黑幕 2s（boss_name="地狱之眼"）+ 瞪大眼 + 强颤动 |
| 3 | 4.5-5.5s | 黑幕淡出 + 保持瞪大 + 强颤动 |
| 4 | 5.5-6.5s | 黑幕消失 1s 后回归正常 + 停止颤动 |
| 5 | 6.5s+ | 激活战斗 + 呼吸动画启动 + 冷却 0.5s |

### 5.7 描边系统

描边使用 `mask_alpha.png` 作为 `Sprite2D` 显示，颜色可配置（默认黑色）：
- **抖动效果**：位置持续通过多频率 sin/cos 函数偏移（频率 7~19Hz）
- **形变效果**：缩放持续波动（±8%）
- **旋转抖动**：±0.03rad 持续振荡
- **跟随遮罩**：描边的旋转方向与遮罩相反（`-rot`）

### 5.8 检查器暴露参数

所有视觉参数均暴露在 Inspector 中可调：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `mask_scale` | `Vector2` | `(0.18, 0.18)` | 遮罩大小 |
| `mask_rotation_deg` | `float` | `0.0` | 遮罩旋转角度 |
| `nebula_scale` | `Vector2` | `(0.27, 0.27)` | 星云缩放 |
| `nebula_offset` | `Vector2` | `(0, 0)` | 星云偏移 |
| `eyeball_scale` | `Vector2` | `(0.18, 0.18)` | 眼珠缩放 |
| `eyeball_offset` | `Vector2` | `(0, 0)` | 眼珠偏移 |
| `mask_stroke_thickness` | `float` | `3.0` | 描边粗细 |
| `mask_stroke_jitter` | `float` | `1.5` | 描边抖动幅度 |
| `mask_stroke_color` | `Color` | `BLACK` | 描边颜色 |

### 5.9 技能系统

**当前所有 6 个技能均关闭**（`has_skill_1~6 = false`），技能功能待重做。Boss 具备技能框架（继承自 WarpedCoreController），技能功能可随时添加。

---

## 六、情景入口

### MainMenu.tscn → 三个按钮

| 按钮 | 目标 | 描述 |
|------|------|------|
| 开始游戏 | `Main.tscn` | 普通关卡 |
| Boss挑战 | `BossSelect.tscn` | 13 个 Boss 选择 |
| 退出游戏 | 退出 | 关闭游戏 |

### BossSelect 入口（13 个 Boss）

| 按钮 | BossBattle 场景 |
|------|----------------|
| 星间巨构 | `BossBattle.tscn` |
| 星海前锋 | `BossBattle_Frontier.tscn` |
| 星尘重兵 | `BossBattle_Heavy.tscn` |
| 星云巨构 | `BossBattle_Nebula.tscn` |
| 天堂号 | `BossBattle_Paradise.tscn` |
| 桃源乡 | `BossBattle_PeachBlossom.tscn` |
| 乌托邦 | `BossBattle_Utopia.tscn` |
| 伊甸园 | `BossBattle_Eden.tscn` |
| 扭曲星核 | `BossBattle_WarpedCore.tscn` |
| 异变源石 | `BossBattle_Source.tscn` |
| 诡异菌孢 | `BossBattle_Spore.tscn` |
| 反物质核 | `BossBattle_Anti.tscn` |
| ★ 地狱之眼 | `BossBattle_HellEye.tscn` |

---

## 七、开发约定

1. **非侵入式开发**：只增新文件，不改原有项目文件
2. **素材命名**：`xxx_cutout.png` 为透明背景 PNG
3. **Boss 组件在代码中构建**（`_setup_body/_build_parts`），不在场景中预设
4. **路径格式**：Windows 风格
5. **交流语言**：中文，反馈问题时附带完整错误信息 + 堆栈
6. **每次修改后需重启 Godot** 以重载脚本和导入缓存
7. **BossHUD 调整**：只拖动 HBox 和 NamePlate/NameLabel 调整位置，不动子节点

---

## 八、当前进度

| 模块 | 状态 | 备注 |
|------|------|------|
| 玩家系统 | ✅ 完成 | 移动/射击/受伤/无敌/击飞/道具 |
| 9 种敌人 | ✅ 完成 | 全部子类 |
| 敌人生成器 | ✅ 完成 | 难度自适应 |
| 主菜单 + BossSelect + 结算 | ✅ 完成 | 13 Boss 入口 |
| HUD（玩家 + Boss） | ✅ 完成 | 双色闪烁血条 |
| **星间巨构 + 3 亚种** | ✅ 完成 | 4 Boss，6 技能 |
| **天堂号 + 3 亚种** | ✅ 完成 | 4 Boss，6 技能 |
| **扭曲星核 + 3 亚种** | ✅ 完成 | 4 Boss，6 技能 + AI |
| **地狱之眼** | ✅ 完成 | ★NEW★ 1 Boss，视觉+动画完成，技能待重做 |

---

*文档版本：v2.23 · 生成时间：2026-05-13*