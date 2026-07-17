# 数值与机制改造实施计划

> 日期：2026-07-15  
> 最后更新：2026-07-16  
> 依据：[数值与机制总策划案](../specs/2026-07-15-balance-and-mechanics-design.md)  
> 目标：将“休闲求胡、机制叠加起飞”的体验落入现有 Godot 4.6 项目，完成事件、奖励、信标内容系统，并建立可重复验证的数值基准。

## 执行约束

- 所有命令必须以 `rtk` 开头。
- 当前工作区存在用户未提交修改，尤其涉及 `RunManager.gd`、`Player.gd`、`ExploreRoom.gd`、`SupportDrone.gd`、商店/机库 UI 与相关测试。执行者必须先查看 `rtk git diff -- <file>`，逐处合并，不得覆盖或回退用户修改。
- 每个任务先写失败检查，再实现，再运行相关既有检查。
- 不允许一次性重写全部装备目录；先完成纵向样板，确认事件谱系、性能与手感后再批量迁移。
- 新的静态定义优先使用只读 Resource；玩家可写元进度使用 JSON。
- 每项 Godot 实现任务开始前，必须读取本任务列出的 GodotPrompter 技能；完成后使用 `godot-code-review` 复核。
- 本计划第 1–14 个 Task 是功能与验收待办，不是可以直接并行派发的工作组。真正的 Agent 派发单元以文末“Agent 工作组”章节为准；若文件清单冲突，以工作组的独占/禁止文件边界为最高优先级。
- `scripts/core/RunManager.gd`、`scripts/app/WorldMap.gd`、`project.godot` 只允许共享基础与集成组修改。其他工作组发现接口不足时提交集成请求，不得自行补丁这些中央文件。

## 总体架构

新增三条相互独立的责任线：

1. `MetaProgressionManager`：航前校准、进阶危机和元进度 JSON。
2. `MechanicRuntime`：本局装备效果、触发事件、冷却和递归保护。
3. Balance Resources：战斗、航程和经济的可调配置。

同时把现有 `RunManager` 内的三类硬编码局内内容拆成独立责任线：

4. `EventService/EventResolver`：事件抽取、条件、成本、短期契约与构筑转化。
5. `RewardService/RewardResolver`：奖励三选一、Boss 奖励、构筑角色匹配与掉落保护。
6. `BeaconService/BeaconResolver`：信标候选、整局规则、航路回响与互斥检查。

现有 `RunManager` 继续管理一局内的地图、经济、危机和装备，不接管玩家元进度；现有 `EquipmentCatalog` 第一阶段只增加标签和效果 ID，不立即迁移全部展示数据。

## 文件地图

计划创建：

- `scripts/data/balance/RunPacingConfig.gd`
- `scripts/data/balance/CombatBalanceConfig.gd`
- `scripts/data/balance/EconomyBalanceConfig.gd`
- `data/balance/run_pacing.tres`
- `data/balance/combat_balance.tres`
- `data/balance/economy_balance.tres`
- `data/balance/master_balance.tsv`
- `scripts/data/meta/CalibrationData.gd`
- `scripts/data/meta/AdvancedCrisisData.gd`
- `data/calibrations/*.tres`
- `data/advanced_crisis/*.tres`
- `scripts/data/mechanics/MechanicEffectData.gd`
- `data/mechanics/*.tres`
- `scripts/core/MetaProgressionManager.gd`
- `scripts/core/BalanceService.gd`
- `scripts/components/mechanics/MechanicRuntime.gd`
- `scripts/data/events/EventDefinition.gd`
- `scripts/data/events/EventOptionData.gd`
- `scripts/data/rewards/RewardDefinition.gd`
- `scripts/data/rewards/RewardPoolData.gd`
- `scripts/data/beacons/BeaconData.gd`
- `scripts/core/run_content/RunContentContext.gd`
- `scripts/core/run_content/RunMutationSet.gd`
- `scripts/core/run_content/RunContentFacade.gd`
- `scripts/core/run_content/EventService.gd`
- `scripts/core/run_content/EventResolver.gd`
- `scripts/core/run_content/RewardService.gd`
- `scripts/core/run_content/RewardResolver.gd`
- `scripts/core/run_content/BeaconService.gd`
- `scripts/core/run_content/BeaconResolver.gd`
- `data/events/*.tres`
- `data/rewards/*.tres`
- `data/beacons/*.tres`
- `scripts/ui/preflight/PreflightSetupPopup.gd`
- `scenes/ui/preflight/PreflightSetupPopup.tscn`
- `scripts/gameplay/explore/SalvageQuotaController.gd`
- `scripts/core/BalanceTelemetry.gd`
- 对应 `tools/*_check.gd` 与 `scenes/tests/*Check.tscn`

主要修改：

- `project.godot`
- `scripts/app/MainMenu.gd`
- `scripts/app/GameOver.gd`
- `scripts/core/GameManager.gd`
- `scripts/core/RunManager.gd`
- `scripts/core/EquipmentCatalog.gd`
- `scripts/entities/player/Player.gd`
- `scripts/entities/projectiles/Bullet.gd`
- `scripts/entities/support/SupportDrone.gd`
- `scripts/entities/enemies/BaseEnemy.gd`
- `scripts/entities/designed_enemies/DesignedEnemy.gd`
- 五个 Boss 家族控制器及其变体
- `scripts/gameplay/explore/ExploreRoom.gd`
- `scripts/gameplay/explore/ExploreReward.gd`
- `scripts/gameplay/explore/EvacuationPoint.gd`
- `scripts/ui/explore/ExploreObjectivesHUD.gd`
- `scripts/ui/world_map/ShopPopup.gd`
- `scripts/ui/world_map/HangarPopup.gd`

---

## 验收待办 Task 1：配置资源与统一阶段服务

Skills: `resource-pattern`, `gdscript-patterns`, `godot-testing`

### 文件

- Create: `scripts/data/balance/RunPacingConfig.gd`
- Create: `scripts/data/balance/CombatBalanceConfig.gd`
- Create: `scripts/data/balance/EconomyBalanceConfig.gd`
- Create: `data/balance/run_pacing.tres`
- Create: `data/balance/combat_balance.tres`
- Create: `data/balance/economy_balance.tres`
- Create: `scripts/core/BalanceService.gd`
- Create: `tools/balance_config_check.gd`
- Create: `scenes/tests/BalanceConfigCheck.tscn`
- Modify: `project.godot`

### 步骤

