# Boss 设计规范文档

> 适用于「高能宇宙大爆炸」后续所有 Boss 的开发  
> 基于星间巨构（StarColossus）和天堂号（Paradise）两个 Boss 家族提炼

---

## 目录

1. [必须提供的公共接口](#一必须提供的公共接口)
2. [生命周期状态机](#二生命周期状态机)
3. [必须的碰撞与分组设置](#三必须的碰撞与分组设置)
4. [文件结构清单](#四文件结构清单)
5. [BossBattle 场景模板](#五bossbattle-场景模板)
6. [Boss 实体场景模板](#六boss-实体场景模板)
7. [控制器脚本模板](#七控制器脚本模板)
8. [死亡动画规范](#八死亡动画规范)
9. [进场动画规范](#九进场动画规范)
10. [BGM 切换规范](#十bgm-切换规范)
11. [受击与伤害系统](#十一受击与伤害系统)
12. [技能系统规范](#十二技能系统规范)
13. [亚种（变体）创建规范](#十三亚种变体创建规范)
14. [BossSelect 注册流程](#十四bossselect-注册流程)
15. [快速检查清单](#十五快速检查清单)

---

## 一、必须提供的公共接口

BossHUD 通过**鸭子类型**自动发现 Boss，不检查具体类名。Boss 控制器必须提供以下成员：

| 成员 | 类型 | 说明 |
|------|------|------|
| `boss_hp` | `int` | 当前 HP（必须为 `var`，非 getter） |
| `max_hp` | `int` | 最大 HP（`@export var`，检查器可调） |
| `boss_name` | `String` | 显示名称（`@export var`，检查器可调） |
| `active` | `bool` | Boss 是否已激活可战斗 |
| `dying` | `bool` | Boss 是否正在死亡（可选，推荐） |
| `apply_damage(amount: int)` | 方法 | 外部伤害入口（#1 最重要的方法） |

### BossHUD 的发现逻辑

```gdscript
# BossHUD.gd._find_boss()
func _find_boss() -> void:
    var root = get_tree().current_scene
    for child in root.get_children():
        if child.has_method("apply_damage") and child.get("boss_hp") != null:
            boss = child; return
```

### apply_damage 的标准实现

```gdscript
func apply_damage(amount: int) -> void:
    if entering or dying:    # 进场中/死亡中无视伤害
        return
    boss_hp -= amount
    if boss_hp <= 0:
        boss_hp = 0
        _die()
    else:
        _play_sfx(HIT_SFX, -5)   # 非致命击打音效
```

---

## 二、生命周期状态机

Boss 使用**布尔标志链**而非正式状态机，在 `_process` 中通过 early return 实现：

```
┌─────────────────────────────────────────────────────┐
│                  _process(delta)                     │
├────────────┬────────────┬────────────┬───────────────┤
│ if dying  │if entering │if !active  │   正常逻辑    │
│ → _death  │→ _entrance │→ return   │  技能循环     │
│  _process │ _process   │            │  闲置动画     │
└────────────┴────────────┴────────────┴───────────────┘
```

```gdscript
func _process(delta: float) -> void:
    if dying:
        _death_process(delta)
        return
    if entering:
        _entrance_process(delta)
        return
    if not active:
        return
    # 正常战斗逻辑...
```

### 标志位初始值

| 标志 | 初始值 | 设置为 true 的时机 |
|------|--------|-------------------|
| `entering` | `true` | 构造时 |
| `active` | `false` | 进场动画最后阶段 |
| `dying` | `false` | HP 归零时（`_die()` 中） |

> **约定**：从 HP 归零到 `_die()` 的调用是**同步的**——扣血后立即检查 `boss_hp <= 0`。

---

## 三、必须的碰撞与分组设置

### 碰撞层

| 层 | 归属 | 说明 |
|----|------|------|
| **layer 1** | 玩家、玩家子弹 | `collision_layer = 1` |
| **layer 2** | Boss 所有部件 | `collision_layer = 2, collision_mask = 1` |

- Boss 部件的 `mask = 1` 意味着**只检测玩家和玩家子弹**
- Boss 不检测其他 Boss、敌人或敌方子弹

### 分组

| 组名 | 添加时机 | 用途 |
|------|---------|------|
| `"boss"` | 每个 Boss 部件的 `_ready()` | 统一标识 |

```gdscript
func _ready() -> void:
    collision_layer = 2
    collision_mask = 1
    add_to_group(&"boss")
```

### 碰撞回调

```gdscript
func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group(&"player"):
        area.take_knockback_damage(20, 1000, 0.5)  # 触碰击飞
        return
    if area.get(&"atk") != null:                    # 玩家子弹
        controller.apply_damage(area.atk)
        area.queue_free()
```

---

## 四、文件结构清单

每个 Boss **家族** 至少包含以下文件：

```
scripts/
├── [BossName]Controller.gd        # 主控制器（继承 Node2D）
├── [BossName]Controller.uid       # Godot 自动生成
├── [BossName][Part].gd             # 部件控制器（继承 BossBase 或 Area2D）
├── [BossName][Part].gd.uid
├── [BossName]Variant1.gd          # 亚种1（继承主控制器，_init 覆写）
├── [BossName]Variant1.gd.uid
├── [BossName]Variant2.gd          # 亚种2
└── ...

scenes/
├── [BossName].tscn                # Boss 实体场景（主控制器版本）
├── [BossName]_Variant1.tscn        # 亚种实体场景
├── BossBattle.tscn                # 战斗场景（主版本）
├── BossBattle_Variant1.tscn       # 亚种战斗场景
└── ...

assets/images/[bossname]/
├── [bossname]_body_cutout.png     # 身体贴图（透明背景）
├── [bossname]_arm_cutout.png      # 手臂/部件贴图
└── [bossname]_[variant]_body_cutout.png  # 亚种贴图
```

---

## 五、BossBattle 场景模板

所有 BossBattle 场景使用**完全相同的节点结构**，仅 Boss 实例不同：

```
BossBattle_xxx (Node2D)
├── ScrollingBG (Node2D)         ← [ScrollingBackground.gd]
├── Camera2D                     ← position (480, 360)
├── player (实例 player.tscn)    ← position (480, 360), bullet_scene 预设
├── [Boss实体] (实例 xxx.tscn)   ← 唯一可变节点
├── BossHUD (实例 BossHUD.tscn)  ← CanvasLayer layer=10
└── HUD (实例 hud.tscn)          ← CanvasLayer
```

### .tscn 文件模板

```gd
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="1"]
[ext_resource type="PackedScene" path="res://scenes/bullet.tscn" id="2"]
[ext_resource type="Script" path="res://scripts/ScrollingBackground.gd" id="3"]
[ext_resource type="PackedScene" path="res://scenes/hud.tscn" id="5"]
[ext_resource type="PackedScene" path="res://scenes/[BossName].tscn" id="6"]
[ext_resource type="PackedScene" path="res://scenes/BossHUD.tscn" id="7"]

[node name="BossBattle" type="Node2D"]

[node name="ScrollingBG" type="Node2D" parent="."]
script = ExtResource("3")

[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2(480, 360)

[node name="player" parent="." instance=ExtResource("1")]
position = Vector2(480, 360)
bullet_scene = ExtResource("2")

[node name="[BossName]" parent="." instance=ExtResource("6")]

[node name="BossHUD" parent="." instance=ExtResource("7")]

[node name="HUD" parent="." instance=ExtResource("5")]
```

---

## 六、Boss 实体场景模板

Boss 实体场景是**轻量级**的——只挂载脚本和预设导出值。子节点（身体、手臂、机炮等）**在代码中通过 `_build_parts()` 动态创建**，不在场景中预设。

```gd
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/[BossName]Controller.gd" id="1"]

[node name="[BossName]" type="Node2D"]
script = ExtResource("1")
# ↓ 预设导出值（覆盖脚本默认值），可不设完全零值
[optional_property] = [value]
```

> **例外**：天堂号的 `BodySprite` 在 Paradise.tscn 中预设了一个 `Sprite2D` 子节点（`z_index = 50`），但这是一个特例。推荐所有子节点在代码中创建。

---

## 七、控制器脚本模板

```gdscript
extends Node2D
## [BossName] 总控

# ═══════════ 贴图 ═══════════
@export var body_tex: Texture2D
@export var part_tex: Texture2D

# ═══════════ 基本属性 ═══════════
@export var max_hp: int = 1000
@export var boss_name: String = "[BossName]"
var boss_hp: int

# ═══════════ 生命周期标志 ═══════════
var active: bool = false
var entering: bool = true
var dying: bool = false

# ═══════════ 技能 ═══════════
@export var has_skill_1: bool = true
@export var has_skill_2: bool = true
# ... has_skill_3~6
@export var skill_cooldown: float = 2.0
@export var skill_1_dmg: int = 5
# ... 各技能伤害值
var is_executing: bool = false
var cooldown_remaining: float = 0.0

# ═══════════ 死亡 ═══════════
const DEATH_DURATION: float = 5.0
var death_timer: float = 0.0
var death_explosion_cd: float = 0.0
var death_sfx_cd: float = 0.0
var won: bool = false

# ═══════════ BGM ═══════════
const BOSS_BGM = preload("res://assets/audio/[boss]_bgm.mp3")
var bgm_player: AudioStreamPlayer

# ═══════════ 资源预加载 ═══════════
const HIT_SFX = preload("res://assets/audio/boss_hit.wav")
const EXPLOSION_SFX = preload("res://assets/audio/explosion.wav")
const EXPLOSION_TEX = preload("res://assets/images/fx/explosion.png")
const DEBRIS_TEX = preload("res://assets/images/fx/debris.png")
const ExplosionScript = preload("res://scripts/Explosion.gd")
const DebrisScript = preload("res://scripts/Debris.gd")


func _ready() -> void:
    screen_size = get_viewport().get_visible_rect().size
    boss_hp = max_hp
    if not body_tex:
        body_tex = preload("res://...default_body_cutout.png")
    _setup_bgm()
    _build_parts()
    _start_entrance()


func _process(delta: float) -> void:
    if dying:
        _death_process(delta)
        return
    if entering:
        _entrance_process(delta)
        return
    if not active:
        return
    # 闲置动画...
    # 技能循环...


func apply_damage(amount: int) -> void:
    if entering or dying:
        return
    boss_hp -= amount
    if boss_hp <= 0:
        boss_hp = 0
        _die()
    else:
        _play_sfx(HIT_SFX, -5)
```

---

## 八、死亡动画规范

死亡动画统一为 **5 秒过程**，之后 2.5 秒回主菜单：

### 8.1 `_die()` — 初始化

```gdscript
func _die() -> void:
    if dying:
        return
    active = false
    dying = true
    death_timer = 0.0
    death_explosion_cd = 0.0
    death_sfx_cd = 0.0
    bgm_player.stop()
    GameManager.bgm_player.play()

    # 压暗材质（蓝调，增强"死亡感"）
    body.modulate = Color(0.35, 0.35, 0.4, 1)
    # 停所有活动
    for part in all_parts:
        part.is_animating = true
```

### 8.2 `_death_process(delta)` — 每帧循环

```gdscript
func _death_process(delta: float) -> void:
    death_timer += delta
    death_explosion_cd -= delta
    death_sfx_cd -= delta

    # 30-45 次/秒 随机部位爆炸 + 碎片
    if death_explosion_cd <= 0.0:
        _spawn_death_explosion()
        death_explosion_cd = randf_range(1.0 / 45.0, 1.0 / 30.0)
        if death_sfx_cd <= 0.0:
            _play_sfx(EXPLOSION_SFX, -8)
            death_sfx_cd = 0.15

    # 颤抖（部件 + 相机）
    _shake_parts()

    # 5s 后终结
    if death_timer >= DEATH_DURATION and not won:
        won = true
        _spawn_final_explosion()
        queue_free()
        _return_to_menu()
```

### 8.3 终结爆炸 + 返回

```gdscript
func _spawn_final_explosion() -> void:
    _play_sfx(EXPLOSION_SFX, 0)
    # 20-30 个爆炸原点覆盖 Boss 区域
    for _i in randi_range(20, 30):
        var exp = Sprite2D.new()
        exp.set_script(ExplosionScript)
        exp.texture = EXPLOSION_TEX
        exp.position = _random_boss_pos()
        exp.scale = Vector2(1.2, 1.2)
        exp.z_index = 1000
        get_tree().current_scene.add_child(exp)
        _spawn_debris(pos, 6~10)

func _return_to_menu() -> void:
    await get_tree().create_timer(2.5).timeout
    if get_tree():
        get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
```

---

## 九、进场动画规范

### 9.1 黑幕遮罩（复用组件）

```gdscript
func _create_entrance_overlay() -> void:
    overlay_layer = CanvasLayer.new()
    overlay_layer.layer = 100                      # 最高层
    overlay_layer.follow_viewport_enabled = true

    overlay_rect = ColorRect.new()
    overlay_rect.color = Color(0, 0, 0, 0)         # 初始透明
    overlay_rect.anchor_left = 0.0; overlay_rect.anchor_right = 1.0
    overlay_rect.anchor_top = 0.0; overlay_rect.anchor_bottom = 1.0
    overlay_rect.offset_left = -150; overlay_rect.offset_top = -150   # 余量防抖动露边
    overlay_rect.offset_right = 150; overlay_rect.offset_bottom = 150
    overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

    overlay_label = Label.new()
    overlay_label.text = boss_name
    overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
    overlay_label.add_theme_font_size_override(&"font_size", 72)
    overlay_label.modulate = Color(1, 1, 1, 0)
    overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    overlay_layer.add_child(overlay_rect)
    overlay_layer.add_child(overlay_label)
    add_child(overlay_layer)
```

### 9.2 进场流程模板

```
屏外初始位 → 滑入(1s ease-out) → 摆姿势+咆哮(0.3s) → 黑屏白字(2-3s) → active=true
```

- 进场期间 `entering = true`，BossHUD 自动隐藏（检测 `boss.active == false`）
- 进场结束后设定 `entering = false; active = true; cooldown_remaining = 0.0`（立刻触发第一个技能）

---

## 十、BGM 切换规范

```gdscript
# 资源常量化
const BOSS_BGM = preload("res://assets/audio/[boss]_bgm.mp3")

func _setup_bgm() -> void:
    bgm_player = AudioStreamPlayer.new()
    bgm_player.stream = BOSS_BGM
    bgm_player.volume_db = -10      # 比普通 BGM 稍低
    add_child(bgm_player)

func _start_bgm() -> void:
    if GameManager.bgm_player.playing:
        GameManager.bgm_player.stop()
    bgm_player.play.call_deferred()  # 延迟一帧避免冲突

# 死亡时恢复（在 _die() 中）：
func _die() -> void:
    bgm_player.stop()
    GameManager.bgm_player.play()
```

**时点**：BGM 在黑屏白字出现时切换（出场动画中段），而非进场开始时。

---

## 十一、受击与伤害系统

### 伤害传递链

```
玩家子弹 → 击中 Boss 部件（Area2D layer=2）→ _on_area_entered()
  └→ if area.atk != null:
       controller.apply_damage(area.atk)
       area.queue_free()

                                    ↓
                                    ↓
            apply_damage(amount):
              ├→ entering/dying → skip
              ├→ boss_hp -= amount
              ├→ play HIT_SFX
              └→ if HP ≤ 0 → _die()
```

### 碰撞伤害

```
玩家触碰 Boss 部件 → Player.take_knockback_damage(20, 1000, 0.5)
  - 伤害: 20
  - 击飞速度: 1000px/s 衰减
  - 击飞时长: 0.5s
  - 无敌帧: 0.7s
```

### 直接技能伤害

```
Boss 技能 → player.take_damage_from_boss(dmg)
  - 1s 无敌帧
Boss 碰撞伤害 → player.take_knockback_damage(dmg, spd, dur)
  - 击飞 + 0.7s 无敌帧
```

---

## 十二、技能系统规范

### 12.1 技能池模式

```gdscript
@export var has_skill_1: bool = true
@export var has_skill_2: bool = true
# ... has_skill_3~6
@export var skill_cooldown: float = 2.0

# _process() 中：
cooldown_remaining -= delta
if cooldown_remaining <= 0.0:
    is_executing = true
    var available: Array[int] = []
    if has_skill_1: available.append(1)
    # ...
    if not available.is_empty():
        var s = available[randi() % available.size()]   # 等概率随机
        match s:
            1: await _skill_1()
            2: await _skill_2()
            # ...
    cooldown_remaining = skill_cooldown
    is_executing = false
```

### 12.2 技能要求

| 要求 | 说明 |
|------|------|
| 技能函数 | `func _skill_N() -> void`，开头检查 `if dying: is_executing = false; return` |
| 伤害值可调 | 每个技能独立 `@export var skill_N_dmg: int` |
| Tween 管理 | 使用 `_make_tween()`（而非直接 `create_tween()`）以便死亡时自动 kill |
| 长循环守卫 | 所有 `while` 循环体内检查 `if dying: break` |
| 开关机制 | `has_skill_N` 控制技能是否出现在技能池中 |

### 12.3 `_make_tween()` 死亡守卫模式

```gdscript
var _skill_tweens: Array[Tween] = []

func _make_tween() -> Tween:
    if dying:
        var tw = create_tween()
        tw.kill()
        return tw
    var tw = get_tree().create_tween()
    _skill_tweens.append(tw)
    return tw

# 在 _die() 中：
func _die() -> void:
    ...
    for tw in _skill_tweens:
        if is_instance_valid(tw) and tw.is_valid():
            tw.kill()
    _skill_tweens.clear()
```

---

## 十三、亚种（变体）创建规范

通过**继承控制器 + `_init()` 覆写**实现，不创建新脚本文件：

```gdscript
# scripts/[BossName]Variant.gd
extends "res://scripts/[BossName]Controller.gd"
## [变体名] —— [简要描述]

func _init() -> void:
    boss_name = "[变体名]"
    max_hp = 1000
    skill_cooldown = 2.0
    has_skill_1 = true
    has_skill_2 = false
    # ...
    body_tex = preload("res://assets/images/[boss]/[variant]_body_cutout.png")
    cannon_tex = preload("res://assets/images/[boss]/[variant]_cannon_cutout.png")
```

### 创建步骤

1. 创建 `[BossName]Variant.gd`（仅覆写 `_init()`）
2. 创建 `[BossName]_Variant.tscn`（与主版本结构相同，仅改 script 引用）
3. 创建 `BossBattle_Variant.tscn`（与主版本结构相同，仅改 Boss 实例引用）
4. 在 `BossSelect.gd` 注册新场景路径
5. 在 `BossSelect.tscn` 添加新按钮

---

## 十四、BossSelect 注册流程

### 14.1 更新 `BossSelect.gd`

```gdscript
const BOSS_SCENES = {
    "Boss1Button": "res://scenes/BossBattle.tscn",
    "Boss2Button": "res://scenes/BossBattle_Variant1.tscn",
    # ...
    "BossNButton": "res://scenes/BossBattle_New.tscn",
}

func _on_boss_selected(scene_path: String) -> void:
    GameManager.score = 0
    GameManager.player_hp = GameManager.PLAYER_MAX_HP
    GameManager.elapsed = 0.0
    get_tree().change_scene_to_file(scene_path)
```

### 14.2 更新 `BossSelect.tscn`

每个按钮 38px 高，间距 12px，从 top=150 开始排列。字号 20px。

---

## 十五、快速检查清单

创建新 Boss 时逐项确认：

| # | 检查项 | 
|---|--------|
| ☐ | 控制器继承 `Node2D`，提供 `boss_hp`, `max_hp`, `boss_name`, `active`, `apply_damage()` |
| ☐ | `_process` 按 dying → entering → !active 顺序 early return |
| ☐ | Boss 部件设置 `collision_layer=2, collision_mask=1, group="boss"` |
| ☐ | 部件碰撞回调：玩家→击飞，玩家子弹→`controller.apply_damage(area.atk)` |
| ☐ | `apply_damage()` 守卫 `entering or dying`，扣血→检查死亡→播放音效 |
| ☐ | `_die()` 设 `dying=true`，停 BGM→恢复 GameManager BGM，压暗材质 |
| ☐ | `_death_process()` 每帧生成爆炸+碎片+颤抖，5s 后终结→回主菜单 |
| ☐ | 进场动画使用 CanvasLayer(100) 黑幕遮罩 |
| ☐ | BGM 在进场黑屏时切换，延迟一帧 `call_deferred` |
| ☐ | 技能使用 `_make_tween()` 而非 `create_tween()` |
| ☐ | 技能入口/长循环检查 `if dying` |
| ☐ | 伤害值全部 `@export var` 暴露在检查器 |
| ☐ | 创建 `[BossName].tscn` + `BossBattle_[BossName].tscn` 各 1 个 |
| ☐ | 亚种仅创建小脚本 `_init()` 覆写 + 对应场景 |
| ☐ | 在 `BossSelect.gd` 和 `BossSelect.tscn` 注册入口 |

---

## 十六、Shader 类 Boss 开发补充规范（v2.23 新增，基于地狱之眼）

当地狱之眼这类 Boss 需要 Shader 裁剪视觉效果时，遵循以下补充规范：

### 16.1 Shader 目录约定

所有 Shader 和材质放在 `assets/images/[bossname]/` 下，与贴图统一管理：
```
assets/images/helleye/
├── mask_alpha.png              # 遮罩贴图（alpha 通道 = 裁剪形状）
├── nebula_raw.png              # 被裁剪的内容贴图
├── eyeball_cutout.png          # 被裁剪的第二个内容贴图
├── eye_clip.gdshader           # 裁剪着色器
└── eye_mask_shader.gdshader    # 辅助着色器
```

### 16.2 ShaderMaterial 创建模板

```gdscript
func _make_clip_shader_mat(mask_tex: Texture2D) -> ShaderMaterial:
    var shader := preload("res://assets/images/helleye/eye_clip.gdshader")
    var mat := ShaderMaterial.new()
    mat.shader = shader
    mat.set_shader_parameter(&"mask_tex", mask_tex)
    mat.set_shader_parameter(&"mask_scale", Vector2(1.0, 1.0))
    mat.set_shader_parameter(&"content_scale", Vector2(1.0, 1.0))
    return mat
```

### 16.3 多层 Sprite 叠加模式

当 Boss 需要多个视觉层通过同一遮罩裁剪时：
1. 每层使用独立的 `Sprite2D` 节点
2. 每层使用同一份 Shader 的独立 `ShaderMaterial` 实例
3. 通过 `z_index` 控制渲染顺序
4. 所有参数通过 `set_shader_parameter()` 在 `_process` 中同步

### 16.4 检查器暴露 Shader 参数

所有 Shader 参数通过 `@export var` 暴露在 Inspector 中：
```gdscript
@export var mask_scale: Vector2 = Vector2(0.18, 0.18)    # 遮罩大小
@export var mask_rotation_deg: float = 0.0               # 遮罩旋转
@export var nebula_scale: Vector2 = Vector2(0.27, 0.27)  # 内容缩放
@export var nebula_offset: Vector2 = Vector2(0, 0)       # 内容偏移
@export var mask_stroke_thickness: float = 3.0            # 描边粗细
@export var mask_stroke_jitter: float = 1.5               # 描边抖动
```

### 16.5 遮罩缩放方向约定

由于 UV 空间中 `rotated * mask_scale` 的运算关系：
- **mask_scale 值越大 = 遮罩越小**（UV 采样范围更大 = 裁出更小区域）
- **content_scale 值越大 = 内容越小**（纹理被拉伸更大）

建议 Inspector 中使用比例值（如 0.18），而非像素值，方便跨分辨率调节。

### 16.6 描边系统

非 Shader 实现的描边（推荐方案）：
- 使用遮罩贴图直接作为 `Sprite2D` 显示
- 通过 `scale = mask_scale + thickness` 实现粗细
- 旋转方向与遮罩相反（`stroke_sprite.rotation = -mask_rotation`）
- 每帧在脚本中通过 sin/cos 组合计算抖动偏移

### 16.7 Shader Boss 快速检查清单（追加）

| # | 检查项 |
|---|--------|
| ☐ | Shader 文件放在 `images/[bossname]/` 下 |
| ☐ | 每层 Sprite 使用独立的 ShaderMaterial 实例（不共享） |
| ☐ | `_setup_body()` 用代码创建所有 Sprite 和碰撞体，不在 .tscn 中预设 |
| ☐ | `_setup_orbiters()` 覆写为空（`pass`）如果不需小环绕球 |
| ☐ | 多层 `z_index` 递增（每层间隔 ≥ 1） |
| ☐ | Shader uniform 每帧同步（可在 `_idle_animation` 或独立方法中） |
| ☐ | Inspector 参数全部 `@export`，默认值为测试调好的值 |
| ☐ | 遮罩旋转角度用 `deg`（人类可读），脚本中 `deg_to_rad` 转换 |

---

*文档版本：1.1*
*基于项目 v2.23 提炼（含地狱之眼 Shader 系统经验）*
