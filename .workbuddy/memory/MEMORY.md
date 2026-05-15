# 长期记忆 - 打飞机游戏项目

## 项目约定
- Godot 4.6，960×720，D3D12 渲染，Jolt 物理
- **非侵入式开发**：只增文件，不改原有项目文件
- 素材命名：`xxx_cutout.png` 为透明背景 PNG
- Boss 组件在代码中构建（`_build_parts()`），不在场景中预设
- Windows 路径格式
- 用户使用中文交流，反馈时带错误堆栈

## 进度总览（2026-05-11 更新）

### 已完成
- 玩家系统（移动/射击/受伤/无敌/击飞/道具）
- 9 种敌人（Shooter, Rammer, Bomber, Scatter, Suicide, Healer, Chain, Missile, Thrower）
- 敌人生成器（难度缩放）
- 主菜单 + Boss选择（8个入口）+ 结算界面
- HUD（玩家+Boss双色闪烁血条）
- 卷动星空背景
- 道具系统（4种）+ 炸弹系统
- 星间巨构 Boss（技能1-6全部完成）
- 星间巨构 3 个亚种（星海前锋/星尘重兵/星云巨构）
- 天堂号 Boss（场景+进场+BGM+6技能随机调度+死亡动画）
- 天堂号 3 个亚种（桃源乡/乌托邦/伊甸园，含图生图材质）

### 无待完成工作

## Boss 血条系统（2026-05-08 重构）
- **素材**：`boss_hp_frame.png` / `boss_nameplate_cutout.png`（AI 生成）
- **场景**：`BossHUD.tscn` — CanvasLayer(layer=10)
  - 节点结构：NamePlate → NameLabel | HBox → Frame + RedBar + FlashBar
  - Frame 比 RedBar 四边大 10-15px 形成边框
  - **只拖动 HBox 和 NamePlate/NameLabel 调整位置，不要动子节点**
- **脚本**：`BossHUD.gd` — 自动查找 Boss，连续扣血累计黄色闪烁
- **闪烁逻辑**：`flash_from_hp` 保持最早受击 HP，黄色条从完整伤害宽度线性缩短至 0（0.6s）

## 天堂号 Boss（2026-05-09 → 2026-05-11）
- **材质**：`paradise_body_v4_cutout.png`（后掠翼轰炸机）、`paradise_cannon_v2_cutout.png`（机炮塔）
- **接口**：Dock 枚举（TOP/LEFT/RIGHT），`@export_enum` 下拉切换
- **TOP 停泊位默认数据**（Paradise.tscn）：
  - `body_scale = (0.8, -0.8)`、`body_offset = (0, -280)`
  - `cannon_scale = (-0.2, 0.2)`
  - 机炮位置：左外(-320,-80)、左内(-150,-30)、右内(150,-30)、右外(320,-80)
- **层级**：机身 z_index=60 > 机炮 z_index=45
- **BGM**：`paradise_bgm.mp3`（电音管风琴，180s）

### 天堂号技能系统（2026-05-11）
- 6 技能全部完成，随机调度（等概率从已启用技能池抽取）
- `has_skill_1~6` 开关控制，`skill_cooldown=2.0s`
- 所有伤害值暴露在检查器：`cannon_bullet_dmg`, `skill_1~6_bullet_dmg`, `skill_4_laser_dmg`, `skill_6_explosion_dmg`
- `max_hp=1200` 也暴露在检查器

### 天堂号技能6修复记录（2026-05-11）
- 蓄力闪烁：硬切换→sin 曲线渐变（4→10Hz）
- 飞行方向：LEFT/RIGHT 停泊位用 `to_local/to_global` 处理旋转
- 蓄力期间炮塔碰撞关闭（layer=0, mask=0, monitoring=false）
- 蓄力期间其他炮塔模仿技能1模式
- 爆炸特效 z_index=1000，scale=1.5

### 天堂号受击与死亡（2026-05-11）
- 参照星间巨构：5s 爆炸死亡动画，30-45次/秒爆炸+碎片+颤抖+相机震动
- 终结爆炸 20-30 原点，2.5s 后回主菜单
- 非致命击打播放 `boss_hit.wav`

### 天堂号死亡中断技能机制（2026-05-11）
- **Bug**：Boss 技能执行中死亡，协程继续运行
- **修复**（ParadiseController.gd）：
  - `_skill_tweens: Array[Tween]` 追踪所有技能 Tween
  - `_make_tween()` 替代 `create_tween()`，死亡时自动 kill
  - `_die()` 强制 kill 全部 Tween、设 `is_executing=false`、停所有炮塔（tracking/process/monitoring/collision）
  - 6 技能入口 + while 循环 + `_fire_cannon()/_spawn_skill2_bullet()` 均检查 `if dying`
  - 3 亚种继承自动受益

### 资产目录重构（2026-05-11）
- 原始 `assets/images/` 扁平结构 → 子目录：boss/, enemy/, fx/, paradise/, player/, powerup/
- 所有 .tscn 路径已更新

### 材质重新生成（2026-05-11）
- 桃源乡和伊甸园材质通过图生图重新生成（修复尺寸和形状问题）
- 参考原版天堂号，仅换色，保持俯视图结构

### 天堂号 3 个亚种（2026-05-11）
| 亚种 | HP | 冷却 | 技能 | 配色 |
|------|-----|------|------|------|
| 桃源乡 | 1000 | 3s | 1,2,3 | 黑绿（图生图） |
| 乌托邦 | 1000 | 2s | 1,3,4,5 | 原版 |
| 伊甸园 | 1000 | 1s | 1,3,4,5,6 | 黑金（图生图） |

- 材质通过 base64 data URI 图生图+抠图生成
- `ParadiseController` 的 `body_tex`/`cannon_tex` 改为 `@export Texture2D`，null 时加载默认

## BossSelect 界面
- 8 个按钮：星间巨构/星海前锋/星尘重兵/星云巨构/天堂号/桃源乡/乌托邦/伊甸园
- 紧凑排列，scroll down 全部可见