- [ ] 写 `BalanceConfigCheck`，检查策划案中的危机阈值、阶段 HP/EHP、伤害类别、收入范围、装配目标和资源字段。
- [ ] 运行检查并确认因资源缺失而失败。
- [ ] 创建三个小型、单一职责的 Resource 类和 `.tres` 默认配置。
- [ ] 创建 `BalanceService` Autoload，只读加载三份资源，并提供 `get_stage_for_crisis()`、阶段 EHP、伤害和经济查询。
- [ ] 禁止运行时修改共享 Resource；如需临时修改，用运行时 Dictionary 副本。
- [ ] 运行 `BalanceConfigCheck`，确认通过。

### 验收

- 所有后续数值均能通过 `BalanceService` 查询。
- UI/特效脚本中不新增核心数值常量。
- Resource 路径错误时给出明确错误并回退到安全默认值。

---

## 验收待办 Task 2：元进度存档管理器

Skills: `save-load`, `resource-pattern`, `gdscript-patterns`, `godot-testing`

### 文件

- Create: `scripts/data/meta/CalibrationData.gd`
- Create: `scripts/data/meta/AdvancedCrisisData.gd`
- Create: `scripts/core/MetaProgressionManager.gd`
- Create: `data/calibrations/*.tres`
- Create: `data/advanced_crisis/*.tres`
- Create: `tools/meta_progression_save_check.gd`
- Create: `scenes/tests/MetaProgressionSaveCheck.tscn`
- Modify: `project.godot`

### 步骤

- [ ] 写检查：首次启动默认解锁三项校准、损坏 JSON 回退、版本迁移、校准选择限制、进阶危机选择不超过最高解锁层。
- [ ] 创建 8 个 `CalibrationData` 和 10 个 `AdvancedCrisisData` 只读资源。
- [ ] 实现 `MetaProgressionManager`，保存到 `user://meta_progression.json`。
- [ ] 使用临时文件写入后替换正式文件；所有 FileAccess 错误必须报告。
- [ ] 实现 v0→v1 迁移入口，即使当前没有旧格式也必须保留迁移框架。
- [ ] 提供里程碑 API：到达第二 Boss、击败各阶段 Boss、到达最终 Boss、首次通关、通关当前最高危机。
- [ ] 确认元进度存档与 `RunManager.SAVE_PATH` 完全独立。

### 验收

- 删除、损坏、降级元进度文件不会破坏局内存档。
- 失败局仍可通过已到达里程碑解锁校准。
- 不存在永久攻击、生命、掉率等级字段。

---

## 验收待办 Task 3：航前校准与进阶危机 UI

Skills: `godot-ui`, `responsive-ui`, `save-load`, `godot-testing`

### 文件

- Create: `scenes/ui/preflight/PreflightSetupPopup.tscn`
- Create: `scripts/ui/preflight/PreflightSetupPopup.gd`
- Create: `tools/preflight_setup_check.gd`
- Create: `scenes/tests/PreflightSetupCheck.tscn`
- Modify: `scripts/app/MainMenu.gd`
- Modify: `scenes/ui/main_menu/MainMenuGeneratedUI.tscn` only if a hook node is required

### 步骤

- [ ] 写 UI 检查：只显示已解锁校准、只能选择一个、危机等级不可越权、确认后才开始新局、取消不清除旧存档。
- [ ] 按策划案场景树创建航前弹窗，复用当前商业 UI 主题。
- [ ] 修改“开始航程”：先打开航前弹窗，确认后再执行 `GameManager.reset_run_state()` 和 `RunManager.start_new_run()`。
- [ ] 把本局校准与危机选择作为不可变的 `preflight_config` 交给 `RunManager`，不在战斗中读取可能变化的 UI 状态。
- [ ] 加入校准效果、限制和解锁来源的完整文本。

### 验收

- 新局一定经过航前确认。
- 继续存档不会重新选择校准或危机。
- 1920×1080 与 960×540 下按钮和文本可用。

---

## 验收待办 Task 4：机制事件协议与纵向样板

Skills: `component-system`, `resource-pattern`, `event-bus`, `gdscript-advanced`, `godot-testing`

### 文件

- Create: `scripts/data/mechanics/MechanicEffectData.gd`
- Create: `scripts/components/mechanics/MechanicRuntime.gd`
- Create: `data/mechanics/` 下纵向样板效果资源
- Create: `tools/mechanic_runtime_check.gd`
- Create: `scenes/tests/MechanicRuntimeCheck.tscn`
- Modify: `scenes/entities/player/player.tscn`
- Modify: `scripts/entities/player/Player.gd`
- Modify: `scripts/entities/projectiles/Bullet.gd`
- Modify: `scripts/entities/support/SupportDrone.gd`
- Modify: `scripts/entities/enemies/BaseEnemy.gd`

### 步骤

- [ ] 写检查覆盖触发、条件、内部冷却、相加/相乘/最大/唯一叠加规则。
- [ ] 写递归保护检查：最大世代 3、同效果不能在同一谱系重入、世代系数正确。
- [ ] 定义有限触发枚举：射击、命中、击杀、冲刺命中、狂热开始、僚机行动、矿物拾取。
- [ ] 定义有限动作枚举：生成弹、施加标记、生成范围伤害、改变冷却、增加热量、召唤僚机动作、修改资源。
- [ ] 把 `MechanicRuntime` 作为 Player 子节点；场景内战斗事件通过显式方法/信号发送，不新增全局 EventBus。
- [ ] 完成每家族至少一个纵向样板：巨构余震、天堂分裂、扭曲标记、地狱热量、神使僚机复制。
- [ ] 为事件谱系加入仅调试模式输出。

### 验收

- 五个样板能在同一测试场景组合。
- 不发生无限递归。
- 生成弹继承强度受 `inherit_mask` 与 `proc_coefficient` 控制。
- 现有没有机制定义的装备仍按旧逻辑工作。

---

## 验收待办 Task 5：狂热覆盖率重构

Skills: `component-system`, `hud-system`, `gdscript-patterns`, `godot-testing`

### 文件

- Create: `tools/frenzy_uptime_check.gd`
- Create: `scenes/tests/FrenzyUptimeCheck.tscn`
- Modify: `scripts/core/GameManager.gd`
- Modify: `scripts/entities/player/Player.gd`
- Modify: `scripts/entities/enemies/BaseEnemy.gd`
- Modify: 五个 Boss 家族受伤入口
- Modify: `scripts/ui/HUD.gd` only if new debug/readout fields are required

