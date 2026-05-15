# 高能宇宙大爆炸 —— 完整项目交接文档

> Godot 4.6 · 2D 弹幕射击 · 960×720 · Windows  
> 文档生成时间：2026-05-13 · v2.23

---

## 目录

1. [项目概述](#一项目概述)
2. [完整文件树](#二完整文件树)
3. [场景入口与流程](#三场景入口与流程)
4. [核心系统](#四核心系统)
5. [玩家系统](#五玩家系统)
6. [敌人系统](#六敌人系统)
7. [弹幕与道具系统](#七弹幕与道具系统)
8. [Boss 系统总览](#八boss-系统总览)
9. [Boss「星间巨构」详解](#九boss星间巨构详解)
10. [星间巨构的三个亚种](#十星间巨构的三个亚种)
11. [Boss「天堂号」详解](#十一boss天堂号详解)
12. [天堂号 3 个亚种](#11-b天堂号-3-个亚种)
13. [Boss「扭曲星核」详解](#十二boss扭曲星核详解)
14. [扭曲星核 3 个亚种](#12-b扭曲星核-3-个亚种)
15. [Boss「地狱之眼」详解](#十三boss地狱之眼详解) ★NEW★
16. [视觉特效系统](#十四视觉特效系统)
17. [UI 系统](#十五ui-系统)
18. [资源清单](#十六资源清单)
19. [碰撞层级与分组](#十七碰撞层级与分组)
20. [伤害传递流程](#十八伤害传递流程)
21. [开发约定](#十九开发约定)
22. [当前进度](#二十当前进度)

---

## 一、项目概述

一款纵向卷轴 2D 弹幕射击游戏（STG），玩家操控星际战机对抗宇宙敌军及巨型 Boss。

### 核心参数

| 项目 | 值 |
|------|-----|
| 引擎 | Godot 4.6 (Forward+) |
| 主场景 | `MainMenu.tscn` → 三入口 |
| 分辨率 | 960 × 720 |
| 渲染驱动 | D3D12 |
| 物理引擎 | Jolt Physics |
| 自动加载单例 | `GameManager.gd` |
| 输入 | WASD/方向键移动，鼠标左键射击 |

### 代码规模

| 指标 | 数量 |
|------|------|
| GDScript 文件 | 43 个 |
| 场景文件 (.tscn) | 40 个 |
| 素材文件 (PNG) | 59 个 |
| 音频文件 (WAV+MP3) | 13 个 |
| 总代码行数 | ~3,900 行 |

---

## 二、完整文件树

```
E:\GoDot Project\打飞机游戏\
├── project.godot                          # Godot 引擎配置
├── PROJECT_DOC.md                         # 旧版文档（2026-05-08）
├── HANDOVER.md                            # 本文档（2026-05-11）
├── README.md                              # 早期 README
├── icon.svg / icon.svg.import             # 图标
├── export_presets.cfg                     # 导出预设
│
├── scripts/                               # 37 个 .gd 脚本
│   ├── GameManager.gd                     # 全局状态（Autoload）
│   ├── Player.gd                          # 玩家控制
│   │
│   ├── BaseEnemy.gd                       # 敌人基类（状态机）
│   ├── BomberEnemy.gd                     # 轰炸机
│   ├── ChainEnemy.gd                      # 连射机
│   ├── HealerEnemy.gd                     # 治疗机
│   ├── MissileEnemy.gd                    # 导弹机
│   ├── RammerEnemy.gd                     # 撞击机
│   ├── ScatterEnemy.gd                    # 散射机
│   ├── ShooterEnemy.gd                    # 射击机
│   ├── SuicideEnemy.gd                    # 自爆机
│   ├── ThrowerEnemy.gd                    # 抛投机
│   ├── EnemySpawner.gd                    # 敌人生成器
│   │
│   ├── Bullet.gd                          # 玩家子弹
│   ├── EnemyBullet.gd                     # 敌方子弹
│   ├── Bomb.gd                            # 炸弹
│   ├── PowerUp.gd                         # 道具
│   │
│   ├── BossBase.gd                        # Boss 组件基类
│   ├── StarColossusController.gd          # 星间巨构主控（999行）
│   ├── StarColossusBody.gd                # 星间巨构身体
│   ├── StarColossusArm.gd                 # 星间巨构手臂
│   ├── StarColossusFrontier.gd            # 亚种：星海前锋
│   ├── StarColossusHeavy.gd               # 亚种：星尘重兵
│   ├── StarColossusNebula.gd              # 亚种：星云巨构
│   │
│   ├── ParadiseController.gd              # 天堂号主控（1337行）
│   ├── ParadiseCannon.gd                  # 天堂号机炮组件
│   ├── ParadisePeachBlossom.gd            # 亚种：桃源乡
│   ├── ParadiseUtopia.gd                  # 亚种：乌托邦
│   ├── ParadiseEden.gd                    # 亚种：伊甸园
│   │
│   ├── HellEyeController.gd               # 地狱之眼主控
│   ├── HellEyePupil.gd                    # 地狱之眼瞳孔
│   │
│   ├── ScrollingBackground.gd             # 无限卷动星空背景
│   ├── Explosion.gd                       # 爆炸帧动画
│   ├── Debris.gd                          # 碎片飞行物
│   ├── RingDrawer.gd                      # 信号环绘制器
│   │
│   ├── MainMenu.gd                        # 主菜单
│   ├── BossSelect.gd                      # Boss 选择界面
│   ├── GameOver.gd                        # 结算界面
│   ├── HUD.gd                             # 玩家 HUD（CanvasLayer）
│   ├── LifeBar.gd                         # 玩家血条组件
│   ├── BossHUD.gd                         # Boss 血条（CanvasLayer）
│   └── HealthBar.gd                       # 敌人血条组件
│
├── scenes/                                # 34 个 .tscn 场景
│   ├── MainMenu.tscn                      # 主菜单
│   ├── BossSelect.tscn                    # Boss 选择
│   ├── main.tscn                          # 正常关卡
│   ├── gameover.tscn                      # 结算
│   │
│   ├── player.tscn                        # 玩家
│   ├── bullet.tscn                        # 玩家子弹
│   ├── EnemyBullet.tscn                   # 敌方子弹
│   ├── Bomb.tscn                          # 炸弹
│   │
│   ├── enemyspawner.tscn                  # 敌人生成器
│   ├── EnemyShooter.tscn                  # 射击机
│   ├── EnemyRammer.tscn                   # 撞击机
│   ├── EnemyBomber.tscn                   # 轰炸机
│   ├── EnemyScatter.tscn                  # 散射机
│   ├── EnemySuicide.tscn                  # 自爆机
│   ├── EnemyHealer.tscn                   # 治疗机
│   ├── EnemyChain.tscn                    # 连射机
│   ├── EnemyMissile.tscn                  # 导弹机
│   ├── EnemyThrower.tscn                  # 抛投机
│   │
│   ├── PowerUpAtk.tscn                    # 攻击提升道具
│   ├── PowerUpFireRate.tscn               # 射速提升道具
│   ├── PowerUpHeal.tscn                   # 恢复道具
│   ├── PowerUpShield.tscn                 # 护盾道具
│   │
│   ├── hud.tscn                           # 玩家 HUD
│   ├── BossHUD.tscn                       # Boss 血条
│   │
│   ├── StarColossus.tscn                  # 星间巨构 Boss
│   ├── StarColossus_Frontier.tscn         # 星海前锋 Boss
│   ├── StarColossus_Heavy.tscn            # 星尘重兵 Boss
│   ├── StarColossus_Nebula.tscn           # 星云巨构 Boss
│   ├── Paradise.tscn                      # 天堂号 Boss
│   ├── Paradise_PeachBlossom.tscn          # 桃源乡 Boss
│   ├── Paradise_Utopia.tscn                # 乌托邦 Boss
│   ├── Paradise_Eden.tscn                  # 伊甸园 Boss
│   │
│   ├── WarpedCore.tscn                     # 扭曲星核 Boss
│   ├── VariantSource.tscn                  # 异变源石 Boss
│   ├── VariantSpore.tscn                   # 诡异菌孢 Boss
│   ├── VariantAnti.tscn                    # 反物质核 Boss
│   │
│   ├── HellEye.tscn                        # ★NEW★ 地狱之眼 Boss
│   │
│   ├── BossBattle.tscn                    # Boss 战 - 星间巨构
│   ├── BossBattle_Frontier.tscn           # Boss 战 - 星海前锋
│   ├── BossBattle_Heavy.tscn              # Boss 战 - 星尘重兵
│   ├── BossBattle_Nebula.tscn             # Boss 战 - 星云巨构
│   ├── BossBattle_Paradise.tscn           # Boss 战 - 天堂号
│   ├── BossBattle_PeachBlossom.tscn       # Boss 战 - 桃源乡
│   ├── BossBattle_Utopia.tscn             # Boss 战 - 乌托邦
│   └── BossBattle_Eden.tscn               # Boss 战 - 伊甸园
│
│   ├── BossBattle_WarpedCore.tscn          # Boss 战 - 扭曲星核
│   ├── BossBattle_Source.tscn              # Boss 战 - 异变源石
│   ├── BossBattle_Spore.tscn               # Boss 战 - 诡异菌孢
│   ├── BossBattle_Anti.tscn                # Boss 战 - 反物质核
│   └── BossBattle_HellEye.tscn             # ★NEW★ Boss 战 - 地狱之眼
│
└── assets/
    ├── images/
    │   ├── boss/        (20 个 PNG)
    │   ├── enemy/       (18 个 PNG)
    │   ├── fx/          (5 个 PNG)
    │   ├── paradise/    (4 个 PNG)
    │   ├── player/      (4 个 PNG)
    │   ├── powerup/     (8 个 PNG)
    │   ├── warpedcore/   (4 个 PNG)
    │   └── helleye/      (5 个 PNG + 2 个 Shader) ★NEW★
    └── audio/           (10 WAV + 6 MP3)
```

---

## 三、场景入口与流程

### 主菜单 → 三个入口

```
MainMenu.tscn
├── 开始游戏 → main.tscn（正常关卡，9 种敌人生成）
├── Boss挑战  → BossSelect.tscn
│   ├── 星间巨构 → BossBattle.tscn
│   ├── 星海前锋 → BossBattle_Frontier.tscn
│   ├── 星尘重兵 → BossBattle_Heavy.tscn
│   ├── 星云巨构 → BossBattle_Nebula.tscn
│   ├── 天堂号   → BossBattle_Paradise.tscn
│   ├── 桃源乡   → BossBattle_PeachBlossom.tscn
│   ├── 乌托邦   → BossBattle_Utopia.tscn
│   └── 伊甸园   → BossBattle_Eden.tscn
└── 退出游戏 → get_tree().quit()
```

### BossBattle 场景通用结构

所有 8 个 BossBattle_*.tscn 共享完全一致的结构，仅 Boss 实体不同：

```
BossBattle (Node2D)
├── ScrollingBG      # 星空背景 (ScrollingBackground.gd)
├── Camera2D         # (480, 360)
├── player           # 玩家实例
├── [Boss实体]        # StarColossus / Paradise 等
├── BossHUD          # Boss 血条 CanvasLayer (layer=10)
└── HUD              # 玩家 HUD CanvasLayer
```

---

## 四、核心系统

### 4.1 GameManager（Autoload 单例）

**路径：** `scripts/GameManager.gd`  
**继承：** `Node`

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `score` | `int` | `0` | 得分 |
| `player_hp` | `int` | `100` | 玩家当前 HP |
| `PLAYER_MAX_HP` | `int` | `100` | 玩家最大 HP（常量） |
| `elapsed` | `float` | `0.0` | 累计游戏时间 |
| `bgm_player` | `AudioStreamPlayer` | 自动创建 | BGM 播放器 |

**方法：**

| 方法 | 签名 | 说明 |
|------|------|------|
| `_ready()` | → void | 创建 AudioStreamPlayer，加载 `bgm.mp3`，循环播放 |
| `_process(delta)` | float → void | 累加 elapsed |
| `add_score(amount)` | int → void | 增加得分 |
| `difficulty()` | → float | 返回 `clamp(elapsed/180, 0, 1)`，3 分钟后达到 1.0 |

### 4.2 卷动背景 (ScrollingBackground.gd)

- 使用两张 `starfield_bg.png` 交替滚动
- 速度 120 px/s，z_index = -100
- 精灵 scale = 1.5x，居中于 x=480

---

## 五、玩家系统

### Player.gd

**路径：** `scripts/Player.gd`  
**继承：** `Area2D`  
**分组：** `"player"`  
**碰撞：** layer=1（玩家），mask=2（检测 Boss）

#### 导出属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `speed` | `float` | `300` | 移动速度 px/s |
| `rotation_speed` | `float` | `8` | 转向平滑度 |
| `bullet_scene` | `PackedScene` | (必填) | 子弹场景 |
| `fire_rate` | `float` | `0.25` | 射击间隔（秒） |
| `atk` | `int` | `100`（场景覆盖） | 每发子弹伤害 |

#### 状态变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `invincible` | `bool` | 是否无敌 |
| `invincible_timer` | `float` | 无敌剩余时间 |
| `is_knocked_back` | `bool` | 是否处于击飞状态 |
| `knockback_speed` | `float` | 击飞速度 |
| `knockback_elapsed` | `float` | 击飞已过时间 |
| `knockback_duration` | `float` | 击飞持续时间 |

#### 主要方法

**每帧 (_process):**
- 管理无敌计时器，闪烁效果（visible 交替）
- 击飞状态下锁定操作，向下弹飞
- 正常状态：WASD 移动 + 射击时朝向鼠标旋转 + 射击 CD

`_shoot()` — 实例化子弹，方向朝前，偏移 50px 生成，播放射击音效

**受伤接口：**
- `take_damage_from(area: Area2D)` — 通用敌人伤害（子弹/碰撞），1s 无敌
- `take_damage_from_boss(dmg: int)` — Boss 直接伤害
- `take_knockback_damage(dmg, speed, duration)` — Boss 碰撞击飞伤害

**道具接口：**
- `apply_powerup_firerate()` — 射速 -0.05（最低 0.08s）
- `apply_powerup_atk()` — 攻击力 +1
- `apply_powerup_heal()` — 恢复 20 HP（上限 100）
- `apply_powerup_shield()` — 激活 5 秒无敌

**HP 归零：** `get_tree().change_scene_to_file("res://scenes/gameover.tscn")`

---

## 六、敌人系统

### 6.1 BaseEnemy.gd — 敌人基类

**路径：** `scripts/BaseEnemy.gd`  
**继承：** `Area2D`  
**分组：** `"enemies"`

#### 状态机

```
WARNING (2s) → MOVING (变量) → COOLDOWN (10s，后5s重入WARNING) → LEAVING (离屏) → queue_free
```

#### 导出属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `move_speed` | `float` | `300` | 移动速度 |
| `lifetime` | `float` | `30` | 存活总时间 |
| `move_cooldown` | `float` | `10` | 移动间隔 |
| `hp` | `int` | `10` | 生命值 |
| `damage` | `int` | `5` | 碰撞伤害 |
| `explosion_scale` | `float` | `0.5` | 死亡爆炸缩放 |

#### 关键方法

**路径预览 (_draw):**
- WARNING 状态下绘制红色/黄色交替脉冲矩形条
- 60 段渐变 alpha（5% 淡入，95% 淡出）
- 宽度动画：0 → 全宽（入场 0.5s），全宽 → 0（退出 0.5s）

**伤害与死亡：**
- `take_damage(amount)` — 扣血、更新血条、命中音效+抖动
- `_die()` — +100 分、爆炸音效、生成 `Explosion` VFX、生成 6-10 碎片（Debris）、queue_free
- `_spawn_debris()` — 碎片随机速度 80-280、旋转速度 -10~+10、随机纹理象限

**子类可覆盖钩子：**
- `_pick_path_target()` — 默认随机屏幕位置
- `_on_arrive()` — 到达目标时触发（默认空）

### 6.2 九种敌机详细参数

| 敌机 | HP | 速度 | 伤害 | 特殊行为 | 碰撞 | 旋转 |
|------|-----|------|------|---------|------|------|
| **Shooter（射击机）** | 20 | 300 | - | 瞄准玩家射击，±45°角度限制 | Capsule r=8 h=40 | 180° |
| **Rammer（撞击机）** | 30 | 1000 | 10 | 路径穿越玩家+延伸50-200px | Capsule r=8 h=40 | 0° |
| **Bomber（轰炸机）** | 10 | 800 | 10 | 飞越时每 0.1s 投弹 | Capsule r=9 h=44 | 0° |
| **Scatter（散射机）** | 20 | 300 | 3 | 5 发扇形散射 (-60°~+60°) | Capsule r=8 h=40 | 0° |
| **Suicide（自爆机）** | 10 | 300 | 10 | 死亡时 16 向环形爆弹，move_cooldown=300 | Capsule r=8 h=40 | 180° |
| **Healer（治疗机）** | 50 | 300 | 2 | 搜索受伤友军治疗 1HP/s，不治同行 | Capsule r=9 h=44 | 0° |
| **Chain（连射机）** | 20 | 300 | 3 | 66%概率连射，最多 10 发（0.1s间隔） | Capsule r=8 h=40 | 180° |
| **Missile（导弹机）** | 50 | 100 | 10 | 持续追踪玩家，每 0.5s 自损 1HP | Capsule r=8 h=40 | 180° |
| **Thrower（抛投机）** | 30 | 300 | 20 | 投掷定时炸弹（5s 飞行+引爆） | Capsule r=8 h=40 | 180° |

### 6.3 EnemySpawner.gd — 敌人生成器

**路径：** `scripts/EnemySpawner.gd`  
**继承：** `Node2D`  
**分组：** `"spawner"`

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enemy_scenes` | `Array[PackedScene]` | main.tscn 中预设 9 种 | 敌机场景列表 |
| `max_enemies` | `int` | `10` | 最大同时存在数 |
| `spawn_interval` | `float` | `2.0` | 生成间隔 |
| `paused` | `bool` | `false` | Boss 出场时设为 true |

生成逻辑：从屏幕上方/左/右三个方向随机出现，间隔随 `GameManager.difficulty()` 缩放（最低 0.4x）。

### 6.4 HealthBar.gd — 敌人血条

浮在世界空间中的血条，`_draw()` 绘制灰色背景+红色血条+黄色受击闪烁。  
绑定在敌人上方 40px 处。尺寸 40×5 px，闪烁持续 0.4s。

---

## 七、弹幕与道具系统

### 7.1 Bullet.gd（玩家子弹）

| 属性 | 值 |
|------|-----|
| 速度 | 1000 px/s |
| 碰撞形状 | Rectangle 8×24 |
| 检测分组 | `"enemies"` |
| 击中行为 | `area.take_damage(atk)` → queue_free |

### 7.2 EnemyBullet.gd（敌方子弹）

| 属性 | 值 |
|------|-----|
| 速度 | 500 px/s（可覆盖） |
| 碰撞形状 | Rectangle 6×18 |
| 检测分组 | `"player"` |
| 击中行为 | `player.take_damage_from(self)` → queue_free |
| 伤害 | 默认 5（可覆盖） |

### 7.3 Bomb.gd（炸弹）

| 属性 | 值 |
|------|-----|
| `explode_delay` | 默认 1.0s（Thrower 设 5s） |
| `damage` | 默认 10（Boss 技能设 30） |
| `explosion_radius` | 默认 150px（Boss 技能设 156px） |
| 飞行机制 | 若有 `travel_target`，先飞过去再倒数 |

视觉：红色脉冲警戒圈，炸弹 sprite 逐渐变大+变橙/红，爆炸时检测玩家距离。

### 7.4 PowerUp.gd（道具）

**枚举 Type：** `{ FIRERATE=0, ATK=1, HEAL=2, SHIELD=3 }`

所有 4 个道具场景使用同一脚本，通过 `power_type` 导出区分。

| 道具 | Type | 效果 |
|------|------|------|
| FireRate | 0 | `apply_powerup_firerate()` |
| ATK | 1 | `apply_powerup_atk()` |
| Heal | 2 | `apply_powerup_heal()` |
| Shield | 3 | `apply_powerup_shield()` |

速度 80 px/s 下落，碰撞形状 Circle r=14。

---

## 八、Boss 系统总览

### 架构模式

```
[Controller] (Node2D)          ← 技能主控、HP 管理
├── [Body] (BossBase/Area2D)   ← 身体碰撞体
├── [Arm/Part] (BossBase/Area2D) ← 手臂/部件碰撞体
└── ... (更多部件)
```

- Controller 继承 `Node2D`（非 Area2D），管理所有组件和技能
- 各部件继承 `BossBase`（Area2D），碰撞层 layer=2 mask=1
- 部件将伤害转发给 controller：`controller.apply_damage(amount)` → `boss_hp -= amount`
- 部件检测玩家碰撞：`player.take_knockback_damage(20, 1000, 0.5)`

### BossBase.gd

**路径：** `scripts/BossBase.gd`  
**继承：** `Area2D`  
**分组：** `"boss"`  
**碰撞：** layer=2, mask=1

核心属性：`controller: Node`，`boss_hp: int`（getter 代理到 controller.boss_hp）

`_on_area_entered(area)`：
- 如果是 Player → `take_knockback_damage(20, 1000, 0.5)`
- 如果 area 有 `atk` 属性（玩家子弹）→ `controller.apply_damage(area.atk)` + queue_free(area)

### BossHUD.gd — Boss 血条

**路径：** `scripts/BossHUD.gd`  
**CanvasLayer layer=10**，自动查找场景中的 Boss。

结构（BossHUD.tscn）：
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

---

## 九、Boss「星间巨构」详解

### 9.1 StarColossusController.gd

**路径：** `scripts/StarColossusController.gd`（999 行）  
**继承：** `Node2D`  
**场景：** `StarColossus.tscn`（几乎为空，仅设置 `combo_interval=2.0`）

#### 导出属性（亚种配置用）

| 属性 | 默认值 | 说明 |
|------|--------|------|
| `body_tex` | `boss_colossus_body_cutout.png` | 身体贴图 |
| `arm_tex` | `boss_colossus_arm_cutout.png` | 左臂贴图 |
| `arm_r_tex` | `boss_colossus_arm_r_cutout.png` | 右臂贴图 |
| `has_skill_1~6` | 全部 `true` | 各技能开关 |
| `max_hp` | `1000` | Boss 最大 HP |
| `boss_name` | `"星间巨构"` | 显示名称 |
| `skill_cooldown` | `2.0` | 技能间隔 |
| `combo_interval` | `3.0` | 连拳间隔 |

各技能伤害导出：`charge_aimed_dmg=5`, `charge_scatter_dmg=5`, `punch_dmg=50`, `burst_dmg=5`, `bomb_dmg=30`

#### 组件结构（_build_parts 动态创建）

```
StarColossusController (Node2D)
├── Body (Area2D, StarColossusBody.gd)
│   └── Sprite2D — boss_colossus_body_cutout.png, scale 0.7, z_index=50
│   └── CollisionShape2D — Rectangle 500×300
├── LeftArm (Area2D, StarColossusArm.gd)
│   └── Sprite2D — boss_colossus_arm_cutout.png, flip_h, scale 1.5, rotation +45°, z_index=30
│   └── CollisionShape2D — Rectangle 130×360
└── RightArm (Area2D, StarColossusArm.gd)
    └── Sprite2D — boss_colossus_arm_r_cutout.png, scale 1.5, rotation -45°, z_index=30
    └── CollisionShape2D — Rectangle 130×360
```

**三部件共享 1000 HP**（通过 `controller.boss_hp`）。

#### 进场动画（~5.5s）

4 阶段：SLIDE_IN(1s) → POSE(0.3s + 咆哮音效) → HOLD(3s 抖动 + 相机震动) → RETURN(0.3s)
- 黑幕覆盖（CanvasLayer layer=100），显示 Boss 名称
- BGM 切换到 `colossus_bgm.mp3`（180s 循环）

#### 闲置动画

- 身体：sin 旋转 ±0.03 rad，Y 偏移 ±8px
- 手臂：sin 旋转 ±0.04 rad
- 技能期间 `is_animating=true` 冻结闲置动画

#### 主动循环

`_process` 中调用 `await _skill_combo_burst()`（当前默认技能）。可在代码中手动切换：

```gdscript
# 切换调试不同技能：
await _skill_charge_attack()   # 技能1
await _skill_arm_punch(true)   # 技能2（左拳）
await _skill_quake()           # 技能3
await _skill_bomb()            # 技能4
await _skill_burst_punch(true) # 技能5
await _skill_combo_burst()     # 技能6（默认）
```

### 9.2 六大技能详解

#### 技能 1：蓄力冲击 + 弹幕 `_skill_charge_attack()`

| 阶段 | 时长 | 描述 |
|------|------|------|
| 蓄力 | 0.5s | 身体上移 50px（先快后慢） |
| 停顿 | 0.5s | 保持蓄力姿态 |
| 下冲 | 0.1s | 身体下压 100px |
| 弹幕 | 变量 | 50% 连发瞄准弹 / 50% 散射弹 |
| 归位 | 0.5s | 身体回原位 |

- 连发：5-10 发瞄准玩家，0.3s/发，弹速 500，伤害 5
- 散射：3-6 弹/轮，120°展开，1s 间隔，至少 3 轮

#### 技能 2：冲拳 `_skill_arm_punch(use_left: bool)`

| 阶段 | 时长 | 描述 |
|------|------|------|
| 蓄力 | 0.5s | 手臂向斜上方移 50px |
| 颤抖 | 2.5s | ±8px 抖动 + 红色/黄色交替警戒框脉冲 |
| 冲拳 | 变量 | 速度 4000，距离 1000px，每帧碰撞检测 |
| 归位 | 0.5s | 双臂回原位 |

- 警戒框：260px 宽矩形，末端 5% 渐变淡出
- 碰撞：玩家距手臂 <130px → 50 伤害（每拳一次）

#### 技能 3：地震 `_skill_quake()`

| 阶段 | 时长 | 描述 |
|------|------|------|
| 外张 | 0.5s | 双臂向外 + 身体下压 100px |
| 生成 | - | 屏幕外生成 5-10 导弹机/撞击机 |
| 颤抖 | 1s | 三部件抖动（2x 振幅）+ 相机震动 ±20px |
| 归位 | 0.5s | 全部复位 |

#### 技能 4：炸弹散布 `_skill_bomb()`

| 阶段 | 时长 | 描述 |
|------|------|------|
| 蓄力 | 1s | 同技能 1 蓄力动画 |
| 放置 | - | 8-12 枚 Bomb.tscn，画面下 1/3 均匀排布 |
| 爆炸 | 3s | 半径 156，伤害 30 |

- 50% 变体：炸弹上移 300px

#### 技能 5：冲拳 + 爆裂弹 `_skill_burst_punch(use_left: bool)`

完全继承技能 2 动画，冲拳到位后额外：
- 从手臂中点射出 10-20 发 360° 环形弹幕
- 弹速 300，伤害 5，子弹 scale 3.6x
- 左臂偏移 (+540, +540)，右臂 (-540, +540)

#### 技能 6：连拳爆裂弹 `_skill_combo_burst()` ★当前默认

| 参数 | 值 |
|------|-----|
| 起始 | 随机左/右 |
| 最少拳数 | 3 |
| 续拳概率 | 第 4 拳起 2/3 |
| 蓄力加速 | 拳1=0.5s → 拳2=0.3s → 拳3+=0.1s |
| 收回 | 异步 tween（0.5s），与下一拳蓄力并行 |
| 每拳 | 含爆裂弹（同技能 5） |

流程：`左/右充能 → 颤抖 → 冲拳+爆裂弹 → 异步收回 → 另一臂充能 → ...`

### 9.3 死亡系统

- `_die()` → 锁动画 → 变暗（0.35 亮度蓝调）→ 旋转掉落（身体 -15°，左臂 +10°，右臂 -8°）
- 死亡过程 5s：30-45 爆炸/秒 + 剧烈抖动（25-35px）+ 相机震动
- 结束后生成 20-30 最终爆炸 + 碎片 → queue_free → 2.5s 后回主菜单

### 9.4 子系统

**StarColossusBody.gd：** sin 呼吸晃动（旋转 ±0.03rad，Y±8px）  
**StarColossusArm.gd：** sin 摆动（旋转 ±0.04rad），支持 SIDE_LEFT/SIDE_RIGHT 枚举

---

## 十、星间巨构的三个亚种

通过继承 `StarColossusController` 并在 `_init()` 中覆盖配置实现。

### 星海前锋 (StarColossusFrontier.gd)

| 参数 | 值 |
|------|-----|
| 名称 | `"星海前锋"` |
| 贴图 | `boss_colossus_body/arm_cutout.png`（默认） |
| 技能冷却 | 3.0s |
| 可用技能 | 1, 2, 3 |
| 禁用技能 | 4, 5, 6 |

### 星尘重兵 (StarColossusHeavy.gd)

| 参数 | 值 |
|------|-----|
| 名称 | `"星尘重兵"` |
| 贴图 | `boss_frontier_body_final_cutout.png` / `boss_frontier_arm_final_cutout.png` |
| 技能冷却 | 2.0s |
| 可用技能 | 2, 3, 4, 5 |
| 禁用技能 | 1, 6 |

### 星云巨构 (StarColossusNebula.gd)

| 参数 | 值 |
|------|-----|
| 名称 | `"星云巨构"` |
| 贴图 | `boss_heavy_body_final_cutout.png` / `boss_heavy_arm_final_cutout.png` |
| 技能冷却 | 1.0s（最快） |
| 可用技能 | 2, 3, 4, 5, 6 |
| 禁用技能 | 1 |

> **注意：** 当前代码中，贴图文件名与 Boss 名称存在交叉：
> - 星尘重兵 (Heavy) 实际使用 `boss_frontier_*` 贴图
> - 星云巨构 (Nebula) 实际使用 `boss_heavy_*` 贴图
> - 星海前锋 (Frontier) 使用原版 `boss_colossus_*` 贴图
> 此分配为当前代码实际状态，如需调整可在各 `_init()` 中修改 `body_tex`/`arm_tex`/`arm_r_tex`。

---

## 十一、Boss「天堂号」详解

### 11.1 ParadiseController.gd

**路径：** `scripts/ParadiseController.gd`（1066 行）  
**继承：** `Node2D`  
**场景：** `Paradise.tscn`

#### 导出属性

| 属性 | 类型 | 默认值（TOP 停泊位） | 说明 |
|------|------|---------------------|------|
| `dock` | `enum` | `0` (TOP) | 停泊位：TOP/LEFT/RIGHT |
| `max_hp` | `int` | `1200` | Boss HP（可编辑） |
| `boss_name` | `String` | `"天堂号"` | 显示名称 |
| `body_tex` | `Texture2D` | 默认 | 机身贴图（导出，子类可覆写） |
| `cannon_tex` | `Texture2D` | 默认 | 机炮贴图（导出，子类可覆写） |
| `body_scale` | `Vector2` | `(0.8, -0.8)` | 机身缩放（Y 负值翻转） |
| `body_offset` | `Vector2` | `(0, -280)` | 机身相对旋转中心 |
| `pivot_offset` | `Vector2` | `(0, -100)` | 旋转中心相对停泊位 |
| `world_offset` | `Vector2` | `(0, 100)` | 整体偏移 |
| `cannon_0~3_pos` | `Vector2` | 见下 | 机炮相对位置 |
| `cannon_scale` | `Vector2` | `(-0.2, 0.2)` | 机炮缩放（X 负值翻转） |
| `sway_amplitude` | `float` | `30.0` | 待机摆动幅度 px |
| `sway_speed` | `float` | `1.5` | 待机摆动速度 |
| `skill_cooldown` | `float` | `2.0` | 技能冷却 |
| `has_skill_1~6` | `bool` | 全 `true` | 各技能开关 |
| `cannon_bullet_dmg` | `int` | `5` | 空闲机炮射击伤害 |
| `skill_1_bullet_dmg` | `int` | `5` | 技能1 子弹伤害 |
| `skill_2_bullet_dmg` | `int` | `5` | 技能2 子弹伤害 |
| `skill_4_laser_dmg` | `int` | `20` | 技能4 激光触碰伤害 |
| `skill_5_bullet_dmg` | `int` | `5` | 技能5 子弹伤害 |
| `skill_6_bullet_dmg` | `int` | `5` | 技能6 爆炸子弹伤害 |
| `skill_6_explosion_dmg` | `int` | `50` | 技能6 爆炸直接伤害 |

#### 默认机炮位置（TOP 停泊位）

| 机炮 | 位置 |
|------|------|
| Cannon1（左外） | `(-320, -80)` |
| Cannon2（左内） | `(-150, -30)` |
| Cannon3（右内） | `(150, -30)` |
| Cannon4（右外） | `(320, -80)` |

#### 组件结构（代码构建）

```
ParadiseController (Node2D)
├── BodySprite (Sprite2D)     — paradise_body_v4_cutout.png, z_index=60
├── PivotDot (ColorRect)       — 旋转中心调试标记 (z_index=999)
├── RingDrawer (Node2D)        — 技能3信号环 (z_index=500)
├── Cannon1 (Area2D/ParadiseCannon)
│   ├── Sprite2D — paradise_cannon_v2_cutout.png
│   └── CollisionShape2D — Circle r=40, z_index=45
├── Cannon2 (同上)
├── Cannon3 (同上)
├── Cannon4 (同上)
├── Laser1 (Line2D) — 红色激光 (width=3, alpha=0.5, z_index=-10)
├── Laser2
├── Laser3
└── Laser4
```

**BGM：** `paradise_bgm.mp3`（电音管风琴，180s）

#### 进场动画（~5.3s）

| 阶段 | 时间 | 描述 |
|------|------|------|
| 0 | 0-1s | 机身从 -300px 滑入 |
| 1 | 1-2s | 机炮从 -200px 滑入 |
| 2 | 2-2.5s | 停顿 |
| 3 | 2.5-2.8s | 激光闪烁射出 |
| 4 | 2.8-3.3s | 激光稳定追踪 |
| 5 | 3.3-5.3s | 黑幕 + Boss 名称 |
| 6 | 5.3s+ | 激活，开始战斗 |

#### 闲置行为

- 机身左右 (±30px) + 前后 (±7.5px) sin 摆动
- 4 门机炮持续追踪玩家，8±4s 冷却射击（bullet speed=500, damage=5, scale=1.84*2, z_index=-80）
- 4 条激光线始终延长到屏幕边缘指示射击方向

#### 主动技能循环

`has_skill_1~6`（默认全部 `true`）控制技能池。技能冷却归零后，从已启用的技能中随机抽取一个等概率执行：
```gdscript
# _process 中的调度逻辑
cooldown_remaining -= delta
if cooldown_remaining <= 0.0:
    var available = [1,2,3,4,5,6].filter(has_skill_*)
    var s = available[randi() % available.size()]
    match s:
        1: await _skill_1()
        2: await _skill_2()
        3: await _skill_3()
        4: await _skill_4()
        5: await _skill_5()
        6: await _skill_6()
    cooldown_remaining = skill_cooldown
```

技能执行完成后等待 `skill_cooldown`（默认 2s），然后随机选下一个。所有 6 个技能的伤害值和 `max_hp` 均暴露在 Godot 检查器面板中。

### 11.2 天堂号六大技能

#### 技能 1 `_skill_1()` — 全炮齐射

| 阶段 | 描述 |
|------|------|
| 炮塔上扬 | 4 门机炮 y+30 (0.3s) |
| 激光加粗 | width 6, alpha 0.3, 闪烁 0.3s |
| 高速射击 | 5-10s，射速 20x（0.05s间隔），30°扩散，小子弹 |
| 恢复 | 激光回归原状 → 炮塔归位 |

激光加粗期间触碰玩家造成 20 伤害（每 0.3s 判定一次）。

#### 技能 2 `_skill_2()` — 单炮掠袭

| 阶段 | 描述 |
|------|------|
| 选定 | 随机 1 门机炮 |
| 警戒 | 3s 条形警戒框（飞行路径） |
| 飞出 | 飞到底部，360-480°/s 旋转，每 0.05s 射击 |
| 飞回 | 同速返回原位 |

#### 技能 3 `_skill_3()` — 信号环换位 ★当前循环中

| 阶段 | 描述 |
|------|------|
| 信号环 | 机头放出 3 个扩散白环（错开 0.6s） |
| 飞出 | 关激光，飞出屏幕 |
| 换位 | 随机切换到不同停泊位 |
| 生成敌机 | 从另外两个方向生成 3-6 架敌机 |
| 滑入 | 从屏幕外 2.4s 滑入 |

#### 技能 4 `_skill_4()` — 激光扫射

| 阶段 | 描述 |
|------|------|
| 炮塔上扬 | y+30 |
| 锁定角度 | 4 门机炮同时锁定 135°（左下） |
| 激光加粗 | width=9 (3x)，alpha=0.8 |
| 扫射旋转 | 10s 内从 135° 匀速旋转到 45° |
| 激光紊乱 | 周期性闪烁加粗 + 玩家触碰检测（20 伤害/0.3s） |
| 恢复 | 激光闪烁关闭 → 炮塔归位 → 恢复追踪 |

#### 技能 5 `_skill_5()` — 多炮齐袭

| 阶段 | 描述 |
|------|------|
| 选定 | 随机 2-3 门机炮 |
| 警戒 | 全部同时显示条形警戒框 |
| 同时飞出 | 所有选定的机炮同时执行技能 2 的飞出-飞回模式 |

#### 技能 6 `_skill_6()` — 自爆突袭

| 阶段 | 描述 |
|------|------|
| 选定 | 随机 1 门机炮，关闭其碰撞（layer=0, mask=0, monitoring=false 防蓄力误伤） |
| 飞到中央 | 1.2s 用全局坐标飞到屏幕中央（LEFT/RIGHT 停泊位用 `to_local` 补偿旋转） |
| 蓄力 | 5s sin 曲线渐变闪烁（4→10Hz 加速），变大至 110%，400px 圆形警戒框 |
| 副炮掩护 | 其他 3 门机炮模仿技能1模式：y+30 + 激光加粗 + 20x 射速 30°扩散射击 |
| 爆炸 | 12-15 发 360° 环形子弹（伤害 5）+ 爆炸特效（scale 1.5, z_index 1000）+ 400px 内玩家受 50 爆炸伤害 |
| 瞬移 | 瞬移到 Boss 后方屏幕外（全局坐标） |
| 滑回 | 2s 滑回原位，恢复碰撞和追踪 |

> **已修复问题：** 蓄力闪烁从硬切换改为 sin 渐变；飞行方向用 `to_local/to_global` 处理 LEFT/RIGHT 旋转；蓄力期间关闭炮塔碰撞防止误伤；警戒圈与伤害判定统一为 400px。

### 11.3 ParadiseCannon.gd

**路径：** `scripts/ParadiseCannon.gd`  
**继承：** `Area2D`  
**碰撞：** layer=2, mask=1（同 BossBase）

| 属性 | 值 | 说明 |
|------|-----|------|
| `turn_speed` | `3.0` rad/s | 追踪旋转速度 |
| `tracking` | `true` | 是否追踪玩家 |

追踪逻辑：计算世界方向（减去父节点旋转补偿），平滑 lerp 朝向玩家。

碰撞：触碰玩家 → `take_knockback_damage(15, 800, 0.4)`；被子弹击中 → `get_parent().apply_damage(area.atk)`

### 11.4 天堂号受击与死亡

#### `apply_damage()` — 受击

参照星间巨构实现：
- 进场中/死亡中无视伤害
- 非致命时播放 `boss_hit.wav` 击打音效
- HP 归零时调用 `_die()`

#### `_die()` — 死亡动画（5 秒）

完全参照星间巨构的死亡系统：
1. **初始化：** 停 BGM → 恢复普通 BGM，压暗材质(0.35 蓝调)，关激光+停追踪
2. **5s 死亡过程：** 30-45次爆炸/秒（身体+4机炮部位）+ 碎片(3-6个/次) + 音效节流0.15s
3. **颤抖：** 机身±25px、机炮±35px、相机±15px 每帧随机偏移
4. **终结爆炸：** 20-30个爆炸原点 + 碎片(6-10个/次)
5. **返回：** queue_free → 2.5s → MainMenu

新增函数：`_death_process()`, `_spawn_death_explosion()`, `_spawn_final_explosion()`, `_spawn_debris()`, `_shake_parts()`, `_return_to_menu()`

> **改造说明：** 天堂号原先为简单 fade out，现已改为与星间巨构同级的完整死亡动画系统。

---

## 11-B、天堂号 3 个亚种

通过继承 `ParadiseController` 并在 `_init()` 中覆写配置实现，与星间巨构亚种模式一致。

### 桃源乡 (ParadisePeachBlossom.gd)

| 参数 | 值 |
|------|-----|
| 名称 | `"桃源乡"` |
| HP | `1000` |
| 技能冷却 | `3.0s` |
| 可用技能 | 1, 2, 3 |
| 禁用技能 | 4, 5, 6 |
| 材质 | 黑绿配色（图生图结果） |
| 脚本 | `scripts/ParadisePeachBlossom.gd` |
| Boss 场景 | `scenes/Paradise_PeachBlossom.tscn` |
| 战斗场景 | `scenes/BossBattle_PeachBlossom.tscn` |

### 乌托邦 (ParadiseUtopia.gd)

| 参数 | 值 |
|------|-----|
| 名称 | `"乌托邦"` |
| HP | `1000` |
| 技能冷却 | `2.0s` |
| 可用技能 | 1, 3, 4, 5 |
| 禁用技能 | 2, 6 |
| 材质 | 天堂号原版材质（默认） |
| 脚本 | `scripts/ParadiseUtopia.gd` |
| Boss 场景 | `scenes/Paradise_Utopia.tscn` |
| 战斗场景 | `scenes/BossBattle_Utopia.tscn` |

### 伊甸园 (ParadiseEden.gd)

| 参数 | 值 |
|------|-----|
| 名称 | `"伊甸园"` |
| HP | `1000` |
| 技能冷却 | `1.0s`（最快） |
| 可用技能 | 1, 3, 4, 5, 6 |
| 禁用技能 | 2 |
| 材质 | 黑金配色（图生图结果） |
| 脚本 | `scripts/ParadiseEden.gd` |
| Boss 场景 | `scenes/Paradise_Eden.tscn` |
| 战斗场景 | `scenes/BossBattle_Eden.tscn` |

### 纹理材质说明

亚种材质通过 base64 data URI 图生图生成，参考图为天堂号原版 cutout PNG：

| 亚种 | 机身纹理 | 机炮纹理 |
|------|---------|---------|
| 桃源乡 | `paradise_body_peach_cutout.png` | `paradise_cannon_peach_cutout.png` |
| 伊甸园 | `paradise_body_eden_cutout.png` | `paradise_cannon_eden_cutout.png` |
| 乌托邦 | 使用基类默认（天堂号原版） | 使用基类默认（天堂号原版） |

> **注意：** `ParadiseController.gd` 的 `body_tex` 和 `cannon_tex` 已改为 `@export var Texture2D` 类型，在 `_ready()` 中若为 null 才加载默认贴图。子类通过 `_init()` 设置 `preload` 即可覆盖。

---
## 十二、Boss「扭曲星核」详解

**脚本：** `scripts/WarpedCoreController.gd` (1689 行)  
**场景：** `scenes/WarpedCore.tscn` → `scenes/BossBattle_WarpedCore.tscn`  
**BGM：** `assets/audio/warpedcore_bgm.mp3`  
**材质：** `assets/images/warpedcore/warpedcore_body_cutout.png` + `warpedcore_orbiter_cutout.png`

扭曲星核是一颗脉动的能量核心，带有 4 颗环绕小球、红移/蓝移相对论重影、布朗运动怠速模式，以及 6 个主动技能。

### 12.1 核心组件

| 组件 | 说明 |
|------|------|
| `body_sprite` | 脉动主体（0.1x 缩放），带红色/蓝色偏移重影（relativistic shift） |
| `orbiter_data` (x4) | 环绕小球，默认半径 100px，缩放 0.05，带碰撞体，拖尾 6 层 |
| `_dock` | 4 停泊位（HOME/LEFT/RIGHT/BOTTOM），用于技能 1 冲刺 |
| 布朗运动 | 怠速时在 `_home_position` 周围随机移动（最大半径 100px） |

### 12.2 六大技能

| # | 名称 | 时长 | 核心机制 |
|---|------|------|----------|
| 1 | 停泊位转移 | ~6s | 3s 警戒 → 冲刺 → 停顿 1s |
| 2 | 轨道扩张 | ~20s | 半径+速度 1→3x 扩大再回归，前方警戒环 |
| 3 | 咆哮+召唤 | ~3.25s | 0.25s 膨胀 → 3s 震动 + 依次召唤敌机 |
| 4 | 强吸力咆哮 | ~10.25s | 0.25s 膨胀 → 10s 吸力，白条涌入+残骸吸入 |
| 5 | 十字激光连射 | ~8-12s | 20-30 球从核心出发→蓄力爆破→紫色十字延伸屏外 |
| 6 | 连续冲刺 | ~15-30s | 8-12 次朝向玩家冲刺，警戒 2→1s 递减，末尾技能1 |

### 12.3 AI 增强

- 记录 `_last_skill`，场上敌机 ≤3 时优先释放技能 3（咆哮召唤）
- 所有亚种自动继承此 AI

### 12.4 技能调度

```
冷却就绪 → has_skill_3且_last_skill≠3且敌机≤3? → 强制技能3
                                         否则 → 随机
```

### 12.5 进场动画（5 阶段）

| 阶段 | 时长 | 效果 |
|------|------|------|
| 0 | 0-0.25s | 背景缩放 + 主体 pulse_mult 归位 |
| 1 | 0.25-2.25s | 主体 + 4 小球逐个滑入 |
| 2 | 2.25-4.25s | 黑幕 2s，boss_name 显示 |
| 3 | 4.25-5.25s | 黑幕消退 |
| 4 | 5.25s+ | 激活战斗 |

### 12.6 受击与死亡

- **受击：** `apply_damage()` 扣血 + 闪白 (body+重影 WHITE 0.05s) + boss_hit 音效
- **死亡：** 5s 爆炸序列，30-45 次/秒爆炸，小球纹理碎片，相机抖动，终结大爆炸 → 2.5s 回主菜单

---
## 12-B、扭曲星核 3 个亚种

通过继承 `WarpedCoreController` 并在 `_ready()` 中覆写配置：

| # | 名称 | HP | 冷却 | 技能 | 纹理 |
|---|------|-----|------|------|------|
| 10 | **异变源石** | 1000 | 3s | 1,2,3 | 原版扭曲星核 |
| 11 | **诡异菌孢** | 1000 | 2s | 1,2,3,4 | 墨绿菌类（AI 生成→抠图） |
| 12 | **反物质核** | 1000 | 1s | 6,2,3,4,5 | 负片扭曲（AI 生成→抠图） |

**脚本：** `scripts/VariantSource.gd` / `VariantSpore.gd` / `VariantAnti.gd`  
**场景：** `scenes/VariantSource.tscn` 等 3 个 + `BossBattle_*.tscn` 3 个

**关键：** 子类必须在 `super._ready()` 前设置 `boss_name = "异变源石"`，否则黑幕会显示父类默认名。

### 材质生成流程

```
原版扭曲星核 .png
  → packAI /v1/images/edits (图生图，reference image)
  → techsz segmentation API (抠图去背景)
  → 保存为 *_cutout.png
```

纹理位置：`assets/images/warpedcore/spore_body_cutout.png`, `spore_orbiter_cutout.png`, `anti_body_cutout.png`, `anti_orbiter_cutout.png`

---

## 十三、Boss「地狱之眼」详解 ★NEW★ (v2.23)

**脚本：** `scripts/HellEyeController.gd` (334 行)  
**场景：** `scenes/HellEye.tscn` → `scenes/BossBattle_HellEye.tscn`  
**BGM：** `assets/audio/hell_eye_boss_bgm.mp3`  
**材质：** `assets/images/helleye/` 目录（5 PNG + 2 Shader）

地狱之眼继承 `WarpedCoreController`，取消了所有环绕小球和现有技能（待重做），专注于独特的 Shader 裁剪视觉效果和眼睛动画系统。

### 13.1 视觉层级

三层叠加渲染（z_index 从低到高）：

| 层 | 节点 | z_index | 说明 |
|----|------|---------|------|
| 描边 | `_stroke_sprite` | 43 | 黑色抖动轮廓，持续形变 |
| 星云 | `_nebula_sprite` | 44 | 红色星云，经 eye_clip shader 裁剪 |
| 眼珠 | `body_sprite` | 45 | 眼球，经 eye_clip shader 裁剪 |

### 13.2 Shader 裁剪系统

**文件：** `assets/images/helleye/eye_clip.gdshader`

使用 `mask_alpha.png` 的 alpha 通道裁剪内容渲染：

```gdshader
shader_type canvas_item;
uniform sampler2D mask_tex;        // 眼形遮罩
uniform vec2 mask_scale;           // 遮罩缩放（值越大越小）
uniform float mask_rotation;       // 遮罩旋转
uniform vec2 mask_offset_uv;       // 遮罩偏移
uniform vec2 content_scale;        // 内容缩放（独立）
uniform vec2 content_offset;       // 内容偏移

void fragment() {
    // UV → 旋转 → 缩放 → 偏移 → 采样 mask alpha
    vec2 centered = UV - 0.5;
    float cr = cos(mask_rotation); float sr = sin(mask_rotation);
    vec2 rotated = vec2(centered.x*cr - centered.y*sr, centered.x*sr + centered.y*cr);
    vec2 mask_uv = clamp(rotated * mask_scale + 0.5 + mask_offset_uv, 0.0, 1.0);
    float mask_a = texture(mask_tex, mask_uv).a;
    // 内容独立缩放 + 偏移
    vec2 tex_uv = (UV - 0.5) * content_scale + 0.5 + content_offset;
    vec4 c = texture(TEXTURE, tex_uv);
    COLOR = vec4(c.rgb, c.a * mask_a);
}
```

**关键**：mask_scale 用乘法 = 值越大遮罩越小；content_scale 用乘法 = 值越大眼珠越小。两者独立控制。

### 13.3 眼睛动画状态机

三种主要动作，循环执行，每次完成后回归正常（0.6s）：

| 动作 | 时长 | 遮罩Y | 眼珠Content | 额外效果 |
|------|------|-------|------------|---------|
| **睁大** (WIDE) | 2.5s | → 2.0x | → 1.4286x (70%) | 眼珠颤动 ±15px + 追踪玩家 |
| **眯眼** (SQUINT) | 1.8s | → 0.3x | → 1.0x | 无 |
| **眨眼** (BLINK) | 0.35s | 1.0→0.04→1.0 | → 1.0x | 前半合后半张 |
| **正常** (NORMAL) | 0.6s | → 1.0x | → 1.0x | 过渡 |

循环顺序：`WIDE → NORMAL → SQUINT → NORMAL → BLINK → NORMAL → WIDE...`

**核心变量**：`_eye_y_mult`（遮罩Y缩放）、`_eyeball_content_mult`（眼珠内容缩放）、`_eye_action`（当前动作）、`_eye_is_returning`（回归标志）

### 13.4 呼吸动画

待机状态下遮罩 Y 以 3s 周期在 75%~125% 正弦波呼吸：
```gdscript
const BREATH_PERIOD: float = 3.0
const BREATH_MIN: float = 0.75
const BREATH_MAX: float = 1.25
```

### 13.5 描边系统

描边用 `mask_alpha.png` 直接作为 Sprite2D 显示，通过 `_apply_stroke_jitter()` 每帧计算抖动：
- **位置抖动**：频率 11/17+13/19 Hz 多频组合，幅度 = `mask_stroke_jitter`
- **缩放抖动**：频率 7/9+8/11 Hz，幅度 ±8%
- **旋转抖动**：频率 14+10 Hz，幅度 ±0.03rad
- 旋转方向为 `-rot`（与遮罩相反，确保对齐）

### 13.6 进场动画（7 阶段，~6.5s）

| 阶段 | 时间 | 效果 |
|------|------|------|
| 0 | 0-1.5s | 从顶部 ease-out 滑入 |
| 0b | 0.5s | BGM 切换 |
| 1 | 1.8-1.9s | 瞪大眼 (0.1s, Y→2.0) + ROAR_SFX + 轻颤 |
| 1b | 1.9-2.5s | 保持瞪大 + content 70% + 轻颤 |
| 2 | 2.5-4.5s | 黑幕 2s + 瞪大(70%) + 强颤(±8,±5) |
| 3 | 4.5-5.5s | 黑幕淡出 + 强颤 |
| 4 | 5.5-6.5s | 1s 后回归正常 Y=1.0 + 停颤 |
| 5 | 6.5s+ | 激活战斗：entering=false, active=true, cooldown=0.5s |

**注意**：`_entrance_process` 每帧调用 `_idle_animation(delta)` 确保描边抖动全程生效。

### 13.7 检查器参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `mask_scale` | `Vector2` | `(0.18, 0.18)` | 遮罩大小（值越大越小） |
| `mask_rotation_deg` | `float` | `0.0` | 遮罩旋转角度 |
| `nebula_scale` | `Vector2` | `(0.27, 0.27)` | 星云缩放 |
| `nebula_offset` | `Vector2` | `(0, 0)` | 星云偏移 |
| `eyeball_scale` | `Vector2` | `(0.18, 0.18)` | 眼珠缩放 |
| `eyeball_offset` | `Vector2` | `(0, 0)` | 眼珠偏移 |
| `mask_stroke_thickness` | `float` | `3.0` | 描边粗细 |
| `mask_stroke_jitter` | `float` | `1.5` | 描边抖动幅度 |
| `mask_stroke_color` | `Color` | `BLACK` | 描边颜色 |

### 13.8 技能状态

**所有 6 个技能均关闭**（`has_skill_1~6 = false`），技能功能待重做。Boss 具备技能框架（继承自 WarpedCoreController），可随时添加。

### 13.9 纹理与资源

| 文件 | 类型 | 用途 |
|------|------|------|
| `mask_alpha.png` | PNG | 眼形遮罩（alpha 通道 = 裁剪形状） |
| `mask_raw.png` | PNG | 遮罩原图（AI 生成） |
| `nebula_raw.png` | PNG | 红色星云（1024² AI 生成） |
| `eyeball_cutout.png` | PNG | 眼球（AI 生成 + 抠图去背景） |
| `eyeball_raw.png` | PNG | 眼球原图 |
| `eye_clip.gdshader` | Shader | 裁剪着色器 |
| `eye_mask_shader.gdshader` | Shader | 亮度→alpha 着色器（备用） |
| `hell_eye_boss_bgm.mp3` | MP3 | 战斗 BGM |
| `hell_eye_boss_bgm_2.mp3` | MP3 | BGM 备选 |

---

## 十四、视觉特效系统

### Explosion.gd

- SpriteSheet 帧动画：6 帧 × 0.07s/帧，3388×2476 的大图
- Tween 淡出后 queue_free

### Debris.gd

- 随机方向/速度/旋转的碎片
- Tween 淡出（1s）→ queue_free
- 100px 超出屏幕时自动清理

### RingDrawer.gd

- 为天堂号技能 3 绘制的扩散信号环
- 颜色从白渐变到蓝色，alpha 在中点峰值

---
## 十五、UI 系统

### MainMenu.gd

三个按钮：开始游戏 → `main.tscn`，Boss挑战 → `BossSelect.tscn`，退出游戏 → `quit()`

### BossSelect.gd

13 个 Boss 按钮 + 返回按钮（共 14 个按钮）：

| 按钮 | 场景 |
|------|------|
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

### GameOver.gd

最终得分显示 + 重新开始按钮 → `main.tscn`

### HUD.gd + LifeBar.gd

- HUD (CanvasLayer)：分数标签 + 生命条
- LifeBar (Node2D)：双色血条（红色底 + 黄色上层受击闪缩）
- 素材：`hud_score_panel.png`，`hud_lifebar_frame.png`

---

## 十六、资源清单

### 14.1 PNG 素材（59 个）

#### Boss 素材（20 个）

| 文件 | 用途 |
|------|------|
| `boss_colossus_body[_cutout].png` | 星间巨构身体 |
| `boss_colossus_arm[_cutout].png` | 星间巨构左臂 |
| `boss_colossus_arm_r[_cutout].png` | 星间巨构右臂 |
| `boss_frontier_body_final_cutout.png` | 星云巨构身体 |
| `boss_frontier_arm_final_cutout.png` | 星云巨构手臂 |
| `boss_heavy_body_final_cutout.png` | 星尘重兵身体 |
| `boss_heavy_arm_final_cutout.png` | 星尘重兵手臂 |
| `boss_nameplate_cutout.png` | Boss 名牌底框 |
| `boss_hp_frame.png` | Boss 血条外框 |
| `hud_lifebar_frame.png` | 玩家血条框 |
| `hud_score_panel.png` | 分数面板 |
| `punch_wind[_cutout].png` | 冲拳风效 |

#### 敌机素材（18 个，9× 普通+cutout）

`enemy_shooter`, `rammer`, `bomber`, `scatter`, `suicide`, `healer`, `chain`, `missile`, `thrower` — 各含普通版和透明版。

#### 天堂号素材（4 个）

| 文件 | 用途 |
|------|------|
| `paradise_body_v4[_cutout].png` | 后掠翼轰炸机机身 |
| `paradise_cannon_v2[_cutout].png` | 机炮塔 |

#### 玩家素材（4 个）

`player_ship[_cutout].png`, `bullet[_cutout].png`

#### 道具素材（8 个）

`powerup_firerate[_cutout].png`, `atk[_cutout].png`, `heal[_cutout].png`, `shield[_cutout].png`

#### 特效素材（5 个）

`bomb_icon[_cutout].png`, `debris.png`, `explosion.png`, `starfield_bg.png`

### 14.2 音频（13 个）

**BGM（4 个 MP3）：**

| 文件 | 时长/大小 | 用途 |
|------|----------|------|
| `bgm.mp3` | 3.4 MB | 正常关卡 |
| `colossus_bgm.mp3` | 4.0 MB | 星间巨构（工业风） |
| `paradise_bgm.mp3` | 4.0 MB | 天堂号（电音管风琴） |
| `warpedcore_bgm.mp3` | 4.0 MB | 扭曲星核（低音脉冲） |

**音效（10 个 WAV）：**

| 文件 | 用途 |
|------|------|
| `shoot.wav` | 玩家射击 |
| `player_hurt.wav` | 玩家受伤 |
| `enemy_hit.wav` | 敌人受击 |
| `explosion.wav` | 爆炸 |
| `boss_hit.wav` | Boss 受击 |
| `boss_roar.wav` | Boss 咆哮 |
| `bomb_drop.wav` | 炸弹投掷 |
| `bomb_explode.wav` | 炸弹爆炸 |
| `cannon_move.wav` | 机炮移动 |
| `laser_zap.wav` | 激光音效 |

---

## 十七、碰撞层级与分组

### 碰撞层

| 层 | 归属 | 说明 |
|----|------|------|
| 1 | 玩家 | layer=1 |
| 2 | Boss 部件 | layer=2, mask=1（只检测玩家和玩家子弹） |

### 分组

| 组名 | 成员 | 用途 |
|------|------|------|
| `"player"` | Player | 敌人/Boss 检测目标 |
| `"enemies"` | 所有 BaseEnemy 子类 | 玩家子弹检测目标 |
| `"boss"` | 所有 BossBase 子类 | 统一管理 |
| `"spawner"` | EnemySpawner | 外部暂停控制 |

---

## 十八、伤害传递流程

```
玩家子弹 (Bullet.gd, atk)
  ├── 命中 "enemies" 组 → area.take_damage(atk) → BaseEnemy.take_damage()
  └── 命中 "boss" 组 → controller.apply_damage(area.atk) → boss_hp -= amount

敌方子弹 (EnemyBullet.gd, damage)
  └── 命中 "player" 组 → player.take_damage_from(self) → HP -= damage

Boss 技能伤害
  ├── player.take_damage_from_boss(dmg) — 直接伤害
  └── player.take_knockback_damage(dmg, speed, dur) — 碰撞击飞

敌人碰撞玩家
  └── BaseEnemy._on_area_entered() → 直接扣 HP + self-destruct
```

### 生命条更新链

```
GameManager.player_hp 变化
  └── LifeBar.gd._process() 检测 → 更新红条+黄条闪烁

boss_hp 变化
  └── BossHUD.gd._process() 检测 → 更新红条+黄条闪烁

敌人 HP 变化
  └── HealthBar.gd.take_hit() → 更新红条+黄条闪烁
```

---

## 十九、开发约定

1. **非侵入式开发**：只增新文件，不改原有项目文件
2. **素材命名**：`xxx_cutout.png` 为透明背景 PNG，`xxx.png` 为带背景的原图
3. **Boss 组件在代码中构建**（`_build_parts()`），不在场景中预设子节点（天堂号的 BodySprite 除外）
4. **路径格式**：Windows 风格 `E:\GoDot Project\打飞机游戏\`
5. **交流语言**：中文，反馈问题时附带完整错误信息 + 堆栈
6. **每次修改后需重启 Godot** 以重载脚本和导入缓存
7. **任务通知**：通过 task-completion-notify skill 发送简短 Windows 通知
8. **BossHUD 调整**：只拖动 HBox 和 NamePlate/NameLabel 调整位置，不动子节点
9. **Boss 贴图关键数据**：
   - 星间巨构身体：scale 0.7，碰撞 500×300
   - 星间巨构手臂：scale 1.5，碰撞 130×360
   - 天堂号机身：`body_scale=(0.8, -0.8)`，z_index=60
   - 天堂号机炮：`cannon_scale=(-0.2, 0.2)`，碰撞 r=40，z_index=45
10. **资产目录结构**（2026-05-11 重构）：原始 `assets/images/` 扁平结构重构为子目录：
    - `assets/images/boss/` — Boss 相关贴图
    - `assets/images/enemy/` — 敌人贴图
    - `assets/images/fx/` — 特效（爆炸/碎片/炸弹图标/星空背景）
    - `assets/images/paradise/` — 天堂号及其亚种材质
    - `assets/images/player/` — 玩家+子弹
    - `assets/images/powerup/` — 道具
    - 所有 `.tscn` 文件已更新指向新路径。新增 `assets/audio/` 中 `cannon_move.wav`、`laser_zap.wav`、`paradise_bgm.mp3`

## 二十、天堂号死亡中断技能机制（2026-05-11）

Boss 在技能执行中死亡时，技能协程继续运行（子弹、炮塔移动、特效不停止），因为 `_die()` 设 `dying=true` 但已飞行的 `await` 协程不检查此标志。

### 修复方案（ParadiseController.gd）

1. **`_skill_tweens: Array[Tween]`**（第100行）— 追踪所有技能 Tween
2. **`_make_tween()`**（第191-198行）替代直接 `create_tween()`，死亡时自动 `kill()` 返回死 Tween
3. **`_die()` 增强**（第1198-1229行）：
   - 遍历 `_skill_tweens` 全部 `kill()`
   - 设置 `is_executing = false`
   - 所有炮塔：`tracking=false`、`set_process(false)`、`monitoring=false`、`collision_layer/mask=0`
4. **6 个技能入口守卫**：每个技能函数开头检查 `if dying: is_executing = false; return`
5. **所有 while 循环守卫**：技能内长时间循环中 `if dying: break`
6. **集中防护**：`_fire_cannon()` 和 `_spawn_skill2_bullet()` 均检查 `if dying: return`
7. 3 个亚种（桃源乡/乌托邦/伊甸园）继承 `ParadiseController`，自动受益


---

## 二十、当前进度

| 模块 | 状态 | 备注 |
|------|------|------|
| 玩家系统 | ✅ 完成 | 移动/射击/受伤/无敌/击飞/道具 |
| 9 种敌人 | ✅ 完成 | Shooter, Rammer, Bomber, Scatter, Suicide, Healer, Chain, Missile, Thrower |
| 敌人生成器 | ✅ 完成 | 基于难度缩放 |
| 主菜单 + 选择 + 结算 | ✅ 完成 | 13 Boss 入口（4 星间巨构系 + 4 天堂号系 + 4 扭曲星核系 + 1 地狱之眼） |
| HUD（玩家 + Boss） | ✅ 完成 | 双色闪烁血条 |
| 卷动背景 | ✅ 完成 | 星空调速 120 px/s |
| 道具系统 | ✅ 完成 | 4 种道具 |
| 炸弹系统 | ✅ 完成 | 飞行+倒计时+爆炸 |
| **星间巨构 Boss** | ✅ 完成 | 技能 1-6 全部完成 |
| **星间巨构亚种** | ✅ 完成 | 星海前锋/星尘重兵/星云巨构（3 个） |
| **天堂号 Boss** | ✅ 完成 | 场景+进场+6技能随机调度+完整死亡动画 |
| **天堂号技能 1-6** | ✅ 完成 | 全部接入随机调度，伤害值暴露在检查器 |
| **天堂号受击+死亡** | ✅ 完成 | 参照星间巨构，5s 爆炸死亡动画 |
| **天堂号亚种** | ✅ 完成 | 桃源乡/乌托邦/伊甸园（3 个，含图生图材质） |
| **扭曲星核 Boss** | ✅ 完成 | 进场+6技能+AI（敌机≤3强制技能3）+完整死亡动画 |
| **扭曲星核亚种** | ✅ 完成 | 异变源石/诡异菌孢/反物质核（3 个，AI 生成材质+抠图） |
| **地狱之眼 Boss** ★NEW★ | ✅ 完成 | Shader裁剪+眼睛动画+描边+呼吸+进场，技能待重做 |

### 天堂号所有技能伤害值（检查器可调）

| 伤害变量 | 默认值 | 说明 |
|---------|--------|------|
| `cannon_bullet_dmg` | 5 | 空闲机炮 |
| `skill_1_bullet_dmg` | 5 | 技能1/技能6副炮 |
| `skill_2_bullet_dmg` | 5 | 技能2 |
| `skill_4_laser_dmg` | 20 | 技能4 激光 |
| `skill_5_bullet_dmg` | 5 | 技能5 |
| `skill_6_bullet_dmg` | 5 | 技能6 子弹 |
| `skill_6_explosion_dmg` | 50 | 技能6 爆炸 |
| `max_hp` | 1200 | Boss HP |

### 快速测试指南

1. 用 Godot 4.6 打开 `project.godot`
2. F5 运行 → 主菜单 → Boss挑战 → 选择任意 Boss
3. 测星间巨构：在 `StarColossusController._process()` 中切换 `await _skill_xxx()`
4. 测天堂号：在 `ParadiseController._process()` 中通过 `has_skill_1~6` 开关控制技能池
5. `BossHUD.tscn` 可拖拽调整血条位置
6. `Paradise.tscn` 的 `dock` 下拉可切换 LEFT/TOP/RIGHT

> 文档最后更新：2026-05-13（v2.22 — 扭曲星核 + 3 亚种 + AI 系统）**

---

*本文档基于 2026-05-11 全项目遍历生成，覆盖 43 个脚本、40 个场景、72+ 个素材文件。*
*如发现与代码实际状态不符之处，以代码为准。*
