# 扭曲星核 + 地狱之眼 —— 方法参考文档

> Godot 4.6 · GDScript · WarpedCoreController + 3 亚种 + HellEyeController
> 生成时间：2026-05-13 · 版本 2.23

---

## 目录

1. [架构总览](#一架构总览)
2. [生命周期方法](#二生命周期方法)
3. [进场系统](#三进场系统)
4. [待机动画系统](#四待机动画系统)
5. [布朗运动系统](#五布朗运动系统)
6. [技能调度与 AI](#六技能调度与-ai)
7. [技能 1：停泊位转移](#七技能-1停泊位转移)
8. [技能 2：轨道扩张](#八技能-2轨道扩张)
9. [技能 3：咆哮 + 召唤敌机](#九技能-3咆哮--召唤敌机)
10. [技能 4：强吸力咆哮](#十技能-4强吸力咆哮)
11. [技能 5：十字激光连射](#十一技能-5十字激光连射)
12. [技能 6：连续冲刺](#十二技能-6连续冲刺)
13. [受击与死亡系统](#十三受击与死亡系统)
14. [亚种 Boss 系统](#十四亚种-boss-系统)
15. [碰撞与伤害流程](#十五碰撞与伤害流程)
16. [绘图系统 _draw](#十六绘图系统-_draw)
17. [音效工具](#十七音效工具)
18. [地狱之眼：着色器裁剪系统](#十八地狱之眼着色器裁剪系统)
19. [地狱之眼：眼睛动画状态机](#十九地狱之眼眼睛动画状态机)
20. [地狱之眼：描边抖动系统](#二十地狱之眼描边抖动系统)
21. [地狱之眼：进场动画](#二十一地狱之眼进场动画)
22. [地狱之眼：检查器参数速查](#二十二地狱之眼检查器参数速查)

---

## 一、架构总览

```
WarpedCoreController (extends Node2D)
├── VariantSource (亚种1: 异变源石)
├── VariantSpore  (亚种2: 诡异菌孢)
└── VariantAnti   (亚种3: 反物质核)
```

### 核心变量

| 变量 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `max_hp` | `int` | 1000 | 最大 HP（@export） |
| `boss_hp` | `int` | max_hp | 当前 HP |
| `boss_name` | `String` | "扭曲星核" | 黑幕显示名（@export） |
| `active` | `bool` | false | 是否已激活 |
| `dying` | `bool` | false | 是否死亡中 |
| `entering` | `bool` | true | 是否进场中 |
| `is_executing` | `bool` | false | 是否正在执行技能 |
| `cooldown_remaining` | `float` | 0.0 | 技能冷却剩余 |
| `_last_skill` | `int` | 0 | 上次技能编号（AI用） |
| `body_sprite` | `Sprite2D` | — | 星核主体精灵 |
| `orbiter_data` | `Array[Dict]` | — | 环绕小球数据 |
| `_dock` | `Dock` | HOME | 当前停泊位 |
| `_brown_state` | `BrownState` | PICK_TARGET | 布朗运动状态 |

---

## 二、生命周期方法

### `_ready()`

```gdscript
func _ready() -> void
```

流程：
1. 获取 `screen_size`、`_initial_position`
2. 调用 `_setup_dock_positions()` 计算 4 个停泊位
3. 调用 `_setup_body()` 创建主体精灵 + 红移/蓝移重影
4. 调用 `_setup_orbiters()` 创建 4 个环绕小球 + 碰撞体
5. 调用 `_create_entrance_overlay()` 创建黑幕层
6. 调用 `_start_bgm()` 播放 BGM

子类 **必须在 super._ready() 前** 设置 `boss_name`、`max_hp`、技能开关，否则黑幕会显示父类默认名。

### `_process(delta)`

```gdscript
func _process(delta: float) -> void
```

分叉：
- `entering` → `_entrance_process(delta)` 进场动画
- `dying` → `_death_process(delta)` 死亡动画
- `active` → `_idle_animation(delta)` + 技能调度

### `_entrance_process(delta)`

5 阶段进场：
| 阶段 | 时间 | 效果 |
|------|------|------|
| 0 | 0-0.25s | 背景缩放到 0 立即恢复，主体 pulse_mult=0→1 |
| 1 | 0.25-2.25s | 主体 0.25→1 倍缩放，四颗小球逐个 0.25→1 滑入 |
| 2 | 2.25-4.25s | 黑幕 2s，boss_name 淡入淡出 |
| 3 | 4.25-5.25s | 黑幕消退 |
| 4 | 5.25s+ | 销毁 overlay，`entering=false, active=true` |

---

## 三、进场系统

### `_create_entrance_overlay()`

创建 CanvasLayer（layer=100），内含全屏 ColorRect + 72px Label。
黑幕文本取 `boss_name`，font_size=72。

### `_start_bgm()`

停止 GameManager 全局 BGM，播放 `warpedcore_bgm.mp3`。

---

## 四、待机动画系统

### `_idle_animation(delta)`

```gdscript
func _idle_animation(delta: float) -> void
```

三部分：

1. **主体脉动**：`body_scale_value * sin(pulse_phase)`，频率受 `_eff_freq_mult` 调制
2. **红移/蓝移重影**：`sin(time * 1.2Hz)` 驱动 ghost_swap，距离 5~35px 摆动
3. **环绕小球**：圆周运动，`angle += speed * z_dir * delta`，碰撞体跟随

---

## 五、布朗运动系统

```gdscript
enum BrownState { PICK_TARGET, MOVING, PAUSING }
```

| 状态 | 说明 |
|------|------|
| PICK_TARGET | 随机选目标偏移（相对 `_home_position`），最小距离 `brown_max_dist * 0.3` |
| MOVING | `ease-out` 曲线移动到目标 |
| PAUSING | 倒计时暂停，归零后回到 PICK_TARGET |

技能期间通过 `_brown_pause_timer = 99.0` 冻结布朗运动。

---

## 六、技能调度与 AI

### `_process()` 中的调度逻辑

```gdscript
cooldown_remaining -= delta
if cooldown_remaining <= 0.0:
    is_executing = true
    # AI判定
    if has_skill_3 and _last_skill != 3:
        if get_tree().get_nodes_in_group("enemies").size() <= 3:
            s = 3
        else:
            s = _pick_random_skill()
    else:
        s = _pick_random_skill()
    if s != 0:
        await _exec_skill(s)
        _last_skill = s
    cooldown_remaining = skill_cooldown
    is_executing = false
```

### `_pick_random_skill() → int`

从已启用的技能中均匀随机选取。

### `_exec_skill(s: int)`

match 分发到 `_skill_1()` ~ `_skill_6()`。

### AI 规则

场上敌机 ≤3 且上次不是技能 3 → 强制技能 3。确保战场持续有压力。

---

## 七、技能 1：停泊位转移

```gdscript
func _skill_1() -> void
```

| 阶段 | 时长 | 说明 |
|------|------|------|
| 冻结布朗 | — | PAUSING, 99s |
| 加速 | 1s | 环绕小球速 1→6 倍 |
| 锁定目标 | — | 从 4 个 dock 排除当前，随机选 |
| 警戒框 | 3s | `_show_warn(from, to)` 条形警告 |
| 冲刺 | `dist / (speed*3)` | ease-out 曲线，小球速 6→1 |
| 停顿 | 1s | 更新 `_dock`、`_home_position` |
| 恢复 | — | 布朗运动 |

---

## 八、技能 2：轨道扩张

```gdscript
func _skill_2() -> void
```

| 阶段 | 时长 | 说明 |
|------|------|------|
| 轨道扩大 | 5s | 半径 1→3 倍，速度 1→5 倍 |
| 匀速维持 | 10s | 速度保持不变 |
| 缓慢回归 | 5s | 半径 3→1，速度 5→1 |

全程显示紫色圆弧警戒环（前方 90° 全亮，45~90° 渐隐，后方 15° 渐隐）。

---

## 九、技能 3：咆哮 + 召唤敌机

```gdscript
func _skill_3() -> void
```

| 阶段 | 时长 | 说明 |
|------|------|------|
| 膨胀 | 0.25s | `body_scale` 1→2，pulse_amp 2x |
| 全屏震动 | 3s | 摄像机 ±25px 随机抖动 |
| 召唤序列 | 3s | 依次生成随机敌机（撞击机/抛投机/自爆机），总时间 3s 均匀分布 |

---

## 十、技能 4：强吸力咆哮

```gdscript
func _skill_4() -> void
```

| 阶段 | 时长 | 说明 |
|------|------|------|
| 膨胀 | 0.25s | body=2x，body_effect=2x |
| 吸力 | 10s | `GameManager.suction_active=true`，白条粒子向心涌入 (4条/s)，残骸生成 (0.15s cd) |

玩家被吸入 → 受击。残骸从屏幕边缘生成，撞到星核或玩家后爆炸。结束后恢复布朗运动。

---

## 十一、技能 5：十字激光连射

```gdscript
func _skill_5() -> void
```

| 阶段 | 时长 | 说明 |
|------|------|------|
| 生成小球 | 循环 | 从星核中心 `Sprite2D.new()` 创建，纹理同轨道小球 |
| 飞行 | 0.5s | EASE_IN_OUT，旋转 2 圈 |
| 蓄力 | ~1s | 旋转指数衰减 4rps→5°/s，显示十字警戒框 (half_w=6) |
| 爆炸 | — | `_spawn_explosion_at(scale=0.35)` |
| 十字激光 | 0.5s | 生长 0.25s (0→1) + 宽度收缩 0.25s (1→0) |
| 销毁 | — | 小球 `queue_free()` |

激光四臂延伸至屏幕对角线 ×0.8，命中玩家 10 伤害（点→线段最短距离判定，碰撞半宽=视觉×2）。

发射 20~30 颗，8~12s 内均匀分布。各球独立协程运行，互不锁步。

---

## 十二、技能 6：连续冲刺

```gdscript
func _skill_6() -> void
```

| 阶段 | 时长 | 说明 |
|------|------|------|
| 加速 | 持续 | `_orbiter_speed_override = 6.0` 全程保持 |
| 锁定终点 | — | 玩家位置 + 方向延申 80~350px |
| 警戒框 | 2.0→递减 | 初始 2s，每次减 0.5s，最低 1.0s |
| 冲刺 | `dist/(speed*3)` | ease-out 曲线，速度保持 6 倍 |
| 循环 | 8~12 次 | 终点立刻锁定+蓄力，无停顿 |
| 末尾技能 1 | 继承递减 | 排除离玩家最近的 dock |

### `_skill_1_exclude_nearest(warn_duration)`

技能 6 末尾触发的技能 1 变体：
- 计算 4 个 dock 到玩家的距离，排除最近的
- 也排除当前 dock（避免原地不动）
- 剩余中随机选取，警戒框时长继承技能 6 的递减值
- 冲刺后停顿 1s

---

## 十三、受击与死亡系统

### `apply_damage(amount: int)`

```gdscript
func apply_damage(amount: int) -> void
```

- 扣血 `boss_hp -= amount`
- 不死亡 → 播放 HIT_SFX + 闪白 (body_sprite + 重影 0.05s WHITE→normal)
- HP≤0 → `_die()`

### `_die()`

- 设置 `active=false, dying=true`
- 停止 BGM，杀所有 Tween
- 清理技能状态（技能2、十字激光、警戒框）
- 所有精灵 modulate 压暗至 `(0.35, 0.35, 0.4)`

### `_death_process(delta)`

- 每秒 30~45 次爆炸（随机在 body_sprite 和轨道小球周围）
- 每 0.15s 播放爆炸音效
- `_shake_parts()` 颤抖
- 5s 后触发 `_spawn_final_explosion()` → `queue_free()` → 2.5s 后回主菜单

### `_shake_parts()`

```
body_sprite ±25px
重影跟随
轨道小球 ±8px + 角度 ±0.15rad
摄像机 ±15px
```

### `_spawn_death_explosion()`

在 body_sprite 和所有轨道小球周围 ±80px 生成爆炸（scale 0.5），碎片为 `orbiter_tex` 小球碎片。

### `_spawn_final_explosion()`

20~30 个爆炸（scale 1.2）分布在 Boss 周围 ±200px，碎片同样为 `orbiter_tex`。

---

## 十四、亚种 Boss 系统

### 继承链

三个亚种均继承 `WarpedCoreController`，仅覆写 `_ready()`：

```gdscript
extends "res://scripts/WarpedCoreController.gd"

func _ready() -> void:
    boss_name = "XXX"       # ★必须在 super 之前
    max_hp = 1000
    has_skill_N = ...
    skill_cooldown = ...
    super._ready()
    boss_hp = max_hp
```

### 数据表

| 编号 | 名称 | HP | 冷却 | 技能 | 材质 |
|------|------|-----|------|------|------|
| 10 | 异变源石 | 1000 | 3s | 1,2,3 | 原版扭曲星核 |
| 11 | 诡异菌孢 | 1000 | 2s | 1,2,3,4 | 墨绿菌类（AI生成） |
| 12 | 反物质核 | 1000 | 1s | 6,2,3,4,5 | 负片扭曲（AI生成） |

### 材质生成流程

```
原版纹理 → packAI /v1/images/edits 图生图
         → techsz segmentation API 抠图
         → 保存 _cutout.png
```

---

## 十五、碰撞与伤害流程

### 碰撞层级

| 实体 | layer (我是谁) | mask (我检测谁) |
|------|---------------|----------------|
| Player | 1 | 2 |
| Bullet (玩家) | 1 | 1 |
| WarpedCore body | 2 | 1 |
| WarpedCore orbiter | 2 | 1 |

### 玩家子弹命中 Boss

```gdscript
# 由 Boss 侧处理（子弹 mask=1 检测不到 layer=2）
func _on_body_area_entered(area):
    if area.is_in_group("player"):
        area.take_knockback_damage(...)       # 玩家碰撞
    elif area.get("atk") != null:
        apply_damage(area.atk)                # 子弹伤害
        area.queue_free()
```

两个碰撞函数（body 和 orbiter）都有此分支。

---

## 十六、绘图系统 `_draw`

```gdscript
func _draw() -> void
```

绘制内容（按顺序）：

1. **技能 5 十字激光** — 遍历 `_cross_lasers` 数组，每条四臂绘制（底色 + 光晕）
2. **技能 4 吸力粒子** — 白条 `draw_colored_polygon` 矩形（2.5px 半宽）
3. **技能 2 轨道警戒圆环** — 分段圆弧，前方 90° 全亮，后方渐隐
4. **条形警戒框** — `_warn_list` 条目，紫色闪烁厚实条 (half_w 可配置)

### `_draw_laser_arm(center, dir, perp, length, half_w, col)`

绘制一条激光臂的矩形。

### `_warn_list` 条目结构

```gdscript
{"from": Vector2, "to": Vector2, "timer": float, "max_timer": float, "full_half_w": float}
```

---

## 十七、音效工具

### `_play_sfx(stream, volume_db)`

创建临时 `AudioStreamPlayer`，播放完毕后自动 `queue_free`。

### 音频资源

| 常量 | 文件 | 用途 |
|------|------|------|
| BOSS_BGM | warpedcore_bgm.mp3 | Boss 战 BGM |
| EXPLOSION_SFX | explosion.wav | 爆炸音效 |
| HIT_SFX | boss_hit.wav | 受击音效 |

---

## 技能时间线速查

| 技能 | 总时长 | 关键机制 |
|------|--------|----------|
| 1 | ~6s | 3s 蓄力 + 冲刺 + 1s 停顿 |
| 2 | ~20s | 5s 扩大 + 10s 维持 + 5s 回归 |
| 3 | ~3.25s | 0.25s 膨胀 + 3s 震动召唤 |
| 4 | ~10.25s | 0.25s 膨胀 + 10s 吸力 |
| 5 | ~8~12s | 20~30 颗小球，间隔 ≈ 总长/总数 |
| 6 | ~15~30s | 8~12 次冲刺，警戒框 2→1s 递减 |