### 步骤

- [ ] 写 60 秒标准射击模拟：无装备覆盖率 25%–40%，地狱 4 件覆盖率 50%–70%。
- [ ] 把热量来源从“等额伤害”改为策划案中的命中、击杀、受伤事件预算。
- [ ] 实现每秒热量获取上限与次级触发系数。
- [ ] 狂热期间默认不获取热量。
- [ ] 调整基础效果为射击间隔 ×0.60–0.65、承伤 ×0.60。
- [ ] 迁移地狱之眼装备，使其修改热量上限、获取倍率和狂热转化，而不是重复堆同一乘区。

### 验收

- DPS 提高本身不会把狂热覆盖率推到接近 100%。
- 天堂多弹与神使僚机能提供联动，但受热量上限控制。
- HUD 数值与实际计时一致。

---

## 验收待办 Task 6：双充能冲刺与巨构转化

Skills: `player-controller`, `input-handling`, `component-system`, `physics-system`, `hud-system`, `godot-testing`

### 文件

- Create: `tools/dash_charge_balance_check.gd`
- Create: `scenes/tests/DashChargeBalanceCheck.tscn`
- Modify: `scripts/entities/player/Player.gd`
- Modify: `scenes/entities/player/player.tscn`
- Modify: 玩家状态 HUD（显示充能）
- Modify: 巨构相关装备定义与机制资源

### 步骤

- [ ] 写检查：2 次充能、1.8 秒恢复、距离/速度、无敌时长、白板持续 DPS 不超过主炮。
- [ ] 把当前单冷却冲刺改为充能模型。
- [ ] 白板冲刺撞击改为 0.5–1.0 倍攻击，默认不反弹。
- [ ] 通过巨构启动器解锁反弹、撞击倍率和余震。
- [ ] 通过 2 件/4 件共鸣分别建立“可输出”和“主输出”能力。
- [ ] 保证 Boss 特定技能的预警时间与冲刺恢复节奏匹配。

### 验收

- 白板不能靠连按冲刺维持近乎常驻无敌。
- 巨构 4 件构筑可用冲刺作为主要输出。
- 冲刺用于移动、躲避、命中的遥测可以区分。

---

## 验收待办 Task 7：五家族装备纵向迁移

Skills: `component-system`, `resource-pattern`, `inventory-system`, `gdscript-advanced`, `godot-testing`

### 文件

- Modify: `scripts/core/EquipmentCatalog.gd`
- Modify: `scripts/core/RunManager.gd`
- Create/Modify: `data/mechanics/*.tres`
- Create: `tools/equipment_mechanic_coverage_check.gd`
- Create: `scenes/tests/EquipmentMechanicCoverageCheck.tscn`

### 步骤

- [ ] 给所有装备增加 `mechanic_tags`、`effect_ids`、`role`（启动器/放大器/转化器/桥接器/稳定器）。
- [ ] 第一批每家族迁移 4–6 件，形成可从普通到 Boss 掉落的完整纵向构筑。
- [ ] 为五家族各制作一套标准 3/5/8 件测试装配。
- [ ] 验证标准装配强度分别达到阶段 2–2.5×、4–5×、8–10×。
- [ ] 再批量迁移剩余装备；每批不超过 20 件，每批运行覆盖检查。
- [ ] 把纯数值重复装备改成不同角色；保留少量简单稳定器供休闲玩家理解。
- [ ] 增加至少 10 个跨家族桥接效果，但同一件装备最多承担一个主要桥接规则。

### 验收

- 每个家族都有启动器、放大器、转化器和至少一个桥接器。
- 商店能识别缺失的机制角色。
- 142 件装备全部有标签；未迁移的旧效果有明确兼容标记。

---

## 验收待办 Task 8：敌人、精英和 Boss 阶段预算

Skills: `component-system`, `ai-navigation`, `physics-system`, `resource-pattern`, `godot-testing`

### 文件

- Create: `tools/combat_budget_check.gd`
- Create: `scenes/tests/CombatBudgetCheck.tscn`
- Modify: `scripts/entities/designed_enemies/DesignedEnemy.gd`
- Modify: `scripts/entities/designed_enemies/DesignedEnemyCatalog.gd`
- Modify: 五个 Boss 家族控制器和变体
- Modify: `scripts/core/RunManager.gd`

### 步骤

- [ ] 写标准靶场，记录白板和三阶段 3/5/8 件装配的有效 DPS。
- [ ] 按 `基础 HP × 阶段系数 × 行为系数` 设置普通怪 HP。
- [ ] 将普通、危险、重击伤害映射到 5、8–12、34–40 三类。
- [ ] 按 4,800 / 9,600 / 20,400 EHP 设置精英，并计入护盾、闪现和不可攻击时间。
- [ ] 按 5,600 / 14,500 / 36,000 EHP 设置 Boss；家族浮动不超过 ±15%。
- [ ] 为 Boss 增加显式阶段索引，不通过名称字符串判断难度。
- [ ] 验证 Boss 胡局可显著缩短，不添加动态减伤兜底。

### 验收

- 普通怪、精英和 Boss TTK 落入策划案区间。
- 精英不会因护盾等机制把实际 EHP 无预算翻倍。
- 后期伤害压力主要来自组合与密度，不是单击秒杀。

---

## 验收待办 Task 9：探索回收进度与房间节奏

Skills: `scene-organization`, `component-system`, `godot-ui`, `hud-system`, `procedural-generation`, `godot-testing`

### 文件

- Create: `scripts/gameplay/explore/SalvageQuotaController.gd`
- Create: `tools/salvage_quota_check.gd`
- Create: `scenes/tests/SalvageQuotaCheck.tscn`
- Modify: `scenes/gameplay/explore/ExploreRoom.tscn`
- Modify: `scripts/gameplay/explore/ExploreRoom.gd`
- Modify: `scripts/gameplay/explore/ExploreReward.gd`
- Modify: `scripts/gameplay/explore/EvacuationPoint.gd`
- Modify: `scripts/ui/explore/ExploreObjectivesHUD.gd`
- Modify: `scripts/core/RunManager.gd`
- Modify: 世界地图节奏/多样性检查

### 步骤

