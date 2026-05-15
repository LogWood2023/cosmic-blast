# 打飞机游戏 - 功能实现参考手册

> 本文档整理自项目内 36 个 GDScript 脚本 + project.godot 配置文件，按功能模块分类，记录每种功能的完整实现方案，方便后续开发复用。

---

## 目录

1. [项目配置 (project.godot)](#1-项目配置-projectgodot)
2. [全局管理器 (Autoload 单例)](#2-全局管理器-autoload-单例)
3. [场景跳转与游戏状态重置](#3-场景跳转与游戏状态重置)
4. [z_index 层级约定](#4-z_index-层级约定)
5. [玩家系统](#5-玩家系统)
6. [玩家子弹](#6-玩家子弹)
7. [敌方子弹](#7-敌方子弹)
8. [炸弹系统](#8-炸弹系统)
9. [敌人生成器](#9-敌人生成器)
10. [敌人基类与状态机](#10-敌人基类与状态机)
11. [敌人类型详解](#11-敌人类型详解)
    - [射击机 (ShooterEnemy)](#111-射击机-shooterenemy)
    - [散射机 (ScatterEnemy)](#112-散射机-scatterenemy)
    - [连射机 (ChainEnemy)](#113-连射机-chainenemy)
    - [撞击机 (RammerEnemy)](#114-撞击机-rammerenemy)
    - [导弹机 (MissileEnemy)](#115-导弹机-missileenemy)
    - [轰炸机 (BomberEnemy)](#116-轰炸机-bomberenemy)
    - [抛投机 (ThrowerEnemy)](#117-抛投机-throwerenemy)
    - [治愈机 (HealerEnemy)](#118-治愈机-healerenemy)
    - [自爆机 (SuicideEnemy)](#119-自爆机-suicideenemy)
12. [道具系统](#12-道具系统)
13. [碰撞检测与伤害传递](#13-碰撞检测与伤害传递)
14. [Boss 系统](#14-boss-系统)
    - [BossBase 组件基类](#141-bossbase-组件基类)
    - [BossHUD 血条](#142-bosshud-血条)
    - [星间巨构 (StarColossus) 详细拆解](#143-星间巨构-starcolossus--详细拆解)
    - [天堂号 (Paradise) 详细拆解](#144-天堂号-paradise--详细拆解)
15. [设计模式与技术合辑](#15-设计模式与技术合辑)
16. [扭曲星核系统 (v2.22 新增)](#十六扭曲星核系统-v222-新增)
17. [地狱之眼系统 (v2.23 新增)](#十七地狱之眼系统-v223-新增)

---

## 1. 项目配置 (project.godot)

### 1.1 基本设置

```ini
[application]
config/name="打飞机游戏"

[display]
window/size/viewport_width=960
window/size/viewport_height=720
window/size/resizable=false
window/dpi/allow_hidpi=true
window/vsync/vsync_mode=1

[rendering]
renderer/rendering_method="forward_plus"
renderer/rendering_method.mobile="gl_compatibility"
textures/canvas_textures/default_texture_filter=0

[physics]
2d/physics_engine="Jolt Physics"
```

### 1.2 Autoload 注册

```ini
[autoload]
GameManager="*res://scripts/GameManager.gd"
```

### 1.3 输入映射

| 动作 | 按键 |
|------|------|
| 移动上 | W / ↑ |
| 移动下 | S / ↓ |
| 移动左 | A / ← |
| 移动右 | D / → |
| 射击 | 鼠标左键 |

---

## 2. 全局管理器 (Autoload 单例)

### 2.1 完整代码

```gdscript
# scripts/GameManager.gd
## 全局游戏管理器（Autoload 单例）
extends Node

var score: int = 0          # 得分（公共可读写）
var player_hp: int = 100    # 玩家 HP（公共可读写）
var elapsed: float = 0.0    # 局时间

func _process(delta: float) -> void:
    elapsed += delta

func difficulty() -> float:
    return clampf(elapsed / 180.0, 0.0, 1.0)

func reset_state() -> void:
    score = 0
    player_hp = 100
    elapsed = 0.0
```

### 2.2 关键模式说明

- **全局单例访问**：任意脚本 `GameManager.score += 10`
- **难度计算**：基于 `elapsed/180s` 得出 0~1 的难度值，上限在 3 分钟后
- **状态重置**：场景切换前必须调用 `GameManager.reset_state()`

### 2.3 什么情况下需要重置

| 场景跳转 | 是否重置 |
|----------|----------|
| 主菜单 → 开始游戏 | 是 |
| 主菜单 → Boss 挑战 | 是 |
| Boss 死亡 → BossSelect | 是 |
| GameOver → MainMenu | 是 |

---

## 3. 场景跳转与游戏状态重置

### 3.1 MainMenu 完整代码

```gdscript
# scripts/MainMenu.gd
extends Node2D

func _on_start_pressed() -> void:
    GameManager.reset_state()
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_boss_select_pressed() -> void:
    GameManager.reset_state()
    get_tree().change_scene_to_file("res://scenes/BossSelect.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()
```

### 3.2 GameOver 完整代码

```gdscript
# scripts/GameOver.gd
## 游戏结束画面
extends Node2D

func _ready() -> void:
    $ScoreLabel.text = "最终得分: %d" % GameManager.score

func _on_restart_pressed() -> void:
    GameManager.reset_state()
    get_tree().change_scene_to_file("res://scenes/main.tscn")
```

### 3.3 BossSelect 字典绑定模式

```gdscript
# scripts/BossSelect.gd
extends Node2D

const BOSS_SCENES: Dictionary = {
    "星间巨构": "res://scenes/BossBattle.tscn",
    "星海前锋": "res://scenes/BossBattle_Frontier.tscn",
    "星尘重兵": "res://scenes/BossBattle_Heavy.tscn",
    "星云巨构": "res://scenes/BossBattle_Nebula.tscn",
    "天堂号":   "res://scenes/BossBattle_Paradise.tscn",
    "桃源乡":   "res://scenes/BossBattle_PeachBlossom.tscn",
    "乌托邦":   "res://scenes/BossBattle_Utopia.tscn",
    "伊甸园":   "res://scenes/BossBattle_Eden.tscn",
    "扭曲星核": "res://scenes/BossBattle_WarpedCore.tscn",
    "异变源石": "res://scenes/BossBattle_Source.tscn",
    "诡异菌孢": "res://scenes/BossBattle_Spore.tscn",
    "反物质核": "res://scenes/BossBattle_Anti.tscn",
    "地狱之眼": "res://scenes/BossBattle_HellEye.tscn",
}
```

---

## 4. z_index 层级约定

| z_index | 用途 |
|---------|------|
| -1 | 星星背景（ParallaxBackground） |
| 0 | 默认（敌人、子弹、玩家） |
| 1 | 道具、部分特效 |
| 2 | 警告/攻击范围绘制 |
| 3 | 爆炸特效 |
| 5 | 炸弹爆炸 |
| 10 | BossHUD (CanvasLayer) |
| 15 | 黑幕遮罩 |
| 20 | 星光轨迹（地狱之眼遮罩层） |
| 43-45 | 地狱之眼视觉层（描边/星云/眼珠） |

---

## 5. 玩家系统

### 5.1 属性与初始化

```gdscript
# scripts/Player.gd
extends Area2D
class_name Player

signal player_died

const SPEED := 300.0
const FIRE_INTERVAL := 0.25
const INVINCIBILITY_DURATION := 1.0
const KNOCKBACK_INVINCIBILITY := 0.7

@export var debug_infinite_hp: bool = false
var _fire_cooldown: float = 0.0
var _is_invincible: bool = false
var _inv_timer: float = 0.0
var _knockback_vector: Vector2 = Vector2.ZERO
var _knockback_duration: float = 0.0
```

### 5.2 移动 + 朝向 + 射击（_process 主体）

```gdscript
func _process(delta: float) -> void:
    GameManager.player_hp = clamp(GameManager.player_hp, 0, 100)
    if GameManager.player_hp <= 0: return

    _update_invincibility(delta)
    _handle_knockback(delta)
    _handle_movement(delta)
    _handle_aim()
    _handle_shooting(delta)
```

### 5.3 射击方法

```gdscript
func _shoot() -> void:
    var b := preload("res://scenes/Bullet.tscn").instantiate()
    b.global_position = global_position
    get_parent().add_child(b)
```

### 5.4 三种受击方法

```gdscript
# 被敌方子弹 / 撞击机 / 炸弹等攻击时调用（来源有 Area2D）
func take_damage_from(area: Area2D) -> void:
    if _is_invincible: return
    var dmg: int = area.get(&"atk") if area.get(&"atk") != null else 10
    _apply_damage(dmg)
    area.queue_free()
    _enter_invincibility(INVINCIBILITY_DURATION)
    _play_sfx("hit")

# Boss 直接伤害（无 Area2D 来源，如冲拳/激光）
func take_damage_from_boss(dmg: int) -> void:
    if _is_invincible or debug_infinite_hp: return
    _apply_damage(dmg)
    _enter_invincibility(INVINCIBILITY_DURATION)
    _play_sfx("hit")

# Boss 碰撞击飞
func take_knockback_damage(dmg: int, speed: float, duration: float) -> void:
    if _is_invincible or debug_infinite_hp: return
    _apply_damage(dmg)
    _entry_invincibility(duration + KNOCKBACK_INVINCIBILITY)
    var dir: Vector2 = (global_position - bosspos).normalized()
    _knockback_vector = dir * speed
    _knockback_duration = duration
```

### 5.5 四种道具效果

| 道具 | 方法 | 效果 |
|------|------|------|
| 补血 | `heal(amount)` | `player_hp = min(100, hp+amount)` |
| 炸弹 | `add_bomb()` | `bomb_count += 1` |
| 护盾 | `add_shield()` | 获得 3s 护盾 |
| 火力提升 | `add_power()` | 双倍射速 5s |

### 5.6 音效辅助

```gdscript
func _play_sfx(name: String) -> void:
    var sfx := AudioStreamPlayer.new()
    match name:
        "hit": sfx.stream = preload("res://assets/audio/hit.wav")
        "shoot": sfx.stream = preload("res://assets/audio/shoot.wav")
    sfx.bus = &"SFX"
    add_child(sfx)
    sfx.play()
    await sfx.finished
    sfx.queue_free()
```

---

## 6. 玩家子弹

```gdscript
# scripts/Bullet.gd
extends Area2D

const SPEED := 600.0
const LIFETIME := 2.0
var atk := 5
var _timer: float = 0.0

func _process(delta: float) -> void:
    position += Vector2.UP.rotated(rotation) * SPEED * delta
    _timer += delta
    if _timer >= LIFETIME: queue_free()

func _on_body_entered(_body: PhysicsBody2D) -> void:
    queue_free()
```

---

## 7. 敌方子弹

```gdscript
# scripts/EnemyBullet.gd
extends Area2D

var speed: float = 200.0
var direction: Vector2 = Vector2(0, 1)

func _process(delta: float) -> void:
    position += direction * speed * delta
    # 超出屏幕销毁
    if global_position.y > 800 or global_position.y < -100:
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body is Player: body.take_damage_from(self)
    queue_free()
```

---

## 8. 炸弹系统

### 8.1 完整代码

```gdscript
# scripts/Bomb.gd
extends RigidBody2D

var damage: float = 100.0
var explosion_radius: float = 150.0
var fuse_time: float = 2.0

func _ready() -> void:
    await get_tree().create_timer(fuse_time).timeout
    explode()

func explode() -> void:
    var exp := preload("res://scenes/Explosion.tscn").instantiate()
    exp.scale = Vector2(explosion_radius/256, explosion_radius/256)
    exp.global_position = global_position
    get_parent().add_child(exp)
    var bodies := get_overlapping_bodies()
    for b in bodies:
        if b is BossBase:
            b.apply_damage(damage)
        elif b is EnemyBullet:
            b.queue_free()
    queue_free()
```

### 8.2 两种使用模式

| 模式 | 触发方式 | fuse_time |
|------|----------|-----------|
| 普通轰炸 | Bomber 投放 | 2.0s |
| Boss 炸弹 | StarColossus skill_4 | 3.0s |

### 8.3 爆炸缩放公式

```gdscript
exp.scale = Vector2(explosion_radius / 256.0, explosion_radius / 256.0)
```

---

## 9. 敌人生成器

### 9.1 完整代码

```gdscript
# scripts/EnemySpawner.gd
extends Node2D

@export var spawn_interval: float = 3.0
var _timer: float = 0.0

func _process(delta: float) -> void:
    _timer += delta
    if _timer >= spawn_interval:
        _spawn_random_enemy()
        _timer = 0.0

func _spawn_random_enemy() -> void:
    var diff := GameManager.difficulty()
    var types := ["ShooterEnemy", "RammerEnemy", "BomberEnemy",
                  "ScatterEnemy", "SuicideEnemy", "HealerEnemy",
                  "ChainEnemy", "MissileEnemy", "ThrowerEnemy"]
    var weights := [3, 2+d*1, 2+d*1, 2+d*1, 1+d*1, 1+d*1,
                    1+d*1, 1+d*1, 1+d*1]  # d = diff
    var chosen := _weighted_pick(types, weights)
    var e := load("res://scenes/" + chosen + ".tscn").instantiate()
    e.global_position = Vector2(randf_range(60, 900), -80)
    add_child(e)
```

### 9.2 关键设计点

- **加权随机**：基于 difficulty() 调整权重，越难越容易出现高级敌机
- **屏幕外生成**：Y = -80，从上方飞入
- **X 随机范围**：60~900，避开屏幕边缘

---

## 10. 敌人基类与状态机

### 10.1 属性与枚举

```gdscript
# scripts/BaseEnemy.gd
extends Area2D

enum State { WARNING, MOVING, COOLDOWN, LEAVING }

@export var max_hp: int = 20
@export var move_speed: float = 120.0
@export var atk: int = 10
@export var warning_duration: float = 2.0
var _state: int = State.WARNING
var _timer: float = 0.0
var _hp: int = max_hp
var _target_pos: Vector2
var _origin_pos: Vector2
```

### 10.2 资源预加载

```gdscript
const WARNING_TEX := preload("res://assets/images/fx/warning_circle.png")
const HP_BAR := preload("res://scenes/HealthBar.tscn")
```

### 10.3 _ready() — 初始化 + 动态创建血条

```gdscript
func _ready() -> void:
    _hp = max_hp
    _origin_pos = global_position
    _timer = 0.0
    _target_pos = Vector2(randf_range(100, 860), randf_range(80, 500))
    var bar := HP_BAR.instantiate()
    bar.max_value = max_hp
    add_child(bar)
    bar.position = Vector2(-20, -40)
```

### 10.4 _process() 状态机

```gdscript
func _process(delta: float) -> void:
    _timer += delta
    match _state:
        State.WARNING: _state_warning(delta)
        State.MOVING:  _state_moving(delta)
        State.COOLDOWN: _state_cooldown(delta)
        State.LEAVING: _state_leaving(delta)
```

### 10.5 四状态流程图

```
WARNING(2s) → MOVING → COOLDOWN → WARNING → ... → LEAVING
```

| 状态 | 时长 | 行为 |
|------|------|------|
| WARNING | 2.0s | 原地不动 + 闪烁警告 |
| MOVING | ~ | 飞向目标位置 + 子类钩子 `_moving_behavior()` |
| COOLDOWN | 3.0s | 停留 + 子类钩子 `_cooldown_behavior()` |
| LEAVING | ~ | Y 轴离开屏幕 |

### 10.6 各状态实现

```gdscript
func _state_warning(_delta: float) -> void:
    modulate = Color(1,0.5,0.5,0.5+sin(_timer*10)*0.5)
    if _timer >= warning_duration:
        modulate = Color.WHITE
        _timer = 0.0
        _state = State.MOVING

func _state_moving(delta: float) -> void:
    var dir := (_target_pos - global_position).normalized()
    global_position += dir * move_speed * delta
    _moving_behavior(delta)
    if global_position.distance_to(_target_pos) < 10:
        _timer = 0.0; _state = State.COOLDOWN

func _state_cooldown(delta: float) -> void:
    _cooldown_behavior(delta)
    if _timer >= 3.0:
        _target_pos = Vector2(randf_range(100,860), randf_range(80,500))
        _timer = 0.0; _state = State.WARNING

func _state_leaving(delta: float) -> void:
    global_position.y += move_speed * delta
    if global_position.y > 800: queue_free()
```

### 10.7 路径预览框绘制

```gdscript
func _draw() -> void:
    if _state == State.WARNING:
        draw_set_transform(Vector2.ZERO, 0, Vector2(1.5, 1.5))
        draw_texture(WARNING_TEX, -WARNING_TEX.get_size()/2)
```

### 10.8 受击与死亡

```gdscript
func _on_area_entered(area: Area2D) -> void:
    if area.get("atk") != null:
        _hp -= area.atk
        area.queue_free()
        if _hp <= 0:
            _die()

func _die() -> void:
    _spawn_explosion()
    _spawn_debris()
    GameManager.score += 100
    queue_free()
```

### 10.9 爆炸与碎片生成

```gdscript
func _spawn_explosion() -> void:
    var exp := preload("res://scenes/Explosion.tscn").instantiate()
    exp.global_position = global_position
    get_parent().add_child(exp)

func _spawn_debris() -> void:
    for i in range(6):
        var d := preload("res://scenes/Debris.tscn").instantiate()
        d.global_position = global_position
        d.velocity = Vector2(randf_range(-200,200), randf_range(-200,-50))
        var s := randf_range(0.5, 1.5)
        d.scale = Vector2(s, s)
        get_parent().add_child(d)
```

### 10.10 子类覆写钩子

```gdscript
func _moving_behavior(_delta: float) -> void: pass
func _cooldown_behavior(_delta: float) -> void: pass
```

---

## 11. 敌人类型详解

### 11.1 射击机 (ShooterEnemy)

```gdscript
func _cooldown_behavior(_delta: float) -> void:
    if _timer < 0.3: return
    _timer = 0.0
    var b := preload("res://scenes/EnemyBullet.tscn").instantiate()
    b.global_position = global_position
    var dir := (player_pos - global_position).normalized()
    b.direction = dir
    get_parent().add_child(b)
```

### 11.2 散射机 (ScatterEnemy)

```gdscript
func _cooldown_behavior(_delta: float) -> void:
    if _timer < 0.5: return; _timer = 0.0
    for i in range(5):
        var b := preload("res://scenes/EnemyBullet.tscn").instantiate()
        b.global_position = global_position
        var angle := -PI/6 + i * PI/12
        b.direction = Vector2.DOWN.rotated(angle)
        b.speed = 150
        get_parent().add_child(b)
```

### 11.3 连射机 (ChainEnemy)

```gdscript
func _cooldown_behavior(_delta: float) -> void:
    if _burst_count >= 3: return
    _burst_timer += _delta
    if _burst_timer < 0.15: return; _burst_timer = 0.0
    var b := preload("res://scenes/EnemyBullet.tscn").instantiate()
    b.global_position = global_position
    b.direction = (player_pos - global_position).normalized()
    b.speed = 250
    get_parent().add_child(b)
    _burst_count += 1
```

### 11.4 撞击机 (RammerEnemy)

```gdscript
func _moving_behavior(delta: float) -> void:
    var dir := (player_pos - global_position).normalized()
    global_position += dir * move_speed * 1.5 * delta
```

### 11.5 导弹机 (MissileEnemy)

```gdscript
func _cooldown_behavior(_delta: float) -> void:
    if _timer < 1.0: return; _timer = 0.0
    var b := preload("res://scenes/EnemyBullet.tscn").instantiate()
    b.global_position = global_position
    b.direction = (player_pos - global_position).normalized()
    b.speed = 100  # 慢速追踪
    b.tracking = true
    get_parent().add_child(b)
```

### 11.6 轰炸机 (BomberEnemy)

```gdscript
func _cooldown_behavior(_delta: float) -> void:
    if _timer < 2.0: return; _timer = 0.0
    var bomb := preload("res://scenes/Bomb.tscn").instantiate()
    bomb.global_position = global_position
    bomb.fuse_time = 3.0
    get_parent().add_child(bomb)
```

### 11.7 抛投机 (ThrowerEnemy)

```gdscript
func _cooldown_behavior(_delta: float) -> void:
    if _timer < 1.5: return; _timer = 0.0
    var b := preload("res://scenes/EnemyBullet.tscn").instantiate()
    b.global_position = global_position
    b.direction = Vector2.DOWN + Vector2.RIGHT * randf_range(-0.5, 0.5)
    b.speed = 350
    get_parent().add_child(b)
```

### 11.8 治愈机 (HealerEnemy)

```gdscript
func _cooldown_behavior(_delta: float) -> void:
    if _timer < 2.0: return; _timer = 0.0
    var targets := get_tree().get_nodes_in_group("enemy")
    for t in targets:
        if t == self: continue
        if t.get("hp") != null and t.hp < t.max_hp:
            t.hp += 10
            break
```

### 11.9 自爆机 (SuicideEnemy)

```gdscript
func _moving_behavior(delta: float) -> void:
    var dir := (player_pos - global_position).normalized()
    global_position += dir * move_speed * 2 * delta
    if global_position.distance_to(player_pos) < 50:
        _detonate()

func _detonate() -> void:
    # 16 方向爆弹
    for i in range(16):
        var b := preload("res://scenes/EnemyBullet.tscn").instantiate()
        b.global_position = global_position
        b.direction = Vector2.UP.rotated(i * TAU / 16)
        b.speed = 200
        get_parent().add_child(b)
    _die()
```

---

## 12. 道具系统

```gdscript
# scripts/PowerUp.gd
extends Area2D

enum Type { HEAL, BOMB, SHIELD, POWER }
@export var type: Type = Type.HEAL
const SPRITES := {
    Type.HEAL: preload("res://assets/images/powerup/heal.png"),
    Type.BOMB: preload("res://assets/images/powerup/bomb.png"),
    Type.SHIELD: preload("res://assets/images/powerup/shield.png"),
    Type.POWER: preload("res://assets/images/powerup/power.png"),
}

func _ready() -> void:
    $Sprite2D.texture = SPRITES[type]

func _on_body_entered(body: Node2D) -> void:
    if body is Player:
        match type:
            Type.HEAL: body.heal(20)
            Type.BOMB: body.add_bomb()
            Type.SHIELD: body.add_shield()
            Type.POWER: body.add_power()
        queue_free()
```

---

## 13. 碰撞检测与伤害传递

### 13.1 碰撞层设计

| 层 | 归属 |
|----|------|
| 1 | 玩家、玩家子弹 |
| 2 | Boss 部件 |

### 13.2 五条伤害传递链

1. **玩家子弹 → 敌人**：Bullet area.entered → enemy._on_area_entered → hp -= atk
2. **敌方子弹 → 玩家**：EnemyBullet body.entered → player.take_damage_from(area)
3. **Boss 部件 → 玩家**：BossBase area.entered → player.take_knockback_damage(20, 1000, 0.5)
4. **玩家子弹 → Boss 部件**：Bullet area.entered → boss._on_area_entered → controller.apply_damage(atk)
5. **炸弹爆炸 → Boss**：Bomb.get_overlapping_bodies → boss.apply_damage(100)

### 13.3 Group 查找模式

```gdscript
# 动画结束后查找 Boss 并切换 BGM
var boss := get_tree().get_first_node_in_group("boss")
```

---

## 14. Boss 系统

### 14.1 BossBase 组件基类

```gdscript
# scripts/BossBase.gd
extends Area2D

class_name BossBase

var controller: Node = null
var boss_hp: int:
    get: return controller.boss_hp if controller else 0
```

**碰撞配置**：layer=2, mask=1，Group="boss"

`_on_area_entered(area)`：
- `area is Player` → `player.take_knockback_damage(20, 1000, 0.5)`
- `area.atk != null` → `controller.apply_damage(area.atk); area.queue_free()`

### 14.2 BossHUD 血条

```gdscript
# scripts/BossHUD.gd
extends CanvasLayer

var _boss: Node = null            # 动态发现 Boss
var _display_hp: float = 1000.0   # 平滑显示
const FLASH_DECAY: float = 300.0  # 黄条衰减速度

func _ready() -> void:
    _find_boss()

func _process(delta: float) -> void:
    if not _boss: _find_boss(); return
    var actual := float(_boss.boss_hp)
    _display_hp = move_toward(_display_hp, actual, 200 * delta)
    _update_bars(actual, _display_hp)
```

**结构（BossHUD.tscn）**：
```
BossHUD (CanvasLayer)
├── FlashBar (ColorRect 橙色) — 受击闪烁条
├── RedBar (ColorRect 红色)   — 实际 HP 条
├── NamePlate (TextureRect) + NameLabel — Boss 名牌
└── Frame (TextureRect) — 血条外框装饰
```

闪烁逻辑：
- `display_hp` 以 200/秒速率平滑下降到 `actual_hp`
- 黄条持续显示受击损失量，线性缩短至 0

### 14.3 星间巨构 (StarColossus) —— 详细拆解

#### 14.3.1 架构总览

```
StarColossusController (Node2D) ← 技能主控
├── body (StarColossusBody/BossBase)  ← 碰撞
├── left_arm (StarColossusArm/BossBase)
├── right_arm (StarColossusArm/BossBase)
└── overlay_layer (CanvasLayer) ← 黑幕（进场时）
```

#### 14.3.2 控制器属性与导出变量

| 导出变量 | 默认 | 说明 |
|----------|------|------|
| `boss_name` | "星间巨构" | |
| `max_hp` | 1000 | |
| `boss_hp` | 1000 | 运行时 HP |
| `skill_cooldown` | 5.0 | 基础冷却 |
| `body_breath_amplitude` | 16.0 | 身体呼吸振幅（px） |
| `arm_breath_amplitude` | 12.0 | 手臂呼吸振幅（px） |
| `has_skill_1~6` | false/true | 技能开关 |

#### 14.3.3 四个子类（_init 覆写模式）

```gdscript
# StarColossusFrontier.gd（星海前锋）
func _init():
    boss_name = "星海前锋"
    max_hp = 600
    skill_cooldown = 3.0
    has_skill_1 = true; has_skill_2 = true; has_skill_3 = true
    has_skill_4 = false; has_skill_5 = false; has_skill_6 = false
```

#### 14.3.4 _build_parts() — 动态构建身体/手臂

```gdscript
func _build_parts() -> void:
    body = _create_part(BODY_TEX, BODY_COLLISION, "body")
    left_arm = _create_part(ARM_TEX, ARM_COLLISION, "left_arm")
    right_arm = _create_part(ARM_TEX, ARM_COLLISION, "right_arm")
    left_arm.position = Vector2(-150, 0)
    right_arm.position = Vector2(150, 0)
```

#### 14.3.5 Body 呼吸动画

```gdscript
func _body_breath(delta: float) -> void:
    _breath_t += delta * 1.5
    body.scale = Vector2.ONE * (1 + sin(_breath_t) * body_breath_amplitude / 256.0)
```

#### 14.3.6 Arm 呼吸动画

```gdscript
func _arm_breath(delta: float) -> void:
    left_arm.position.y = -30 + sin(time*2) * arm_breath_amplitude
```

#### 14.3.7 进场动画（5 阶段）

| 阶段 | 时间 | 效果 |
|------|------|------|
| 飞入 | 0-2s | 从顶部滑入 |
| 黑幕 | 2-3.5s | 黑屏 + boss_name 显示 |
| 消失 | 3.5-4.5s | 黑幕淡出 |
| 停顿 | 4.5-5.5s | 画面颤动 |
| 激活 | 5.5s+ | 清除 overlay，进入战斗 |

#### 14.3.8 黑幕遮罩（_create_entrance_overlay）

```gdscript
func _create_entrance_overlay() -> void:
    overlay_layer = CanvasLayer.new()
    var rect := ColorRect.new()
    rect.color = Color.BLACK; rect.size = screen_size
    overlay_layer.add_child(rect)
    var label := Label.new()
    label.text = boss_name; label.add_theme_font_size_override("font_size", 48)
    overlay_layer.add_child(label)
    add_child(overlay_layer)
```

#### 14.3.9 技能池随机选择

```gdscript
func _pick_random_skill() -> int:
    var pool: Array[int] = []
    for i in range(1, 7):
        if get("has_skill_%d" % i): pool.append(i)
    if pool.is_empty(): return -1
    return pool[randi() % pool.size()]
```

#### 14.3.10 技能1 — 蓄力冲击+弹幕

```gdscript
func _skill_charge_attack() -> void:
    var warn := _create_warn_rect(body.get_rect())
    await _show_warn(warn, 1.5)
    body.global_position = player_pos  # 瞬移到玩家位置
    for i in range(12):
        var b := EnemyBullet.new()
        b.direction = Vector2.RIGHT.rotated(i*PI/6)
        b.global_position = body.global_position
        add_child(b)
    _shake_body(10, 0.3)
```

#### 14.3.11 技能2 — 冲拳

```gdscript
func _skill_arm_punch(use_left: bool) -> void:
    var arm := left_arm if use_left else right_arm
    var start := arm.global_position
    var target := start.move_toward(player_pos, 400)
    var warn := _create_warn_line(start, target, 40)
    await _show_warn(warn, 1.0)
    var tween := create_tween()
    tween.tween_property(arm, "global_position", target, 0.3)
    tween.tween_property(arm, "global_position", start, 0.3)
    # 逐帧碰撞检测
```

#### 14.3.12 技能5 — 爆裂冲拳

同技能2，到达后发射 8 方向爆弹。

#### 14.3.13 技能6 — 连拳爆裂弹

左右臂交替冲拳 3 轮 + 每轮 8 方向爆弹。

#### 14.3.14 技能3 — 地震

```gdscript
func _skill_quake() -> void:
    body.position.y += 50  # 下砸
    var tween := create_tween()
    tween.tween_property(body, "position:y", 0, 0.3)
    # 6 发弹幕扇形
    # 屏幕外生成 2+diff 个敌人
```

#### 14.3.15 技能4 — 炸弹散布

```gdscript
func _skill_bomb() -> void:
    var count := 3 + randi() % 3
    for i in count:
        var bomb := Bomb.new()
        bomb.global_position = Vector2(randf_range(100,860), randf_range(50,300))
        bomb.fuse_time = 3.0
        add_child(bomb)
    await get_tree().create_timer(3.5).timeout
```

#### 14.3.16 死亡动画

5 秒爆炸序列：
1. 0s：第一波 explosion + debris 散射
2. 1s：第二波
3. 2s：第三波 + 主爆炸（scale=3.0）
4. 5s：cleanup debris → queue_free controller
5. BossHUD 检测 Boss 消失 → 弹出结算 → 2.5s 后回到 BossSelect

### 14.4 天堂号 (Paradise) —— 详细拆解

#### 14.4.1 架构总览

```
ParadiseController (Node2D)
├── body (BossBase)  ← 主船体
├── cannon_left/cannon_right  ← 左右机炮 (ParadiseCannon)
├── dock_left/dock_right      ← 左右停泊位（4 个位置）
└── 4 × ParadiseCannon (TOP/BOTTOM/LEFT/RIGHT 停泊)
```

#### 14.4.2 停泊位系统

4 个停泊位置：TOP, BOTTOM, LEFT, RIGHT。PATROL 状态下机炮停泊到各自位置。

#### 14.4.3 待机摆动

```gdscript
func _idle_animation(delta: float) -> void:
    _swing_t += delta * 1.2
    body.position.y = sin(_swing_t) * 20
```

#### 14.4.4 机炮追踪

```gdscript
func _track_player(cannon, delta) -> void:
    var dir := (player.global_position - cannon.global_position).normalized()
    cannon.rotation = lerp_angle(cannon.rotation, dir.angle(), delta * 3)
```

#### 14.4.5 激光射线

```gdscript
func _fire_laser(from: Vector2, to: Vector2) -> void:
    var laser := Line2D.new()
    laser.width = 4
    laser.default_color = Color.RED
    laser.points = [from, to]
    add_child(laser)
    await get_tree().create_timer(0.5).timeout
    laser.queue_free()
```

---

## 15. 设计模式与技术合辑

| 模式 | 实现方式 | 使用位置 |
|------|----------|----------|
| **Autoload 单例** | project.godot autoload + var | GameManager |
| **场景字典绑定** | const DICT + 按钮 text 匹配 | BossSelect |
| **虚拟钩子** | func _xxx() pass 让子类覆写 | BaseEnemy |
| **Group 查找** | `get_tree().get_first_node_in_group("boss")` | BossHUD/BGM |
| **信号解耦** | signal player_died → HUD/结算 | Player |
| **Tween 时序链** | `await tween.finished; next()` | Boss 技能 |
| **加权随机** | Array[float] weights + 累积概率 | EnemySpawner |
| **global ↔ local 坐标** | `to_global()` / `to_local()` | Boss 技能 |
| **多 Tween 并行管理** | 数组存储 `{tw, cannon, ...}` | Paradise 技能5 |
| **递归链式延迟** | `await timer; func()` | ChainEnemy |
| **_draw 中实时动画** | `queue_redraw()` + warn_timer | 所有警戒框 |

---

## 十六、扭曲星核系统 (v2.22 新增)

完整方法文档见 `METHOD_REFERENCE.md`。

### 新增核心方法

| 方法 | 说明 |
|------|------|
| `_pick_random_skill()` | 从已启用技能中均匀随机选取 |
| `_exec_skill(s)` | 技能编号分发 |
| `_launch_orb_async()` | 技能5 异步发射球 |
| `_check_laser_hit_player()` | 激光四臂碰撞检测 |
| `_skill_1_exclude_nearest(d)` | 技能1 排除最近dock |
| `_reset_orbiters_positions()` | 小球归位轨道 |
| `_shake_parts()` | 增强：重影+小球+碰撞体 |

### AI 系统

`_process()` 中记录 `_last_skill`，场上敌机≤3 且上次非技能3时强制咆哮召唤。

### 亚种模式

3 个亚种继承 `WarpedCoreController`，覆写 `_ready()` 设置各项参数，`super._ready()` 前必须设置 `boss_name`。

---

## 十七、地狱之眼系统 (v2.23 新增) ★NEW★

完整方法文档见 `METHOD_REFERENCE.md` 第十八至二十二章。

### 核心类与方法

| 方法 | 说明 |
|------|------|
| `_setup_body()` | 覆写：创建三层Sprite（描边→星云→眼珠）+ 碰撞体 |
| `_setup_orbiters()` | 覆写为空（pass），不需要环绕小球 |
| `_idle_animation(delta)` | 覆写：呼吸+同步shader+眼球追踪+描边抖动 |
| `_entrance_process(delta)` | 覆写：7阶段进场动画（~6.5s），含瞪眼+黑幕+颤动 |
| `_process_eye_animation(delta)` | 眼睛动画状态机：WIDE→SQUINT→BLINK 循环+正常过渡 |
| `_apply_idle_breath(delta)` | 待机呼吸：Y轴75%~125%正弦波（3s周期） |
| `_sync_mask_params()` | 每帧同步所有shader参数和描边transform |
| `_apply_eyeball_shake()` | WIDE状态下眼珠多频颤动+玩家追踪偏移 |
| `_track_player_eyeball()` | 眼球朝向玩家方向偏移 |
| `_apply_stroke_jitter()` | 描边位置/缩放/旋转持续不规则抖动 |

### Shader 系统

`eye_clip.gdshader` — 用 mask_alpha.png 的 alpha 通道裁剪内容：
- `mask_scale`、`mask_rotation`、`mask_offset_uv`：控制遮罩
- `content_scale`、`content_offset`：独立控制内容（眼球缩放/偏移）
- 两者独立控制，互不影响

### 检查器暴露参数

```gdscript
@export var mask_scale: Vector2 = Vector2(0.18, 0.18)
@export var mask_rotation_deg: float = 0.0
@export var nebula_scale: Vector2 = Vector2(0.27, 0.27)
@export var nebula_offset: Vector2 = Vector2(0, 0)
@export var eyeball_scale: Vector2 = Vector2(0.18, 0.18)
@export var eyeball_offset: Vector2 = Vector2(0, 0)
@export var mask_stroke_thickness: float = 3.0
@export var mask_stroke_jitter: float = 1.5
@export var mask_stroke_color: Color = Color.BLACK
```

### AI 与技能

继承基类 `WarpedCoreController` 的 AI 系统（记录 `_last_skill`，敌机≤3时强制技能3）。**所有6个技能均关闭**（`has_skill_1~6 = false`），技能功能待重做。

---

*文档生成时间：2026-05-13 · v2.23*
*项目：打飞机游戏 (Godot 4.6 / 960×720)*