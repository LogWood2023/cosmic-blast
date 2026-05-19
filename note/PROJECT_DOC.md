# 高能宇宙大爆炸 —— 项目概述文档

> Godot 4.6 · 2D 弹幕射击 · 960×720 · Windows
> 文档版本：v2.33 · 生成时间：2026-05-18

---

## 一、项目概述

一款纵向卷轴 2D 弹幕射击游戏（STG），玩家操控星际战机对抗宇宙敌军及巨型 Boss。支持正常关卡模式和 Boss 挑战模式（当前共 14 个 Boss）。

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
cosmic-blast/
├── project.godot              # 引擎配置
├── VERSION                    # 版本号 (2.33)
├── README.md                  # 项目说明
├── note/
│   ├── PROJECT_DOC.md         # 本文档
│   ├── METHOD_REFERENCE.md    # 方法参考（代码级 API 文档）
│   ├── HANDOVER.md            # 完整交接文档
│   ├── FEATURE_REFERENCE.md   # 功能实现参考手册
│   └── BOSS_DESIGN_SPEC.md    # Boss 设计规范
├── scripts/                   # GDScript 脚本
│   ├── GameManager.gd         # 全局状态（Autoload）
│   ├── Player.gd              # 玩家控制
│   ├── BaseEnemy.gd           # 敌人基类（9 种子类）
│   ├── DivineMessenger.gd     # ★NEW★ 神明使者主控（~870行）
│   ├── BossBase.gd            # Boss 组件基类
│   ├── StarColossusController.gd     # 星间巨构主控（999行）
│   ├── ParadiseController.gd        # 天堂号主控（1337行）
│   ├── WarpedCoreController.gd     # 扭曲星核主控（1689行）
│   ├── HellEyeController.gd        # 地狱之眼主控（334行）
│   ├── BossSelect.gd               # Boss 选择界面
│   ├── BossHUD.gd/HUD.gd           # UI 系统
│   └── ...
├── scenes/                    # 场景文件 (.tscn)
│   ├── DivineMessenger.tscn   # ★NEW★ 神明使者场景
│   ├── BossBattle_DivineMessenger.tscn  # ★NEW★ 神明使者战斗场景
│   └── ...
└── assets/
    ├── images/
    │   ├── divine_messenger/  # ★NEW★ 神明使者贴图
    │   │   ├── crystal_raw.png / crystal_cutout.png
    │   │   ├── crown_raw.png / crown_cutout.png / crown_v2_raw.png
    │   │   ├── wings_raw.png / wings_cutout.png
    │   │   └── wings_open_raw.png / wings_open_cutout.png
    │   ├── boss/              # Boss 贴图
    │   ├── enemy/              # 敌人贴图
    │   ├── fx/                 # 特效
    │   ├── paradise/           # 天堂号/亚种材质
    │   ├── player/             # 玩家
    │   ├── powerup/            # 道具
    │   ├── warpedcore/         # 扭曲星核/亚种材质
    │   └── helleye/            # 地狱之眼材质+Shader
    └── audio/
        ├── warpedcore_bgm.mp3  # 神明使者 BGM（复用扭曲星核）
        └── ...
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

9 种子类敌人：Shooter、Rammer、Bomber、Scatter、Suicide、Healer、Chain、Missile、Thrower

### 3.4 碰撞层级

| 层 | 归属 |
|----|------|
| 1 | 玩家、玩家子弹 |
| 2 | Boss 部件 |

---

## 四、Boss 系统总览

### 4.1 五大家族（14 个 Boss）

| 家族 | 族长 | 亚种数 | 特点 |
|------|------|--------|------|
| **星间巨构** | 星间巨构 | 3 | 双臂身体 + 6技能 |
| **天堂号** | 天堂号 | 3 | 4机炮 + 停泊位 + 6技能 |
| **扭曲星核** | 扭曲星核 | 3 | 环绕小球 + 布朗运动 + 6技能 |
| **地狱之眼** | 地狱之眼 | 0 | Shader裁剪 + 眼睛动画 |
| **神明使者** ★NEW★ | 神明使者 | 0 | 水晶/王冠/羽翼 + 展翅动画 |

### 4.2 架构模式

```
[Controller] (Node2D)          ← 技能主控、HP 管理
├── [Body] (Area2D)            ← 身体碰撞体
└── ...更多节点
```

### 4.3 Boss AI

- 记录 `_last_skill`（上次执行的技能编号）
- 场上敌机数量 ≤ 3 且上次不是技能 3 → 强制释放技能 3
- 否则从已启用技能中均匀随机选取

---

## 五、Boss「神明使者」★NEW★ (v2.33)

### 5.1 概述

神明使者是全新的 Boss，由三个核心视觉部件组成：水晶（主体）、王冠（头顶）、羽翼（左右各一）。支持翅膀张开/闭合两种配置状态，配置之间可以通过动画循环切换。