- [ ] 写检查：总价值、50% 显露、65% 开放撤离、最终搜刮统计、空房安全回退。
- [ ] 新增 `SalvageQuotaController`，只持有房间回收目标与完成进度。
- [ ] 宝箱、矿脉、精英缓存和特殊目标注册价值；破坏/回收后发信号。
- [ ] 撤离点在 65% 前不可完成，50% 后显示方向。
- [ ] 调整稳定收益，使前 70% 内容包含 80%–85% 稳定价值。
- [ ] 调整巡逻基准到 35/30/25 秒、上限 8/10/12，并保留战斗档案 ±25% 浮动。
- [ ] 将地图战斗/事件/奖励权重改向约 3:3:2；特殊节点单独统计。
- [ ] 更新所有假定 5:2:1 的既有测试。

### 验收

- 玩家不能出生后直接撤离。
- 不要求清敌；没有奖励目标的异常房间可安全开放撤离。
- 模拟路线中探索房中位数为 8–9。

---

## 验收待办 Task 10：经济、商店和装备保护

Skills: `inventory-system`, `resource-pattern`, `godot-ui`, `godot-testing`

### 文件

- Create: `tools/run_economy_curve_check.gd`
- Create: `scenes/tests/RunEconomyCurveCheck.tscn`
- Modify: `scripts/core/RunManager.gd`
- Modify: `scripts/core/EquipmentCatalog.gd`
- Modify: `scripts/ui/world_map/ShopPopup.gd`
- Modify: `scripts/ui/world_map/HangarPopup.gd`

### 步骤

- [ ] 写 1,000 个固定种子经济模拟，记录 Boss 前拥有/装配/算力/收入/消费分布。
- [ ] 将 70% 搜刮房间收入调整到 55–75 / 85–115 / 125–170。
- [ ] 实现 12 格商店的候选角色组成。
- [ ] 实现重抽公式及免费重抽兼容。
- [ ] 实现连续 3 节点无装备保护和第一 Boss 前 3 件装配保护。
- [ ] 保持无重复装备规则。
- [ ] UI 显示装备角色、机制标签和其补齐的构筑环节，避免只展示百分比。

### 验收

- Boss 前装配中位数 3/5/8，P25 不低于 2/4/7。
- 标准局付费重抽中位数 1–2。
- 一次普通探索后不能买空商店。
- 保护机制只修复断档，不强行给出完整胡局。

---

## 验收待办 Task 11：航前校准效果接入

Skills: `dependency-injection`, `component-system`, `save-load`, `godot-testing`

### 文件

- Create: `tools/calibration_effects_check.gd`
- Create: `scenes/tests/CalibrationEffectsCheck.tscn`
- Modify: `scripts/core/RunManager.gd`
- Modify: `scripts/core/GameManager.gd`
- Modify: `scripts/entities/player/Player.gd`
- Modify: `scripts/gameplay/explore/ExploreRoom.gd`

### 步骤

- [ ] 为 8 项校准逐项写效果与代价检查。
- [ ] 新局开始时把所选校准复制进 `RunManager` 的本局配置。
- [ ] 各系统通过显式查询/注入读取本局配置，不在每帧查询元进度文件。
- [ ] 实现宽域扫描、采购凭证、共振罗盘、应急隔舱、算力租约、热机协议、回收探针、混沌种子。
- [ ] 验证继续存档恢复相同校准。

### 验收

- 任何校准都不是无代价的必选最优解。
- 同一局只能有一个校准。
- 校准不会改变标准配置资源本身。

---

## 验收待办 Task 12：进阶危机效果接入

Skills: `resource-pattern`, `dependency-injection`, `ai-navigation`, `godot-testing`

### 文件

- Create: `scripts/core/AdvancedCrisisResolver.gd`
- Create: `tools/advanced_crisis_check.gd`
- Create: `scenes/tests/AdvancedCrisisCheck.tscn`
- Modify: `scripts/core/RunManager.gd`
- Modify: `scripts/gameplay/explore/ExploreRoom.gd`
- Modify: 精英词缀和 Boss 阶段代码
- Modify: `scripts/app/GameOver.gd`

### 步骤

- [ ] 写危机 0–10 累计效果快照检查。
- [ ] 实现 `AdvancedCrisisResolver`，把所选等级解析为本局不可变修正集合。
- [ ] 依次接入巡逻、经济、精英词缀、事件代价、Boss 阶段、陷阱、治疗、混编和最终裁决。
- [ ] 通关当前最高层时解锁下一层；失败不降级。
- [ ] 危机 0 必须保持完全标准配置。

### 验收

- 等级效果只累计一次。
- 继续存档不会重复应用。
- 进阶危机不写回标准 `.tres`。
- 危机 10 的难度来自组合规则，不依赖重击超过 40。

---

## 验收待办 Task 13：平衡遥测与自动报告

Skills: `godot-testing`, `save-load`, `godot-optimization`

### 文件

- Create: `scripts/core/BalanceTelemetry.gd`
- Create: `tools/balance_telemetry_check.gd`
- Create: `scenes/tests/BalanceTelemetryCheck.tscn`
- Modify: `project.godot`
- Modify: 相关系统的调试事件上报点

### 步骤

- [ ] 实现仅调试/开发构建启用的遥测开关。
- [ ] 按策划案记录房间、整局、经济、战斗、狂热、冲刺和机制贡献。
- [ ] 输出 JSON Lines 到 `user://balance_runs.jsonl`。
- [ ] 对写入失败、文件过大和关闭遥测做安全处理；建议单文件 10 MB 后轮换。
- [ ] 提供汇总工具输出 P25/P50/P75/P90，而不是只看平均值。

### 验收

- 正式关闭遥测时不产生文件和明显运行时开销。
- 每次 Boss 结算能还原当时装配、DPS、TTK 和机制贡献。

---

## 验收待办 Task 14：集成验证与调优顺序

Skills: `godot-testing`, `godot-code-review`, `godot-debugging`, `godot-optimization`

### 步骤

- [ ] 运行所有现有 `scenes/tests/` 无头检查，记录原有失败与新增失败。
- [ ] 运行 BalanceConfig、MechanicRuntime、Frenzy、Dash、CombatBudget、SalvageQuota、Economy、Calibration、AdvancedCrisis 检查。
- [ ] 使用固定标准装配分别打五家族三阶段 Boss。
- [ ] 使用至少 100 个航图种子验证节点与经济分布；经济最终使用 1,000 个种子。
- [ ] 人工完成白板、普通构筑、单家族胡局、跨家族胡局各至少一局。
- [ ] 按策划案第 19 节顺序调数值；禁止先微调全部单品。
- [ ] 使用 `godot-code-review` 检查所有新增 GDScript 和场景通信。
- [ ] 使用性能分析确认胡局弹体、事件触发和无人机不突破帧预算。

### 最终通过条件

- 完整局时 P50 45–52 分钟、P90 不高于 60 分钟。
- Boss 前装配 3/5/8 达标。
- 标准狂热覆盖率和五家族 TTK 达标。
- 胡局能突破常规时长且无无限递归/严重掉帧。
- 标准危机 0 不受进阶系统污染。
- 元进度和局内存档均能迁移、损坏回退并独立工作。

## 交接提醒

本计划同时包含基础规则改造与内容迁移。推荐每完成 Task 4、Task 8、Task 10 各做一次可玩的里程碑版本，不要等 142 件装备全部迁移后才试玩。

执行者若发现策划案数值与实测冲突，应优先守住以下顺序：

1. 休闲生存预算。
2. 3/5/8 装配节奏。
3. 3–5 分钟探索房与 30–60 分钟局时。
4. 标准构筑可通关。
5. 胡局允许破坏常规。

单个装备的原始数值优先级低于上述五项。

---

## Agent 工作组：派发与集成总则

以下 12 个工作组才是交给独立 Agent 的执行单元。推荐每个工作组使用独立分支或 worktree；如果只能共享同一工作区，严格按波次合并，且任何 Agent 开始前都必须重新检查 `rtk git status --short` 和其允许修改文件的现有 diff。

### 统一输入契约

所有组共同读取：

- [数值与机制总策划案](../specs/2026-07-15-balance-and-mechanics-design.md)
- 本实施计划
- `AGENTS.md`、`CLAUDE.md` 和任务列出的 GodotPrompter 技能
- WG-01 发布的 `docs/godot-prompter/contracts/run-content-contract.md`

除 WG-01 外，所有组把需要中央文件接线的内容写入：

`docs/godot-prompter/integration-requests/WG-XX.md`

请求必须给出：调用点、期望接口、参数/返回类型、失败回退、需要连接的信号和对应测试。不得用“请自行接入”替代接口说明。

每个组完成时写：

`docs/godot-prompter/reports/WG-XX.md`

报告包含已改文件、未完成项、运行命令、测试结果、已知风险、数值偏差和需要 WG-01 处理的请求。

### 全局独占文件

| 文件/目录 | 唯一所有者 | 说明 |
|---|---|---|
| `scripts/core/RunManager.gd` | WG-01 | 所有局内内容适配、存档迁移和最终提交只在此接线 |
| `scripts/app/WorldMap.gd` | WG-01 | 三类弹窗的打开/回调只由集成组接线 |
| `project.godot` | WG-01 | Autoload 与项目设置统一登记 |
| 玩家战斗核心文件 | WG-05 | 详见 WG-05，不允许装备内容组直接加特殊判断 |
| `scripts/core/EquipmentCatalog.gd` | WG-06 | 经济组只能通过目录 API 读取 |
| 探索房核心文件 | WG-08 | 其他组通过上下文/信号接入 |
| 商店与机库 UI | WG-09 | 其他组不得顺手修改展示逻辑 |
| 主菜单、航前和 GameOver 接线 | WG-10 | 危机组只提供 Resolver 与结果 |

## WG-01：共享基础、接口冻结与最终集成

**Agent 目标：** 先把中央巨型管理器周围的接口冻结，最后统一接入其他 11 组的产物。此 Agent 需要保留到项目末期，不应在基础阶段结束后销毁上下文。

**Skills：** `godot-brainstorming`, `resource-pattern`, `component-system`, `dependency-injection`, `save-load`, `gdscript-advanced`, `godot-testing`

**前置依赖：** 无。它是所有内容组的前置。

**独占文件：**

- `scripts/core/RunManager.gd`
- `scripts/app/WorldMap.gd`
- `project.godot`
- `scripts/core/BalanceService.gd`
- `scripts/data/balance/*`
- `data/balance/*`
- `scripts/core/run_content/RunContentContext.gd`
- `scripts/core/run_content/RunMutationSet.gd`
- `scripts/core/run_content/RunContentFacade.gd`
- `docs/godot-prompter/contracts/run-content-contract.md`

**允许创建：** `tools/run_content_contract_check.gd`、`scenes/tests/RunContentContractCheck.tscn`、中央适配测试和本组报告。

**禁止修改：** 各内容组的 Resolver、`.tres` 内容库、玩家战斗文件、装备目录、探索、商店、Boss、航前 UI。

**输入接口：** 现有 `RunManager` 公开 API、局内存档字段、其他组的 `RunMutationSet` 与集成请求。

**输出接口：**

- 冻结 `RunContentContext`、`ChoiceView`、`RunMutationSet` 字段和错误码。
- 提供 `prepare_choices()`、`resolve_choice()`、`validate_mutation()`、`commit_mutation()`、`get_active_rule_snapshot()`。
- 保留现有事件/奖励/信标公开方法作为兼容转发层。
- 明确内容服务不得直接持有或修改 `RunManager`。
- 提供主表验证与生成入口：TSV 通过 schema、唯一键、类型、阶段值和白名单动作检查后，生成各域只读 `.tres`；运行时不直接读取 TSV。

**实施步骤：**

1. 写契约测试，快照当前事件、奖励、信标 API 与存档字段。
2. 创建只读上下文和原子 mutation 数据结构；验证不足费用、重复提交、过期 state version。
3. 创建 Facade，但第一阶段仍转发旧实现，保证行为不变。
4. 发布接口文档并通知其他组可以开工。
5. 各组完成后逐组接入，迁移旧 Dictionary 常量与存档。
6. 所有兼容测试通过后才删除旧内部实现；兼容公开方法本版本保留。

**验收：**

- 其他组无需修改 `RunManager.gd` 即可添加新 `.tres` 内容。
- mutation 要么完整提交，要么完全不改变本局状态。
- 旧存档缺少新增字段时安全迁移；内容 ID 缺失时记录并忽略。
- WG-01 基础提交后，中央契约在本轮开发中不得破坏式改名。
- `master_balance.tsv` 是唯一策划编辑源；重新生成结果稳定，手改 `.tres` 会被漂移检查发现。

## WG-02：事件系统与 24 项首发事件

**Agent 目标：** 把事件抽取、选项、成本、短期契约和局势改变从 `RunManager` 拆出，并实现总案第 20 节首发事件库。