**脚本：** `scripts/DivineMessenger.gd` (~870行)  
**材质：** `assets/images/divine_messenger/` 目录  
**BGM：** `assets/audio/warpedcore_bgm.mp3`（复用扭曲星核 BGM）  
**场景：** `scenes/DivineMessenger.tscn` → `BossBattle_DivineMessenger.tscn`

### 5.2 视觉层级（三层合成）

| 层 | 节点 | z_index | 说明 |
|----|------|---------|------|
| 翅膀 | `WingsLeft` / `WingsRight` | 48 | 左右羽翼，可旋转摇晃，含旋转枢轴容器 |
| 水晶 | `Crystal` | 50 | 主体核心，上下浮动 |
| 王冠 | `Crown` | 51 | 顶部装饰，上下浮动 |

### 5.3 翅膀架构

```
DivineMessenger (Node2D)
├── LeftPivotNode (Node2D)           # 左翅膀旋转枢轴
│   ├── WingsLeft (Sprite2D)         # 左翅膀（从双翼材质左半裁剪）
│   └── LeftPivotDot (Sprite2D)      # 旋转中心红点（可显/隐）
├── RightPivotNode (Node2D)          # 右翅膀旋转枢轴
│   ├── WingsRight (Sprite2D)        # 右翅膀（从双翼材质右半裁剪，不翻转）
│   └── RightPivotDot (Sprite2D)     # 旋转中心红点（可显/隐）
├── Crystal (Sprite2D)               # 水晶
├── Crown (Sprite2D)                 # 王冠
└── BodyArea (Area2D)                # 碰撞体（半径100px）
```

- 翅膀材质从双翼纹理正中裁剪为左右两半
- 旋转通过旋转枢轴容器实现，翅膀保持原始朝向（不水平翻转）
- 旋转中心红点通过 `show_pivot_dots` 控制显隐

### 5.4 翅膀配置系统（开/合两套状态）

张开和闭合配置各自保存以下 8 项属性：

| 属性 | 说明 |
|------|------|
| `wings_scale` | 翅膀缩放 |
| `wings_z_index` | 翅膀层级 |
| `wings_shake_angle` | 摇晃角度幅度 |
| `wings_shake_speed` | 摇晃速度 |
| `wing_pivot_left_pos` | 左枢轴位置 |
| `wing_pivot_right_pos` | 右枢轴位置 |
| `wing_left_offset` | 左翅膀相对枢轴的偏移 |
| `wing_right_offset` | 右翅膀相对枢轴的偏移 |

- **注意**：水晶和王冠的位置/缩放/层级不受翅膀配置切换影响，始终跟随 Inspector 中的 `crystal_*` / `crown_*` 参数
- 切换函数：`apply_wings_open_state()` / `apply_wings_closed_state()`
- 保存函数：`save_wings_open_state()` / `save_wings_closed_state()`
- 同步函数：`_sync_all_node_props()` 确保配置切换后节点立即更新

### 5.5 待机动画

- 水晶：正弦波上下浮动（±8px），相位随机
- 王冠：正弦波上下浮动（±8px），相位随机
- 翅膀：正弦波上下浮动（±8px）+ 正弦波旋转摇晃（角度 ±`wings_shake_angle`）
- 三个动画各自的相位和速度均随机，避免同步

### 5.6 展翅/闭翅动画（10阶段完整循环，~5.4s/周期）

**展翅 (Phase 0–4)**：

| 阶段 | 时长 | 缓动 | 描述 |
|------|------|------|------|
| 0 | 0.8s | ease_out ↓50px | 水晶/王冠/翅膀向下50px，左逆10°右顺10° |
| 1 | 0.3s | 停顿 | 峰值停顿 |
| 2 | 0.3s | ease_in ↑100px | 向上100px，左右各反向20°；0.2s切换张开配置 |
| 3 | 2.0s | 维持顶峰 | 最高点停顿，所有效果全开 |
| 4 | 0.5s | ease_out ↓50px | 向下50px回位，效果渐消 |

**闭翅 (Phase 5–7)**：展翅的倒放（4→2→1），无 stage-3 维持。

| 阶段 | 时长 | 缓动 | 描述 |
|------|------|------|------|
| 5 (close_4) | 0.5s | ease_in ↑50px | 反向回升至顶峰 |
| 6 (close_2) | 0.3s | ease_out ↓100px | 向下100px回落，0.1s切换闭合配置 |
| 7 (close_1) | 0.3s | 停顿 | 底部停顿，然后回到阶段0 |

- 缓动函数：`ease_out(t) = 1-(1-t)³`，`ease_in(t) = t³`
- 配置切换时保存绝对视觉状态（位置+旋转），切换后恢复，确保无缝过渡
- **闭翅阶段不触发 shader 描边光源和 Point Light 方向性发光**