**Skills：** `dialogue-system`, `resource-pattern`, `component-system`, `godot-ui`, `save-load`, `godot-testing`

**前置依赖：** WG-01 接口冻结。

**独占文件：**

- `scripts/data/events/EventDefinition.gd`
- `scripts/data/events/EventOptionData.gd`
- `scripts/core/run_content/EventService.gd`
- `scripts/core/run_content/EventResolver.gd`
- `data/events/**`
- `scripts/ui/world_map/EventChoicePopup.gd`
- `scenes/ui/world_map/EventChoicePopup.tscn`
- `tools/event_service_check.gd`
- `scenes/tests/EventServiceCheck.tscn`

**允许修改：** 仅本组新建测试、事件 Resource 与本组报告/集成请求。

**禁止修改：** `RunManager.gd`、`WorldMap.gd`、`project.godot`、奖励/信标服务、任何玩家/敌人脚本。

**输入接口：** `RunContentContext`；可用 Resolver 白名单动作；当前节点与路线快照。

**输出接口：** `ChoiceView[]`、`RunMutationSet`、事件契约快照；不得输出任意 Callable 或脚本路径让中央层执行。

**验收：**

- 总案列出的 24 项事件都有可加载 Resource、成本预览和至少 2 个选项。
- 条件不满足的跨家族/转换事件不会污染抽取池。
- 1000 种子中无重复唯一事件、无连续 3 个同家族事件、前期有安全候选。
- 费用不足、离开、契约过期、路线节点已访问均有测试。
- 现有事件兼容测试所需的旧 ID 有迁移映射。

## WG-03：奖励节点、Boss 奖励与掉落保护

**Agent 目标：** 实现总案第 21 节奖励池、构筑角色识别、Boss 4 选 1 和 3/5/8 掉落保护。

**Skills：** `resource-pattern`, `inventory-system`, `component-system`, `godot-ui`, `godot-testing`

**前置依赖：** WG-01 接口冻结；读取 WG-06 约定的装备角色字段，若 WG-06 尚未完成则使用契约 mock。

**独占文件：**

- `scripts/data/rewards/RewardDefinition.gd`
- `scripts/data/rewards/RewardPoolData.gd`
- `scripts/core/run_content/RewardService.gd`
- `scripts/core/run_content/RewardResolver.gd`
- `data/rewards/**`
- `scripts/ui/world_map/RewardCacheChoicePopup.gd`
- `scenes/ui/world_map/RewardCacheChoicePopup.tscn`
- `scripts/ui/world_map/BossRewardPopup.gd`
- `scenes/ui/world_map/BossRewardPopup.tscn`
- `tools/reward_service_check.gd`
- `scenes/tests/RewardServiceCheck.tscn`

**禁止修改：** 中央文件、`EquipmentCatalog.gd`、商店/机库 UI、事件/信标内容。

**输入接口：** `RewardContext`、只读装备目录查询接口、阶段目标和 dry-streak 计数。

**输出接口：** 3 张常规奖励 `ChoiceView` 或 4 张 Boss 奖励 `ChoiceView`；选择后输出原子 mutation 与保底计数更新。

**验收：**

- 8 类首发奖励池都有固定种子检查。
- 不重复装备、不空奖；无合法装备时按策划回退。
- 3 节点无装备、4 次无启动器、4 次无匹配放大器保底准确触发且只消费一次。
- 1000 种子经济模拟中 Boss 前装配中位数 3/5/8、P25 不低于 2/4/7。
- 低血量、生存卡概率、Boss 维护包与弃装备后的补偿权重符合总案。

## WG-04：局内信标与航路回响

**Agent 目标：** 实现 26 个规则型信标、候选生成、互斥、激活快照和航路回响。

**Skills：** `resource-pattern`, `component-system`, `event-bus`, `godot-ui`, `gdscript-advanced`, `godot-testing`

**前置依赖：** WG-01 接口冻结；WG-05 发布 `MechanicRuntime` 规则钩子表后完成战斗型信标联调。

**独占文件：**

- `scripts/data/beacons/BeaconData.gd`
- `scripts/core/run_content/BeaconService.gd`
- `scripts/core/run_content/BeaconResolver.gd`
- `data/beacons/**`
- `scripts/ui/world_map/SpecialBonusPopup.gd`
- `scenes/ui/world_map/SpecialBonusPopup.tscn`
- `tools/beacon_service_check.gd`
- `scenes/tests/BeaconServiceCheck.tscn`

**禁止修改：** 中央文件、玩家战斗核心、装备目录、事件/奖励内容。

**输入接口：** 当前家族权重、已激活 `rule_key`、未进入节点快照、MechanicRuntime 支持的钩子表。

**输出接口：** 信标候选、`activate_rule` mutation、不可变 active rule snapshot、未来 3 节点的 route echo mutation。

**验收：**

- 通用/经济/防御 6 个和五家族各 4 个信标均可加载，共 26 个。
- 每个信标恰有一个主 `rule_key`；相同规则不重复、不叠层。
- 每局基础可达信标中位数为 2，事件追加后总激活上限为 3。
- 二级弹体/命中保留 generation、lineage 和 proc coefficient，不能触发自身。
- 每个信标至少有一项可观测的规则触发测试，而非只检查百分比字段。

## WG-05：战斗核心机制运行层

**Agent 目标：** 建立统一战斗事件协议、递归保护、狂热覆盖率和双充能冲刺，并提供信标/装备只需声明数据即可使用的钩子。

**Skills：** `component-system`, `player-controller`, `input-handling`, `physics-system`, `event-bus`, `hud-system`, `gdscript-advanced`, `godot-testing`

**前置依赖：** WG-01 的平衡查询与规则快照接口。

**独占文件：**

- `scripts/components/mechanics/MechanicRuntime.gd`
- `scripts/data/mechanics/MechanicEffectData.gd`
- `data/mechanics/runtime_samples/**`
- `scripts/core/GameManager.gd`
- `scripts/entities/player/Player.gd`
- `scenes/entities/player/player.tscn`
- `scripts/entities/projectiles/Bullet.gd`
- `scripts/entities/support/SupportDrone.gd`
- `scenes/entities/support/SupportDrone.tscn`
- `scripts/entities/enemies/BaseEnemy.gd`
- 狂热/冲刺/机制运行层专属测试

**禁止修改：** `EquipmentCatalog.gd`、五家族内容 Resource、中央文件、Boss 控制器、商店/探索 UI。