### 5.7 翅膀变形效果（阶段2缓入→阶段3维持→阶段4缓出）

| 效果 | 实现 | 阶段2 | 阶段3 | 阶段4 |
|------|------|:--:|:--:|:--:|
| **边缘发光** | `wing_glow.gdshader` HDR shader + WorldEnvironment Glow | 0→1 | 1 | 1→0 |
| **缩放提升** | `wing_scale_boost_mult` (默认1.4x) | 1→1.4 | 1.4 | 1.4→1 |
| **翅膀外扩** | 左右各外移80px + 上移50px | 0→80/50 | 80/50 | 80/50→0 |
| **Point Light** | 枢轴中心径向光晕 sprite | 0→600px | 600px | 600px→0 |

### 5.8 检查器暴露参数

| 分组 | 参数 | 类型 | 默认值 | 说明 |
|------|------|------|--------|------|
| Crystal/Crown | `crystal_scale/pos/z_index` | `Vector2/V2/int` | — | 水晶/王冠配置 |
| — | `overall_scale` | `float` | 1.0 | 整体缩放 |
| Wings Closed State | `wings_closed_*` | 各类型 | — | 闭合翅膀配置(8项) |
| Wings Open State | `wings_open_*` | 各类型 | — | 张开翅膀配置(8项) |
| Wing Glow (HDR) | `wing_glow_size` | `float` | 0.008 | shader发光扩散半径(UV) |
| — | `wing_glow_max_brightness` | `float` | 2.0 | 峰值HDR亮度 |
| — | `wing_glow_spread` | `int` | 5 | 发光扩散圈数(1~10) |
| Wing Scale Boost | `wing_scale_boost_mult` | `float` | 1.4 | 翅膀缩放倍数 |
| Wing Spread | `wing_spread_offset` | `float` | 80.0 | 水平外扩像素 |
| — | `wing_spread_rise` | `float` | 50.0 | 垂直上升像素 |
| Point Lights | `point_light_size` | `float` | 600.0 | 光晕像素直径 |
| — | `point_light_max_brightness` | `float` | 0.5 | 峰值透明度 |
| Other | `show_pivot_dots` | `bool` | false | 显示旋转中心红点 |
| — | `max_hp / spawn_y_ratio` | `int / float` | — | 生命值/出生Y比例 |
| — | `has_skill_1~6` | `bool` | — | 技能开关 |

---

## 六、已知问题 & 待完成

### 6.1 翅膀配置持久化问题 ⚠️

`save_wings_open_state()` / `save_wings_closed_state()` 将当前 Inspector 值复制到独立的 state 变量副本中。但 `_ready()` 中调用 `apply_wings_*_state()` 会把副本值覆盖回 `@export` 变量，导致：
- Inspector 中手动调整的值在游戏运行后被覆盖
- Godot 编辑器关闭后，state 变量副本丢失（非 `@export`）
- 下次打开项目时，`wings_closed_*` / `wings_open_*` 恢复为代码中的硬编码默认值

**修正方案**：将配置数据源统一为 `@export` 变量，删除独立的 state 变量副本。或者使用 Resource 文件持久化配置。

### 6.2 待完成事项

- [ ] 修复翅膀配置持久化
- [ ] 展翅动画切换回正式使用（替换 `_test_toggle_cycle`）
- [ ] 实现 6 个技能（当前为占位符）
- [ ] 适配 BossBattle_DivineMessenger.tscn 场景

---

## 七、情景入口

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
| 地狱之眼 | `BossBattle_HellEye.tscn` |
| ★ 神明使者 | `BossBattle_DivineMessenger.tscn` |

---

## 八、当前进度

| 模块 | 状态 | 备注 |
|------|------|------|
| 玩家系统 | ✅ 完成 | 移动/射击/受伤/无敌/击飞/道具 |
| 9 种敌人 | ✅ 完成 | 全部子类 |
| 敌人生成器 | ✅ 完成 | 难度自适应 |
| 主菜单 + BossSelect + 结算 | ✅ 完成 | 14 Boss 入口 |
| HUD（玩家 + Boss） | ✅ 完成 | 双色闪烁血条 |
| **星间巨构 + 3 亚种** | ✅ 完成 | 4 Boss，6 技能 |
| **天堂号 + 3 亚种** | ✅ 完成 | 4 Boss，6 技能 |
| **扭曲星核 + 3 亚种** | ✅ 完成 | 4 Boss，6 技能 + AI |
| **地狱之眼** | ✅ 完成 | 1 Boss，视觉+动画完成，技能待重做 |
| **神明使者** ★NEW★ | 🔨 开发中 | 1 Boss，视觉+展翅动画完成，配置持久化待修复，技能待实现 |

---

*文档版本：v2.33 · 生成时间：2026-05-18*