**输入接口：** `MechanicEffectData[]`、active rule snapshot、CombatBalance 查询。

**输出接口：** 冻结的战斗事件载荷、支持的 trigger/action/rule_key 清单、逐效果统计信号。

**验收：**

- 标准狂热覆盖率 25%–40%，地狱之眼样板 50%–70%。
- 默认冲刺是 2 充能防御工具；无巨构规则时不能成为持续主输出。
- 事件世代不超过 3，同 effect/lineage 不递归，弹体和每秒触发有硬上限。
- WG-04 的 26 个信标不需要在 Player 内添加 26 段 ID 特判。

## WG-06：五家族装备机制与桥接器

**Agent 目标：** 为装备补齐启动器/放大器/桥接器/经济/生存角色，迁移五家族纵向样板，再批量覆盖目录。

**Skills：** `resource-pattern`, `component-system`, `inventory-system`, `gdscript-advanced`, `godot-testing`

**前置依赖：** WG-05 冻结 trigger/action 清单；WG-03 提供角色查询需求。

**独占文件：**

- `scripts/core/EquipmentCatalog.gd`
- `data/mechanics/equipment/**`
- `tools/equipment_mechanic_coverage_check.gd`
- `scenes/tests/EquipmentMechanicCoverageCheck.tscn`

**禁止修改：** Player、Bullet、SupportDrone、BaseEnemy、中央文件、奖励服务、商店 UI。

`data/balance/master_balance.tsv` 由 WG-01 独占。WG-06 以其中 142 件装备行为输入；如需调整角色、价格、算力或机制字段，提交逐行变更请求给 WG-01，不直接并行编辑主表。

**输入接口：** MechanicRuntime 支持清单、装备原始目录、总案五家族机制主轴。

**输出接口：** 稳定的目录查询 `role`、`mechanic_tags`、`effect_ids`、`bridge_tags`、`rarity`、`compute_cost`；装备效果 Resource。

**验收：**

- 先完成五家族各 4 件纵向样板并实测，再迁移其余装备。
- 每家族至少有 2 个启动器、2 个放大器、2 个桥接器候选。
- 不在目录中嵌入针对 Player/RunManager 的 Callable。
- 142 件目录结构全覆盖；未迁移效果明确标记 legacy，不能静默缺失。

## WG-07：普通敌人、精英与 Boss 数值

**Agent 目标：** 按阶段 DPS 和 2–5 秒/1 分钟/1–3 分钟 TTK 预算重标敌人，并让难度来自机制组合而非无限血量。

**Skills：** `ai-navigation`, `physics-system`, `component-system`, `resource-pattern`, `state-machine`, `godot-testing`

**前置依赖：** WG-01 CombatBalance 查询；WG-05 战斗事件和伤害类别冻结。

**独占文件：**

- `scripts/entities/designed_enemies/DesignedEnemy.gd`
- `scripts/entities/designed_enemies/DesignedEnemyCatalog.gd`
- `scripts/entities/bosses/**`
- `scenes/entities/bosses/**`
- `scenes/gameplay/boss/**`
- `scripts/ui/BossHUD.gd`
- `scenes/ui/BossHUD.tscn`
- `scripts/app/BossSelect.gd`
- `scenes/app/BossSelect.tscn`
- `scenes/ui/boss_select/**`
- 敌人、精英、Boss 预算测试

**允许修改：** 仅敌人/Boss 专属文件和本组测试；若 BaseEnemy 缺钩子向 WG-05 提请求。

**禁止修改：** `BaseEnemy.gd`、Player、RunManager、MechanicRuntime、探索房控制器。

**输出接口：** 标准化敌人配置、Boss 阶段事件、进阶危机可注入的词缀/阶段 modifier 接口。

**验收：** 普通、精英、Boss 的 EHP/TTK 落入总案区间；重击不超过 40；Boss 有明确输出窗口，胡局可 20–50 秒击杀但标准构筑仍为 1–3 分钟。

## WG-08：探索目标、房间节奏与航图节点分布

**Agent 目标：** 实现回收价值、65% 撤离、70%–80% 实际搜刮、巡逻压力和事件/奖励/信标可达数量目标。

**Skills：** `scene-organization`, `component-system`, `procedural-generation`, `godot-ui`, `hud-system`, `godot-testing`

**前置依赖：** WG-01 的 RunPacing 查询与中央地图集成请求格式。

**独占文件：**

- `scripts/gameplay/explore/SalvageQuotaController.gd`
- `scripts/gameplay/explore/ExploreRoom.gd`
- `scenes/gameplay/explore/ExploreRoom.tscn`
- `scripts/gameplay/explore/ExploreReward.gd`
- `scripts/gameplay/explore/EvacuationPoint.gd`
- `scripts/ui/explore/ExploreObjectivesHUD.gd`
- 探索节奏/搜刮专属测试

**禁止修改：** WorldMap、RunManager、事件/奖励/信标 Service、敌人/Boss 数值文件。

**输出接口：** `salvage_progress_changed`、`evacuation_unlocked`、房间结算摘要、航图节点分布参数集成请求。

**验收：** 房间 P50 3–5 分钟；65% 可撤离、P50 搜刮 70%–80%；敌人无限生成不能刷装备；1000 航图种子可达事件/奖励/信标中位数为 6/2/2。

## WG-09：经济、商店与机库交互

**Agent 目标：** 完成阶段收入、12 格商店、重抽、购买能力和机制信息展示；消费侧不重复实现奖励保底。

**Skills：** `inventory-system`, `resource-pattern`, `godot-ui`, `responsive-ui`, `godot-testing`

**前置依赖：** WG-01 EconomyBalance 查询；WG-06 装备目录 API；可用 mock 并在后续联调。

**独占文件：**

- `scripts/core/EconomyService.gd`
- `scripts/ui/world_map/ShopPopup.gd`
- `scenes/ui/world_map/ShopPopup.tscn`
- `scripts/ui/world_map/HangarPopup.gd`
- `scripts/ui/world_map/EquipmentItemRow.gd`
- `scenes/ui/world_map/EquipmentItemRow.tscn`
- 经济/商店专属测试

**禁止修改：** EquipmentCatalog、RunManager、RewardService、探索房、MetaProgression。

**输出接口：** 商店草案、报价/重抽 transaction mutation、装备角色展示 DTO；中央层只提交交易结果。

**验收：** 70% 搜刮收入、装备价格和重抽公式达标；商店 12 格角色组成稳定；标准状态通常买 1 件、经济胡局可买 2 件但不能一次普通探索买空商店。

## WG-10：航前校准、元存档与菜单流程

**Agent 目标：** 只实现航前校准与进阶危机选择/解锁的元进度，不新增永久攻击生命成长。

**Skills：** `save-load`, `resource-pattern`, `godot-ui`, `responsive-ui`, `dependency-injection`, `godot-testing`

**前置依赖：** WG-01 新局配置注入接口；WG-11 提供危机汇总查询契约。

**独占文件：**

- `scripts/data/meta/CalibrationData.gd`
- `data/calibrations/**`
- `scripts/core/MetaProgressionManager.gd`
- `scripts/ui/preflight/PreflightSetupPopup.gd`
- `scenes/ui/preflight/PreflightSetupPopup.tscn`
- `scripts/app/MainMenu.gd`
- `scripts/app/GameOver.gd`
- 元存档/航前 UI 测试

**禁止修改：** `AdvancedCrisisData.gd` 与危机 Resource、project.godot、RunManager、玩家战斗文件。

**输出接口：** 版本化 `user://meta_progression.json`、所选校准/危机只读快照、新局与结算信号；Autoload 登记交给 WG-01。

**验收：** 8 项校准、单选、解锁条件、危机解锁记录正常；损坏存档安全回退；元存档不覆盖局内存档；没有永久属性等级。

## WG-11：进阶危机规则解析

**Agent 目标：** 实现危机 0–10 的累计不可变 modifier 集合，并向探索、经济、敌人、Boss 与事件成本提供统一查询。

**Skills：** `resource-pattern`, `dependency-injection`, `save-load`, `ai-navigation`, `godot-testing`

**前置依赖：** WG-01 Balance/RunContent 契约；WG-07 的敌人/Boss modifier 接口；WG-10 的选择快照格式。

**独占文件：**

- `scripts/data/meta/AdvancedCrisisData.gd`
- `data/advanced_crisis/**`
- `scripts/core/AdvancedCrisisResolver.gd`
- 危机快照与累计效果测试

**禁止修改：** GameOver、MetaProgressionManager、RunManager、ExploreRoom、商店 UI、敌人/Boss 实现文件。

**输出接口：** `resolve(level) -> immutable modifiers`、分域查询、序列化 ID 列表；各消费组通过依赖注入读取。

**验收：** 0–10 层只累计一次；危机 0 完全等于标准配置；继续存档不重复应用；危机 10 不把普通/重击伤害突破既定类别。

## WG-12：遥测、自动模拟与全量验收

**Agent 目标：** 建立不修改游戏权威状态的观察层、经济/航图模拟器、分位数报告和最终回归清单。

**Skills：** `godot-testing`, `save-load`, `godot-optimization`, `godot-debugging`, `godot-code-review`

**前置依赖：** WG-01 遥测信号契约。测试骨架可在第一波后开始，最终验收在所有组集成后执行。

**独占文件：**

- `scripts/core/BalanceTelemetry.gd`
- `tools/balance_telemetry_check.gd`
- `tools/run_seed_simulator.gd`
- `tools/balance_report.gd`
- `scenes/tests/BalanceTelemetryCheck.tscn`
- `scenes/tests/FullBalanceAcceptanceCheck.tscn`
- `docs/godot-prompter/reports/WG-12.md`

**允许修改：** 只新增本组工具和测试。发现缺少上报点时提交各组/WG-01 集成请求，不直接改其独占文件。

**禁止修改：** 所有其他生产脚本、Resource 内容和中央文件。

**输出接口：** `user://balance_runs.jsonl`、P25/P50/P75/P90 报告、固定种子失败清单、性能热点清单。

**验收：**

- 正式关闭遥测时不写文件且无明显运行开销。
- 1000 种子还原事件/奖励/信标分布、经济、3/5/8 和保底触发率。
- 每个信标/机制记录触发数、伤害贡献、最大世代和峰值每秒事件数。
- 完成白板、标准、单家族胡局、跨家族胡局的自动/人工验收报告。

## 工作组依赖波次与合并顺序

### 波次 A：先冻结共享接口

1. 只启动 WG-01。
2. WG-01 完成契约测试、Facade、只读 Context、Mutation 和接口文档。
3. 在接口文档通过审阅前，不启动会依赖局内状态的内容实现。

### 波次 B：可并行的主体系统

接口冻结后可并行启动：

- WG-02 事件
- WG-03 奖励
- WG-04 信标的数据/候选部分
- WG-05 战斗核心
- WG-08 探索节奏
- WG-09 经济商店（先用目录 mock）
- WG-10 元进度（先用危机汇总 mock）
- WG-12 遥测骨架

这些组不得修改中央文件；需要接线统一写 integration request。

### 波次 C：依赖运行时契约的内容

1. WG-05 冻结战斗 trigger/action/rule_key 后，启动 WG-06 装备机制，并让 WG-04 完成战斗型信标联调。
2. WG-05 冻结伤害/阶段事件后，启动 WG-07 敌人与 Boss。
3. WG-07 和 WG-10 的输入契约稳定后，启动 WG-11 进阶危机。

### 波次 D：中央接线和验收

建议合并次序：

1. WG-01 基础接口。
2. WG-05 战斗运行层。
3. WG-02、WG-03、WG-04 三类内容服务。
4. WG-08、WG-09、WG-10 周边流程。
5. WG-06 装备内容、WG-07 敌人与 Boss、WG-11 危机。
6. WG-01 按各组 integration request 统一修改 `RunManager.gd`、`WorldMap.gd`、`project.godot`。
7. WG-12 执行全量模拟和回归；问题回到对应唯一所有者，不在验收组热修。

## 可复制给每个 Agent 的统一开场指令

在各工作组正文前附加以下指令：

```text
你负责且只负责 WG-XX。先完整读取 AGENTS.md、CLAUDE.md、总策划案、实施计划、
run-content-contract.md，以及 WG-XX 列出的技能。先检查工作区和允许修改文件的现有 diff，
保留所有用户改动。严格遵守独占/禁止文件边界；接口不足时写 integration-requests/WG-XX.md，
不要修改 RunManager.gd、WorldMap.gd 或 project.godot。先写失败测试，再实现，再运行相关既有测试。
完成后写 reports/WG-XX.md，列明改动、命令、结果、风险和待集成项。
```

WG-01 是唯一例外：它可以修改三个中央文件，但也不得越界修改其他工作组的独占内容。
